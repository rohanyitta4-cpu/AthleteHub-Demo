import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_event_v3.freezed.dart';
part 'game_event_v3.g.dart';

enum EventOutcome {
  singleLeft, singleCenter, singleRight,
  doubleLeft, doubleCenter, doubleRight,
  tripleLeft, tripleCenter, tripleRight,
  homeRun,
  walk, hitByPitch, strikeout, groundout, flyout,
  sacrificeHit, sacrificeFly,
  error, fielderChoice, passedBall, wildPitch,
  stolenBase, caughtStealing,
  pickoff, balk
}

@freezed
abstract class GameEventV3 with _$GameEventV3 {
  const factory GameEventV3({
    required String eventId,
    required DateTime timestamp,
    required int inning,
    required String half, // 'top' or 'bottom'
    required String batterId,
    required String pitcherId,
    required EventOutcome outcome,
    @Default({}) Map<String, bool> runnersBefore, // {'1st': false, '2nd': false, '3rd': false}
    @Default({}) Map<String, bool> runnersAfter, // {'1st': false, '2nd': false, '3rd': false}
    @Default(0) int rbi,
    String? scorerId, // player ID who scored
    Map<String, dynamic>? metadata,
  }) = _GameEventV3;

  factory GameEventV3.fromJson(Map<String, dynamic> json) => _$GameEventV3FromJson(json);
}

