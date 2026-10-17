import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_v3.freezed.dart';
part 'game_v3.g.dart';

enum GameState { scheduled, inProgress, completed, cancelled }

@freezed
abstract class GameV3 with _$GameV3 {
  const factory GameV3({
    required String gameId,
    required String teamHome,
    required String teamAway,
    required DateTime date,
    @Default(GameState.scheduled) GameState state,
    @Default(1) int inning,
    @Default('top') String half, // 'top' or 'bottom'
    @Default(0) int outs,
    @Default({}) Map<String, bool> runners, // {'1st': false, '2nd': false, '3rd': false}
    @Default({}) Map<String, int> score, // {'home': 0, 'away': 0}
    @Default([]) List<String> lineupHome, // player IDs
    @Default([]) List<String> lineupAway, // player IDs
    @Default([]) List<String> events, // event IDs
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _GameV3;

  factory GameV3.fromJson(Map<String, dynamic> json) => _$GameV3FromJson(json);
}

