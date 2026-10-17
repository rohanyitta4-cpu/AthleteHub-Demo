import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_first_app_vsc/player_stats.dart';
import 'package:flutter_first_app_vsc/utils/skill_profile.dart';

PlayerStats game(int hits, int atBats) =>
    PlayerStats.fromGameStats({'atBats': atBats, 'hits': hits});

void main() {
  test('needs 3 games', () {
    expect(skillProfile('battingAverage', [game(1, 4), game(1, 4)]), isNull);
  });

  test('every hit .250 game: steady, at season level, streak at its longest', () {
    final axes = skillProfile('battingAverage', List.generate(6, (_) => game(1, 4)))!;
    final byLabel = {for (final a in axes) a.label: a};
    expect(byLabel['Form']!.score, 50);
    expect(byLabel['Frequency']!.score, 100);
    expect(byLabel['Streak']!.score, 100);
    expect(byLabel['Streak']!.detail, '6 active · best 6');
    expect(byLabel['Peak']!.score, 100);
    expect(byLabel['Steadiness']!.score, 100);
    expect(byLabel['Form']!.detail, 'Last 5 games .250 · season .250');
  });

  test('hot finish raises Form and uses the Dashboard hit streak', () {
    final games = [game(0, 4), game(0, 4), game(0, 4), game(0, 4), game(0, 4), game(2, 4), game(2, 4)];
    final axes = {for (final a in skillProfile('battingAverage', games)!) a.label: a};
    expect(axes['Form']!.score, greaterThan(50));
    expect(axes['Form']!.raw, '.200 L5');
    expect(axes['Streak']!.detail, '2 active · best 2');
    expect(axes['Frequency']!.detail, '2 of 7 games at .143 or better');
  });

  test('an active streak shorter than the best still ranks well against your other streaks', () {
    // Finished streaks of 1, 1, 2 and 40, then a 6-game streak still going.
    final games = [
      for (final run in [1, 1, 2, 40]) ...[for (var i = 0; i < run; i++) game(1, 3), game(0, 3)],
      for (var i = 0; i < 6; i++) game(1, 3),
    ];
    final streak = {for (final a in skillProfile('battingAverage', games)!) a.label: a}['Streak']!;
    expect(streak.detail, '6 active · best 40');
    expect(streak.raw, '6 active');
    expect(streak.score, 75);
  });

  test('Form only calls a change meaningful when it beats normal swing', () {
    // Alternating 1-for-4 and 3-for-4 games: a .500 hitter whose last 10 are
    // also .500 should read as normal, not hot or cold.
    final games = [for (var i = 0; i < 30; i++) i.isEven ? game(1, 4) : game(3, 4)];
    final form = {for (final a in skillProfile('battingAverage', games)!) a.label: a}['Form']!;
    expect(form.meaning, 'Within your normal game-to-game swing');
  });

  test('steadiness is measured around the true season level', () {
    // Per-game averages mean .625; the season is 2-for-5 = .400.
    final axes = {for (final a in skillProfile('battingAverage', [game(1, 1), game(1, 4), game(0, 0)])!) a.label: a};
    expect(axes['Steadiness']!.detail, contains('of .400'));
  });
}
