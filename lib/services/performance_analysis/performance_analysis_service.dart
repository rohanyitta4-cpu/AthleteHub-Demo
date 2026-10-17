import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../firebase_stats_service.dart';
import '../../models/hitting_profile.dart';
import 'analysis_context_builder.dart';
import 'performance_report_model.dart';

/// Generates and caches Scout performance reports.
///
/// 1. Stats are computed in Dart ([AnalysisContextBuilder]).
/// 2. The `analyzePerformance` Cloud Function computes every score and the
///    grade, and Gemini writes the explanation.
/// 3. Reports are cached per hitting profile and keyed by game count, so
///    switching profiles never shows a stale grade.
/// 4. When Scout's standards change, existing reports are kept as they were.
///    The player can recalculate; the replaced report is archived and the new
///    one remembers the old grade so the change is labeled.
///
/// The app never computes a grade itself; if the function is unreachable the
/// last cached report is shown instead.
class PerformanceAnalysisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStatsService _statsService = FirebaseStatsService();

  String? get _userId => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _cacheDoc(String uid, HittingProfile? profile) =>
      _userDoc(uid).collection('performanceAnalysis').doc('report_${profile?.id ?? 'overall'}');

  // ---------------------------------------------------------------------------
  // Hitting profile preference
  // ---------------------------------------------------------------------------

  Future<HittingProfile?> getHittingProfile() async {
    final uid = _userId;
    if (uid == null) return null;
    try {
      final doc = await _userDoc(uid).get();
      return HittingProfile.fromId(doc.data()?['hittingProfile'] as String?);
    } catch (_) {
      return null;
    }
  }

  Future<void> setHittingProfile(HittingProfile profile) async {
    final uid = _userId;
    if (uid == null) throw Exception('User not authenticated');
    await _userDoc(uid).set({
      'hittingProfile': profile.id,
      'scoringGuideVersion': PerformanceReport.currentScoringVersion,
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // "Help improve Scout" (opt-in calibration data)
  // ---------------------------------------------------------------------------

  Future<ScoutDataSharing> getDataSharing() async {
    final uid = _userId;
    if (uid == null) return const ScoutDataSharing(enabled: false);
    try {
      final data = (await _userDoc(uid).get()).data() ?? const {};
      final sharing = data['scoutDataSharing'];
      return ScoutDataSharing(
        enabled: sharing is Map && sharing['enabled'] == true,
        competitionLevel: CompetitionLevel.fromId(data['competitionLevel'] as String?),
      );
    } catch (_) {
      return const ScoutDataSharing(enabled: false);
    }
  }

  /// Turning sharing off deletes everything already contributed (server-side).
  Future<void> setDataSharing({
    required bool enabled,
    CompetitionLevel? competitionLevel,
  }) async {
    await _functions.httpsCallable('setScoutDataSharing').call({
      'enabled': enabled,
      'competitionLevel': competitionLevel?.id,
    });
  }

  // ---------------------------------------------------------------------------
  // Reports
  // ---------------------------------------------------------------------------

  /// Report for an already-built context (the Scout sheet).
  ///
  /// Reuses the cached report while the game count and profile are unchanged,
  /// even if it was scored under older standards (the sheet then offers a
  /// recalculation). New games always produce a report under current standards.
  Future<PerformanceReport> reportForContext(
    PerformanceContext context, {
    HittingProfile? profile,
    bool forceRefresh = false,
  }) async {
    final uid = _userId;
    if (uid == null) throw Exception('User not authenticated');
    if (!context.hasEnoughData) return PerformanceReport.insufficientData();

    if (!forceRefresh) {
      final cached = await _getCachedReport(uid, profile);
      if (cached != null && cached.report.gamesAnalyzed == context.gamesAnalyzed) {
        return cached.report;
      }
    }

    return _cacheReport(uid, profile, await _callAnalysis(context, profile));
  }

  /// Most recent cached report for [profile], regardless of game count.
  Future<PerformanceReport?> cachedReport({HittingProfile? profile}) async {
    final uid = _userId;
    if (uid == null) return null;
    return (await _getCachedReport(uid, profile))?.report;
  }

  /// Get or generate a report for the saved profile (full report screen).
  Future<PerformanceReport> getReport({bool forceRefresh = false}) async {
    final uid = _userId;
    if (uid == null) throw Exception('User not authenticated');
    final profile = await getHittingProfile();

    if (!forceRefresh) {
      final cached = await _getCachedReport(uid, profile);
      if (cached != null && !cached.isStale) return cached.report;
      if (cached != null && !cached.canRegenerate) return cached.report;
    }
    return generateReport();
  }

  /// Fetch all games, build the context and ask the server for a fresh report.
  Future<PerformanceReport> generateReport() async {
    final uid = _userId;
    if (uid == null) throw Exception('User not authenticated');

    final games = await _statsService.getAllGames();
    if (games.length < 5) return PerformanceReport.insufficientData();

    games.sort((a, b) {
      final aDate = a['date'] as Timestamp?;
      final bDate = b['date'] as Timestamp?;
      if (aDate == null || bDate == null) return 0;
      return aDate.compareTo(bDate);
    });

    final context = AnalysisContextBuilder.build(games);
    if (!context.hasEnoughData) return PerformanceReport.insufficientData();

    final profile = await getHittingProfile();
    try {
      return await _cacheReport(uid, profile, await _callAnalysis(context, profile));
    } catch (_) {
      final cached = await _getCachedReport(uid, profile);
      if (cached != null) return cached.report;
      rethrow;
    }
  }

  Future<PerformanceReport> _callAnalysis(PerformanceContext context, HittingProfile? profile) async {
    final callable = _functions.httpsCallable(
      'analyzePerformance',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 90)),
    );

    String? seasonId;
    try {
      seasonId = (await _statsService.getActiveSeason())?.id;
    } catch (_) {}

    final result = await callable.call({
      'context': context.toJson(),
      if (profile != null) 'hittingProfile': profile.id,
      // Only used server-side to key opt-in calibration data per player-season.
      'seasonId': ?seasonId,
    }).timeout(const Duration(seconds: 90));

    final data = Map<String, dynamic>.from(result.data as Map);
    return PerformanceReport.fromJson({
      ...data,
      'generatedAt': DateTime.now().toIso8601String(),
      'gamesAnalyzed': context.gamesAnalyzed,
    });
  }

  Future<CachedPerformanceReport?> _getCachedReport(String uid, HittingProfile? profile) async {
    try {
      final doc = await _cacheDoc(uid, profile).get();
      final data = doc.data();
      if (data == null) return null;
      final cached = CachedPerformanceReport.fromJson(data);
      if (cached.report.hittingProfile != profile?.id) return null;
      return cached;
    } catch (_) {
      return null;
    }
  }

  /// Saves [report] as the current one. A report it replaces that was scored
  /// under different standards is archived, and [report] records its grade.
  Future<PerformanceReport> _cacheReport(
    String uid,
    HittingProfile? profile,
    PerformanceReport report,
  ) async {
    var toSave = report;
    try {
      final doc = _cacheDoc(uid, profile);
      final existing = await doc.get();
      final previousData = existing.data();
      if (previousData != null) {
        final previous = CachedPerformanceReport.fromJson(previousData).report;
        if (previous.scoringVersion != report.scoringVersion) {
          await doc.collection('history').add({
            ...previousData,
            'archivedAt': DateTime.now().toIso8601String(),
          });
          toSave = report.replacing(previous);
        }
      }
      final activeSeason = await _statsService.getActiveSeason();
      await doc.set(CachedPerformanceReport(
        report: toSave,
        generatedAt: DateTime.now(),
        seasonId: activeSeason?.id,
      ).toJson());
    } catch (_) {
      // Caching failure is non-fatal.
    }
    return toSave;
  }

  /// Whether a new report can be generated for the full report screen.
  Future<bool> canGenerateNewReport() async {
    final uid = _userId;
    if (uid == null) return false;
    final cached = await _getCachedReport(uid, await getHittingProfile());
    return cached == null || cached.canRegenerate;
  }

  /// Time until the full report screen may regenerate (24-hour limit).
  Future<Duration?> timeUntilNextReport() async {
    final uid = _userId;
    if (uid == null) return null;
    final cached = await _getCachedReport(uid, await getHittingProfile());
    if (cached == null) return Duration.zero;
    final remaining = cached.generatedAt.add(const Duration(hours: 24)).difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

class ScoutDataSharing {
  final bool enabled;
  final CompetitionLevel? competitionLevel;

  const ScoutDataSharing({required this.enabled, this.competitionLevel});
}

/// Mirrors COMPETITION_LEVELS in functions/src/calibration.ts.
enum CompetitionLevel {
  middleSchool('middle_school', 'Middle school'),
  highSchoolJv('high_school_jv', 'High school JV'),
  highSchoolVarsity('high_school_varsity', 'High school varsity'),
  travel('travel', 'Travel / showcase'),
  college('college', 'College'),
  adult('adult', 'Adult league');

  final String id;
  final String label;
  const CompetitionLevel(this.id, this.label);

  static CompetitionLevel? fromId(String? id) {
    for (final level in values) {
      if (level.id == id) return level;
    }
    return null;
  }
}
