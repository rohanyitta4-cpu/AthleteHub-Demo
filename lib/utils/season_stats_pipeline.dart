import 'package:cloud_firestore/cloud_firestore.dart';

import '../player_stats.dart';

/// Keys we never treat as stat fields when reading legacy root-level stats.
const _ignoredGameRootKeys = {
  'date',
  'stats',
  'updatedAt',
  'clientUpdatedAt',
  'ownerId',
  'userId',
  'seasonId',
  'source',
  'sessionId',
  'id',
  'gameId',
  'metadata',
};

/// Parses one game document the same way the dashboard builds each
/// game row, plus legacy root-level stats when `stats` is missing or empty
/// (matches logic in [stats_quiz_screen] aggregated stats jobs).
PlayerStats playerStatsFromFirestoreGame(Map<String, dynamic> data) {
  final raw = data['stats'];
  Map<String, dynamic>? nested;
  if (raw is Map<String, dynamic>) {
    nested = raw;
  } else if (raw is Map) {
    nested = Map<String, dynamic>.from(raw);
  }

  if (nested != null && nested.isNotEmpty) {
    return PlayerStats.fromJson(nested);
  }

  // Legacy: counters only on document root (older saves / partial writes).
  if (data.containsKey('hits') || data.containsKey('at_bats') || data.containsKey('atBats')) {
    final legacy = <String, dynamic>{};
    for (final e in data.entries) {
      if (_ignoredGameRootKeys.contains(e.key)) continue;
      legacy[e.key] = e.value;
    }
    if (legacy.isNotEmpty) {
      return PlayerStats.fromJson(legacy);
    }
  }

  return PlayerStats();
}

/// Sums [PlayerStats] from each game document — same totals as the dashboard
/// aggregate over `_gameData`.
PlayerStats aggregatePlayerStatsFromGameDocuments(Iterable<DocumentSnapshot> docs) {
  return PlayerStats.sum(
    docs.map((doc) {
      final data = doc.data();
      return data is Map<String, dynamic> ? playerStatsFromFirestoreGame(data) : PlayerStats();
    }),
  );
}
