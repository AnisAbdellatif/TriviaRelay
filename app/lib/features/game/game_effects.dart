import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/game/game_cues.dart';
import '../../core/game/social.dart';
import '../../core/providers/config_providers.dart';
import '../../core/providers/connection_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../shared/game_feedback.dart';

part 'game_effects.g.dart';

/// The platform's side of the game: sounds, buzzes, the screen kept on.
@Riverpod(keepAlive: true)
GameFeedback gameFeedback(Ref ref) {
  final feedback = DeviceGameFeedback();
  ref.onDispose(feedback.dispose);
  return feedback;
}

/// What the game screen does besides drawing, for as long as it is open: the
/// game screen watches this, and closing it stops all of it.
///
/// * Keeps the screen on while a seat is attached (a snapshot has come, and
///   the seat hasn't ended), as the official app does from the moment its game
///   socket connects.
/// * Marks the game's moments ([cuesFor]): the game starting, a question
///   opening, this player's answer locked in, right or wrong at the reveal,
///   and a tick in each of the last [tickSeconds] seconds of a question they
///   haven't answered. With a sound when the sound setting is on, a buzz when
///   the haptics one is (Android), and neither while the app is in the
///   background.
@riverpod
class GameEffects extends _$GameEffects {
  static const _tickEvery = Duration(milliseconds: 200);

  Timer? _ticker;
  int? _lastSecond;
  bool _awake = false;

  @override
  void build() {
    final feedback = ref.watch(gameFeedbackProvider);
    ref
      // Loaded now, so the first cue knows whether to sound.
      ..listen(settingsProvider, (_, _) {})
      ..listen(seatStateProvider, (previous, next) {
        final after = next.value;
        if (after != null) {
          cuesFor(previous?.value, after).forEach(_cue);
          final reactions = newReactions(previous?.value, after);
          if (reactions.isNotEmpty) playReaction(reactions.last.type);
          final poppers = after.you.poppers;
          if (poppers != null && poppers != previous?.value?.you.poppers) {
            unawaited(ref.read(poppersProvider.notifier).heard(poppers));
          }
        }
        _followClock();
        _keepAwake();
      })
      ..listen(seatClosedProvider, (_, _) {
        _followClock();
        _keepAwake();
      })
      ..onDispose(() {
        _ticker?.cancel();
        _ticker = null;
        if (_awake) unawaited(feedback.keepAwake(false));
        _awake = false;
      });
    _followClock();
    _keepAwake();
  }

  bool get _attached =>
      ref.read(seatStateProvider).hasValue &&
      ref.read(seatClosedProvider) == null;

  void _keepAwake() {
    final on = _attached;
    if (on == _awake) return;
    _awake = on;
    unawaited(ref.read(gameFeedbackProvider).keepAwake(on));
  }

  /// Ticks run on a timer of their own while a question is counting down for
  /// this player, and stop with it.
  void _followClock() {
    final state = ref.read(seatStateProvider).value;
    final counting =
        _attached &&
        state != null &&
        secondsToAnswer(state, _serverNow()) != null;
    if (!counting) {
      _ticker?.cancel();
      _ticker = null;
      _lastSecond = null;
      return;
    }
    _ticker ??= Timer.periodic(_tickEvery, (_) => _tick());
  }

  void _tick() {
    final state = ref.read(seatStateProvider).value;
    final seconds = state == null ? null : secondsToAnswer(state, _serverNow());
    if (seconds == null || seconds == 0) {
      _followClock();
      if (seconds == 0) _lastSecond = 0;
      return;
    }
    if (seconds != _lastSecond &&
        seconds <= tickSeconds &&
        _lastSecond != null) {
      _cue(GameCue.tick);
    }
    _lastSecond = seconds;
  }

  int _serverNow() =>
      ref.read(clockProvider)().millisecondsSinceEpoch +
      ref.read(serverClockOffsetProvider);

  /// Plays a reaction's sound: one received, or one this player just sent (the
  /// official app plays both).
  void playReaction(String type) {
    if (!_inForeground) return;
    if (ref.read(settingsProvider).value?.sound != true) return;
    unawaited(ref.read(gameFeedbackProvider).reactionSound(type));
  }

  void _cue(GameCue cue) {
    if (!_inForeground) return;
    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;
    final feedback = ref.read(gameFeedbackProvider);
    if (settings.sound) unawaited(feedback.sound(cue));
    if (settings.haptics) unawaited(feedback.buzz(cue));
  }

  static bool get _inForeground {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }
}
