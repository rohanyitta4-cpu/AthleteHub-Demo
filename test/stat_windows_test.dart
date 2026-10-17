import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_first_app_vsc/player_stats.dart';
import 'package:flutter_first_app_vsc/utils/game_highlight.dart';
import 'package:flutter_first_app_vsc/utils/stat_windows.dart';

PlayerStats game(Map<String, dynamic> stats) => PlayerStats.fromGameStats(stats);

void main() {
  final oneForOne = game({'atBats': 1, 'hits': 1});
  final oneForFour = game({'atBats': 4, 'hits': 1});
  final walkOnly = game({'atBats': 0, 'hits': 0, 'walks': 1});
  final hitless = game({'atBats': 3, 'hits': 0});

  test('season AVG is hits over at-bats, not the mean of game averages', () {
    final games = [oneForOne, oneForFour];
    expect(windowTotal('battingAverage', games), closeTo(0.4, 1e-9));
    // Mean of per-game averages would be (1.000 + .250) / 2 = .625.
    expect(windowPerGame('battingAverage', games), closeTo(0.4, 1e-9));
  });

  test('games without at-bats have no AVG instead of a zero', () {
    expect(perGameValue('battingAverage', walkOnly), isNull);
    expect(perGameValue('onBasePercentage', walkOnly), 1.0);
    expect(perGameValue('battingAverage', hitless), 0.0);
  });

  test('counting stats: total over a window, per-game level for trends', () {
    final games = [oneForOne, oneForFour, hitless];
    expect(windowTotal('hits', games), 2);
    expect(windowPerGame('hits', games), closeTo(2 / 3, 1e-9));
  });

  test('baseball formatting drops the leading zero', () {
    expect(formatStat('battingAverage', 0.751), '.751');
    expect(formatStat('battingAverage', 1), '1.000');
    expect(formatStat('hits', 145), '145');
  });

  test('hit streaks skip games without a plate appearance', () {
    final noPa = game({'atBats': 0});
    final games = [oneForFour, hitless, oneForOne, noPa, oneForFour];
    expect(currentStreaks(games).hit, 2);
    expect(longestHitStreak(games), 2);
    expect(longestHitStreak([oneForOne, oneForOne, oneForOne, hitless, oneForOne]), 3);
  });

  test('two-strike numbers that cannot add up are left out of the season', () {
    // 3-for-4 with 4 two-strike at-bats and 0 two-strike hits means 3 hits
    // in 0 other at-bats: impossible, so the game is skipped.
    final bad = game({'atBats': 4, 'hits': 3, 'strikeouts': 0, 'twoStrikeCounts': 4, 'successWithTwoStrikes': 0});
    final good = game({'atBats': 4, 'hits': 2, 'strikeouts': 1, 'twoStrikeCounts': 2, 'successWithTwoStrikes': 1});
    expect(twoStrikeIssue(bad), isNotNull);
    expect(twoStrikeIssue(good), isNull);
    expect(perGameValue('twoStrikeSuccessRate', bad), isNull);
    expect(validTwoStrikeGames([bad, good]), [good]);
    expect(windowTotal('twoStrikeCounts', [bad, good]), 2);
  });

  test('a normal swing is not a meaningful trend, a real slump is', () {
    final steady = [for (var i = 0; i < 30; i++) i.isEven ? oneForFour : game({'atBats': 4, 'hits': 3})];
    expect(trendSignal('battingAverage', steady)!.meaningful, isFalse);
    final slump = [for (var i = 0; i < 30; i++) i < 20 ? game({'atBats': 4, 'hits': 2}) : hitless];
    final signal = trendSignal('battingAverage', slump)!;
    expect(signal.meaningful, isTrue);
    expect(signal.better, isFalse);
  });
}
