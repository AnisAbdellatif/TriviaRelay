// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appStore)
final appStoreProvider = AppStoreProvider._();

final class AppStoreProvider
    extends $FunctionalProvider<AppStore, AppStore, AppStore>
    with $Provider<AppStore> {
  AppStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appStoreHash();

  @$internal
  @override
  $ProviderElement<AppStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppStore create(Ref ref) {
    return appStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppStore>(value),
    );
  }
}

String _$appStoreHash() => r'7a79713f4ac0564ccd9c1bdcac4c2c16587c0a83';

@ProviderFor(loginRunner)
final loginRunnerProvider = LoginRunnerProvider._();

final class LoginRunnerProvider
    extends $FunctionalProvider<LoginRunner, LoginRunner, LoginRunner>
    with $Provider<LoginRunner> {
  LoginRunnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loginRunnerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loginRunnerHash();

  @$internal
  @override
  $ProviderElement<LoginRunner> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LoginRunner create(Ref ref) {
    return loginRunner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoginRunner value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoginRunner>(value),
    );
  }
}

String _$loginRunnerHash() => r'd8d64d42f74b573c0c33f549383d835c285a97be';

/// The signed-in Sporcle account, or null.

@ProviderFor(Account)
final accountProvider = AccountProvider._();

/// The signed-in Sporcle account, or null.
final class AccountProvider
    extends $AsyncNotifierProvider<Account, SporcleAccount?> {
  /// The signed-in Sporcle account, or null.
  AccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountHash();

  @$internal
  @override
  Account create() => Account();
}

String _$accountHash() => r'e991148dd4ea5d532b01e223711b0a64089fb98d';

/// The signed-in Sporcle account, or null.

abstract class _$Account extends $AsyncNotifier<SporcleAccount?> {
  FutureOr<SporcleAccount?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SporcleAccount?>, SporcleAccount?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SporcleAccount?>, SporcleAccount?>,
              AsyncValue<SporcleAccount?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
