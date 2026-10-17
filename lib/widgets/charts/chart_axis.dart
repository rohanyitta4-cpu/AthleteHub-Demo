import 'dart:math' as math;

import '../../utils/stat_key_map.dart';
import '../../utils/stat_windows.dart';

/// Round axis top and step from 0. Three-decimal stats use .100/.250 steps.
(double, double) niceAxis(String key, double peak) {
  if (isRateStat(key) && peak <= 1) {
    if (peak <= 0.5) return (0.5, 0.1);
    return (1.0, 0.25);
  }
  if (peak <= 0) return (1, 0.25);
  final rough = peak / 4;
  final magnitude = math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
  final step = [1.0, 2.0, 2.5, 5.0, 10.0]
      .map((m) => m * magnitude)
      .firstWhere((s) => s >= rough);
  return ((peak / step).ceil() * step, step);
}

String axisLabel(String key, double value) {
  if (isRatioStat(key)) return formatStat(key, value);
  return value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

/// Game-number spacing for x-axis labels so at most ~7 show.
int labelEvery(int shown) {
  for (final step in [1, 2, 5, 10, 20, 25, 50]) {
    if (shown / step <= 7) return step;
  }
  return 100;
}

/// Whether game [number] (1-based) at visible index [i] of [shown] gets a label.
bool showGameLabel(int number, int i, int shown) {
  final every = labelEvery(shown);
  final isLast = i == shown - 1;
  if (isLast) return true;
  if (number % every != 0) return false;
  return shown - 1 - i >= every / 2;
}
