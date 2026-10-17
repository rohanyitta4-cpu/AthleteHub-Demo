import 'dart:math' as math;

import '../player_stats.dart';
import 'stat_key_map.dart';

/// Shared stat math for the dashboard and stats screens, so the same number
/// is computed the same way everywhere.

/// Ratio stats: their value over several games comes from summed totals
/// (hits ÷ at-bats), never from averaging per-game values.
bool isRatioStat(String key) => isRateStat(key) || key == 'war';

/// Stats where a bigger number is worse.
const lowerIsBetterStats = {
  'strikeouts',
  'earnedRunAverage',
  'walksHitsPerInningPitched',
  'earnedRuns',
};

/// Stats that only apply to hitters.
const pitchingStats = {
  'earnedRunAverage',
  'walksHitsPerInningPitched',
  'strikeoutRate',
  'inningsPitched',
  'earnedRuns',
  'pitchesThrown',
};

const _twoStrikeKeys = {'twoStrikeSuccessRate', 'twoStrikeCounts'};

/// Whether the game logged two-strike at-bats at all.
bool twoStrikeTracked(PlayerStats s) => s.twoStrikeCounts > 0 || s.successWithTwoStrikes > 0;

/// Why a game's two-strike numbers can't all be true, or null when they can
/// (or weren't logged). Two-strike counts are at-bats that reached two
/// strikes; successes are hits in those at-bats.
String? twoStrikeIssue(PlayerStats s) {
  if (!twoStrikeTracked(s)) return null;
  final ts = s.twoStrikeCounts;
  final hits2 = s.successWithTwoStrikes;
  if (ts > s.atBats) {
    return 'Two-strike at-bats ($ts) can\'t be more than at bats (${s.atBats}).';
  }
  if (hits2 > ts) {
    return 'Hits with two strikes ($hits2) can\'t be more than two-strike at-bats ($ts).';
  }
  if (hits2 > s.hits) {
    return 'Hits with two strikes ($hits2) can\'t be more than hits (${s.hits}).';
  }
  if (s.strikeouts > ts) {
    return 'Every strikeout reaches two strikes, so two-strike at-bats ($ts) '
        'can\'t be fewer than strikeouts (${s.strikeouts}).';
  }
  if (s.hits - hits2 > s.atBats - ts) {
    return '${s.hits - hits2} hits before two strikes is more than the '
        '${s.atBats - ts} at-bats that ended before two strikes.';
  }
  return null;
}

/// Games whose two-strike numbers were logged and add up.
List<PlayerStats> validTwoStrikeGames(Iterable<PlayerStats> games) =>
    [for (final g in games) if (twoStrikeTracked(g) && twoStrikeIssue(g) == null) g];

/// Games in the "recent" window used everywhere (dashboard, stat pages,
/// radar Form, rolling line): 10, or 5 until there are enough games to
/// compare 10 against the rest of the season.
int recentWindow(int gameCount) => gameCount >= 13 ? 10 : 5;

/// Recent level against the season, and whether the gap is bigger than the
/// player's normal game-to-game swing.
class TrendSignal {
  final double recent;
  final double season;
  final int window;

  /// True only when the gap is at least two standard errors, judged from the
  /// spread of this player's own single games.
  final bool meaningful;

  /// True when recent is better than season (lower for lower-is-better stats).
  final bool better;

  const TrendSignal({
    required this.recent,
    required this.season,
    required this.window,
    required this.meaningful,
    required this.better,
  });

  double get gap => recent - season;
}

/// Null with fewer than [window] + 3 games or when the stat never applied.
TrendSignal? trendSignal(String key, List<PlayerStats> games, {int? window}) {
  final w = window ?? recentWindow(games.length);
  if (games.length < w + 3) return null;
  final season = windowPerGame(key, games);
  final recentGames = games.sublist(games.length - w);
  final recent = windowPerGame(key, recentGames);
  if (season == null || recent == null) return null;

  final values = [for (final g in games) perGameValue(key, g)].whereType<double>().toList();
  final counted = [for (final g in recentGames) perGameValue(key, g)].whereType<double>().length;
  var meaningful = false;
  if (values.length >= 2 && counted > 0) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / (values.length - 1);
    final standardError = math.sqrt(variance / counted);
    meaningful = standardError > 0 && (recent - season).abs() >= 2 * standardError;
  }
  final lower = lowerIsBetterStats.contains(key);
  return TrendSignal(
    recent: recent,
    season: season,
    window: w,
    meaningful: meaningful,
    better: lower ? recent < season : recent > season,
  );
}

/// One game's value, or null when the stat had no denominator that game
/// (no at-bats for AVG, no innings for ERA, not logged for optional stats),
/// so charts can skip it instead of showing a false zero.
double? perGameValue(String key, PlayerStats s) {
  if (_twoStrikeKeys.contains(key) && (!twoStrikeTracked(s) || twoStrikeIssue(s) != null)) {
    return null;
  }
  final plateAppearances =
      s.atBats + s.walks + s.hitByPitch + s.sacrificeFlies + s.sacrificeHits;
  final hasDenominator = switch (key) {
    'battingAverage' || 'sluggingPercentage' || 'isolatedPower' || 'war' => s.atBats > 0,
    'onBasePercentage' || 'onBasePlusSlugging' => plateAppearances > 0,
    'runsCreated' => s.atBats + s.walks > 0,
    'earnedRunAverage' || 'walksHitsPerInningPitched' || 'strikeoutRate' =>
      s.inningsPitched > 0,
    'twoStrikeSuccessRate' => s.twoStrikeCounts > 0,
    _ => true,
  };
  if (!hasDenominator) return null;
  final v = s.statValue(key);
  return v != null && v.isFinite ? v : null;
}

/// Value over a set of games as players read it: summed-totals ratio for
/// ratio stats (season AVG), plain total for counting stats (season hits).
double windowTotal(String key, List<PlayerStats> games) {
  if (_twoStrikeKeys.contains(key)) games = validTwoStrikeGames(games);
  if (games.isEmpty) return 0;
  final v = PlayerStats.sum(games).statValue(key) ?? 0;
  return v.isFinite ? v : 0;
}

/// Per-game level over a set of games: the ratio for ratio stats, total
/// divided by games for counting stats. Null when nothing applies.
double? windowPerGame(String key, List<PlayerStats> games) {
  if (games.isEmpty) return null;
  if (isRatioStat(key)) {
    if (games.every((g) => perGameValue(key, g) == null)) return null;
    return windowTotal(key, games);
  }
  final counted = games.where((g) => perGameValue(key, g) != null).toList();
  if (counted.isEmpty) return null;
  return windowTotal(key, counted) / counted.length;
}

/// Baseball formatting: .751 rather than 0.751.
String formatStat(String key, double value) {
  final s = formatStatValue(key, value);
  if (s.startsWith('0.')) return s.substring(1);
  if (s.startsWith('-0.')) return '-${s.substring(2)}';
  return s;
}

/// Per-game level for counting stats ("2.13"), ratio formatting otherwise.
String formatPerGame(String key, double value) =>
    isRatioStat(key) ? formatStat(key, value) : value.toStringAsFixed(2);
