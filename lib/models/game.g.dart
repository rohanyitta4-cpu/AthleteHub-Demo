// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Game _$GameFromJson(Map<String, dynamic> json) => _Game(
  gameId: json['gameId'] as String,
  teamId: json['teamId'] as String,
  seasonId: json['seasonId'] as String,
  playerId: json['playerId'] as String,
  userId: json['userId'] as String,
  gameDate: DateTime.parse(json['gameDate'] as String),
  opponent: json['opponent'] as String,
  location: json['location'] as String,
  type:
      $enumDecodeNullable(_$GameTypeEnumMap, json['type']) ?? GameType.regular,
  status:
      $enumDecodeNullable(_$GameStatusEnumMap, json['status']) ??
      GameStatus.completed,
  atBats: (json['atBats'] as num?)?.toInt() ?? 0,
  runs: (json['runs'] as num?)?.toInt() ?? 0,
  hits: (json['hits'] as num?)?.toInt() ?? 0,
  doubles: (json['doubles'] as num?)?.toInt() ?? 0,
  triples: (json['triples'] as num?)?.toInt() ?? 0,
  homeRuns: (json['homeRuns'] as num?)?.toInt() ?? 0,
  walks: (json['walks'] as num?)?.toInt() ?? 0,
  hitByPitch: (json['hitByPitch'] as num?)?.toInt() ?? 0,
  strikeouts: (json['strikeouts'] as num?)?.toInt() ?? 0,
  sacrificeHits: (json['sacrificeHits'] as num?)?.toInt() ?? 0,
  stolenBases: (json['stolenBases'] as num?)?.toInt() ?? 0,
  runsBattedIn: (json['runsBattedIn'] as num?)?.toInt() ?? 0,
  twoStrikeCounts: (json['twoStrikeCounts'] as num?)?.toInt() ?? 0,
  successWithTwoStrikes: (json['successWithTwoStrikes'] as num?)?.toInt() ?? 0,
  earnedRuns: (json['earnedRuns'] as num?)?.toInt() ?? 0,
  totalPitches: (json['totalPitches'] as num?)?.toInt() ?? 0,
  inningsPitched: (json['inningsPitched'] as num?)?.toDouble() ?? 0.0,
  metadata: json['metadata'] as Map<String, dynamic>?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$GameToJson(_Game instance) => <String, dynamic>{
  'gameId': instance.gameId,
  'teamId': instance.teamId,
  'seasonId': instance.seasonId,
  'playerId': instance.playerId,
  'userId': instance.userId,
  'gameDate': instance.gameDate.toIso8601String(),
  'opponent': instance.opponent,
  'location': instance.location,
  'type': _$GameTypeEnumMap[instance.type]!,
  'status': _$GameStatusEnumMap[instance.status]!,
  'atBats': instance.atBats,
  'runs': instance.runs,
  'hits': instance.hits,
  'doubles': instance.doubles,
  'triples': instance.triples,
  'homeRuns': instance.homeRuns,
  'walks': instance.walks,
  'hitByPitch': instance.hitByPitch,
  'strikeouts': instance.strikeouts,
  'sacrificeHits': instance.sacrificeHits,
  'stolenBases': instance.stolenBases,
  'runsBattedIn': instance.runsBattedIn,
  'twoStrikeCounts': instance.twoStrikeCounts,
  'successWithTwoStrikes': instance.successWithTwoStrikes,
  'earnedRuns': instance.earnedRuns,
  'totalPitches': instance.totalPitches,
  'inningsPitched': instance.inningsPitched,
  'metadata': instance.metadata,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$GameTypeEnumMap = {
  GameType.regular: 'regular',
  GameType.playoff: 'playoff',
  GameType.practice: 'practice',
};

const _$GameStatusEnumMap = {
  GameStatus.completed: 'completed',
  GameStatus.in_progress: 'in_progress',
  GameStatus.cancelled: 'cancelled',
};
