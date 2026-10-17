import 'package:freezed_annotation/freezed_annotation.dart';
part 'team_season_meta.freezed.dart';
part 'team_season_meta.g.dart';

@freezed
abstract class TeamSeasonMeta with _$TeamSeasonMeta {
  const factory TeamSeasonMeta({
    required String seasonId,
    required String teamId,
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    @Default(true) bool isActive,
    @Default(0) int gamesCount,
    DateTime? lastUpdated,
  }) = _TeamSeasonMeta;

  factory TeamSeasonMeta.fromJson(Map<String,dynamic> json) => _$TeamSeasonMetaFromJson(json);
}