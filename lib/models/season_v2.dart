import 'package:freezed_annotation/freezed_annotation.dart';

part 'season_v2.freezed.dart';
part 'season_v2.g.dart';

enum SeasonType { regular, playoffs, practice }

@freezed
abstract class SeasonV2 with _$SeasonV2 {
  const factory SeasonV2({
    required String seasonId,
    required String userId,
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    @Default(true) bool isActive,
    @Default(SeasonType.regular) SeasonType type,
    @Default({}) Map<String, dynamic> settings,
  }) = _SeasonV2;

  const SeasonV2._();

  // Getter for total games (placeholder - would need to be calculated from actual games)
  int get totalGames => 0; // This would be calculated from actual game data

  factory SeasonV2.fromJson(Map<String, dynamic> json) => _$SeasonV2FromJson(json);
}