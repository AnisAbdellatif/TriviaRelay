import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// What the app keeps on the device: the signed-in account's Party
/// credentials, this install's device id, and the seat it was last in, so an
/// app that was closed mid-game can go back to it; the app's settings, and by
/// player the name they chose to be seen by and their last known Party
/// Poppers. Never a password.
///
/// On Android none of it is in a backup or a transfer to a new phone
/// (android/app/src/main/AndroidManifest.xml).
class AppStore {
  static const _accountKey = 'trivia_relay.account';
  static const _deviceKey = 'trivia_relay.device_id';
  static const _seatKey = 'trivia_relay.seat';
  static const _settingsKey = 'trivia_relay.settings';
  static const _namesKey = 'trivia_relay.display_names';
  static const _poppersKey = 'trivia_relay.poppers';
  static const _bypassTokenKey = 'trivia_relay.bypass_token';

  Future<SporcleAccount?> account() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_accountKey), SporcleAccount.fromJson);
  }

  Future<void> saveAccount(SporcleAccount? account) async {
    final prefs = await SharedPreferences.getInstance();
    if (account == null) {
      await prefs.remove(_accountKey);
    } else {
      await prefs.setString(_accountKey, jsonEncode(account.toJson()));
    }
  }

  /// A random 16-hex id, made once per install: what Sporcle knows this device
  /// as (protocol/PROTOCOL.md §3).
  Future<String> deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    await prefs.setString(_deviceKey, id);
    return id;
  }

  /// The seat [playerId] was last in, or null. A seat is kept with the player
  /// it belongs to and only ever handed back to that player: whoever signs in
  /// on this phone next never gets somebody else's.
  Future<SeatTicket?> seat(String? playerId) async {
    if (playerId == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final kept = _decode(prefs.getString(_seatKey), _KeptSeat.fromJson);
    return kept?.playerId == playerId ? kept?.ticket : null;
  }

  /// Keeps [seat] as [playerId]'s, or forgets the seat (either being null).
  Future<void> saveSeat(SeatTicket? seat, {String? playerId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (seat == null || playerId == null) {
      await prefs.remove(_seatKey);
    } else {
      await prefs.setString(
        _seatKey,
        jsonEncode(_KeptSeat(playerId, seat).toJson()),
      );
    }
  }

  /// The app's settings (sound, haptics), or the defaults.
  Future<AppSettings> settings() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_settingsKey), AppSettings.fromJson) ??
        const AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  /// The name [playerId] chose to be seen by, or null. Kept by player, so it
  /// outlives signing out and in again, and is nobody else's.
  Future<String?> displayName(String playerId) async =>
      (await _byPlayer(_namesKey))[playerId] as String?;

  Future<void> saveDisplayName(String playerId, String? name) =>
      _saveByPlayer(_namesKey, playerId, name);

  /// What [playerId] last heard of their Party Poppers, or null.
  Future<PopperBalance?> poppers(String playerId) async {
    final kept = (await _byPlayer(_poppersKey))[playerId];
    if (kept is! Map<String, dynamic>) return null;
    try {
      return PopperBalance.fromJson(kept);
    } on Object {
      return null;
    }
  }

  Future<void> savePoppers(String playerId, PopperBalance balance) =>
      _saveByPlayer(_poppersKey, playerId, balance.toJson());

  /// A HMAC-signed bearer token returned by the relay after redeeming a bypass
  /// code. Persists across app restarts; null means bypass is not active.
  Future<String?> bypassToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_bypassTokenKey);
  }

  Future<void> saveBypassToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_bypassTokenKey);
    } else {
      await prefs.setString(_bypassTokenKey, token);
    }
  }

  Future<Map<String, dynamic>> _byPlayer(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(key), (json) => json) ?? {};
  }

  Future<void> _saveByPlayer(String key, String playerId, Object? value) async {
    final prefs = await SharedPreferences.getInstance();
    final all = {...await _byPlayer(key)};
    if (value == null) {
      all.remove(playerId);
    } else {
      all[playerId] = value;
    }
    await prefs.setString(key, jsonEncode(all));
  }

  static T? _decode<T>(String? raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw == null) return null;
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }
}

/// A seat and whose it is, as stored. A seat stored before it had an owner
/// reads as nothing.
class _KeptSeat {
  const _KeptSeat(this.playerId, this.ticket);

  factory _KeptSeat.fromJson(Map<String, dynamic> json) => _KeptSeat(
    json['player_id'] as String,
    SeatTicket.fromJson(json['ticket'] as Map<String, dynamic>),
  );

  final String playerId;
  final SeatTicket ticket;

  Map<String, dynamic> toJson() => {
    'player_id': playerId,
    'ticket': ticket.toJson(),
  };
}
