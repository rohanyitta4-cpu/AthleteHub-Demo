import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App supports exactly two persisted theme ids: [light_bw], [dark_bw_simple].
String canonicalThemeId(String? stored) {
  final s = stored ?? 'light_bw';
  if (s == 'dark_bw_simple') return 'dark_bw_simple';
  if (s == 'light_bw') return 'light_bw';
  if (s.startsWith('dark')) return 'dark_bw_simple';
  return 'light_bw';
}

class ThemeProvider extends ChangeNotifier {
  String _currentTheme = 'light_bw';

  String get currentTheme => _currentTheme;

  void setTheme(String themeName) {
    _currentTheme = canonicalThemeId(themeName);
    _saveThemePreference();
    notifyListeners();
  }

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentTheme', _currentTheme);
  }

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _currentTheme = canonicalThemeId(prefs.getString('currentTheme'));
    notifyListeners();
  }

  bool get isDarkMode => _currentTheme == 'dark_bw_simple';
}
