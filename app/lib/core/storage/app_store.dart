import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// What the app keeps on the device: the signed-in account's Party
/// credentials, this install's device id, and the seat it was last in, so an
/// app that was closed mid-game can go back to it. Never a password.
class AppStore {
  static const _accountKey = 'trivia_relay.account';
  static const _deviceKey = 'trivia_relay.device_id';
  static const _seatKey = 'trivia_relay.seat';

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

  Future<SeatTicket?> seat() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_seatKey), SeatTicket.fromJson);
  }

  Future<void> saveSeat(SeatTicket? seat) async {
    final prefs = await SharedPreferences.getInstance();
    if (seat == null) {
      await prefs.remove(_seatKey);
    } else {
      await prefs.setString(_seatKey, jsonEncode(seat.toJson()));
    }
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
