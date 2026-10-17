import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_stats_service.dart';
import '../models/hitting_profile.dart';
import '../player_stats.dart';
import '../services/performance_analysis/analysis_context_builder.dart';
import '../services/performance_analysis/performance_analysis_service.dart';
import '../services/performance_analysis/performance_report_model.dart';
import '../theme/app_styles.dart';
import '../theme/rank_accent.dart';
import '../utils/season_stats_pipeline.dart';
import '../utils/stat_windows.dart';
import '../widgets/dashboard/artsy_hero_card.dart';
import '../widgets/dashboard/dash_style.dart';
import '../widgets/dashboard/quick_stats_panel.dart';
import '../widgets/dashboard/recent_games_carousel.dart';
import '../widgets/hitting_profile_picker.dart';
import 'performance_report_screen.dart';

/// Quick-stat picker options: group → key → (row label, picker name, plural).
const Map<String, Map<String, (String, String, String)>> _quickStatGroups = {
  'Hitting rates': {
    'battingAverage': ('AVG', 'Batting average', ''),
    'onBasePercentage': ('OBP', 'On-base %', ''),
    'sluggingPercentage': ('SLG', 'Slugging %', ''),
    'onBasePlusSlugging': ('OPS', 'OPS', ''),
    'isolatedPower': ('ISO', 'Isolated power', ''),
    'runsCreated': ('RC', 'Runs created', ''),
    'war': ('WAR', 'WAR', ''),
  },
  'Hitting': {
    'atBats': ('AB', 'At bats', 'at bats'),
    'hits': ('Hits', 'Hits', 'hits'),
    'doubles': ('2B', 'Doubles', 'doubles'),
    'triples': ('3B', 'Triples', 'triples'),
    'homeRuns': ('HR', 'Home runs', 'home runs'),
    'runs': ('Runs', 'Runs', 'runs'),
    'runsBattedIn': ('RBI', 'RBI', 'RBI'),
    'walks': ('BB', 'Walks', 'walks'),
    'intentionalWalks': ('IBB', 'Intentional walks', 'intentional walks'),
    'hitByPitch': ('HBP', 'Hit by pitch', 'hit by pitches'),
    'strikeouts': ('K', 'Strikeouts', 'strikeouts'),
    'sacrificeHits': ('SH', 'Sacrifice bunts', 'sacrifice bunts'),
    'sacrificeFlies': ('SF', 'Sacrifice flies', 'sacrifice flies'),
    'stolenBases': ('SB', 'Stolen bases', 'stolen bases'),
  },
  'Approach': {
    'hardHitBalls': ('HH', 'Hard-hit balls', 'hard-hit balls'),
    'hardHitRate': ('HH%', 'Hard-hit rate', ''),
    'qualityAtBats': ('QAB', 'Quality at-bats', 'quality at-bats'),
    'qualityAtBatRate': ('QAB%', 'Quality at-bat rate', ''),
    'twoStrikeCounts': ('2S', 'Two-strike counts', 'two-strike counts'),
    'twoStrikeSuccessRate': ('2S AVG', 'Two-strike success', ''),
  },
  'Pitching': {
    'earnedRunAverage': ('ERA', 'ERA', ''),
    'walksHitsPerInningPitched': ('WHIP', 'WHIP', ''),
    'strikeoutRate': ('K/9', 'Strikeouts per 9', ''),
    'inningsPitched': ('IP', 'Innings pitched', 'innings pitched'),
    'earnedRuns': ('ER', 'Earned runs', 'earned runs'),
    'pitchesThrown': ('P', 'Pitches thrown', 'pitches thrown'),
  },
};

final Map<String, (String, String, String)> _quickStatOptions = {for (final group in _quickStatGroups.values) ...group};

/// Floor for each mini-chart scale so typical games don't fill the bar.
const Map<String, double> _chartScaleFloor = {
  'battingAverage': 1,
  'onBasePercentage': 1,
  'sluggingPercentage': 2,
  'onBasePlusSlugging': 3,
  'isolatedPower': 1,
  'runsCreated': 3,
  'war': 200,
  'atBats': 5,
  'hits': 4,
  'doubles': 2,
  'triples': 2,
  'homeRuns': 2,
  'runs': 3,
  'runsBattedIn': 4,
  'walks': 3,
  'intentionalWalks': 2,
  'hitByPitch': 2,
  'strikeouts': 3,
  'sacrificeHits': 2,
  'sacrificeFlies': 2,
  'stolenBases': 3,
  'hardHitBalls': 4,
  'hardHitRate': 1,
  'qualityAtBats': 5,
  'qualityAtBatRate': 1,
  'twoStrikeCounts': 5,
  'twoStrikeSuccessRate': 1,
  'earnedRunAverage': 9,
  'walksHitsPerInningPitched': 3,
  'strikeoutRate': 15,
  'inningsPitched': 7,
  'earnedRuns': 5,
  'pitchesThrown': 100,
};

const _defaultQuickStats = ['battingAverage', 'hits', 'runsBattedIn', 'homeRuns'];
const _maxQuickStats = 4;
const _quickStatsPrefsKey = 'dashboardPreview.quickStats.v2';
const _recentGameCount = 10;

/// Home tab: rank card, recent games, quick stats.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _analysis = PerformanceAnalysisService();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _gamesSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  List<_Game> _games = [];
  bool _loadingGames = true;
  String _name = '';
  String? _photoUrl;
  HittingProfile? _profile;
  PerformanceReport? _report;
  bool _loadingReport = true;
  bool _generatingReport = false;
  bool _refreshingReport = false;
  int _heroTick = 0;

  Color? _tint;
  bool _profileLoaded = false;

  int? _syncedGameCount;
  List<String> _quickStats = _defaultQuickStats;

  @override
  void initState() {
    super.initState();
    _listenToUser();
    _listenToGames();
    _loadPlayer();
    _loadProfileAndReport();
    _loadQuickStats();
  }

  @override
  void dispose() {
    _gamesSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }

  void _listenToUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _userSub = FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((doc) {
      if (!mounted || !doc.exists) return;
      final data = doc.data();
      if (data == null) return;
      final name = (data['displayName'] as String?)?.trim();
      setState(() {
        if (name != null && name.isNotEmpty) _name = name;
        _photoUrl = data['profilePictureUrl'] as String? ?? _photoUrl;
      });
    });
  }

  Future<void> _listenToGames() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final season = await FirebaseStatsService().getActiveSeason();
    if (uid == null || season == null) {
      if (mounted) setState(() => _loadingGames = false);
      return;
    }
    _gamesSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('seasons')
        .doc(season.id)
        .collection('games')
        .orderBy('date')
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;
            setState(() {
              _games = snap.docs.map((doc) {
                final data = doc.data();
                final meta = data['metadata'];
                final opponent = (data['opponent'] ?? (meta is Map ? meta['opponent'] : null))?.toString().trim();
                return _Game(
                  date: (data['date'] as Timestamp?)?.toDate(),
                  stats: playerStatsFromFirestoreGame(data),
                  opponent: opponent == null || opponent.isEmpty ? null : opponent,
                );
              }).toList();
              _loadingGames = false;
            });
            _syncReport();
          },
          onError: (_) {
            if (mounted) setState(() => _loadingGames = false);
          },
        );
  }

  Future<void> _loadPlayer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _name = user.displayName ?? 'Player');
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data == null || !mounted) return;
      setState(() {
        _name = (data['displayName'] as String?)?.trim().isNotEmpty == true ? data['displayName'] as String : _name;
        _photoUrl = data['profilePictureUrl'] as String?;
      });
    } catch (_) {}
  }

  /// Load cached report, then sync if game count changed.
  Future<void> _loadProfileAndReport() async {
    try {
      final profile = await _analysis.getHittingProfile();
      final report = await _analysis.cachedReport(profile: profile);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _report = report;
        _profileLoaded = true;
        _syncedGameCount = null;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingReport = false);
    }
    _syncReport();
  }

  /// Same grade path as Scout: reuse saved report until game count changes.
  Future<void> _syncReport({bool userRequested = false}) async {
    if (!_profileLoaded || _loadingGames || _refreshingReport) return;
    if (_games.length < 5 || _syncedGameCount == _games.length) return;

    final gameCount = _games.length;
    final context = AnalysisContextBuilder.build([
      for (final g in _games) {'date': g.date, 'stats': g.stats},
    ]);
    if (!context.hasEnoughData) return;

    setState(() {
      _refreshingReport = true;
      if (userRequested) _generatingReport = true;
    });
    try {
      final report = await _analysis.reportForContext(context, profile: _profile);
      if (!mounted) return;
      setState(() {
        _report = report;
        _syncedGameCount = gameCount;
      });
    } catch (_) {
      if (mounted && userRequested) {
        ScaffoldMessenger.of(
          this.context,
        ).showSnackBar(const SnackBar(content: Text("Couldn't reach Scout. Try again in a moment.")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _refreshingReport = false;
          _generatingReport = false;
        });
      }
    }
    if (mounted && _games.length != gameCount) _syncReport();
  }

  Future<void> _changeProfile() async {
    final chosen = await HittingProfileSheet.show(context, _profile);
    if (chosen == null || chosen == _profile || !mounted) return;
    setState(() {
      _profile = chosen;
      _loadingReport = true;
    });
    final cached = await _analysis.cachedReport(profile: chosen);
    if (!mounted) return;
    setState(() {
      _report = cached;
      _loadingReport = false;
      _syncedGameCount = null;
    });
    _syncReport();
  }

  Future<void> _loadQuickStats() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_quickStatsPrefsKey);
    if (saved == null || !mounted) return;
    setState(() => _quickStats = saved.where(_quickStatOptions.containsKey).take(_maxQuickStats).toList());
  }

  Future<void> _saveQuickStats(List<String> keys) async {
    setState(() => _quickStats = keys);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_quickStatsPrefsKey, keys);
  }

  PlayerStats _totals(Iterable<_Game> games) => PlayerStats.sum(games.map((g) => g.stats));

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: RankAccent.instance, builder: (context, _) => _buildScreen(context));

  Widget _buildScreen(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final realScore = rankedScore(_report, _games.length);
    if (!_loadingGames && !_loadingReport) {
      WidgetsBinding.instance.addPostFrameCallback((_) => RankAccent.instance.setScore(realScore));
    }
    final target = RankAccent.instance.color(isDark);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), automaticallyImplyLeading: false),
      body: target == null
          ? _buildBody(isDark, null)
          : TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: target),
              duration: const Duration(milliseconds: 450),
              builder: (context, tint, _) => Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 520,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, -1),
                            radius: 1.1,
                            colors: [
                              tint!.withValues(alpha: isDark ? 0.14 : 0.10),
                              tint.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildBody(isDark, tint),
                ],
              ),
            ),
    );
  }

  Widget _buildBody(bool isDark, Color? tint) {
    _tint = tint;
    const side = EdgeInsets.symmetric(horizontal: 16);
    return RefreshIndicator(
      color: tint,
      onRefresh: () async {
        setState(() => _heroTick++);
        await Future.wait([_loadPlayer(), _loadProfileAndReport()]);
      },
      child: ListView(
        // Room for the floating bottom nav.
        padding: const EdgeInsets.only(top: 16, bottom: 130),
        children: [
          _FadeSlideIn(
            delay: 0,
            child: Padding(
              padding: side,
              child: ArtsyHeroCard(
                name: _name,
                photoUrl: _photoUrl,
                profile: _profile,
                report: _report,
                seasonTotals: _totals(_games),
                gamesLogged: _games.length,
                loading: _loadingReport,
                generating: _generatingReport,
                refreshTick: _heroTick,
                scoreOverride: RankAccent.instance.previewScore,
                onGenerate: () => _syncReport(userRequested: true),
                onChangeProfile: _changeProfile,
              ),
            ),
          ),
          if (rankedScore(_report, _games.length) != null) ...[
            const SizedBox(height: 12),
            Padding(padding: side, child: _seeReportButton(isDark)),
          ],
          const SizedBox(height: 30),
          _FadeSlideIn(
            delay: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: side,
                  child: _sectionHeader(
                    isDark,
                    'RECENT GAMES',
                    trailing: _games.isEmpty
                        ? null
                        : Text(
                            'Last ${_games.length.clamp(0, _recentGameCount)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[500] : Colors.grey[700],
                            ),
                          ),
                  ),
                ),
                if (_profile == null && _games.isNotEmpty) Padding(padding: side, child: _profileNudge(isDark)),
                const SizedBox(height: 8),
                _buildRecentGames(isDark, side),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _FadeSlideIn(
            delay: 240,
            child: Padding(
              padding: side,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                    isDark,
                    'QUICK STATS',
                    trailing: TextButton.icon(
                      onPressed: () => _editQuickStats(isDark),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: tint ?? _text(isDark),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: Text('Pick stats', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: sectionLabelGap),
                  _buildQuickStats(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _seeReportButton(bool isDark) {
    final tint = _tint;
    final text = dashText(isDark);
    final muted = dashMuted(isDark);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PerformanceReportScreen())),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: dashCard(
            isDark,
            radius: 14,
          ).copyWith(border: Border.all(color: tint?.withValues(alpha: 0.22) ?? dashBorder(isDark))),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              children: [
                if (tint != null) ...[
                  Container(
                    width: 3,
                    height: 28,
                    decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SCOUTING REPORT', style: dashLabel(isDark, size: 10)),
                      const SizedBox(height: 3),
                      Text(
                        'See full report',
                        style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: text),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 22, color: tint ?? muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(bool isDark, String label, {Widget? trailing}) {
    final tint = _tint;
    return Row(
      children: [
        if (tint != null) ...[
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(child: Text(label, style: sectionLabelStyle(isDark))),
        ?trailing,
      ],
    );
  }

  Color _text(bool isDark) => isDark ? Colors.white : const Color(0xFF111111);

  Widget _profileNudge(bool isDark) {
    final muted = isDark ? Colors.grey[400] : Colors.grey[800];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: _changeProfile,
        child: Row(
          children: [
            Icon(Icons.auto_awesome, size: 14, color: muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'Highlights adapt to your hitter type. ',
                  children: [
                    TextSpan(
                      text: 'Set profile',
                      style: TextStyle(color: _text(isDark), decoration: TextDecoration.underline),
                    ),
                  ],
                ),
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentGames(bool isDark, EdgeInsets side) {
    if (_loadingGames) {
      return const SizedBox(height: 226, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (_games.isEmpty) {
      return Padding(
        padding: side,
        child: _emptyCard(
          isDark,
          Icons.sports_baseball_outlined,
          'No games yet',
          'Tap + to log your first game. Your last $_recentGameCount games show up here.',
        ),
      );
    }

    final total = _games.length;
    final recent = [
      for (var i = total - 1; i >= 0 && i >= total - _recentGameCount; i--)
        CarouselGame(date: _games[i].date, stats: _games[i].stats, number: i + 1, opponent: _games[i].opponent),
    ];
    return RecentGamesCarousel(games: recent, profile: _profile, accent: _tint);
  }

  Widget _emptyCard(bool isDark, IconData icon, String title, String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: dashCard(isDark, radius: 12),
      child: Row(
        children: [
          Icon(icon, color: isDark ? Colors.grey[400] : Colors.grey[700]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body, style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _format(String key, double value) => formatStat(key, value);

  double _valueFor(String key, List<_Game> games) => windowTotal(key, [for (final g in games) g.stats]);

  double? _gameValue(String key, PlayerStats s) => perGameValue(key, s);

  QuickStatRow _quickStatRow(String key) {
    final (label, _, noun) = _quickStatOptions[key]!;
    final window = math.min(_recentGameCount, _games.length);
    final recent = _games.sublist(_games.length - window);
    final allStats = [for (final g in _games) g.stats];
    final recentStats = [for (final g in recent) g.stats];
    final bars = [for (final g in recent) _gameValue(key, g.stats)];
    final season = _valueFor(key, _games);
    final value = _format(key, season);
    final rate = isRatioStat(key);

    final windowMax = bars.fold<double>(0, (m, v) => v != null && v > m ? v : m);
    final scaleMax = math.max(_chartScaleFloor[key] ?? 1, windowMax);
    final reference = rate ? season : (_games.isEmpty ? null : season / _games.length);
    final signal = trendSignal(key, allStats, window: window);

    QuickStatRow row({String? primary, String? secondary, String? emptyMessage}) {
      final gap = signal?.gap ?? 0;
      final showArrow = signal != null && primary != null && gap.abs() > 1e-9;
      return QuickStatRow(
        label: label,
        value: value,
        bars: bars,
        scaleMax: scaleMax,
        reference: reference,
        primary: primary,
        arrowUp: showArrow ? gap > 0 : null,
        primaryIsGood: showArrow && signal.meaningful ? signal.better : null,
        secondary: secondary,
        emptyMessage: emptyMessage,
      );
    }

    String pace() {
      if (signal == null) return 'last $window games';
      if (!signal.meaningful) return 'normal swing';
      return signal.better ? 'above season pace' : 'below season pace';
    }

    if (rate) {
      if (season == 0 && _games.every((g) => _gameValue(key, g.stats) == null)) {
        return row(emptyMessage: 'Not logged yet this season.');
      }
      if (_games.length < 2) return row(secondary: 'season');
      final recentValue = windowTotal(key, recentStats);
      return row(primary: 'L$window ${_format(key, recentValue)}', secondary: pace());
    }

    if (season == 0) {
      if (key == 'homeRuns') {
        final xbh = recent.fold<int>(0, (n, g) => n + g.stats.doubles + g.stats.triples);
        return row(
          emptyMessage: 'No home runs yet. Doubles and triples count toward SLG.',
          primary: 'XBH $xbh',
          secondary: 'last $window games',
        );
      }
      return row(emptyMessage: 'No $noun yet this season.');
    }
    final inWindow = windowTotal(key, recentStats);
    return row(
      primary: _format(key, inWindow),
      secondary: signal == null || !signal.meaningful ? 'in last $window games' : pace(),
    );
  }

  Widget _buildQuickStats(bool isDark) {
    if (_quickStats.isEmpty) {
      return _emptyCard(
        isDark,
        Icons.bar_chart_rounded,
        'No stats pinned',
        'Tap Pick stats to choose up to $_maxQuickStats stats to follow.',
      );
    }
    return QuickStatsPanel(
      rows: [for (final key in _quickStats) _quickStatRow(key)],
      recentGames: math.min(_recentGameCount, math.max(_games.length, 1)),
      accent: _tint,
    );
  }

  Widget _statOption(
    bool isDark, {
    required String name,
    required int order,
    required bool disabled,
    required VoidCallback onTap,
  }) {
    final selected = order >= 0;
    final text = dashText(isDark);
    final onText = isDark ? Colors.black : Colors.white;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.fromLTRB(selected ? 6 : 12, 7, 12, 7),
        decoration: BoxDecoration(
          color: selected ? text : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? text : dashBorder(isDark)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: onText.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${order + 1}',
                  style: dashMono(size: 11, weight: FontWeight.w800, color: onText),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: selected
                    ? onText
                    : disabled
                    ? dashMuted(isDark).withValues(alpha: 0.5)
                    : text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editQuickStats(bool isDark) async {
    final selected = [..._quickStats];
    final text = dashText(isDark);
    final muted = dashMuted(isDark);
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      backgroundColor: dashSurface(isDark),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        'Quick stats',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: text),
                      ),
                    ),
                    Text(
                      '${selected.length}/$_maxQuickStats',
                      style: dashMono(size: 13, weight: FontWeight.w700, color: muted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Shown in the order you pick them.', style: GoogleFonts.inter(fontSize: 13, color: muted)),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final group in _quickStatGroups.entries) ...[
                          const SizedBox(height: 14),
                          Text(group.key.toUpperCase(), style: dashLabel(isDark)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final entry in group.value.entries)
                                _statOption(
                                  isDark,
                                  name: entry.value.$2,
                                  order: selected.indexOf(entry.key),
                                  disabled: !selected.contains(entry.key) && selected.length >= _maxQuickStats,
                                  onTap: () => setSheetState(() {
                                    if (selected.contains(entry.key)) {
                                      selected.remove(entry.key);
                                    } else if (selected.length < _maxQuickStats) {
                                      selected.add(entry.key);
                                    }
                                  }),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.pop(context, selected),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: text, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null) await _saveQuickStats(result);
  }
}

class _FadeSlideIn extends StatelessWidget {
  final int delay;
  final Widget child;

  const _FadeSlideIn({required this.delay, required this.child});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    const length = 520;
    final start = delay / (delay + length);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: delay + length),
      builder: (context, t, child) {
        final v = Curves.easeOutCubic.transform(((t - start) / (1 - start)).clamp(0.0, 1.0));
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * 24), child: child),
        );
      },
      child: child,
    );
  }
}

class _Game {
  final DateTime? date;
  final PlayerStats stats;
  final String? opponent;

  const _Game({required this.date, required this.stats, this.opponent});
}
