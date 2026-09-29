import 'package:freezed_annotation/freezed_annotation.dart';

part 'joinable_game.freezed.dart';
part 'joinable_game.g.dart';

/// Why a game is listed for this player (protocol/PROTOCOL.md §3.4), in the
/// order the lists are shown.
enum GameList { invited, friends, public }

/// Where a listed game is. A stage this app doesn't know reads as [playing].
enum GameStage {
  lobby,
  question,
  @JsonValue('final')
  finalRound,
  playing,
}

/// A game the player could join (protocol/PROTOCOL.md §3.4); joining it is
/// joining its [code].
@freezed
abstract class JoinableGame with _$JoinableGame {
  const JoinableGame._();

  const factory JoinableGame({
    required String code,
    @JsonKey(unknownEnumValue: GameList.public)
    @Default(GameList.public)
    GameList list,
    GamePack? pack,
    String? host,
    int? playerCount,
    @JsonKey(unknownEnumValue: GameStage.playing)
    @Default(GameStage.playing)
    GameStage stage,
    int? questionNumber,
    @Default(false) bool hasImages,
  }) = _JoinableGame;

  factory JoinableGame.fromJson(Map<String, dynamic> json) =>
      _$JoinableGameFromJson(json);

  bool get inLobby => stage == GameStage.lobby;
}

/// The pack a listed game is playing.
@freezed
abstract class GamePack with _$GamePack {
  const factory GamePack({
    int? id,
    @Default('') String name,
    String? description,
    String? imageUrl,
  }) = _GamePack;

  factory GamePack.fromJson(Map<String, dynamic> json) =>
      _$GamePackFromJson(json);
}
