import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/team_v3.dart';
import '../models/roster_entry_v3.dart';
import '../models/game_v3.dart';
import '../models/game_event_v3.dart';
import '../models/invite_code_v3.dart';
import '../models/season_v2.dart';
import '../models/game.dart';
import '../models/user_profile_v2.dart';

class BaseballMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Main migration function - migrates from current structure to new baseball structure
  static Future<void> migrateToBaseballStructure() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    print('🏗️ Starting migration to baseball structure for user: ${user.uid}');

    try {
      // Step 1: Check if user already has a team, if not create one
      String teamId = await getUserTeamId() ?? '';
      if (teamId.isEmpty) {
        teamId = await _createDefaultTeam(user.uid);
        print('✅ Created default team: $teamId');
      } else {
        print('ℹ️ User already has team: $teamId');
      }

      // Step 2: Create roster entry for user (only if they're a player)
      final userProfile = await _getUserProfile(user.uid);
      if (userProfile != null && userProfile.role == UserRole.player) {
        await _createRosterEntry(user.uid, teamId);
        print('✅ Created roster entry');
      } else {
        print('ℹ️ Skipping roster entry creation for non-player or null profile');
      }

      // Step 3: Migrate seasons and games
      await _migrateSeasonsAndGames(user.uid, teamId);
      print('✅ Migrated seasons and games');

      // Step 4: Update user profile with team reference
      await _updateUserProfile(user.uid, teamId);
      print('✅ Updated user profile');

      // Step 5: Create sample invite code
      await _createSampleInviteCode(teamId);
      print('✅ Created sample invite code');

      print('🎉 Migration completed successfully!');
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// Create a default team for the user
  static Future<String> _createDefaultTeam(String userId) async {
    final teamId = _firestore.collection('teams').doc().id;
    final now = DateTime.now();
    final team = TeamV3(
      teamId: teamId,
      name: 'My Team',
      coachIds: [userId],
      playerIds: [],
      settings: {},
      createdAt: now,
      updatedAt: now,
      ended: false,
      expiresAt: now.add(const Duration(days: 100)),
    );
    await _firestore.collection('teams').doc(teamId).set(team.toJson());
    return teamId;
  }

  /// Get user profile to check role
  static Future<UserProfileV2?> _getUserProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          return UserProfileV2.fromJson(data);
        }
      }
    } catch (e) {
      print('Error getting user profile: $e');
    }
    return null;
  }

  /// Create roster entry for the user
  static Future<void> _createRosterEntry(String userId, String teamId) async {
    try {
      final rosterEntry = RosterEntryV3(
        playerId: userId,
        teamId: teamId,
        userId: userId,
        position: 'Player',
        jerseyNumber: 1,
        joinedAt: DateTime.now(),
      );

      await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('roster_entries')
          .doc(userId)
          .set(rosterEntry.toJson());
    } catch (e) {
      print('Error creating roster entry: $e');
    }
  }

  /// Migrate existing seasons and games to new structure
  static Future<void> _migrateSeasonsAndGames(String userId, String teamId) async {
    try {
      // Get all seasons for user
      final seasonsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('seasons')
          .get();

      for (final seasonDoc in seasonsSnapshot.docs) {
        try {
          final season = SeasonV2.fromJson(seasonDoc.data());
          print('📊 Migrating season: ${season.name}');

          // Get all games for this season
          final gamesSnapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('seasons')
              .doc(season.seasonId)
              .collection('games')
              .get();

          // Migrate each game
          for (final gameDoc in gamesSnapshot.docs) {
            try {
              final game = Game.fromJson(gameDoc.data());
              await _migrateGame(game, teamId);
            } catch (e) {
              print('⚠️ Error migrating game: $e');
            }
          }
        } catch (e) {
          print('⚠️ Error migrating season: $e');
        }
      }
    } catch (e) {
      print('⚠️ Error in games migration: $e');
    }
  }

  /// Migrate individual game to new structure
  static Future<void> _migrateGame(Game game, String teamId) async {
    try {
      // Create new game in teams structure
      final newGame = GameV3(
        gameId: game.gameId,
        teamHome: teamId, // User's team is home
        teamAway: 'opponent_${game.opponent.replaceAll(' ', '_').toLowerCase()}',
        date: game.gameDate,
        state: game.status == GameStatus.completed 
            ? GameState.completed 
            : GameState.scheduled,
        score: {'home': 0, 'away': 0}, // Default scores
        metadata: {
          'original_location': game.location,
          'original_opponent': game.opponent,
          'migrated_from': 'user_games',
          'migrated_at': DateTime.now().toIso8601String(),
        },
        createdAt: game.createdAt ?? DateTime.now(),
        updatedAt: game.updatedAt ?? DateTime.now(),
      );

      await _firestore
          .collection('games')
          .doc(game.gameId)
          .set(newGame.toJson());

      // Create game events from the embedded stats
      await _createGameEventsFromStats(game, teamId);
    } catch (e) {
      print('⚠️ Error saving game: $e');
    }
  }

  /// Create game events from embedded stats
  static Future<void> _createGameEventsFromStats(Game game, String teamId) async {
    try {
      final events = <GameEventV3>[];
      int eventCounter = 0;

      // Create events for each stat
      for (int i = 0; i < game.atBats; i++) {
        eventCounter++;
        final event = GameEventV3(
          eventId: '${game.gameId}_event_$eventCounter',
          timestamp: game.gameDate.add(Duration(minutes: i * 2)), // Spread events over time
          inning: 1,
          half: 'bottom',
          batterId: game.playerId,
          pitcherId: 'opponent_pitcher',
          outcome: _determineOutcomeFromStats(game, i),
          runnersBefore: {'1st': false, '2nd': false, '3rd': false},
          runnersAfter: {'1st': false, '2nd': false, '3rd': false},
          rbi: i < game.runsBattedIn ? 1 : 0,
          metadata: {
            'migrated_from_stats': true,
            'original_game_id': game.gameId,
          },
        );
        events.add(event);
      }

      // Save all events
      for (final event in events) {
        try {
          await _firestore
              .collection('games')
              .doc(game.gameId)
              .collection('events')
              .doc(event.eventId)
              .set(event.toJson());
        } catch (e) {
          print('⚠️ Error saving event: $e');
        }
      }
    } catch (e) {
      print('⚠️ Error creating game events: $e');
    }
  }

  /// Determine event outcome based on stats
  static EventOutcome _determineOutcomeFromStats(Game game, int atBatIndex) {
    // Simple logic to distribute outcomes based on stats
    final hits = game.hits;
    final homeRuns = game.homeRuns;
    final triples = game.triples;
    final doubles = game.doubles;
    final walks = game.walks;
    final strikeouts = game.strikeouts;
    
    if (atBatIndex < hits) {
      if (atBatIndex < homeRuns) return EventOutcome.homeRun;
      if (atBatIndex < homeRuns + triples) return EventOutcome.tripleCenter;
      if (atBatIndex < homeRuns + triples + doubles) return EventOutcome.doubleCenter;
      return EventOutcome.singleCenter;
    } else if (atBatIndex < hits + walks) {
      return EventOutcome.walk;
    } else if (atBatIndex < hits + walks + strikeouts) {
      return EventOutcome.strikeout;
    } else {
      return EventOutcome.groundout;
    }
  }

  /// Update user profile with team reference
  static Future<void> _updateUserProfile(String userId, String teamId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'teamId': teamId,
        'migration_completed': true,
        'migration_date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }

  /// Create sample invite code
  static Future<void> _createSampleInviteCode(String teamId) async {
    try {
      final inviteCode = InviteCodeV3(
        code: 'TEAM${teamId.substring(0, 8).toUpperCase()}',
        teamId: teamId,
        role: InviteRole.player,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        maxUses: 10,
        createdAt: DateTime.now(),
        createdBy: _auth.currentUser?.uid,
      );

      await _firestore
          .collection('inviteCodes')
          .doc(inviteCode.code)
          .set(inviteCode.toJson());
    } catch (e) {
      print('Error creating sample invite code: $e');
    }
  }

  /// Check if migration is needed
  static Future<bool> isMigrationNeeded() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data();
      return data == null || !data.containsKey('migration_completed');
    } catch (e) {
      print('Error checking migration status: $e');
      return false;
    }
  }

  /// Get user's team ID
  static Future<String?> getUserTeamId() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      return userDoc.data()?['teamId'] as String?;
    } catch (e) {
      print('Error getting user team ID: $e');
      return null;
    }
  }
}
