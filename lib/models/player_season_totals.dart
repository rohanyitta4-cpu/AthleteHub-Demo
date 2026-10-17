import 'package:freezed_annotation/freezed_annotation.dart';
part 'player_season_totals.freezed.dart';
part 'player_season_totals.g.dart';

@freezed
abstract class PlayerSeasonTotals with _$PlayerSeasonTotals {
  const factory PlayerSeasonTotals({
    required String playerId,
    @Default(0) int games,
    @Default(0) int atBats,
    @Default(0) int hits,
    @Default(0) int runs,
    @Default(0) int rbi,
    @Default(0) int homeRuns,
    @Default(0) int walks,
    @Default(0) int strikeouts,
    @Default(0.0) double inningsPitched,
    // ...other totals
    DateTime? lastUpdated,
  }) = _PlayerSeasonTotals;

  factory PlayerSeasonTotals.fromJson(Map<String,dynamic> json) => _$PlayerSeasonTotalsFromJson(json);
}