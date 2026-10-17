import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/stat_insight.dart';
import '../player_stats.dart';
import '../utils/chart_data_preparer.dart';

/// Service for fetching and managing AI-generated stat insights
class AIStatAnalyzerService {
  // ✅ Make Firebase instances lazy to prevent early initialization crashes
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFunctions get _functions => FirebaseFunctions.instance;

  String? get _userId => _auth.currentUser?.uid;

  /// Keys expected by the backend analyzeStat function.
  static const Set<String> _backendStatKeys = {
    'atBats',
    'runs',
    'hits',
    'doubles',
    'triples',
    'homeRuns',
    'walks',
    'hitByPitch',
    'strikeouts',
    'sacrificeHits',
    'stolenBases',
    'runsBattedIn',
    'twoStrikeCounts',
    'successWithTwoStrikes',
    'inningsPitched',
    'earnedRuns',
    'totalPitches',
    'sacrificeFlies',
    'intentionalWalks',
    'hardHitBalls',
    'hardHitBallsInPlay',
    'qualityAtBats',
    'qabPlateAppearances',
  };

  Map<String, dynamic> _minimalStatsForBackend(dynamic stats) {
    final out = <String, dynamic>{};
    if (stats is PlayerStats) {
      final json = stats.toJson();
      for (final key in _backendStatKeys) {
        if (!json.containsKey(key)) continue;
        final value = json[key];
        if (value is num || value is bool) {
          out[key] = value;
        }
      }
      return out;
    }
    if (stats is Map) {
      for (final key in _backendStatKeys) {
        if (!stats.containsKey(key)) continue;
        final value = stats[key];
        if (value is num || value is bool) {
          out[key] = value;
        } else if (value != null) {
          final parsed = num.tryParse(value.toString());
          if (parsed != null) out[key] = parsed;
        }
      }
    }
    return out;
  }

  /// Get cached insight from Firestore
  Future<StatInsight?> getCachedInsight(String statName) async {
    // ✅ Add delay to ensure Firebase is ready
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      if (_userId == null) {
        print('⚠️ [AI Service] User not authenticated');
        return null;
      }

      // Wrap Firestore access in try-catch with timeout
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('statInsights')
          .doc(statName)
          .get()
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              print('⚠️ [AI Service] Timeout getting cached insight');
              throw TimeoutException('Firestore get timeout');
            },
          );

      if (doc.exists) {
        return StatInsight.fromFirestore(doc);
      }
    } catch (e) {
      print('❌ [AI Service] Error getting cached insight: $e');
      // Return null instead of crashing
    }
    return null;
  }

  /// Check if insight should be refreshed (not fresh or doesn't exist)
  bool shouldRefreshInsight(StatInsight? insight) {
    if (insight == null) return true;
    return !insight.isFresh();
  }

  /// Analyze stat using Firebase Function
  Future<StatInsight> analyzeStat(
    String statName,
    List<Map<String, dynamic>> gameData,
  ) async {
    // ✅ Add delay to ensure Firebase is ready
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (_userId == null) {
      print('⚠️ [AI Service] User not authenticated, returning basic insight');
      return _createBasicInsight(statName, gameData);
    }

    try {
      // Prepare compact game payload for the function.
      // Avoid sending full PlayerStats.toJson() (contains list fields) because
      // large nested payloads can trigger native serialization crashes on iOS.
      const maxGames = 80;
      final limited = gameData.length > maxGames
          ? gameData.sublist(gameData.length - maxGames)
          : gameData;
      final gamesForAnalysis = limited
          .map<Map<String, dynamic>>((game) => <String, dynamic>{
                'stats': _minimalStatsForBackend(game['stats']),
              })
          .toList();

      // Call Firebase Function with timeout
      final callable = _functions.httpsCallable('analyzeStat');
      final result = await callable.call({
        'statName': statName,
        'gameData': gamesForAnalysis,
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('AI analysis timed out');
        },
      );

      final insightData = result.data as Map<String, dynamic>;
      final insight = StatInsight.fromMap({
        ...insightData,
        'statName': statName,
      });

      // Cache the insight in Firestore (don't wait for it)
      _cacheInsight(insight).catchError((e) {
        print('⚠️ [AI Service] Error caching insight: $e');
      });

      return insight;
    } catch (e) {
      print('❌ [AI Service] Error analyzing stat: $e');
      // Return a basic insight on error instead of crashing
      return _createBasicInsight(statName, gameData);
    }
  }

  /// Cache insight in Firestore
  Future<void> _cacheInsight(StatInsight insight) async {
    if (_userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('statInsights')
          .doc(insight.statName)
          .set(insight.toFirestore());
    } catch (e) {
      print('Error caching insight: $e');
    }
  }

  /// Create a basic insight when AI analysis fails
  StatInsight _createBasicInsight(
    String statName,
    List<Map<String, dynamic>> gameData,
  ) {
    final values = _extractStatValues(statName, gameData);
    if (values.isEmpty) {
      return StatInsight(
        statName: statName,
        mainAnalysis: 'No data available for analysis.',
        keyInsights: [],
        recommendations: ['Enter more game data to get insights.'],
        trend: 'stable',
        trendPercentage: 0.0,
        lastUpdated: DateTime.now(),
      );
    }

    final current = values.last;
    final average = values.reduce((a, b) => a + b) / values.length;
    final trend = current > average ? 'up' : (current < average ? 'down' : 'stable');
    final trendPercentage = average > 0 ? ((current - average) / average * 100) : 0.0;

    return StatInsight(
      statName: statName,
      mainAnalysis: 'Current value: ${current.toStringAsFixed(3)}, '
          'Average: ${average.toStringAsFixed(3)}. '
          '${trend == 'up' ? 'Trending upward' : trend == 'down' ? 'Trending downward' : 'Stable performance'}.',
      keyInsights: [
        'Current value: ${current.toStringAsFixed(3)}',
        'Season average: ${average.toStringAsFixed(3)}',
      ],
      recommendations: ['Continue tracking your progress.'],
      trend: trend,
      trendPercentage: trendPercentage,
      lastUpdated: DateTime.now(),
    );
  }

  /// Extract stat values from game data (helper for basic insight)
  List<double> _extractStatValues(
    String statName,
    List<Map<String, dynamic>> gameData,
  ) {
    return ChartDataPreparer.getStatValues(statName, gameData);
  }

  /// Refresh insight (force new analysis)
  Future<StatInsight> refreshInsight(
    String statName,
    List<Map<String, dynamic>> gameData,
  ) async {
    // Delete cached version and get new analysis
    if (_userId != null) {
      try {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('statInsights')
            .doc(statName)
            .delete();
      } catch (e) {
        print('Error deleting cached insight: $e');
      }
    }
    return analyzeStat(statName, gameData);
  }
}

