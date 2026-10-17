// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_v3.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TeamV3 _$TeamV3FromJson(Map<String, dynamic> json) => _TeamV3(
  teamId: json['teamId'] as String,
  name: json['name'] as String,
  coachIds: (json['coachIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  playerIds:
      (json['playerIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  settings: json['settings'] as Map<String, dynamic>?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  ended: json['ended'] as bool? ?? false,
  expiresAt: json['expiresAt'] == null
      ? null
      : DateTime.parse(json['expiresAt'] as String),
);

Map<String, dynamic> _$TeamV3ToJson(_TeamV3 instance) => <String, dynamic>{
  'teamId': instance.teamId,
  'name': instance.name,
  'coachIds': instance.coachIds,
  'playerIds': instance.playerIds,
  'settings': instance.settings,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'ended': instance.ended,
  'expiresAt': instance.expiresAt?.toIso8601String(),
};
