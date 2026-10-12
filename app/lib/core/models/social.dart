import 'package:freezed_annotation/freezed_annotation.dart';

part 'social.freezed.dart';
part 'social.g.dart';

/// One of the player's Sporcle friends (protocol/PROTOCOL.md §3.6). [id] is
/// what an invitation takes.
@freezed
abstract class Friend with _$Friend {
  const factory Friend({
    required String id,
    required String name,
    String? handle,
  }) = _Friend;

  factory Friend.fromJson(Map<String, dynamic> json) => _$FriendFromJson(json);
}

/// What the app last heard of the player's Party Poppers (protocol/PROTOCOL.md
/// §3.5): how many, and when they last claimed the free ones (ms), each null
/// when Sporcle didn't say.
@freezed
abstract class PopperBalance with _$PopperBalance {
  const factory PopperBalance({int? poppers, int? lastClaim}) = _PopperBalance;

  factory PopperBalance.fromJson(Map<String, dynamic> json) =>
      _$PopperBalanceFromJson(json);
}

/// The app's own settings, kept on the device.
@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    /// Game sounds: a question opening, an answer locked in, right or wrong,
    /// the last seconds.
    @Default(true) bool sound,

    /// A buzz with those moments, where the device has one (Android).
    @Default(true) bool haptics,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
