import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../player_stats.dart';
import '../../theme/app_styles.dart';
import '../../utils/stat_key_map.dart';
import '../../utils/stat_windows.dart';
import '../dashboard/dash_style.dart';
import 'chart_axis.dart';

/// One bar per game for the visible window, with the season level as a
/// dashed reference. Bar width follows how many games are visible.
class BarChartWidget extends StatelessWidget {
  final String statName;

  /// Full season, oldest first, so game numbers and the season line are real.
  final List<Map<String, dynamic>> gameData;

  /// Visible games as indexes into [gameData]: [start] inclusive, [end]
  /// exclusive. Defaults to the whole season.
  final int? start;
  final int? end;

  /// Shown at the end of the legend row (e.g. a help button).
  final Widget? legendTrailing;

  const BarChartWidget({
    super.key,
    required this.statName,
    required this.gameData,
    this.start,
    this.end,
    this.legendTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final key = getStatKey(statName) ?? statName;
    final games = [for (final g in gameData) PlayerStats.fromGameStats(g['stats'])];
    final muted = dashMuted(isDark);

    if (games.isEmpty) {
      return Center(
        child: Text('No games yet', style: GoogleFonts.inter(fontSize: 14, color: muted)),
      );
    }

    final end = (this.end ?? games.length).clamp(1, games.length);
    final start = (this.start ?? 0).clamp(0, end - 1);
    final shown = end - start;
    final values = [for (var i = start; i < end; i++) perGameValue(key, games[i])];
    final season = windowPerGame(key, games);
    final peak = [...values, season].whereType<double>().fold<double>(0, math.max);
    final (maxY, step) = niceAxis(key, peak);
    final accent = statAccent(isDark);
    final stub = maxY * 0.012;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slot = (constraints.maxWidth - 42) / shown;
              final barWidth = (slot * 0.62).clamp(2.0, 16.0);
              return BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: step,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: dashBorder(isDark), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      if (season != null)
                        HorizontalLine(
                          y: season,
                          color: isDark ? Colors.white70 : Colors.black54,
                          strokeWidth: 1.2,
                          dashArray: const [4, 4],
                        ),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: step,
                        getTitlesWidget: (value, meta) {
                          if (value > maxY + 1e-9) return const SizedBox.shrink();
                          return Text(
                            axisLabel(key, value),
                            style: dashMono(size: 10, weight: FontWeight.w500, color: muted),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          final i = value.round();
                          if (i < 0 || i >= shown) return const SizedBox.shrink();
                          final number = start + i + 1;
                          if (!showGameLabel(number, i, shown)) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'G$number',
                              style: dashMono(size: 9.5, weight: FontWeight.w500, color: muted),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      tooltipBorderRadius: BorderRadius.circular(8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final v = values[group.x];
                        return BarTooltipItem(
                          'G${start + group.x + 1}\n',
                          GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(
                              text: v == null ? '—' : formatPerGame(key, v),
                              style: dashMono(size: 11, weight: FontWeight.w500, color: Colors.white),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < shown; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: values[i] == null ? 0 : math.max(values[i]!, stub),
                            width: barWidth,
                            color: values[i] == null
                                ? Colors.transparent
                                : values[i] == 0
                                    ? dashBorder(isDark)
                                    : accent.withValues(alpha: i == shown - 1 ? 1 : 0.6),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(math.min(3, barWidth / 2)),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 8, height: 10, color: accent.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text('Single game', style: _legendStyle(isDark)),
                  const SizedBox(width: 16),
                  Container(width: 5, height: 1.5, color: isDark ? Colors.white70 : Colors.black54),
                  const SizedBox(width: 3),
                  Container(width: 5, height: 1.5, color: isDark ? Colors.white70 : Colors.black54),
                  const SizedBox(width: 6),
                  Text('Season avg', style: _legendStyle(isDark)),
                ],
              ),
            ),
            ?legendTrailing,
          ],
        ),
      ],
    );
  }

  TextStyle _legendStyle(bool isDark) =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: dashMuted(isDark));
}
