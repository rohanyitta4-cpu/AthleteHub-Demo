import '../../player_stats.dart';
import '../../utils/stat_calculations.dart';
import '../../utils/stat_windows.dart';

/// Builds a complete performance analysis context from game data.
/// 
/// All statistical calculations happen HERE in Dart — Gemini only interprets
/// the pre-computed metrics. This ensures accuracy and determinism.
class AnalysisContextBuilder {
  /// Build a complete analysis context from a list of game data.
  /// 
  /// [games] should be sorted chronologically (oldest first).
  static PerformanceContext build(List<Map<String, dynamic>> games) {
    if (games.isEmpty) {
      return PerformanceContext.empty();
    }

    // Extract PlayerStats from each game
    final statsList = _extractStats(games);
    if (statsList.isEmpty) {
      return PerformanceContext.empty();
    }

    // Calculate season totals
    final seasonTotals = _aggregateStats(statsList);
    
    // Calculate season metrics
    final seasonMetrics = _calculateSeasonMetrics(seasonTotals, statsList.length);

    // Calculate trend metrics (needs at least 5 games)
    final trendMetrics = _calculateTrendMetrics(statsList);

    // Calculate situational metrics
    final situationalMetrics = _calculateSituationalMetrics(statsList);

    // Identify performance areas
    final performanceAreas = _identifyPerformanceAreas(
      seasonMetrics,
      trendMetrics,
      statsList,
    );

    return PerformanceContext(
      gamesAnalyzed: statsList.length,
      season: seasonMetrics,
      trend: trendMetrics,
      situational: situationalMetrics,
      areas: performanceAreas,
      last10: statsList.length >= 10 ? _window(statsList, 10) : null,
      last20: statsList.length >= 20 ? _window(statsList, 20) : null,
      generatedAt: DateTime.now(),
    );
  }

  /// Plate appearances, defined the same way everywhere (AB + BB + HBP + SF + SH).
  static int _plateAppearances(PlayerStats t) => t.plateAppearances;

  /// Raw counts and rates for the most recent [size] games.
  static WindowMetrics _window(List<PlayerStats> statsList, int size) {
    final t = _aggregateStats(statsList.sublist(statsList.length - size));
    final pa = _plateAppearances(t);
    return WindowMetrics(
      games: size,
      atBats: t.atBats,
      plateAppearances: pa,
      hits: t.hits,
      strikeouts: t.strikeouts,
      walks: t.walks,
      avg: t.atBats > 0 ? t.hits / t.atBats : 0.0,
      kRate: pa > 0 ? t.strikeouts / pa * 100 : 0.0,
      bbRate: _bbRate(t),
    );
  }

  /// Extract PlayerStats objects from game data maps.
  static List<PlayerStats> _extractStats(List<Map<String, dynamic>> games) {
    final result = <PlayerStats>[];
    for (final game in games) {
      final statsData = game['stats'];
      if (statsData == null) continue;
      
      PlayerStats stats;
      if (statsData is PlayerStats) {
        stats = statsData;
      } else if (statsData is Map<String, dynamic>) {
        stats = PlayerStats.fromJson(statsData);
      } else {
        continue;
      }
      result.add(stats);
    }
    return result;
  }

  /// Aggregate multiple games into season totals.
  static PlayerStats _aggregateStats(List<PlayerStats> statsList) =>
      PlayerStats.sum(statsList);

  /// Unintentional walk rate (%): (BB − IBB) / (PA − IBB). Intentional walks
  /// say more about the opponent than the hitter's eye.
  static double _bbRate(PlayerStats t) {
    final pa = t.plateAppearances - t.intentionalWalks;
    return pa > 0 ? t.unintentionalWalks / pa * 100 : 0.0;
  }

  /// Calculate season-level rate stats.
  static SeasonMetrics _calculateSeasonMetrics(PlayerStats t, int games) {
    final plateAppearances = _plateAppearances(t);
    
    // AVG = H / AB
    final avg = t.atBats > 0 ? t.hits / t.atBats : 0.0;
    
    // OBP = (H + BB + HBP) / (AB + BB + HBP + SF)
    final obpDenom = t.atBats + t.walks + t.hitByPitch + t.sacrificeFlies;
    final obp = obpDenom > 0 ? (t.hits + t.walks + t.hitByPitch) / obpDenom : 0.0;
    
    // SLG = TB / AB, where TB = H + 2B + 2*3B + 3*HR
    final totalBases = t.hits + t.doubles + (2 * t.triples) + (3 * t.homeRuns);
    final slg = t.atBats > 0 ? totalBases / t.atBats : 0.0;
    
    // OPS = OBP + SLG
    final ops = obp + slg;
    
    // BB% = (BB − IBB) / (PA − IBB)
    final bbRate = _bbRate(t);
    
    // K% = K / PA
    final kRate = plateAppearances > 0 ? (t.strikeouts / plateAppearances) * 100 : 0.0;
    
    // BABIP = (H - HR) / (AB - K - HR + SF)
    // Balls in play excludes strikeouts and home runs
    final babipNumerator = t.hits - t.homeRuns;
    final babipDenominator = t.atBats - t.strikeouts - t.homeRuns + t.sacrificeFlies;
    final babip = babipDenominator > 0 ? babipNumerator / babipDenominator : 0.0;
    
    // ISO (Isolated Power) = SLG - AVG
    final iso = slg - avg;
    
    return SeasonMetrics(
      games: games,
      plateAppearances: plateAppearances,
      atBats: t.atBats,
      hits: t.hits,
      doubles: t.doubles,
      triples: t.triples,
      homeRuns: t.homeRuns,
      walks: t.walks,
      strikeouts: t.strikeouts,
      rbi: t.runsBattedIn,
      avg: avg,
      obp: obp,
      slg: slg,
      ops: ops,
      bbRate: bbRate,
      kRate: kRate,
      babip: babip,
      iso: iso,
      intentionalWalks: t.intentionalWalks,
      sacrificeFlies: t.sacrificeFlies,
      sacrificeBunts: t.sacrificeHits,
      hardHit: t.tracksHardHit
          ? TrackedRate(
              count: t.hardHitBalls,
              denominator: t.hardHitBallsInPlay,
              games: t.hardHitGames,
              rate: t.hardHitRate,
            )
          : null,
      qualityAtBats: t.tracksQualityAtBats
          ? TrackedRate(
              count: t.qualityAtBats,
              denominator: t.qabPlateAppearances,
              games: t.qabGames,
              rate: t.qualityAtBatRate,
            )
          : null,
    );
  }

  /// Calculate trend metrics comparing recent performance to earlier periods.
  static TrendMetrics _calculateTrendMetrics(List<PlayerStats> statsList) {
    if (statsList.length < 5) {
      return TrendMetrics.insufficientData();
    }

    // Last 5 games
    final last5 = statsList.sublist(statsList.length - 5);
    final last5Totals = _aggregateStats(last5);
    final last5Avg = last5Totals.atBats > 0 ? last5Totals.hits / last5Totals.atBats : 0.0;
    final last5PA = _plateAppearances(last5Totals);
    final last5KRate = last5PA > 0 ? (last5Totals.strikeouts / last5PA) * 100 : 0.0;
    final last5BBRate = last5PA > 0 ? _bbRate(last5Totals) : 0.0;

    // Last 10 games (if available)
    double last10Avg = last5Avg;
    double last10KRate = last5KRate;
    double last10BBRate = last5BBRate;
    if (statsList.length >= 10) {
      final last10 = statsList.sublist(statsList.length - 10);
      final last10Totals = _aggregateStats(last10);
      last10Avg = last10Totals.atBats > 0 ? last10Totals.hits / last10Totals.atBats : 0.0;
      final last10PA = _plateAppearances(last10Totals);
      last10KRate = last10PA > 0 ? (last10Totals.strikeouts / last10PA) * 100 : 0.0;
      last10BBRate = last10PA > 0 ? _bbRate(last10Totals) : 0.0;
    }

    // Previous 10 games (games 11-20 from the end, if available)
    double previous10Avg = last10Avg;
    double previous10KRate = last10KRate;
    double previous10BBRate = last10BBRate;
    if (statsList.length >= 20) {
      final previous10 = statsList.sublist(statsList.length - 20, statsList.length - 10);
      final previous10Totals = _aggregateStats(previous10);
      previous10Avg = previous10Totals.atBats > 0 ? previous10Totals.hits / previous10Totals.atBats : 0.0;
      final prev10PA = _plateAppearances(previous10Totals);
      previous10KRate = prev10PA > 0 ? (previous10Totals.strikeouts / prev10PA) * 100 : 0.0;
      previous10BBRate = prev10PA > 0 ? _bbRate(previous10Totals) : 0.0;
    }

    // Calculate game-by-game batting averages for trend analysis
    final gameAvgs = <double>[];
    for (final stats in statsList) {
      if (stats.atBats > 0) {
        gameAvgs.add(stats.hits / stats.atBats);
      }
    }

    // Determine contact trend
    final contactTrend = _determineTrend(
      recent: last5Avg,
      previous: statsList.length >= 10 ? previous10Avg : last5Avg,
      threshold: 0.020, // 20 points of AVG
    );

    // Determine strikeout trend (note: decreasing K% is "improving")
    final strikeoutTrend = _determineTrend(
      recent: last5KRate,
      previous: statsList.length >= 10 ? previous10KRate : last5KRate,
      threshold: 3.0, // 3% change
      invertPositive: true, // Lower K% is better
    );

    // Determine discipline trend (BB%)
    final disciplineTrend = _determineTrend(
      recent: last5BBRate,
      previous: statsList.length >= 10 ? previous10BBRate : last5BBRate,
      threshold: 2.0, // 2% change
    );

    // Consistency score based on recent games
    final consistency = StatCalculations.consistencyScore(gameAvgs);

    // Streak calculation
    final seasonTotals = _aggregateStats(statsList);
    final seasonAvg = seasonTotals.atBats > 0 ? seasonTotals.hits / seasonTotals.atBats : 0.0;
    final streak = StatCalculations.longestStreakAbove(gameAvgs, seasonAvg);

    return TrendMetrics(
      last5Avg: last5Avg,
      last5KRate: last5KRate,
      last5BBRate: last5BBRate,
      last10Avg: last10Avg,
      last10KRate: last10KRate,
      last10BBRate: last10BBRate,
      previous10Avg: previous10Avg,
      previous10KRate: previous10KRate,
      previous10BBRate: previous10BBRate,
      avgChange: last10Avg - previous10Avg,
      kRateChange: last10KRate - previous10KRate,
      bbRateChange: last10BBRate - previous10BBRate,
      contactTrend: contactTrend,
      strikeoutTrend: strikeoutTrend,
      disciplineTrend: disciplineTrend,
      consistency: consistency,
      consistencyGames: gameAvgs.length,
      streakAboveAvg: streak,
      hasSufficientData: true,
    );
  }

  /// Calculate situational performance metrics.
  static SituationalMetrics _calculateSituationalMetrics(List<PlayerStats> statsList) {
    int totalTwoStrikeCounts = 0;
    int totalTwoStrikeSuccess = 0;

    // Games whose two-strike numbers can't add up are left out, so one bad
    // entry can't turn into a "two-strike weakness".
    for (final stats in validTwoStrikeGames(statsList)) {
      totalTwoStrikeCounts += stats.twoStrikeCounts;
      totalTwoStrikeSuccess += stats.successWithTwoStrikes;
    }

    final twoStrikeAvg = totalTwoStrikeCounts > 0
        ? totalTwoStrikeSuccess / totalTwoStrikeCounts
        : 0.0;

    // Compare two-strike performance to overall average
    final seasonTotals = _aggregateStats(statsList);
    final overallAvg = seasonTotals.atBats > 0 ? seasonTotals.hits / seasonTotals.atBats : 0.0;
    
    final twoStrikeDelta = twoStrikeAvg - overallAvg;
    
    String twoStrikeAssessment;
    if (totalTwoStrikeCounts < 10) {
      twoStrikeAssessment = 'insufficient_data';
    } else if (twoStrikeDelta > 0.020) {
      twoStrikeAssessment = 'strength';
    } else if (twoStrikeDelta < -0.050) {
      twoStrikeAssessment = 'weakness';
    } else {
      twoStrikeAssessment = 'neutral';
    }

    return SituationalMetrics(
      twoStrikeAtBats: totalTwoStrikeCounts,
      twoStrikeHits: totalTwoStrikeSuccess,
      twoStrikeAvg: twoStrikeAvg,
      twoStrikeDeltaVsOverall: twoStrikeDelta,
      twoStrikeAssessment: twoStrikeAssessment,
      // Note: RISP, home/away, L/R splits not tracked in current data model
      rispAvg: null,
      homeAvg: null,
      awayAvg: null,
      vsLeftAvg: null,
      vsRightAvg: null,
    );
  }

  /// Identify key performance areas and their status.
  static PerformanceAreas _identifyPerformanceAreas(
    SeasonMetrics season,
    TrendMetrics trend,
    List<PlayerStats> statsList,
  ) {
    // Contact assessment
    String contactStatus;
    String contactDetail;
    if (!trend.hasSufficientData) {
      contactStatus = 'neutral';
      contactDetail = 'Not enough data to assess trend';
    } else if (trend.contactTrend == 'improving') {
      contactStatus = 'improving';
      contactDetail = 'AVG up ${_formatChange(trend.avgChange)} over last 10 games';
    } else if (trend.contactTrend == 'declining') {
      contactStatus = 'declining';
      contactDetail = 'AVG down ${_formatChange(trend.avgChange.abs())} over last 10 games';
    } else {
      contactStatus = 'stable';
      contactDetail = 'AVG holding steady at ${_formatAvg(season.avg)}';
    }

    // Power assessment based on ISO
    String powerStatus;
    String powerDetail;
    if (season.iso >= 0.200) {
      powerStatus = 'strength';
      powerDetail = 'ISO of ${season.iso.toStringAsFixed(3)} indicates plus power';
    } else if (season.iso >= 0.120) {
      powerStatus = 'stable';
      powerDetail = 'ISO of ${season.iso.toStringAsFixed(3)} shows average power';
    } else {
      powerStatus = 'weakness';
      powerDetail = 'ISO of ${season.iso.toStringAsFixed(3)} is below average';
    }

    // Discipline assessment based on K% and BB%
    String disciplineStatus;
    String disciplineDetail;
    if (trend.disciplineTrend == 'improving' && season.bbRate >= 8) {
      disciplineStatus = 'improving';
      disciplineDetail = 'Walk rate at ${season.bbRate.toStringAsFixed(1)}%, trending up';
    } else if (trend.disciplineTrend == 'declining' || season.bbRate < 5) {
      disciplineStatus = 'declining';
      disciplineDetail = 'Walk rate at ${season.bbRate.toStringAsFixed(1)}%, needs attention';
    } else {
      disciplineStatus = 'stable';
      disciplineDetail = 'Walk rate at ${season.bbRate.toStringAsFixed(1)}%';
    }

    // Strikeouts assessment
    String strikeoutStatus;
    String strikeoutDetail;
    if (trend.strikeoutTrend == 'improving') {
      strikeoutStatus = 'improving';
      strikeoutDetail = 'K% down to ${trend.last5KRate.toStringAsFixed(1)}%, improving contact';
    } else if (trend.strikeoutTrend == 'declining' || season.kRate > 25) {
      strikeoutStatus = 'concern';
      strikeoutDetail = 'K% at ${season.kRate.toStringAsFixed(1)}% needs work';
    } else {
      strikeoutStatus = 'stable';
      strikeoutDetail = 'K% at ${season.kRate.toStringAsFixed(1)}%';
    }

    // Consistency assessment
    String consistencyStatus;
    String consistencyDetail;
    if (trend.consistency >= 0.75) {
      consistencyStatus = 'strength';
      consistencyDetail = 'Very consistent game-to-game performance';
    } else if (trend.consistency >= 0.50) {
      consistencyStatus = 'stable';
      consistencyDetail = 'Moderate consistency in performance';
    } else {
      consistencyStatus = 'concern';
      consistencyDetail = 'High variance between games';
    }

    return PerformanceAreas(
      contact: PerformanceArea(status: contactStatus, detail: contactDetail),
      power: PerformanceArea(status: powerStatus, detail: powerDetail),
      discipline: PerformanceArea(status: disciplineStatus, detail: disciplineDetail),
      strikeouts: PerformanceArea(status: strikeoutStatus, detail: strikeoutDetail),
      consistency: PerformanceArea(status: consistencyStatus, detail: consistencyDetail),
    );
  }

  /// Determine trend direction based on recent vs previous values.
  static String _determineTrend({
    required double recent,
    required double previous,
    required double threshold,
    bool invertPositive = false,
  }) {
    final diff = recent - previous;
    if (diff.abs() < threshold) return 'stable';
    
    if (invertPositive) {
      // For stats where lower is better (like K%)
      return diff > 0 ? 'declining' : 'improving';
    } else {
      return diff > 0 ? 'improving' : 'declining';
    }
  }

  static String _formatChange(double change) {
    final points = (change * 1000).round();
    return '$points points';
  }

  static String _formatAvg(double avg) {
    return avg.toStringAsFixed(3);
  }
}

/// Complete performance analysis context for Gemini interpretation.
class PerformanceContext {
  final int gamesAnalyzed;
  final SeasonMetrics season;
  final TrendMetrics trend;
  final SituationalMetrics situational;
  final PerformanceAreas areas;
  final WindowMetrics? last10;
  final WindowMetrics? last20;
  final DateTime generatedAt;

  const PerformanceContext({
    required this.gamesAnalyzed,
    required this.season,
    required this.trend,
    required this.situational,
    required this.areas,
    this.last10,
    this.last20,
    required this.generatedAt,
  });

  factory PerformanceContext.empty() => PerformanceContext(
    gamesAnalyzed: 0,
    season: SeasonMetrics.empty(),
    trend: TrendMetrics.insufficientData(),
    situational: SituationalMetrics.empty(),
    areas: PerformanceAreas.empty(),
    generatedAt: DateTime.now(),
  );

  bool get hasEnoughData => gamesAnalyzed >= 5;

  /// Convert to JSON for Gemini API.
  Map<String, dynamic> toJson() => {
    'gamesAnalyzed': gamesAnalyzed,
    'season': season.toJson(),
    'trend': trend.toJson(),
    'situational': situational.toJson(),
    'areas': areas.toJson(),
    'windows': {
      if (last10 != null) 'last10': last10!.toJson(),
      if (last20 != null) 'last20': last20!.toJson(),
    },
    'generatedAt': generatedAt.toIso8601String(),
  };
}

/// Counting stats and rates for the most recent N games (momentum input).
class WindowMetrics {
  final int games;
  final int atBats;
  final int plateAppearances;
  final int hits;
  final int strikeouts;
  final int walks;
  final double avg;
  final double kRate;
  final double bbRate;

  const WindowMetrics({
    required this.games,
    required this.atBats,
    required this.plateAppearances,
    required this.hits,
    required this.strikeouts,
    required this.walks,
    required this.avg,
    required this.kRate,
    required this.bbRate,
  });

  Map<String, dynamic> toJson() => {
    'games': games,
    'atBats': atBats,
    'plateAppearances': plateAppearances,
    'hits': hits,
    'strikeouts': strikeouts,
    'walks': walks,
    'avg': double.parse(avg.toStringAsFixed(3)),
    'kRate': double.parse(kRate.toStringAsFixed(1)),
    'bbRate': double.parse(bbRate.toStringAsFixed(1)),
  };
}

/// Season-level rate statistics.
class SeasonMetrics {
  final int games;
  final int plateAppearances;
  final int atBats;
  final int hits;
  final int doubles;
  final int triples;
  final int homeRuns;
  final int walks;
  final int strikeouts;
  final int rbi;
  final double avg;
  final double obp;
  final double slg;
  final double ops;
  final double bbRate;
  final double kRate;
  final double babip;
  final double iso;
  final int intentionalWalks;
  final int sacrificeFlies;
  final int sacrificeBunts;
  final TrackedRate? hardHit;
  final TrackedRate? qualityAtBats;

  const SeasonMetrics({
    required this.games,
    required this.plateAppearances,
    required this.atBats,
    required this.hits,
    required this.doubles,
    required this.triples,
    required this.homeRuns,
    required this.walks,
    required this.strikeouts,
    required this.rbi,
    required this.avg,
    required this.obp,
    required this.slg,
    required this.ops,
    required this.bbRate,
    required this.kRate,
    required this.babip,
    required this.iso,
    this.intentionalWalks = 0,
    this.sacrificeFlies = 0,
    this.sacrificeBunts = 0,
    this.hardHit,
    this.qualityAtBats,
  });

  factory SeasonMetrics.empty() => const SeasonMetrics(
    games: 0,
    plateAppearances: 0,
    atBats: 0,
    hits: 0,
    doubles: 0,
    triples: 0,
    homeRuns: 0,
    walks: 0,
    strikeouts: 0,
    rbi: 0,
    avg: 0.0,
    obp: 0.0,
    slg: 0.0,
    ops: 0.0,
    bbRate: 0.0,
    kRate: 0.0,
    babip: 0.0,
    iso: 0.0,
  );

  Map<String, dynamic> toJson() => {
    'games': games,
    'plateAppearances': plateAppearances,
    'atBats': atBats,
    'hits': hits,
    'doubles': doubles,
    'triples': triples,
    'homeRuns': homeRuns,
    'walks': walks,
    'strikeouts': strikeouts,
    'rbi': rbi,
    'avg': double.parse(avg.toStringAsFixed(3)),
    'obp': double.parse(obp.toStringAsFixed(3)),
    'slg': double.parse(slg.toStringAsFixed(3)),
    'ops': double.parse(ops.toStringAsFixed(3)),
    'bbRate': double.parse(bbRate.toStringAsFixed(1)),
    'kRate': double.parse(kRate.toStringAsFixed(1)),
    'babip': double.parse(babip.toStringAsFixed(3)),
    'iso': double.parse(iso.toStringAsFixed(3)),
    'intentionalWalks': intentionalWalks,
    'sacrificeFlies': sacrificeFlies,
    'sacrificeBunts': sacrificeBunts,
    if (hardHit != null) 'hardHit': hardHit!.toJson('ballsInPlay'),
    if (qualityAtBats != null)
      'qualityAtBats': qualityAtBats!.toJson('plateAppearances'),
  };
}

/// An optional stat over only the games where the player logged it.
class TrackedRate {
  final int count;
  final int denominator;
  final int games;
  final double rate;

  const TrackedRate({
    required this.count,
    required this.denominator,
    required this.games,
    required this.rate,
  });

  Map<String, dynamic> toJson(String denominatorKey) => {
    'count': count,
    denominatorKey: denominator,
    'games': games,
    'rate': double.parse(rate.toStringAsFixed(3)),
  };
}

/// Trend metrics comparing recent to historical performance.
class TrendMetrics {
  final double last5Avg;
  final double last5KRate;
  final double last5BBRate;
  final double last10Avg;
  final double last10KRate;
  final double last10BBRate;
  final double previous10Avg;
  final double previous10KRate;
  final double previous10BBRate;
  final double avgChange;
  final double kRateChange;
  final double bbRateChange;
  final String contactTrend;
  final String strikeoutTrend;
  final String disciplineTrend;
  final double consistency;
  final int consistencyGames;
  final int streakAboveAvg;
  final bool hasSufficientData;

  const TrendMetrics({
    required this.last5Avg,
    required this.last5KRate,
    required this.last5BBRate,
    required this.last10Avg,
    required this.last10KRate,
    required this.last10BBRate,
    required this.previous10Avg,
    required this.previous10KRate,
    required this.previous10BBRate,
    required this.avgChange,
    required this.kRateChange,
    required this.bbRateChange,
    required this.contactTrend,
    required this.strikeoutTrend,
    required this.disciplineTrend,
    required this.consistency,
    this.consistencyGames = 0,
    required this.streakAboveAvg,
    required this.hasSufficientData,
  });

  factory TrendMetrics.insufficientData() => const TrendMetrics(
    last5Avg: 0.0,
    last5KRate: 0.0,
    last5BBRate: 0.0,
    last10Avg: 0.0,
    last10KRate: 0.0,
    last10BBRate: 0.0,
    previous10Avg: 0.0,
    previous10KRate: 0.0,
    previous10BBRate: 0.0,
    avgChange: 0.0,
    kRateChange: 0.0,
    bbRateChange: 0.0,
    contactTrend: 'unknown',
    strikeoutTrend: 'unknown',
    disciplineTrend: 'unknown',
    consistency: 0.0,
    streakAboveAvg: 0,
    hasSufficientData: false,
  );

  Map<String, dynamic> toJson() => {
    'last5Avg': double.parse(last5Avg.toStringAsFixed(3)),
    'last5KRate': double.parse(last5KRate.toStringAsFixed(1)),
    'last5BBRate': double.parse(last5BBRate.toStringAsFixed(1)),
    'last10Avg': double.parse(last10Avg.toStringAsFixed(3)),
    'last10KRate': double.parse(last10KRate.toStringAsFixed(1)),
    'last10BBRate': double.parse(last10BBRate.toStringAsFixed(1)),
    'previous10Avg': double.parse(previous10Avg.toStringAsFixed(3)),
    'previous10KRate': double.parse(previous10KRate.toStringAsFixed(1)),
    'previous10BBRate': double.parse(previous10BBRate.toStringAsFixed(1)),
    'avgChange': double.parse(avgChange.toStringAsFixed(3)),
    'kRateChange': double.parse(kRateChange.toStringAsFixed(1)),
    'bbRateChange': double.parse(bbRateChange.toStringAsFixed(1)),
    'contactTrend': contactTrend,
    'strikeoutTrend': strikeoutTrend,
    'disciplineTrend': disciplineTrend,
    'consistency': double.parse(consistency.toStringAsFixed(2)),
    'consistencyGames': consistencyGames,
    'streakAboveAvg': streakAboveAvg,
    'hasSufficientData': hasSufficientData,
  };
}

/// Situational performance metrics.
class SituationalMetrics {
  final int twoStrikeAtBats;
  final int twoStrikeHits;
  final double twoStrikeAvg;
  final double twoStrikeDeltaVsOverall;
  final String twoStrikeAssessment;
  final double? rispAvg;
  final double? homeAvg;
  final double? awayAvg;
  final double? vsLeftAvg;
  final double? vsRightAvg;

  const SituationalMetrics({
    required this.twoStrikeAtBats,
    required this.twoStrikeHits,
    required this.twoStrikeAvg,
    required this.twoStrikeDeltaVsOverall,
    required this.twoStrikeAssessment,
    this.rispAvg,
    this.homeAvg,
    this.awayAvg,
    this.vsLeftAvg,
    this.vsRightAvg,
  });

  factory SituationalMetrics.empty() => const SituationalMetrics(
    twoStrikeAtBats: 0,
    twoStrikeHits: 0,
    twoStrikeAvg: 0.0,
    twoStrikeDeltaVsOverall: 0.0,
    twoStrikeAssessment: 'insufficient_data',
  );

  Map<String, dynamic> toJson() => {
    'twoStrike': {
      'atBats': twoStrikeAtBats,
      'hits': twoStrikeHits,
      'avg': double.parse(twoStrikeAvg.toStringAsFixed(3)),
      'deltaVsOverall': double.parse(twoStrikeDeltaVsOverall.toStringAsFixed(3)),
      'assessment': twoStrikeAssessment,
    },
    if (rispAvg != null) 'rispAvg': rispAvg,
    if (homeAvg != null) 'homeAvg': homeAvg,
    if (awayAvg != null) 'awayAvg': awayAvg,
    if (vsLeftAvg != null) 'vsLeftAvg': vsLeftAvg,
    if (vsRightAvg != null) 'vsRightAvg': vsRightAvg,
  };
}

/// Performance area assessments.
class PerformanceAreas {
  final PerformanceArea contact;
  final PerformanceArea power;
  final PerformanceArea discipline;
  final PerformanceArea strikeouts;
  final PerformanceArea consistency;

  const PerformanceAreas({
    required this.contact,
    required this.power,
    required this.discipline,
    required this.strikeouts,
    required this.consistency,
  });

  factory PerformanceAreas.empty() => PerformanceAreas(
    contact: PerformanceArea.empty(),
    power: PerformanceArea.empty(),
    discipline: PerformanceArea.empty(),
    strikeouts: PerformanceArea.empty(),
    consistency: PerformanceArea.empty(),
  );

  Map<String, dynamic> toJson() => {
    'contact': contact.toJson(),
    'power': power.toJson(),
    'discipline': discipline.toJson(),
    'strikeouts': strikeouts.toJson(),
    'consistency': consistency.toJson(),
  };
}

/// Individual performance area status.
class PerformanceArea {
  final String status; // 'improving', 'declining', 'stable', 'strength', 'weakness', 'concern', 'neutral'
  final String detail;

  const PerformanceArea({
    required this.status,
    required this.detail,
  });

  factory PerformanceArea.empty() => const PerformanceArea(
    status: 'neutral',
    detail: 'Not enough data',
  );

  Map<String, dynamic> toJson() => {
    'status': status,
    'detail': detail,
  };
}
