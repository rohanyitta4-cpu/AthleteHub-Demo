import 'package:freezed_annotation/freezed_annotation.dart';

part 'team_v3.freezed.dart';
part 'team_v3.g.dart';

@freezed
abstract class TeamV3 with _$TeamV3 {
  const factory TeamV3({
    required String teamId,
    required String name,
    required List<String> coachIds, // user ids
    @Default(<String>[]) List<String> playerIds,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool ended,
    DateTime? expiresAt,
  }) = _TeamV3;

  factory TeamV3.fromJson(Map<String, dynamic> json) => _$TeamV3FromJson(json);
}

