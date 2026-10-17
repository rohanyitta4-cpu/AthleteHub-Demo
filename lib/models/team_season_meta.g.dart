// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_season_meta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TeamSeasonMeta _$TeamSeasonMetaFromJson(Map<String, dynamic> json) =>
    _TeamSeasonMeta(
      seasonId: json['seasonId'] as String,
      teamId: json['teamId'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
      gamesCount: (json['gamesCount'] as num?)?.toInt() ?? 0,
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$TeamSeasonMetaToJson(_TeamSeasonMeta instance) =>
    <String, dynamic>{
      'seasonId': instance.seasonId,
      'teamId': instance.teamId,
      'name': instance.name,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'isActive': instance.isActive,
      'gamesCount': instance.gamesCount,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };
