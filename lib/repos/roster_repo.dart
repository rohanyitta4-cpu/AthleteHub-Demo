import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/firestore_paths.dart';
import '../models/roster_entry.dart';

class RosterRepo {
  static final _db = FirebaseFirestore.instance;

  /// Add a player to the team roster
  Future<void> addRosterEntry(String teamId, RosterEntry entry) async {
    await _db.collection(FP.teamRoster(teamId))
        .doc(entry.playerId)
        .set(entry.toJson());
  }

  /// Update an existing roster entry
  Future<void> updateRosterEntry(String teamId, RosterEntry entry) async {
    await _db.collection(FP.teamRoster(teamId))
        .doc(entry.playerId)
        .set(entry.toJson());
  }

  /// Remove a player from the team roster
  Future<void> removeRosterEntry(String teamId, String playerId) async {
    await _db.collection(FP.teamRoster(teamId))
        .doc(playerId)
        .delete();
  }

  /// Get a specific roster entry
  Future<RosterEntry?> getRosterEntry(String teamId, String playerId) async {
    final doc = await _db.collection(FP.teamRoster(teamId))
        .doc(playerId)
        .get();
    
    if (doc.exists) {
      return RosterEntry.fromJson(doc.data()!);
    }
    return null;
  }

  /// Get all roster entries for a team (one-time fetch)
  Future<List<RosterEntry>> getRoster(String teamId) async {
    final snapshot = await _db.collection(FP.teamRoster(teamId)).get();
    return snapshot.docs.map((doc) => RosterEntry.fromJson(doc.data())).toList();
  }

  /// Stream all roster entries for a team (real-time updates)
  Stream<List<RosterEntry>> streamRoster(String teamId) {
    return _db.collection(FP.teamRoster(teamId))
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => RosterEntry.fromJson(doc.data())).toList());
  }

  /// Stream roster entries by role (e.g., "starter", "bench")
  Stream<List<RosterEntry>> streamRosterByRole(String teamId, String role) {
    return _db.collection(FP.teamRoster(teamId))
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => RosterEntry.fromJson(doc.data())).toList());
  }

  /// Get roster entries by role (one-time fetch)
  Future<List<RosterEntry>> getRosterByRole(String teamId, String role) async {
    final snapshot = await _db.collection(FP.teamRoster(teamId))
        .where('role', isEqualTo: role)
        .get();
    return snapshot.docs.map((doc) => RosterEntry.fromJson(doc.data())).toList();
  }

  /// Update player role
  Future<void> updatePlayerRole(String teamId, String playerId, String newRole) async {
    final entry = await getRosterEntry(teamId, playerId);
    if (entry != null) {
      final updatedEntry = entry.copyWith(role: newRole);
      await updateRosterEntry(teamId, updatedEntry);
    }
  }

  /// Update player jersey number
  Future<void> updateJerseyNumber(String teamId, String playerId, int jerseyNumber) async {
    final entry = await getRosterEntry(teamId, playerId);
    if (entry != null) {
      final updatedEntry = entry.copyWith(jerseyNumber: jerseyNumber);
      await updateRosterEntry(teamId, updatedEntry);
    }
  }

  /// Get roster entry by jersey number
  Future<RosterEntry?> getRosterEntryByJersey(String teamId, int jerseyNumber) async {
    final snapshot = await _db.collection(FP.teamRoster(teamId))
        .where('jerseyNumber', isEqualTo: jerseyNumber)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return RosterEntry.fromJson(snapshot.docs.first.data());
    }
    return null;
  }

  /// Check if jersey number is available
  Future<bool> isJerseyNumberAvailable(String teamId, int jerseyNumber, {String? excludePlayerId}) async {
    final snapshot = await _db.collection(FP.teamRoster(teamId))
        .where('jerseyNumber', isEqualTo: jerseyNumber)
        .get();
    
    if (excludePlayerId != null) {
      return snapshot.docs.every((doc) => doc.id == excludePlayerId);
    }
    
    return snapshot.docs.isEmpty;
  }

  /// Get next available jersey number
  Future<int> getNextAvailableJerseyNumber(String teamId) async {
    final roster = await getRoster(teamId);
    final usedNumbers = roster
        .where((entry) => entry.jerseyNumber != null)
        .map((entry) => entry.jerseyNumber!)
        .toSet();
    
    int number = 1;
    while (usedNumbers.contains(number)) {
      number++;
    }
    return number;
  }

  /// Batch add multiple roster entries
  Future<void> batchAddRosterEntries(String teamId, List<RosterEntry> entries) async {
    final batch = _db.batch();
    
    for (final entry in entries) {
      final docRef = _db.collection(FP.teamRoster(teamId)).doc(entry.playerId);
      batch.set(docRef, entry.toJson());
    }
    
    await batch.commit();
  }

  /// Batch remove multiple roster entries
  Future<void> batchRemoveRosterEntries(String teamId, List<String> playerIds) async {
    final batch = _db.batch();
    
    for (final playerId in playerIds) {
      final docRef = _db.collection(FP.teamRoster(teamId)).doc(playerId);
      batch.delete(docRef);
    }
    
    await batch.commit();
  }

  /// Get roster statistics
  Future<Map<String, int>> getRosterStats(String teamId) async {
    final roster = await getRoster(teamId);
    
    final stats = <String, int>{
      'total': roster.length,
      'starters': 0,
      'bench': 0,
      'noRole': 0,
    };
    
    for (final entry in roster) {
      if (entry.role == 'starter') {
        stats['starters'] = (stats['starters'] ?? 0) + 1;
      } else if (entry.role == 'bench') {
        stats['bench'] = (stats['bench'] ?? 0) + 1;
      } else {
        stats['noRole'] = (stats['noRole'] ?? 0) + 1;
      }
    }
    
    return stats;
  }

  /// Search roster by player name (if you have player names stored elsewhere)
  Future<List<RosterEntry>> searchRoster(String teamId, String query) async {
    // This would require additional data structure to store player names
    // For now, return all roster entries
    final roster = await getRoster(teamId);
    return roster.where((entry) => 
        entry.playerId.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}