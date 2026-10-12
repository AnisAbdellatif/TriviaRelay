// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'joinable_game.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JoinableGame _$JoinableGameFromJson(Map<String, dynamic> json) =>
    _JoinableGame(
      code: json['code'] as String,
      list:
          $enumDecodeNullable(
            _$GameListEnumMap,
            json['list'],
            unknownValue: GameList.public,
          ) ??
          GameList.public,
      pack: json['pack'] == null
          ? null
          : GamePack.fromJson(json['pack'] as Map<String, dynamic>),
      host: json['host'] as String?,
      playerCount: (json['player_count'] as num?)?.toInt(),
      stage:
          $enumDecodeNullable(
            _$GameStageEnumMap,
            json['stage'],
            unknownValue: GameStage.playing,
          ) ??
          GameStage.playing,
      questionNumber: (json['question_number'] as num?)?.toInt(),
      hasImages: json['has_images'] as bool? ?? false,
    );

Map<String, dynamic> _$JoinableGameToJson(_JoinableGame instance) =>
    <String, dynamic>{
      'code': instance.code,
      'list': _$GameListEnumMap[instance.list]!,
      'pack': instance.pack?.toJson(),
      'host': instance.host,
      'player_count': instance.playerCount,
      'stage': _$GameStageEnumMap[instance.stage]!,
      'question_number': instance.questionNumber,
      'has_images': instance.hasImages,
    };

const _$GameListEnumMap = {
  GameList.invited: 'invited',
  GameList.friends: 'friends',
  GameList.public: 'public',
};

const _$GameStageEnumMap = {
  GameStage.lobby: 'lobby',
  GameStage.question: 'question',
  GameStage.finalRound: 'final',
  GameStage.playing: 'playing',
};

_GamePack _$GamePackFromJson(Map<String, dynamic> json) => _GamePack(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String? ?? '',
  description: json['description'] as String?,
  imageUrl: json['image_url'] as String?,
);

Map<String, dynamic> _$GamePackToJson(_GamePack instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'image_url': instance.imageUrl,
};
