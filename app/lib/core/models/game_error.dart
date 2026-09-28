import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_error.freezed.dart';
part 'game_error.g.dart';

/// An error from the relay (protocol/PROTOCOL.md §3, §4): `{code, message}`.
///
/// Failures that never reach the relay use codes defined in
/// [GameError] static constants (not part of the wire protocol).
@freezed
abstract class GameError with _$GameError implements Exception {
  const factory GameError({required String code, String? message}) = _GameError;

  factory GameError.fromJson(Map<String, dynamic> json) =>
      _$GameErrorFromJson(json);

  /// Client-local: the relay could not be reached or did not answer.
  static const connectionFailed = 'connection_failed';

  /// Client-local: an intent was sent without a joined seat.
  static const notJoined = 'not_joined';

  /// Client-local: the reply to an intent timed out.
  static const timeout = 'timeout';
}
