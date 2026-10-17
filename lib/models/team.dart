import 'package:freezed_annotation/freezed_annotation.dart';
part 'team.freezed.dart';
part 'team.g.dart';

@freezed
abstract class Team with _$Team {
  const factory Team({
    required String teamId,
    required String name,
    required List<String> coachIds,  // user ids
    @Default(<String>[]) List<String> playerIds,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Team;

  factory Team.fromJson(Map<String,dynamic> json) => _$TeamFromJson(json);
}
