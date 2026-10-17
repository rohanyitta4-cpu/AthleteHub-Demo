import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import '../firebase_stats_service.dart';
import '../simple_loading_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/stat_hero_section.dart';
import '../widgets/ai_analysis_button.dart';
import '../widgets/stat_metrics_grid.dart';
import '../utils/insight_generator_helper.dart';
import '../widgets/stat_comparison_section.dart';
import '../widgets/stat_game_log.dart';
import '../widgets/advanced_chart_container.dart';
import '../widgets/stat_skill_profile_card.dart';
import '../widgets/stat_picker_bottom_sheet.dart';
import '../services/ai_stat_analyzer_service.dart';
import '../utils/chart_data_preparer.dart';
import '../utils/season_stats_pipeline.dart';
import '../theme/app_title_style.dart';
import '../utils/friendly_error.dart';

class EnhancedStatsScreen extends StatefulWidget {
  const EnhancedStatsScreen({super.key});

  // Static method to refresh stats from other screens
  static void refreshStats(BuildContext context) {
    final state = context.findAncestorStateOfType<_EnhancedStatsScreenState>();
    state?.refreshData();
  }

  @override
  State<EnhancedStatsScreen> createState() => _EnhancedStatsScreenState();
}

class _EnhancedStatsScreenState extends State<EnhancedStatsScreen> {
  // Global switch to enable/disable AI Insights end-to-end.
  // When false, no background generation runs and the AIInsightsCard is hidden.
  static const bool _enableAiInsights = true;
  // ✅ FIX #1: Make services lazy to prevent early Firebase initialization
  FirebaseStatsService? _firebaseService;
  AIStatAnalyzerService? _aiService;
  bool _servicesInitialized = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _gamesSubscription;
  StreamSubscription<String?>? _seasonSubscription;
  StreamSubscription<DocumentSnapshot>? _userProSubscription;
  List<Map<String, dynamic>> _gameData = [];
  bool _isProMode = false;
  
  // State
  bool isLoading = true;
  String? errorMessage;
  String? _cachedSeasonId;
  bool _isInitialLoad = true;

  // Current selected stat index
  int _currentStatIndex = 0;

  // Available stats (same as original)
  final List<String> statOptions = [
    'Batting Average',
    'On-Base Percentage',
    'Slugging Percentage',
    'On-Base Plus Slugging',
    'Isolated Power',
    'Runs Created',
    'Hard-Hit Rate',
    'Quality At-Bat Rate',
    'Earned Run Average',
    'Strikeout Rate',
    'Walks + Hits per Inning Pitched',
    'WAR',
    'ERA',
    'Strikeouts',
    'Pitches Thrown',
    'At Bats',
    'Runs',
    'Hits',
    'Doubles',
    'Triples',
    'Home Runs',
    'Walks',
    'Intentional Walks',
    'Hit By Pitch',
    'Sacrifice Bunts',
    'Sacrifice Flies',
    'Stolen Bases',
    'Runs Batted In',
    'Two Strike Counts',
    'Two Strike Success Rate',
    'Hard-Hit Balls',
    'Quality At-Bats',
    'Innings Pitched',
    'Earned Runs',
  ];

  @override
  void initState() {
    super.initState();
    
    // ✅ FIX #1: Defer service initialization to after first frame
    // This prevents Firebase/Cloud Functions from initializing before the engine is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      try {
        // ✅ Initialize services lazily here, not as instance fields
        _firebaseService = FirebaseStatsService();
        _aiService = AIStatAnalyzerService();
        _servicesInitialized = true;
        
        // Check if user is authenticated before initializing
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          if (mounted) {
            setState(() {
              errorMessage = 'User not authenticated';
              isLoading = false;
            });
          }
          return;
        }
        
        _loadLastViewedStat();
        _startSeasonListener();
        _startProListener();
        _checkForNewData();
      } catch (e, stackTrace) {
        print('Error in EnhancedStatsScreen initState: $e');
        print('Stack trace: $stackTrace');
        if (mounted) {
          setState(() {
            errorMessage = friendlyError(e, "Couldn't load your stats");
            isLoading = false;
          });
        }
      }
    });
  }

  Future<void> _loadLastViewedStat() async {
    try {
      // Load from shared preferences and jump to saved page
      final prefs = await SharedPreferences.getInstance();
      final lastStat = prefs.getString('lastViewedStat');
      if (lastStat != null && statOptions.contains(lastStat)) {
        final savedIndex = statOptions.indexOf(lastStat);
        if (savedIndex >= 0 && savedIndex < statOptions.length && mounted) {
          setState(() {
            _currentStatIndex = savedIndex;
          });
        }
      }
    } catch (e) {
      print('Error loading last viewed stat: $e');
      // Don't crash on error, just use default index 0
    }
  }

  Future<void> _saveLastViewedStat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastViewedStat', statOptions[_currentStatIndex]);
  }

  void _startGamesStream() {
    if (_gamesSubscription != null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _loadGamesFromActiveSeason();
  }

  Future<void> _loadGamesFromActiveSeason() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _firebaseService == null) return;

      var season = await _firebaseService!.getActiveSeason();
      if (season == null) {
        await _firebaseService!.createDefaultSeason();
        season = await _firebaseService!.getActiveSeason();
      }
      if (season == null) {
        if (mounted) {
          setState(() {
            errorMessage = 'Could not create or load a season. Pull to refresh.';
            isLoading = false;
          });
        }
        return;
      }

      _gamesSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('seasons')
          .doc(season.id)
          .collection('games')
          .orderBy('date', descending: false)
          .snapshots()
          .listen(
        (QuerySnapshot snapshot) {
          if (mounted) {
            final newGameData = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id,
                'date': data['date'] != null ? (data['date'] as Timestamp).toDate() : null,
                'stats': playerStatsFromFirestoreGame(data),
              };
            }).toList();
            
            setState(() {
              _gameData = newGameData;
              isLoading = false;
              errorMessage = null;
              _isInitialLoad = false;
            });
            
            // Generate insights for existing games (one-time, in background)
            if (_enableAiInsights && newGameData.isNotEmpty && _servicesInitialized) {
              _generateInsightsForExistingGames(newGameData);
            }
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              errorMessage = friendlyError(error, "Couldn't load your games");
              isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = friendlyError(e, "Couldn't load your season");
          isLoading = false;
        });
      }
    }
  }

  void _checkForNewData() {
    if (_isInitialLoad) {
      _startGamesStream();
    }
  }

  void refreshData() {
    _disposeStream();
    _isInitialLoad = true;
    _startGamesStream();
  }

  void _disposeStream() {
    _gamesSubscription?.cancel();
    _gamesSubscription = null;
  }

  // Static flag to prevent multiple simultaneous insight generation calls
  static bool _isGeneratingInsights = false;

  /// Generate insights for existing games (one-time background process)
  /// Only runs if no insights exist yet
  void _generateInsightsForExistingGames(List<Map<String, dynamic>> gameData) async {
    // Prevent multiple simultaneous calls
    if (_isGeneratingInsights) {
      print('ℹ️ [EnhancedStats] Insight generation already in progress, skipping');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !_servicesInitialized) return;

    try {
      // Check if insights already exist (with timeout to prevent hanging)
      final insightsRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('statInsights')
          .limit(1);
      
      final insightsSnapshot = await insightsRef.get().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ [EnhancedStats] Timeout checking for existing insights');
          return insightsRef.get();
        },
      );
      
      // If insights already exist, don't regenerate
      if (insightsSnapshot.docs.isNotEmpty) {
        print('ℹ️ [EnhancedStats] Insights already exist, skipping generation');
        return;
      }

      print('🔄 [EnhancedStats] No insights found. Will generate insights in background (delayed)...');
      
      // Mark as generating to prevent multiple calls
      _isGeneratingInsights = true;
      
      // Generate insights in background with LONG delay to ensure Firebase is completely ready
      // This runs asynchronously and won't block the UI
      Future.delayed(const Duration(seconds: 10), () async {
        try {
          if (!mounted) {
            _isGeneratingInsights = false;
            return;
          }

          print('🔄 [EnhancedStats] Starting insight generation...');
          final success = await InsightGeneratorHelper.generateInsightsForAllStats(gameData).timeout(
            const Duration(minutes: 2), // Long timeout for all stats
          );
          
          _isGeneratingInsights = false;
          
          if (success && mounted) {
            print('✅ [EnhancedStats] Insights generation completed');
            // Trigger a rebuild to show new insights
            setState(() {});
          }
        } catch (e) {
          _isGeneratingInsights = false;
          print('❌ [EnhancedStats] Error generating insights: $e');
          // Don't crash - just log the error
        }
      });
    } catch (e) {
      _isGeneratingInsights = false;
      print('❌ [EnhancedStats] Error checking for existing insights: $e');
      // Don't crash - just log the error
    }
  }

  void _startProListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _userProSubscription?.cancel();
    _userProSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snap) {
      final pro = (snap.data()?['isProMode'] as bool?) ?? false;
      if (mounted) setState(() => _isProMode = pro);
    });
  }

  void _startSeasonListener() {
    try {
      // Check if already subscribed
      if (_seasonSubscription != null) return;
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            errorMessage = 'User not authenticated';
            isLoading = false;
          });
        }
        return;
      }
      
      if (_firebaseService == null) return;
      
      _seasonSubscription = _firebaseService!.watchCurrentActiveSeasonId().listen(
        (String? seasonId) {
          if (!mounted) return;
          
          if (seasonId != null && seasonId != _cachedSeasonId) {
            _disposeStream();
            if (mounted) {
              setState(() {
                _gameData = [];
                isLoading = true;
                errorMessage = null;
              });
            }
            _cachedSeasonId = seasonId;
            _startGamesStream();
          }
        },
        onError: (error) {
          print('Error in season listener: $error');
          if (mounted) {
            setState(() {
              errorMessage = friendlyError(error, "Couldn't load your season");
              isLoading = false;
            });
          }
        },
      );
    } catch (e, stackTrace) {
      print('Error starting season listener: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          errorMessage = friendlyError(e, "Couldn't load your stats");
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _disposeStream();
    _seasonSubscription?.cancel();
    _userProSubscription?.cancel();
    super.dispose();
  }


  void _showStatPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatPickerBottomSheet(
        availableStats: statOptions,
        selectedStat: getCurrentStatName(),
        onStatSelected: (stat) {
          final index = statOptions.indexOf(stat);
          if (index >= 0 && index != _currentStatIndex) {
            setState(() {
              _currentStatIndex = index;
            });
            _saveLastViewedStat();
          }
        },
      ),
    );
  }

  String getCurrentStatName() {
    if (_currentStatIndex < 0 || _currentStatIndex >= statOptions.length) {
      return statOptions[0];
    }
    return statOptions[_currentStatIndex];
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX #4: Guard against building widgets before services are initialized
    if (!_servicesInitialized || _firebaseService == null || _aiService == null) {
      return const SimpleLoadingScreen(title: 'Loading Stats...');
    }
    
    // ✅ FIX #5: Wrap entire build in try-catch to prevent native crashes from propagating
    try {
      return _buildScreenContent(context);
    } catch (e, stackTrace) {
      print('❌ CRITICAL: Error in EnhancedStatsScreen build: $e');
      print('Stack trace: $stackTrace');
      return Scaffold(
        appBar: AppBar(
          title: const Text('Statistics'),
          backgroundColor: const Color(0xFF1a1a1a),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                "Couldn't load your stats",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Tap Retry. If it keeps happening, close and reopen the app.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Try to rebuild
                  if (mounted) setState(() {});
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildScreenContent(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const SimpleLoadingScreen(title: 'Loading Stats...');
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Statistics',
            style: appTitleStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1a1a1a),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Error Loading Stats',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: refreshData,
                child: Text('Retry', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    // Full stats screen with PageView - Enhanced Design
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        // Floating hamburger sits top-left — leave room so title does not overlap it.
        leadingWidth: 72,
        leading: const SizedBox.shrink(),
        titleSpacing: 0,
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1A1C1F) : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Statistics',
          style: appTitleStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _showStatPicker,
              icon: Icon(
                Icons.tune,
                color: isDark ? Colors.white : Colors.black87,
              ),
              tooltip: 'Select Stat',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          refreshData();
        },
        color: theme.colorScheme.primary,
        child: Column(
          children: [
            // Stat detail page (no swiping)
            Expanded(
              child: _buildStatDetailPage(getCurrentStatName(), theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDetailPage(String statName, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    // Optional stats only use the games where they were logged.
    final games = ChartDataPreparer.gamesWithStat(statName, _gameData);
    final notTrackedYet = _gameData.isNotEmpty && games.isEmpty;

    if (games.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0A0A0A),
                    const Color(0xFF111214),
                  ]
                : [
                    const Color(0xFFF5F7FA),
                    Colors.white,
                  ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bar_chart,
                  size: 64,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                notTrackedYet ? 'Not tracked yet' : 'No data available',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  notTrackedYet
                      ? '$statName is optional. Fill it in on your next game entry and it will show up here.'
                      : 'Log a game from the + tab first. Your stats will show here after you have at least one game.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    try {
      // Enhanced stat detail page with better layout
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0A0A0A),
                    const Color(0xFF111214),
                  ]
                : [
                    const Color(0xFFF5F7FA),
                    Colors.white,
                  ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // 1. Hero card — compact: stat + big number + delta + 3 chips
              Builder(
                builder: (context) {
                  try {
                    return StatHeroSection(
                      statName: statName,
                      gameData: games,
                    );
                  } catch (e) {
                    print('Error building StatHeroSection: $e');
                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: Text("This section couldn't load right now."),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              // Scout analysis sits right under the hero card.
              if (!_enableAiInsights)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 22,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI stat insights',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'We are finishing the analysis pipeline after the first App Store release. '
                                  'This section will unlock in a follow-up update.',
                                  style: GoogleFonts.inter(fontSize: 13, height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_enableAiInsights && _gameData.isNotEmpty)
                AIAnalysisButton(
                  statName: statName,
                  gameData: _gameData,
                ),
              if (!_enableAiInsights || _gameData.isNotEmpty)
                const SizedBox(height: 16),
              // 2. Performance card — PERFORMANCE label + L10/L25/Season + chart-type pill + chart
              Builder(
                builder: (context) {
                  try {
                    return AdvancedChartContainer(
                      statName: statName,
                      gameData: games,
                      isPro: _isProMode,
                    );
                  } catch (e) {
                    print('Error building AdvancedChartContainer: $e');
                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: Text("This chart couldn't load right now."),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              // 3. Skill profile radar, with the Form section explaining each axis.
              StatSkillProfileCard(statName: statName, gameData: games),
              const SizedBox(height: 16),
              // 4. Game log — fixed-height card that scrolls internally.
              Builder(
                builder: (context) {
                  try {
                    return StatGameLog(
                      statName: statName,
                      gameData: games,
                    );
                  } catch (e) {
                    print('Error building StatGameLog: $e');
                    return const SizedBox.shrink();
                  }
                },
              ),
              const SizedBox(height: 16),
              // 5. Detailed stats — opens as a popout sheet instead of lengthening the page.
              _DetailedStatsCard(
                statName: statName,
                isDark: isDark,
                buildMetricsGrid: () {
                  try {
                    return StatMetricsGrid(
                      statName: statName,
                      gameData: games,
                    );
                  } catch (e) {
                    print('Error building StatMetricsGrid: $e');
                    return const SizedBox.shrink();
                  }
                },
                buildComparison: () {
                  try {
                    return StatComparisonSection(
                      statName: statName,
                      gameData: games,
                    );
                  } catch (e) {
                    print('Error building StatComparisonSection: $e');
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        ),
        ),
      );
    } catch (e) {
      print('Error building stat detail page for $statName: $e');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                "Couldn't load $statName",
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Try another stat, or close and reopen the app.',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }
}

/// "Detailed stats" entry card. Tapping opens a popout sheet whose content
/// scrolls inside the sheet, so the stat page itself stays short.
class _DetailedStatsCard extends StatelessWidget {
  final String statName;
  final bool isDark;
  final Widget Function() buildMetricsGrid;
  final Widget Function() buildComparison;

  const _DetailedStatsCard({
    required this.statName,
    required this.isDark,
    required this.buildMetricsGrid,
    required this.buildComparison,
  });

  void _open(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final sheetBg = isDark ? const Color(0xFF111214) : Colors.white;
          return Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detailed stats',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              statName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200],
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      24 + MediaQuery.of(context).padding.bottom,
                    ),
                    children: [
                      buildMetricsGrid(),
                      const SizedBox(height: 16),
                      buildComparison(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color cardBg =
        isDark ? Colors.white.withOpacity(0.04) : Colors.grey[50]!;
    final Color cardBorder =
        isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200]!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detailed stats',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Central tendencies, dispersion & comparisons',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
