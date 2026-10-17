import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/firestore_paths.dart';
import '../models/team_game.dart';

class GameRepo {
  static final _db = FirebaseFirestore.instance;

  /// Add or update a game (upsert operation)
  Future<void> upsertGame(TeamGame game) async {
    final ref = _db.collection(FP.teamGames(game.teamId, game.seasonId)).doc(game.gameId);
    await ref.set(game.toJson(), SetOptions(merge: true));
    // Cloud Function will update aggregates
  }

  /// Create a new game
  Future<String> createGame(TeamGame game) async {
    final docRef = await _db.collection(FP.teamGames(game.teamId, game.seasonId)).add(game.toJson());
    return docRef.id;
  }

  /// Update an existing game
  Future<void> updateGame(TeamGame game) async {
    await _db.collection(FP.teamGames(game.teamId, game.seasonId))
        .doc(game.gameId)
        .set(game.toJson());
  }

  /// Delete a game
  Future<void> deleteGame(String teamId, String seasonId, String gameId) async {
    await _db.doc(FP.teamGame(teamId, seasonId, gameId)).delete();
  }

  /// Get a specific game
  Future<TeamGame?> getGame(String teamId, String seasonId, String gameId) async {
    final doc = await _db.doc(FP.teamGame(teamId, seasonId, gameId)).get();
    
    if (doc.exists) {
      return TeamGame.fromJson(doc.data()!);
    }
    return null;
  }

  /// Stream all games for a team and season (real-time updates)
  Stream<List<TeamGame>> streamGames(String teamId, String seasonId) {
    return _db.collection(FP.teamGames(teamId, seasonId))
        .orderBy('gameDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TeamGame.fromJson(doc.data())).toList());
  }

  /// Get all games for a team and season (one-time fetch)
  Future<List<TeamGame>> getGames(String teamId, String seasonId) async {
    final snapshot = await _db.collection(FP.teamGames(teamId, seasonId))
        .orderBy('gameDate', descending: true)
        .get();
    return snapshot.docs.map((doc) => TeamGame.fromJson(doc.data())).toList();
  }

  /// Stream games by date range
  Stream<List<TeamGame>> streamGamesByDateRange(
    String teamId, 
    String seasonId, 
    DateTime startDate, 
    DateTime endDate
  ) {
    return _db.collection(FP.teamGames(teamId, seasonId))
        .where('gameDate', isGreaterThanOrEqualTo: startDate)
        .where('gameDate', isLessThanOrEqualTo: endDate)
        .orderBy('gameDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TeamGame.fromJson(doc.data())).toList());
  }

  /// Get games by date range (one-time fetch)
  Future<List<TeamGame>> getGamesByDateRange(
    String teamId, 
    String seasonId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    final snapshot = await _db.collection(FP.teamGames(teamId, seasonId))
        .where('gameDate', isGreaterThanOrEqualTo: startDate)
        .where('gameDate', isLessThanOrEqualTo: endDate)
        .orderBy('gameDate', descending: true)
        .get();
    return snapshot.docs.map((doc) => TeamGame.fromJson(doc.data())).toList();
  }

  /// Stream games by opponent
  Stream<List<TeamGame>> streamGamesByOpponent(String teamId, String seasonId, String opponent) {
    return _db.collection(FP.teamGames(teamId, seasonId))
        .where('opponent', isEqualTo: opponent)
        .orderBy('gameDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TeamGame.fromJson(doc.data())).toList());
  }

  /// Get games by opponent (one-time fetch)
  Future<List<TeamGame>> getGamesByOpponent(String teamId, String seasonId, String opponent) async {
    final snapshot = await _db.collection(FP.teamGames(teamId, seasonId))
        .where('opponent', isEqualTo: opponent)
        .orderBy('gameDate', descending: true)
        .get();
    return snapshot.docs.map((doc) => TeamGame.fromJson(doc.data())).toList();
  }

  /// Stream games by type (regular, playoff, practice)
  Stream<List<TeamGame>> streamGamesByType(String teamId, String seasonId, String type) {
    return _db.collection(FP.teamGames(teamId, seasonId))
        .where('type', isEqualTo: type)
        .orderBy('gameDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TeamGame.fromJson(doc.data())).toList());
  }

  /// Get games by type (one-time fetch)
  Future<List<TeamGame>> getGamesByType(String teamId, String seasonId, String type) async {
    final snapshot = await _db.collection(FP.teamGames(teamId, seasonId))
        .where('type', isEqualTo: type)
        .orderBy('gameDate', descending: true)
        .get();
    return snapshot.docs.map((doc) => TeamGame.fromJson(doc.data())).toList();
  }

  /// Stream games by status (completed, in_progress, cancelled)
  Stream<List<TeamGame>> streamGamesByStatus(String teamId, String seasonId, String status) {
    return _db.collection(FP.teamGames(teamId, seasonId))
        .where('status', isEqualTo: status)
        .orderBy('gameDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TeamGame.fromJson(doc.data())).toList());
  }

  /// Get games by status (one-time fetch)
  Future<List<TeamGame>> getGamesByStatus(String teamId, String seasonId, String status) async {
    final snapshot = await _db.collection(FP.teamGames(teamId, seasonId))
        .where('status', isEqualTo: status)
        .orderBy('gameDate', descending: true)
        .get();
    return snapshot.docs.map((doc) => TeamGame.fromJson(doc.data())).toList();
  }

  /// Stream games for a specific player
  Stream<List<TeamGame>> streamGamesForPlayer(String teamId, String seasonId, String playerId) {
    return _db.collection(FP.teamGames(teamId, seasonId))
        .where('playerStats.$playerId', isNull: false)
        .orderBy('gameDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TeamGame.fromJson(doc.data())).toList());
  }

  /// Get games for a specific player (one-time fetch)
  Future<List<TeamGame>> getGamesForPlayer(String teamId, String seasonId, String playerId) async {
    final snapshot = await _db.collection(FP.teamGames(teamId, seasonId))
        .where('playerStats.$playerId', isNull: false)
        .orderBy('gameDate', descending: true)
        .get();
    return snapshot.docs.map((doc) => TeamGame.fromJson(doc.data())).toList();
  }

  /// Get recent games (last N games)
  Future<List<TeamGame>> getRecentGames(String teamId, String seasonId, int limit) async {
    final snapshot = await _db.collection(FP.teamGames(teamId, seasonId))
        .orderBy('gameDate', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => TeamGame.fromJson(doc.data())).toList();
  }

  /// Stream recent games (last N games)
  Stream<List<TeamGame>> streamRecentGames(String teamId, String seasonId, int limit) {
    return _db.collection(FP.teamGames(teamId, seasonId))
        .orderBy('gameDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TeamGame.fromJson(doc.data())).toList());
  }

  /// Update game status
  Future<void> updateGameStatus(String teamId, String seasonId, String gameId, String status) async {
    await _db.doc(FP.teamGame(teamId, seasonId, gameId))
        .update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
  }

  /// Update game metadata
  Future<void> updateGameMetadata(String teamId, String seasonId, String gameId, Map<String, dynamic> metadata) async {
    await _db.doc(FP.teamGame(teamId, seasonId, gameId))
        .update({'metadata': metadata, 'updatedAt': FieldValue.serverTimestamp()});
  }

  /// Add or update player stats for a game
  Future<void> updatePlayerGameStats(
    String teamId, 
    String seasonId, 
    String gameId, 
    String playerId, 
    PlayerGameStats stats
  ) async {
    final game = await getGame(teamId, seasonId, gameId);
    if (game != null) {
      final updatedPlayerStats = Map<String, PlayerGameStats>.from(game.playerStats);
      updatedPlayerStats[playerId] = stats;
      
      final updatedGame = game.copyWith(
        playerStats: updatedPlayerStats,
        updatedAt: DateTime.now(),
      );
      
      await updateGame(updatedGame);
    }
  }

  /// Remove player stats from a game
  Future<void> removePlayerGameStats(
    String teamId, 
    String seasonId, 
    String gameId, 
    String playerId
  ) async {
    final game = await getGame(teamId, seasonId, gameId);
    if (game != null) {
      final updatedPlayerStats = Map<String, PlayerGameStats>.from(game.playerStats);
      updatedPlayerStats.remove(playerId);
      
      final updatedGame = game.copyWith(
        playerStats: updatedPlayerStats,
        updatedAt: DateTime.now(),
      );
      
      await updateGame(updatedGame);
    }
  }

  /// Get game statistics
  Future<Map<String, dynamic>> getGameStats(String teamId, String seasonId) async {
    final games = await getGames(teamId, seasonId);
    
    final stats = <String, dynamic>{
      'totalGames': games.length,
      'completedGames': games.where((g) => g.status == 'completed').length,
      'inProgressGames': games.where((g) => g.status == 'in_progress').length,
      'cancelledGames': games.where((g) => g.status == 'cancelled').length,
      'regularGames': games.where((g) => g.type == 'regular').length,
      'playoffGames': games.where((g) => g.type == 'playoff').length,
      'practiceGames': games.where((g) => g.type == 'practice').length,
    };
    
    return stats;
  }

  /// Batch delete multiple games
  Future<void> batchDeleteGames(String teamId, String seasonId, List<String> gameIds) async {
    final batch = _db.batch();
    
    for (final gameId in gameIds) {
      final docRef = _db.doc(FP.teamGame(teamId, seasonId, gameId));
      batch.delete(docRef);
    }
    
    await batch.commit();
  }
}