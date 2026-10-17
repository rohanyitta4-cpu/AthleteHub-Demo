// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'roster_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RosterEntry _$RosterEntryFromJson(Map<String, dynamic> json) => _RosterEntry(
  playerId: json['playerId'] as String,
  role: json['role'] as String?,
  jerseyNumber: (json['jerseyNumber'] as num?)?.toInt(),
  addedAt: json['addedAt'] == null
      ? null
      : DateTime.parse(json['addedAt'] as String),
);

Map<String, dynamic> _$RosterEntryToJson(_RosterEntry instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'role': instance.role,
      'jerseyNumber': instance.jerseyNumber,
      'addedAt': instance.addedAt?.toIso8601String(),
    };
