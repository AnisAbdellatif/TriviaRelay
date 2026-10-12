// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Server base URL.
///
/// On the web the app is normally served by the relay itself, so its own origin
/// is the right answer and nothing needs configuring per deployment. Override with
/// `--dart-define=SERVER_URL=https://example.com` when the app is hosted
/// somewhere else, and for Android, which has no origin: `scripts/ci.sh apk`
/// always sets it (and only to an https address). A release build left without
/// one has no relay ([relayConfigured] is false) and says so rather than trying
/// somewhere.

@ProviderFor(ServerBaseUrl)
final serverBaseUrlProvider = ServerBaseUrlProvider._();

/// Server base URL.
///
/// On the web the app is normally served by the relay itself, so its own origin
/// is the right answer and nothing needs configuring per deployment. Override with
/// `--dart-define=SERVER_URL=https://example.com` when the app is hosted
/// somewhere else, and for Android, which has no origin: `scripts/ci.sh apk`
/// always sets it (and only to an https address). A release build left without
/// one has no relay ([relayConfigured] is false) and says so rather than trying
/// somewhere.
final class ServerBaseUrlProvider
    extends $NotifierProvider<ServerBaseUrl, String> {
  /// Server base URL.
  ///
  /// On the web the app is normally served by the relay itself, so its own origin
  /// is the right answer and nothing needs configuring per deployment. Override with
  /// `--dart-define=SERVER_URL=https://example.com` when the app is hosted
  /// somewhere else, and for Android, which has no origin: `scripts/ci.sh apk`
  /// always sets it (and only to an https address). A release build left without
  /// one has no relay ([relayConfigured] is false) and says so rather than trying
  /// somewhere.
  ServerBaseUrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverBaseUrlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverBaseUrlHash();

  @$internal
  @override
  ServerBaseUrl create() => ServerBaseUrl();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$serverBaseUrlHash() => r'7fd1881a1f87d8517ff2828917aabe54957dcb1a';

/// Server base URL.
///
/// On the web the app is normally served by the relay itself, so its own origin
/// is the right answer and nothing needs configuring per deployment. Override with
/// `--dart-define=SERVER_URL=https://example.com` when the app is hosted
/// somewhere else, and for Android, which has no origin: `scripts/ci.sh apk`
/// always sets it (and only to an https address). A release build left without
/// one has no relay ([relayConfigured] is false) and says so rather than trying
/// somewhere.

abstract class _$ServerBaseUrl extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Whether this build knows its relay. False only for a release build that is
/// neither served by a relay nor built with SERVER_URL, which the app shows as
/// a broken build (main.dart) instead of quietly talking to localhost.

@ProviderFor(relayConfigured)
final relayConfiguredProvider = RelayConfiguredProvider._();

/// Whether this build knows its relay. False only for a release build that is
/// neither served by a relay nor built with SERVER_URL, which the app shows as
/// a broken build (main.dart) instead of quietly talking to localhost.

final class RelayConfiguredProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether this build knows its relay. False only for a release build that is
  /// neither served by a relay nor built with SERVER_URL, which the app shows as
  /// a broken build (main.dart) instead of quietly talking to localhost.
  RelayConfiguredProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'relayConfiguredProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$relayConfiguredHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return relayConfigured(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$relayConfiguredHash() => r'565e0421f9a829dabf92b9ff3bc5b2e55d61d409';

@ProviderFor(clock)
final clockProvider = ClockProvider._();

final class ClockProvider extends $FunctionalProvider<Clock, Clock, Clock>
    with $Provider<Clock> {
  ClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockHash();

  @$internal
  @override
  $ProviderElement<Clock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Clock create(Ref ref) {
    return clock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Clock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Clock>(value),
    );
  }
}

String _$clockHash() => r'ce4c8073e4878f6859ed9a59fae2c1819b4179af';
