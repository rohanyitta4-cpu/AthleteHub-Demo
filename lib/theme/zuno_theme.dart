import 'package:flutter/material.dart';

import 'zuno_colors.dart';

export 'zuno_colors.dart';

/// Theme-aware Zuno chat colors. Use `context.bg`, `context.accent`, etc.
extension ZunoTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bg => isDark ? ZunoColors.darkBg : ZunoColors.lightBg;

  Color get surface => isDark ? ZunoColors.darkSurface : ZunoColors.lightSurface;

  Color get surface2 => isDark ? ZunoColors.darkSurface2 : ZunoColors.lightSurface2;

  Color get accent => isDark ? ZunoColors.darkAccent : ZunoColors.lightAccent;

  Color get onAccent => isDark ? ZunoColors.darkOnAccent : ZunoColors.lightOnAccent;

  Color get textPrimary => isDark ? ZunoColors.darkText : ZunoColors.lightText;

  Color get textMuted => isDark ? ZunoColors.darkMuted : ZunoColors.lightMuted;

  Color get border => isDark ? ZunoColors.darkBorder : ZunoColors.lightBorder;

  /// Action row chips inside AI bubble (slightly off surface2).
  Color get actionChip => isDark ? ZunoColors.darkActionChip : ZunoColors.lightActionChip;
}
