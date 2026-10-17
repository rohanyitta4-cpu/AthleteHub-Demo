import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_team_membership.freezed.dart';
part 'user_team_membership.g.dart';

@freezed
abstract class UserTeamMembership with _$UserTeamMembership {
  const factory UserTeamMembership({
    required String userId,
    required String teamId,
    required String teamName,
    required String role, // "coach" or "player"
    required DateTime joinedAt,
    DateTime? leftAt,
    @Default(true) bool isActive,
    @Default(false) bool isDefault, // User's default team
    Map<String, dynamic>? metadata,
  }) = _UserTeamMembership;

  factory UserTeamMembership.fromJson(Map<String, dynamic> json) => _$UserTeamMembershipFromJson(json);
}

@freezed
abstract class UserProfileV3 with _$UserProfileV3 {
  const factory UserProfileV3({
    required String userId,
    required String email,
    String? displayName,
    String? firstName,
    String? lastName,
    String? profileImageUrl,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default([]) List<UserTeamMembership> teamMemberships,
    String? defaultTeamId,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? metadata,
  }) = _UserProfileV3;

  factory UserProfileV3.fromJson(Map<String, dynamic> json) => _$UserProfileV3FromJson(json);
}