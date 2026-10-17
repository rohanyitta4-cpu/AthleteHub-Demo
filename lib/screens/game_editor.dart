import 'package:flutter/material.dart';
import '../models/team_game.dart';
import '../models/roster_entry.dart';
import '../repos/game_repo.dart';
import '../repos/roster_repo.dart';
import '../utils/friendly_error.dart';

class GameEditorScreen extends StatefulWidget {
  final String teamId;
  final String seasonId;
  final String teamName;

  const GameEditorScreen({
    super.key,
    required this.teamId,
    required this.seasonId,
    required this.teamName,
  });

  @override
  State<GameEditorScreen> createState() => _GameEditorScreenState();
}

class _GameEditorScreenState extends State<GameEditorScreen> {
  final GameRepo _gameRepo = GameRepo();
  final RosterRepo _rosterRepo = RosterRepo();
  final _formKey = GlobalKey<FormState>();

  // Game details
  final _opponentController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _gameDate = DateTime.now();
  String _gameType = 'regular';
  String _gameStatus = 'completed';

  // Roster and stats
  List<RosterEntry> _roster = [];
  Map<String, PlayerGameStats> _playerStats = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoster();
  }

  @override
  void dispose() {
    _opponentController.dispose();
    _locationController.dispose();
    super.dispose();
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

        // Initialize player stats
        _initializePlayerStats();
      }
    } catch (e) {
      setState(() {
        _error = friendlyError(e, "Couldn't load the roster");
        _isLoading = false;
      });
    }
  }

  void _initializePlayerStats() {
    final stats = <String, PlayerGameStats>{};
    for (final player in _roster) {
      stats[player.playerId] = const PlayerGameStats();
    }
    setState(() {
      _playerStats = stats;
    });
  }

  Future<void> _saveGame() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final gameId = DateTime.now().millisecondsSinceEpoch.toString();
      final game = TeamGame(
        gameId: gameId,
        seasonId: widget.seasonId,
        teamId: widget.teamId,
        gameDate: _gameDate,
        opponent: _opponentController.text.trim(),
        location: _locationController.text.trim(),
        type: _gameType,
        status: _gameStatus,
        playerStats: _playerStats,
        metadata: {
          'createdBy': 'coach',
          'createdAt': DateTime.now().toIso8601String(),
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _gameRepo.upsertGame(game);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Game saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e, "Couldn't save the game")),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _updatePlayerStat(String playerId, String statName, dynamic value) {
    setState(() {
      final currentStats = _playerStats[playerId] ?? const PlayerGameStats();
      _playerStats[playerId] = _updateStatField(currentStats, statName, value);
    });
  }

  PlayerGameStats _updateStatField(PlayerGameStats stats, String statName, dynamic value) {
    switch (statName) {
      case 'atBats':
        return stats.copyWith(atBats: value as int);
      case 'runs':
        return stats.copyWith(runs: value as int);
      case 'hits':
        return stats.copyWith(hits: value as int);
      case 'doubles':
        return stats.copyWith(doubles: value as int);
      case 'triples':
        return stats.copyWith(triples: value as int);
      case 'homeRuns':
        return stats.copyWith(homeRuns: value as int);
      case 'walks':
        return stats.copyWith(walks: value as int);
      case 'hitByPitch':
        return stats.copyWith(hitByPitch: value as int);
      case 'strikeouts':
        return stats.copyWith(strikeouts: value as int);
      case 'inningsPitched':
        return stats.copyWith(inningsPitched: value as double);
      case 'earnedRuns':
        return stats.copyWith(earnedRuns: value as int);
      case 'totalPitches':
        return stats.copyWith(totalPitches: value as int);
      default:
        return stats;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Game'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveGame,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
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

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGameDetailsCard(),
            const SizedBox(height: 24),
            _buildPlayerStatsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Game Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _opponentController,
              decoration: const InputDecoration(
                labelText: 'Opponent',
                border: OutlineInputBorder(),
                hintText: 'e.g., Team A',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter opponent name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                hintText: 'e.g., Home Field',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter location';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Game Date'),
              subtitle: Text(
                '${_gameDate.day}/${_gameDate.month}/${_gameDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _gameDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _gameDate = date;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _gameType,
                    decoration: const InputDecoration(
                      labelText: 'Game Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'regular', child: Text('Regular')),
                      DropdownMenuItem(value: 'playoff', child: Text('Playoff')),
                      DropdownMenuItem(value: 'practice', child: Text('Practice')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _gameType = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _gameStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _gameStatus = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Player Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_roster.isEmpty)
              const Text('No players in roster')
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Player')),
                    DataColumn(label: Text('AB')),
                    DataColumn(label: Text('R')),
                    DataColumn(label: Text('H')),
                    DataColumn(label: Text('2B')),
                    DataColumn(label: Text('3B')),
                    DataColumn(label: Text('HR')),
                    DataColumn(label: Text('BB')),
                    DataColumn(label: Text('HBP')),
                    DataColumn(label: Text('K')),
                    DataColumn(label: Text('IP')),
                    DataColumn(label: Text('ER')),
                    DataColumn(label: Text('Pitches')),
                  ],
                  rows: _roster.map((player) {
                    final stats = _playerStats[player.playerId] ?? const PlayerGameStats();
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            player.playerId,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(_buildStatInput(player.playerId, 'atBats', stats.atBats)),
                        DataCell(_buildStatInput(player.playerId, 'runs', stats.runs)),
                        DataCell(_buildStatInput(player.playerId, 'hits', stats.hits)),
                        DataCell(_buildStatInput(player.playerId, 'doubles', stats.doubles)),
                        DataCell(_buildStatInput(player.playerId, 'triples', stats.triples)),
                        DataCell(_buildStatInput(player.playerId, 'homeRuns', stats.homeRuns)),
                        DataCell(_buildStatInput(player.playerId, 'walks', stats.walks)),
                        DataCell(_buildStatInput(player.playerId, 'hitByPitch', stats.hitByPitch)),
                        DataCell(_buildStatInput(player.playerId, 'strikeouts', stats.strikeouts)),
                        DataCell(_buildStatInput(player.playerId, 'inningsPitched', stats.inningsPitched)),
                        DataCell(_buildStatInput(player.playerId, 'earnedRuns', stats.earnedRuns)),
                        DataCell(_buildStatInput(player.playerId, 'totalPitches', stats.totalPitches)),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatInput(String playerId, String statName, dynamic value) {
    return SizedBox(
      width: 60,
      child: TextFormField(
        initialValue: value.toString(),
        keyboardType: statName == 'inningsPitched' 
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        onChanged: (value) {
          if (value.trim().isEmpty) return;
          
          dynamic parsedValue;
          if (statName == 'inningsPitched') {
            parsedValue = double.tryParse(value.trim()) ?? 0.0;
          } else {
            parsedValue = int.tryParse(value.trim()) ?? 0;
          }
          
          _updatePlayerStat(playerId, statName, parsedValue);
        },
      ),
    );
  }
}