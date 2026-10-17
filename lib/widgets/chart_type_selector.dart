import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_styles.dart';

enum ChartType { line, bar, heatmap }

/// Custom toggle with a sliding pill (AnimatedContainer). Selected = primary blue + white text; unselected = transparent + gray text.
class ChartTypeSelector extends StatelessWidget {
  final ChartType selectedType;
  final void Function(ChartType) onTypeChanged;
  /// When false, bar & heatmap show a lock affordance (still tappable — parent should route to Pro).
  final bool isPro;

  const ChartTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    this.isPro = true,
  });

  int get _selectedIndex {
    switch (selectedType) {
      case ChartType.line:
        return 0;
      case ChartType.bar:
        return 1;
      case ChartType.heatmap:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Use the app's accent so this selector inherits the active theme (black in
    // light mode, white in dark mode) rather than a fixed dodger blue that
    // clashed with the rest of the screen.
    final Color selectedBg = theme.colorScheme.primary;
    final Color selectedFg = theme.colorScheme.onPrimary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth = constraints.maxWidth / 3;
        final pillLeft = _selectedIndex * segmentWidth + 4;
        final pillWidth = segmentWidth - 8;

        return Container(
          height: 36,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Sliding pill
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOutCubic,
                margin: EdgeInsets.only(left: pillLeft, top: 4, bottom: 4),
                width: pillWidth,
                decoration: BoxDecoration(
                  color: selectedBg,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: activePillShadow(isDark),
                ),
              ),
              // Labels
              Row(
                children: [
                  _buildSegment(context, ChartType.line, 'Line', isDark,
                      selectedFg, locked: false),
                  _buildSegment(context, ChartType.bar, 'Bar', isDark,
                      selectedFg, locked: !isPro),
                  _buildSegment(context, ChartType.heatmap, 'Heatmap', isDark,
                      selectedFg, locked: !isPro),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegment(
    BuildContext context,
    ChartType type,
    String label,
    bool isDark,
    Color selectedFg, {
    bool locked = false,
  }) {
    final isSelected = selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTypeChanged(type),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 36,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (locked) ...[
                  Icon(
                    Icons.lock_outline,
                    size: 12,
                    color: isSelected
                        ? selectedFg.withOpacity(0.7)
                        : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? selectedFg
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
