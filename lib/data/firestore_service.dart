import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team.dart';
import '../models/roster_entry.dart';
import '../models/team_season_meta.dart';
import '../models/team_game.dart';
import '../models/player_season_totals.dart';
import '../models/user_team_membership.dart';
import 'firestore_paths.dart';

final db = FirebaseFirestore.instance;

extension TypedCollection on FirebaseFirestore {
  CollectionReference<T> colWithConverter<T>({
    required String path,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
  }) => collection(path).withConverter<T>(
      fromFirestore: (snap, _) {
        final data = snap.data() as Map<String, dynamic>;
        data['id'] = snap.id;
        return fromJson(data);
      },
      toFirestore: (value, _) => toJson(value),
  );
}

extension TypedFirestoreService on FirebaseFirestore {
  // Teams
  CollectionReference<Team> teams() => colWithConverter<Team>(
    path: FP.teams(),
    fromJson: Team.fromJson,
    toJson: (team) => team.toJson(),
  );

  DocumentReference<Team> team(String teamId) => teams().doc(teamId);

  // Team Roster
  CollectionReference<RosterEntry> teamRoster(String teamId) => colWithConverter<RosterEntry>(
    path: FP.teamRoster(teamId),
    fromJson: RosterEntry.fromJson,
    toJson: (entry) => entry.toJson(),
  );

  DocumentReference<RosterEntry> teamRosterPlayer(String teamId, String playerId) => 
    teamRoster(teamId).doc(playerId);

  // Team Seasons
  CollectionReference<TeamSeasonMeta> teamSeasons(String teamId) => colWithConverter<TeamSeasonMeta>(
    path: FP.teamSeasons(teamId),
    fromJson: TeamSeasonMeta.fromJson,
    toJson: (season) => season.toJson(),
  );

  DocumentReference<TeamSeasonMeta> teamSeason(String teamId, String seasonId) => 
    teamSeasons(teamId).doc(seasonId);

  // Team Games
  CollectionReference<TeamGame> teamGames(String teamId, String seasonId) => colWithConverter<TeamGame>(
    path: FP.teamGames(teamId, seasonId),
    fromJson: TeamGame.fromJson,
    toJson: (game) => game.toJson(),
  );

  DocumentReference<TeamGame> teamGame(String teamId, String seasonId, String gameId) => 
    teamGames(teamId, seasonId).doc(gameId);

  // Team Season Stats
  CollectionReference<PlayerSeasonTotals> teamSeasonPlayerStats(String teamId, String seasonId) => 
    colWithConverter<PlayerSeasonTotals>(
      path: FP.teamSeasonStats(teamId, seasonId),
      fromJson: PlayerSeasonTotals.fromJson,
      toJson: (stats) => stats.toJson(),
    );

  DocumentReference<PlayerSeasonTotals> teamSeasonPlayerStat(String teamId, String seasonId, String playerId) => 
    teamSeasonPlayerStats(teamId, seasonId).doc(playerId);

  // User Team Memberships
  CollectionReference<UserTeamMembership> userTeams(String userId) => colWithConverter<UserTeamMembership>(
    path: FP.userTeams(userId),
    fromJson: UserTeamMembership.fromJson,
    toJson: (membership) => membership.toJson(),
  );

  DocumentReference<UserTeamMembership> userTeam(String userId, String teamId) => 
    userTeams(userId).doc(teamId);
}

// Convenience methods for common operations
class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // Team operations
  static Future<String> createTeam(Team team) async {
    final docRef = await _db.teams().add(team);
    return docRef.id;
  }

  static Future<void> updateTeam(String teamId, Team team) async {
    await _db.team(teamId).set(team);
  }

  static Future<Team?> getTeam(String teamId) async {
    final doc = await _db.team(teamId).get();
    return doc.data();
  }

  static Stream<Team?> watchTeam(String teamId) {
    return _db.team(teamId).snapshots().map((doc) => doc.data());
  }

  // Team roster operations
  static Future<void> addPlayerToRoster(String teamId, RosterEntry entry) async {
    await _db.teamRosterPlayer(teamId, entry.playerId).set(entry);
  }

  static Future<void> removePlayerFromRoster(String teamId, String playerId) async {
    await _db.teamRosterPlayer(teamId, playerId).delete();
  }

  static Future<List<RosterEntry>> getTeamRoster(String teamId) async {
    final snapshot = await _db.teamRoster(teamId).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  static Stream<List<RosterEntry>> watchTeamRoster(String teamId) {
    return _db.teamRoster(teamId).snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Season operations
  static Future<String> createSeason(String teamId, TeamSeasonMeta season) async {
    final docRef = await _db.teamSeasons(teamId).add(season);
    return docRef.id;
  }

  static Future<void> updateSeason(String teamId, String seasonId, TeamSeasonMeta season) async {
    await _db.teamSeason(teamId, seasonId).set(season);
  }

  static Future<TeamSeasonMeta?> getSeason(String teamId, String seasonId) async {
    final doc = await _db.teamSeason(teamId, seasonId).get();
    return doc.data();
  }

  static Future<List<TeamSeasonMeta>> getTeamSeasons(String teamId) async {
    final snapshot = await _db.teamSeasons(teamId).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  static Stream<List<TeamSeasonMeta>> watchTeamSeasons(String teamId) {
    return _db.teamSeasons(teamId).snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Game operations
  static Future<String> createGame(String teamId, String seasonId, TeamGame game) async {
    final docRef = await _db.teamGames(teamId, seasonId).add(game);
    return docRef.id;
  }

  static Future<void> updateGame(String teamId, String seasonId, String gameId, TeamGame game) async {
    await _db.teamGame(teamId, seasonId, gameId).set(game);
  }

  static Future<TeamGame?> getGame(String teamId, String seasonId, String gameId) async {
    final doc = await _db.teamGame(teamId, seasonId, gameId).get();
    return doc.data();
  }

  static Future<List<TeamGame>> getTeamGames(String teamId, String seasonId) async {
    final snapshot = await _db.teamGames(teamId, seasonId).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  static Stream<List<TeamGame>> watchTeamGames(String teamId, String seasonId) {
    return _db.teamGames(teamId, seasonId).snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Player stats operations
  static Future<void> updatePlayerSeasonStats(String teamId, String seasonId, PlayerSeasonTotals stats) async {
    await _db.teamSeasonPlayerStat(teamId, seasonId, stats.playerId).set(stats);
  }

  static Future<PlayerSeasonTotals?> getPlayerSeasonStats(String teamId, String seasonId, String playerId) async {
    final doc = await _db.teamSeasonPlayerStat(teamId, seasonId, playerId).get();
    return doc.data();
  }

  static Future<List<PlayerSeasonTotals>> getAllPlayerSeasonStats(String teamId, String seasonId) async {
    final snapshot = await _db.teamSeasonPlayerStats(teamId, seasonId).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  static Stream<List<PlayerSeasonTotals>> watchAllPlayerSeasonStats(String teamId, String seasonId) {
    return _db.teamSeasonPlayerStats(teamId, seasonId).snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => doc.data()).toList());
  }

  // User team membership operations
  static Future<void> addUserToTeam(String userId, UserTeamMembership membership) async {
    await _db.userTeam(userId, membership.teamId).set(membership);
  }

  static Future<void> removeUserFromTeam(String userId, String teamId) async {
    await _db.userTeam(userId, teamId).delete();
  }

  static Future<List<UserTeamMembership>> getUserTeams(String userId) async {
    final snapshot = await _db.userTeams(userId).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  static Stream<List<UserTeamMembership>> watchUserTeams(String userId) {
    return _db.userTeams(userId).snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Batch operations
  static Future<void> batchCreateGameWithStats({
    required String teamId,
    required String seasonId,
    required TeamGame game,
    required List<PlayerSeasonTotals> playerStats,
  }) async {
    final batch = _db.batch();
    
    // Add game
    final gameRef = _db.teamGames(teamId, seasonId).doc();
    batch.set(gameRef, game);
    
    // Update player stats
    for (final stats in playerStats) {
      final statsRef = _db.teamSeasonPlayerStat(teamId, seasonId, stats.playerId);
      batch.set(statsRef, stats);
    }
    
    await batch.commit();
  }

  // Query helpers
  static Future<List<Team>> getTeamsByCoach(String coachId) async {
    final snapshot = await _db.teams()
        .where('coachIds', arrayContains: coachId)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  static Future<List<Team>> getTeamsByPlayer(String playerId) async {
    final snapshot = await _db.teams()
        .where('playerIds', arrayContains: playerId)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  static Future<List<TeamGame>> getGamesByPlayer(String teamId, String seasonId, String playerId) async {
    final snapshot = await _db.teamGames(teamId, seasonId)
        .where('playerStats.$playerId', isNull: false)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}