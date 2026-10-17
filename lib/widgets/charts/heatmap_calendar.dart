import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../player_stats.dart';
import '../../services/export_builders.dart';
import '../../utils/stat_key_map.dart';
import '../../utils/stat_windows.dart';

/// Calendar of game days for one year, across every season, with a year
/// switcher. [gameData] (the active season) is shown until all seasons load.
class HeatmapCalendar extends StatefulWidget {
  final String statName;
  final List<Map<String, dynamic>> gameData;

  const HeatmapCalendar({
    super.key,
    required this.statName,
    required this.gameData,
  });

  @override
  State<HeatmapCalendar> createState() => _HeatmapCalendarState();
}

class _HeatmapCalendarState extends State<HeatmapCalendar> {
  /// Every dated game as (date, stats); starts as the active season only.
  List<(DateTime, PlayerStats)> _games = [];
  int? _year;

  @override
  void initState() {
    super.initState();
    _games = _fromGameData(widget.gameData);
    _loadAllSeasons();
  }

  @override
  void didUpdateWidget(HeatmapCalendar old) {
    super.didUpdateWidget(old);
    if (old.gameData.length != widget.gameData.length) _loadAllSeasons();
  }

  List<(DateTime, PlayerStats)> _fromGameData(List<Map<String, dynamic>> data) => [
        for (final g in data)
          if (g['date'] is DateTime) (g['date'] as DateTime, PlayerStats.fromGameStats(g['stats'])),
      ];

  Future<void> _loadAllSeasons() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final seasons = await loadExportSeasons(FirebaseFirestore.instance, uid);
      final all = [
        for (final s in seasons)
          for (final g in s.games)
            if (g.date != null) (g.date!, g.stats),
      ];
      if (mounted && all.isNotEmpty) setState(() => _games = all);
    } catch (e) {
      debugPrint('Heatmap: could not load all seasons: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final key = getStatKey(widget.statName) ?? widget.statName;
    final currentYear = DateTime.now().year;

    final dataYears = {for (final g in _games) g.$1.year};
    final years = {...dataYears, currentYear}.toList()..sort();
    final defaultYear = dataYears.contains(currentYear)
        ? currentYear
        : (dataYears.isEmpty ? currentYear : dataYears.reduce((a, b) => a > b ? a : b));
    final year = years.contains(_year) ? _year! : defaultYear;
    final yearIndex = years.indexOf(year);

    // Games on the same day are combined so a doubleheader reads as one day.
    final byDay = <DateTime, List<PlayerStats>>{};
    for (final (date, stats) in _games) {
      if (date.year != year) continue;
      byDay.putIfAbsent(DateTime(date.year, date.month, date.day), () => []).add(stats);
    }
    final dateValueMap = <DateTime, double>{};
    byDay.forEach((day, games) {
      final v = perGameValue(key, PlayerStats.sum(games));
      if (v != null) dateValueMap[day] = v;
    });
    final gamesInYear = byDay.values.fold<int>(0, (n, g) => n + g.length);

    final header = _buildYearHeader(
      isDark,
      year: year,
      games: gamesInYear,
      onPrev: yearIndex > 0 ? () => setState(() => _year = years[yearIndex - 1]) : null,
      onNext: yearIndex < years.length - 1 ? () => setState(() => _year = years[yearIndex + 1]) : null,
    );

    if (dateValueMap.isEmpty) {
      return Column(
        children: [
          header,
          Expanded(
            child: Center(
              child: Text(
                'No games logged in $year',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final values = dateValueMap.values;
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    final monthGroups = <String, List<MapEntry<DateTime, double>>>{};
    for (final entry in dateValueMap.entries) {
      final monthKey = DateFormat('yyyy-MM').format(entry.key);
      monthGroups.putIfAbsent(monthKey, () => []).add(entry);
    }
    final sortedMonths = monthGroups.keys.toList()..sort();

    return Column(
      children: [
        header,
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Legend
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lower',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Row(
                        children: [
                          _buildLegendCell(context, _getColorForValue(minValue, minValue, maxValue, isDark, theme)),
                          const SizedBox(width: 4),
                          _buildLegendCell(context, _getColorForValue((minValue + maxValue) / 3, minValue, maxValue, isDark, theme)),
                          const SizedBox(width: 4),
                          _buildLegendCell(context, _getColorForValue((minValue + maxValue) * 2 / 3, minValue, maxValue, isDark, theme)),
                          const SizedBox(width: 4),
                          _buildLegendCell(context, _getColorForValue(maxValue, minValue, maxValue, isDark, theme)),
                        ],
                      ),
                      Text(
                        'Higher',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                ...sortedMonths.map((monthKey) {
                  final entries = monthGroups[monthKey]!..sort((a, b) => a.key.compareTo(b.key));
                  return _buildMonthGrid(context, key, entries, minValue, maxValue, isDark, theme);
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYearHeader(
    bool isDark, {
    required int year,
    required int games,
    VoidCallback? onPrev,
    VoidCallback? onNext,
  }) {
    final text = isDark ? Colors.white : Colors.black;
    final muted = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    Widget arrow(IconData icon, VoidCallback? onTap, String tooltip) => IconButton(
          onPressed: onTap,
          tooltip: tooltip,
          icon: Icon(icon, size: 22),
          color: text,
          disabledColor: muted.withValues(alpha: 0.3),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          arrow(Icons.chevron_left_rounded, onPrev, 'Previous year'),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$year',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: text),
                ),
                Text(
                  games == 1 ? '1 game' : '$games games',
                  style: GoogleFonts.inter(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
          arrow(Icons.chevron_right_rounded, onNext, 'Next year'),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(
    BuildContext context,
    String key,
    List<MapEntry<DateTime, double>> entries,
    double minValue,
    double maxValue,
    bool isDark,
    ThemeData theme,
  ) {
    final firstDate = entries.first.key;
    final monthName = DateFormat('MMMM yyyy').format(firstDate);

    final firstDayOfMonth = DateTime(firstDate.year, firstDate.month, 1);
    final daysInMonth = DateTime(firstDate.year, firstDate.month + 1, 0).day;
    final valueMap = {for (var e in entries) e.key.day: e.value};

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthName,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(daysInMonth, (index) {
              final day = index + 1;
              final value = valueMap[day];

              return GestureDetector(
                onTap: value != null
                    ? () => _showTooltip(
                          context,
                          DateTime(firstDayOfMonth.year, firstDayOfMonth.month, day),
                          formatStat(key, value),
                          isDark,
                        )
                    : null,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: value != null
                        ? _getColorForValue(value, minValue, maxValue, isDark, theme)
                        : (isDark ? Colors.grey[800] : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 0.5,
                    ),
                  ),
                  child: value != null
                      ? Center(
                          child: Text(
                            day.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _getColorForValue(double value, double minValue, double maxValue, bool isDark, ThemeData theme) {
    if (minValue == maxValue) {
      return theme.colorScheme.primary;
    }

    final normalized = (value - minValue) / (maxValue - minValue);

    if (normalized < 0.25) {
      return isDark ? Colors.blue[800]! : Colors.blue[300]!;
    } else if (normalized < 0.5) {
      return isDark ? Colors.blue[600]! : Colors.blue[400]!;
    } else if (normalized < 0.75) {
      return theme.colorScheme.primary;
    } else {
      return theme.colorScheme.secondary;
    }
  }

  Widget _buildLegendCell(BuildContext context, Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
    );
  }

  void _showTooltip(BuildContext context, DateTime date, String value, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          DateFormat('MMM d, yyyy').format(date),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          '${widget.statName}: $value',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
