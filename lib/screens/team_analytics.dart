import 'package:flutter/material.dart';
// Removed unused Firestore import
import '../models/player_season_totals.dart';
import '../repos/stats_repo.dart';
import '../utils/friendly_error.dart';

class TeamAnalyticsScreen extends StatefulWidget {
  final String teamId;
  final String seasonId;
  final String teamName;

  const TeamAnalyticsScreen({
    super.key,
    required this.teamId,
    required this.seasonId,
    required this.teamName,
  });

  @override
  State<TeamAnalyticsScreen> createState() => _TeamAnalyticsScreenState();
}

class _TeamAnalyticsScreenState extends State<TeamAnalyticsScreen>
    with TickerProviderStateMixin {
  final StatsRepo _statsRepo = StatsRepo();
  late TabController _tabController;

  List<PlayerSeasonTotals> _playerStats = [];
  Map<String, dynamic> _teamTotals = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load team totals
      final teamTotals = await _statsRepo.getTeamSeasonTotals(widget.teamId, widget.seasonId);
      setState(() {
        _teamTotals = teamTotals;
      });

      // Load player stats
      final playerStatsStream = _statsRepo.streamAllPlayerSeasonTotals(widget.teamId, widget.seasonId);
      await for (final stats in playerStatsStream) {
        setState(() {
          _playerStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = friendlyError(e, "Couldn't load team analytics");
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.teamName} Analytics'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Team Stats'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboards'),
            Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
          ],
        ),
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
              onPressed: _loadAnalytics,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildTeamStatsTab(),
        _buildLeaderboardsTab(),
        _buildTrendsTab(),
      ],
    );
  }

  Widget _buildTeamStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTeamTotalsCard(),
          const SizedBox(height: 24),
          _buildPlayerStatsTable(),
        ],
      ),
    );
  }

  Widget _buildTeamTotalsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Team Totals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_teamTotals.isEmpty)
              const Text('No team data available')
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatCard('Games', _teamTotals['games']?.toString() ?? '0'),
                  _buildStatCard('At Bats', _teamTotals['atBats']?.toString() ?? '0'),
                  _buildStatCard('Hits', _teamTotals['hits']?.toString() ?? '0'),
                  _buildStatCard('Runs', _teamTotals['runs']?.toString() ?? '0'),
                  _buildStatCard('RBI', _teamTotals['rbi']?.toString() ?? '0'),
                  _buildStatCard('Home Runs', _teamTotals['homeRuns']?.toString() ?? '0'),
                  _buildStatCard('Walks', _teamTotals['walks']?.toString() ?? '0'),
                  _buildStatCard('Strikeouts', _teamTotals['strikeouts']?.toString() ?? '0'),
                  _buildStatCard('Batting Avg', _formatAverage(_teamTotals['battingAverage'])),
                  _buildStatCard('On Base %', _formatAverage(_teamTotals['onBasePercentage'])),
                  _buildStatCard('Slugging %', _formatAverage(_teamTotals['sluggingPercentage'])),
                  _buildStatCard('OPS', _formatAverage(_teamTotals['onBasePlusSlugging'])),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatAverage(dynamic value) {
    if (value == null) return '0.000';
    if (value is double) {
      return value.toStringAsFixed(3);
    }
    return '0.000';
  }

  Widget _buildPlayerStatsTable() {
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
            if (_playerStats.isEmpty)
              const Text('No player data available')
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Player')),
                    DataColumn(label: Text('G')),
                    DataColumn(label: Text('AB')),
                    DataColumn(label: Text('H')),
                    DataColumn(label: Text('R')),
                    DataColumn(label: Text('RBI')),
                    DataColumn(label: Text('HR')),
                    DataColumn(label: Text('BB')),
                    DataColumn(label: Text('K')),
                    DataColumn(label: Text('AVG')),
                    DataColumn(label: Text('OBP')),
                    DataColumn(label: Text('SLG')),
                    DataColumn(label: Text('OPS')),
                  ],
                  rows: _playerStats.map((player) {
                    return DataRow(
                      cells: [
                        DataCell(Text(player.playerId)),
                        DataCell(Text(player.games.toString())),
                        DataCell(Text(player.atBats.toString())),
                        DataCell(Text(player.hits.toString())),
                        DataCell(Text(player.runs.toString())),
                        DataCell(Text(player.rbi.toString())),
                        DataCell(Text(player.homeRuns.toString())),
                        DataCell(Text(player.walks.toString())),
                        DataCell(Text(player.strikeouts.toString())),
                        DataCell(Text(_formatAverage(_avg(player)))),
                        DataCell(Text(_formatAverage(_obp(player)))),
                        DataCell(Text(_formatAverage(_slg(player)))),
                        DataCell(Text(_formatAverage(_ops(player)))),
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

  Widget _buildLeaderboardsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLeaderboardCard('Hits', 'hits'),
          const SizedBox(height: 16),
          _buildLeaderboardCard('Home Runs', 'homeRuns'),
          const SizedBox(height: 16),
          _buildLeaderboardCard('RBI', 'rbi'),
          const SizedBox(height: 16),
          _buildLeaderboardCard('Batting Average', 'battingAverage'),
          const SizedBox(height: 16),
          _buildLeaderboardCard('OPS', 'onBasePlusSlugging'),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(String title, String statField) {
    // Sort players by the specified stat
    final sortedPlayers = List<PlayerSeasonTotals>.from(_playerStats);
    sortedPlayers.sort((a, b) {
      final aValue = _getStatValue(a, statField);
      final bValue = _getStatValue(b, statField);
      
      if (aValue is double && bValue is double) {
        return bValue.compareTo(aValue);
      } else if (aValue is int && bValue is int) {
        return bValue.compareTo(aValue);
      }
      return 0;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (sortedPlayers.isEmpty)
              const Text('No data available')
            else
              ...sortedPlayers.take(5).map((player) {
                final value = _getStatValue(player, statField);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[600],
                    child: Text(
                      '${sortedPlayers.indexOf(player) + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(player.playerId),
                  trailing: Text(
                    value is double ? value.toStringAsFixed(3) : value.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  dynamic _getStatValue(PlayerSeasonTotals player, String statField) {
    switch (statField) {
      case 'hits':
        return player.hits;
      case 'homeRuns':
        return player.homeRuns;
      case 'rbi':
        return player.rbi;
      case 'battingAverage':
        return _avg(player);
      case 'onBasePlusSlugging':
        return _ops(player);
      default:
        return 0;
    }
  }

  // Derived metrics computed client-side based on available totals
  double _avg(PlayerSeasonTotals p) {
    if (p.atBats <= 0) return 0.0;
    return p.hits / p.atBats;
  }

  double _obp(PlayerSeasonTotals p) {
    // Approximate OBP with hits+walks over AB+BB (no HBP/SF available in totals)
    final denom = p.atBats + p.walks;
    if (denom <= 0) return 0.0;
    return (p.hits + p.walks) / denom;
  }

  double _slg(PlayerSeasonTotals p) {
    // SLG requires singles/doubles/triples/HR. If not in totals, fallback to 0.
    return 0.0;
  }

  double _ops(PlayerSeasonTotals p) {
    return _obp(p) + _slg(p);
  }

  Widget _buildTrendsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Trends Coming Soon',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Charts and trend analysis will be available here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}