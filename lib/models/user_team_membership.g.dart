// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_team_membership.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserTeamMembership _$UserTeamMembershipFromJson(Map<String, dynamic> json) =>
    _UserTeamMembership(
      userId: json['userId'] as String,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      leftAt: json['leftAt'] == null
          ? null
          : DateTime.parse(json['leftAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      isDefault: json['isDefault'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$UserTeamMembershipToJson(_UserTeamMembership instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'teamId': instance.teamId,
      'teamName': instance.teamName,
      'role': instance.role,
      'joinedAt': instance.joinedAt.toIso8601String(),
      'leftAt': instance.leftAt?.toIso8601String(),
      'isActive': instance.isActive,
      'isDefault': instance.isDefault,
      'metadata': instance.metadata,
    };

_UserProfileV3 _$UserProfileV3FromJson(Map<String, dynamic> json) =>
    _UserProfileV3(
      userId: json['userId'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      teamMemberships:
          (json['teamMemberships'] as List<dynamic>?)
              ?.map(
                (e) => UserTeamMembership.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      defaultTeamId: json['defaultTeamId'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$UserProfileV3ToJson(_UserProfileV3 instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'email': instance.email,
      'displayName': instance.displayName,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'profileImageUrl': instance.profileImageUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'teamMemberships': instance.teamMemberships,
      'defaultTeamId': instance.defaultTeamId,
      'preferences': instance.preferences,
      'metadata': instance.metadata,
    };
