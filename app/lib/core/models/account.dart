import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';
part 'account.g.dart';

/// A signed-in Sporcle player: the Party credentials a login returns, and the
/// device id this install made for itself (protocol/PROTOCOL.md §3).
///
/// The password is never part of this, or of anything the app keeps.
@freezed
abstract class SporcleAccount with _$SporcleAccount {
  const SporcleAccount._();

  const factory SporcleAccount({
    required String playerId,
    required String token,
    required String handle,
    required String deviceId,
  }) = _SporcleAccount;

  factory SporcleAccount.fromJson(Map<String, dynamic> json) =>
      _$SporcleAccountFromJson(json);

  /// "The player" of a relay request body.
  Map<String, dynamic> get player => {
    'player_id': playerId,
    'token': token,
    'device_id': deviceId,
    'handle': handle,
  };

  /// The same, as the headers `GET /api/packs` takes (never the URL).
  Map<String, String> get headers => {
    'x-player-id': playerId,
    'x-player-token': token,
    'x-device-id': deviceId,
    'x-player-handle': handle,
  };
}

/// A seat the relay holds (protocol/PROTOCOL.md §3.3): what joining its channel
/// takes, again on every reconnect.
@freezed
abstract class SeatTicket with _$SeatTicket {
  const factory SeatTicket({
    required String seatId,
    required String seatToken,
    required String gameCode,
  }) = _SeatTicket;

  factory SeatTicket.fromJson(Map<String, dynamic> json) =>
      _$SeatTicketFromJson(json);
}

/// A pack in search results (protocol/PROTOCOL.md §3.2).
@freezed
abstract class PackSummary with _$PackSummary {
  const factory PackSummary({
    required int id,
    required String name,
    String? description,
    String? imageUrl,
    int? numQuestions,
    @Default(false) bool hasImages,
    int? playCount,
  }) = _PackSummary;

  factory PackSummary.fromJson(Map<String, dynamic> json) =>
      _$PackSummaryFromJson(json);
}

/// The lists of Sporcle's catalog a host can browse (protocol/PROTOCOL.md
/// §3.2), in the order they're offered. The names are the relay's.
enum PackList {
  popular,
  fresh,
  bookmarked,
  created,
  friends,
  purchased,
  free,
  all,
}

/// What a host chooses for a new game. Each value is one the relay allows
/// (protocol/fixtures/constants.json).
@freezed
abstract class HostOptions with _$HostOptions {
  const factory HostOptions({
    @Default(10) int questionsPerGame,
    @Default(30) int questionSeconds,
    @Default(Audience.private) Audience audience,
  }) = _HostOptions;

  factory HostOptions.fromJson(Map<String, dynamic> json) =>
      _$HostOptionsFromJson(json);

  static const questionsPerGameChoices = [5, 10, 15, 20];
  static const questionSecondsChoices = [15, 30, 45, 60];
}

/// Who may find a hosted game. `anyone` lists it publicly, and strangers join
/// within seconds.
enum Audience { private, friends, anyone }
