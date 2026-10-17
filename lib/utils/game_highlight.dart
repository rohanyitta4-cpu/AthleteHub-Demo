import '../models/hitting_profile.dart';
import '../player_stats.dart';

enum HighlightTone { positive, neutral, negative }

class GameHighlight {
  final String text;
  final HighlightTone tone;

  const GameHighlight(this.text, this.tone);
}

String _plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

/// Box-score style line, e.g. "2-for-4 · 2B, HR, 3 RBI, BB".
String gameLine(PlayerStats s) {
  final extras = <String>[];
  void add(int n, String label) {
    if (n <= 0) return;
    extras.add(n == 1 ? label : '$n $label');
  }

  add(s.doubles, '2B');
  add(s.triples, '3B');
  add(s.homeRuns, 'HR');
  if (s.runsBattedIn > 0) extras.add('${s.runsBattedIn} RBI');
  add(s.runs, 'R');
  add(s.walks, 'BB');
  add(s.hitByPitch, 'HBP');
  add(s.stolenBases, 'SB');
  add(s.strikeouts, 'K');

  final base = '${s.hits}-for-${s.atBats}';
  return extras.isEmpty ? base : '$base · ${extras.join(', ')}';
}

/// One-line takeaway for a single game, judged by what [profile] values most.
GameHighlight gameHighlight(PlayerStats s, HittingProfile? profile) {
  final pa = s.plateAppearances;
  if (pa == 0) {
    return const GameHighlight('No plate appearances logged', HighlightTone.neutral);
  }

  switch (profile) {
    case HittingProfile.power:
      return _powerHighlight(s);
    case HittingProfile.contact:
      return _contactHighlight(s);
    case HittingProfile.onBase:
      return _onBaseHighlight(s);
    case null:
      return _overallHighlight(s);
  }
}

/// Current streaks counted back from the most recent game.
class Streaks {
  final int hit;
  final int onBase;

  const Streaks({required this.hit, required this.onBase});
}

/// [games] oldest first. Games with no plate appearances neither extend nor
/// break a streak.
Streaks currentStreaks(List<PlayerStats> games) {
  int count(bool Function(PlayerStats) kept) {
    var n = 0;
    for (final s in games.reversed) {
      if (s.plateAppearances == 0) continue;
      if (!kept(s)) break;
      n++;
    }
    return n;
  }

  return Streaks(
    hit: count((s) => s.hits > 0),
    onBase: count((s) => _timesOnBase(s) > 0),
  );
}

/// Longest run of games with a hit this season, same rules as [currentStreaks].
int longestHitStreak(List<PlayerStats> games) {
  var best = 0;
  var run = 0;
  for (final s in games) {
    if (s.plateAppearances == 0) continue;
    run = s.hits > 0 ? run + 1 : 0;
    if (run > best) best = run;
  }
  return best;
}

int _totalBases(PlayerStats s) =>
    s.hits + s.doubles + 2 * s.triples + 3 * s.homeRuns;

int _timesOnBase(PlayerStats s) => s.hits + s.walks + s.hitByPitch;

GameHighlight _powerHighlight(PlayerStats s) {
  final tb = _totalBases(s);
  final xbh = s.doubles + s.triples + s.homeRuns;
  if (s.homeRuns > 0) {
    final hr = s.homeRuns == 1 ? 'Homered' : '${s.homeRuns} home runs';
    return GameHighlight('$hr, ${_plural(tb, 'total base')}', HighlightTone.positive);
  }
  if (xbh > 0) {
    return GameHighlight(
      '${_plural(xbh, 'extra-base hit')}, ${_plural(tb, 'total base')}',
      HighlightTone.positive,
    );
  }
  if (s.hits > 0) {
    return GameHighlight(
      'Singles only: ${_plural(tb, 'total base')}',
      HighlightTone.neutral,
    );
  }
  return GameHighlight(
    s.strikeouts > 0
        ? 'No extra-base damage, ${_plural(s.strikeouts, 'strikeout')}'
        : 'No extra-base damage',
    HighlightTone.negative,
  );
}

GameHighlight _contactHighlight(PlayerStats s) {
  final ab = s.atBats;
  if (s.hits >= 2 && s.strikeouts == 0) {
    return GameHighlight('${s.hits} hits with no strikeouts', HighlightTone.positive);
  }
  if (s.hits >= 2) {
    return GameHighlight('Multi-hit game: ${s.hits}-for-$ab', HighlightTone.positive);
  }
  if (ab > 0 && s.strikeouts == 0) {
    return GameHighlight(
      'Put all ${_plural(ab, 'at-bat')} in play',
      s.hits > 0 ? HighlightTone.positive : HighlightTone.neutral,
    );
  }
  if (s.hits == 1) {
    return GameHighlight(
      '1 hit, ${_plural(s.strikeouts, 'strikeout')}',
      HighlightTone.neutral,
    );
  }
  if (ab == 0) {
    return const GameHighlight('No official at-bats', HighlightTone.neutral);
  }
  return GameHighlight(
    s.strikeouts > 0
        ? 'Hitless with ${_plural(s.strikeouts, 'strikeout')}'
        : 'Hitless in ${_plural(ab, 'at-bat')}',
    HighlightTone.negative,
  );
}

GameHighlight _onBaseHighlight(PlayerStats s) {
  final pa = s.plateAppearances;
  final onBase = _timesOnBase(s);
  final freePasses = s.walks + s.hitByPitch;
  final reached = 'Reached base $onBase of $pa times';
  if (onBase >= 3 || onBase / pa >= 0.6) {
    return GameHighlight(reached, HighlightTone.positive);
  }
  if (freePasses > 0) {
    final drew = s.walks > 0 ? 'Drew ${_plural(s.walks, 'walk')}' : 'Hit by a pitch';
    return GameHighlight('$drew, reached $onBase of $pa', HighlightTone.positive);
  }
  if (onBase > 0) return GameHighlight(reached, HighlightTone.neutral);
  return GameHighlight("Didn't reach base in ${_plural(pa, 'trip')}", HighlightTone.negative);
}

GameHighlight _overallHighlight(PlayerStats s) {
  final onBase = _timesOnBase(s);
  if (s.homeRuns > 0) {
    return GameHighlight(
      s.homeRuns == 1 ? 'Homered' : '${s.homeRuns} home runs',
      HighlightTone.positive,
    );
  }
  if (s.hits >= 2) {
    return GameHighlight('Multi-hit game: ${s.hits}-for-${s.atBats}', HighlightTone.positive);
  }
  if (onBase > 0) {
    return GameHighlight(
      'Reached base $onBase of ${s.plateAppearances} times',
      HighlightTone.neutral,
    );
  }
  return GameHighlight(
    "Didn't reach base in ${_plural(s.plateAppearances, 'trip')}",
    HighlightTone.negative,
  );
}
