// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_event_v3.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GameEventV3 _$GameEventV3FromJson(Map<String, dynamic> json) => _GameEventV3(
  eventId: json['eventId'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  inning: (json['inning'] as num).toInt(),
  half: json['half'] as String,
  batterId: json['batterId'] as String,
  pitcherId: json['pitcherId'] as String,
  outcome: $enumDecode(_$EventOutcomeEnumMap, json['outcome']),
  runnersBefore:
      (json['runnersBefore'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as bool),
      ) ??
      const {},
  runnersAfter:
      (json['runnersAfter'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as bool),
      ) ??
      const {},
  rbi: (json['rbi'] as num?)?.toInt() ?? 0,
  scorerId: json['scorerId'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$GameEventV3ToJson(_GameEventV3 instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'timestamp': instance.timestamp.toIso8601String(),
      'inning': instance.inning,
      'half': instance.half,
      'batterId': instance.batterId,
      'pitcherId': instance.pitcherId,
      'outcome': _$EventOutcomeEnumMap[instance.outcome]!,
      'runnersBefore': instance.runnersBefore,
      'runnersAfter': instance.runnersAfter,
      'rbi': instance.rbi,
      'scorerId': instance.scorerId,
      'metadata': instance.metadata,
    };

const _$EventOutcomeEnumMap = {
  EventOutcome.singleLeft: 'singleLeft',
  EventOutcome.singleCenter: 'singleCenter',
  EventOutcome.singleRight: 'singleRight',
  EventOutcome.doubleLeft: 'doubleLeft',
  EventOutcome.doubleCenter: 'doubleCenter',
  EventOutcome.doubleRight: 'doubleRight',
  EventOutcome.tripleLeft: 'tripleLeft',
  EventOutcome.tripleCenter: 'tripleCenter',
  EventOutcome.tripleRight: 'tripleRight',
  EventOutcome.homeRun: 'homeRun',
  EventOutcome.walk: 'walk',
  EventOutcome.hitByPitch: 'hitByPitch',
  EventOutcome.strikeout: 'strikeout',
  EventOutcome.groundout: 'groundout',
  EventOutcome.flyout: 'flyout',
  EventOutcome.sacrificeHit: 'sacrificeHit',
  EventOutcome.sacrificeFly: 'sacrificeFly',
  EventOutcome.error: 'error',
  EventOutcome.fielderChoice: 'fielderChoice',
  EventOutcome.passedBall: 'passedBall',
  EventOutcome.wildPitch: 'wildPitch',
  EventOutcome.stolenBase: 'stolenBase',
  EventOutcome.caughtStealing: 'caughtStealing',
  EventOutcome.pickoff: 'pickoff',
  EventOutcome.balk: 'balk',
};
