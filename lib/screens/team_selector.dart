import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_team_membership.dart';
import '../config/feature_flags.dart';
import '../repos/team_repo.dart';
import '../utils/friendly_error.dart';

class TeamSelectorScreen extends StatefulWidget {
  const TeamSelectorScreen({super.key});

  @override
  State<TeamSelectorScreen> createState() => _TeamSelectorScreenState();
}

class _TeamSelectorScreenState extends State<TeamSelectorScreen> {
  final TeamRepo _teamRepo = TeamRepo();
  String? _selectedTeamId;
  bool _isLoading = true;
  List<UserTeamMembership> _userTeams = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserTeams();
  }

  Future<void> _loadUserTeams() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Get user's linked teams
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        setState(() {
          _error = 'User profile not found';
          _isLoading = false;
        });
        return;
      }

      final userData = userDoc.data()!;
      final linkedTeams = List<String>.from(userData['linkedTeams'] ?? []);

      if (linkedTeams.isEmpty) {
        setState(() {
          _error = 'No teams found. Create a team or ask a coach to add you.';
          _isLoading = false;
        });
        return;
      }

      // Load team details
      final teams = <UserTeamMembership>[];
      for (final teamId in linkedTeams) {
        try {
          final team = await _teamRepo.getTeam(teamId);
          if (team != null) {
            // Get user's role in this team
            final roleDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('roles')
                .doc(teamId)
                .get();

            final role = roleDoc.exists ? roleDoc.data()!['role'] : 'player';

            teams.add(UserTeamMembership(
              userId: user.uid,
              teamId: teamId,
              teamName: team.name,
              role: role,
              joinedAt: DateTime.now(),
              isActive: true,
              isDefault: false,
            ));
          }
        } catch (e) {
          print('Error loading team $teamId: $e');
        }
      }

      setState(() {
        _userTeams = teams;
        _selectedTeamId = teams.isNotEmpty ? teams.first.teamId : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = friendlyError(e, "Couldn't load your teams");
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTeam(String teamId) async {
    setState(() {
      _selectedTeamId = teamId;
    });

    // Update user's default team
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'defaultTeamId': teamId,
          'lastTeamSelection': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating default team: $e');
    }
  }

  void _navigateToTeam() {
    if (_selectedTeamId == null) return;

    final selectedTeam = _userTeams.firstWhere(
      (team) => team.teamId == _selectedTeamId,
    );

    // Navigate based on role
    if (selectedTeam.role == 'coach' && !FeatureFlags.coachAccounts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coach accounts are coming soon.')),
      );
    } else if (selectedTeam.role == 'coach') {
      Navigator.pushReplacementNamed(context, '/coach-dashboard', arguments: {
        'teamId': _selectedTeamId,
        'teamName': selectedTeam.teamName,
      });
    } else {
      Navigator.pushReplacementNamed(context, '/athlete-dashboard', arguments: {
        'teamId': _selectedTeamId,
        'teamName': selectedTeam.teamName,
      });
    }
  }

  void _createTeam() {
    Navigator.pushNamed(context, '/create-team');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Team'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUserTeams,
              child: const Text('Retry'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createTeam,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Team'),
            ),
          ],
        ),
      );
    }

    if (_userTeams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No teams found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a team or ask a coach to add you.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _createTeam,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Create Team'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _userTeams.length,
            itemBuilder: (context, index) {
              final team = _userTeams[index];
              final isSelected = team.teamId == _selectedTeamId;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isSelected ? 8 : 2,
                color: isSelected ? Colors.blue[50] : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? Colors.blue[600] : Colors.grey[400],
                    child: Icon(
                      team.role == 'coach' ? Icons.sports_baseball : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    team.teamName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.blue[800] : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Role: ${team.role.toUpperCase()}',
                        style: TextStyle(
                          color: team.role == 'coach' ? Colors.blue[600] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (team.isDefault)
                        const Text(
                          'Default Team',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: Colors.blue[600],
                        )
                      : null,
                  onTap: () => _selectTeam(team.teamId),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              top: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedTeamId != null ? _navigateToTeam : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Continue to Dashboard',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _createTeam,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[600],
                    side: BorderSide(color: Colors.blue[600]!),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Create New Team',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}