import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/team_v3.dart';
import '../models/roster_entry_v3.dart';
import '../models/game_v3.dart';
import '../models/game_event_v3.dart';
import '../models/invite_code_v3.dart';
import 'baseball_migration_service.dart';

class BaseballService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get user's team
  static Future<TeamV3?> getUserTeam() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final teamId = await BaseballMigrationService.getUserTeamId();
    if (teamId == null) return null;

    final teamDoc = await _firestore.collection('teams').doc(teamId).get();
    if (!teamDoc.exists) return null;

    return TeamV3.fromJson(teamDoc.data()!);
  }

  /// Get team roster
  static Future<List<RosterEntryV3>> getTeamRoster(String teamId) async {
    final rosterSnapshot = await _firestore
        .collection('teams')
        .doc(teamId)
        .collection('roster_entries')
        .get();

    return rosterSnapshot.docs
        .map((doc) => RosterEntryV3.fromJson(doc.data()))
        .toList();
  }

  /// Get team games
  static Future<List<GameV3>> getTeamGames(String teamId) async {
    final gamesSnapshot = await _firestore
        .collection('games')
        .where('teamHome', isEqualTo: teamId)
        .orderBy('date', descending: true)
        .get();

    final awayGamesSnapshot = await _firestore
        .collection('games')
        .where('teamAway', isEqualTo: teamId)
        .orderBy('date', descending: true)
        .get();

    final homeGames = gamesSnapshot.docs
        .map((doc) => GameV3.fromJson(doc.data()))
        .toList();

    final awayGames = awayGamesSnapshot.docs
        .map((doc) => GameV3.fromJson(doc.data()))
        .toList();

    final allGames = [...homeGames, ...awayGames];
    allGames.sort((a, b) => b.date.compareTo(a.date));
    return allGames;
  }

  /// Get game events
  static Future<List<GameEventV3>> getGameEvents(String gameId) async {
    final eventsSnapshot = await _firestore
        .collection('games')
        .doc(gameId)
        .collection('events')
        .orderBy('timestamp')
        .get();

    return eventsSnapshot.docs
        .map((doc) => GameEventV3.fromJson(doc.data()))
        .toList();
  }

  /// Create new game
  static Future<String> createGame({
    required String teamHome,
    required String teamAway,
    required DateTime date,
    String? opponent,
  }) async {
    final gameId = _firestore.collection('games').doc().id;
    final game = GameV3(
      gameId: gameId,
      teamHome: teamHome,
      teamAway: teamAway,
      date: date,
      metadata: opponent != null ? {'opponent': opponent} : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('games').doc(gameId).set(game.toJson());
    return gameId;
  }

  /// Add game event
  static Future<void> addGameEvent({
    required String gameId,
    required String batterId,
    required String pitcherId,
    required EventOutcome outcome,
    int inning = 1,
    String half = 'bottom',
    Map<String, bool>? runnersBefore,
    Map<String, bool>? runnersAfter,
    int rbi = 0,
    String? scorerId,
  }) async {
    final eventId = _firestore.collection('games').doc().id;
    final event = GameEventV3(
      eventId: eventId,
      timestamp: DateTime.now(),
      inning: inning,
      half: half,
      batterId: batterId,
      pitcherId: pitcherId,
      outcome: outcome,
      runnersBefore: runnersBefore ?? {'1st': false, '2nd': false, '3rd': false},
      runnersAfter: runnersAfter ?? {'1st': false, '2nd': false, '3rd': false},
      rbi: rbi,
      scorerId: scorerId,
    );

    await _firestore
        .collection('games')
        .doc(gameId)
        .collection('events')
        .doc(eventId)
        .set(event.toJson());

    // Update game state if needed
    await _updateGameState(gameId);
  }

  /// Update game state based on events
  static Future<void> _updateGameState(String gameId) async {
    final eventsSnapshot = await _firestore
        .collection('games')
        .doc(gameId)
        .collection('events')
        .get();

    if (eventsSnapshot.docs.isNotEmpty) {
      await _firestore.collection('games').doc(gameId).update({
        'state': GameState.inProgress.toString(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Join team via invite code
  static Future<bool> joinTeamViaInviteCode(String inviteCode) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final code = inviteCode.trim().toUpperCase();
    final inviteRef = _firestore.collection('inviteCodes').doc(code);
    final inviteSnap = await inviteRef.get();
    if (!inviteSnap.exists) return false;
    final data = inviteSnap.data()!;
    // Handle Timestamp or String for expiresAt for backward compatibility
    DateTime expiresAt;
    final rawExpires = data['expiresAt'];
    if (rawExpires is Timestamp) {
      expiresAt = rawExpires.toDate();
    } else if (rawExpires is String) {
      expiresAt = DateTime.tryParse(rawExpires) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else if (rawExpires is int) {
      expiresAt = DateTime.fromMillisecondsSinceEpoch(rawExpires);
    } else {
      expiresAt = DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (expiresAt.isBefore(DateTime.now())) return false;
    if (data['active'] != true) return false;

    final String teamId = data['teamId'];
    final teamRef = _firestore.collection('teams').doc(teamId);
    final rosterRef = teamRef.collection('roster_entries').doc(user.uid);

    try {
      await _firestore.runTransaction((tx) async {
        final inviteDoc = await tx.get(inviteRef);
        if (!inviteDoc.exists) throw Exception('Code vanished');
        final inviteData = inviteDoc.data()!;
        final int uses = (inviteData['uses'] ?? 0) as int;
        final int maxUses = (inviteData['maxUses'] ?? 1000000) as int;
        if (uses >= maxUses) {
          throw Exception('Code has reached max uses');
        }

        tx.set(rosterRef, {
          'playerId': user.uid,
          'joinedAt': FieldValue.serverTimestamp(),
          'role': 'player',
        }, SetOptions(merge: true));

        tx.update(teamRef, {
          'playerIds': FieldValue.arrayUnion([user.uid]),
        });

        tx.update(inviteRef, {
          'uses': FieldValue.increment(1),
        });
      });

      await _firestore.collection('users').doc(user.uid).set({
        'teamId': teamId,
        'role': 'player',
      }, SetOptions(merge: true));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Create invite code via Cloud Function (secure)
  static Future<String> createInviteCodeCF({
    required String teamId,
    InviteRole role = InviteRole.player,
    int ttlHours = 48,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final callable = FirebaseFunctions.instance.httpsCallable('createInviteCode');
    final result = await callable.call({
      'teamId': teamId,
      'role': role.name,
      'ttlHours': ttlHours,
    });
    final code = result.data['code'].toString().toUpperCase();
    return code;
  }

  /// Generate random invite code
  // Deprecated: client-side generation removed in favor of Cloud Function

  /// Get team stats from events
  static Future<Map<String, dynamic>> getTeamStats(String teamId) async {
    final games = await getTeamGames(teamId);
    final stats = <String, dynamic>{
      'gamesPlayed': games.length,
      'wins': 0,
      'losses': 0,
      'totalRuns': 0,
      'totalHits': 0,
      'totalAtBats': 0,
    };

    for (final game in games) {
      final events = await getGameEvents(game.gameId);
      
      // Calculate game stats
      int runs = 0;
      int hits = 0;
      int atBats = 0;
      
      for (final event in events) {
        if (event.batterId == _auth.currentUser?.uid) {
          atBats++;
          if (_isHit(event.outcome)) hits++;
          if (event.rbi > 0) runs += event.rbi;
        }
      }
      
      stats['totalRuns'] = (stats['totalRuns'] as int) + runs;
      stats['totalHits'] = (stats['totalHits'] as int) + hits;
      stats['totalAtBats'] = (stats['totalAtBats'] as int) + atBats;
      
      // Determine win/loss
      if (game.state == GameState.completed) {
        if (game.teamHome == teamId) {
          if (game.score['home']! > game.score['away']!) {
            stats['wins'] = (stats['wins'] as int) + 1;
          } else {
            stats['losses'] = (stats['losses'] as int) + 1;
          }
        } else {
          if (game.score['away']! > game.score['home']!) {
            stats['wins'] = (stats['wins'] as int) + 1;
          } else {
            stats['losses'] = (stats['losses'] as int) + 1;
          }
        }
      }
    }

    // Calculate batting average
    if (stats['totalAtBats'] > 0) {
      stats['battingAverage'] = (stats['totalHits'] as int) / (stats['totalAtBats'] as int);
    } else {
      stats['battingAverage'] = 0.0;
    }

    return stats;
  }

  /// Check if event outcome is a hit
  static bool _isHit(EventOutcome outcome) {
    return [
      EventOutcome.singleLeft, EventOutcome.singleCenter, EventOutcome.singleRight,
      EventOutcome.doubleLeft, EventOutcome.doubleCenter, EventOutcome.doubleRight,
      EventOutcome.tripleLeft, EventOutcome.tripleCenter, EventOutcome.tripleRight,
      EventOutcome.homeRun,
    ].contains(outcome);
  }
}
