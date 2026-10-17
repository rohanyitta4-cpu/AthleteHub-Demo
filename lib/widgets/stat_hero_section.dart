import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../player_stats.dart';
import '../theme/app_styles.dart';
import '../utils/stat_key_map.dart';
import '../utils/stat_windows.dart';
import 'dashboard/dash_style.dart';

/// Top card of a stat page: the season number, its change since the last
/// game, and Last game / L10 / L25 with arrows against the season.
class StatHeroSection extends StatelessWidget {
  final String statName;
  final List<Map<String, dynamic>> gameData;

  const StatHeroSection({
    super.key,
    required this.statName,
    required this.gameData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final key = getStatKey(statName) ?? statName;
    final games = [for (final g in gameData) PlayerStats.fromGameStats(g['stats'])];
    final ratio = isRatioStat(key);
    final season = windowTotal(key, games);
    List<PlayerStats> last(int n) => games.sublist((games.length - n).clamp(0, games.length));

    // A single game never moves the season beyond normal swing, so this line
    // stays gray; color is reserved for the L10 / L25 arrows below.
    String? deltaText;
    bool deltaUp = true;
    if (games.length >= 2 && ratio) {
      final diff = season - windowTotal(key, games.sublist(0, games.length - 1));
      if (diff.abs() < 0.0005) {
        deltaText = 'No change since last game';
      } else {
        deltaUp = diff > 0;
        deltaText = '${formatStat(key, diff.abs())} ${deltaUp ? 'up' : 'down'} since last game';
      }
    }
    final hasDeltaArrow = deltaText != null && !deltaText.startsWith('No change');

    final lastGameValue = perGameValue(key, games.last);
    final tiles = <(String, String, TrendSignal?)>[
      ('Last game', lastGameValue == null ? '—' : formatStat(key, lastGameValue), null),
      ('L10', formatStat(key, windowTotal(key, last(10))), trendSignal(key, games, window: 10)),
      ('L25', formatStat(key, windowTotal(key, last(25))), trendSignal(key, games, window: 25)),
    ];
    final anyArrow = tiles.any((t) => t.$3 != null);

    final totals = PlayerStats.sum(games);
    final subline = switch (key) {
      'battingAverage' => '${totals.hits}-for-${totals.atBats}',
      'onBasePercentage' =>
        '${totals.hits + totals.walks + totals.hitByPitch} times on base',
      _ => ratio ? null : 'in ${games.length} games',
    };

    return GradientBorderCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  statName.toUpperCase(),
                  style: sectionLabelStyle(isDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                ratio ? 'SEASON' : 'SEASON TOTAL',
                style: dashLabel(isDark, size: 9.5),
              ),
            ],
          ),
          const SizedBox(height: sectionLabelGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatStat(key, season),
                style: dashMono(
                  size: 44,
                  weight: FontWeight.w800,
                  color: statAccent(isDark),
                  height: 1,
                ),
              ),
              if (subline != null) ...[
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    subline,
                    style: dashMono(size: 12.5, weight: FontWeight.w500, color: dashMuted(isDark)),
                  ),
                ),
              ],
            ],
          ),
          if (deltaText case final deltaText?) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (hasDeltaArrow) ...[
                  Text(
                    deltaUp ? '▲' : '▼',
                    style: TextStyle(fontSize: 10, color: dashMuted(isDark)),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  deltaText,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: dashMuted(isDark),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: dashBorder(isDark))),
            ),
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) Container(width: 1, height: 30, color: dashBorder(isDark)),
                  Expanded(
                    child: Column(
                      children: [
                        Text(tiles[i].$1.toUpperCase(), style: dashLabel(isDark, size: 9.5)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tiles[i].$2,
                              style: dashMono(
                                size: 16,
                                weight: FontWeight.w700,
                                color: dashText(isDark),
                              ),
                            ),
                            if (_arrow(tiles[i].$3, isDark) case final arrow?) ...[
                              const SizedBox(width: 4),
                              arrow,
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (anyArrow) ...[
            const SizedBox(height: 10),
            Text(
              'Arrows compare each stretch with your season. Gray = normal game-to-game swing.',
              style: GoogleFonts.inter(fontSize: 11, color: dashMuted(isDark), height: 1.3),
            ),
          ],
        ],
      ),
    );
  }

  static Widget? _arrow(TrendSignal? signal, bool isDark) {
    if (signal == null || signal.gap.abs() < 1e-9) return null;
    final color = !signal.meaningful
        ? dashMuted(isDark)
        : signal.better
            ? dashPositive
            : dashNegative;
    return Text(signal.gap > 0 ? '▲' : '▼', style: TextStyle(fontSize: 10, color: color));
  }
}
