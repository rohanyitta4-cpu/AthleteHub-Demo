import 'dart:math' as math;

import '../player_stats.dart';
import 'game_highlight.dart';
import 'stat_windows.dart';

/// One radar axis: a 0–100 score plus the plain-language numbers behind it.
class SkillAxis {
  final String label;
  final double score;

  /// The real number this axis is about, shown before the score (".600 L10").
  final String raw;
  final String detail;
  final String meaning;

  const SkillAxis({
    required this.label,
    required this.score,
    required this.raw,
    required this.detail,
    required this.meaning,
  });
}

/// Lengths of every run of games meeting [kept], skipping games where
/// [applies] is false (they neither extend nor break a run).
List<int> _runs(
  List<PlayerStats> games,
  bool Function(PlayerStats) applies,
  bool Function(PlayerStats) kept,
) {
  final runs = <int>[];
  var run = 0;
  for (final g in games) {
    if (!applies(g)) continue;
    if (kept(g)) {
      run++;
    } else if (run > 0) {
      runs.add(run);
      run = 0;
    }
  }
  if (run > 0) runs.add(run);
  return runs;
}

/// Where the active streak ranks among this season's finished streaks
/// ([runs] ends with the active one): 50 = a typical streak for you, 100 =
/// at least as long as all of them.
double _streakRank(int current, List<int> runs) {
  if (current == 0 || runs.isEmpty) return 0;
  final finished = runs.sublist(0, runs.length - 1);
  if (finished.isEmpty) return 100;
  var below = 0.0;
  for (final r in finished) {
    if (r < current) {
      below += 1;
    } else if (r == current) {
      below += 0.5;
    }
  }
  return (below / finished.length * 100).clamp(0.0, 100.0);
}

/// Five-axis profile for one stat, built from the same windows, streak and
/// formatting as the rest of the app so every number matches.
///
/// Returns null with fewer than 3 games or when the stat never applied.
List<SkillAxis>? skillProfile(String key, List<PlayerStats> games) {
  final season = windowPerGame(key, games);
  if (games.length < 3 || season == null) return null;

  final lower = lowerIsBetterStats.contains(key);
  final ratio = isRatioStat(key);
  final pitching = pitchingStats.contains(key);
  final n = games.length;
  final window = recentWindow(n);
  String fmt(double v) => formatPerGame(key, v);

  /// How [a] compares with [b] where 1.0 means equal and above 1 is better.
  double relative(double a, double b) {
    final (num, den) = lower ? (b, a) : (a, b);
    if (den == 0) return num == 0 ? 1 : 2;
    return num / den;
  }

  // Form: recent window against the season level.
  final recent =
      windowPerGame(key, games.sublist(math.max(0, n - window))) ?? season;
  final form = (50 * relative(recent, season)).clamp(0.0, 100.0);

  // Frequency: share of games at the season level (ratio) or with any (counting).
  final counted = [
    for (final g in games) perGameValue(key, g),
  ].whereType<double>().toList();
  bool good(double v) =>
      ratio ? (lower ? v <= season : v >= season) : (lower ? v == 0 : v > 0);
  final reached = counted.where(good).length;
  final frequency = counted.isEmpty ? 0.0 : reached / counted.length * 100;
  final goodLabel = ratio
      ? 'at ${formatStat(key, season)} or ${lower ? 'lower' : 'better'}'
      : (lower ? 'with none' : 'with at least 1');

  // Streak: hit streak for hitting stats (same as the Dashboard), otherwise
  // consecutive games meeting the frequency bar.
  final int current;
  final int longest;
  final List<int> runs;
  if (!pitching) {
    current = currentStreaks(games).hit;
    longest = longestHitStreak(games);
    runs = _runs(games, (g) => g.plateAppearances > 0, (g) => g.hits > 0);
  } else {
    runs = _runs(
      games,
      (g) => perGameValue(key, g) != null,
      (g) => good(perGameValue(key, g)!),
    );
    var run = 0;
    for (final v in counted) {
      run = good(v) ? run + 1 : 0;
    }
    current = run;
    longest = runs.fold(0, math.max);
  }
  final streak = _streakRank(current, runs);

  // Peak: season level against the best stretch of [window] games.
  double? best;
  for (var end = window; end <= n; end++) {
    final v = windowPerGame(key, games.sublist(end - window, end));
    if (v == null) continue;
    if (best == null || (lower ? v < best : v > best)) best = v;
  }
  best ??= season;
  final peak = (100 * relative(season, best)).clamp(0.0, 100.0);

  // Steadiness: typical distance of single games from the season level.
  final spread = counted.isEmpty
      ? 0.0
      : math.sqrt(
          counted
                  .map((v) => (v - season) * (v - season))
                  .reduce((a, b) => a + b) /
              counted.length,
        );
  final steadiness = season == 0
      ? (spread == 0 ? 100.0 : 0.0)
      : (100 * (1 - spread / season.abs() / 2)).clamp(0.0, 100.0);

  final signal = trendSignal(key, games, window: window);
  final formVerdict = signal == null
      ? 'Compared with your season level'
      : !signal.meaningful
      ? 'Within your normal game-to-game swing'
      : signal.better
      ? 'Clearly above your season level'
      : 'Clearly below your season level';

  return [
    SkillAxis(
      label: 'Form',
      score: form,
      raw: '${fmt(recent)} L$window',
      detail: 'Last $window games ${fmt(recent)} · season ${fmt(season)}',
      meaning: formVerdict,
    ),
    SkillAxis(
      label: 'Frequency',
      score: frequency,
      raw: '$reached of ${counted.length}',
      detail: '$reached of ${counted.length} games $goodLabel',
      meaning: '${frequency.round()}% of your games',
    ),
    SkillAxis(
      label: 'Streak',
      score: streak,
      raw: current == 0 ? 'none active' : '$current active',
      detail: current == 0
          ? 'No active streak · best $longest'
          : '$current active · best $longest',
      meaning: current == 0
          ? 'Score ranks your current run against your other streaks this season'
          : 'Longer than ${streak.round()}% of your ${pitching ? 'runs' : 'hit streaks'} this season',
    ),
    SkillAxis(
      label: 'Peak',
      score: peak,
      raw: 'best ${fmt(best)}',
      detail: 'Season ${fmt(season)} · best $window games ${fmt(best)}',
      meaning: 'How close your season is to your best stretch',
    ),
    SkillAxis(
      label: 'Steadiness',
      score: steadiness,
      raw: '±${fmt(spread)}',
      detail: 'Games usually land within ±${fmt(spread)} of ${fmt(season)}',
      meaning: 'Higher means fewer big swings',
    ),
  ];
}
