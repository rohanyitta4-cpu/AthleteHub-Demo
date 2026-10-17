import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'player_stats.dart';
import 'utils/season_stats_pipeline.dart';

class FirebaseStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Create default season for new users. [seasonName] overrides the default label when non-empty.
  Future<void> createDefaultSeason({String? seasonName}) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final seasonsRef = _firestore.collection('users').doc(currentUserId).collection('seasons');
      final activeSeasonQuery = await seasonsRef.where('isActive', isEqualTo: true).get();

      // If no active season exists, create one. Either way, ensure
      // `users/{uid}.currentActiveSeasonId` is set for immediate UX.
      if (activeSeasonQuery.docs.isEmpty) {
        final resolvedName = seasonName?.trim();
        final displayName = (resolvedName != null && resolvedName.isNotEmpty)
            ? resolvedName
            : 'Default Season';
        final seasonRef = await seasonsRef.add({
          'name': displayName,
          'year': DateTime.now().year.toString(),
          'startDate': FieldValue.serverTimestamp(),
          'endDate': null,
          'isActive': true,
          'overallStats': PlayerStats().toJson(),
        });
        print('Created default season: ${seasonRef.id}');

        // Make the default season immediately discoverable by any UI that listens
        // to `currentActiveSeasonId` (and reduce "no active season" UX on first login).
        await _firestore.collection('users').doc(currentUserId).set({
          'currentActiveSeasonId': seasonRef.id,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('currentActiveSeasonId', seasonRef.id);
        } catch (_) {
          // Non-fatal: preferences are just a fast path for initial UX.
        }
      } else {
        // Active season already exists, but `currentActiveSeasonId` might be missing.
        final existingSeasonId = activeSeasonQuery.docs.first.id;
        await _firestore.collection('users').doc(currentUserId).set({
          'currentActiveSeasonId': existingSeasonId,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('currentActiveSeasonId', existingSeasonId);
        } catch (_) {
          // Non-fatal: preferences are just a fast path for initial UX.
        }
      }
    } catch (e) {
      print('Error creating default season: $e');
      throw Exception('Failed to create default season: $e');
    }
  }

  // Get active season
  Future<DocumentSnapshot?> getActiveSeason() async {
    if (currentUserId == null) return null;

    try {
      // 0) Prefer locally cached season id for immediate UX
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedId = prefs.getString('currentActiveSeasonId');
        if (cachedId != null && cachedId.isNotEmpty) {
          final cachedDoc = await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('seasons')
              .doc(cachedId)
              .get()
              .timeout(const Duration(seconds: 15));
          if (cachedDoc.exists) {
            return cachedDoc;
          }
        }
      } catch (_) {}

      // 1) Prefer explicitly selected season id on user
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final String? selectedSeasonId = userDoc.data() != null ? userDoc.data()!['currentActiveSeasonId'] as String? : null;
      if (selectedSeasonId != null && selectedSeasonId.isNotEmpty) {
        final selected = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('seasons')
            .doc(selectedSeasonId)
            .get()
            .timeout(const Duration(seconds: 30));
        if (selected.exists) {
          return selected;
        }
      }

      // 2) Fallback to any active season
      final query = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('seasons')
          .where('isActive', isEqualTo: true)
          .orderBy('startDate', descending: true)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 30));
      return query.docs.isNotEmpty ? query.docs.first : null;
    } catch (e) {
      print('Error getting active season: $e');
      return null;
    }
  }

  // Watch for changes to the currentActiveSeasonId field
  Stream<String?> watchCurrentActiveSeasonId() {
    final uid = currentUserId;
    if (uid == null) {
      return const Stream<String?>.empty();
    }
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => (snap.data() ?? const {})['currentActiveSeasonId'] as String?);
  }

  // Create new season
  Future<void> createNewSeason(String seasonName) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      print('Starting new season creation: $seasonName');
      final seasonsRef = _firestore.collection('users').doc(currentUserId).collection('seasons');
      
      // Deactivate ALL currently active seasons (batch operation)
      final activeSeasonsQuery = await seasonsRef.where('isActive', isEqualTo: true).get();
      if (activeSeasonsQuery.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in activeSeasonsQuery.docs) {
          batch.update(doc.reference, {
            'isActive': false,
            'endDate': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }

      final seasonRef = await seasonsRef.add({
        'name': seasonName.trim(),
        'year': DateTime.now().year.toString(),
        'startDate': FieldValue.serverTimestamp(),
        'endDate': null,
        'isActive': true,
        'overallStats': PlayerStats().toJson(),
      });

      // Update user's currentActiveSeasonId to ensure stats go to correct season
      await _firestore.collection('users').doc(currentUserId).set({
        'currentActiveSeasonId': seasonRef.id,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Persist locally
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('currentActiveSeasonId', seasonRef.id);
      } catch (_) {}

      print('Created new season: $seasonName with ID: ${seasonRef.id}');
    } catch (e) {
      print('Error creating new season: $e');
      throw Exception('Failed to create new season: $e');
    }
  }

  // Log game to active season
  Future<void> logGame(Map<String, dynamic> gameData) async {
    if (currentUserId == null) {
      print('No user ID available for game logging');
      return;
    }

    try {
      print('Starting game logging process...');
      
      // Get or create active season
      var activeSeason = await getActiveSeason();
      if (activeSeason == null) {
        print('No active season found, creating default...');
        try {
          await createDefaultSeason();
          activeSeason = await getActiveSeason();
        } catch (e) {
          print('Failed to create default season: $e');
          await _saveGameLocally(gameData);
          return;
        }
      }

      if (activeSeason == null) {
        print('No active season available for game logging');
        await _saveGameLocally(gameData);
        return;
      }

      print('Active season found: ${activeSeason.id}');

      // Extract stats from game data
      final gameStats = gameData['stats'] as Map<String, dynamic>;
      
      // Validate stats
      _validateGameStats(gameStats);

      // Add game to season (await and add updatedAt/ownerId for streaming & ordering)
      print('Adding game to season...');
      final payload = {
        'date': gameData['date'] ?? FieldValue.serverTimestamp(),
        'stats': gameStats,
        'updatedAt': FieldValue.serverTimestamp(),
        'ownerId': currentUserId,
      };

      late DocumentReference gameRef;
      try {
        gameRef = await activeSeason.reference
            .collection('games')
            .add(payload)
            .timeout(const Duration(seconds: 8));
        print('[SAVE] success gameId=${gameRef.id}');
      } on TimeoutException {
        print('[SAVE] timeout — write will continue in background');
        // Fire-and-forget to let the SDK finish when network resumes
        // ignore: unawaited_futures
        activeSeason.reference.collection('games').add(payload);
      }

      print('Game added successfully: ${gameRef.id}');

      // Update season overall stats
      print('Updating season stats...');
      await _updateSeasonStats(activeSeason.reference, gameStats);

      print('Logged game on ${DateTime.now()} with stats: $gameStats');
    } catch (e) {
      print('Error logging game: $e');
      // Save locally as fallback when Firebase fails
      await _saveGameLocally(gameData);
      print('Game saved locally as fallback');
    }
  }

  /// Add a game to the active season with client timestamp for immediate updates
  Future<void> addGame(Map<String, dynamic> gameData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final activeSeason = await getActiveSeason();
      if (activeSeason == null) throw Exception('No active season found');

      // Add both client and server timestamps for immediate updates
      final gameWithTimestamps = {
        ...gameData,
        'clientUpdatedAt': Timestamp.now(), // For immediate local ordering
        'updatedAt': FieldValue.serverTimestamp(), // For server truth
        'userId': user.uid,
        'seasonId': activeSeason.id,
      };

      print('🔄 [SAVE] Attempting to save game to: /users/${user.uid}/games');
      print('🔄 [SAVE] Payload: $gameWithTimestamps');

      // Save directly to user's games collection (unified path)
      final gameRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('games')
          .doc(); // Auto-generated ID

      // First attempt with timeout
      try {
        await gameRef
            .set(gameWithTimestamps, SetOptions(merge: true))
            .timeout(const Duration(seconds: 8));
        print('✅ [SAVE] Game saved OK at ${gameRef.path}');
      } on TimeoutException {
        print('⚠️ [SAVE] Timeout on first attempt, retrying without timeout...');
        // Retry without timeout - let Firestore handle it
        await gameRef.set(gameWithTimestamps, SetOptions(merge: true));
        print('✅ [SAVE] Game saved on retry at ${gameRef.path}');
      }

      // Also save to season for backward compatibility (background operation)
      // ignore: unawaited_futures
      FirebaseFirestore.instance
          .collection('seasons')
          .doc(activeSeason.id)
          .collection('games')
          .doc(gameRef.id)
          .set(gameWithTimestamps);

      // Update user's lastUpdated field to trigger stream refresh
      await forceStreamRefresh(user.uid);

    } on TimeoutException {
      print('❌ [SAVE] Final timeout after retry (check rules / connectivity)');
      throw Exception('Connection timeout. Please check your internet connection and try again.');
    } on FirebaseException catch (e, st) {
      print('❌ [SAVE] FirebaseException code=${e.code} msg=${e.message}');
      print('$st');
      
      String userMessage;
      switch (e.code) {
        case 'permission-denied':
          userMessage = 'Access denied. Please check your account permissions.';
          break;
        case 'unavailable':
          userMessage = 'Service temporarily unavailable. Please try again in a few minutes.';
          break;
        case 'resource-exhausted':
          userMessage = 'Service limit reached. Please try again later.';
          break;
        default:
          userMessage = 'Unable to save game. Please try again.';
      }
      
      throw Exception(userMessage);
    } catch (e, st) {
      print('❌ [SAVE] Unknown error: $e');
      print('$st');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  /// Real-time stream of all games for the current user (across seasons)
  /// Requires `ownerId` to be written with each `games` document (added in logGame).
  Stream<List<Map<String, dynamic>>> watchAllGames() {
    final uid = currentUserId;
    if (uid == null) {
      return const Stream<List<Map<String, dynamic>>>.empty();
    }

    // Use collectionGroup to observe every season's games for this user
    final query = _firestore
        .collectionGroup('games')
        .where('ownerId', isEqualTo: uid)
        .orderBy('date');

    return query.snapshots().map((snap) {
      final items = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final statsData = data['stats'];
        try {
          PlayerStats stats;
          if (statsData is PlayerStats) {
            stats = statsData;
          } else if (statsData is Map<String, dynamic>) {
            stats = PlayerStats.fromJson(statsData);
          } else {
            continue;
          }
          items.add({
            'date': data['date'] as Timestamp? ?? Timestamp.now(),
            'stats': stats,
          });
        } catch (_) {
          // Skip malformed items
          continue;
        }
      }
      return items;
    });
  }

  /// Get real-time stream of games for a user
  Stream<List<Map<String, dynamic>>> getGamesStream(String userId) {
    print('🔄 [STREAM] Starting games stream for user: $userId');
    
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('games')
        .orderBy('clientUpdatedAt', descending: true) // Order by client timestamp for immediate updates
        .snapshots()
        .map((snapshot) {
          print('🔄 [STREAM] Games updated: ${snapshot.docs.length} games');
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  /// Get real-time stream of games for a specific season
  Stream<List<Map<String, dynamic>>> getSeasonGamesStream(String seasonId) {
    print('🔄 [STREAM] Starting season games stream for: $seasonId');
    
    return FirebaseFirestore.instance
        .collection('seasons')
        .doc(seasonId)
        .collection('games')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          print('🔄 [STREAM] Season $seasonId games updated: ${snapshot.docs.length} games');
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Save game data locally as fallback
  Future<void> _saveGameLocally(Map<String, dynamic> gameData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localGames = prefs.getStringList('local_games') ?? [];
      
      // Convert game data to JSON string for storage
      final gameJson = {
        'date': DateTime.now().toIso8601String(),
        'stats': gameData['stats'],
      };
      
      // Add new game to local storage
      localGames.add(gameJson.toString());
      
      // Keep only last 50 games to prevent storage issues
      if (localGames.length > 50) {
        localGames.removeRange(0, localGames.length - 50);
      }
      
      await prefs.setStringList('local_games', localGames);
      print('Game saved locally: ${gameData['stats']}');
    } catch (e) {
      print('Error saving game locally: $e');
    }
  }

  // Load local games as fallback
  Future<List<Map<String, dynamic>>> loadLocalGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localGames = prefs.getStringList('local_games') ?? [];
      
      return localGames.map((gameStr) {
        try {
          // Parse the game string - it should be in format "{date: ..., stats: ...}"
          final cleanStr = gameStr.replaceAll('{', '').replaceAll('}', '');
          final parts = cleanStr.split(',');
          
          Map<String, dynamic> stats = {};
          for (final part in parts) {
            if (part.contains('stats:')) {
              // Extract stats part
              final statsPart = part.split('stats:')[1].trim();
              // Simple parsing - in a real app you'd use proper JSON parsing
              if (statsPart.contains('atBats:')) {
                final atBatsMatch = RegExp(r'atBats:\s*(\d+)').firstMatch(statsPart);
                if (atBatsMatch != null) {
                  stats['atBats'] = int.parse(atBatsMatch.group(1)!);
                }
              }
              if (statsPart.contains('hits:')) {
                final hitsMatch = RegExp(r'hits:\s*(\d+)').firstMatch(statsPart);
                if (hitsMatch != null) {
                  stats['hits'] = int.parse(hitsMatch.group(1)!);
                }
              }
              if (statsPart.contains('runs:')) {
                final runsMatch = RegExp(r'runs:\s*(\d+)').firstMatch(statsPart);
                if (runsMatch != null) {
                  stats['runs'] = int.parse(runsMatch.group(1)!);
                }
              }
            }
          }
          
          return {'stats': stats};
        } catch (e) {
          print('Error parsing local game: $e');
          return {'stats': {'atBats': 0, 'hits': 0, 'runs': 0}};
        }
      }).toList();
    } catch (e) {
      print('Error loading local games: $e');
      return [];
    }
  }

  // Get all seasons for user
  Future<List<DocumentSnapshot>> getAllSeasons() async {
    if (currentUserId == null) return [];

    try {
      final query = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('seasons')
          .orderBy('startDate', descending: true)
          .get()
          .timeout(const Duration(seconds: 30));
      return query.docs;
    } catch (e) {
      print('Error getting seasons: $e');
      return [];
    }
  }

  // Get games for a season
  Future<List<DocumentSnapshot>> getSeasonGames(String seasonId) async {
    if (currentUserId == null) return [];

    try {
      final query = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('seasons')
          .doc(seasonId)
          .collection('games')
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 30));
      return query.docs;
    } catch (e) {
      print('Error getting season games: $e');
      return [];
    }
  }

  /// Live stream of games for a season (same path/order as dashboard).
  Stream<QuerySnapshot> watchSeasonGames(String seasonId) {
    if (currentUserId == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('seasons')
        .doc(seasonId)
        .collection('games')
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Get season stats - calculates from actual games for accuracy
  Future<Map<String, dynamic>> getSeasonStats(String seasonId) async {
    if (currentUserId == null) return PlayerStats().toJson();

    try {
      final games = await getSeasonGames(seasonId);
      final aggregatedStats =
          aggregatePlayerStatsFromGameDocuments(games);
      return aggregatedStats.toJson();
    } catch (e) {
      print('Error getting season stats: $e');
      return PlayerStats().toJson();
    }
  }

  // Get all games for current user (for charts)
  Future<List<Map<String, dynamic>>> getAllGames() async {
    if (currentUserId == null) {
      print('No user ID available for getting games');
      return [];
    }

    try {
      print('Getting all games for user: $currentUserId');
      final seasons = await getAllSeasons();
      print('Found ${seasons.length} seasons');
      
      if (seasons.isEmpty) {
        print('No seasons found, creating default season');
        await createDefaultSeason();
        return [];
      }
      
      final allGames = <Map<String, dynamic>>[];
      
      for (final season in seasons) {
        print('Processing season: ${season.id}');
        final games = await getSeasonGames(season.id);
        print('Found ${games.length} games in season ${season.id}');
        
        for (final game in games) {
          try {
            final gameData = game.data() as Map<String, dynamic>?;
            if (gameData != null && gameData['stats'] != null) {
              // Convert stats to PlayerStats object
              final statsData = gameData['stats'];
              PlayerStats stats;
              
              if (statsData is PlayerStats) {
                stats = statsData;
              } else if (statsData is Map<String, dynamic>) {
                stats = PlayerStats.fromJson(statsData);
              } else {
                print('Invalid stats data type for game ${game.id}: ${statsData.runtimeType}');
                continue;
              }
              
              allGames.add({
                'date': gameData['date'] as Timestamp? ?? Timestamp.now(),
                'stats': stats, // Store as PlayerStats object
              });
            }
          } catch (e) {
            print('Error processing game ${game.id}: $e');
            continue;
          }
        }
      }
      
      print('Total games found: ${allGames.length}');
      
      // Sort by date
      if (allGames.isNotEmpty) {
        allGames.sort((a, b) => (b['date'] as Timestamp).compareTo(a['date'] as Timestamp));
      }
      
      return allGames;
    } catch (e) {
      print('Error getting all games: $e');
      return [];
    }
  }

  // Legacy methods
  Future<void> savePlayerStats(PlayerStats stats, {String? teamId}) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    await logGame({
      'date': FieldValue.serverTimestamp(),
      'stats': stats.toJson(),
    });
  }

  Future<PlayerStats?> loadPlayerStats({String? teamId}) async {
    if (currentUserId == null) return null;

    try {
      final activeSeason = await getActiveSeason();
      if (activeSeason != null) {
        final data = activeSeason.data() as Map<String, dynamic>?;
        if (data != null && data['overallStats'] != null) {
          return PlayerStats.fromJson(data['overallStats'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      print('Error loading player stats: $e');
      return null;
    }
  }

  // Validate game stats
  void _validateGameStats(Map<String, dynamic> stats) {
    if (stats.isEmpty) {
      throw Exception('Game stats cannot be empty');
    }
    
    // Add validation for required fields if needed
    if (stats['atBats'] != null && (stats['atBats'] as int) < 0) {
      throw Exception('At bats cannot be negative');
    }
  }

  // Update season overall stats
  Future<void> _updateSeasonStats(DocumentReference seasonRef, Map<String, dynamic> gameStats) async {
    try {
      final seasonDoc = await seasonRef.get();
      if (!seasonDoc.exists) return;

      final docData = seasonDoc.data() as Map<String, dynamic>?;
      if (docData == null) return;
      
      final overallStatsData = docData['overallStats'] as Map<String, dynamic>?;
      if (overallStatsData == null) return;

      final currentStats = PlayerStats.fromJson(overallStatsData);

      // Update stats with new game data
      final updatedStats = _calculateUpdatedStats(currentStats, gameStats);
      
      await seasonRef.update({
        'overallStats': updatedStats.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating season stats: $e');
      throw Exception('Failed to update season stats: $e');
    }
  }

  // Calculate updated stats
  PlayerStats _calculateUpdatedStats(PlayerStats currentStats, Map<String, dynamic> gameStats) {
    return currentStats + PlayerStats.fromJson(gameStats);
  }

  // Create sample game data for testing
  Future<void> createSampleGameData() async {
    if (currentUserId == null) {
      print('No user ID available for creating sample data');
      return;
    }

    try {
      print('Creating sample game data');
      
      // Ensure we have an active season
      await createDefaultSeason();
      
      // Create a sample game with realistic stats
      final sampleStats = PlayerStats(
        atBats: 4,
        hits: 2,
        doubles: 1,
        runs: 1,
        runsBattedIn: 1,
        walks: 1,
        strikeouts: 1,
        homeRuns: 0,
        triples: 0,
        stolenBases: 0,
        hitByPitch: 0,
        sacrificeHits: 0,
        twoStrikeCounts: 2,
        successWithTwoStrikes: 1,
        inningsPitched: 0,
        earnedRuns: 0,
        totalPitches: 0,
      );

      await logGame({
        'date': FieldValue.serverTimestamp(),
        'stats': sampleStats.toJson(),
        'opponent': 'Sample Team',
        'location': 'Home',
      });

      print('Sample game data created successfully');
    } catch (e) {
      print('Error creating sample game data: $e');
    }
  }

  /// Force refresh streams by updating a timestamp field
  /// This triggers the stream to emit new data
  Future<void> forceStreamRefresh(String userId) async {
    try {
      print('🔄 [STREAM] Forcing refresh for user: $userId');
      
      // Update a timestamp field in the user document to trigger stream refresh
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      print('🔄 [STREAM] Refresh triggered successfully');
    } catch (e) {
      print('❌ [STREAM] Failed to force refresh: $e');
    }
  }
}