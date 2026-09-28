import 'package:freezed_annotation/freezed_annotation.dart';

part 'seat_state.freezed.dart';
part 'seat_state.g.dart';

/// Whether the relay is in the Sporcle game for this seat
/// (protocol/PROTOCOL.md §5.1).
@JsonEnum(fieldRename: FieldRename.snake)
enum SeatStatus {
  connecting,
  live,

  /// The relay's own connection to the game failed.
  lost,

  /// The host removed the player.
  removed,
}

/// Where the game is (protocol/PROTOCOL.md §6.1).
@JsonEnum(fieldRename: FieldRename.snake)
enum Phase {
  lobby,
  question,
  reveal,
  finalVote,
  finalWager,
  finalQuestion,
  finalReveal,
  finalScores;

  bool get isOpenQuestion => this == question || this == finalQuestion;
  bool get isReveal => this == reveal || this == finalReveal;
  bool get isFinal => index >= finalVote.index;
}

/// The whole of what the relay knows about this seat's game: a complete
/// snapshot every time, never a delta (protocol/PROTOCOL.md §5.1).
@freezed
abstract class SeatState with _$SeatState {
  const SeatState._();

  const factory SeatState({
    required int protocolVersion,
    @Default(0) int protocolMinor,
    required int serverTime,
    required String gameCode,
    required SeatStatus status,
    required Phase phase,
    Pack? pack,
    required GameOptions options,
    @Default(<RoundInfo>[]) List<RoundInfo> rounds,
    Question? question,
    int? deadline,
    @Default(<PlayerView>[]) List<PlayerView> players,
    required You you,
    Reveal? reveal,
    @JsonKey(name: 'final') FinalRound? finalRound,
  }) = _SeatState;

  factory SeatState.fromJson(Map<String, dynamic> json) =>
      _$SeatStateFromJson(json);

  PlayerView? player(int? peerId) {
    for (final p in players) {
      if (p.peerId == peerId) return p;
    }
    return null;
  }

  PlayerView? get me => player(you.peerId);

  /// Players by score, highest first; ties keep seat order.
  List<PlayerView> get standings {
    final sorted = [...players];
    sorted.sort((a, b) => b.score.compareTo(a.score));
    return sorted;
  }
}

@freezed
abstract class Pack with _$Pack {
  const factory Pack({
    required int id,
    required String name,
    String? description,
    String? imageUrl,
    int? numQuestions,
    @Default(false) bool hasImages,
  }) = _Pack;

  factory Pack.fromJson(Map<String, dynamic> json) => _$PackFromJson(json);
}

@freezed
abstract class GameOptions with _$GameOptions {
  const factory GameOptions({
    required int questionsPerGame,
    required int questionSeconds,
  }) = _GameOptions;

  factory GameOptions.fromJson(Map<String, dynamic> json) =>
      _$GameOptionsFromJson(json);
}

@freezed
abstract class RoundInfo with _$RoundInfo {
  const factory RoundInfo({required int index, int? percent}) = _RoundInfo;

  factory RoundInfo.fromJson(Map<String, dynamic> json) =>
      _$RoundInfoFromJson(json);
}

@freezed
abstract class Question with _$Question {
  const factory Question({
    required int index,
    required String text,
    String? category,
    String? difficulty,
    String? imageUrl,
    @Default(false) bool isFinal,
  }) = _Question;

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(_final(json));
}

// `final` is a Dart keyword, so the wire's `final` flag is read as `is_final`.
Map<String, dynamic> _final(Map<String, dynamic> json) =>
    json.containsKey('final') ? {...json, 'is_final': json['final']} : json;

@freezed
abstract class PlayerView with _$PlayerView {
  const factory PlayerView({
    required int peerId,
    required String name,
    @Default(false) bool host,
    @Default(true) bool connected,
    @Default(false) bool ready,
    @Default(0) int score,
    @Default(false) bool answered,

    /// Their answer to the open question, once you have answered it yourself.
    String? guess,
    @Default(false) bool finalWagered,
  }) = _PlayerView;

  factory PlayerView.fromJson(Map<String, dynamic> json) =>
      _$PlayerViewFromJson(json);
}

@freezed
abstract class You with _$You {
  const factory You({
    int? peerId,
    @Default(false) bool host,

    /// Whether the host may reveal the open question (a relay before 1.1
    /// doesn't say, and allowed it any time).
    @Default(true) bool canReveal,
    OwnAnswer? answer,
    @Default(<int>[]) List<int> wagerChoices,
    @Default(<String, bool>{}) Map<String, bool> judgements,
    @Default(false) bool judged,

    /// This player asked to play again; the host's asking starts the next game.
    @Default(false) bool playedAgain,
  }) = _You;

  factory You.fromJson(Map<String, dynamic> json) => _$YouFromJson(json);
}

@freezed
abstract class OwnAnswer with _$OwnAnswer {
  const factory OwnAnswer({required String text, required int wager}) =
      _OwnAnswer;

  factory OwnAnswer.fromJson(Map<String, dynamic> json) =>
      _$OwnAnswerFromJson(json);
}

@freezed
abstract class Reveal with _$Reveal {
  const factory Reveal({
    String? answer,
    @Default(<RevealAnswer>[]) List<RevealAnswer> answers,
  }) = _Reveal;

  factory Reveal.fromJson(Map<String, dynamic> json) => _$RevealFromJson(json);
}

@freezed
abstract class RevealAnswer with _$RevealAnswer {
  const factory RevealAnswer({
    required int peerId,
    String? text,
    @Default(0) int wager,
    @Default(false) bool correct,
    int? score,
  }) = _RevealAnswer;

  factory RevealAnswer.fromJson(Map<String, dynamic> json) =>
      _$RevealAnswerFromJson(json);
}

@freezed
abstract class FinalRound with _$FinalRound {
  const factory FinalRound({
    @Default(<String, int>{}) Map<String, int> votes,
    String? picked,
    String? vote,
    int? wager,
    @Default(<FinalWager>[]) List<FinalWager> wagers,
  }) = _FinalRound;

  factory FinalRound.fromJson(Map<String, dynamic> json) =>
      _$FinalRoundFromJson(json);

  /// What the final question can be voted to be, easiest first.
  static const voteChoices = ['easy', 'medium', 'hard'];
}

@freezed
abstract class FinalWager with _$FinalWager {
  const factory FinalWager({required int peerId, required int wager}) =
      _FinalWager;

  factory FinalWager.fromJson(Map<String, dynamic> json) =>
      _$FinalWagerFromJson(json);
}
