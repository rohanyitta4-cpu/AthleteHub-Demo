// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_v2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfileV2 _$UserProfileV2FromJson(
  Map<String, dynamic> json,
) => _UserProfileV2(
  userId: json['userId'] as String,
  displayName: json['displayName'] as String,
  email: json['email'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  lastActive: DateTime.parse(json['lastActive'] as String),
  role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']) ?? UserRole.player,
  profileImageUrl: json['profileImageUrl'] as String?,
  teamId: json['teamId'] as String?,
  preferences: json['preferences'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$UserProfileV2ToJson(_UserProfileV2 instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'displayName': instance.displayName,
      'email': instance.email,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastActive': instance.lastActive.toIso8601String(),
      'role': _$UserRoleEnumMap[instance.role]!,
      'profileImageUrl': instance.profileImageUrl,
      'teamId': instance.teamId,
      'preferences': instance.preferences,
    };

const _$UserRoleEnumMap = {UserRole.player: 'player', UserRole.coach: 'coach'};
