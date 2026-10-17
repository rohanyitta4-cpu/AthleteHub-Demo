// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_season_totals.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlayerSeasonTotals _$PlayerSeasonTotalsFromJson(Map<String, dynamic> json) =>
    _PlayerSeasonTotals(
      playerId: json['playerId'] as String,
      games: (json['games'] as num?)?.toInt() ?? 0,
      atBats: (json['atBats'] as num?)?.toInt() ?? 0,
      hits: (json['hits'] as num?)?.toInt() ?? 0,
      runs: (json['runs'] as num?)?.toInt() ?? 0,
      rbi: (json['rbi'] as num?)?.toInt() ?? 0,
      homeRuns: (json['homeRuns'] as num?)?.toInt() ?? 0,
      walks: (json['walks'] as num?)?.toInt() ?? 0,
      strikeouts: (json['strikeouts'] as num?)?.toInt() ?? 0,
      inningsPitched: (json['inningsPitched'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$PlayerSeasonTotalsToJson(_PlayerSeasonTotals instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'games': instance.games,
      'atBats': instance.atBats,
      'hits': instance.hits,
      'runs': instance.runs,
      'rbi': instance.rbi,
      'homeRuns': instance.homeRuns,
      'walks': instance.walks,
      'strikeouts': instance.strikeouts,
      'inningsPitched': instance.inningsPitched,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };
