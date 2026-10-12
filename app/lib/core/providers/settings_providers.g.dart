// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's own settings (sound, haptics), kept on the device.

@ProviderFor(Settings)
final settingsProvider = SettingsProvider._();

/// The app's own settings (sound, haptics), kept on the device.
final class SettingsProvider
    extends $AsyncNotifierProvider<Settings, AppSettings> {
  /// The app's own settings (sound, haptics), kept on the device.
  SettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsHash();

  @$internal
  @override
  Settings create() => Settings();
}

String _$settingsHash() => r'28df1c1e4e26dff5bd61844879d007ed49cc1a2f';

/// The app's own settings (sound, haptics), kept on the device.

abstract class _$Settings extends $AsyncNotifier<AppSettings> {
  FutureOr<AppSettings> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AppSettings>, AppSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AppSettings>, AppSettings>,
              AsyncValue<AppSettings>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// What the signed-in player last heard of their Party Poppers (protocol/
/// PROTOCOL.md §3.5): from a seat they took, or a claim. Null until then.

@ProviderFor(Poppers)
final poppersProvider = PoppersProvider._();

/// What the signed-in player last heard of their Party Poppers (protocol/
/// PROTOCOL.md §3.5): from a seat they took, or a claim. Null until then.
final class PoppersProvider
    extends $AsyncNotifierProvider<Poppers, PopperBalance?> {
  /// What the signed-in player last heard of their Party Poppers (protocol/
  /// PROTOCOL.md §3.5): from a seat they took, or a claim. Null until then.
  PoppersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'poppersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$poppersHash();

  @$internal
  @override
  Poppers create() => Poppers();
}

String _$poppersHash() => r'372f8053b84da10bb5198ffe06deaac9739670ce';

/// What the signed-in player last heard of their Party Poppers (protocol/
/// PROTOCOL.md §3.5): from a seat they took, or a claim. Null until then.

abstract class _$Poppers extends $AsyncNotifier<PopperBalance?> {
  FutureOr<PopperBalance?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PopperBalance?>, PopperBalance?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PopperBalance?>, PopperBalance?>,
              AsyncValue<PopperBalance?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// A game an invite link asked to join (protocol/PROTOCOL.md §3.8), waiting for
/// the person to say yes or no. Home offers it once somebody is signed in.

@ProviderFor(PendingInvite)
final pendingInviteProvider = PendingInviteProvider._();

/// A game an invite link asked to join (protocol/PROTOCOL.md §3.8), waiting for
/// the person to say yes or no. Home offers it once somebody is signed in.
final class PendingInviteProvider
    extends $NotifierProvider<PendingInvite, String?> {
  /// A game an invite link asked to join (protocol/PROTOCOL.md §3.8), waiting for
  /// the person to say yes or no. Home offers it once somebody is signed in.
  PendingInviteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingInviteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingInviteHash();

  @$internal
  @override
  PendingInvite create() => PendingInvite();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$pendingInviteHash() => r'e0017a2609e8e2083aaf36b44a9477309ec6d701';

/// A game an invite link asked to join (protocol/PROTOCOL.md §3.8), waiting for
/// the person to say yes or no. Home offers it once somebody is signed in.

abstract class _$PendingInvite extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
