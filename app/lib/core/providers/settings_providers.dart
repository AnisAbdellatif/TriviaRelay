import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../invite/invite_link.dart';
import '../models/models.dart';
import 'account_providers.dart';
import 'connection_providers.dart';

part 'settings_providers.g.dart';

/// The app's own settings (sound, haptics), kept on the device.
@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  @override
  Future<AppSettings> build() => ref.watch(appStoreProvider).settings();

  Future<void> change(AppSettings Function(AppSettings) edit) async {
    final next = edit(await future);
    state = AsyncData(next);
    await ref.read(appStoreProvider).saveSettings(next);
  }
}

/// What the signed-in player last heard of their Party Poppers (protocol/
/// PROTOCOL.md §3.5): from a seat they took, or a claim. Null until then.
@Riverpod(keepAlive: true)
class Poppers extends _$Poppers {
  @override
  Future<PopperBalance?> build() async {
    final account = await ref.watch(accountProvider.future);
    if (account == null) return null;
    return ref.read(appStoreProvider).poppers(account.playerId);
  }

  /// A count Sporcle just gave (a seat's `poppers`); a claim time already
  /// known is kept.
  Future<void> heard(int? poppers) async {
    if (poppers == null) return;
    final before = await future;
    await _keep(PopperBalance(poppers: poppers, lastClaim: before?.lastClaim));
  }

  /// Claims the free ones Sporcle has given back, and keeps the answer.
  Future<PopperBalance> claim() async {
    final account = await ref.read(accountProvider.future);
    if (account == null) throw const GameError(code: 'invalid_player');
    final balance = await ref.read(relayApiProvider).claimPoppers(account);
    await _keep(balance);
    return balance;
  }

  Future<void> _keep(PopperBalance balance) async {
    final account = ref.read(accountProvider).value;
    state = AsyncData(balance);
    if (account != null) {
      await ref.read(appStoreProvider).savePoppers(account.playerId, balance);
    }
  }
}

/// A HMAC-signed bearer token returned by the relay after redeeming a one-time bypass
/// code (Settings → "Host tools"). While set, the host's player menu opens for away
/// players too. Persists across app restarts in [AppStore]; null means bypass is off.
@Riverpod(keepAlive: true)
class KickBypassToken extends _$KickBypassToken {
  @override
  Future<String?> build() async {
    final token = await ref.read(appStoreProvider).bypassToken();
    if (token != null) unawaited(_check(token));
    return token;
  }

  /// Drops [token] if the relay no longer honours it. Offline, it stays: the
  /// relay refuses it on use anyway.
  Future<void> _check(String token) async {
    try {
      if (await ref.read(relayApiProvider).checkBypassToken(token)) return;
    } on Object {
      return;
    }
    await revoked(token);
  }

  /// The relay refused [token]: forget it, unless another replaced it since.
  Future<void> revoked(String token) async {
    if ((await future) == token) await deactivate();
  }

  /// Redeems [code] against the relay, stores the returned bearer, and updates state.
  Future<void> activate(String code) async {
    final store = ref.read(appStoreProvider);
    final deviceId = await store.deviceId();
    final bearer = await ref
        .read(relayApiProvider)
        .redeemBypassCode(code, deviceId);
    await store.saveBypassToken(bearer);
    state = AsyncData(bearer);
  }

  /// Clears the bearer token and removes it from persistent storage.
  Future<void> deactivate() async {
    await ref.read(appStoreProvider).saveBypassToken(null);
    state = const AsyncData(null);
  }
}

/// A game an invite link asked to join (protocol/PROTOCOL.md §3.8), waiting for
/// the person to say yes or no. Home offers it once somebody is signed in.
@Riverpod(keepAlive: true)
class PendingInvite extends _$PendingInvite {
  @override
  String? build() => null;

  /// Offers the game [code]; anything that isn't a game code is ignored.
  void offer(String? code) {
    if (code != null && isGameCode(code)) state = code;
  }

  /// The code on offer, now handled (joined or turned down).
  String? take() {
    final code = state;
    state = null;
    return code;
  }
}
