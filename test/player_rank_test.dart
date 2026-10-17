import 'dart:math' as math;

import 'package:flutter_first_app_vsc/utils/player_rank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tiers cover 0–100 with no gaps or overlaps', () {
    for (var s = 0; s <= 100; s++) {
      expect(rankTiers.where((t) => t.contains(s)).length, 1, reason: 'score $s');
    }
  });

  test('rank boundaries match the spec', () {
    expect(rankFor(0).name, 'Kicking Rocks');
    expect(rankFor(19).name, 'Kicking Rocks');
    expect(rankFor(20).name, 'Benchwarmer');
    expect(rankFor(59).name, 'Average Joe');
    expect(rankFor(60).name, 'On the Radar');
    expect(rankFor(82).name, 'Elite Threat');
    expect(rankFor(94).name, 'Elite Threat');
    expect(rankFor(95).name, 'Generational Athlete');
    expect(rankFor(100).name, 'Generational Athlete');
  });

  test('each tier has six phrases', () {
    for (final t in rankTiers) {
      expect(t.phrases.length, 6, reason: t.name);
    }
  });

  test('pickPhrase never repeats the previous phrase', () {
    final rng = math.Random(1);
    for (final t in rankTiers) {
      var prev = t.phrases.first;
      for (var i = 0; i < 50; i++) {
        final next = pickPhrase(t, previous: prev, random: rng);
        expect(next, isNot(prev));
        expect(t.phrases, contains(next));
        prev = next;
      }
    }
  });

  test('nextRank walks up and stops at the top', () {
    expect(nextRank(rankFor(82))!.name, 'Generational Athlete');
    expect(nextRank(rankFor(99)), isNull);
  });

  test('progressTowardNextRank is within the current band', () {
    expect(progressTowardNextRank(20, rankFor(20)), 0);
    expect(progressTowardNextRank(30, rankFor(30)), closeTo(0.5, 0.001));
    expect(progressTowardNextRank(39, rankFor(39)), closeTo(0.95, 0.001));
    expect(progressTowardNextRank(95, rankFor(95)), 0);
    expect(progressTowardNextRank(100, rankFor(100)), 1);
  });
}
