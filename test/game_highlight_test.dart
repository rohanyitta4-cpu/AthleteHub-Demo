import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_first_app_vsc/models/hitting_profile.dart';
import 'package:flutter_first_app_vsc/player_stats.dart';
import 'package:flutter_first_app_vsc/utils/game_highlight.dart';

PlayerStats game(Map<String, dynamic> stats) => PlayerStats.fromGameStats(stats);

void main() {
  final homerGame = game({
    'atBats': 4, 'hits': 2, 'doubles': 1, 'homeRuns': 1,
    'runsBattedIn': 3, 'walks': 1, 'strikeouts': 1,
  });
  final singlesNoK = game({'atBats': 4, 'hits': 2, 'strikeouts': 0});
  final walksOnly = game({'atBats': 2, 'hits': 0, 'walks': 2, 'strikeouts': 1});
  final hitless = game({'atBats': 4, 'hits': 0, 'strikeouts': 3});

  test('game line lists hits, extras and strikeouts', () {
    expect(gameLine(homerGame), '2-for-4 · 2B, HR, 3 RBI, BB, K');
    expect(gameLine(singlesNoK), '2-for-4');
  });

  test('power profile rewards extra-base damage', () {
    final h = gameHighlight(homerGame, HittingProfile.power);
    expect(h.text, 'Homered, 6 total bases');
    expect(h.tone, HighlightTone.positive);
    expect(gameHighlight(singlesNoK, HittingProfile.power).tone, HighlightTone.neutral);
    expect(gameHighlight(hitless, HittingProfile.power).tone, HighlightTone.negative);
  });

  test('contact profile rewards hits without strikeouts', () {
    final h = gameHighlight(singlesNoK, HittingProfile.contact);
    expect(h.text, '2 hits with no strikeouts');
    expect(h.tone, HighlightTone.positive);
    expect(gameHighlight(hitless, HittingProfile.contact).text, 'Hitless with 3 strikeouts');
  });

  test('on-base profile counts walks as a good game', () {
    final h = gameHighlight(walksOnly, HittingProfile.onBase);
    expect(h.text, 'Drew 2 walks, reached 2 of 4');
    expect(h.tone, HighlightTone.positive);
    expect(gameHighlight(hitless, HittingProfile.onBase).text, "Didn't reach base in 4 trips");
  });

  test('streaks count back from the latest game and skip empty games', () {
    final streaks = currentStreaks([homerGame, hitless, singlesNoK, PlayerStats(), walksOnly]);
    expect(streaks.hit, 0);
    expect(streaks.onBase, 2);
    expect(currentStreaks([hitless, homerGame, singlesNoK]).hit, 2);
    expect(currentStreaks(const []).hit, 0);
  });

  test('no profile falls back to an overall read', () {
    expect(gameHighlight(homerGame, null).text, 'Homered');
    expect(gameHighlight(PlayerStats(), null).text, 'No plate appearances logged');
  });
}
