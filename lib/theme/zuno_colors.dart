import 'package:flutter/material.dart';

/// Shared palette for Zuno chat (and aligned app surfaces). Dark ↔ light are inverted accents.
class ZunoColors {
  ZunoColors._();

  // Backgrounds
  static const darkBg = Color(0xFF0C0C0C);
  static const lightBg = Color(0xFFFFFFFF);

  // Surface (bubble/card bg)
  static const darkSurface = Color(0xFF1C1C1C);
  static const lightSurface = Color(0xFFF2F2F2);

  // Surface secondary (chips, inner elements)
  static const darkSurface2 = Color(0xFF2A2A2A);
  static const lightSurface2 = Color(0xFFE0E0E0);

  // Accent (user bubble, send btn, avatar circle, + in input)
  static const darkAccent = Color(0xFFFFFFFF);
  static const lightAccent = Color(0xFF111111);

  // On-accent text / icon
  static const darkOnAccent = Color(0xFF111111);
  static const lightOnAccent = Color(0xFFFFFFFF);

  // Primary text (message body)
  static const darkText = Color(0xFFE0E0E0);
  static const lightText = Color(0xFF222222);

  // Muted text (ZUNO chip, hints)
  static const darkMuted = Color(0xFF777777);
  static const lightMuted = Color(0xFF888888);

  // Divider / border
  static const darkBorder = Color(0xFF2A2A2A);
  static const lightBorder = Color(0xFFE5E5E5);

  /// Action row chips inside AI bubble (slightly off surface2).
  static const darkActionChip = Color(0xFF222222);
  static const lightActionChip = Color(0xFFD8D8D8);
}
