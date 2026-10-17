import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/firestore_paths.dart';
import '../models/player_season_totals.dart';

class StatsRepo {
  static final _db = FirebaseFirestore.instance;

  /// Create or update player season totals
  Future<void> upsertPlayerSeasonTotals(PlayerSeasonTotals stats) async {
    await _db.collection(FP.teamSeasonStats(stats.playerId, stats.playerId)) // Note: This should be teamId, seasonId
        .doc(stats.playerId)
        .set(stats.toJson(), SetOptions(merge: true));
  }

  /// Create player season totals
  Future<void> createPlayerSeasonTotals(String teamId, String seasonId, PlayerSeasonTotals stats) async {
    await _db.collection(FP.teamSeasonStats(teamId, seasonId))
        .doc(stats.playerId)
        .set(stats.toJson());
  }

  /// Update player season totals
  Future<void> updatePlayerSeasonTotals(String teamId, String seasonId, PlayerSeasonTotals stats) async {
    await _db.collection(FP.teamSeasonStats(teamId, seasonId))
        .doc(stats.playerId)
        .set(stats.toJson());
  }

  /// Delete player season totals
  Future<void> deletePlayerSeasonTotals(String teamId, String seasonId, String playerId) async {
    await _db.doc(FP.teamSeasonPlayerStats(teamId, seasonId, playerId)).delete();
  }

  /// Get player season totals
  Future<PlayerSeasonTotals?> getPlayerSeasonTotals(String teamId, String seasonId, String playerId) async {
    final doc = await _db.doc(FP.teamSeasonPlayerStats(teamId, seasonId, playerId)).get();
    
    if (doc.exists) {
      return PlayerSeasonTotals.fromJson(doc.data()!);
    }
    return null;
  }

  /// Get all player season totals for a team
  Future<List<PlayerSeasonTotals>> getAllPlayerSeasonTotals(String teamId, String seasonId) async {
    final snapshot = await _db.collection(FP.teamSeasonStats(teamId, seasonId)).get();
    return snapshot.docs.map((doc) => PlayerSeasonTotals.fromJson(doc.data())).toList();
  }

  /// Stream all player season totals for a team (real-time updates)
  Stream<List<PlayerSeasonTotals>> streamAllPlayerSeasonTotals(String teamId, String seasonId) {
    return _db.collection(FP.teamSeasonStats(teamId, seasonId))
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PlayerSeasonTotals.fromJson(doc.data())).toList());
  }

  /// Stream specific player season totals (real-time updates)
  Stream<PlayerSeasonTotals?> streamPlayerSeasonTotals(String teamId, String seasonId, String playerId) {
    return _db.doc(FP.teamSeasonPlayerStats(teamId, seasonId, playerId))
        .snapshots()
        .map((doc) => doc.exists ? PlayerSeasonTotals.fromJson(doc.data()!) : null);
  }

  /// Get team season totals (aggregated stats)
  Future<Map<String, dynamic>> getTeamSeasonTotals(String teamId, String seasonId) async {
    final players = await getAllPlayerSeasonTotals(teamId, seasonId);
    
    if (players.isEmpty) {
      return _getEmptyTeamTotals();
    }

    // Aggregate all player stats
    final totals = <String, dynamic>{
      'totalGames': players.fold<int>(0, (total, player) => total + player.games),
      'totalAtBats': players.fold<int>(0, (total, player) => total + player.atBats),
      'totalHits': players.fold<int>(0, (total, player) => total + player.hits),
      'totalRuns': players.fold<int>(0, (total, player) => total + player.runs),
      'totalRbi': players.fold<int>(0, (total, player) => total + player.rbi),
      'totalHomeRuns': players.fold<int>(0, (total, player) => total + player.homeRuns),
      'totalWalks': players.fold<int>(0, (total, player) => total + player.walks),
      'totalStrikeouts': players.fold<int>(0, (total, player) => total + player.strikeouts),
      'totalInningsPitched': players.fold<double>(0.0, (total, player) => total + player.inningsPitched),
      'teamBattingAverage': 0.0,
      'teamOnBasePercentage': 0.0,
      'teamSluggingPercentage': 0.0,
      'teamEra': 0.0,
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    // Calculate team averages
    if (totals['totalAtBats'] > 0) {
      totals['teamBattingAverage'] = (totals['totalHits'] as int) / (totals['totalAtBats'] as int);
    }

    // Calculate team ERA (simplified - would need earned runs data)
    if (totals['totalInningsPitched'] > 0) {
      // This would need earned runs data to calculate properly
      totals['teamEra'] = 0.0; // Placeholder
    }

    return totals;
  }

  /// Stream team season totals (real-time updates)
  Stream<Map<String, dynamic>> streamTeamSeasonTotals(String teamId, String seasonId) {
    return streamAllPlayerSeasonTotals(teamId, seasonId).map((players) {
      if (players.isEmpty) {
        return _getEmptyTeamTotals();
      }

      // Aggregate all player stats
      final totals = <String, dynamic>{
        'totalGames': players.fold<int>(0, (total, player) => total + player.games),
        'totalAtBats': players.fold<int>(0, (total, player) => total + player.atBats),
        'totalHits': players.fold<int>(0, (total, player) => total + player.hits),
        'totalRuns': players.fold<int>(0, (total, player) => total + player.runs),
        'totalRbi': players.fold<int>(0, (total, player) => total + player.rbi),
        'totalHomeRuns': players.fold<int>(0, (total, player) => total + player.homeRuns),
        'totalWalks': players.fold<int>(0, (total, player) => total + player.walks),
        'totalStrikeouts': players.fold<int>(0, (total, player) => total + player.strikeouts),
        'totalInningsPitched': players.fold<double>(0.0, (total, player) => total + player.inningsPitched),
        'teamBattingAverage': 0.0,
        'teamOnBasePercentage': 0.0,
        'teamSluggingPercentage': 0.0,
        'teamEra': 0.0,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      // Calculate team averages
      if (totals['totalAtBats'] > 0) {
        totals['teamBattingAverage'] = (totals['totalHits'] as int) / (totals['totalAtBats'] as int);
      }

      return totals;
    });
  }

  /// Get player rankings for a specific stat
  Future<List<Map<String, dynamic>>> getPlayerRankings(
    String teamId, 
    String seasonId, 
    String statName, 
    {bool descending = true}
  ) async {
    final players = await getAllPlayerSeasonTotals(teamId, seasonId);
    
    // Sort players by the specified stat
    players.sort((a, b) {
      final aValue = _getStatValue(a, statName);
      final bValue = _getStatValue(b, statName);
      
      if (descending) {
        return bValue.compareTo(aValue);
      } else {
        return aValue.compareTo(bValue);
      }
    });

    // Return rankings with player info
    return players.asMap().entries.map((entry) {
      final index = entry.key;
      final player = entry.value;
      return {
        'rank': index + 1,
        'playerId': player.playerId,
        'value': _getStatValue(player, statName),
        'statName': statName,
      };
    }).toList();
  }

  /// Stream player rankings for a specific stat (real-time updates)
  Stream<List<Map<String, dynamic>>> streamPlayerRankings(
    String teamId, 
    String seasonId, 
    String statName, 
    {bool descending = true}
  ) {
    return streamAllPlayerSeasonTotals(teamId, seasonId).map((players) {
      // Sort players by the specified stat
      players.sort((a, b) {
        final aValue = _getStatValue(a, statName);
        final bValue = _getStatValue(b, statName);
        
        if (descending) {
          return bValue.compareTo(aValue);
        } else {
          return aValue.compareTo(bValue);
        }
      });

      // Return rankings with player info
      return players.asMap().entries.map((entry) {
        final index = entry.key;
        final player = entry.value;
        return {
          'rank': index + 1,
          'playerId': player.playerId,
          'value': _getStatValue(player, statName),
          'statName': statName,
        };
      }).toList();
    });
  }

  /// Update player stats from game data
  Future<void> updatePlayerStatsFromGame(
    String teamId, 
    String seasonId, 
    String playerId, 
    Map<String, dynamic> gameStats
  ) async {
    final currentStats = await getPlayerSeasonTotals(teamId, seasonId, playerId);
    
    if (currentStats != null) {
      // Update existing stats
      final updatedStats = currentStats.copyWith(
        games: currentStats.games + 1,
        atBats: currentStats.atBats + (gameStats['atBats'] as int? ?? 0),
        hits: currentStats.hits + (gameStats['hits'] as int? ?? 0),
        runs: currentStats.runs + (gameStats['runs'] as int? ?? 0),
        rbi: currentStats.rbi + (gameStats['rbi'] as int? ?? 0),
        homeRuns: currentStats.homeRuns + (gameStats['homeRuns'] as int? ?? 0),
        walks: currentStats.walks + (gameStats['walks'] as int? ?? 0),
        strikeouts: currentStats.strikeouts + (gameStats['strikeouts'] as int? ?? 0),
        inningsPitched: currentStats.inningsPitched + (gameStats['inningsPitched'] as double? ?? 0.0),
        lastUpdated: DateTime.now(),
      );
      
      await updatePlayerSeasonTotals(teamId, seasonId, updatedStats);
    } else {
      // Create new stats
      final newStats = PlayerSeasonTotals(
        playerId: playerId,
        games: 1,
        atBats: gameStats['atBats'] as int? ?? 0,
        hits: gameStats['hits'] as int? ?? 0,
        runs: gameStats['runs'] as int? ?? 0,
        rbi: gameStats['rbi'] as int? ?? 0,
        homeRuns: gameStats['homeRuns'] as int? ?? 0,
        walks: gameStats['walks'] as int? ?? 0,
        strikeouts: gameStats['strikeouts'] as int? ?? 0,
        inningsPitched: gameStats['inningsPitched'] as double? ?? 0.0,
        lastUpdated: DateTime.now(),
      );
      
      await createPlayerSeasonTotals(teamId, seasonId, newStats);
    }
  }

  /// Batch update multiple player stats
  Future<void> batchUpdatePlayerStats(
    String teamId, 
    String seasonId, 
    List<PlayerSeasonTotals> statsList
  ) async {
    final batch = _db.batch();
    
    for (final stats in statsList) {
      final docRef = _db.collection(FP.teamSeasonStats(teamId, seasonId)).doc(stats.playerId);
      batch.set(docRef, stats.toJson());
    }
    
    await batch.commit();
  }

  /// Get empty team totals
  Map<String, dynamic> _getEmptyTeamTotals() {
    return {
      'totalGames': 0,
      'totalAtBats': 0,
      'totalHits': 0,
      'totalRuns': 0,
      'totalRbi': 0,
      'totalHomeRuns': 0,
      'totalWalks': 0,
      'totalStrikeouts': 0,
      'totalInningsPitched': 0.0,
      'teamBattingAverage': 0.0,
      'teamOnBasePercentage': 0.0,
      'teamSluggingPercentage': 0.0,
      'teamEra': 0.0,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Get stat value from player stats
  double _getStatValue(PlayerSeasonTotals player, String statName) {
    switch (statName.toLowerCase()) {
      case 'games':
        return player.games.toDouble();
      case 'atbats':
      case 'at_bats':
        return player.atBats.toDouble();
      case 'hits':
        return player.hits.toDouble();
      case 'runs':
        return player.runs.toDouble();
      case 'rbi':
        return player.rbi.toDouble();
      case 'homeruns':
      case 'home_runs':
        return player.homeRuns.toDouble();
      case 'walks':
        return player.walks.toDouble();
      case 'strikeouts':
        return player.strikeouts.toDouble();
      case 'inningspitched':
      case 'innings_pitched':
        return player.inningsPitched;
      default:
        return 0.0;
    }
  }
}