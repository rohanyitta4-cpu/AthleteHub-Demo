import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../player_stats.dart';

// Flag to disable insight generation until function is deployed
// Set to true once analyzeStat function is deployed
const bool _enableInsightGeneration = true;

/// Keys the backend analyzeStat actually uses (extractStatValuesFromGames). No list fields.
const Set<String> _backendStatKeys = {
  'atBats', 'runs', 'hits', 'doubles', 'triples', 'homeRuns', 'walks',
  'hitByPitch', 'strikeouts', 'sacrificeHits', 'stolenBases', 'runsBattedIn',
  'twoStrikeCounts', 'successWithTwoStrikes', 'inningsPitched', 'earnedRuns', 'totalPitches',
  'sacrificeFlies', 'intentionalWalks', 'hardHitBalls', 'hardHitBallsInPlay',
  'qualityAtBats', 'qabPlateAppearances',
};

/// Build a small map for one game so the callable payload stays tiny. Sending full [toJson]
/// (with 20+ numeric lists per game) causes huge payloads and a native serialization crash on iOS.
Map<String, dynamic> _minimalStatsForBackend(dynamic stats) {
  final Map<String, dynamic> out = {};
  if (stats is PlayerStats) {
    final j = stats.toJson();
    for (final k in _backendStatKeys) {
      if (j.containsKey(k)) {
        final v = j[k];
        if (v is num || v is bool) out[k] = v;
      }
    }
    return out;
  }
  if (stats is Map) {
    for (final k in _backendStatKeys) {
      if (stats.containsKey(k)) {
        final v = stats[k];
        if (v is num || v is bool) {
          out[k] = v;
        } else if (v != null) {
          final n = num.tryParse(v.toString());
          if (n != null) out[k] = n;
        }
      }
    }
  }
  return out;
}

/// Helper to generate insights for all stats in the background
/// This is called separately to avoid crashes in the main UI
class InsightGeneratorHelper {
  static FirebaseFunctions get _functions => FirebaseFunctions.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Generate insights for all stats given game data
  /// Returns true if at least one insight was generated successfully
  static Future<bool> generateInsightsForAllStats(
    List<Map<String, dynamic>> gameData,
  ) async {
    // Check if insight generation is enabled
    if (!_enableInsightGeneration) {
      print('ℹ️ [InsightGenerator] Insight generation is disabled. Enable it by setting _enableInsightGeneration = true after deploying the analyzeStat function.');
      return false;
    }

    if (gameData.isEmpty) return false;

    final user = _auth.currentUser;
    if (user == null) {
      print('⚠️ [InsightGenerator] User not authenticated');
      return false;
    }

    // List of stats to generate insights for
    final statNames = [
      'Batting Average',
      'On-Base Percentage',
      'Slugging Percentage',
      'On-Base Plus Slugging',
      'Isolated Power',
      'Runs Created',
      'Home Runs',
      'Hits',
      'RBIs',
      'Stolen Bases',
      'Earned Run Average',
      'Strikeout Rate',
      'Walks + Hits per Inning Pitched',
    ];

    bool anySuccess = false;
    int successCount = 0;

    // Generate insights one at a time with delays to avoid overwhelming Firebase
    for (final statName in statNames) {
      try {
        // Add delay between each call
        await Future.delayed(const Duration(milliseconds: 500));

        print('🔄 [InsightGenerator] Generating insight for: $statName');

        // Minimal payload only (scalar stats). Full toJson() with lists crashes iOS native serialization.
        final gamesForAnalysis = gameData
            .map((game) => <String, dynamic>{'stats': _minimalStatsForBackend(game['stats'])})
            .toList();

        final callable = _functions.httpsCallable('analyzeStat');
        await callable.call({
          'statName': statName,
          'gameData': gamesForAnalysis,
        }).timeout(const Duration(seconds: 30));

        // Insight is automatically cached by the Firebase Function
        print('✅ [InsightGenerator] Successfully generated insight for: $statName');
        successCount++;
        anySuccess = true;
      } catch (e) {
        print('❌ [InsightGenerator] Error generating insight for $statName: $e');
        // Continue with next stat even if one fails
      }
    }

    print('✅ [InsightGenerator] Completed: $successCount/${statNames.length} insights generated');
    return anySuccess;
  }

  /// Generate insights for a single stat. Never throws; returns false on any error.
  static Future<bool> generateInsightForStat(
    String statName,
    List<Map<String, dynamic>> gameData,
  ) async {
    if (gameData.isEmpty) return false;

    try {
      final user = _auth.currentUser;
      if (user == null) return false;
    } catch (_) {
      return false;
    }

    if (!_enableInsightGeneration) {
      return false;
    }

    try {
      const int maxGames = 80;
      final limited = gameData.length > maxGames ? gameData.sublist(gameData.length - maxGames) : gameData;

      // Send only minimal scalar stats per game. Full toJson() includes 20+ List<double> per game
      // and causes native JSON serialization to crash on iOS (process kill).
      final List<Map<String, dynamic>> gamesForAnalysis = [];
      for (final game in limited) {
        try {
          final stats = _minimalStatsForBackend(game['stats']);
          gamesForAnalysis.add(<String, dynamic>{'stats': stats});
        } catch (_) {
          gamesForAnalysis.add(<String, dynamic>{'stats': <String, dynamic>{}});
        }
      }

      final payload = <String, dynamic>{'statName': statName, 'gameData': gamesForAnalysis};

      final callable = _functions.httpsCallable('analyzeStat');
      await callable.call(payload).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('analyzeStat timeout'),
      );
      return true;
    } catch (e, stackTrace) {
      debugPrint('InsightGenerator error for $statName: $e\n$stackTrace');
      return false;
    }
  }
}

