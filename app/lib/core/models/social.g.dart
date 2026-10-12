// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Friend _$FriendFromJson(Map<String, dynamic> json) => _Friend(
  id: json['id'] as String,
  name: json['name'] as String,
  handle: json['handle'] as String?,
);

Map<String, dynamic> _$FriendToJson(_Friend instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'handle': instance.handle,
};

_PopperBalance _$PopperBalanceFromJson(Map<String, dynamic> json) =>
    _PopperBalance(
      poppers: (json['poppers'] as num?)?.toInt(),
      lastClaim: (json['last_claim'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PopperBalanceToJson(_PopperBalance instance) =>
    <String, dynamic>{
      'poppers': instance.poppers,
      'last_claim': instance.lastClaim,
    };

_AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => _AppSettings(
  sound: json['sound'] as bool? ?? true,
  haptics: json['haptics'] as bool? ?? true,
);

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{'sound': instance.sound, 'haptics': instance.haptics};
