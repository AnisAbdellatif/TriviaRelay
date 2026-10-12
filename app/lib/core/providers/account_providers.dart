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
  Future<SporcleAccount?> build() async {
    final store = ref.watch(appStoreProvider);
    final account = await store.account();
    if (account == null) return null;
    return account.copyWith(
      displayName: await store.displayName(account.playerId),
    );
  }

  /// The name other players see from now on, or the handle again (null): what
  /// the next seat is taken with. Kept for this player on this device.
  Future<void> setDisplayName(String? name) async {
    final account = await future;
    if (account == null) return;
    final chosen = name == null || name.trim().isEmpty ? null : name.trim();
    final store = ref.read(appStoreProvider);
    await store.saveDisplayName(account.playerId, chosen);
    final next = account.copyWith(displayName: chosen);
    await store.saveAccount(next);
    state = AsyncData(next);
  }

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
      displayName: await store.displayName(credentials.playerId),
    );
    // A seat somebody else left on this phone is theirs: dropped, not offered.
    if (await store.seat(account.playerId) == null) await store.saveSeat(null);
    await store.saveAccount(account);
    state = AsyncData(account);
  }

  /// Signs out on purpose: forgets the account and the seat the phone holds
  /// for it, and stops any connection to that seat, so nothing of this player
  /// is left for whoever picks the phone up next. Leaving the seat first is
  /// [CurrentSeat.leave]'s; this only forgets it.
  Future<void> signOut() async {
    final store = ref.read(appStoreProvider);
    await store.saveSeat(null);
    ref.invalidate(seatConnectionProvider);
    await store.saveAccount(null);
    state = const AsyncData(null);
  }

  /// Sporcle no longer takes the token: forgets the account, but keeps the
  /// seat. A seat doesn't use the token (the relay holds it), so a game in
  /// progress goes on, and the same player signing in again is offered it
  /// back. Nobody else is ([AppStore.seat]).
  Future<void> expire() async {
    await ref.read(appStoreProvider).saveAccount(null);
    state = const AsyncData(null);
  }
}
