import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/player_rank.dart';

const _enabledKey = 'rankAccent.enabled';
const _scoreKey = 'rankAccent.score';

/// App-wide accent from the player's AthleteHub rank. Off by default (brand blue).
/// Persists the last score so accents are correct before the report reloads.
class RankAccent extends ChangeNotifier {
  RankAccent._();
  static final instance = RankAccent._();

  bool _enabled = false;
  int? _score;
  int? _previewScore;

  bool get enabled => _enabled;
  int? get score => _score;

  /// Dev Themes slider override; not persisted.
  int? get previewScore => _previewScore;

  RankTier? get tier {
    final s = _previewScore ?? _score;
    return _enabled && s != null ? rankFor(s) : null;
  }

  void setPreviewScore(int? value) {
    if (value == _previewScore) return;
    _previewScore = value;
    notifyListeners();
  }

  /// Bright on dark UI, deep on light (so gold/amber stay readable).
  Color? color(bool isDark) {
    final t = tier;
    if (t == null) return null;
    return isDark ? t.bright : t.deep;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;
    _score = prefs.getInt(_scoreKey);
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (value == _enabled) return;
    _enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  Future<void> setScore(int? value) async {
    if (value == _score) return;
    _score = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_scoreKey);
    } else {
      await prefs.setInt(_scoreKey, value);
    }
  }
}

/// Theme extension so Material rebuilds when the rank accent changes.
@immutable
class RankAccentTheme extends ThemeExtension<RankAccentTheme> {
  final Color? accent;
  const RankAccentTheme(this.accent);

  @override
  RankAccentTheme copyWith({Color? accent}) => RankAccentTheme(accent ?? this.accent);

  @override
  RankAccentTheme lerp(RankAccentTheme? other, double t) => RankAccentTheme(Color.lerp(accent, other?.accent, t));
}
