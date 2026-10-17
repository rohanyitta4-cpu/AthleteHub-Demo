import 'dart:async';

/// Singleton service to broadcast stats update events across the app
/// Used to notify dashboard and other screens when new stats are saved
class StatsUpdateService {
  static final StatsUpdateService _instance = StatsUpdateService._internal();

  factory StatsUpdateService() {
    return _instance;
  }

  StatsUpdateService._internal();

  final _statsUpdateController = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream that emits whenever stats are updated
  Stream<Map<String, dynamic>> get onStatsUpdated => _statsUpdateController.stream;

  /// Call this when new stats are saved
  void notifyStatsUpdated({
    required String userId,
    required String seasonId,
    Map<String, dynamic>? statsData,
  }) {
    print('📢 [STATS_UPDATE] Broadcasting stats update for user: $userId, season: $seasonId');
    _statsUpdateController.add({
      'userId': userId,
      'seasonId': seasonId,
      'timestamp': DateTime.now(),
      'statsData': statsData,
    });
  }

  void dispose() {
    _statsUpdateController.close();
  }
}
