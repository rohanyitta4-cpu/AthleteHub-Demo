import 'utils/stat_key_map.dart';

/// Picks the first non-null numeric value for Firestore keys (camelCase, snake_case,
/// or human labels written by flashcard entry).
int _readStatsInt(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v == null) continue;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is num) return v.toInt();
    final p = int.tryParse(v.toString());
    if (p != null) return p;
  }
  return 0;
}

double _readStatsDouble(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v == null) continue;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    final p = double.tryParse(v.toString());
    if (p != null) return p;
  }
  return 0.0;
}

/// Like [_readStatsInt], but returns null when none of the keys are present,
/// so "not tracked this game" stays distinguishable from a logged 0.
int? _readOptionalInt(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (json[k] == null) continue;
    return _readStatsInt(json, [k]);
  }
  return null;
}

class PlayerStats {
  // Raw input stats
  int atBats;
  int runs;
  int hits;
  int doubles;
  int triples;
  int homeRuns;
  int walks;
  int hitByPitch;
  int strikeouts;
  /// Sacrifice bunts (official "SH"). Games logged before sacrifice flies had
  /// their own field may include flies here too.
  int sacrificeHits;
  int sacrificeFlies;
  /// Subset of [walks].
  int intentionalWalks;
  int stolenBases;
  int runsBattedIn;
  int twoStrikeCounts;
  int successWithTwoStrikes;
  double inningsPitched;
  int earnedRuns;
  int totalPitches;

  // Optional per-game stats. Rates only use games where the player logged
  // them, so the denominators are accumulated alongside the counts.
  int hardHitBalls;
  int hardHitGames;
  int hardHitBallsInPlay;
  int qualityAtBats;
  int qabGames;
  int qabPlateAppearances;

  // Tracking stats over time for graphs
  List<double> battingAverages;
  List<double> sluggingPercentages;
  List<double> warList;
  List<double> eraList;
  List<double> strikeoutsList;
  List<double> pitchesList;
  List<double> battingAveragesMonthly;
  List<double> eraListMonthly;
  List<double> atBatsList;
  List<double> runsList;
  List<double> hitsList;
  List<double> doublesList;
  List<double> triplesList;
  List<double> homeRunsList;
  List<double> walksList;
  List<double> hitByPitchList;
  List<double> sacrificeHitsList;
  List<double> stolenBasesList;
  List<double> runsBattedInList;
  List<double> twoStrikeCountsList;
  List<double> successWithTwoStrikesList;
  List<double> inningsPitchedList;
  List<double> earnedRunsList;

  PlayerStats({
    this.atBats = 0,
    this.runs = 0,
    this.hits = 0,
    this.doubles = 0,
    this.triples = 0,
    this.homeRuns = 0,
    this.walks = 0,
    this.hitByPitch = 0,
    this.strikeouts = 0,
    this.sacrificeHits = 0,
    this.sacrificeFlies = 0,
    this.intentionalWalks = 0,
    this.stolenBases = 0,
    this.runsBattedIn = 0,
    this.twoStrikeCounts = 0,
    this.successWithTwoStrikes = 0,
    this.inningsPitched = 0.0,
    this.earnedRuns = 0,
    this.totalPitches = 0,
    this.hardHitBalls = 0,
    this.hardHitGames = 0,
    this.hardHitBallsInPlay = 0,
    this.qualityAtBats = 0,
    this.qabGames = 0,
    this.qabPlateAppearances = 0,
    List<double>? battingAverages,
    List<double>? sluggingPercentages,
    List<double>? warList,
    List<double>? eraList,
    List<double>? strikeoutsList,
    List<double>? pitchesList,
    List<double>? battingAveragesMonthly,
    List<double>? eraListMonthly,
    List<double>? atBatsList,
    List<double>? runsList,
    List<double>? hitsList,
    List<double>? doublesList,
    List<double>? triplesList,
    List<double>? homeRunsList,
    List<double>? walksList,
    List<double>? hitByPitchList,
    List<double>? sacrificeHitsList,
    List<double>? stolenBasesList,
    List<double>? runsBattedInList,
    List<double>? twoStrikeCountsList,
    List<double>? successWithTwoStrikesList,
    List<double>? inningsPitchedList,
    List<double>? earnedRunsList,
  })  : battingAverages = battingAverages ?? [],
        sluggingPercentages = sluggingPercentages ?? [],
        warList = warList ?? [],
        eraList = eraList ?? [],
        strikeoutsList = strikeoutsList ?? [],
        pitchesList = pitchesList ?? [],
        battingAveragesMonthly = battingAveragesMonthly ?? [],
        eraListMonthly = eraListMonthly ?? [],
        atBatsList = atBatsList ?? [],
        runsList = runsList ?? [],
        hitsList = hitsList ?? [],
        doublesList = doublesList ?? [],
        triplesList = triplesList ?? [],
        homeRunsList = homeRunsList ?? [],
        walksList = walksList ?? [],
        hitByPitchList = hitByPitchList ?? [],
        sacrificeHitsList = sacrificeHitsList ?? [],
        stolenBasesList = stolenBasesList ?? [],
        runsBattedInList = runsBattedInList ?? [],
        twoStrikeCountsList = twoStrikeCountsList ?? [],
        successWithTwoStrikesList = successWithTwoStrikesList ?? [],
        inningsPitchedList = inningsPitchedList ?? [],
        earnedRunsList = earnedRunsList ?? [];

  double get battingAverage {
    if (atBats <= 0) return 0.0;
    // Batting average should never exceed 1.000 (you can't get more hits than at bats)
    final avg = hits / atBats;
    return avg.clamp(0.0, 1.0);
  }
  double get sluggingPercentage => atBats > 0 ? (hits + doubles + 2 * triples + 3 * homeRuns) / atBats : 0.0;

  /// (H + BB + HBP) / (AB + BB + HBP + SF). Intentional walks count, sac bunts don't.
  double get onBasePercentage {
    final denom = atBats + walks + hitByPitch + sacrificeFlies;
    return denom > 0 ? (hits + walks + hitByPitch) / denom : 0.0;
  }

  int get plateAppearances =>
      atBats + walks + hitByPitch + sacrificeFlies + sacrificeHits;

  /// Batted balls that could be hit hard: AB − K + SF (bunts excluded).
  int get ballsInPlay {
    final bip = atBats - strikeouts + sacrificeFlies;
    return bip > 0 ? bip : 0;
  }

  int get unintentionalWalks {
    final ubb = walks - intentionalWalks;
    return ubb > 0 ? ubb : 0;
  }

  bool get tracksHardHit => hardHitGames > 0;
  bool get tracksQualityAtBats => qabGames > 0;

  /// Hard-hit balls / balls in play, over games where hard-hit balls were logged.
  double get hardHitRate => hardHitBallsInPlay > 0
      ? (hardHitBalls / hardHitBallsInPlay).clamp(0.0, 1.0)
      : 0.0;

  /// Quality at-bats / plate appearances, over games where QABs were logged.
  double get qualityAtBatRate => qabPlateAppearances > 0
      ? (qualityAtBats / qabPlateAppearances).clamp(0.0, 1.0)
      : 0.0;
  double get war => battingAverage * 100 + sluggingPercentage * 50;
  double get era => inningsPitched > 0 ? (earnedRuns * 9) / inningsPitched : 0.0;
  int get totalStrikeouts => strikeouts;
  double get twoStrikeSuccessRate => twoStrikeCounts > 0 ? successWithTwoStrikes / twoStrikeCounts : 0.0;
  
  // Additional calculated stats
  double get isolatedPower => sluggingPercentage - battingAverage;
  double get runsCreated => ((hits + walks) * (hits + doubles + 2 * triples + 3 * homeRuns)) / (atBats + walks);
  double get earnedRunAverage => era;
  double get strikeoutRate => inningsPitched > 0 ? (strikeouts * 9) / inningsPitched : 0.0;
  double get walksHitsPerInningPitched => inningsPitched > 0 ? (walks + hits) / inningsPitched : 0.0;
  double get onBasePlusSlugging => onBasePercentage + sluggingPercentage;

  /// Counting-stat totals of two stat lines (the per-game history lists are not merged).
  PlayerStats operator +(PlayerStats o) => PlayerStats(
        atBats: atBats + o.atBats,
        runs: runs + o.runs,
        hits: hits + o.hits,
        doubles: doubles + o.doubles,
        triples: triples + o.triples,
        homeRuns: homeRuns + o.homeRuns,
        walks: walks + o.walks,
        hitByPitch: hitByPitch + o.hitByPitch,
        strikeouts: strikeouts + o.strikeouts,
        sacrificeHits: sacrificeHits + o.sacrificeHits,
        sacrificeFlies: sacrificeFlies + o.sacrificeFlies,
        intentionalWalks: intentionalWalks + o.intentionalWalks,
        stolenBases: stolenBases + o.stolenBases,
        runsBattedIn: runsBattedIn + o.runsBattedIn,
        twoStrikeCounts: twoStrikeCounts + o.twoStrikeCounts,
        successWithTwoStrikes: successWithTwoStrikes + o.successWithTwoStrikes,
        inningsPitched: inningsPitched + o.inningsPitched,
        earnedRuns: earnedRuns + o.earnedRuns,
        totalPitches: totalPitches + o.totalPitches,
        hardHitBalls: hardHitBalls + o.hardHitBalls,
        hardHitGames: hardHitGames + o.hardHitGames,
        hardHitBallsInPlay: hardHitBallsInPlay + o.hardHitBallsInPlay,
        qualityAtBats: qualityAtBats + o.qualityAtBats,
        qabGames: qabGames + o.qabGames,
        qabPlateAppearances: qabPlateAppearances + o.qabPlateAppearances,
      );

  static PlayerStats sum(Iterable<PlayerStats> lines) =>
      lines.fold(PlayerStats(), (acc, s) => acc + s);

  /// Parses the `stats` field of a game document (a map or an already-built [PlayerStats]).
  static PlayerStats fromGameStats(Object? raw) {
    if (raw is PlayerStats) return raw;
    if (raw is Map<String, dynamic>) return PlayerStats.fromJson(raw);
    if (raw is Map) return PlayerStats.fromJson(Map<String, dynamic>.from(raw));
    return PlayerStats();
  }

  /// Season totals for a list of game documents shaped `{'stats': ...}`.
  static PlayerStats sumGames(Iterable<Map<String, dynamic>> games) =>
      sum(games.map((g) => fromGameStats(g['stats'])));

  /// Value for a stat key or display name. Returns null for optional stats
  /// that weren't logged, and for unknown names.
  double? statValue(String nameOrKey) {
    final key = getStatKey(nameOrKey) ?? nameOrKey;
    switch (key) {
      case 'battingAverage':
        return battingAverage;
      case 'onBasePercentage':
        return onBasePercentage;
      case 'sluggingPercentage':
        return sluggingPercentage;
      case 'onBasePlusSlugging':
        return onBasePlusSlugging;
      case 'isolatedPower':
        return isolatedPower;
      case 'runsCreated':
        return runsCreated;
      case 'war':
        return war;
      case 'earnedRunAverage':
        return earnedRunAverage;
      case 'strikeoutRate':
        return strikeoutRate;
      case 'walksHitsPerInningPitched':
        return walksHitsPerInningPitched;
      case 'atBats':
        return atBats.toDouble();
      case 'runs':
        return runs.toDouble();
      case 'hits':
        return hits.toDouble();
      case 'doubles':
        return doubles.toDouble();
      case 'triples':
        return triples.toDouble();
      case 'homeRuns':
        return homeRuns.toDouble();
      case 'walks':
        return walks.toDouble();
      case 'intentionalWalks':
        return intentionalWalks.toDouble();
      case 'hitByPitch':
        return hitByPitch.toDouble();
      case 'sacrificeHits':
        return sacrificeHits.toDouble();
      case 'sacrificeFlies':
        return sacrificeFlies.toDouble();
      case 'stolenBases':
        return stolenBases.toDouble();
      case 'runsBattedIn':
        return runsBattedIn.toDouble();
      case 'twoStrikeCounts':
        return twoStrikeCounts.toDouble();
      case 'twoStrikeSuccessRate':
        return twoStrikeSuccessRate;
      case 'strikeouts':
        return strikeouts.toDouble();
      case 'pitchesThrown':
      case 'totalPitches':
        return totalPitches.toDouble();
      case 'inningsPitched':
        return inningsPitched;
      case 'earnedRuns':
        return earnedRuns.toDouble();
      case 'hardHitBalls':
        return tracksHardHit ? hardHitBalls.toDouble() : null;
      case 'hardHitRate':
        return tracksHardHit ? hardHitRate : null;
      case 'qualityAtBats':
        return tracksQualityAtBats ? qualityAtBats.toDouble() : null;
      case 'qualityAtBatRate':
        return tracksQualityAtBats ? qualityAtBatRate : null;
      default:
        return null;
    }
  }

  void addStats({
    int? atBatsAdded,
    int? runsAdded,
    int? hitsAdded,
    int? doublesAdded,
    int? triplesAdded,
    int? homeRunsAdded,
    int? walksAdded,
    int? hitByPitchAdded,
    int? strikeoutsAdded,
    int? sacrificeHitsAdded,
    int? stolenBasesAdded,
    int? runsBattedInAdded,
    int? twoStrikeCountsAdded,
    int? successWithTwoStrikesAdded,
    double? inningsPitchedAdded,
    int? earnedRunsAdded,
    int? totalPitchesAdded,
  }) {
    atBats += atBatsAdded ?? 0;
    runs += runsAdded ?? 0;
    hits += hitsAdded ?? 0;
    doubles += doublesAdded ?? 0;
    triples += triplesAdded ?? 0;
    homeRuns += homeRunsAdded ?? 0;
    walks += walksAdded ?? 0;
    hitByPitch += hitByPitchAdded ?? 0;
    strikeouts += strikeoutsAdded ?? 0;
    sacrificeHits += sacrificeHitsAdded ?? 0;
    stolenBases += stolenBasesAdded ?? 0;
    runsBattedIn += runsBattedInAdded ?? 0;
    twoStrikeCounts += twoStrikeCountsAdded ?? 0;
    successWithTwoStrikes += successWithTwoStrikesAdded ?? 0;
    inningsPitched += inningsPitchedAdded ?? 0.0;
    earnedRuns += earnedRunsAdded ?? 0;
    totalPitches += totalPitchesAdded ?? 0;

    battingAverages.add(battingAverage);
    sluggingPercentages.add(sluggingPercentage);
    warList.add(war);
    eraList.add(era);
    strikeoutsList.add(totalStrikeouts.toDouble());
    pitchesList.add(totalPitches.toDouble());
    battingAveragesMonthly.add(battingAverage);
    eraListMonthly.add(era);
    atBatsList.add(atBats.toDouble());
    runsList.add(runs.toDouble());
    hitsList.add(hits.toDouble());
    doublesList.add(doubles.toDouble());
    triplesList.add(triples.toDouble());
    homeRunsList.add(homeRuns.toDouble());
    walksList.add(walks.toDouble());
    hitByPitchList.add(hitByPitch.toDouble());
    sacrificeHitsList.add(sacrificeHits.toDouble());
    stolenBasesList.add(stolenBases.toDouble());
    runsBattedInList.add(runsBattedIn.toDouble());
    twoStrikeCountsList.add(twoStrikeCounts.toDouble());
    successWithTwoStrikesList.add(successWithTwoStrikes.toDouble());
    inningsPitchedList.add(inningsPitched);
    earnedRunsList.add(earnedRuns.toDouble());
  }

  Map<String, dynamic> toMap() => {
        'atBats': atBats,
        'runs': runs,
        'hits': hits,
        'doubles': doubles,
        'triples': triples,
        'homeRuns': homeRuns,
        'walks': walks,
        'hitByPitch': hitByPitch,
        'strikeouts': strikeouts,
        'sacrificeHits': sacrificeHits,
        'sacrificeFlies': sacrificeFlies,
        'intentionalWalks': intentionalWalks,
        'stolenBases': stolenBases,
        'runsBattedIn': runsBattedIn,
        'twoStrikeCounts': twoStrikeCounts,
        'successWithTwoStrikes': successWithTwoStrikes,
        'inningsPitched': inningsPitched,
        'earnedRuns': earnedRuns,
        'totalPitches': totalPitches,
        'battingAverages': battingAverages,
        'sluggingPercentages': sluggingPercentages,
        'warList': warList,
        'eraList': eraList,
        'strikeoutsList': strikeoutsList,
        'pitchesList': pitchesList,
        'battingAveragesMonthly': battingAveragesMonthly,
        'eraListMonthly': eraListMonthly,
        'atBatsList': atBatsList,
        'runsList': runsList,
        'hitsList': hitsList,
        'doublesList': doublesList,
        'triplesList': triplesList,
        'homeRunsList': homeRunsList,
        'walksList': walksList,
        'hitByPitchList': hitByPitchList,
        'sacrificeHitsList': sacrificeHitsList,
        'stolenBasesList': stolenBasesList,
        'runsBattedInList': runsBattedInList,
        'twoStrikeCountsList': twoStrikeCountsList,
        'successWithTwoStrikesList': successWithTwoStrikesList,
        'inningsPitchedList': inningsPitchedList,
        'earnedRunsList': earnedRunsList,
        // Calculated stats
        'battingAverage': battingAverage,
        'onBasePercentage': onBasePercentage,
        'sluggingPercentage': sluggingPercentage,
        'onBasePlusSlugging': onBasePlusSlugging,
        'isolatedPower': isolatedPower,
        'runsCreated': runsCreated,
        'earnedRunAverage': earnedRunAverage,
        'strikeoutRate': strikeoutRate,
        'walksHitsPerInningPitched': walksHitsPerInningPitched,
        ..._trackedStatsJson(),
      };

  Map<String, dynamic> toJson() => {
        'atBats': atBats,
        'runs': runs,
        'hits': hits,
        'doubles': doubles,
        'triples': triples,
        'homeRuns': homeRuns,
        'walks': walks,
        'hitByPitch': hitByPitch,
        'strikeouts': strikeouts,
        'sacrificeHits': sacrificeHits,
        'sacrificeFlies': sacrificeFlies,
        'intentionalWalks': intentionalWalks,
        'stolenBases': stolenBases,
        'runsBattedIn': runsBattedIn,
        'twoStrikeCounts': twoStrikeCounts,
        'successWithTwoStrikes': successWithTwoStrikes,
        'inningsPitched': inningsPitched,
        'earnedRuns': earnedRuns,
        'totalPitches': totalPitches,
        'battingAverages': battingAverages,
        'sluggingPercentages': sluggingPercentages,
        'warList': warList,
        'eraList': eraList,
        'strikeoutsList': strikeoutsList,
        'pitchesList': pitchesList,
        'battingAveragesMonthly': battingAveragesMonthly,
        'eraListMonthly': eraListMonthly,
        'atBatsList': atBatsList,
        'runsList': runsList,
        'hitsList': hitsList,
        'doublesList': doublesList,
        'triplesList': triplesList,
        'homeRunsList': homeRunsList,
        'walksList': walksList,
        'hitByPitchList': hitByPitchList,
        'sacrificeHitsList': sacrificeHitsList,
        'stolenBasesList': stolenBasesList,
        'runsBattedInList': runsBattedInList,
        'twoStrikeCountsList': twoStrikeCountsList,
        'successWithTwoStrikesList': successWithTwoStrikesList,
        'inningsPitchedList': inningsPitchedList,
        'earnedRunsList': earnedRunsList,
        // Calculated stats
        'battingAverage': battingAverage,
        'onBasePercentage': onBasePercentage,
        'sluggingPercentage': sluggingPercentage,
        'onBasePlusSlugging': onBasePlusSlugging,
        'isolatedPower': isolatedPower,
        'runsCreated': runsCreated,
        'earnedRunAverage': earnedRunAverage,
        'strikeoutRate': strikeoutRate,
        'walksHitsPerInningPitched': walksHitsPerInningPitched,
        ..._trackedStatsJson(),
      };

  Map<String, dynamic> _trackedStatsJson() => {
        if (tracksHardHit) ...{
          'hardHitBalls': hardHitBalls,
          'hardHitGames': hardHitGames,
          'hardHitBallsInPlay': hardHitBallsInPlay,
          'hardHitRate': hardHitRate,
        },
        if (tracksQualityAtBats) ...{
          'qualityAtBats': qualityAtBats,
          'qabGames': qabGames,
          'qabPlateAppearances': qabPlateAppearances,
          'qualityAtBatRate': qualityAtBatRate,
        },
      };

  /// Same as [fromJson]: accepts camelCase, snake_case (Zuno / Cloud Functions), and flashcard labels.
  factory PlayerStats.fromMap(Map<String, dynamic> map) => PlayerStats.fromJson(map);

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    final stats = PlayerStats._fromJsonBase(json);
    final hardHit = _readOptionalInt(json, ['hardHitBalls', 'hard_hit_balls', 'Hard-Hit Balls']);
    if (hardHit != null) {
      stats.hardHitBalls = hardHit;
      // Aggregated docs carry their own denominators; a single game uses its own line.
      stats.hardHitGames = _readOptionalInt(json, ['hardHitGames']) ?? 1;
      stats.hardHitBallsInPlay =
          _readOptionalInt(json, ['hardHitBallsInPlay']) ?? stats.ballsInPlay;
    }
    final qab = _readOptionalInt(json, ['qualityAtBats', 'quality_at_bats', 'Quality At-Bats']);
    if (qab != null) {
      stats.qualityAtBats = qab;
      stats.qabGames = _readOptionalInt(json, ['qabGames']) ?? 1;
      stats.qabPlateAppearances =
          _readOptionalInt(json, ['qabPlateAppearances']) ?? stats.plateAppearances;
    }
    return stats;
  }

  factory PlayerStats._fromJsonBase(Map<String, dynamic> json) => PlayerStats(
        // camelCase, snake_case (Zuno), and flashcard display labels ("At Bats", etc.)
        atBats: _readStatsInt(json, ['atBats', 'at_bats', 'atBatCount', 'At Bats']),
        runs: _readStatsInt(json, ['runs', 'runCount', 'Runs']),
        hits: _readStatsInt(json, ['hits', 'hitCount', 'Hits']),
        doubles: _readStatsInt(json, ['doubles', 'doubles_count', 'doubleCount', 'Doubles']),
        triples: _readStatsInt(json, ['triples', 'triples_count', 'tripleCount', 'Triples']),
        homeRuns: _readStatsInt(json, [
          'homeRuns',
          'home_runs',
          'homeRunCount',
          'home_runs_count',
          'Home Runs',
        ]),
        walks: _readStatsInt(json, ['walks', 'walk', 'walkCount', 'Walks']),
        hitByPitch: _readStatsInt(json, ['hitByPitch', 'hit_by_pitch', 'hitByPitchCount', 'Hit By Pitch']),
        strikeouts: _readStatsInt(json, ['strikeouts', 'strikeout_count', 'strikeoutCount', 'Strikeouts']),
        sacrificeHits: _readStatsInt(json, [
          'sacrificeHits',
          'sacrifice_hits',
          'sacrifice_bunts',
          'Sacrifice Hits',
          'Sacrifice Bunts',
        ]),
        sacrificeFlies: _readStatsInt(json, ['sacrificeFlies', 'sacrifice_flies', 'Sacrifice Flies']),
        intentionalWalks: _readStatsInt(json, [
          'intentionalWalks',
          'intentional_walks',
          'Intentional Walks',
        ]),
        stolenBases: _readStatsInt(json, ['stolenBases', 'stolen_bases', 'stolenBaseCount', 'Stolen Bases']),
        runsBattedIn: _readStatsInt(json, ['runsBattedIn', 'rbi', 'rbiCount', 'RBI']),
        twoStrikeCounts: _readStatsInt(json, [
          'twoStrikeCounts',
          'strike_count',
          'strikeCount',
          'Two-Strike Count',
        ]),
        successWithTwoStrikes: _readStatsInt(json, [
          'successWithTwoStrikes',
          'success_with_2_strikes',
          'successWith2StrikesCount',
          'Two-Strike Success',
        ]),
        inningsPitched: _readStatsDouble(json, ['inningsPitched', 'innings_pitched', 'Innings Pitched']),
        earnedRuns: _readStatsInt(json, ['earnedRuns', 'earned_runs', 'earnedRunCount', 'Earned Runs']),
        totalPitches: _readStatsInt(json, ['totalPitches', 'pitches_thrown', 'pitchesThrownCount', 'Pitches Thrown']),
        battingAverages: List<double>.from(json['battingAverages'] ?? []),
        sluggingPercentages: List<double>.from(json['sluggingPercentages'] ?? []),
        warList: List<double>.from(json['warList'] ?? []),
        eraList: List<double>.from(json['eraList'] ?? []),
        strikeoutsList: List<double>.from(json['strikeoutsList'] ?? []),
        pitchesList: List<double>.from(json['pitchesList'] ?? []),
        battingAveragesMonthly: List<double>.from(json['battingAveragesMonthly'] ?? []),
        eraListMonthly: List<double>.from(json['eraListMonthly'] ?? []),
        atBatsList: List<double>.from(json['atBatsList'] ?? []),
        runsList: List<double>.from(json['runsList'] ?? []),
        hitsList: List<double>.from(json['hitsList'] ?? []),
        doublesList: List<double>.from(json['doublesList'] ?? []),
        triplesList: List<double>.from(json['triplesList'] ?? []),
        homeRunsList: List<double>.from(json['homeRunsList'] ?? []),
        walksList: List<double>.from(json['walksList'] ?? []),
        hitByPitchList: List<double>.from(json['hitByPitchList'] ?? []),
        sacrificeHitsList: List<double>.from(json['sacrificeHitsList'] ?? []),
        stolenBasesList: List<double>.from(json['stolenBasesList'] ?? []),
        runsBattedInList: List<double>.from(json['runsBattedInList'] ?? []),
        twoStrikeCountsList: List<double>.from(json['twoStrikeCountsList'] ?? []),
        successWithTwoStrikesList: List<double>.from(json['successWithTwoStrikesList'] ?? []),
        inningsPitchedList: List<double>.from(json['inningsPitchedList'] ?? []),
        earnedRunsList: List<double>.from(json['earnedRunsList'] ?? []),
      );
}

final PlayerStats playerStats = PlayerStats();