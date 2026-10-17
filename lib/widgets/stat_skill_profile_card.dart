import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../player_stats.dart';
import '../theme/app_styles.dart';
import '../utils/skill_profile.dart';
import '../utils/stat_key_map.dart';
import '../utils/stat_windows.dart';
import 'dashboard/dash_style.dart';
import 'how_to_read_button.dart';

/// "SKILL PROFILE" card: a five-axis radar for one stat against the same
/// profile 30 days ago, with a verdict on top and the real numbers behind each
/// axis underneath. Tapping an axis on the radar jumps to its explanation.
class StatSkillProfileCard extends StatefulWidget {
  final String statName;
  final List<Map<String, dynamic>> gameData;

  const StatSkillProfileCard({
    super.key,
    required this.statName,
    required this.gameData,
  });

  @override
  State<StatSkillProfileCard> createState() => _StatSkillProfileCardState();
}

class _StatSkillProfileCardState extends State<StatSkillProfileCard> {
  static const _ghostDays = 30;

  /// Changes smaller than this many points are drawn gray.
  static const _notablePoints = 10;

  final _rowKeys = List.generate(5, (_) => GlobalKey());
  int? _flashed;

  void _jumpTo(int i) {
    final ctx = _rowKeys[i].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      alignment: 0.3,
    );
    setState(() => _flashed = i);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && _flashed == i) setState(() => _flashed = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final key = getStatKey(widget.statName) ?? widget.statName;
    final games = [
      for (final g in widget.gameData) PlayerStats.fromGameStats(g['stats']),
    ];
    final axes = skillProfile(key, games);

    if (axes == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: dashCard(isDark, radius: 16),
        child: Text(
          'Log 3+ games to see your skill profile.',
          style: GoogleFonts.inter(fontSize: 13, color: dashMuted(isDark)),
        ),
      );
    }

    // Profile as it stood 30 days before the latest game.
    final dates = [for (final g in widget.gameData) g['date'] as DateTime?];
    final latest = dates.whereType<DateTime>().fold<DateTime?>(
      null,
      (a, b) => a == null || b.isAfter(a) ? b : a,
    );
    List<SkillAxis>? ghost;
    if (latest != null) {
      final cutoff = latest.subtract(const Duration(days: _ghostDays));
      final earlier = [
        for (var i = 0; i < games.length; i++)
          if (dates[i] != null && !dates[i]!.isAfter(cutoff)) games[i],
      ];
      ghost = skillProfile(key, earlier);
    }
    final deltas = [
      for (var i = 0; i < axes.length; i++)
        ghost == null ? null : axes[i].score - ghost[i].score,
    ];

    final signal = trendSignal(key, games);
    final muted = dashMuted(isDark);
    final (String lead, Color leadColor) = switch (signal) {
      null => ('Your profile', dashText(isDark)),
      final s when !s.meaningful => ('Holding steady', dashText(isDark)),
      final s when s.better => ('Heating up', dashPositive),
      _ => ('Cooling off', dashNegative),
    };
    final perGame = isRatioStat(key) ? '' : '/game';
    final numbers = signal == null
        ? null
        : 'L${signal.window} ${formatPerGame(key, signal.recent)}$perGame vs season '
              '${formatPerGame(key, signal.season)}$perGame';
    String? mover;
    if (ghost != null) {
      var best = 0;
      for (var i = 1; i < axes.length; i++) {
        if (deltas[i]!.abs() > deltas[best]!.abs()) best = i;
      }
      final d = deltas[best]!.round();
      mover = d.abs() < _notablePoints
          ? 'No big changes in the last $_ghostDays days'
          : '${axes[best].label} ${d > 0 ? 'up' : 'down'} ${d.abs()} pts in $_ghostDays days';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: dashCard(isDark, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('SKILL PROFILE', style: sectionLabelStyle(isDark)),
              const Spacer(),
              Text(
                widget.statName,
                style: GoogleFonts.inter(fontSize: 11, color: muted),
              ),
              const SizedBox(width: 6),
              const HowToReadButton(
                title: 'Reading your skill profile',
                sections: _howToRead,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: lead,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: leadColor,
                  ),
                ),
                if (numbers != null)
                  TextSpan(
                    text: '  $numbers',
                    style: dashMono(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: dashText(isDark),
                    ),
                  ),
              ],
            ),
          ),
          if (mover != null) ...[
            const SizedBox(height: 3),
            Text(mover, style: GoogleFonts.inter(fontSize: 12.5, color: muted)),
          ],
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final geometry = _RadarGeometry(
                  constraints.biggest,
                  axes.length,
                );
                return GestureDetector(
                  onTapUp: (d) {
                    final i = geometry.axisAt(d.localPosition);
                    if (i != null) _jumpTo(i);
                  },
                  child: CustomPaint(
                    size: constraints.biggest,
                    painter: _RadarPainter(
                      axes: axes,
                      ghost: ghost,
                      geometry: geometry,
                      accent: statAccent(isDark),
                      grid: dashBorder(isDark),
                      strongGrid: muted.withValues(alpha: 0.45),
                      text: dashText(isDark),
                      muted: muted,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _legend(
                isDark,
                Container(width: 14, height: 3, color: statAccent(isDark)),
                'Now',
              ),
              if (ghost != null)
                _legend(
                  isDark,
                  Row(
                    children: [
                      Container(width: 5, height: 1.5, color: muted),
                      const SizedBox(width: 3),
                      Container(width: 5, height: 1.5, color: muted),
                    ],
                  ),
                  'You $_ghostDays days ago',
                ),
              _legend(
                isDark,
                const SizedBox.shrink(),
                'Tap a point for details',
              ),
            ],
          ),
          const SizedBox(height: 14),
          dashDivider(isDark),
          for (var i = 0; i < axes.length; i++) ...[
            if (i > 0) dashDivider(isDark),
            AnimatedContainer(
              key: _rowKeys[i],
              duration: const Duration(milliseconds: 250),
              color: _flashed == i
                  ? statAccent(isDark).withValues(alpha: 0.08)
                  : Colors.transparent,
              child: _AxisRow(
                axis: axes[i],
                delta: deltas[i],
                notable: _notablePoints,
                isDark: isDark,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _legend(bool isDark, Widget swatch, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      swatch,
      if (swatch is! SizedBox) const SizedBox(width: 6),
      Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, color: dashMuted(isDark)),
      ),
    ],
  );
}

const _howToRead = [
  (
    'The shape',
    'Each point is scored from 0 to 100. Further from the center is better. '
        'The brighter middle ring is 50: on Form that is exactly your season '
        'level, and on Streak it is a typical streak for you. The dashed shape '
        'is you 30 days ago, so you can see what has grown or shrunk.',
  ),
  (
    'The verdict',
    '"Heating up" or "Cooling off" appears only when your last 10 games are '
        'further from your season than your normal game-to-game swing. '
        'Otherwise it says "Holding steady".',
  ),
  (
    'Arrows',
    'Each row shows how many points it moved in the last 30 days. Gray '
        'arrows are small moves (under 10 points).',
  ),
  (
    'Form',
    'Your last 10 games (last 5 early in the season) compared with your '
        'season. 50 means the same as your season, above 50 means you are '
        'hotter than usual, below 50 cooler.',
  ),
  (
    'Frequency',
    'The share of your games that hit the bar shown: your season level for '
        'averages, or at least one for counting stats like hits and RBIs.',
  ),
  (
    'Streak',
    'Your current hit streak ranked against every hit streak you have had '
        'this season. 50 is a typical streak for you; a streak longer than all '
        'of them scores 100. Games where you didn\'t bat don\'t break it.',
  ),
  (
    'Peak',
    'Your season compared with your best stretch of games. 100 means your '
        'whole season is as good as your best run.',
  ),
  (
    'Steadiness',
    'How far single games usually land from your season level. Higher means '
        'fewer big ups and downs. One-at-bat games swing a lot, so averages '
        'naturally score lower here than counting stats.',
  ),
  (
    'Which games count',
    'Only games where the stat applies. A game with no at-bats has no '
        'batting average, so it is left out instead of counted as .000.',
  ),
  (
    'Tool grades',
    'Power, Contact and the other tool grades on your Home screen come from '
        'Scout (0–100, 75 = typical) and look at your whole game. This profile '
        'looks at one stat, compared with your own season.',
  ),
];

class _AxisRow extends StatelessWidget {
  final SkillAxis axis;

  /// Points gained or lost over the last 30 days; null without enough history.
  final double? delta;
  final int notable;
  final bool isDark;

  const _AxisRow({
    required this.axis,
    required this.delta,
    required this.notable,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const tabular = [FontFeature.tabularFigures()];
    final muted = dashMuted(isDark);
    final d = delta?.round();
    final arrowColor = d == null || d.abs() < notable
        ? muted
        : d > 0
        ? dashPositive
        : dashNegative;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                axis.label,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: dashText(isDark),
                ),
              ),
              Text(
                '  ·  ',
                style: GoogleFonts.inter(fontSize: 14, color: muted),
              ),
              Flexible(
                child: Text(
                  axis.raw,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: dashMono(
                    size: 15,
                    weight: FontWeight.w800,
                    color: dashText(isDark),
                  ),
                ),
              ),
              const Spacer(),
              if (d != null && d != 0) ...[
                Text(
                  '${d > 0 ? '▲' : '▼'}${d.abs()}',
                  style: dashMono(
                    size: 11,
                    weight: FontWeight.w700,
                    color: arrowColor,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                axis.score.round().toString(),
                style: dashMono(
                  size: 13,
                  weight: FontWeight.w700,
                  color: muted,
                ),
              ),
              Text(
                '/100',
                style: dashMono(
                  size: 9.5,
                  weight: FontWeight.w500,
                  color: muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 10,
            width: double.infinity,
            child: CustomPaint(
              painter: _ScoreBarPainter(
                fraction: axis.score / 100,
                color: statAccent(isDark),
                track: dashBorder(isDark),
                tick: muted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            axis.detail,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: dashText(isDark),
              fontFeatures: tabular,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            axis.meaning,
            style: GoogleFonts.inter(fontSize: 12.5, height: 1.3, color: muted),
          ),
        ],
      ),
    );
  }
}

class _ScoreBarPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color track;
  final Color tick;

  _ScoreBarPainter({
    required this.fraction,
    required this.color,
    required this.track,
    required this.tick,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const h = 6.0;
    final top = (size.height - h) / 2;
    const r = Radius.circular(1.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, top, size.width, h), r),
      Paint()..color = track,
    );
    final f = fraction.clamp(0.0, 1.0);
    if (f > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, top, size.width * f, h), r),
        Paint()..color = color,
      );
    }
    final x = size.width / 2;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = tick
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_ScoreBarPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.track != track ||
      old.tick != tick;
}

/// Shared layout so taps land on the same axes the painter draws.
class _RadarGeometry {
  final Offset center;
  final double radius;
  final int n;

  factory _RadarGeometry(Size size, int n) {
    // Room for two-line labels: ~36px above the top point, ~41px below the
    // lower points (they sit at sin 54° of the radius), ~72px at the sides.
    final radius = math.min(size.width / 2 - 72, (size.height - 77) / 1.81);
    return _RadarGeometry._(Offset(size.width / 2, 36 + radius), radius, n);
  }

  const _RadarGeometry._(this.center, this.radius, this.n);

  Offset point(int i, double fraction) {
    final angle = -math.pi / 2 + i * 2 * math.pi / n;
    return center +
        Offset(math.cos(angle), math.sin(angle)) * radius * fraction;
  }

  /// Nearest axis to a tap, ignoring taps near the center or far outside.
  int? axisAt(Offset p) {
    final v = p - center;
    if (v.distance < radius * 0.25 || v.distance > radius + 80) return null;
    var angle = math.atan2(v.dy, v.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    return (angle / (2 * math.pi / n)).round() % n;
  }
}

/// Fixed 0–100 radar with banded rings at 25/50/75/100 so shapes compare
/// across stats, plus an optional dashed "30 days ago" shape.
class _RadarPainter extends CustomPainter {
  final List<SkillAxis> axes;
  final List<SkillAxis>? ghost;
  final _RadarGeometry geometry;
  final Color accent;
  final Color grid;
  final Color strongGrid;
  final Color text;
  final Color muted;

  _RadarPainter({
    required this.axes,
    required this.ghost,
    required this.geometry,
    required this.accent,
    required this.grid,
    required this.strongGrid,
    required this.text,
    required this.muted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    final n = axes.length;

    Path polygon(double Function(int) fraction) {
      final first = g.point(0, fraction(0));
      final path = Path()..moveTo(first.dx, first.dy);
      for (var i = 1; i < n; i++) {
        final p = g.point(i, fraction(i));
        path.lineTo(p.dx, p.dy);
      }
      return path..close();
    }

    // Bands: below 50, 50–75, 75–100, getting lighter toward the edge.
    for (final (outer, alpha) in [(1.0, 0.07), (0.75, 0.05), (0.5, 0.03)]) {
      canvas.drawPath(
        polygon((_) => outer),
        Paint()..color = muted.withValues(alpha: alpha),
      );
    }
    for (final ring in [0.25, 0.5, 0.75, 1.0]) {
      canvas.drawPath(
        polygon((_) => ring),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring == 0.5 ? 1.4 : 1
          ..color = ring == 0.5 ? strongGrid : grid,
      );
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(g.center, g.point(i, 1), Paint()..color = grid);
    }

    for (final (ring, label) in [(50, '50 · season level'), (100, '100')]) {
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: dashMono(size: 8.5, weight: FontWeight.w600, color: muted),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = g.point(0, ring / 100);
      tp.paint(canvas, Offset(p.dx + 4, p.dy - tp.height / 2));
    }

    final ghost = this.ghost;
    if (ghost != null) {
      final path = polygon((i) => (ghost[i].score / 100).clamp(0.02, 1.0));
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = muted;
      for (final metric in path.computeMetrics()) {
        for (double d = 0; d < metric.length; d += 7) {
          canvas.drawPath(
            metric.extractPath(d, math.min(d + 4, metric.length)),
            paint,
          );
        }
      }
    }

    final shape = polygon((i) => (axes[i].score / 100).clamp(0.02, 1.0));
    canvas.drawPath(shape, Paint()..color = accent.withValues(alpha: 0.18));
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = accent,
    );
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(
        g.point(i, (axes[i].score / 100).clamp(0.02, 1.0)),
        3,
        Paint()..color = accent,
      );
    }

    for (var i = 0; i < n; i++) {
      final tp = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        text: TextSpan(
          children: [
            TextSpan(
              text: '${axes[i].label}\n',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
            TextSpan(
              text: axes[i].raw,
              style: dashMono(size: 11, weight: FontWeight.w700, color: text),
            ),
          ],
        ),
      )..layout();
      final edge = g.point(i, 1);
      final dir = edge - g.center;
      final unit = dir / dir.distance;
      final anchor = edge + unit * 14;
      final dx = unit.dx.abs() < 0.2
          ? -tp.width / 2
          : (unit.dx > 0 ? 0.0 : -tp.width);
      final dy = unit.dy < -0.5
          ? -tp.height
          : (unit.dy > 0.5 ? 0.0 : -tp.height / 2);
      tp.paint(canvas, anchor + Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.axes != axes ||
      old.ghost != ghost ||
      old.accent != accent ||
      old.grid != grid ||
      old.text != text;
}
