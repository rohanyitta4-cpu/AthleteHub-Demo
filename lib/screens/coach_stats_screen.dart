import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/gradient_container.dart';
import '../models/team_v3.dart';
import '../models/game_v3.dart';
import '../utils/friendly_error.dart';

class CoachStatsScreen extends StatefulWidget {
  const CoachStatsScreen({super.key});

  @override
  State<CoachStatsScreen> createState() => _CoachStatsScreenState();
}

class _CoachStatsScreenState extends State<CoachStatsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  TeamV3? _currentTeam;
  List<GameV3> _games = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  Future<void> _loadTeamData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'No user logged in';
          _isLoading = false;
        });
        return;
      }

      // Load team data
      await _loadTeamInfo(user.uid);
      
      // Load games data
      if (_currentTeam != null) {
        await _loadGamesData();
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = friendlyError(e, "Couldn't load team stats");
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTeamInfo(String userId) async {
    try {
      // Find team where user is a coach
      final teamsQuery = await _firestore
          .collection('teams')
          .where('coachIds', arrayContains: userId)
          .get();

      if (teamsQuery.docs.isNotEmpty) {
        final teamData = teamsQuery.docs.first.data();
        // Convert timestamps to proper format
        final normalizedData = _normalizeTeamData(teamData);
        setState(() {
          _currentTeam = TeamV3.fromJson(normalizedData);
        });
      }
    } catch (e) {
      print('Error loading team info: $e');
    }
  }

  Map<String, dynamic> _normalizeTeamData(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);
    
    // Convert timestamps to DateTime strings
    if (data['createdAt'] is Timestamp) {
      normalized['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    if (data['updatedAt'] is Timestamp) {
      normalized['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
    }
    if (data['expiresAt'] is Timestamp) {
      normalized['expiresAt'] = (data['expiresAt'] as Timestamp).toDate().toIso8601String();
    }
    
    return normalized;
  }

  Future<void> _loadGamesData() async {
    if (_currentTeam == null) return;

    try {
      final gamesQuery = await _firestore
          .collection('games')
          .where('teamHome', isEqualTo: _currentTeam!.teamId)
          .orderBy('date', descending: true)
          .get();

      setState(() {
        _games = gamesQuery.docs
            .map((doc) => GameV3.fromJson(doc.data()))
            .toList();
      });
    } catch (e) {
      print('Error loading games data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: const Text('Coach Stats')),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: const Text('Coach Stats')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTeamData,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                child: Text('Retry', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: const Text('Coach Stats')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              GradientContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.analytics,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TEAM STATS',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2.0,
                                  shadows: [
                                    Shadow(
                                      color: const Color(0xFF2563eb).withOpacity(0.3),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentTeam?.name ?? 'No Team',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFC0C0C0),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Season Overview
              _buildSeasonOverview(),

              const SizedBox(height: 24),

              // Team Performance
              _buildTeamPerformance(),

              const SizedBox(height: 24),

              // Recent Games
              _buildRecentGames(),

              const SizedBox(height: 24),

              // Individual Player Stats (Placeholder)
              _buildPlayerStatsPlaceholder(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonOverview() {
    final completedGames = _games.where((game) => game.state == GameState.completed).length;
    final scheduledGames = _games.where((game) => game.state == GameState.scheduled).length;
    final totalGames = _games.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1A1A1A) 
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard, color: Color(0xFF2563eb)),
              const SizedBox(width: 8),
              Text(
                'Season Overview',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2563eb),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Games',
                  '$totalGames',
                  Icons.sports_baseball,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  '$completedGames',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Scheduled',
                  '$scheduledGames',
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Win Rate',
                  '${totalGames > 0 ? (completedGames * 100 / totalGames).toStringAsFixed(0) : 0}%',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamPerformance() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1A1A1A) 
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Color(0xFF2563eb)),
              const SizedBox(width: 8),
              Text(
                'Team Performance',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2563eb),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Text(
                  'Detailed analytics coming soon!',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This will include batting averages, ERA, fielding percentages, and more comprehensive team statistics.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentGames() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1A1A1A) 
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Color(0xFF2563eb)),
              const SizedBox(width: 8),
              Text(
                'Recent Games',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2563eb),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_games.isEmpty)
            Text(
              'No games played yet',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ..._games.take(5).map((game) => _buildGameCard(game)),
        ],
      ),
    );
  }

  Widget _buildGameCard(GameV3 game) {
    final isCompleted = game.state == GameState.completed;
    final isScheduled = game.state == GameState.scheduled;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[800]?.withOpacity(0.3)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted 
              ? Colors.green.withOpacity(0.3)
              : isScheduled 
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.schedule,
            color: isCompleted ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs ${game.teamAway}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${game.date.day}/${game.date.month}/${game.date.year} at ${game.date.hour.toString().padLeft(2, '0')}:${game.date.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (game.metadata?['location'] != null)
                  Text(
                    '📍 ${game.metadata!['location']}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                game.state.name.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? Colors.green : Colors.orange,
                ),
              ),
              if (isCompleted)
                Text(
                  '${game.score['home']} - ${game.score['away']}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatsPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1A1A1A) 
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF2563eb)),
              const SizedBox(width: 8),
              Text(
                'Player Statistics',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2563eb),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Text(
                  'Individual player stats coming soon!',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This will include batting averages, home runs, RBIs, ERA, strikeouts, and other detailed player performance metrics.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
