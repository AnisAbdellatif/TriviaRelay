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

    /// Something to tell the player for a moment (since 1.2).
    Notice? notice,

    /// The count down before the open question shows (since 1.2).
    StartCountdown? countdown,

    /// The lobby's pack votes, the most voted first (since 1.2).
    @Default(<PackVote>[]) List<PackVote> packVotes,

    /// The game's chat (since 1.2).
    @Default(ChatState()) ChatState chat,

    /// Reactions other players sent this one, while they show (since 1.2).
    @Default(<Reaction>[]) List<Reaction> reactions,
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

  /// Players by score, highest first; ties keep seat order. A spectating
  /// host comes last, as in the official app: they aren't playing.
  List<PlayerView> get standings {
    final sorted = [...players];
    sorted.sort((a, b) {
      if (a.spectating != b.spectating) return a.spectating ? 1 : -1;
      return b.score.compareTo(a.score);
    });
    return sorted;
  }

  /// Everybody playing: not a spectating host.
  List<PlayerView> get playing => [
    for (final p in players)
      if (!p.spectating) p,
  ];
}

/// The rules both sides share (protocol/fixtures/constants.json).
abstract final class GameRules {
  /// The longest answer, as the official app's field takes it.
  static const answerMaxLength = 80;

  /// How many packs one player may vote for in a game.
  static const maxPackVotes = 5;

  /// The count down before the game's first question, and before the final.
  static const startCountdownMs = 5000;
  static const finalCountdownMs = 3000;

  /// The longest chat message, as the official app's field takes it.
  static const chatMaxLength = 256;

  /// The reactions this app may send: the free one, the goose (the honk).
  static const reactionTypes = ['goose'];

  /// Every reaction sound a player may receive, each with a sound of this
  /// app's own (scripts/make_sounds.py).
  static const reactionSounds = [
    'goose',
    'cow',
    'donkey',
    'goat',
    'rooster',
    'sheep',
    'soccer_cheer',
    'aww',
    'clap',
    'ooh',
    'laugh',
    'accordion',
    'rim_shot',
    'trombone',
    'trumpet',
    'tuba',
  ];

  /// At most one reaction sent in this long.
  static const reactionGapMs = 2000;

  /// How long a received reaction shows.
  static const reactionMs = 4000;

  /// Why a question may be reported, as the relay takes them, with their
  /// words.
  static const reportReasons = {
    'inaccurate': 'Inaccurate',
    'typo': 'Typo or spelling',
    'offensive': 'Offensive content',
  };
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

    /// They asked to play again, on the final scores (since 1.2).
    @Default(false) bool readyForNextGame,

    /// Watching, not playing: a host who hosts as a spectator (since 1.2).
    @Default(false) bool spectating,
    @Default(0) int score,
    @Default(false) bool answered,

    /// Their answer to the open question, once you have answered it yourself.
    String? guess,
    @Default(false) bool finalWagered,

    /// The reactions they have had this game (since 1.2).
    @Default(PlayerReactions()) PlayerReactions reactions,
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

    /// Hosting without playing (since 1.2): no answers, votes or wagers.
    @Default(false) bool spectating,

    /// Whether the question on screen may be rated and reported now: once
    /// answered, and while revealed (since 1.2).
    @Default(false) bool canRate,

    /// This player's thumb on it: 1 up, -1 down, 0 none (since 1.2).
    @Default(0) int rating,

    /// This player reported it (since 1.2).
    @Default(false) bool reported,

    /// The Party Poppers this player has, as far as the seat knows: what
    /// Sporcle said as they took it, less any spent since (since 1.2).
    int? poppers,
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

    /// The next game's code, when it started without this player: Play Again
    /// joins it (since 1.2).
    String? nextGameCode,
    int? wager,
    @Default(<FinalWager>[]) List<FinalWager> wagers,
  }) = _FinalRound;

  factory FinalRound.fromJson(Map<String, dynamic> json) =>
      _$FinalRoundFromJson(json);

  /// What the final question can be voted to be, easiest first.
  static const voteChoices = ['easy', 'medium', 'hard'];
}

/// Something to tell the player for a moment, shown as a banner until
/// [until] (protocol/PROTOCOL.md §5.1; since 1.2). [title] and [message] are
/// the game's own words, sent with a `server` notice; the app words the rest.
@freezed
abstract class Notice with _$Notice {
  const factory Notice({
    required String kind,

    /// `info`, `warn`, `error` or `success`.
    @Default('info') String level,
    String? title,
    String? message,
    required int until,
  }) = _Notice;

  factory Notice.fromJson(Map<String, dynamic> json) => _$NoticeFromJson(json);

  /// The host sent everyone back to the lobby.
  static const toLobby = 'to_lobby';

  /// The host handed the game to this player.
  static const promoted = 'promoted';

  /// The host left, and the game is this player's to run now.
  static const hostLeft = 'host_left';

  /// Joining this game with pictures cost the player a Party Popper.
  static const popperSpent = 'popper_spent';

  /// A message from the game itself, in [title] and [message].
  static const server = 'server';
}

/// The count down before a question shows, on every phone at once: the
/// game's start ([start]) or the final question ([finalQuestion]). The
/// question's clock starts at [until] (protocol/PROTOCOL.md §5.1; since 1.2).
@freezed
abstract class StartCountdown with _$StartCountdown {
  const factory StartCountdown({required String kind, required int until}) =
      _StartCountdown;

  factory StartCountdown.fromJson(Map<String, dynamic> json) =>
      _$StartCountdownFromJson(json);

  static const start = 'start';
  static const finalQuestion = 'final';
}

/// A pack players voted for in the lobby (since 1.2).
@freezed
abstract class PackVote with _$PackVote {
  const factory PackVote({
    required Pack pack,
    @Default(0) int votes,
    @Default(<int>[]) List<int> voters,

    /// This player voted for it.
    @Default(false) bool you,
  }) = _PackVote;

  factory PackVote.fromJson(Map<String, dynamic> json) =>
      _$PackVoteFromJson(json);
}

@freezed
abstract class FinalWager with _$FinalWager {
  const factory FinalWager({required int peerId, required int wager}) =
      _FinalWager;

  factory FinalWager.fromJson(Map<String, dynamic> json) =>
      _$FinalWagerFromJson(json);
}

/// The reactions a player has had this game: how many, and the latest few
/// sounds (since 1.2).
@freezed
abstract class PlayerReactions with _$PlayerReactions {
  const factory PlayerReactions({
    @Default(0) int total,
    @Default(<String>[]) List<String> recent,
  }) = _PlayerReactions;

  factory PlayerReactions.fromJson(Map<String, dynamic> json) =>
      _$PlayerReactionsFromJson(json);
}

/// A sound another player sent this one, shown until [until]
/// (protocol/PROTOCOL.md §6.7; since 1.2). [id] grows with each, so each plays
/// once.
@freezed
abstract class Reaction with _$Reaction {
  const factory Reaction({
    required int id,
    int? peerId,
    required String type,
    required int until,
  }) = _Reaction;

  factory Reaction.fromJson(Map<String, dynamic> json) =>
      _$ReactionFromJson(json);
}

/// The game's chat as the relay keeps it (protocol/PROTOCOL.md §6.6; since
/// 1.2): the latest messages, oldest first.
@freezed
abstract class ChatState with _$ChatState {
  const ChatState._();

  const factory ChatState({
    @Default(<ChatMessage>[]) List<ChatMessage> messages,

    /// Other players' messages since the chat was last open.
    @Default(0) int unread,

    /// The names of the others typing.
    @Default(<String>[]) List<String> typing,

    /// An app joined to the seat shows the chat.
    @Default(false) bool open,

    /// There is more before the first message.
    @Default(false) bool hasMore,

    /// The relay is fetching earlier messages.
    @Default(false) bool loading,
  }) = _ChatState;

  factory ChatState.fromJson(Map<String, dynamic> json) =>
      _$ChatStateFromJson(json);
}

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,

    /// The sender, while they are in the game.
    int? peerId,

    /// The name the message carries; null for the game's own.
    String? name,
    @Default('') String text,
    String? imageUrl,

    /// The game's own message, not a player's.
    @Default(false) bool system,
    @Default(0) int at,

    /// This player's.
    @Default(false) bool own,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
