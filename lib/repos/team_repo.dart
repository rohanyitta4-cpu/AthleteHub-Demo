import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team.dart';
import '../data/firestore_service.dart';

class TeamRepo {
  static final _db = FirebaseFirestore.instance;

  /// Create a new team
  Future<String> createTeam(Team team) async {
    final docRef = await _db.teams().add(team);
    return docRef.id;
  }

  /// Get a specific team by ID
  Future<Team?> getTeam(String teamId) async {
    final doc = await _db.team(teamId).get();
    return doc.data();
  }

  /// Update an existing team
  Future<void> updateTeam(String teamId, Team team) async {
    await _db.team(teamId).set(team);
  }

  /// Delete a team
  Future<void> deleteTeam(String teamId) async {
    await _db.team(teamId).delete();
  }

  /// Stream a specific team (real-time updates)
  Stream<Team?> streamTeam(String teamId) {
    return _db.team(teamId).snapshots().map((doc) => doc.data());
  }

  /// Stream all teams for a specific coach
  Stream<List<Team>> streamTeamsForCoach(String coachId) {
    return _db.teams()
        .where('coachIds', arrayContains: coachId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Stream all teams for a specific player
  Stream<List<Team>> streamTeamsForPlayer(String playerId) {
    return _db.teams()
        .where('playerIds', arrayContains: playerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Get all teams for a coach (one-time fetch)
  Future<List<Team>> getTeamsForCoach(String coachId) async {
    final snapshot = await _db.teams()
        .where('coachIds', arrayContains: coachId)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Get all teams for a player (one-time fetch)
  Future<List<Team>> getTeamsForPlayer(String playerId) async {
    final snapshot = await _db.teams()
        .where('playerIds', arrayContains: playerId)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Add a coach to a team
  Future<void> addCoachToTeam(String teamId, String coachId) async {
    final team = await getTeam(teamId);
    if (team != null) {
      final updatedTeam = team.copyWith(
        coachIds: [...team.coachIds, coachId],
        updatedAt: DateTime.now(),
      );
      await updateTeam(teamId, updatedTeam);
    }
  }

  /// Remove a coach from a team
  Future<void> removeCoachFromTeam(String teamId, String coachId) async {
    final team = await getTeam(teamId);
    if (team != null) {
      final updatedTeam = team.copyWith(
        coachIds: team.coachIds.where((id) => id != coachId).toList(),
        updatedAt: DateTime.now(),
      );
      await updateTeam(teamId, updatedTeam);
    }
  }

  /// Add a player to a team
  Future<void> addPlayerToTeam(String teamId, String playerId) async {
    final team = await getTeam(teamId);
    if (team != null) {
      final updatedTeam = team.copyWith(
        playerIds: [...team.playerIds, playerId],
        updatedAt: DateTime.now(),
      );
      await updateTeam(teamId, updatedTeam);
    }
  }

  /// Remove a player from a team
  Future<void> removePlayerFromTeam(String teamId, String playerId) async {
    final team = await getTeam(teamId);
    if (team != null) {
      final updatedTeam = team.copyWith(
        playerIds: team.playerIds.where((id) => id != playerId).toList(),
        updatedAt: DateTime.now(),
      );
      await updateTeam(teamId, updatedTeam);
    }
  }

  /// Update team settings
  Future<void> updateTeamSettings(String teamId, Map<String, dynamic> settings) async {
    final team = await getTeam(teamId);
    if (team != null) {
      final updatedTeam = team.copyWith(
        settings: settings,
        updatedAt: DateTime.now(),
      );
      await updateTeam(teamId, updatedTeam);
    }
  }

  /// Check if user is a coach of a team
  Future<bool> isCoachOfTeam(String teamId, String userId) async {
    final team = await getTeam(teamId);
    return team?.coachIds.contains(userId) ?? false;
  }

  /// Check if user is a player of a team
  Future<bool> isPlayerOfTeam(String teamId, String userId) async {
    final team = await getTeam(teamId);
    return team?.playerIds.contains(userId) ?? false;
  }

  /// Check if user has any role in a team
  Future<bool> isMemberOfTeam(String teamId, String userId) async {
    final team = await getTeam(teamId);
    return team?.coachIds.contains(userId) == true || 
           team?.playerIds.contains(userId) == true;
  }

  /// Get team membership role for a user
  Future<String?> getUserTeamRole(String teamId, String userId) async {
    final team = await getTeam(teamId);
    if (team == null) return null;
    
    if (team.coachIds.contains(userId)) return 'coach';
    if (team.playerIds.contains(userId)) return 'player';
    return null;
  }
}