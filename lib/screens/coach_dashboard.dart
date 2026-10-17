import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/gradient_container.dart';
import '../models/team_v3.dart';
import '../models/game_v3.dart';
import '../utils/friendly_error.dart';

class CoachDashboard extends StatefulWidget {
  const CoachDashboard({super.key});

  @override
  State<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  TeamV3? _currentTeam;
  List<GameV3> _upcomingGames = [];
  List<GameV3> _recentGames = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCoachData();
  }

  Future<void> _loadCoachData() async {
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
      await _loadTeamData(user.uid);
      
      // Load games data
      if (_currentTeam != null) {
        await _loadGamesData();
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = friendlyError(e, "Couldn't load your team");
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTeamData(String userId) async {
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
      print('Error loading team data: $e');
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
      // Load upcoming games (next 7 days)
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));
      
      final upcomingQuery = await _firestore
          .collection('games')
          .where('teamHome', isEqualTo: _currentTeam!.teamId)
          .where('date', isGreaterThan: now)
          .where('date', isLessThan: nextWeek)
          .orderBy('date')
          .get();

      // Load recent games (last 7 days)
      final lastWeek = now.subtract(const Duration(days: 7));
      
      final recentQuery = await _firestore
          .collection('games')
          .where('teamHome', isEqualTo: _currentTeam!.teamId)
          .where('date', isGreaterThan: lastWeek)
          .where('date', isLessThan: now)
          .orderBy('date', descending: true)
          .get();

      setState(() {
        _upcomingGames = upcomingQuery.docs
            .map((doc) => GameV3.fromJson(doc.data()))
            .toList();
        _recentGames = recentQuery.docs
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
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: const Text('Coach Dashboard')),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.black),
      ),
    );
  }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: const Text('Coach Dashboard')),
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
                onPressed: _loadCoachData,
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
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: const Text('Coach Dashboard')),
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
                            Icons.sports_baseball,
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
                                'COACH DASHBOARD',
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

              // Quick Stats Summary
              _buildQuickStats(),

              const SizedBox(height: 24),

              // Upcoming Games
              _buildUpcomingGames(),

              const SizedBox(height: 24),

              // Recent Games
              _buildRecentGames(),

              const SizedBox(height: 24),

              // Start Live Game Button
              _buildStartLiveGameButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
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
          Text(
            'Quick Stats',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2563eb),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Upcoming Games',
                  '${_upcomingGames.length}',
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Recent Games',
                  '${_recentGames.length}',
                  Icons.history,
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
                  'Team Players',
                  _currentTeam?.playerIds.length.toString() ?? '0',
                  Icons.group,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Season Record',
                  '0-0',
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

  Widget _buildUpcomingGames() {
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
              const Icon(Icons.schedule, color: Color(0xFF2563eb)),
              const SizedBox(width: 8),
              Text(
                'Upcoming Games',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2563eb),
                ),
            ),
          ],
        ),
          const SizedBox(height: 16),
          if (_upcomingGames.isEmpty)
            Text(
              'No upcoming games scheduled',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ..._upcomingGames.take(3).map((game) => _buildGameCard(game, isUpcoming: true)),
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
            if (_recentGames.isEmpty)
            Text(
              'No recent games',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ..._recentGames.take(3).map((game) => _buildGameCard(game, isUpcoming: false)),
        ],
      ),
    );
  }

  Widget _buildGameCard(GameV3 game, {required bool isUpcoming}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[800]?.withOpacity(0.3)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUpcoming ? Colors.orange.withOpacity(0.3) : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isUpcoming ? Icons.schedule : Icons.check_circle,
            color: isUpcoming ? Colors.orange : Colors.green,
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
                  '${game.date.day}/${game.date.month}/${game.date.year}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            game.state.name.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isUpcoming ? Colors.orange : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartLiveGameButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Navigate to live game setup
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Live game feature coming soon!')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563eb),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.play_arrow, color: Colors.white),
        label: Text(
          'Start Live Game',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}