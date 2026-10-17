import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_styles.dart';
import '../dashboard/dash_style.dart';

/// Zoom control under a chart: −/+ change how many games are visible, and the
/// overview strip (every game in the range) shows and moves the visible window.
class ChartZoomBar extends StatelessWidget {
  /// One value per game in the selected range; null where the stat didn't apply.
  final List<double?> values;

  /// Game number (1-based) of the first game in [values].
  final int firstGameNumber;

  /// Visible window, relative to [values].
  final int windowStart;
  final int windowLength;

  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final ValueChanged<int> onMove;

  const ChartZoomBar({
    super.key,
    required this.values,
    required this.firstGameNumber,
    required this.windowStart,
    required this.windowLength,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final zoomed = windowLength < values.length;
    final from = firstGameNumber + windowStart;
    final to = from + windowLength - 1;

    void moveTo(double dx, double width) {
      if (!zoomed || width <= 0) return;
      final center = (dx / width).clamp(0.0, 1.0) * values.length;
      final start = (center - windowLength / 2).round().clamp(0, values.length - windowLength);
      if (start != windowStart) onMove(start);
    }

    return Column(
      children: [
        Row(
          children: [
            _ZoomButton(icon: Icons.remove_rounded, onTap: onZoomOut, isDark: isDark),
            const SizedBox(width: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => moveTo(d.localPosition.dx, constraints.maxWidth),
                  onHorizontalDragUpdate: (d) => moveTo(d.localPosition.dx, constraints.maxWidth),
                  child: SizedBox(
                    height: 30,
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, 30),
                      painter: _OverviewPainter(
                        values: values,
                        windowStart: windowStart,
                        windowLength: windowLength,
                        bar: dashMuted(isDark).withValues(alpha: 0.45),
                        activeBar: statAccent(isDark),
                        window: statAccent(isDark).withValues(alpha: 0.12),
                        windowBorder: statAccent(isDark).withValues(alpha: 0.6),
                        track: dashBorder(isDark),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ZoomButton(icon: Icons.add_rounded, onTap: onZoomIn, isDark: isDark),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              'G$from–G$to · ${windowLength == values.length ? 'all' : windowLength} games',
              style: dashMono(size: 10, weight: FontWeight.w500, color: dashMuted(isDark)),
            ),
            const Spacer(),
            Text(
              zoomed ? 'Drag the strip to move' : 'Tap + to zoom in',
              style: dashLabel(isDark, size: 9.5),
            ),
          ],
        ),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;

  const _ZoomButton({required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 34,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: dashBorder(isDark)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? dashText(isDark) : dashMuted(isDark).withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _OverviewPainter extends CustomPainter {
  final List<double?> values;
  final int windowStart;
  final int windowLength;
  final Color bar;
  final Color activeBar;
  final Color window;
  final Color windowBorder;
  final Color track;

  _OverviewPainter({
    required this.values,
    required this.windowStart,
    required this.windowLength,
    required this.bar,
    required this.activeBar,
    required this.window,
    required this.windowBorder,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n == 0) return;
    final slot = size.width / n;
    final peak = values.whereType<double>().fold<double>(0, math.max);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = track,
    );

    final barWidth = math.max(1.0, slot * 0.6);
    for (var i = 0; i < n; i++) {
      final v = values[i];
      if (v == null) continue;
      final h = peak <= 0 ? 1.0 : math.max(1.0, v / peak * (size.height - 8));
      final inWindow = i >= windowStart && i < windowStart + windowLength;
      final x = i * slot + (slot - barWidth) / 2;
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - 4 - h, barWidth, h),
        Paint()..color = inWindow ? activeBar : bar,
      );
    }

    if (windowLength < n) {
      final rect = Rect.fromLTWH(windowStart * slot, 0, windowLength * slot, size.height);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      canvas.drawRRect(rrect, Paint()..color = window);
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = windowBorder,
      );
    }
  }

  @override
  bool shouldRepaint(_OverviewPainter old) =>
      old.values != values ||
      old.windowStart != windowStart ||
      old.windowLength != windowLength ||
      old.activeBar != activeBar;
}
