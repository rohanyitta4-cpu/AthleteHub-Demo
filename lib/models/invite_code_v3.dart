import 'package:freezed_annotation/freezed_annotation.dart';

part 'invite_code_v3.freezed.dart';
part 'invite_code_v3.g.dart';

enum InviteRole { player, coach, fan }

@freezed
abstract class InviteCodeV3 with _$InviteCodeV3 {
  const factory InviteCodeV3({
    required String code,
    required String teamId,
    required InviteRole role,
    required DateTime expiresAt,
    @Default(true) bool active,
    @Default(0) int uses,
    @Default(0) int maxUses,
    required DateTime createdAt,
    String? createdBy, // user ID
    Map<String, dynamic>? metadata,
  }) = _InviteCodeV3;

  factory InviteCodeV3.fromJson(Map<String, dynamic> json) => _$InviteCodeV3FromJson(json);
}

