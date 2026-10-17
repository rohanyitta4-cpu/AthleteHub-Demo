import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_first_app_vsc/player_stats.dart';
import 'package:flutter_first_app_vsc/utils/chart_data_preparer.dart';
import 'package:flutter_first_app_vsc/utils/stat_key_map.dart';

void main() {
  final tracked = {
    'stats': {
      'atBats': 4, 'hits': 2, 'walks': 2, 'intentionalWalks': 1,
      'strikeouts': 1, 'sacrificeFlies': 1, 'hitByPitch': 0,
      'hardHitBalls': 2, 'qualityAtBats': 4,
    }
  };
  final untracked = {
    'stats': {'atBats': 3, 'hits': 0, 'strikeouts': 2, 'walks': 0}
  };

  test('textbook OBP counts sac flies in the denominator', () {
    final s = PlayerStats.fromGameStats(tracked['stats']);
    expect(s.onBasePercentage, closeTo(4 / 7, 1e-9));
    expect(s.plateAppearances, 7);
    expect(s.unintentionalWalks, 1);
  });

  test('tracked rates ignore games where the stat was not logged', () {
    final total = PlayerStats.sumGames([tracked, untracked]);
    expect(total.hardHitGames, 1);
    expect(total.hardHitBallsInPlay, 4); // 4 AB - 1 K + 1 SF
    expect(total.hardHitRate, closeTo(0.5, 1e-9));
    expect(total.qualityAtBatRate, closeTo(4 / 7, 1e-9));
    expect(total.statValue('Hard-Hit Rate'), closeTo(0.5, 1e-9));
    expect(PlayerStats.sumGames([untracked]).statValue('Hard-Hit Rate'), isNull);
  });

  test('aggregated JSON round-trips its tracked denominators', () {
    final total = PlayerStats.sumGames([tracked, untracked, tracked]);
    final back = PlayerStats.fromJson(total.toJson());
    expect(back.hardHitBallsInPlay, total.hardHitBallsInPlay);
    expect(back.qabPlateAppearances, total.qabPlateAppearances);
    expect(back.hardHitGames, 2);
  });

  test('charts and stat pages skip untracked games', () {
    final games = [tracked, untracked, tracked].cast<Map<String, dynamic>>();
    expect(ChartDataPreparer.getStatValues('Hard-Hit Rate', games).length, 2);
    expect(ChartDataPreparer.gamesWithStat('Hard-Hit Rate', games).length, 2);
    expect(ChartDataPreparer.gamesWithStat('Hits', games).length, 3);
    expect(formatStatValue('Hard-Hit Rate', 0.5), '50%');
    expect(formatStatValue('On-Base Percentage', 4 / 7), '0.571');
  });
}
