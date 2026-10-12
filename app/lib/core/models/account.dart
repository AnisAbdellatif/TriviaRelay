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

    /// The name other players see in a game, when the player chose one; else
    /// they see [handle] (protocol/PROTOCOL.md §3).
    String? displayName,
  }) = _SporcleAccount;

  factory SporcleAccount.fromJson(Map<String, dynamic> json) =>
      _$SporcleAccountFromJson(json);

  /// What other players see this player as.
  String get shownName => displayName ?? handle;

  /// "The player" of a relay request body.
  Map<String, dynamic> get player => {
    'player_id': playerId,
    'token': token,
    'device_id': deviceId,
    'handle': handle,
    'name': ?displayName,
  };

  /// The same, as the headers `GET /api/packs` and `GET /api/games` take
  /// (never the URL).
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

    /// The Party Poppers Sporcle said the player had as they took the seat,
    /// when it said (protocol/PROTOCOL.md §3.5).
    int? poppers,
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

    /// Whether this player bookmarked it, or null when the relay can't say.
    bool? bookmarked,

    /// Whether this player is told when somebody hosts it, or null.
    bool? subscribed,
  }) = _PackSummary;

  factory PackSummary.fromJson(Map<String, dynamic> json) =>
      _$PackSummaryFromJson(json);
}

/// What a pack can be reported for (protocol/PROTOCOL.md §3.2), as the relay
/// names them.
enum ReportReason { harassment, offensive, spam, inaccurate, other }

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

    /// Host without playing: run the game, answer nothing (since 1.2).
    @Default(false) bool spectate,
  }) = _HostOptions;

  factory HostOptions.fromJson(Map<String, dynamic> json) =>
      _$HostOptionsFromJson(json);

  static const questionsPerGameChoices = [5, 10, 15, 20];
  static const questionSecondsChoices = [15, 30, 45, 60];
}

/// Who may find a hosted game. `anyone` lists it publicly, and strangers join
/// within seconds.
enum Audience { private, friends, anyone }
