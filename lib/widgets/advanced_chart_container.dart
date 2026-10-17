import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chart_type_selector.dart';
import '../theme/app_styles.dart';
import 'charts/multi_line_chart.dart';
import 'charts/bar_chart_widget.dart';
import 'charts/heatmap_calendar.dart';
import 'charts/chart_zoom_bar.dart';
import 'how_to_read_button.dart';
import '../player_stats.dart';
import '../utils/stat_key_map.dart';
import '../utils/stat_windows.dart';
import '../screens/pro_upgrade_screen.dart';
import '../services/pro_entitlements.dart';

/// Range filter applied to game data before charting.
enum ChartDataRange { last10, last25, season }

class AdvancedChartContainer extends StatefulWidget {
  final String statName;
  final List<Map<String, dynamic>> gameData;
  final double? goalValue;
  final double? personalBest;

  /// When false, only [ChartType.line] is available; bar & heatmap require Pro.
  final bool isPro;

  const AdvancedChartContainer({
    super.key,
    required this.statName,
    required this.gameData,
    this.goalValue,
    this.personalBest,
    this.isPro = false,
  });

  @override
  State<AdvancedChartContainer> createState() => _AdvancedChartContainerState();
}

class _AdvancedChartContainerState extends State<AdvancedChartContainer> {
  ChartType _selectedChartType = ChartType.line;
  ChartDataRange _selectedRange = ChartDataRange.season;

  /// Zoomed window inside the selected range; null shows the whole range.
  int? _zoomLength;
  int? _zoomStart;

  static const _minZoomGames = 10;

  void _resetZoom() {
    _zoomLength = null;
    _zoomStart = null;
  }

  /// Zoom steps from the whole range down to [_minZoomGames], widest first.
  List<int> _zoomLevels(int rangeLength) => {
        rangeLength,
        for (final l in const [50, 30, 20, _minZoomGames])
          if (l < rangeLength) l,
      }.toList();

  (int, int) _zoomWindow(int rangeLength) {
    final length = (_zoomLength ?? rangeLength).clamp(1, rangeLength);
    final start = (_zoomStart ?? rangeLength - length).clamp(0, rangeLength - length);
    return (start, length);
  }

  void _zoomTo(int newLength, int rangeLength) {
    final (start, length) = _zoomWindow(rangeLength);
    setState(() {
      _zoomStart = (start + length - newLength).clamp(0, rangeLength - newLength);
      _zoomLength = newLength;
    });
  }

  ChartType get _effectiveChartType {
    if (!ProEntitlements.canUseBarAndHeatmapCharts(widget.isPro) &&
        (_selectedChartType == ChartType.bar ||
            _selectedChartType == ChartType.heatmap)) {
      return ChartType.line;
    }
    return _selectedChartType;
  }

  /// Returns a slice of [widget.gameData] honoring [_selectedRange].
  /// gameData is ordered oldest → newest, so we tail-slice.
  List<Map<String, dynamic>> get _rangedGameData {
    if (widget.gameData.isEmpty) return widget.gameData;
    switch (_selectedRange) {
      case ChartDataRange.last10:
        if (widget.gameData.length <= 10) return widget.gameData;
        return widget.gameData.sublist(widget.gameData.length - 10);
      case ChartDataRange.last25:
        if (widget.gameData.length <= 25) return widget.gameData;
        return widget.gameData.sublist(widget.gameData.length - 25);
      case ChartDataRange.season:
        return widget.gameData;
    }
  }

  @override
  void didUpdateWidget(AdvancedChartContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameData.length != widget.gameData.length ||
        oldWidget.statName != widget.statName) {
      _resetZoom();
    }
    if (oldWidget.isPro && !widget.isPro) {
      if (_selectedChartType != ChartType.line) {
        setState(() => _selectedChartType = ChartType.line);
      }
    } else if (!oldWidget.isPro && widget.isPro) {
      setState(() {}); // Bar/heatmap segments unlock when Pro activates mid-session.
    }
  }

  Future<void> _onChartTypeChanged(ChartType type) async {
    if ((type == ChartType.bar || type == ChartType.heatmap) &&
        !ProEntitlements.canUseBarAndHeatmapCharts(widget.isPro)) {
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (context) => const ProUpgradeScreen()),
      );
      return;
    }
    setState(() => _selectedChartType = type);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color cardBg = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.white;
    final Color cardBorder = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.grey[200]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: "PERFORMANCE" kicker on the left, range selector on the right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'PERFORMANCE',
                style: sectionLabelStyle(isDark),
              ),
            ),
            _RangeSelector(
              selected: _selectedRange,
              onChanged: (r) => setState(() {
                _selectedRange = r;
                _resetZoom();
              }),
            ),
          ],
        ),
        const SizedBox(height: sectionLabelGap),
        // Chart type selector (line / bar / heatmap)
        ChartTypeSelector(
          selectedType: _selectedChartType,
          isPro: widget.isPro,
          onTypeChanged: _onChartTypeChanged,
        ),
        const SizedBox(height: 16),
        // Chart card — theme-aware (no longer hardcoded white)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: _effectiveChartType == ChartType.heatmap ? 360 : 280,
                child: _buildChart(),
              ),
              if (_effectiveChartType != ChartType.heatmap &&
                  _rangedGameData.length > _minZoomGames) ...[
                const SizedBox(height: 14),
                _buildZoomBar(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildZoomBar() {
    final rangeLength = _rangedGameData.length;
    final rangeStart = widget.gameData.length - rangeLength;
    final key = getStatKey(widget.statName) ?? widget.statName;
    final (start, length) = _zoomWindow(rangeLength);
    final levels = _zoomLevels(rangeLength);
    final narrower = levels.where((l) => l < length);
    final wider = levels.where((l) => l > length);
    return ChartZoomBar(
      values: [
        for (final g in _rangedGameData) perGameValue(key, PlayerStats.fromGameStats(g['stats'])),
      ],
      firstGameNumber: rangeStart + 1,
      windowStart: start,
      windowLength: length,
      onZoomIn: narrower.isEmpty ? null : () => _zoomTo(narrower.first, rangeLength),
      onZoomOut: wider.isEmpty ? null : () => _zoomTo(wider.last, rangeLength),
      onMove: (s) => setState(() => _zoomStart = s),
    );
  }

  static const _helpButton = HowToReadButton(title: 'Reading the chart', sections: _howToRead);

  Widget _buildChart() {
    final rangeLength = _rangedGameData.length;
    final rangeStart = widget.gameData.length - rangeLength;
    final (start, length) = _zoomWindow(rangeLength);
    final first = rangeStart + start;
    switch (_effectiveChartType) {
      case ChartType.line:
        return MultiLineChart(
          statName: widget.statName,
          gameData: widget.gameData,
          start: first,
          end: first + length,
          legendTrailing: _helpButton,
        );
      case ChartType.bar:
        return BarChartWidget(
          statName: widget.statName,
          gameData: widget.gameData,
          start: first,
          end: first + length,
          legendTrailing: _helpButton,
        );
      case ChartType.heatmap:
        // Heatmap is calendar-based; pass full season so the calendar grid stays meaningful.
        return HeatmapCalendar(
          statName: widget.statName,
          gameData: widget.gameData,
        );
    }
  }
}

const _howToRead = [
  (
    'Dots',
    'Each faint dot is one game. A single game can only land on a few values '
        '(1-for-1 is 1.000, 1-for-2 is .500, 0-for-3 is .000), so the dots '
        'line up in rows and swing a lot. A gap means no at-bats that game.',
  ),
  (
    'Solid line: 10-game average',
    'Not a line of best fit. At every game it shows your average over that '
        'game and the 9 before it (5 games early in the season). Example: at '
        'G30 it covers G21–G30. It rises in hot stretches and dips in cold '
        'ones, and is much steadier than single games.',
  ),
  (
    'The line above the chart',
    'Compares your last 10 games with your season. "Heating up" or "Cooling '
        'off" only appears when the gap is bigger than your normal '
        'game-to-game swing; otherwise it says "within normal swing".',
  ),
  (
    'Dashed line: season average',
    'Same idea, but covering every game up to that point, so it moves slowly '
        'and finishes at your current season number.',
  ),
  (
    'Why averages use totals',
    'For stats like batting average, the 10-game and season lines are total '
        'hits divided by total at-bats, the same way your season average is '
        'worked out. They are not the average of the dots.',
  ),
  (
    'Bar chart',
    'One bar per game. The brightest bar is your latest game, a small grey '
        'stub is a game with zero, and a gap is a game where the stat did not '
        'apply, such as no at-bats. The dashed line is your season level.',
  ),
  (
    'Zoom',
    'Tap + to zoom in and − to zoom out. When zoomed in, drag or tap the strip '
        'under the chart to move along the season. L10, L25 and Season pick '
        'which games the strip covers.',
  ),
  (
    'Exact numbers',
    'Tap anywhere on a chart to see that game\'s number, plus the 10-game and '
        'season values on the line chart.',
  ),
];

/// Segmented "L10 / L25 / Season" pill — themed with [theme.colorScheme.primary]
/// so the selected segment uses the app's accent color (black in light, white in dark).
class _RangeSelector extends StatelessWidget {
  final ChartDataRange selected;
  final ValueChanged<ChartDataRange> onChanged;

  const _RangeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color trackColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.grey[200]!;
    final Color selectedBg = theme.colorScheme.primary;
    final Color selectedFg = theme.colorScheme.onPrimary;
    final Color unselectedFg = isDark ? Colors.grey[400]! : Colors.grey[700]!;

    Widget seg(String label, ChartDataRange r) {
      final isSel = selected == r;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSel ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSel ? activePillShadow(isDark) : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSel ? selectedFg : unselectedFg,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg('L10', ChartDataRange.last10),
          seg('L25', ChartDataRange.last25),
          seg('Season', ChartDataRange.season),
        ],
      ),
    );
  }
}
