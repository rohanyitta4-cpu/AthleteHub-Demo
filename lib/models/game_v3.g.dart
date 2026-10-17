// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_v3.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GameV3 _$GameV3FromJson(Map<String, dynamic> json) => _GameV3(
  gameId: json['gameId'] as String,
  teamHome: json['teamHome'] as String,
  teamAway: json['teamAway'] as String,
  date: DateTime.parse(json['date'] as String),
  state:
      $enumDecodeNullable(_$GameStateEnumMap, json['state']) ??
      GameState.scheduled,
  inning: (json['inning'] as num?)?.toInt() ?? 1,
  half: json['half'] as String? ?? 'top',
  outs: (json['outs'] as num?)?.toInt() ?? 0,
  runners:
      (json['runners'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as bool),
      ) ??
      const {},
  score:
      (json['score'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const {},
  lineupHome:
      (json['lineupHome'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  lineupAway:
      (json['lineupAway'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  events:
      (json['events'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  metadata: json['metadata'] as Map<String, dynamic>?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$GameV3ToJson(_GameV3 instance) => <String, dynamic>{
  'gameId': instance.gameId,
  'teamHome': instance.teamHome,
  'teamAway': instance.teamAway,
  'date': instance.date.toIso8601String(),
  'state': _$GameStateEnumMap[instance.state]!,
  'inning': instance.inning,
  'half': instance.half,
  'outs': instance.outs,
  'runners': instance.runners,
  'score': instance.score,
  'lineupHome': instance.lineupHome,
  'lineupAway': instance.lineupAway,
  'events': instance.events,
  'metadata': instance.metadata,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$GameStateEnumMap = {
  GameState.scheduled: 'scheduled',
  GameState.inProgress: 'inProgress',
  GameState.completed: 'completed',
  GameState.cancelled: 'cancelled',
};
