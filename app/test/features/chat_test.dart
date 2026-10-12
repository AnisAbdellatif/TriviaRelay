import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_relay/core/game/game_cues.dart';
import 'package:trivia_relay/core/models/models.dart';
import 'package:trivia_relay/features/game/chat_screen.dart';
import 'package:trivia_relay/features/game/game_effects.dart';
import 'package:trivia_relay/features/game/game_screen.dart';
import 'package:trivia_relay/shared/game_feedback.dart';
import 'package:trivia_relay/shared/widgets/game_top_bar.dart';

import '../support/app.dart';
import '../support/fake_seat_connection.dart';
import '../support/protocol_fixtures.dart';
import '../support/pump.dart';

/// No speaker in a test.
class _Quiet implements GameFeedback {
  @override
  Future<void> sound(GameCue cue) async {}
  @override
  Future<void> reactionSound(String type) async {}
  @override
  Future<void> buzz(GameCue cue) async {}
  @override
  Future<void> keepAwake(bool on) async {}
  @override
  void dispose() {}
}

void main() {
  SeatState snapshot(String name) => ProtocolFixtures.snapshot(name);

  Future<FakeSeatConnection> show(
    WidgetTester tester,
    SeatState state, {
    Size size = const Size(360, 740),
  }) async {
    final connection = FakeSeatConnection()..emit(state);
    await pumpApp(
      tester,
      const GameScreen(),
      connection: connection,
      size: size,
      overrides: [gameFeedbackProvider.overrideWithValue(_Quiet())],
    );
    return connection;
  }

  Future<void> openChat(WidgetTester tester) async {
    await tapKey(tester, GameTopBar.chatKey);
    expect(find.byType(ChatScreen), findsOneWidget);
  }

  group('the chat', () {
    testWidgets('its button counts what came while it was closed', (
      tester,
    ) async {
      await show(tester, snapshot('lobby_chat_player'));
      expect(find.byKey(const Key('chatUnreadBadge')), findsOneWidget);
      expect(find.byTooltip('Chat, 1 new message'), findsOneWidget);

      await show(tester, snapshot('lobby_player_votes'));
      expect(find.byKey(GameTopBar.chatKey), findsOneWidget);
      expect(find.byKey(const Key('chatUnreadBadge')), findsNothing);
    });

    testWidgets(
      'opens with the chat open at the relay, and says who wrote what',
      (tester) async {
        final connection = await show(tester, snapshot('lobby_chat_player'));
        await openChat(tester);
        expect(connection.calls, contains('chat_open'));

        expect(
          find.text('Hosta'),
          findsNothing,
          reason: 'the message’s own name',
        );
        expect(find.text('Host'), findsNWidgets(2));
        expect(find.text('مرحبا!'), findsOneWidget);
        expect(find.text('You'), findsOneWidget);
        expect(find.text('Hi all'), findsOneWidget);
        expect(find.text('Welcome to the game!'), findsOneWidget);
        expect(find.textContaining('is typing…'), findsOneWidget);

        // A message written right to left reads right to left.
        final arabic = tester.widget<Directionality>(
          find
              .ancestor(
                of: find.text('مرحبا!'),
                matching: find.byType(Directionality),
              )
              .first,
        );
        expect(arabic.textDirection, TextDirection.rtl);

        await tapKey(tester, const Key('chatBackButton'));
        expect(find.byType(ChatScreen), findsNothing);
        expect(connection.calls.last, 'chat_close');
      },
    );

    testWidgets('sends what is typed, says it is typing, and counts', (
      tester,
    ) async {
      final connection = await show(tester, snapshot('lobby_chat_player'));
      await openChat(tester);

      await tester.enterText(find.byKey(const Key('chatField')), 'Good luck');
      await tester.pump();
      expect(connection.calls, contains('chat_typing:true'));
      expect(find.text('9/${GameRules.chatMaxLength}'), findsOneWidget);

      await tapKey(tester, const Key('chatSendButton'));
      expect(connection.calls, contains('chat_send:Good luck'));
      expect(find.text('0/${GameRules.chatMaxLength}'), findsOneWidget);
    });

    testWidgets('takes no more than the official field', (tester) async {
      await show(tester, snapshot('lobby_chat_player'));
      await openChat(tester);
      await tester.enterText(
        find.byKey(const Key('chatField')),
        'x' * (GameRules.chatMaxLength + 40),
      );
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('chatField')))
            .controller!
            .text
            .length,
        GameRules.chatMaxLength,
      );
    });

    testWidgets('asks for earlier messages when there are more', (
      tester,
    ) async {
      final state = snapshot('lobby_chat_player');
      final connection = await show(
        tester,
        state.copyWith(chat: state.chat.copyWith(hasMore: true)),
      );
      await openChat(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('chatMoreButton')),
        100,
        scrollable: find.descendant(
          of: find.byKey(const Key('chatMessages')),
          matching: find.byType(Scrollable),
        ),
      );
      await tapKey(tester, const Key('chatMoreButton'));
      expect(connection.calls, contains('chat_more'));
    });

    testWidgets(
      'makes way when a question needs answering, as the official app has no chat there',
      (tester) async {
        final connection = await show(tester, snapshot('lobby_chat_player'));
        await openChat(tester);
        connection.emit(snapshot('question_player'));
        await settle(tester);
        expect(find.byType(ChatScreen), findsNothing);
        expect(connection.calls.last, 'chat_close');
        expect(find.byKey(GameTopBar.chatKey), findsNothing);

        // Once answered, it is back.
        connection.emit(snapshot('question_host_answered'));
        await settle(tester);
        expect(find.byKey(GameTopBar.chatKey), findsOneWidget);
      },
    );

    for (final (name, size) in const [
      ('lobby_chat_player', Size(320, 568)),
      ('reveal_host', Size(320, 568)),
    ]) {
      testWidgets('$name with its chat fits a small phone at twice the text', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await show(tester, snapshot(name), size: size);
        expect(tester.takeException(), isNull);
        await openChat(tester);
        await tester.enterText(
          find.byKey(const Key('chatField')),
          'A longer message that wraps',
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('its controls are big enough to tap, and say what they are', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await show(tester, snapshot('lobby_chat_player'));
      await openChat(tester);
      await tester.enterText(find.byKey(const Key('chatField')), 'hi');
      await tester.pump();
      for (final key in const [Key('chatBackButton'), Key('chatSendButton')]) {
        final size = tester.getSize(find.byKey(key));
        expect(size.width, greaterThanOrEqualTo(44), reason: '$key');
        expect(size.height, greaterThanOrEqualTo(44), reason: '$key');
      }
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      expect(find.byTooltip('Send'), findsOneWidget);
      expect(find.byTooltip('Back to the game'), findsOneWidget);
      handle.dispose();
    });
  });

  group('reactions', () {
    testWidgets(
      'any player can honk another, and the host keeps the host’s items',
      (tester) async {
        final connection = await show(tester, snapshot('lobby_player_votes'));
        await tapKey(tester, const ValueKey('player-1'));
        expect(find.byKey(const Key('playerAction-honk')), findsOneWidget);
        expect(find.byKey(const Key('playerAction-kick')), findsNothing);
        await tester.tap(find.byKey(const Key('playerAction-honk')));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        expect(connection.calls, contains('react:1:goose'));
        expect(find.textContaining('You honked at'), findsOneWidget);
        await settle(tester);

        // Once in a while: right after, the honk waits.
        await tapKey(tester, const ValueKey('player-1'));
        final honk = tester.widget<ListTile>(
          find.byKey(const Key('playerAction-honk')),
        );
        expect(honk.enabled, isFalse);
      },
    );

    testWidgets('a player sees how many reactions each has had', (
      tester,
    ) async {
      await show(tester, snapshot('reveal_reactions_player'));
      expect(find.textContaining('3 REACTIONS'), findsWidgets);
      expect(find.textContaining('1 REACTION'), findsWidgets);
    });

    testWidgets('one received says who sent it', (tester) async {
      final connection = await show(tester, snapshot('reveal_judged_player'));
      connection.emit(snapshot('reveal_reactions_player'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('reactionToast')), findsOneWidget);
      expect(find.textContaining('honked at you'), findsOneWidget);
      await settle(tester);
      await tester.pump(const Duration(seconds: 3));
      expect(find.byKey(const Key('reactionToast')), findsNothing);
    });

    testWidgets('coming in on one already received sends no toast', (
      tester,
    ) async {
      await show(tester, snapshot('reveal_reactions_player'));
      expect(find.byKey(const Key('reactionToast')), findsNothing);
    });
  });

  testWidgets(
    'with the chat in the bar, a player’s Leave makes way into a menu of its own',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await show(
        tester,
        snapshot('reveal_judged_player'),
        size: const Size(320, 568),
      );
      expect(find.byKey(GameTopBar.chatKey), findsOneWidget);
      expect(find.byKey(GameTopBar.leaveKey), findsNothing);
      await tapKey(tester, GameTopBar.menuKey);
      expect(find.byKey(const Key('toLobbyItem')), findsNothing);
      await tapKey(tester, const Key('leaveItem'));
      expect(find.text('Leave the game?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a Popper spent is said', (tester) async {
    await show(tester, snapshot('question_popper_notice_player'));
    expect(find.text('Popper spent'), findsOneWidget);
  });
}
