import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_relay/core/game/game_cues.dart';
import 'package:trivia_relay/core/providers/settings_providers.dart';
import 'package:trivia_relay/features/game/game_effects.dart';
import 'package:trivia_relay/features/game/game_screen.dart';
import 'package:trivia_relay/shared/game_feedback.dart';

import '../support/app.dart';
import '../support/fake_seat_connection.dart';
import '../support/protocol_fixtures.dart';
import '../support/pump.dart';

/// Stands in for the speaker, the buzzer and the screen's wake lock.
class _Feedback implements GameFeedback {
  final sounds = <GameCue>[];
  final reactions = <String>[];
  final buzzes = <GameCue>[];
  final awake = <bool>[];

  @override
  Future<void> sound(GameCue cue) async => sounds.add(cue);
  @override
  Future<void> reactionSound(String type) async => reactions.add(type);
  @override
  Future<void> buzz(GameCue cue) async => buzzes.add(cue);
  @override
  Future<void> keepAwake(bool on) async => awake.add(on);
  @override
  void dispose() {}
}

void main() {
  final lobby = ProtocolFixtures.snapshot('lobby_host');
  final question = ProtocolFixtures.snapshot('question_player');

  Future<({_Feedback feedback, FakeSeatConnection connection})> pumpGame(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
    DateTime Function()? clock,
  }) async {
    final feedback = _Feedback();
    final connection = FakeSeatConnection()..emit(lobby);
    await pumpApp(
      tester,
      const GameScreen(),
      connection: connection,
      prefs: prefs,
      clock: clock,
      overrides: [gameFeedbackProvider.overrideWithValue(feedback)],
    );
    return (feedback: feedback, connection: connection);
  }

  testWidgets('the screen stays on while the game is open, and no longer', (
    tester,
  ) async {
    final game = await pumpGame(tester);
    expect(game.feedback.awake, [true]);

    await tester.pumpWidget(const SizedBox());
    await settle(tester);
    expect(game.feedback.awake, [true, false]);
  });

  testWidgets('the game starting sounds, and buzzes', (tester) async {
    final game = await pumpGame(tester);
    expect(game.feedback.sounds, isEmpty, reason: 'coming in marks nothing');

    game.connection.emit(question);
    await settle(tester);
    expect(game.feedback.sounds, [GameCue.start]);
    expect(game.feedback.buzzes, [GameCue.start]);
  });

  testWidgets('sound off is silence; the buzz is its own setting', (
    tester,
  ) async {
    final game = await pumpGame(
      tester,
      prefs: {
        'trivia_relay.settings': jsonEncode({'sound': false, 'haptics': true}),
      },
    );
    game.connection.emit(question);
    await settle(tester);
    expect(game.feedback.sounds, isEmpty);
    expect(game.feedback.buzzes, [GameCue.start]);
  });

  testWidgets('the last seconds of an unanswered question tick', (
    tester,
  ) async {
    var now = fixtureNow;
    final game = await pumpGame(
      tester,
      clock: () => DateTime.fromMillisecondsSinceEpoch(now),
    );
    game.connection.emit(question);
    await settle(tester);
    expect(game.feedback.sounds, [GameCue.start]);

    // 15 s to go when it opened: nothing until the last five.
    now = fixtureNow + 9000;
    await tester.pump(const Duration(milliseconds: 400));
    expect(game.feedback.sounds.where((c) => c == GameCue.tick), isEmpty);

    for (final at in [10500, 11500, 12500]) {
      now = fixtureNow + at;
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(game.feedback.sounds.where((c) => c == GameCue.tick).length, 3);
  });

  testWidgets('nothing sounds in the background', (tester) async {
    final game = await pumpGame(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    game.connection.emit(question);
    await settle(tester);
    expect(game.feedback.sounds, isEmpty);
    expect(game.feedback.buzzes, isEmpty);
  });

  testWidgets('a reaction sent to this player plays its sound, once', (
    tester,
  ) async {
    final game = await pumpGame(tester);
    game.connection.emit(ProtocolFixtures.snapshot('reveal_judged_player'));
    await settle(tester);
    expect(game.feedback.reactions, isEmpty);

    final honked = ProtocolFixtures.snapshot('reveal_reactions_player');
    game.connection.emit(honked);
    await settle(tester);
    expect(game.feedback.reactions, ['goose']);

    // The same again (another snapshot while it shows) plays nothing more.
    game.connection.emit(honked.copyWith(serverTime: fixtureNow + 500));
    await settle(tester);
    expect(game.feedback.reactions, ['goose']);
  });

  testWidgets('a reaction is silent with the sound off', (tester) async {
    final game = await pumpGame(
      tester,
      prefs: {
        'trivia_relay.settings': jsonEncode({'sound': false, 'haptics': true}),
      },
    );
    game.connection.emit(ProtocolFixtures.snapshot('reveal_judged_player'));
    await settle(tester);
    game.connection.emit(ProtocolFixtures.snapshot('reveal_reactions_player'));
    await settle(tester);
    expect(game.feedback.reactions, isEmpty);
  });

  testWidgets('a Popper spent comes off the balance the app knows', (
    tester,
  ) async {
    final game = await pumpGame(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameScreen)),
    );
    final spent = ProtocolFixtures.snapshot('question_popper_notice_player');
    game.connection.emit(
      spent.copyWith(you: spent.you.copyWith(poppers: 3), notice: null),
    );
    await settle(tester);
    expect(container.read(poppersProvider).value?.poppers, 3);

    game.connection.emit(spent);
    await settle(tester);
    expect(spent.you.poppers, 2);
    expect(container.read(poppersProvider).value?.poppers, 2);
  });
}
