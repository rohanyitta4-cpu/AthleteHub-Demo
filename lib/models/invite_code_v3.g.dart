// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_code_v3.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InviteCodeV3 _$InviteCodeV3FromJson(Map<String, dynamic> json) =>
    _InviteCodeV3(
      code: json['code'] as String,
      teamId: json['teamId'] as String,
      role: $enumDecode(_$InviteRoleEnumMap, json['role']),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      active: json['active'] as bool? ?? true,
      uses: (json['uses'] as num?)?.toInt() ?? 0,
      maxUses: (json['maxUses'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$InviteCodeV3ToJson(_InviteCodeV3 instance) =>
    <String, dynamic>{
      'code': instance.code,
      'teamId': instance.teamId,
      'role': _$InviteRoleEnumMap[instance.role]!,
      'expiresAt': instance.expiresAt.toIso8601String(),
      'active': instance.active,
      'uses': instance.uses,
      'maxUses': instance.maxUses,
      'createdAt': instance.createdAt.toIso8601String(),
      'createdBy': instance.createdBy,
      'metadata': instance.metadata,
    };

const _$InviteRoleEnumMap = {
  InviteRole.player: 'player',
  InviteRole.coach: 'coach',
  InviteRole.fan: 'fan',
};
