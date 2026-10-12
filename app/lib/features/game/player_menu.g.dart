// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_menu.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// When this app last sent a reaction: the relay takes one every
/// [GameRules.reactionGapMs], as the official app sends them.

@ProviderFor(LastReaction)
final lastReactionProvider = LastReactionProvider._();

/// When this app last sent a reaction: the relay takes one every
/// [GameRules.reactionGapMs], as the official app sends them.
final class LastReactionProvider
    extends $NotifierProvider<LastReaction, DateTime?> {
  /// When this app last sent a reaction: the relay takes one every
  /// [GameRules.reactionGapMs], as the official app sends them.
  LastReactionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastReactionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastReactionHash();

  @$internal
  @override
  LastReaction create() => LastReaction();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$lastReactionHash() => r'723f452753c2914d6ed66a1f23d3202a980558eb';

/// When this app last sent a reaction: the relay takes one every
/// [GameRules.reactionGapMs], as the official app sends them.

abstract class _$LastReaction extends $Notifier<DateTime?> {
  DateTime? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime?, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime?, DateTime?>,
              DateTime?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
