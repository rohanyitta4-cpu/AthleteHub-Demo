import 'package:freezed_annotation/freezed_annotation.dart';

part 'game.freezed.dart';
part 'game.g.dart';

enum GameType { regular, playoff, practice }

/// Wire values use snake_case in JSON/Firestore (see game.g.dart).
enum GameStatus {
  completed,
  // ignore: constant_identifier_names — matches persisted `in_progress`
  in_progress,
  cancelled,
}

@freezed
abstract class Game with _$Game {
  const factory Game({
    required String gameId,
    required String teamId,
    required String seasonId,
    required String playerId, // The player this game belongs to
    required String userId, // User who created this entry
    required DateTime gameDate,
    required String opponent,
    required String location,
    @Default(GameType.regular) GameType type,
    @Default(GameStatus.completed) GameStatus status,

    // embedded per-game stats
    @Default(0) int atBats,
    @Default(0) int runs,
    @Default(0) int hits,
    @Default(0) int doubles,
    @Default(0) int triples,
    @Default(0) int homeRuns,
    @Default(0) int walks,
    @Default(0) int hitByPitch,
    @Default(0) int strikeouts,
    @Default(0) int sacrificeHits,
    @Default(0) int stolenBases,
    @Default(0) int runsBattedIn,
    @Default(0) int twoStrikeCounts,
    @Default(0) int successWithTwoStrikes,
    @Default(0) int earnedRuns,
    @Default(0) int totalPitches,
    @Default(0.0) double inningsPitched,

    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Game;

  factory Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);
}