import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/models.dart';
import '../sporcle/sporcle_login.dart';
import '../storage/app_store.dart';
import 'connection_providers.dart';

part 'account_providers.g.dart';

@Riverpod(keepAlive: true)
AppStore appStore(Ref ref) => AppStore();

/// How a login runs: on the device, except in a browser, which may not call
/// sporcle.com and asks the relay instead (protocol/PROTOCOL.md §3.1).
typedef LoginRunner =
    Future<({String playerId, String token, String handle})> Function(
      String email,
      String password,
      String deviceId,
    );

@Riverpod(keepAlive: true)
LoginRunner loginRunner(Ref ref) {
  if (kIsWeb) return ref.watch(relayApiProvider).login;
  return (email, password, deviceId) async {
    final login = SporcleLogin();
    try {
      return await login.login(email, password, deviceId);
    } finally {
      login.close();
    }
  };
}

/// The signed-in Sporcle account, or null.
@Riverpod(keepAlive: true)
class Account extends _$Account {
  @override
  Future<SporcleAccount?> build() => ref.watch(appStoreProvider).account();

  /// Logs in and keeps the Party credentials the login returns. The password is
  /// used for the login and forgotten.
  Future<void> signIn(String email, String password) async {
    final store = ref.read(appStoreProvider);
    // The token is bound to this device id, so mint with the same one the app then
    // sends as X-UDID.
    final deviceId = await store.deviceId();
    final credentials = await ref.read(loginRunnerProvider)(
      email.trim(),
      password,
      deviceId,
    );
    final account = SporcleAccount(
      playerId: credentials.playerId,
      token: credentials.token,
      handle: credentials.handle,
      deviceId: deviceId,
    );
    await store.saveAccount(account);
    state = AsyncData(account);
  }

  Future<void> signOut() async {
    await ref.read(appStoreProvider).saveAccount(null);
    state = const AsyncData(null);
  }
}
