import 'package:fl_chart/fl_chart.dart';
import '../player_stats.dart';
import '../utils/stat_key_map.dart';
import '../utils/stat_calculations.dart';

/// Utility class for preparing chart data from game data
class ChartDataPreparer {
  /// Convert game data to FlSpot list for a given stat
  static List<FlSpot> prepareLineChartData(
    String statName,
    List<Map<String, dynamic>> gameData,
  ) {
    final values = _extractStatValues(statName, gameData);
    return values.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }

  /// Extract stat values from game data
  static List<double> _extractStatValues(
    String statName,
    List<Map<String, dynamic>> gameData,
  ) {
    final statKey = getStatKey(statName);
    if (statKey == null || gameData.isEmpty) return [];

    // Optional stats a player didn't log for a game become NaN and are dropped.
    return gameData
        .map<double>((game) =>
            PlayerStats.fromGameStats(game['stats']).statValue(statKey) ??
            double.nan)
        .where((v) => v.isFinite)
        .toList();
  }

  /// Games that have a value for [statName]. For optional stats (hard-hit
  /// balls, quality at-bats) this skips games where they weren't logged, so
  /// widgets that pair values with game dates by index stay aligned.
  static List<Map<String, dynamic>> gamesWithStat(
    String statName,
    List<Map<String, dynamic>> gameData,
  ) {
    final statKey = getStatKey(statName);
    if (statKey == null || !optionalStatKeys.contains(statKey)) return gameData;
    return gameData
        .where((g) =>
            PlayerStats.fromGameStats(g['stats']).statValue(statKey) != null)
        .toList();
  }

  /// Calculate moving average spots
  static List<FlSpot> calculateMovingAverage(List<FlSpot> spots, int windowSize) {
    if (spots.isEmpty) return [];
    final values = spots.map((s) => s.y).toList();
    final movingAvg = StatCalculations.movingAverage(values, windowSize);
    return movingAvg.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }

  /// Get current value for a stat
  static double getCurrentValue(String statName, List<Map<String, dynamic>> gameData) {
    final values = _extractStatValues(statName, gameData);
    if (values.isEmpty) return 0.0;
    return values.last;
  }

  /// Get all values for a stat
  static List<double> getStatValues(String statName, List<Map<String, dynamic>> gameData) {
    return _extractStatValues(statName, gameData);
  }
}

