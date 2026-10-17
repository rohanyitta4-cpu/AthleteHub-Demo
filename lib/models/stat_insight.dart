import 'package:cloud_firestore/cloud_firestore.dart';

/// A single categorized coaching recommendation (DRILL / MENTAL / APPROACH).
class CoachRecommendation {
  final String category; // DRILL, MENTAL, APPROACH
  final String title;
  final String detail;

  const CoachRecommendation({
    required this.category,
    required this.title,
    required this.detail,
  });

  factory CoachRecommendation.fromMap(Map<dynamic, dynamic> map) {
    final rawCategory = (map['category'] ?? 'APPROACH').toString().toUpperCase();
    const valid = {'DRILL', 'MENTAL', 'APPROACH'};
    return CoachRecommendation(
      category: valid.contains(rawCategory) ? rawCategory : 'APPROACH',
      title: (map['title'] ?? '').toString().trim(),
      detail: (map['detail'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toMap() => {
        'category': category,
        'title': title,
        'detail': detail,
      };

  static List<CoachRecommendation> listFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => CoachRecommendation.fromMap(e))
        .where((r) => r.title.isNotEmpty && r.detail.isNotEmpty)
        .toList();
  }
}

/// Data model for AI-generated stat insights
class StatInsight {
  final String statName;
  final String mainAnalysis; // 2-3 sentence summary (legacy)
  final String coachNote; // Coach's Corner note (preferred display text)
  final List<String> keyInsights; // Bullet points (legacy / detailed view)
  final List<String> recommendations; // Flat action items (legacy)
  final List<CoachRecommendation> coachRecommendations; // Categorized cards
  final String trend; // "up", "down", "stable"
  final double trendPercentage;
  final DateTime lastUpdated;
  final Map<String, dynamic> metadata;

  StatInsight({
    required this.statName,
    required this.mainAnalysis,
    String? coachNote,
    required this.keyInsights,
    required this.recommendations,
    this.coachRecommendations = const [],
    required this.trend,
    required this.trendPercentage,
    required this.lastUpdated,
    this.metadata = const {},
  }) : coachNote = (coachNote != null && coachNote.trim().isNotEmpty)
            ? coachNote
            : mainAnalysis;

  /// Create from Firestore document
  factory StatInsight.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StatInsight(
      statName: data['statName'] ?? '',
      mainAnalysis: data['mainAnalysis'] ?? '',
      coachNote: data['coachNote'] as String?,
      keyInsights: List<String>.from(data['keyInsights'] ?? []),
      recommendations: List<String>.from(data['recommendations'] ?? []),
      coachRecommendations:
          CoachRecommendation.listFrom(data['coachRecommendations']),
      trend: data['trend'] ?? 'stable',
      trendPercentage: (data['trendPercentage'] ?? 0.0).toDouble(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Create from Firebase Function response
  factory StatInsight.fromMap(Map<String, dynamic> map) {
    return StatInsight(
      statName: map['statName'] ?? '',
      mainAnalysis: map['mainAnalysis'] ?? '',
      coachNote: map['coachNote'] as String?,
      keyInsights: List<String>.from(map['keyInsights'] ?? []),
      recommendations: List<String>.from(map['recommendations'] ?? []),
      coachRecommendations:
          CoachRecommendation.listFrom(map['coachRecommendations']),
      trend: map['trend'] ?? 'stable',
      trendPercentage: (map['trendPercentage'] ?? 0.0).toDouble(),
      lastUpdated: DateTime.now(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'statName': statName,
      'mainAnalysis': mainAnalysis,
      'coachNote': coachNote,
      'keyInsights': keyInsights,
      'recommendations': recommendations,
      'coachRecommendations':
          coachRecommendations.map((r) => r.toMap()).toList(),
      'trend': trend,
      'trendPercentage': trendPercentage,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'metadata': metadata,
    };
  }

  /// Convert to Map for API calls
  Map<String, dynamic> toMap() {
    return {
      'statName': statName,
      'mainAnalysis': mainAnalysis,
      'coachNote': coachNote,
      'keyInsights': keyInsights,
      'recommendations': recommendations,
      'coachRecommendations':
          coachRecommendations.map((r) => r.toMap()).toList(),
      'trend': trend,
      'trendPercentage': trendPercentage,
      'lastUpdated': lastUpdated.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Check if insight is still fresh (within 24 hours)
  bool isFresh() {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    return difference.inHours < 24;
  }

  /// Create a copy with updated fields
  StatInsight copyWith({
    String? statName,
    String? mainAnalysis,
    String? coachNote,
    List<String>? keyInsights,
    List<String>? recommendations,
    List<CoachRecommendation>? coachRecommendations,
    String? trend,
    double? trendPercentage,
    DateTime? lastUpdated,
    Map<String, dynamic>? metadata,
  }) {
    return StatInsight(
      statName: statName ?? this.statName,
      mainAnalysis: mainAnalysis ?? this.mainAnalysis,
      coachNote: coachNote ?? this.coachNote,
      keyInsights: keyInsights ?? this.keyInsights,
      recommendations: recommendations ?? this.recommendations,
      coachRecommendations: coachRecommendations ?? this.coachRecommendations,
      trend: trend ?? this.trend,
      trendPercentage: trendPercentage ?? this.trendPercentage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      metadata: metadata ?? this.metadata,
    );
  }
}
