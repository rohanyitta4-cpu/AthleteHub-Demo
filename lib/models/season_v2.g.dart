// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season_v2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SeasonV2 _$SeasonV2FromJson(Map<String, dynamic> json) => _SeasonV2(
  seasonId: json['seasonId'] as String,
  userId: json['userId'] as String,
  name: json['name'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: json['endDate'] == null
      ? null
      : DateTime.parse(json['endDate'] as String),
  isActive: json['isActive'] as bool? ?? true,
  type:
      $enumDecodeNullable(_$SeasonTypeEnumMap, json['type']) ??
      SeasonType.regular,
  settings: json['settings'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$SeasonV2ToJson(_SeasonV2 instance) => <String, dynamic>{
  'seasonId': instance.seasonId,
  'userId': instance.userId,
  'name': instance.name,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate?.toIso8601String(),
  'isActive': instance.isActive,
  'type': _$SeasonTypeEnumMap[instance.type]!,
  'settings': instance.settings,
};

const _$SeasonTypeEnumMap = {
  SeasonType.regular: 'regular',
  SeasonType.playoffs: 'playoffs',
  SeasonType.practice: 'practice',
};
