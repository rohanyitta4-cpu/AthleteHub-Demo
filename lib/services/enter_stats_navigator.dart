import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnterStatsNavigator {
  static const String _entryModeKey = 'stats_entry_mode';

  /// AI / Zuno chat entry (`EnterStatsFormScreen` / `StatsQuizScreen`).
  static const String formMode = 'form';

  /// Default for new installs — fast flashcard entry; Zuno chat is opt-in (Pro).
  static const String flashcardMode = 'flashcard';

  static Future<void> navigateToStatsEntry(
    BuildContext context, {
    String? teamName,
  }) async {
    if (!context.mounted) return;
    Navigator.of(context).pushNamed('/stats_entry');
  }

  static Future<void> navigateToStatsForm(
    BuildContext context, {
    String? teamName,
  }) async {
    if (!context.mounted) return;
    Navigator.of(context).pushNamed('/stats_entry');
  }

  static Future<String> getEntryMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_entryModeKey) ?? flashcardMode;
  }

  static Future<void> setEntryMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_entryModeKey, mode);
  }
}
