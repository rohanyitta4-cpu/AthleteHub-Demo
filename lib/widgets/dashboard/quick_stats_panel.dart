import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_styles.dart';
import 'dash_style.dart';

/// One stat row: season value, last-10 bars and the recent level.
class QuickStatRow {
  final String label;
  final String value;

  /// Per-game values for the last games, oldest first; null = no plate appearances.
  final List<double?> bars;

  /// Value at the top of the chart; bars never rescale to fill it.
  final double scaleMax;

  /// Season per-game level, drawn as a dashed line across the bars.
  final double? reference;

  /// Headline of the right column, e.g. "L10 .600" or "18".
  final String? primary;

  /// Direction of the recent level against the season; null = no arrow.
  final bool? arrowUp;

  /// Only set when the change is bigger than the player's normal game-to-game
  /// swing: true = green, false = red. Null keeps the arrow neutral gray.
  final bool? primaryIsGood;
  final String? secondary;

  /// Replaces the bars when there's nothing to chart yet.
  final String? emptyMessage;

  const QuickStatRow({
    required this.label,
    required this.value,
    required this.bars,
    required this.scaleMax,
    this.reference,
    this.primary,
    this.arrowUp,
    this.primaryIsGood,
    this.secondary,
    this.emptyMessage,
  });
}

class QuickStatsPanel extends StatelessWidget {
  final List<QuickStatRow> rows;

  /// Number of games the bars and the right column cover.
  final int recentGames;

  /// Bar color; defaults to [statAccent].
  final Color? accent;

  const QuickStatsPanel({super.key, required this.rows, this.recentGames = 10, this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = accent ?? statAccent(isDark);
    return Container(
      decoration: accent == null
          ? dashCard(isDark, radius: 16)
          : dashCard(isDark, radius: 16).copyWith(border: Border.all(color: accent!.withValues(alpha: 0.22))),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) dashDivider(isDark),
            _Row(row: rows[i], isDark: isDark, barColor: barColor),
          ],
          dashDivider(isDark),
          _Legend(isDark: isDark, recentGames: recentGames, barColor: barColor),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final QuickStatRow row;
  final bool isDark;
  final Color barColor;

  const _Row({required this.row, required this.isDark, required this.barColor});

  @override
  Widget build(BuildContext context) {
    final muted = dashMuted(isDark);
    final empty = row.emptyMessage != null;
    final primaryColor = switch (row.primaryIsGood) {
      true => dashPositive,
      false => dashNegative,
      null => dashText(isDark),
    };
    final arrowColor = row.primaryIsGood == null ? muted : primaryColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.label.toUpperCase(), style: dashLabel(isDark, size: 10.5)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    row.value,
                    style: dashMono(
                      size: 26,
                      weight: FontWeight.w800,
                      height: 1.05,
                      color: empty ? muted : dashText(isDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 46,
              child: empty
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        row.emptyMessage!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 12.5, height: 1.3, color: muted),
                      ),
                    )
                  : CustomPaint(
                      painter: _BarsPainter(
                        values: row.bars,
                        scaleMax: row.scaleMax,
                        reference: row.reference,
                        color: barColor,
                        referenceColor: dashMuted(isDark),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 82,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (row.primary != null)
                  Text.rich(
                    TextSpan(
                      children: [
                        if (row.arrowUp != null)
                          TextSpan(
                            text: row.arrowUp! ? '▲ ' : '▼ ',
                            style: TextStyle(fontSize: 10, color: arrowColor),
                          ),
                        TextSpan(text: row.primary),
                      ],
                    ),
                    maxLines: 1,
                    style: dashMono(size: 13.5, weight: FontWeight.w800, color: primaryColor),
                  ),
                if (row.secondary != null) ...[
                  const SizedBox(height: 2),
                  Text(row.secondary!, maxLines: 1, style: GoogleFonts.inter(fontSize: 12, color: muted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final bool isDark;
  final int recentGames;
  final Color barColor;

  const _Legend({required this.isDark, required this.recentGames, required this.barColor});

  @override
  Widget build(BuildContext context) {
    final muted = dashMuted(isDark);
    final style = GoogleFonts.inter(fontSize: 11, color: muted, height: 1.3);
    Widget item(Widget swatch, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: 5),
        Text(text, style: style),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          item(
            Text(
              '.000',
              style: dashMono(size: 11, weight: FontWeight.w800, color: muted),
            ),
            'Season',
          ),
          item(
            Container(
              width: 6,
              height: 10,
              decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(1.5)),
            ),
            'Each of last $recentGames games',
          ),
          item(CustomPaint(size: const Size(14, 10), painter: _DashPainter(muted)), 'Season avg per game'),
          item(Text('▲▼', style: TextStyle(fontSize: 9, color: muted)), 'Gray = normal swing'),
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final y = size.height / 2;
    for (double x = 0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, y), Offset((x + 3).clamp(0, size.width), y), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// Per-game bars on a fixed scale (0 → [scaleMax]) so heights are comparable
/// game to game. Zero games are stubs, games without plate appearances are
/// left empty, and the latest game is drawn at full strength.
class _BarsPainter extends CustomPainter {
  final List<double?> values;
  final double scaleMax;
  final double? reference;
  final Color color;
  final Color referenceColor;

  _BarsPainter({
    required this.values,
    required this.scaleMax,
    required this.reference,
    required this.color,
    required this.referenceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || scaleMax <= 0) return;
    const slots = 10;
    const stub = 2.5;
    final slot = size.width / slots;
    final barWidth = slot * 0.62;
    final start = size.width - slot * values.length;
    double heightFor(double v) => stub + (size.height - stub) * (v / scaleMax).clamp(0.0, 1.0);

    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      final left = start + slot * i + (slot - barWidth) / 2;
      final latest = i == values.length - 1;
      if (v == null) {
        canvas.drawCircle(
          Offset(left + barWidth / 2, size.height - 1.5),
          1.2,
          Paint()..color = referenceColor.withValues(alpha: 0.5),
        );
        continue;
      }
      final h = v <= 0 ? stub : heightFor(v);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(left, size.height - h, barWidth, h), const Radius.circular(2)),
        Paint()..color = latest ? color : color.withValues(alpha: v <= 0 ? 0.3 : 0.4),
      );
    }

    final ref = reference;
    if (ref != null && ref > 0) {
      final y = size.height - heightFor(ref);
      final paint = Paint()
        ..color = referenceColor.withValues(alpha: 0.7)
        ..strokeWidth = 1;
      for (var x = start; x < size.width; x += 6) {
        canvas.drawLine(Offset(x, y), Offset((x + 3).clamp(0, size.width), y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.values != values ||
      old.scaleMax != scaleMax ||
      old.reference != reference ||
      old.color != color ||
      old.referenceColor != referenceColor;
}
