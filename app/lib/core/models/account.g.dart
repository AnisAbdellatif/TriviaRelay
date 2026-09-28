// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SporcleAccount _$SporcleAccountFromJson(Map<String, dynamic> json) =>
    _SporcleAccount(
      playerId: json['player_id'] as String,
      token: json['token'] as String,
      handle: json['handle'] as String,
      deviceId: json['device_id'] as String,
    );

Map<String, dynamic> _$SporcleAccountToJson(_SporcleAccount instance) =>
    <String, dynamic>{
      'player_id': instance.playerId,
      'token': instance.token,
      'handle': instance.handle,
      'device_id': instance.deviceId,
    };

_SeatTicket _$SeatTicketFromJson(Map<String, dynamic> json) => _SeatTicket(
  seatId: json['seat_id'] as String,
  seatToken: json['seat_token'] as String,
  gameCode: json['game_code'] as String,
);

Map<String, dynamic> _$SeatTicketToJson(_SeatTicket instance) =>
    <String, dynamic>{
      'seat_id': instance.seatId,
      'seat_token': instance.seatToken,
      'game_code': instance.gameCode,
    };

_PackSummary _$PackSummaryFromJson(Map<String, dynamic> json) => _PackSummary(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String?,
  imageUrl: json['image_url'] as String?,
  numQuestions: (json['num_questions'] as num?)?.toInt(),
  hasImages: json['has_images'] as bool? ?? false,
  playCount: (json['play_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$PackSummaryToJson(_PackSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'image_url': instance.imageUrl,
      'num_questions': instance.numQuestions,
      'has_images': instance.hasImages,
      'play_count': instance.playCount,
    };

_HostOptions _$HostOptionsFromJson(Map<String, dynamic> json) => _HostOptions(
  questionsPerGame: (json['questions_per_game'] as num?)?.toInt() ?? 10,
  questionSeconds: (json['question_seconds'] as num?)?.toInt() ?? 30,
  audience:
      $enumDecodeNullable(_$AudienceEnumMap, json['audience']) ??
      Audience.private,
);

Map<String, dynamic> _$HostOptionsToJson(_HostOptions instance) =>
    <String, dynamic>{
      'questions_per_game': instance.questionsPerGame,
      'question_seconds': instance.questionSeconds,
      'audience': _$AudienceEnumMap[instance.audience]!,
    };

const _$AudienceEnumMap = {
  Audience.private: 'private',
  Audience.friends: 'friends',
  Audience.anyone: 'anyone',
};
