import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'rank_accent.dart';

/// Brand blue, or the player's rank color when "Match accents" is on.
Color statAccent(bool isDark) =>
    RankAccent.instance.color(isDark) ?? (isDark ? const Color(0xFF4F8CFF) : const Color(0xFF2563EB));

TextStyle sectionLabelStyle(bool isDark) => GoogleFonts.inter(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: isDark ? Colors.grey[500] : Colors.grey[700],
  letterSpacing: 1.1,
);

const double sectionLabelGap = 14;

List<BoxShadow> activePillShadow(bool isDark) => [
  BoxShadow(
    color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.18),
    blurRadius: 8,
    offset: const Offset(0, 3),
  ),
  BoxShadow(
    color: (isDark ? Colors.white : statAccent(isDark)).withValues(alpha: isDark ? 0.22 : 0.18),
    blurRadius: 14,
    spreadRadius: -2,
  ),
];

const List<Color> rainbowColors = [
  Color(0xFFFF3B30),
  Color(0xFFFF9500),
  Color(0xFFFFCC00),
  Color(0xFF34C759),
  Color(0xFF00C7BE),
  Color(0xFF007AFF),
  Color(0xFFAF52DE),
  Color(0xFFFF2D55),
  Color(0xFFFF3B30),
];

class GradientBorderCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? fill;

  const GradientBorderCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 16,
    this.fill,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = statAccent(isDark);
    final borderGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              Colors.white.withValues(alpha: 0.28),
              accent.withValues(alpha: 0.35),
              Colors.white.withValues(alpha: 0.04),
              const Color(0xFF10B981).withValues(alpha: 0.30),
            ]
          : [
              accent.withValues(alpha: 0.35),
              Colors.black.withValues(alpha: 0.06),
              const Color(0xFF10B981).withValues(alpha: 0.30),
            ],
    );

    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        gradient: borderGradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: fill ?? (isDark ? const Color(0xFF15171A) : Colors.white),
          borderRadius: BorderRadius.circular(radius - 1),
        ),
        child: child,
      ),
    );
  }
}
