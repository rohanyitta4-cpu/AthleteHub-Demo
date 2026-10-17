/// Performance Report Model
/// 
/// Structured data model for Gemini-generated scouting reports.
/// Gemini interprets pre-computed metrics and returns this structure.
library;

class PerformanceReport {
  /// Overall grade (A+, A, A-, B+, B, B-, C+, C, C-, D, F)
  final String grade;
  
  /// One-line summary of current performance
  final String headline;
  
  /// Key strengths with statistical evidence
  final List<ReportInsight> strengths;
  
  /// Key concerns with statistical evidence
  final List<ReportInsight> concerns;
  
  /// Summary of recent trend direction
  final String trendSummary;
  
  /// Recommended focus area for improvement
  final String focusArea;
  
  /// Detailed focus recommendation
  final String? focusDetail;

  /// Category the focus is about (the weakest scored category).
  final String? focusCategory;

  /// Practice drills for [focusCategory].
  final List<String> drills;

  /// Who "typical" means in this report, e.g. "High school varsity and travel ball hitters".
  final String? comparisonGroup;

  /// Set when the player's own level isn't the group the benchmarks describe.
  final String? comparisonNote;
  
  /// Overall trend direction: 'improving', 'declining', 'stable'
  final String overallTrend;
  
  /// Confidence level in the assessment: 'high', 'medium', 'low'
  final String confidence;
  
  /// When this report was generated
  final DateTime generatedAt;
  
  /// Number of games analyzed for this report
  final int gamesAnalyzed;

  /// Weighted 0-100 score the letter grade is derived from (null on old reports).
  final int? overallScore;

  /// 2-3 sentence season summary.
  final String summary;

  /// Per-category rubric scores with rationale.
  final List<CategoryScore> categories;

  /// Most notable finding right now.
  final KeyInsight? keyInsight;

  /// 'ai' when Gemini wrote it, 'rubric' for the deterministic fallback.
  final String source;

  /// Bumped whenever the scoring guide changes so cached reports regenerate.
  final int scoringVersion;

  /// Hitting profile the grade was weighted for (null = balanced weights).
  final String? hittingProfile;

  /// Label for what the main grade measures, e.g. "Contact Hitter".
  final String profileLabel;

  /// Profile-neutral score so players on different profiles can compare.
  final int? overallOffenseScore;
  final String? overallOffenseGrade;

  /// Points momentum added to or removed from the overall score.
  final double momentumAdjustment;

  /// Benchmark set and profile-weight version the server scored with.
  final String? benchmarkSet;
  final int? profileWeightsVersion;

  /// 'provisional' until the standards are validated against real data.
  final String standardsStatus;

  /// Set when this report replaced one scored under older standards.
  final String? previousGrade;
  final int? previousScoringVersion;

  /// Mirrors SCORING_VERSION in functions/src/scoring.ts. It changes only when
  /// the formulas or the active standards change; older reports are kept and
  /// shown with an option to recalculate.
  static const int currentScoringVersion = 5;

  bool get usesCurrentStandards => scoringVersion >= currentScoringVersion;
  bool get isProvisional => standardsStatus != 'validated';

  const PerformanceReport({
    required this.grade,
    required this.headline,
    required this.strengths,
    required this.concerns,
    required this.trendSummary,
    required this.focusArea,
    this.focusDetail,
    this.focusCategory,
    this.drills = const [],
    this.comparisonGroup,
    this.comparisonNote,
    required this.overallTrend,
    required this.confidence,
    required this.generatedAt,
    required this.gamesAnalyzed,
    this.overallScore,
    this.summary = '',
    this.categories = const [],
    this.keyInsight,
    this.source = 'rubric',
    this.scoringVersion = 1,
    this.hittingProfile,
    this.profileLabel = 'Overall Offense',
    this.overallOffenseScore,
    this.overallOffenseGrade,
    this.momentumAdjustment = 0,
    this.benchmarkSet,
    this.profileWeightsVersion,
    this.standardsStatus = 'provisional',
    this.previousGrade,
    this.previousScoringVersion,
  });

  /// Copy that remembers the grade it replaced under older standards.
  PerformanceReport replacing(PerformanceReport previous) {
    final json = toJson();
    json['previous'] = {
      'grade': previous.grade,
      'scoringVersion': previous.scoringVersion,
    };
    return PerformanceReport.fromJson(json);
  }

  factory PerformanceReport.fromJson(Map<String, dynamic> json) {
    final standards = json['standards'] is Map ? json['standards'] as Map : null;
    final previous = json['previous'] is Map ? json['previous'] as Map : null;
    return PerformanceReport(
      grade: json['grade'] as String? ?? 'C',
      headline: json['headline'] as String? ?? 'Performance analysis',
      strengths: (json['strengths'] as List<dynamic>?)
          ?.map((e) => ReportInsight.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList() ?? [],
      concerns: (json['concerns'] as List<dynamic>?)
          ?.map((e) => ReportInsight.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList() ?? [],
      trendSummary: json['trendSummary'] as String? ?? '',
      focusArea: json['focusArea'] as String? ?? '',
      focusDetail: json['focusDetail'] as String?,
      focusCategory: json['focusCategory'] as String?,
      drills: (json['drills'] as List<dynamic>?)?.whereType<String>().toList() ?? const [],
      comparisonGroup: (json['comparison'] as Map?)?['group'] as String?,
      comparisonNote: (json['comparison'] as Map?)?['note'] as String?,
      overallTrend: json['overallTrend'] as String? ?? 'stable',
      confidence: json['confidence'] as String? ?? 'medium',
      generatedAt: json['generatedAt'] != null 
          ? DateTime.parse(json['generatedAt'] as String)
          : DateTime.now(),
      gamesAnalyzed: (json['gamesAnalyzed'] as num?)?.toInt() ?? 0,
      overallScore: (json['overallScore'] as num?)?.round(),
      summary: json['summary'] as String? ?? '',
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => CategoryScore.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList() ?? const [],
      keyInsight: json['keyInsight'] is Map
          ? KeyInsight.fromJson(Map<String, dynamic>.from(json['keyInsight'] as Map))
          : null,
      source: json['source'] as String? ?? 'rubric',
      scoringVersion: (json['scoringVersion'] as num?)?.toInt() ?? 1,
      hittingProfile: json['hittingProfile'] as String?,
      profileLabel: json['profileLabel'] as String? ?? 'Overall Offense',
      overallOffenseScore: (json['overallOffense'] is Map)
          ? ((json['overallOffense'] as Map)['score'] as num?)?.round()
          : null,
      overallOffenseGrade: (json['overallOffense'] is Map)
          ? (json['overallOffense'] as Map)['grade'] as String?
          : null,
      momentumAdjustment: (json['momentumAdjustment'] as num?)?.toDouble() ?? 0,
      benchmarkSet: standards?['benchmarkSet'] as String?,
      profileWeightsVersion: (standards?['profileWeightsVersion'] as num?)?.toInt(),
      standardsStatus: standards?['status'] as String? ?? 'provisional',
      previousGrade: previous?['grade'] as String?,
      previousScoringVersion: (previous?['scoringVersion'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'grade': grade,
    'headline': headline,
    'strengths': strengths.map((e) => e.toJson()).toList(),
    'concerns': concerns.map((e) => e.toJson()).toList(),
    'trendSummary': trendSummary,
    'focusArea': focusArea,
    if (focusDetail != null) 'focusDetail': focusDetail,
    if (focusCategory != null) 'focusCategory': focusCategory,
    if (drills.isNotEmpty) 'drills': drills,
    if (comparisonGroup != null)
      'comparison': {'group': comparisonGroup, 'note': comparisonNote},
    'overallTrend': overallTrend,
    'confidence': confidence,
    'generatedAt': generatedAt.toIso8601String(),
    'gamesAnalyzed': gamesAnalyzed,
    if (overallScore != null) 'overallScore': overallScore,
    'summary': summary,
    'categories': categories.map((e) => e.toJson()).toList(),
    if (keyInsight != null) 'keyInsight': keyInsight!.toJson(),
    'source': source,
    'scoringVersion': scoringVersion,
    'hittingProfile': hittingProfile,
    'profileLabel': profileLabel,
    if (overallOffenseScore != null)
      'overallOffense': {'score': overallOffenseScore, 'grade': overallOffenseGrade},
    'momentumAdjustment': momentumAdjustment,
    'standards': {
      'scoringVersion': scoringVersion,
      if (benchmarkSet != null) 'benchmarkSet': benchmarkSet,
      if (profileWeightsVersion != null) 'profileWeightsVersion': profileWeightsVersion,
      'status': standardsStatus,
    },
    if (previousGrade != null)
      'previous': {'grade': previousGrade, 'scoringVersion': previousScoringVersion},
  };

  /// Create a fallback report when Gemini is unavailable.
  factory PerformanceReport.fallback({
    required String grade,
    required String headline,
    required List<ReportInsight> strengths,
    required List<ReportInsight> concerns,
    required String trendSummary,
    required String focusArea,
    String? focusDetail,
    required String overallTrend,
    required int gamesAnalyzed,
  }) {
    return PerformanceReport(
      grade: grade,
      headline: headline,
      strengths: strengths,
      concerns: concerns,
      trendSummary: trendSummary,
      focusArea: focusArea,
      focusDetail: focusDetail,
      overallTrend: overallTrend,
      confidence: gamesAnalyzed >= 15 ? 'high' : (gamesAnalyzed >= 8 ? 'medium' : 'low'),
      generatedAt: DateTime.now(),
      gamesAnalyzed: gamesAnalyzed,
    );
  }

  /// Create an empty report for insufficient data.
  factory PerformanceReport.insufficientData() {
    return PerformanceReport(
      grade: '--',
      headline: 'Need more games for analysis',
      strengths: [],
      concerns: [],
      trendSummary: 'Log at least 5 games to generate your performance report.',
      focusArea: 'Keep logging games',
      overallTrend: 'unknown',
      confidence: 'low',
      generatedAt: DateTime.now(),
      gamesAnalyzed: 0,
    );
  }

  /// Grade color for UI
  String get gradeColor {
    switch (grade[0]) {
      case 'A': return 'green';
      case 'B': return 'blue';
      case 'C': return 'yellow';
      case 'D': return 'orange';
      case 'F': return 'red';
      default: return 'gray';
    }
  }

  /// Trend icon for UI
  String get trendIcon {
    switch (overallTrend) {
      case 'improving': return '↑';
      case 'declining': return '↓';
      default: return '→';
    }
  }
}

/// Individual insight with title and evidence.
class ReportInsight {
  final String title;
  final String evidence;
  final String? category; // 'contact', 'power', 'discipline', 'consistency', etc.

  const ReportInsight({
    required this.title,
    required this.evidence,
    this.category,
  });

  factory ReportInsight.fromJson(Map<String, dynamic> json) {
    return ReportInsight(
      title: json['title'] as String? ?? '',
      evidence: json['evidence'] as String? ?? '',
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'evidence': evidence,
    if (category != null) 'category': category,
  };
}

/// One rubric category (contact, power, discipline, momentum, twoStrike, consistency).
class CategoryScore {
  final String key;
  final String label;
  final int weight;
  final int score;
  final bool available;
  final String rationale;

  const CategoryScore({
    required this.key,
    required this.label,
    required this.weight,
    required this.score,
    this.available = true,
    required this.rationale,
  });

  factory CategoryScore.fromJson(Map<String, dynamic> json) => CategoryScore(
    key: json['key'] as String? ?? '',
    label: json['label'] as String? ?? '',
    weight: (json['weight'] as num?)?.toInt() ?? 0,
    score: (json['score'] as num?)?.round() ?? 0,
    available: json['available'] as bool? ?? true,
    rationale: json['rationale'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'weight': weight,
    'score': score,
    'available': available,
    'rationale': rationale,
  };
}

class KeyInsight {
  final String title;
  final String detail;
  final String tone; // 'positive', 'warning', 'neutral'
  final List<MapEntry<String, String>> stats;

  const KeyInsight({
    required this.title,
    required this.detail,
    required this.tone,
    required this.stats,
  });

  factory KeyInsight.fromJson(Map<String, dynamic> json) => KeyInsight(
    title: json['title'] as String? ?? '',
    detail: json['detail'] as String? ?? '',
    tone: json['tone'] as String? ?? 'neutral',
    stats: (json['stats'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((m) => MapEntry('${m['label'] ?? ''}', '${m['value'] ?? ''}'))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'detail': detail,
    'tone': tone,
    'stats': stats.map((e) => {'label': e.key, 'value': e.value}).toList(),
  };
}

/// Cached report stored in Firestore.
class CachedPerformanceReport {
  final PerformanceReport report;
  final DateTime generatedAt;
  final String? seasonId;

  const CachedPerformanceReport({
    required this.report,
    required this.generatedAt,
    this.seasonId,
  });

  factory CachedPerformanceReport.fromJson(Map<String, dynamic> json) {
    return CachedPerformanceReport(
      report: PerformanceReport.fromJson(Map<String, dynamic>.from(json['report'] as Map)),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      seasonId: json['seasonId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'report': report.toJson(),
    'generatedAt': generatedAt.toIso8601String(),
    if (seasonId != null) 'seasonId': seasonId,
  };

  /// Check if report is stale (older than 24 hours).
  bool get isStale {
    final now = DateTime.now();
    final age = now.difference(generatedAt);
    return age.inHours >= 24;
  }

  /// Check if report can be regenerated (rate limit: once per 24 hours).
  bool get canRegenerate => isStale;
}
