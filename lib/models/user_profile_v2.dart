import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile_v2.freezed.dart';
part 'user_profile_v2.g.dart';

enum UserRole { player, coach }

@freezed
abstract class UserProfileV2 with _$UserProfileV2 {
  const factory UserProfileV2({
    required String userId,
    required String displayName,
    required String email,
    required DateTime createdAt,
    required DateTime lastActive,
    @Default(UserRole.player) UserRole role,
    String? profileImageUrl,
    String? teamId,
    @Default({}) Map<String, dynamic> preferences,
  }) = _UserProfileV2;

  factory UserProfileV2.fromJson(Map<String, dynamic> json) => _$UserProfileV2FromJson(json);
}