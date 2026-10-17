// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'roster_entry_v3.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RosterEntryV3 _$RosterEntryV3FromJson(Map<String, dynamic> json) =>
    _RosterEntryV3(
      playerId: json['playerId'] as String,
      teamId: json['teamId'] as String,
      userId: json['userId'] as String,
      position: json['position'] as String,
      jerseyNumber: (json['jerseyNumber'] as num).toInt(),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      leftAt: json['leftAt'] == null
          ? null
          : DateTime.parse(json['leftAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$RosterEntryV3ToJson(_RosterEntryV3 instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'teamId': instance.teamId,
      'userId': instance.userId,
      'position': instance.position,
      'jerseyNumber': instance.jerseyNumber,
      'joinedAt': instance.joinedAt.toIso8601String(),
      'leftAt': instance.leftAt?.toIso8601String(),
      'metadata': instance.metadata,
    };
