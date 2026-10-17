import 'dart:math' as math;

/// Utility class for statistical calculations
class StatCalculations {
  /// Calculate mean (average)
  static double mean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Calculate median
  static double median(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length % 2 == 0) {
      return (sorted[mid - 1] + sorted[mid]) / 2.0;
    }
    return sorted[mid];
  }

  /// Calculate mode (most frequent value)
  static double? mode(List<double> values) {
    if (values.isEmpty) return null;
    final frequency = <double, int>{};
    for (final value in values) {
      frequency[value] = (frequency[value] ?? 0) + 1;
    }
    double? modeValue;
    int maxFreq = 0;
    frequency.forEach((value, freq) {
      if (freq > maxFreq) {
        maxFreq = freq;
        modeValue = value;
      }
    });
    return modeValue;
  }

  /// Calculate standard deviation
  static double standardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    final avg = mean(values);
    final squaredDiffs = values.map((v) => math.pow(v - avg, 2).toDouble()).toList();
    final variance = mean(squaredDiffs);
    return math.sqrt(variance);
  }

  /// Calculate range (max - min)
  static double range(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce(math.max) - values.reduce(math.min);
  }

  /// Calculate interquartile range (IQR)
  static double interquartileRange(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final q1 = _percentile(sorted, 25);
    final q3 = _percentile(sorted, 75);
    return q3 - q1;
  }

  /// Calculate percentile
  static double _percentile(List<double> sorted, double percentile) {
    if (sorted.isEmpty) return 0.0;
    final index = (percentile / 100.0) * (sorted.length - 1);
    if (index == index.truncateToDouble()) {
      return sorted[index.toInt()];
    }
    final lower = sorted[index.floor()];
    final upper = sorted[index.ceil()];
    return lower + (upper - lower) * (index - index.floor());
  }

  /// Calculate quartiles
  static Map<String, double> quartiles(List<double> values) {
    if (values.isEmpty) {
      return {'q1': 0.0, 'q2': 0.0, 'q3': 0.0};
    }
    final sorted = List<double>.from(values)..sort();
    return {
      'q1': _percentile(sorted, 25),
      'q2': _percentile(sorted, 50), // median
      'q3': _percentile(sorted, 75),
    };
  }

  /// Calculate moving average
  static List<double> movingAverage(List<double> values, int windowSize) {
    if (values.isEmpty || windowSize <= 0) return [];
    final result = <double>[];
    for (int i = 0; i < values.length; i++) {
      final start = math.max(0, i - windowSize + 1);
      final window = values.sublist(start, i + 1);
      result.add(mean(window));
    }
    return result;
  }

  /// Calculate trend percentage (change from first to last or period comparison)
  static double calculateTrendPercentage(List<double> values, {int? period}) {
    if (values.isEmpty) return 0.0;
    if (values.length == 1) return 0.0;

    double earlier;
    double later;

    if (period != null && values.length > period) {
      // Compare recent period to previous period
      final recentPeriod = values.sublist(values.length - period);
      final previousPeriod = values.sublist(values.length - period * 2, values.length - period);
      earlier = mean(previousPeriod);
      later = mean(recentPeriod);
    } else {
      // Compare last value to first value
      earlier = values.first;
      later = values.last;
    }

    if (earlier == 0) return later > 0 ? 100.0 : 0.0;
    return ((later - earlier) / earlier) * 100.0;
  }

  /// Calculate consistency score (0.0 to 1.0, higher = more consistent)
  static double consistencyScore(List<double> values) {
    if (values.isEmpty) return 0.0;
    if (values.length == 1) return 1.0;

    final stdDev = standardDeviation(values);
    final avg = mean(values);
    if (avg == 0.0) return 1.0;

    // Coefficient of variation (lower = more consistent)
    final cv = stdDev / avg;
    // Convert to 0-1 score (higher = more consistent)
    return math.exp(-cv).clamp(0.0, 1.0);
  }

  /// Find longest streak of values above threshold
  static int longestStreakAbove(List<double> values, double threshold) {
    if (values.isEmpty) return 0;
    int maxStreak = 0;
    int currentStreak = 0;
    for (final value in values) {
      if (value >= threshold) {
        currentStreak++;
        maxStreak = math.max(maxStreak, currentStreak);
      } else {
        currentStreak = 0;
      }
    }
    return maxStreak;
  }

  /// Find longest streak of values below threshold
  static int longestStreakBelow(List<double> values, double threshold) {
    if (values.isEmpty) return 0;
    int maxStreak = 0;
    int currentStreak = 0;
    for (final value in values) {
      if (value <= threshold) {
        currentStreak++;
        maxStreak = math.max(maxStreak, currentStreak);
      } else {
        currentStreak = 0;
      }
    }
    return maxStreak;
  }

  /// Get min and max values
  static Map<String, double> minMax(List<double> values) {
    if (values.isEmpty) return {'min': 0.0, 'max': 0.0};
    return {
      'min': values.reduce(math.min),
      'max': values.reduce(math.max),
    };
  }

  /// Calculate recent form (average of last N games)
  static double recentForm(List<double> values, int lastNGames) {
    if (values.isEmpty) return 0.0;
    final n = math.min(lastNGames, values.length);
    final recent = values.sublist(values.length - n);
    return mean(recent);
  }
}

