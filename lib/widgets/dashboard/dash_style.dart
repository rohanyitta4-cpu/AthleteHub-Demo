import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const dashPositive = Color(0xFF10B981);
const dashWarning = Color(0xFFF59E0B);
const dashNegative = Color(0xFFEF4444);

Color dashSurface(bool isDark) => isDark ? const Color(0xFF161618) : Colors.white;

Color dashBorder(bool isDark) => isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE4E4E7);

Color dashText(bool isDark) => isDark ? Colors.white : const Color(0xFF111111);

Color dashMuted(bool isDark) => isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.64);

BoxDecoration dashCard(bool isDark, {double radius = 14}) => BoxDecoration(
  color: dashSurface(isDark),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: dashBorder(isDark)),
);

/// Scorebook monospace (tabular figures).
TextStyle dashMono({required double size, FontWeight weight = FontWeight.w600, Color? color, double? height}) =>
    GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

TextStyle dashLabel(bool isDark, {double size = 10}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w700, letterSpacing: 1, color: dashMuted(isDark));

Widget dashDivider(bool isDark) => Container(height: 1, color: dashBorder(isDark));

/// Tool-grade color: 78+ above typical, under 72 below, else neutral.
Color dashScoreColor(int score, bool isDark) {
  if (score >= 78) return dashPositive;
  if (score >= 72) return isDark ? Colors.white70 : Colors.black54;
  return dashWarning;
}
