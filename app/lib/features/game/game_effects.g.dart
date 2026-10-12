// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_effects.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The platform's side of the game: sounds, buzzes, the screen kept on.

@ProviderFor(gameFeedback)
final gameFeedbackProvider = GameFeedbackProvider._();

/// The platform's side of the game: sounds, buzzes, the screen kept on.

final class GameFeedbackProvider
    extends $FunctionalProvider<GameFeedback, GameFeedback, GameFeedback>
    with $Provider<GameFeedback> {
  /// The platform's side of the game: sounds, buzzes, the screen kept on.
  GameFeedbackProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameFeedbackProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameFeedbackHash();

  @$internal
  @override
  $ProviderElement<GameFeedback> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GameFeedback create(Ref ref) {
    return gameFeedback(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GameFeedback value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GameFeedback>(value),
    );
  }
}

String _$gameFeedbackHash() => r'f915613828726bad9185e556ce77ea21074b0a2d';

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

@ProviderFor(GameEffects)
final gameEffectsProvider = GameEffectsProvider._();

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
final class GameEffectsProvider extends $NotifierProvider<GameEffects, void> {
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
  GameEffectsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameEffectsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameEffectsHash();

  @$internal
  @override
  GameEffects create() => GameEffects();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$gameEffectsHash() => r'c82ca53bb215d8f8d757e66816b212152e38e129';

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

abstract class _$GameEffects extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
