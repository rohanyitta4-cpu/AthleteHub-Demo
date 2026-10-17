// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_game.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlayerGameStats _$PlayerGameStatsFromJson(Map<String, dynamic> json) =>
    _PlayerGameStats(
      atBats: (json['atBats'] as num?)?.toInt() ?? 0,
      runs: (json['runs'] as num?)?.toInt() ?? 0,
      hits: (json['hits'] as num?)?.toInt() ?? 0,
      doubles: (json['doubles'] as num?)?.toInt() ?? 0,
      triples: (json['triples'] as num?)?.toInt() ?? 0,
      homeRuns: (json['homeRuns'] as num?)?.toInt() ?? 0,
      walks: (json['walks'] as num?)?.toInt() ?? 0,
      hitByPitch: (json['hitByPitch'] as num?)?.toInt() ?? 0,
      strikeouts: (json['strikeouts'] as num?)?.toInt() ?? 0,
      inningsPitched: (json['inningsPitched'] as num?)?.toDouble() ?? 0.0,
      earnedRuns: (json['earnedRuns'] as num?)?.toInt() ?? 0,
      totalPitches: (json['totalPitches'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PlayerGameStatsToJson(_PlayerGameStats instance) =>
    <String, dynamic>{
      'atBats': instance.atBats,
      'runs': instance.runs,
      'hits': instance.hits,
      'doubles': instance.doubles,
      'triples': instance.triples,
      'homeRuns': instance.homeRuns,
      'walks': instance.walks,
      'hitByPitch': instance.hitByPitch,
      'strikeouts': instance.strikeouts,
      'inningsPitched': instance.inningsPitched,
      'earnedRuns': instance.earnedRuns,
      'totalPitches': instance.totalPitches,
    };

_TeamGame _$TeamGameFromJson(Map<String, dynamic> json) => _TeamGame(
  gameId: json['gameId'] as String,
  seasonId: json['seasonId'] as String,
  teamId: json['teamId'] as String,
  gameDate: DateTime.parse(json['gameDate'] as String),
  opponent: json['opponent'] as String,
  location: json['location'] as String,
  type: json['type'] as String? ?? 'regular',
  status: json['status'] as String? ?? 'completed',
  playerStats:
      (json['playerStats'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, PlayerGameStats.fromJson(e as Map<String, dynamic>)),
      ) ??
      const <String, PlayerGameStats>{},
  metadata: json['metadata'] as Map<String, dynamic>?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$TeamGameToJson(_TeamGame instance) => <String, dynamic>{
  'gameId': instance.gameId,
  'seasonId': instance.seasonId,
  'teamId': instance.teamId,
  'gameDate': instance.gameDate.toIso8601String(),
  'opponent': instance.opponent,
  'location': instance.location,
  'type': instance.type,
  'status': instance.status,
  'playerStats': instance.playerStats,
  'metadata': instance.metadata,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
