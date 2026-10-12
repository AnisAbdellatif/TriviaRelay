import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/game/game_cues.dart';
import '../core/game/social.dart';

/// What the game screen does besides drawing: plays a cue's sound, buzzes, and
/// keeps the screen on. One seam, so tests can stand in for the platform.
abstract class GameFeedback {
  Future<void> sound(GameCue cue);

  /// A reaction's sound ([reactionSoundAsset]): another player's, or one this
  /// player sent.
  Future<void> reactionSound(String type);
  Future<void> buzz(GameCue cue);
  Future<void> keepAwake(bool on);
  void dispose();
}

/// The real thing: sounds from `assets/sounds/` (scripts/make_sounds.py) through
/// audioplayers, Flutter's own haptics, and wakelock_plus.
class DeviceGameFeedback implements GameFeedback {
  // One player per cue, made on first use: a tick can't cut a question's chime
  // short, and a quick answer can't swallow its own blip.
  final Map<GameCue, AudioPlayer> _players = {};

  /// Reactions share one player: a new one cuts the last short.
  AudioPlayer? _reactions;

  @override
  Future<void> sound(GameCue cue) async {
    try {
      final player = _players[cue] ??= await _player();
      await player.stop();
      await player.play(AssetSource('sounds/${cue.name}.wav'));
    } on Object {
      // A sound that can't play (autoplay rules, no audio device) is no error.
    }
  }

  @override
  Future<void> reactionSound(String type) async {
    try {
      final player = _reactions ??= await _player();
      await player.stop();
      await player.play(AssetSource(reactionSoundAsset(type)));
    } on Object {
      // As for a cue.
    }
  }

  Future<AudioPlayer> _player() async {
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    // Short cues, played often: Android's low-latency pool, and never taking
    // audio focus from whatever else is playing.
    if (!kIsWeb) {
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
            .build(),
      );
    }
    return player;
  }

  @override
  Future<void> buzz(GameCue cue) async {
    if (kIsWeb) return;
    switch (cue) {
      case GameCue.submit || GameCue.tick:
        await HapticFeedback.selectionClick();
      case GameCue.correct:
        await HapticFeedback.mediumImpact();
      case GameCue.wrong:
        await HapticFeedback.heavyImpact();
      case GameCue.start || GameCue.question:
        await HapticFeedback.lightImpact();
    }
  }

  @override
  Future<void> keepAwake(bool on) async {
    try {
      await WakelockPlus.toggle(enable: on);
    } on Object {
      // A browser without the Wake Lock API: the screen sleeps as it would.
    }
  }

  @override
  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
    _reactions?.dispose();
    _reactions = null;
  }
}
