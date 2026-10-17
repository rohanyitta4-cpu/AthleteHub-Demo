import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_title_style.dart';
import 'theme/rank_accent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'simple_loading_screen.dart';
import 'firebase_stats_service.dart';
import 'player_stats.dart';
import 'utils/stat_key_map.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/season_stats_pipeline.dart';
import 'utils/friendly_error.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  /// Near-black cards (not Material blue-gray).
  static const _darkCard = Color(0xFF161618);
  static const _darkBorder = Color(0x14FFFFFF);

  Color? _accent(bool isDark) => RankAccent.instance.color(isDark);

  Widget _accentTitle(String title, double size, bool isDark) {
    final accent = _accent(isDark);
    final text = Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
    if (accent == null) return text;
    return Row(
      children: [
        Container(
          width: 3,
          height: size,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: text),
      ],
    );
  }

  final FirebaseStatsService _firebaseService = FirebaseStatsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<DocumentSnapshot> _seasons = [];
  DocumentSnapshot? _selectedSeason;
  List<DocumentSnapshot> _games = [];
  List<DocumentSnapshot> _filteredGames = [];
  bool _isLoading = true;
  String? _errorMessage;
  List<DocumentSnapshot> _activeSeasons = [];
  DocumentSnapshot? _selectedGame; // Track selected game for details view
  String _filterType = 'none'; // 'none', 'date', 'month', 'gameNumber', 'year'
  String? _filterValue;
  final String _sortType = 'date'; // 'date', 'year' - sort by date (newest first) or year
  PlayerStats? _seasonStats; // Aggregated stats for the selected season

  StreamSubscription<QuerySnapshot>? _gamesStreamSub;

  @override
  void dispose() {
    _gamesStreamSub?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      var seasons = await _firebaseService.getAllSeasons();
      if (seasons.isEmpty) {
        final user = _auth.currentUser;
        if (user != null) {
          await _firebaseService.createDefaultSeason();
          seasons = await _firebaseService.getAllSeasons();
        }
      }
      if (!mounted) return;

      setState(() {
        _seasons = seasons;
        _isLoading = false;
      });

      if (seasons.isNotEmpty) {
        DocumentSnapshot? activeSeason;
        _activeSeasons = [];
        for (final season in seasons) {
          final data = season.data() as Map<String, dynamic>?;
          if (data?['isActive'] == true) {
            _activeSeasons.add(season);
          }
          if ((data?['isActive'] == true) && activeSeason == null) {
            activeSeason = season;
          }
        }

        if (activeSeason != null) {
          await _selectSeason(activeSeason);
        } else {
          await _selectSeason(seasons.first);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = friendlyError(e, "Couldn't load your seasons");
        _isLoading = false;
      });
    }
  }

  Future<void> _selectSeason(DocumentSnapshot season) async {
    if (!mounted) return;

    await _gamesStreamSub?.cancel();
    _gamesStreamSub = null;

    setState(() {
      _selectedSeason = season;
      _isLoading = true;
      _selectedGame = null;
      _errorMessage = null;
    });

    try {
      final seasonId = season.id;

      final seasonData = season.data() as Map<String, dynamic>?;
      final isActive = seasonData?['isActive'] == true;

      if (isActive) {
        final user = _auth.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'currentActiveSeasonId': seasonId,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('currentActiveSeasonId', seasonId);
          } catch (_) {}
        }
      }

      if (!mounted) return;

      if (_auth.currentUser == null) {
        setState(() {
          _errorMessage = 'Not signed in';
          _isLoading = false;
        });
        return;
      }

      _gamesStreamSub = _firebaseService
          .watchSeasonGames(seasonId)
          .listen(
            (snapshot) {
              if (!mounted) return;
              final games = snapshot.docs;
              final aggregated = aggregatePlayerStatsFromGameDocuments(games);
              setState(() {
                _games = games;
                _seasonStats = aggregated;
                _applyFilter();
                _isLoading = false;
                _errorMessage = null;
              });
            },
            onError: (Object e) {
              if (!mounted) return;
              setState(() {
                _errorMessage = friendlyError(e, "Couldn't load your games");
                _isLoading = false;
              });
            },
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = friendlyError(e, "Couldn't load your seasons");
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Avoid Material surface pink tint on light B&W theme.
    final scaffoldColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        title: Text('Game History', style: appTitleStyle(color: isDark ? Colors.white : Colors.black)),
        backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: isDark ? Colors.white : Colors.black),
            onSelected: (value) {
              switch (value) {
                case 'new':
                  _createNewSeason();
                  break;
                case 'end':
                  _endSeasonFlow();
                  break;
                case 'delete':
                  _deleteSeasonFlow();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'new',
                child: Text('New Season', style: GoogleFonts.poppins()),
              ),
              PopupMenuItem(
                value: 'end',
                child: Text('End Season', style: GoogleFonts.poppins()),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete Season', style: GoogleFonts.poppins(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const SimpleLoadingScreen(title: 'Loading History...')
          : _errorMessage != null
          ? _buildErrorWidget()
          : _selectedGame != null
          ? _buildGameDetailsView()
          : _buildContent(),
    );
  }

  Widget _buildErrorWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Error',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red[400]),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: GoogleFonts.poppins(fontSize: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadSeasons,
            child: Text('Retry', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? _darkCard
        : (theme.scaffoldBackgroundColor == Colors.white
              ? Colors.grey.shade100
              : theme.colorScheme.surfaceContainerHighest);

    return Column(
      children: [
        if (_seasons.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? _darkBorder : Colors.grey[300]!, width: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<DocumentSnapshot>(
                        value: _selectedSeason,
                        isExpanded: true,
                        hint: Text(
                          'Select Season',
                          style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                        ),
                        items: _seasons.map((season) {
                          final data = season.data() as Map<String, dynamic>?;
                          final name = data?['name'] ?? 'Unknown Season';
                          final year = data?['year'] ?? '';
                          final displayName = year.isNotEmpty ? '$name $year' : name;

                          return DropdownMenuItem(
                            value: season,
                            child: Text(
                              displayName,
                              style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                            ),
                          );
                        }).toList(),
                        onChanged: (season) {
                          if (season != null) {
                            _selectSeason(season);
                          }
                        },
                        style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                        dropdownColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 56, // Match season dropdown height
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? _darkBorder : Colors.grey[300]!, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      _filterType != 'none' ? Icons.filter_alt : Icons.filter_alt_outlined,
                      color: _filterType != 'none'
                          ? (_accent(isDark) ?? Theme.of(context).colorScheme.primary)
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    tooltip: 'Filter Games',
                    onSelected: (value) {
                      if (value == 'clear') {
                        setState(() {
                          _filterType = 'none';
                          _filterValue = null;
                          _applyFilter();
                        });
                      } else {
                        setState(() {
                          _filterType = value;
                          _filterValue = null;
                          _applyFilter();
                        });
                        if (value != 'none') {
                          _showFilterDialog(value);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'none',
                        child: Row(
                          children: [
                            Icon(
                              Icons.clear_all,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            const SizedBox(width: 12),
                            Text('No Filter', style: GoogleFonts.poppins()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'month',
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            const SizedBox(width: 12),
                            Text('By Month', style: GoogleFonts.poppins()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'date',
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            const SizedBox(width: 12),
                            Text('By Date', style: GoogleFonts.poppins()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'gameNumber',
                        child: Row(
                          children: [
                            Icon(
                              Icons.numbers,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            const SizedBox(width: 12),
                            Text('By Game Number', style: GoogleFonts.poppins()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'year',
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            const SizedBox(width: 12),
                            Text('By Year', style: GoogleFonts.poppins()),
                          ],
                        ),
                      ),
                      if (_filterType != 'none') ...[
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              const Icon(Icons.clear, size: 20, color: Colors.red),
                              const SizedBox(width: 12),
                              Text('Clear Filter', style: GoogleFonts.poppins(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        if (_seasonStats != null && _selectedSeason != null) ...[
          _buildSeasonStatsSummary(),
          const SizedBox(height: 16),
        ],

        Expanded(
          child: _filteredGames.isEmpty && _games.isNotEmpty
              ? _buildNoFilterResultsWidget()
              : _filteredGames.isEmpty
              ? _buildEmptyGamesWidget()
              : _buildAnimatedGamesList(),
        ),
      ],
    );
  }

  Widget _buildSeasonStatsSummary() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stats = _seasonStats!;
    final accent = _accent(isDark);
    final cardColor = isDark
        ? _darkCard
        : (theme.scaffoldBackgroundColor == Colors.white ? Colors.white : theme.colorScheme.surfaceContainerHighest);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        gradient: accent == null
            ? null
            : RadialGradient(
                center: const Alignment(1.1, -1.3),
                radius: 1.2,
                colors: [
                  accent.withValues(alpha: isDark ? 0.07 : 0.04),
                  cardColor,
                ],
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent?.withValues(alpha: 0.18) ?? (isDark ? _darkBorder : Colors.grey[300]!),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.15 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _accentTitle('Season Totals', 18, isDark),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatItem('Games', _games.length.toString())),
              Expanded(child: _buildStatItem('At Bats', stats.atBats.toString())),
              Expanded(child: _buildStatItem('Hits', stats.hits.toString())),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatItem('Runs', stats.runs.toString())),
              Expanded(child: _buildStatItem('HR', stats.homeRuns.toString())),
              Expanded(child: _buildStatItem('RBI', stats.runsBattedIn.toString())),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatItem('AVG', stats.battingAverage.toStringAsFixed(3), highlight: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {bool highlight = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = highlight ? _accent(isDark) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: accent ?? (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedGamesList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? theme.colorScheme.surface
        : (theme.scaffoldBackgroundColor == Colors.white ? Colors.grey.shade50 : theme.colorScheme.surface);
    const itemHeight = 72.0; // Height of each game item
    const maxVisibleItems = 8.0;
    const maxHeight = itemHeight * maxVisibleItems;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: maxHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: surfaceColor,
        border: Border.all(color: isDark ? _darkBorder : Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filteredGames.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final game = _filteredGames[index];
                final data = game.data() as Map<String, dynamic>?;
                if (data == null) return const SizedBox.shrink();
                final date = data['date'] as Timestamp?;
                if (date == null) return const SizedBox.shrink();

                return _buildSwipeableGameItem(game, date, index);
              },
            ),
            // Fade so list doesn't collide with the floating nav.
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [surfaceColor.withOpacity(0.0), surfaceColor],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeableGameItem(DocumentSnapshot game, Timestamp date, int index) {
    return Dismissible(
      key: Key(game.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_forever, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(
                  'Delete Game',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.red),
                ),
                content: Text(
                  'Are you sure you want to delete this game? This will permanently remove it from all data, graphs, and history.',
                  style: GoogleFonts.poppins(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel', style: GoogleFonts.poppins()),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) async {
        await _deleteGame(game);
      },
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 300 + (index * 30)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(offset: Offset(0, 15 * (1 - value)), child: _buildGameDateItem(game, date)),
          );
        },
      ),
    );
  }

  Widget _buildGameDateItem(DocumentSnapshot game, Timestamp date) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final itemColor = isDark
        ? _darkCard
        : (theme.scaffoldBackgroundColor == Colors.white ? Colors.white : theme.colorScheme.surfaceContainerHighest);
    final formattedDate = DateFormat('MMM dd, yyyy').format(date.toDate());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: itemColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? _darkBorder : Colors.grey[200]!, width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.15 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _selectedGame = game;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    formattedDate,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        _accent(isDark)?.withValues(alpha: isDark ? 0.10 : 0.07) ?? theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'View Stats',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _accent(isDark) ?? theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameDetailsView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = _selectedGame!.data() as Map<String, dynamic>?;
    if (data == null) {
      return _buildContent();
    }

    final date = data['date'] as Timestamp?;
    if (date == null) {
      return _buildContent();
    }

    final stats = playerStatsFromFirestoreGame(data);

    final formattedDate = DateFormat('EEEE, MMMM dd, yyyy').format(date.toDate());

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111111) : Colors.white,
            border: Border(bottom: BorderSide(color: isDark ? _darkBorder : Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
                onPressed: () {
                  setState(() {
                    _selectedGame = null;
                  });
                },
              ),
              Expanded(
                child: Text(
                  formattedDate,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsSection('Batting Stats', [
                  _buildStatRow('At Bats', stats.atBats.toString()),
                  _buildStatRow('Hits', stats.hits.toString()),
                  _buildStatRow('Runs', stats.runs.toString()),
                  _buildStatRow('Doubles', stats.doubles.toString()),
                  _buildStatRow('Triples', stats.triples.toString()),
                  _buildStatRow('Home Runs', stats.homeRuns.toString()),
                  _buildStatRow('Runs Batted In', stats.runsBattedIn.toString()),
                  _buildStatRow('Walks', stats.walks.toString()),
                  _buildStatRow('Intentional Walks', stats.intentionalWalks.toString()),
                  _buildStatRow('Strikeouts', stats.strikeouts.toString()),
                  _buildStatRow('Hit By Pitch', stats.hitByPitch.toString()),
                  _buildStatRow('Sacrifice Bunts', stats.sacrificeHits.toString()),
                  _buildStatRow('Sacrifice Flies', stats.sacrificeFlies.toString()),
                  _buildStatRow('Stolen Bases', stats.stolenBases.toString()),
                  if (stats.tracksHardHit) ...[
                    _buildStatRow('Hard-Hit Balls', stats.hardHitBalls.toString()),
                    _buildStatRow('Hard-Hit Rate', formatStatValue('hardHitRate', stats.hardHitRate)),
                  ],
                  if (stats.tracksQualityAtBats) ...[
                    _buildStatRow('Quality At-Bats', stats.qualityAtBats.toString()),
                    _buildStatRow('Quality At-Bat Rate', formatStatValue('qualityAtBatRate', stats.qualityAtBatRate)),
                  ],
                  _buildStatRow('Batting Average', stats.battingAverage.toStringAsFixed(3), highlight: true),
                  _buildStatRow('On-Base Percentage', stats.onBasePercentage.toStringAsFixed(3), highlight: true),
                  _buildStatRow('Slugging Percentage', stats.sluggingPercentage.toStringAsFixed(3), highlight: true),
                  _buildStatRow('On-Base Plus Slugging', stats.onBasePlusSlugging.toStringAsFixed(3), highlight: true),
                  _buildStatRow('Isolated Power', stats.isolatedPower.toStringAsFixed(3)),
                  _buildStatRow('Runs Created', stats.runsCreated.toStringAsFixed(2)),
                  _buildStatRow('Two Strike Counts', stats.twoStrikeCounts.toString()),
                  _buildStatRow('Two Strike Success Rate', stats.twoStrikeSuccessRate.toStringAsFixed(3)),
                ]),

                const SizedBox(height: 24),

                if (stats.inningsPitched > 0 || stats.earnedRuns > 0 || stats.totalPitches > 0)
                  _buildStatsSection('Pitching Stats', [
                    _buildStatRow('Innings Pitched', stats.inningsPitched.toStringAsFixed(1)),
                    _buildStatRow('Earned Runs', stats.earnedRuns.toString()),
                    _buildStatRow('Total Pitches', stats.totalPitches.toString()),
                    _buildStatRow('ERA', stats.earnedRunAverage.toStringAsFixed(2)),
                    _buildStatRow('Strikeout Rate', stats.strikeoutRate.toStringAsFixed(3)),
                    _buildStatRow('WHIP', stats.walksHitsPerInningPitched.toStringAsFixed(3)),
                  ]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(String title, List<Widget> statRows) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _accentTitle(title, 18, isDark),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? _darkCard : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? _darkBorder : Colors.grey[300]!),
          ),
          child: Column(children: statRows),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, {bool highlight = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = highlight ? _accent(isDark) : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? _darkBorder : Colors.grey[300]!, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 15, color: isDark ? Colors.grey[300] : Colors.grey[700])),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: accent ?? (isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGamesWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No Games Yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your performance by entering game stats',
            style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.grey[500] : Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _createNewSeason() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final nameController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Season', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Season Name'),
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Create', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
    if (confirmed != true || nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final seasonsRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('seasons');

      final activeSeasonsQuery = await seasonsRef.where('isActive', isEqualTo: true).get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in activeSeasonsQuery.docs) {
        batch.update(doc.reference, {'isActive': false, 'endDate': FieldValue.serverTimestamp()});
      }
      await batch.commit();

      final currentYear = DateTime.now().year.toString();
      final newSeasonRef = await seasonsRef.add({
        'name': nameController.text.trim(),
        'year': currentYear,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'startDate': FieldValue.serverTimestamp(),
        'overallStats': PlayerStats().toJson(),
      });

      // Point the user at this season so new games land here.
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'currentActiveSeasonId': newSeasonRef.id,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Local cache so reopen lands on the same season.
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('currentActiveSeasonId', newSeasonRef.id);
      } catch (_) {}

      await _loadSeasons();
      try {
        await _firebaseService.forceStreamRefresh(user.uid);
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New season "${nameController.text.trim()}" created successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = friendlyError(e, "Couldn't create the season"));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e, "Couldn't create the season")),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _endSeasonFlow() async {
    if (_activeSeasons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active seasons to end')));
      return;
    }

    final picked = await showDialog<DocumentSnapshot?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'End Season',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.red),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Pick an active season to end.', style: GoogleFonts.poppins(fontSize: 14)),
                const SizedBox(height: 12),
                ..._activeSeasons.map((s) {
                  final data = s.data() as Map<String, dynamic>?;
                  final name = data?['name'] ?? 'Season';
                  return ListTile(
                    title: Text(name, style: GoogleFonts.poppins()),
                    onTap: () => Navigator.pop(context, s),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
    if (picked == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm End Season',
          style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w700),
        ),
        content: Text('Are you sure you want to end this season?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes, End', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final user = _auth.currentUser;
    if (user == null) return;
    await picked.reference.update({'isActive': false, 'endedAt': FieldValue.serverTimestamp()});
    try {
      await _firebaseService.forceStreamRefresh(user.uid);
    } catch (_) {}

    // If the open season ended, switch to another active one.
    if (_selectedSeason?.id == picked.id && _activeSeasons.length > 1) {
      final next = _activeSeasons.firstWhere((s) => s.id != picked.id, orElse: () => _seasons.first);
      await _selectSeason(next);
    }
    await _loadSeasons();
  }

  Future<void> _deleteSeasonFlow() async {
    if (_selectedSeason == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Season',
          style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will permanently remove the season and all its games. Continue?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final seasonId = _selectedSeason!.id;
      final seasonData = _selectedSeason!.data() as Map<String, dynamic>?;
      final wasActive = seasonData?['isActive'] == true;

      final gamesSnap = await _selectedSeason!.reference.collection('games').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final gameDoc in gamesSnap.docs) {
        batch.delete(gameDoc.reference);
      }
      await batch.commit();

      await _selectedSeason!.reference.delete();

      // If this was active, reassign currentActiveSeasonId.
      if (wasActive) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final currentActiveId = userDoc.data()?['currentActiveSeasonId'] as String?;

        if (currentActiveId == seasonId) {
          final allSeasons = await _firebaseService.getAllSeasons();
          DocumentSnapshot? newActiveSeason;

          for (final season in allSeasons) {
            final data = season.data() as Map<String, dynamic>?;
            if (data?['isActive'] == true && season.id != seasonId) {
              newActiveSeason = season;
              break;
            }
          }

          // Prefer another active season; else most recent.
          if (newActiveSeason == null && allSeasons.isNotEmpty) {
            newActiveSeason = allSeasons.first;
            await newActiveSeason.reference.update({'isActive': true});
          }

          if (newActiveSeason != null) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'currentActiveSeasonId': newActiveSeason.id,
              'lastUpdated': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('currentActiveSeasonId', newActiveSeason.id);
            } catch (_) {}
          } else {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'currentActiveSeasonId': FieldValue.delete(),
              'lastUpdated': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('currentActiveSeasonId');
            } catch (_) {}
          }
        }
      }

      try {
        await _firebaseService.forceStreamRefresh(user.uid);
      } catch (_) {}

      await _loadSeasons();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = friendlyError(e, "Couldn't delete the season"));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e, "Couldn't delete the season")), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    List<DocumentSnapshot> gamesToProcess = List.from(_games);

    if (_filterType != 'none' && _filterValue != null) {
      List<DocumentSnapshot> filtered = [];

      for (final game in _games) {
        final data = game.data() as Map<String, dynamic>?;
        final date = data?['date'] as Timestamp?;
        if (date == null) continue;

        final gameDate = date.toDate();
        bool include = false;

        switch (_filterType) {
          case 'month':
            final filterMonth = _filterValue!;
            final gameMonth = '${gameDate.year}-${gameDate.month.toString().padLeft(2, '0')}';
            include = gameMonth == filterMonth;
            break;

          case 'date':
            final filterDateStr = _filterValue!;
            final gameDateStr =
                '${gameDate.year}-${gameDate.month.toString().padLeft(2, '0')}-${gameDate.day.toString().padLeft(2, '0')}';
            include = gameDateStr == filterDateStr;
            break;

          case 'gameNumber':
            final targetNumber = int.tryParse(_filterValue ?? '') ?? 0;
            final gameIndex = _games.indexOf(game) + 1;
            include = gameIndex == targetNumber;
            break;

          case 'year':
            final filterYear = _filterValue!;
            include = gameDate.year.toString() == filterYear;
            break;
        }

        if (include) {
          filtered.add(game);
        }
      }

      gamesToProcess = filtered;
    }

    // Apply sorting
    gamesToProcess.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>?;
      final bData = b.data() as Map<String, dynamic>?;
      final aDate = aData?['date'] as Timestamp?;
      final bDate = bData?['date'] as Timestamp?;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      final aDateTime = aDate.toDate();
      final bDateTime = bDate.toDate();

      if (_sortType == 'year') {
        // Sort by year (newest first), then by date within year
        final yearCompare = bDateTime.year.compareTo(aDateTime.year);
        if (yearCompare != 0) return yearCompare;
        return bDateTime.compareTo(aDateTime);
      } else {
        // Sort by date (newest first)
        return bDateTime.compareTo(aDateTime);
      }
    });

    setState(() {
      _filteredGames = gamesToProcess;
    });
  }

  Future<void> _showFilterDialog(String filterType) async {
    final theme = Theme.of(context);

    if (filterType == 'month') {
      final now = DateTime.now();
      // First show month selector
      final selectedMonth = await showDialog<int>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Select Month', style: GoogleFonts.poppins()),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(12, (index) {
                final monthNum = index + 1;
                final monthName = DateFormat('MMMM').format(DateTime(now.year, monthNum));
                return ListTile(
                  title: Text(monthName, style: GoogleFonts.poppins()),
                  onTap: () => Navigator.pop(context, monthNum),
                );
              }),
            ),
          ),
        ),
      );

      if (selectedMonth != null && mounted) {
        // Then show year selector
        final selectedYear = await showDialog<int>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Select Year', style: GoogleFonts.poppins()),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (yearOffset) {
                  final year = now.year - yearOffset;
                  return ListTile(
                    title: Text('$year', style: GoogleFonts.poppins()),
                    onTap: () => Navigator.pop(context, year),
                  );
                }),
              ),
            ),
          ),
        );

        if (selectedYear != null && mounted) {
          setState(() {
            _filterValue = '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}';
            _applyFilter();
          });
        }
      }
    } else if (filterType == 'year') {
      final now = DateTime.now();
      final selectedYear = await showDialog<int>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Select Year', style: GoogleFonts.poppins()),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (yearOffset) {
                final year = now.year - yearOffset;
                return ListTile(
                  title: Text('$year', style: GoogleFonts.poppins()),
                  onTap: () => Navigator.pop(context, year),
                );
              }),
            ),
          ),
        ),
      );
      if (selectedYear != null && mounted) {
        setState(() {
          _filterValue = selectedYear.toString();
          _applyFilter();
        });
      }
    } else if (filterType == 'date') {
      final selectedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (selectedDate != null && mounted) {
        setState(() {
          _filterValue =
              '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
          _applyFilter();
        });
      }
    } else if (filterType == 'gameNumber') {
      final controller = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Enter Game Number', style: GoogleFonts.poppins()),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Game Number (1-${_games.length})',
              hintText: 'Enter a number between 1 and ${_games.length}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text('Filter', style: GoogleFonts.poppins(color: theme.colorScheme.primary)),
            ),
          ],
        ),
      );
      if (result != null && result.isNotEmpty && mounted) {
        final gameNum = int.tryParse(result);
        if (gameNum != null && gameNum >= 1 && gameNum <= _games.length) {
          setState(() {
            _filterValue = result;
            _applyFilter();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please enter a number between 1 and ${_games.length}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildNoFilterResultsWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No Games Match Filter',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filter criteria',
            style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.grey[500] : Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGame(DocumentSnapshot game) async {
    if (_selectedSeason == null) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final seasonId = _selectedSeason!.id;
      final gameId = game.id;

      // Delete from season's games collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('seasons')
          .doc(seasonId)
          .collection('games')
          .doc(gameId)
          .delete();

      // Also delete from main games collection if it exists there
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('games').doc(gameId).delete();
      } catch (_) {
        // Game might not exist in main collection, that's okay
      }

      // Recalculate season stats after deletion (same pipeline as dashboard)
      final games = await _firebaseService.getSeasonGames(seasonId);
      final aggregatedStats = aggregatePlayerStatsFromGameDocuments(games);

      // Update season's overallStats
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('seasons').doc(seasonId).update({
        'overallStats': aggregatedStats.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Live games stream updates the list; still notify listeners.

      // Notify other screens to refresh (dashboard, stats screen)
      await _firebaseService.forceStreamRefresh(user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Game deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e, "Couldn't delete the game")),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
