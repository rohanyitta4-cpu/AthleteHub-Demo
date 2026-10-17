import 'package:freezed_annotation/freezed_annotation.dart';
part 'team_game.freezed.dart';
part 'team_game.g.dart';

@freezed
abstract class PlayerGameStats with _$PlayerGameStats {
  const factory PlayerGameStats({
    @Default(0) int atBats,
    @Default(0) int runs,
    @Default(0) int hits,
    @Default(0) int doubles,
    @Default(0) int triples,
    @Default(0) int homeRuns,
    @Default(0) int walks,
    @Default(0) int hitByPitch,
    @Default(0) int strikeouts,
    @Default(0.0) double inningsPitched,
    @Default(0) int earnedRuns,
    @Default(0) int totalPitches,
  }) = _PlayerGameStats;

  factory PlayerGameStats.fromJson(Map<String,dynamic> json) => _$PlayerGameStatsFromJson(json);
}

@freezed
abstract class TeamGame with _$TeamGame {
  const factory TeamGame({
    required String gameId,
    required String seasonId,
    required String teamId,
    required DateTime gameDate,
    required String opponent,
    required String location,
    @Default('regular') String type,
    @Default('completed') String status,
    // playerStats: map of playerId -> PlayerGameStats
    @Default(<String, PlayerGameStats>{}) Map<String, PlayerGameStats> playerStats,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TeamGame;

  factory TeamGame.fromJson(Map<String,dynamic> json) => _$TeamGameFromJson(json);
}