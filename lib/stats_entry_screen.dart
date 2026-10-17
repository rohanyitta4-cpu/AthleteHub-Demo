import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'firebase_stats_service.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'utils/responsive_layout.dart';
import 'theme/app_title_style.dart';
import 'utils/friendly_error.dart';
import 'player_stats.dart';
import 'utils/stat_windows.dart';

class StatsEntryScreen extends StatefulWidget {
  final String teamName;
  const StatsEntryScreen({super.key, required this.teamName});

  @override
  State<StatsEntryScreen> createState() => _StatsEntryScreenState();
}

class _StatsEntryScreenState extends State<StatsEntryScreen>
    with TickerProviderStateMixin {
  bool isHitting = true;
  int currentIndex = 0;
  DateTime selectedDate = DateTime.now();
  Map<String, String> inputValues = {};
  final PageController _pageController = PageController(viewportFraction: 0.92);
  final TextEditingController _inputController = TextEditingController();
  late AnimationController _cardAnimationController;
  late AnimationController _dateAnimationController;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _cardFadeAnimation;

  final List<String> hittingStatsLabels = [
    'At Bats',
    'Hits',
    'Runs',
    'Doubles',
    'Triples',
    'Home Runs',
    'Walks',
    'Intentional Walks',
    'Hit By Pitch',
    'Strikeouts',
    'Sacrifice Bunts',
    'Sacrifice Flies',
    'Stolen Bases',
    'RBI',
    'Two-Strike Count',
    'Two-Strike Success',
    'Hard-Hit Balls',
    'Quality At-Bats',
  ];

  /// Shown under the stat name for stats whose meaning isn't obvious.
  static const Map<String, String> _statHints = {
    'Intentional Walks': 'Already counted in your walks total',
    'Sacrifice Bunts': 'Bunts that moved a runner and got you out',
    'Sacrifice Flies': 'Fly-ball outs that scored a run',
    'Hard-Hit Balls':
        'Balls you squared up — hard liners, deep flies, hard grounders. Outs count too',
    'Quality At-Bats':
        'Hit, walk/HBP, 6+ pitches, hard-hit out, sac, moved a runner, or RBI',
    'Two-Strike Count': 'At-bats that reached two strikes, including strikeouts',
    'Two-Strike Success': 'Hits in those two-strike at-bats',
  };

  /// Leave blank when not tracked; blanks are excluded from these stats
  /// instead of being saved as 0.
  static const Set<String> _optionalLabels = {'Hard-Hit Balls', 'Quality At-Bats'};

  final List<String> pitchingStatsLabels = [
    'Innings Pitched',
    'Earned Runs',
    'Strikeouts',
    'Pitches Thrown',
  ];

  /// Firestore / [PlayerStats.fromJson] keys (flashcards used human labels before — caused all-zero UIs).
  static const Map<String, String> _hittingFirestoreKeys = {
    'At Bats': 'atBats',
    'Hits': 'hits',
    'Runs': 'runs',
    'Doubles': 'doubles',
    'Triples': 'triples',
    'Home Runs': 'homeRuns',
    'Walks': 'walks',
    'Hit By Pitch': 'hitByPitch',
    'Strikeouts': 'strikeouts',
    'Intentional Walks': 'intentionalWalks',
    'Sacrifice Bunts': 'sacrificeHits',
    'Sacrifice Flies': 'sacrificeFlies',
    'Hard-Hit Balls': 'hardHitBalls',
    'Quality At-Bats': 'qualityAtBats',
    'Stolen Bases': 'stolenBases',
    'RBI': 'runsBattedIn',
    'Two-Strike Count': 'twoStrikeCounts',
    'Two-Strike Success': 'successWithTwoStrikes',
  };

  static const Map<String, String> _pitchingFirestoreKeys = {
    'Innings Pitched': 'inningsPitched',
    'Earned Runs': 'earnedRuns',
    'Strikeouts': 'strikeouts',
    'Pitches Thrown': 'totalPitches',
  };

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _dateAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _cardScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeOut,
      ),
    );
    _cardAnimationController.forward();

    // Align with the rest of the app: seasons use `currentActiveSeasonId`, not `activeSeasonId`.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await FirebaseStatsService().createDefaultSeason();
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _pageController.dispose();
    _cardAnimationController.dispose();
    _dateAnimationController.dispose();
    super.dispose();
  }

  /// Returns the stat label for the current page, or `null` when the user is
  /// on the date card (step 0).
  String? get _currentLabel {
    if (currentIndex == 0) return null;
    final list = isHitting ? hittingStatsLabels : pitchingStatsLabels;
    final statIdx = currentIndex - 1;
    if (statIdx < 0 || statIdx >= list.length) return null;
    return list[statIdx];
  }

  List<String> get _currentStatList =>
      isHitting ? hittingStatsLabels : pitchingStatsLabels;

  /// Total carousel steps = 1 date card + N stat cards.
  int get _totalSteps => _currentStatList.length + 1;

  /// Index of the last stat card (also the page that shows "Save Stats").
  int get _lastStepIndex => _totalSteps - 1;

  void _syncInputForCurrentPage() {
    final label = _currentLabel;
    if (label == null) {
      _inputController.clear();
    } else {
      _inputController.text = inputValues[label] ?? '';
    }
  }

  Future<void> _selectDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      // Override the dialog's color scheme with neutral B/W so it doesn't
      // inherit the app's seed-color tint (which read as pink/purple).
      builder: (context, child) {
        final neutralScheme = isDark
            ? const ColorScheme.dark(
                primary: Colors.white,
                onPrimary: Colors.black,
                surface: Color(0xFF1C1C1E),
                onSurface: Colors.white,
                surfaceContainerHigh: Color(0xFF1C1C1E),
                surfaceContainerHighest: Color(0xFF2C2C2E),
              )
            : const ColorScheme.light(
                primary: Color(0xFF111111),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Color(0xFF111111),
                surfaceContainerHigh: Colors.white,
                surfaceContainerHighest: Color(0xFFF1F2F4),
              );
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: neutralScheme,
            datePickerTheme: DatePickerThemeData(
              backgroundColor: neutralScheme.surface,
              headerBackgroundColor: neutralScheme.surface,
              headerForegroundColor: neutralScheme.onSurface,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return neutralScheme.onPrimary;
                }
                if (states.contains(WidgetState.disabled)) {
                  return neutralScheme.onSurface.withValues(alpha: 0.30);
                }
                return neutralScheme.onSurface;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return neutralScheme.primary;
                }
                return Colors.transparent;
              }),
              todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return neutralScheme.primary;
                }
                return Colors.transparent;
              }),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return neutralScheme.onPrimary;
                }
                return neutralScheme.primary;
              }),
              todayBorder: BorderSide(color: neutralScheme.primary, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: neutralScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      _dateAnimationController.forward(from: 0.0);
      setState(() => selectedDate = picked);
      HapticFeedback.lightImpact();
    }
  }

  void _onStatChanged(String value) {
    final label = _currentLabel;
    if (label != null) inputValues[label] = value;
  }

  void _goToNext() {
    if (currentIndex < _lastStepIndex) {
      HapticFeedback.lightImpact();
      FocusScope.of(context).unfocus();
      setState(() {
        currentIndex++;
        _syncInputForCurrentPage();
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goToPrevious() {
    if (currentIndex > 0) {
      HapticFeedback.lightImpact();
      FocusScope.of(context).unfocus();
      setState(() {
        currentIndex--;
        _syncInputForCurrentPage();
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _submitStats() async {
    HapticFeedback.mediumImpact();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
      }
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final statsService = FirebaseStatsService();
      var season = await statsService.getActiveSeason();
      if (season == null) {
        await statsService.createDefaultSeason();
        season = await statsService.getActiveSeason();
      }
      if (season == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No active or default season found. Open Seasons once or try again.',
              ),
            ),
          );
        }
        return;
      }
      final activeSeasonId = season.id;

      final keyMap = isHitting ? _hittingFirestoreKeys : _pitchingFirestoreKeys;
      final stats = <String, dynamic>{};
      for (final label in _currentStatList) {
        final firestoreKey = keyMap[label];
        if (firestoreKey == null) continue;
        final entered = inputValues[label]?.trim() ?? '';
        if (_optionalLabels.contains(label) && entered.isEmpty) continue;
        final raw = entered.isEmpty ? '0' : entered;
        if (firestoreKey == 'inningsPitched') {
          stats[firestoreKey] = double.tryParse(raw) ?? 0.0;
        } else {
          stats[firestoreKey] = int.tryParse(raw) ?? 0;
        }
      }

      final problem = isHitting ? _validateHitting(stats) : null;
      if (problem != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(problem)),
          );
        }
        return;
      }

      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('seasons')
          .doc(activeSeasonId)
          .collection('games')
          .add({
        'date': Timestamp.fromDate(selectedDate),
        'stats': stats,
        'type': isHitting ? 'hitting' : 'pitching',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Stats saved for ${DateFormat('MM/dd/yyyy').format(selectedDate)}!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {
          inputValues.clear();
          currentIndex = 0;
          selectedDate = DateTime.now();
          _inputController.clear();
        });
        _pageController.jumpToPage(0);
        _cardAnimationController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e, "Couldn't save your stats"))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final responsive = ResponsiveLayout(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBody: true,
      appBar: AppBar(
        // The MainNavigationScreen overlays a floating hamburger button at
        // top: 60, left: 20 across every tab. Reserve the leading slot so the
        // title starts past it instead of being painted under it.
        automaticallyImplyLeading: false,
        leadingWidth: responsive.scaleFont(72),
        leading: const SizedBox.shrink(),
        titleSpacing: 0,
        // Wrap in DefaultTextStyle that explicitly clears any inherited
        // text-decoration (the inherited AppBar titleTextStyle was rendering
        // stray underline/strike marks on top of the title).
        title: DefaultTextStyle.merge(
          style: const TextStyle(
            decoration: TextDecoration.none,
            decorationColor: Colors.transparent,
            decorationThickness: 0,
          ),
          child: Text(
            'Enter Stats',
            style: appTitleStyle(color: colors.onSurface),
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: colors.outline.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header section — only the Hitting / Pitching mode toggle now.
            // Date selection has moved into the carousel as step 0.
            Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.defaultPadding * 1.25,
                responsive.scaleFont(14),
                responsive.defaultPadding * 1.25,
                responsive.scaleFont(10),
              ),
              child: _buildModeSegmented(colors, responsive),
            ),
            // PageView — step 0 is the date card, steps 1..N are stat cards.
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                onPageChanged: (index) {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    currentIndex = index;
                    _syncInputForCurrentPage();
                  });
                },
                itemCount: _totalSteps,
                itemBuilder: (context, index) {
                  final card = index == 0
                      ? _buildAnimatedDateCard(colors, isDark)
                      : _buildAnimatedFlashcard(
                          _currentStatList[index - 1], colors, isDark);
                  return _carouselTransform(index, card);
                },
              ),
            ),
            // Page indicator — neutral (no seed-color tint).
            Padding(
              padding: EdgeInsets.symmetric(vertical: responsive.scaleFont(10)),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _totalSteps,
                effect: WormEffect(
                  activeDotColor:
                      isDark ? Colors.white : const Color(0xFF111111),
                  dotColor: colors.onSurface.withValues(alpha: 0.18),
                  dotHeight: responsive.scaleFont(6),
                  dotWidth: responsive.scaleFont(6),
                  spacing: responsive.scaleFont(5),
                ),
              ),
            ),
            // Navigation buttons
            Container(
              padding: EdgeInsets.fromLTRB(
                responsive.defaultPadding * 1.25,
                responsive.scaleFont(12),
                responsive.defaultPadding * 1.25,
                responsive.scaleFont(16),
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: colors.outline.withValues(alpha: 0.10),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSecondaryButton(
                      'Previous',
                      Icons.arrow_back_rounded,
                      currentIndex > 0 ? _goToPrevious : null,
                      colors,
                      responsive,
                    ),
                  ),
                  SizedBox(width: responsive.scaleFont(12)),
                  Expanded(
                    flex: 2,
                    child: currentIndex == _lastStepIndex
                        ? _buildPrimaryButton(
                            'Save Stats',
                            Icons.check_rounded,
                            _submitStats,
                            colors,
                            responsive,
                            isFinal: true,
                          )
                        : _buildPrimaryButton(
                            currentIndex == 0 ? 'Start' : 'Next',
                            Icons.arrow_forward_rounded,
                            _goToNext,
                            colors,
                            responsive,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Header widgets -------------------------------------------------------

  /// Catches entries that can't all be true at once, e.g. more intentional
  /// walks than walks.
  String? _validateHitting(Map<String, dynamic> stats) {
    int v(String k) => (stats[k] as num?)?.toInt() ?? 0;
    final ab = v('atBats');
    if (v('hits') > ab) return 'Hits can\'t be more than at bats.';
    if (v('intentionalWalks') > v('walks')) {
      return 'Intentional walks are part of your walks, so they can\'t be more than walks.';
    }
    final ballsInPlay = ab - v('strikeouts') + v('sacrificeFlies');
    if (stats.containsKey('hardHitBalls') && v('hardHitBalls') > ballsInPlay) {
      return 'Hard-hit balls can\'t be more than balls you put in play '
          '(at bats − strikeouts + sac flies = $ballsInPlay).';
    }
    final pa = ab + v('walks') + v('hitByPitch') + v('sacrificeFlies') + v('sacrificeHits');
    if (stats.containsKey('qualityAtBats') && v('qualityAtBats') > pa) {
      return 'Quality at-bats can\'t be more than plate appearances ($pa).';
    }
    return twoStrikeIssue(PlayerStats(
      atBats: ab,
      hits: v('hits'),
      strikeouts: v('strikeouts'),
      twoStrikeCounts: v('twoStrikeCounts'),
      successWithTwoStrikes: v('successWithTwoStrikes'),
    ));
  }

  Widget _buildModeSegmented(ColorScheme colors, ResponsiveLayout responsive) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Single rounded track that hosts both options. Selected one floats on a
    // contrasting fill — same model as an iOS UISegmentedControl.
    final Color trackColor = isDark
        ? colors.surfaceContainerHighest.withValues(alpha: 0.4)
        : const Color(0xFFEFEFF1);
    final Color selectedFill = isDark ? colors.surface : Colors.white;

    return Container(
      padding: EdgeInsets.all(responsive.scaleFont(4)),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(responsive.scaleFont(12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegment(
              label: 'Hitting',
              icon: Icons.sports_baseball_rounded,
              isSelected: isHitting,
              selectedFill: selectedFill,
              colors: colors,
              responsive: responsive,
              onTap: () {
                if (!isHitting) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    isHitting = true;
                    currentIndex = 0;
                    _pageController.jumpToPage(0);
                    _syncInputForCurrentPage();
                  });
                  _cardAnimationController.forward(from: 0.0);
                }
              },
            ),
          ),
          Expanded(
            child: _buildSegment(
              label: 'Pitching',
              icon: Icons.sports_handball_rounded,
              isSelected: !isHitting,
              selectedFill: selectedFill,
              colors: colors,
              responsive: responsive,
              onTap: () {
                if (isHitting) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    isHitting = false;
                    currentIndex = 0;
                    _pageController.jumpToPage(0);
                    _syncInputForCurrentPage();
                  });
                  _cardAnimationController.forward(from: 0.0);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color selectedFill,
    required ColorScheme colors,
    required ResponsiveLayout responsive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(vertical: responsive.scaleFont(10)),
        decoration: BoxDecoration(
          color: isSelected ? selectedFill : Colors.transparent,
          borderRadius: BorderRadius.circular(responsive.scaleFont(9)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: responsive.scaleFont(16),
              color: isSelected
                  ? colors.onSurface
                  : colors.onSurface.withValues(alpha: 0.55),
            ),
            SizedBox(width: responsive.scaleFont(8)),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: responsive.scaleFont(14),
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? colors.onSurface
                    : colors.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Bottom nav buttons ---------------------------------------------------

  Widget _buildPrimaryButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
    ColorScheme colors,
    ResponsiveLayout responsive, {
    bool isFinal = false,
  }) {
    // The primary action always uses the theme's primary color, so it
    // automatically inverts (dark on light, light on dark) without
    // hard-coded colors. The Save action gets a subtle green wash so users
    // can tell it's the terminal step.
    final Color bg = isFinal ? const Color(0xFF16A34A) : colors.primary;
    final Color fg = isFinal ? Colors.white : colors.onPrimary;

    return SizedBox(
      height: responsive.scaleFont(50),
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.scaleFont(14)),
          ),
          padding: EdgeInsets.symmetric(horizontal: responsive.scaleFont(20)),
        ),
        icon: Icon(icon, size: responsive.scaleFont(18)),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: responsive.scaleFont(15),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
    String label,
    IconData icon,
    VoidCallback? onPressed,
    ColorScheme colors,
    ResponsiveLayout responsive,
  ) {
    final bool isEnabled = onPressed != null;
    final Color fg = isEnabled
        ? colors.onSurface
        : colors.onSurface.withValues(alpha: 0.35);
    final Color borderColor = isEnabled
        ? colors.outline.withValues(alpha: 0.30)
        : colors.outline.withValues(alpha: 0.15);

    return SizedBox(
      height: responsive.scaleFont(50),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: borderColor, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.scaleFont(14)),
          ),
          padding: EdgeInsets.symmetric(horizontal: responsive.scaleFont(14)),
        ),
        icon: Icon(icon, size: responsive.scaleFont(16)),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: responsive.scaleFont(14),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Rotates, shrinks and fades each card based on its distance from the
  /// centered page, so cards turn in 3D as they're swiped.
  Widget _carouselTransform(int index, Widget card) {
    if (MediaQuery.of(context).disableAnimations) return card;
    return AnimatedBuilder(
      animation: _pageController,
      child: card,
      builder: (context, child) {
        double page = currentIndex.toDouble();
        if (_pageController.hasClients &&
            _pageController.position.haveDimensions) {
          page = _pageController.page ?? page;
        }
        final delta = (index - page).clamp(-1.0, 1.0);
        final distance = delta.abs();
        return Opacity(
          opacity: 1 - distance * 0.45,
          child: Transform(
            alignment: delta > 0 ? Alignment.centerLeft : Alignment.centerRight,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(delta * -0.55)
              ..scaleByDouble(1 - distance * 0.12, 1 - distance * 0.12, 1, 1),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildAnimatedFlashcard(
      String label, ColorScheme colors, bool isDark) {
    return ScaleTransition(
      scale: _cardScaleAnimation,
      child: FadeTransition(
        opacity: _cardFadeAnimation,
        child: _buildFlashcard(label, colors, isDark),
      ),
    );
  }

  Widget _buildAnimatedDateCard(ColorScheme colors, bool isDark) {
    return ScaleTransition(
      scale: _cardScaleAnimation,
      child: FadeTransition(
        opacity: _cardFadeAnimation,
        child: _buildDateCard(colors, isDark),
      ),
    );
  }

  Widget _buildDateCard(ColorScheme colors, bool isDark) {
    final responsive = ResponsiveLayout(context);
    final total = _totalSteps;
    final progress = 1 / total;
    const double maxCardWidth = 460;

    final Color cardStart =
        isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFAFAFB);
    final Color cardEnd =
        isDark ? const Color(0xFF161618) : const Color(0xFFF1F2F4);

    final bool isToday = _isSameDay(selectedDate, DateTime.now());

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxCardWidth),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: responsive.defaultPadding * 0.5,
            vertical: responsive.defaultPadding * 0.75,
          ),
          padding: EdgeInsets.fromLTRB(
            responsive.scaleFont(22),
            responsive.scaleFont(20),
            responsive.scaleFont(22),
            responsive.scaleFont(24),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardStart, cardEnd],
            ),
            borderRadius: BorderRadius.circular(responsive.scaleFont(22)),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress bar — matches the flashcards.
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(responsive.scaleFont(8)),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.white : const Color(0xFF111111),
                        ),
                        minHeight: responsive.scaleFont(6),
                      ),
                    ),
                  ),
                  SizedBox(width: responsive.scaleFont(10)),
                  Text(
                    '1/$total',
                    style: GoogleFonts.inter(
                      fontSize: responsive.scaleFont(12),
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.scaleFont(22)),
              Text(
                'STEP 1 · GAME DATE',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: responsive.scaleFont(11),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: colors.onSurface.withValues(alpha: 0.55),
                ),
              ),
              SizedBox(height: responsive.scaleFont(6)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'When did you play?',
                  style: GoogleFonts.poppins(
                    color: colors.onSurface,
                    fontSize: responsive.scaleFont(28),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: responsive.scaleFont(22)),
              // Big tappable date display.
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _selectDate,
                  borderRadius:
                      BorderRadius.circular(responsive.scaleFont(14)),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.scaleFont(18),
                      vertical: responsive.scaleFont(20),
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius:
                          BorderRadius.circular(responsive.scaleFont(14)),
                      border: Border.all(
                        color: colors.outline.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('EEEE').format(selectedDate),
                          style: GoogleFonts.inter(
                            fontSize: responsive.scaleFont(13),
                            fontWeight: FontWeight.w600,
                            color:
                                colors.onSurface.withValues(alpha: 0.55),
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: responsive.scaleFont(4)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            DateFormat('MMM d, yyyy').format(selectedDate),
                            style: GoogleFonts.inter(
                              fontSize: responsive.scaleFont(32),
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                        ),
                        SizedBox(height: responsive.scaleFont(10)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_calendar_rounded,
                              size: responsive.scaleFont(14),
                              color:
                                  colors.onSurface.withValues(alpha: 0.55),
                            ),
                            SizedBox(width: responsive.scaleFont(6)),
                            Text(
                              'Tap to change',
                              style: GoogleFonts.inter(
                                fontSize: responsive.scaleFont(12),
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: responsive.scaleFont(12)),
              // Quick "Today" chip — one-tap reset when the user is far away.
              Center(
                child: GestureDetector(
                  onTap: isToday
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          setState(() => selectedDate = DateTime.now());
                        },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.scaleFont(12),
                      vertical: responsive.scaleFont(6),
                    ),
                    decoration: BoxDecoration(
                      color: isToday
                          ? colors.onSurface.withValues(alpha: 0.06)
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(responsive.scaleFont(20)),
                      border: Border.all(
                        color: colors.outline.withValues(
                          alpha: isToday ? 0.20 : 0.30,
                        ),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isToday ? '✓ Today' : 'Use today',
                      style: GoogleFonts.inter(
                        fontSize: responsive.scaleFont(12),
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface
                            .withValues(alpha: isToday ? 0.45 : 0.80),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: responsive.scaleFont(14)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: responsive.scaleFont(14),
                    color: colors.onSurface.withValues(alpha: 0.45),
                  ),
                  SizedBox(width: responsive.scaleFont(6)),
                  Text(
                    'Tap Start when ready',
                    style: GoogleFonts.inter(
                      fontSize: responsive.scaleFont(11),
                      fontWeight: FontWeight.w500,
                      color: colors.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildFlashcard(String label, ColorScheme colors, bool isDark) {
    final responsive = ResponsiveLayout(context);
    final total = _totalSteps;
    final progress = (currentIndex + 1) / total;

    // Clamp the card width on large screens so it doesn't stretch edge-to-edge
    // on iPads (or landscape phones) and lose the "flashcard" identity.
    const double maxCardWidth = 460;

    // Neutral surfaces — explicitly avoid mixing in `colors.primary` so the
    // card doesn't pick up the seed-color tint (which previously read as pink
    // in light mode). Subtle vertical tone shift for depth, nothing more.
    final Color cardStart =
        isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFAFAFB);
    final Color cardEnd =
        isDark ? const Color(0xFF161618) : const Color(0xFFF1F2F4);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxCardWidth),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: responsive.defaultPadding * 0.5,
            vertical: responsive.defaultPadding * 0.75,
          ),
          padding: EdgeInsets.fromLTRB(
            responsive.scaleFont(22),
            responsive.scaleFont(20),
            responsive.scaleFont(22),
            responsive.scaleFont(24),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardStart, cardEnd],
            ),
            borderRadius: BorderRadius.circular(responsive.scaleFont(22)),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          width: double.infinity,
          // Allow scrolling only when the keyboard squeezes content; otherwise
          // the card sits naturally at its intrinsic height.
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress bar — thicker so users can actually see it
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(responsive.scaleFont(8)),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Colors.white : const Color(0xFF111111),
                          ),
                          minHeight: responsive.scaleFont(6),
                        ),
                      ),
                    ),
                    SizedBox(width: responsive.scaleFont(10)),
                    Text(
                      '${currentIndex + 1}/$total',
                      style: GoogleFonts.inter(
                        fontSize: responsive.scaleFont(12),
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.scaleFont(22)),
                // STAT TYPE kicker
                Text(
                  _optionalLabels.contains(label) ? 'OPTIONAL' : 'STAT TYPE',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: responsive.scaleFont(11),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: colors.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                SizedBox(height: responsive.scaleFont(6)),
                // Stat name (auto-shrinks on small phones / long stat names)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: colors.onSurface,
                      fontSize: responsive.scaleFont(32),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_statHints[label] != null) ...[
                  SizedBox(height: responsive.scaleFont(6)),
                  Text(
                    _optionalLabels.contains(label)
                        ? '${_statHints[label]}. Leave blank if you didn\'t track it.'
                        : _statHints[label]!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: responsive.scaleFont(12),
                      height: 1.35,
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                SizedBox(height: responsive.scaleFont(22)),
                // Input field — clean pill, single themed border, no double shadow
                _buildStatInput(colors, responsive),
                SizedBox(height: responsive.scaleFont(14)),
                // Helper line — balances the bottom of the card and gives the
                // user a clear affordance for what to do (return = next).
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.keyboard_return_rounded,
                      size: responsive.scaleFont(14),
                      color: colors.onSurface.withValues(alpha: 0.45),
                    ),
                    SizedBox(width: responsive.scaleFont(6)),
                    Text(
                      currentIndex == total - 1
                          ? 'Tap Save when you\'re done'
                          : 'Press return to go to next stat',
                      style: GoogleFonts.inter(
                        fontSize: responsive.scaleFont(11),
                        fontWeight: FontWeight.w500,
                        color: colors.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatInput(ColorScheme colors, ResponsiveLayout responsive) {
    final optional = _optionalLabels.contains(_currentLabel);
    return TextField(
      controller: _inputController,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        color: colors.onSurface,
        fontSize: responsive.scaleFont(40),
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        height: 1.1,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: colors.surface,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.scaleFont(14)),
          borderSide: BorderSide(
            color: colors.outline.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.scaleFont(14)),
          borderSide: BorderSide(
            color: colors.outline.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.scaleFont(14)),
          borderSide: BorderSide(
            color: colors.onSurface,
            width: 1.5,
          ),
        ),
        hintText: optional ? '—' : '0',
        hintStyle: GoogleFonts.inter(
          fontSize: responsive.scaleFont(40),
          fontWeight: FontWeight.w800,
          color: colors.onSurface.withValues(alpha: 0.18),
          height: 1.1,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: responsive.scaleFont(18),
          vertical: responsive.scaleFont(16),
        ),
      ),
      onChanged: _onStatChanged,
      onSubmitted: (_) {
        HapticFeedback.lightImpact();
        _goToNext();
      },
    );
  }
}
