import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/gradient_container.dart';
import '../models/team_v3.dart';
import '../models/game_v3.dart';
import '../utils/friendly_error.dart';

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  
  TeamV3? _currentTeam;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Form controllers
  final _opponentController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  @override
  void dispose() {
    _opponentController.dispose();
    _locationController.dispose();
    super.dispose();
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
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = friendlyError(e, "Couldn't load your team");
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _createGame() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentTeam == null) return;

    setState(() => _isLoading = true);

    try {
      // Combine date and time
      final gameDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Generate game ID
      final gameId = _firestore.collection('games').doc().id;

      final game = GameV3(
        gameId: gameId,
        teamHome: _currentTeam!.teamId,
        teamAway: _opponentController.text.trim(),
        date: gameDateTime,
        state: GameState.scheduled,
        inning: 1,
        half: 'top',
        outs: 0,
        runners: {'1st': false, '2nd': false, '3rd': false},
        score: {'home': 0, 'away': 0},
        lineupHome: [],
        lineupAway: [],
        events: [],
        metadata: {
          'location': _locationController.text.trim(),
          'created_by': _auth.currentUser!.uid,
          'created_at': DateTime.now().toIso8601String(),
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('games')
          .doc(gameId)
          .set(game.toJson());

      // Clear form
      _opponentController.clear();
      _locationController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _selectedTime = TimeOfDay.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, "Couldn't create the game")),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: const Text('Game Setup')),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: const Text('Game Setup')),
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
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: const Text('Game Setup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
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
                                  'GAME SETUP',
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

                // Game Setup Form
                _buildGameSetupForm(),

                const SizedBox(height: 24),

                // Create Game Button
                _buildCreateGameButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameSetupForm() {
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
              const Icon(Icons.add_circle_outline, color: Color(0xFF2563eb)),
              const SizedBox(width: 8),
              Text(
                'Create New Game',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2563eb),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Opponent Field
          TextFormField(
            controller: _opponentController,
            decoration: InputDecoration(
              labelText: 'Opponent Team',
              hintText: 'Enter opponent team name',
              prefixIcon: const Icon(Icons.group, color: Color(0xFF2563eb)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2563eb)),
              ),
            ),
            style: GoogleFonts.poppins(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter opponent team name';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Location Field
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Location',
              hintText: 'Enter game location',
              prefixIcon: const Icon(Icons.location_on, color: Color(0xFF2563eb)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2563eb)),
              ),
            ),
            style: GoogleFonts.poppins(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter game location';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Date and Time Selection
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Color(0xFF2563eb)),
                            const SizedBox(width: 8),
                            Text(
                              'Date',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF2563eb),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _selectTime,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Color(0xFF2563eb)),
                            const SizedBox(width: 8),
                            Text(
                              'Time',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF2563eb),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedTime.format(context),
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateGameButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _createGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563eb),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: _isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add, color: Colors.white),
        label: Text(
          _isLoading ? 'Creating Game...' : 'Create Game',
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
