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

/// Season trend for one stat: faint per-game dots, a rolling line over the
/// app's recent window (10 games, or 5 early in the season) and the
/// season-to-date line, with a one-line read of recent form above it. Ratio stats are computed from summed totals over
/// each window, so the lines never show impossible values.
class MultiLineChart extends StatelessWidget {
  final String statName;

  /// Full season, oldest first. Rolling and season lines need the games
  /// before the visible range too.
  final List<Map<String, dynamic>> gameData;

  /// Visible games as indexes into [gameData]: [start] inclusive, [end]
  /// exclusive. Defaults to the whole season.
  final int? start;
  final int? end;

  /// Shown at the end of the legend row (e.g. a help button).
  final Widget? legendTrailing;

  const MultiLineChart({
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
    final games = [
      for (final g in gameData) PlayerStats.fromGameStats(g['stats']),
    ];
    final muted = dashMuted(isDark);

    if (games.isEmpty) {
      return Center(
        child: Text(
          'No games yet',
          style: GoogleFonts.inter(fontSize: 14, color: muted),
        ),
      );
    }

    final rollingWindow = recentWindow(games.length);
    final end = (this.end ?? games.length).clamp(1, games.length);
    final start = (this.start ?? 0).clamp(0, end - 1);
    final shown = end - start;

    final perGame = <double?>[];
    final rolling = <double?>[];
    final season = <double?>[];
    for (var i = start; i < end; i++) {
      perGame.add(perGameValue(key, games[i]));
      rolling.add(
        windowPerGame(
          key,
          games.sublist(math.max(0, i - rollingWindow + 1), i + 1),
        ),
      );
      season.add(windowPerGame(key, games.sublist(0, i + 1)));
    }

    final peak = [
      ...perGame,
      ...rolling,
      ...season,
    ].whereType<double>().fold<double>(0, math.max);
    final (maxY, step) = niceAxis(key, peak);

    List<FlSpot> spots(List<double?> values) => [
      for (var i = 0; i < values.length; i++)
        values[i] == null ? FlSpot.nullSpot : FlSpot(i.toDouble(), values[i]!),
    ];

    final accent = statAccent(isDark);
    final dotColor = (isDark ? Colors.white : Colors.black).withValues(
      alpha: 0.16,
    );
    final seasonColor = isDark ? Colors.white70 : Colors.black54;

    return Column(
      children: [
        _FormInsight(statKey: key, games: games, isDark: isDark),
        const SizedBox(height: 10),
        Expanded(
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: math.max(1, shown - 1).toDouble(),
              minY: 0,
              maxY: maxY,
              clipData: const FlClipData.none(),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: step,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: dashBorder(isDark), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: step,
                    getTitlesWidget: (value, meta) {
                      if (value > maxY + 1e-9) return const SizedBox.shrink();
                      return Text(
                        axisLabel(key, value),
                        style: dashMono(
                          size: 10,
                          weight: FontWeight.w500,
                          color: muted,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final i = value.round();
                      if ((value - i).abs() > 1e-6 || i < 0 || i >= shown) {
                        return const SizedBox.shrink();
                      }
                      final number = start + i + 1;
                      if (!showGameLabel(number, i, shown)) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'G$number',
                          style: dashMono(
                            size: 9.5,
                            weight: FontWeight.w500,
                            color: muted,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                // Single games: dots only.
                LineChartBarData(
                  spots: spots(perGame),
                  barWidth: 0,
                  color: Colors.transparent,
                  dotData: FlDotData(
                    getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                      radius: 1.8,
                      color: dotColor,
                      strokeWidth: 0,
                    ),
                  ),
                ),
                LineChartBarData(
                  spots: spots(season),
                  barWidth: 1.5,
                  color: seasonColor,
                  dashArray: const [4, 4],
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: spots(rolling),
                  barWidth: 2.5,
                  color: accent,
                  isStrokeCapRound: true,
                  isStrokeJoinRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        accent.withValues(alpha: 0.18),
                        accent.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  tooltipBorderRadius: BorderRadius.circular(8),
                  getTooltipItems: (touched) {
                    return touched.map((spot) {
                      // One tooltip block per touch, attached to the first series.
                      if (spot.barIndex != touched.first.barIndex) return null;
                      final i = spot.x.round();
                      String fmt(double? v) =>
                          v == null ? '—' : formatPerGame(key, v);
                      return LineTooltipItem(
                        'G${start + i + 1}\n',
                        GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(
                            text:
                                'Game ${fmt(perGame[i])}\n'
                                '$rollingWindow-game ${fmt(rolling[i])}\n'
                                'Season ${fmt(season[i])}',
                            style: dashMono(
                              size: 11,
                              weight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        textAlign: TextAlign.left,
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    _LegendItem(
                      swatch: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      label: 'Single game',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 16),
                    _LegendItem(
                      swatch: Container(width: 14, height: 2.5, color: accent),
                      label: '$rollingWindow-game avg',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 16),
                    _LegendItem(
                      swatch: Row(
                        children: [
                          Container(width: 5, height: 1.5, color: seasonColor),
                          const SizedBox(width: 3),
                          Container(width: 5, height: 1.5, color: seasonColor),
                        ],
                      ),
                      label: 'Season avg',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
            ?legendTrailing,
          ],
        ),
      ],
    );
  }
}

/// "Cooling off · L10 .600 vs season .751" above the chart.
class _FormInsight extends StatelessWidget {
  final String statKey;
  final List<PlayerStats> games;
  final bool isDark;

  const _FormInsight({required this.statKey, required this.games, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final muted = dashMuted(isDark);
    final signal = trendSignal(statKey, games);
    final perGame = isRatioStat(statKey) ? '' : '/game';
    final (String lead, Color color, String note) = switch (signal) {
      null => ('', muted, 'Recent form shows up after ${recentWindow(games.length) + 3} games'),
      final s when !s.meaningful => ('', muted, 'within normal swing'),
      final s when s.better => ('Heating up', dashPositive, ''),
      _ => ('Cooling off', dashNegative, ''),
    };
    final numbers = signal == null
        ? ''
        : 'L${signal.window} ${formatPerGame(statKey, signal.recent)}$perGame vs season '
            '${formatPerGame(statKey, signal.season)}$perGame';
    return Align(
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            if (lead.isNotEmpty)
              TextSpan(
                text: '$lead  ',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: color),
              ),
            TextSpan(
              text: numbers,
              style: dashMono(size: 12.5, weight: FontWeight.w700, color: dashText(isDark)),
            ),
            if (note.isNotEmpty)
              TextSpan(
                text: numbers.isEmpty ? note : '  ·  $note',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: muted),
              ),
          ],
        ),
        maxLines: 2,
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Widget swatch;
  final String label;
  final bool isDark;

  const _LegendItem({
    required this.swatch,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: dashMuted(isDark),
          ),
        ),
      ],
    );
  }
}
