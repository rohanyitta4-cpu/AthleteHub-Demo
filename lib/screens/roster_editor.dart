import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/roster_entry.dart';
import '../repos/roster_repo.dart';
import '../repos/team_repo.dart';
import '../utils/friendly_error.dart';
// Create repos inside dialog to avoid relying on outer state

class RosterEditorScreen extends StatefulWidget {
  final String teamId;
  final String teamName;

  const RosterEditorScreen({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<RosterEditorScreen> createState() => _RosterEditorScreenState();
}

class _RosterEditorScreenState extends State<RosterEditorScreen> {
  final RosterRepo _rosterRepo = RosterRepo();
  final TeamRepo _teamRepo = TeamRepo();
  List<RosterEntry> _roster = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoster();
  }

  Future<void> _loadRoster() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final rosterStream = _rosterRepo.streamRoster(widget.teamId);
      await for (final roster in rosterStream) {
        setState(() {
          _roster = roster;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = friendlyError(e, "Couldn't load the roster");
        _isLoading = false;
      });
    }
  }

  void _addPlayer() {
    showDialog(
      context: context,
      builder: (context) => _AddPlayerDialog(
        teamId: widget.teamId,
        onPlayerAdded: _loadRoster,
      ),
    );
  }

  void _editPlayer(RosterEntry player) {
    showDialog(
      context: context,
      builder: (context) => _EditPlayerDialog(
        teamId: widget.teamId,
        player: player,
        onPlayerUpdated: _loadRoster,
      ),
    );
  }

  Future<void> _removePlayer(RosterEntry player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Player'),
        content: Text('Are you sure you want to remove ${player.playerId} from the roster?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _rosterRepo.removeRosterEntry(widget.teamId, player.playerId);
        await _teamRepo.removePlayerFromTeam(widget.teamId, player.playerId);
        _loadRoster();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e, "Couldn't remove the player")),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.teamName} Roster'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _addPlayer,
            icon: const Icon(Icons.person_add),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadRoster,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_roster.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No players in roster',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add players to get started',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addPlayer,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Player'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _roster.length,
      itemBuilder: (context, index) {
        final player = _roster[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[600],
              child: Text(
                player.jerseyNumber?.toString() ?? '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              player.playerId,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (player.role != null)
                  Text('Role: ${player.role}'),
                if (player.addedAt != null)
                  Text(
                    'Added: ${player.addedAt!.day}/${player.addedAt!.month}/${player.addedAt!.year}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editPlayer(player);
                    break;
                  case 'remove':
                    _removePlayer(player);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddPlayerDialog extends StatefulWidget {
  final String teamId;
  final VoidCallback onPlayerAdded;

  const _AddPlayerDialog({
    required this.teamId,
    required this.onPlayerAdded,
  });

  @override
  State<_AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<_AddPlayerDialog> {
  final RosterRepo _rosterRepo = RosterRepo();
  final TeamRepo _teamRepo = TeamRepo();
  final _formKey = GlobalKey<FormState>();
  final _playerIdController = TextEditingController();
  final _roleController = TextEditingController();
  final _jerseyNumberController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _playerIdController.dispose();
    _roleController.dispose();
    _jerseyNumberController.dispose();
    super.dispose();
  }

  Future<void> _addPlayer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final playerId = _playerIdController.text.trim();
      final role = _roleController.text.trim().isEmpty ? null : _roleController.text.trim();
      final jerseyNumber = _jerseyNumberController.text.trim().isEmpty
          ? null
          : int.tryParse(_jerseyNumberController.text.trim());

      // Create roster entry
      final rosterEntry = RosterEntry(
        playerId: playerId,
        role: role,
        jerseyNumber: jerseyNumber,
        addedAt: DateTime.now(),
      );

      await _rosterRepo.addRosterEntry(widget.teamId, rosterEntry);

      // Add player to team
      await _teamRepo.addPlayerToTeam(widget.teamId, playerId);

      // Create user profile if it doesn't exist
      await _createUserProfile(playerId);

      widget.onPlayerAdded();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, "Couldn't add the player")),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createUserProfile(String playerId) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(playerId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        await userRef.set({
          'displayName': playerId,
          'firstName': playerId.split(' ').first,
          'lastName': playerId.split(' ').length > 1 ? playerId.split(' ').last : '',
          'email': '$playerId@example.com',
          'linkedTeams': FieldValue.arrayUnion([widget.teamId]),
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Create role document
        await userRef.collection('roles').doc(widget.teamId).set({
          'role': 'player',
          'teamId': widget.teamId,
        });
      }
    } catch (e) {
      print('Error creating user profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Player'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _playerIdController,
              decoration: const InputDecoration(
                labelText: 'Player Name/ID',
                border: OutlineInputBorder(),
                hintText: 'e.g., John Doe',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a player name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Role (Optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., Starter, Bench',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _jerseyNumberController,
              decoration: const InputDecoration(
                labelText: 'Jersey Number (Optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., 42',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final number = int.tryParse(value.trim());
                  if (number == null || number < 0) {
                    return 'Please enter a valid jersey number';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addPlayer,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}

class _EditPlayerDialog extends StatefulWidget {
  final String teamId;
  final RosterEntry player;
  final VoidCallback onPlayerUpdated;

  const _EditPlayerDialog({
    required this.teamId,
    required this.player,
    required this.onPlayerUpdated,
  });

  @override
  State<_EditPlayerDialog> createState() => _EditPlayerDialogState();
}

class _EditPlayerDialogState extends State<_EditPlayerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _roleController = TextEditingController();
  final _jerseyNumberController = TextEditingController();
  final RosterRepo _rosterRepo = RosterRepo();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _roleController.text = widget.player.role ?? '';
    _jerseyNumberController.text = widget.player.jerseyNumber?.toString() ?? '';
  }

  @override
  void dispose() {
    _roleController.dispose();
    _jerseyNumberController.dispose();
    super.dispose();
  }

  Future<void> _updatePlayer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final role = _roleController.text.trim().isEmpty ? null : _roleController.text.trim();
      final jerseyNumber = _jerseyNumberController.text.trim().isEmpty
          ? null
          : int.tryParse(_jerseyNumberController.text.trim());

      final updatedPlayer = widget.player.copyWith(
        role: role,
        jerseyNumber: jerseyNumber,
      );

      await _rosterRepo.updateRosterEntry(widget.teamId, updatedPlayer);

      widget.onPlayerUpdated();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, "Couldn't update the player")),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.player.playerId}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
                hintText: 'e.g., Starter, Bench',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _jerseyNumberController,
              decoration: const InputDecoration(
                labelText: 'Jersey Number',
                border: OutlineInputBorder(),
                hintText: 'e.g., 42',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final number = int.tryParse(value.trim());
                  if (number == null || number < 0) {
                    return 'Please enter a valid jersey number';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updatePlayer,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}