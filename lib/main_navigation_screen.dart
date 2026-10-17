import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/dashboard_screen.dart';
import 'screens/enhanced_stats_screen.dart';
import 'screens/performance_report_screen.dart';
import 'history_screen.dart';
import 'account_screen.dart';
import 'notification_service.dart';
import 'widgets/animated_hamburger_menu.dart';
import 'theme/rank_accent.dart';
import 'widgets/dashboard/dash_style.dart';
import 'widgets/rainbow_glow.dart';
import 'models/player_profile.dart';
import 'services/enter_stats_navigator.dart';
import 'services/athletehub_iap.dart';
import 'services/test_launch_service.dart';
import 'screens/enter_stats_form_screen.dart';
import 'stats_entry_screen.dart';
import 'firebase_stats_service.dart';

class MainNavigationScreen extends StatefulWidget {
  final NotificationService notificationService;

  const MainNavigationScreen({super.key, required this.notificationService});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int activeIndex = 0;
  List<Widget> _pages = [];
  bool _navExpanded = false;
  Timer? _shrinkTimer;
  Timer? _entryModeCheckTimer;

  bool _menuOpen = false;

  // User profile data
  String? _userName;
  String? _profilePictureUrl;
  bool _isProMode = false;

  /// After first read of `users/{uid}` so we don't strip Zuno mode before Pro status is known.
  bool _proStatusKnown = false;
  String _selectedEntryMode = EnterStatsNavigator.flashcardMode;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _profileSubscription;

  @override
  void initState() {
    super.initState();
    // Keep IAP stream alive so purchases/restores always grant Pro in Firestore.
    AthleteHubIap.instance.ensurePurchaseListener((_, _) {});
    _loadEntryMode();
    _initializePages();
    _loadUserProfile();
    _setupProfileListener();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureDefaultSeason();
      TestLaunchService.ensureTestFlightPro();
    });

    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Start periodic check for entry mode changes (every 500ms)
    _entryModeCheckTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _checkEntryModeChange(),
    );
  }

  Future<void> _ensureDefaultSeason() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await FirebaseStatsService().createDefaultSeason();
    } catch (e) {
      debugPrint('Failed to create default season: $e');
    }
  }

  Future<void> _loadEntryMode() async {
    final mode = await EnterStatsNavigator.getEntryMode();
    setState(() {
      _selectedEntryMode = mode;
      _initializePages(); // Rebuild pages with new mode
    });
  }

  Future<void> _checkEntryModeChange() async {
    final newMode = await EnterStatsNavigator.getEntryMode();
    if (mounted && newMode != _selectedEntryMode) {
      setState(() {
        _selectedEntryMode = newMode;
        _initializePages();
      });
      await _syncEntryModeWithProStatus();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload profile picture when app resumes
      _loadUserProfile();
    }
  }

  void _setupProfileListener() {
    final user = _auth.currentUser;
    if (user != null) {
      // Listen to users collection for real-time updates
      _profileSubscription = _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen(
            (snapshot) {
              if (mounted && snapshot.exists) {
                final data = snapshot.data()!;
                final bool prevPro = _isProMode;
                final bool newPro = (data['isProMode'] as bool?) ?? false;
                setState(() {
                  _userName =
                      data['displayName'] as String? ??
                      user.displayName ??
                      'Player';
                  _profilePictureUrl = data['profilePictureUrl'] as String?;
                  _isProMode = newPro;
                  _proStatusKnown = true;
                });
                _syncEntryModeWithProStatus();
                if (prevPro != newPro) {
                  _initializePages();
                }
              } else if (mounted) {
                final bool prevPro = _isProMode;
                setState(() {
                  _isProMode = false;
                  _proStatusKnown = true;
                });
                _syncEntryModeWithProStatus();
                if (prevPro) {
                  _initializePages();
                }
                // Fallback to playerProfiles collection if users doc doesn't exist
                _firestore
                    .collection('playerProfiles')
                    .doc(user.uid)
                    .get()
                    .then((profileDoc) {
                      if (mounted && profileDoc.exists) {
                        final profile = PlayerProfile.fromFirestore(profileDoc);
                        setState(() {
                          _userName =
                              profile.displayName ??
                              user.displayName ??
                              'Player';
                          _profilePictureUrl = profile.profilePictureUrl;
                        });
                      } else if (mounted) {
                        setState(() {
                          _userName = user.displayName ?? 'Player';
                        });
                      }
                    });
              }
            },
            onError: (error) {
              print('Error listening to profile: $error');
            },
          );
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Load from users collection first (primary source)
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          if (mounted) {
            setState(() {
              _userName =
                  data['displayName'] as String? ??
                  user.displayName ??
                  'Player';
              _profilePictureUrl = data['profilePictureUrl'] as String?;
            });
          }
        } else {
          // Fallback to playerProfiles collection
          final profileDoc = await _firestore
              .collection('playerProfiles')
              .doc(user.uid)
              .get();

          if (profileDoc.exists) {
            final profile = PlayerProfile.fromFirestore(profileDoc);
            if (mounted) {
              setState(() {
                _userName = profile.displayName ?? user.displayName ?? 'Player';
                _profilePictureUrl = profile.profilePictureUrl;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _userName = user.displayName ?? 'Player';
              });
            }
          }
        }

        // Load pro mode status
        final userDocForProMode = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDocForProMode.exists) {
          final Map<String, dynamic>? proData = userDocForProMode.data();
          final bool isProMode = (proData?['isProMode'] as bool?) ?? false;
          if (mounted) {
            setState(() {
              _isProMode = isProMode;
              _proStatusKnown = true;
            });
            _syncEntryModeWithProStatus();
          }
        } else if (mounted) {
          setState(() {
            _isProMode = false;
            _proStatusKnown = true;
          });
          _syncEntryModeWithProStatus();
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  String _effectiveEntryMode() {
    if (_proStatusKnown &&
        !_isProMode &&
        _selectedEntryMode == EnterStatsNavigator.formMode) {
      return EnterStatsNavigator.flashcardMode;
    }
    return _selectedEntryMode;
  }

  Future<void> _syncEntryModeWithProStatus() async {
    if (!_proStatusKnown || _isProMode) return;
    if (_selectedEntryMode != EnterStatsNavigator.formMode) return;
    await EnterStatsNavigator.setEntryMode(EnterStatsNavigator.flashcardMode);
    if (mounted) {
      setState(() {
        _selectedEntryMode = EnterStatsNavigator.flashcardMode;
        _initializePages();
      });
    }
  }

  void _initializePages() {
    // Zuno chat entry (Pro) vs flashcards
    final entryScreen =
        _effectiveEntryMode() == EnterStatsNavigator.flashcardMode
        ? const StatsEntryScreen(teamName: 'Default Team')
        : const EnterStatsFormScreen();

    // Note: EnhancedStatsScreen is NOT created here - it's created conditionally in build()
    // to prevent early initialization that causes native crashes (FIX #3)
    _pages = [
      const DashboardScreen(),
      const SizedBox.shrink(), // Placeholder for EnhancedStatsScreen (created conditionally in build)
      entryScreen,
      const HistoryScreen(),
      AccountScreen(
        notificationService: widget.notificationService,
        onProfileUpdated: () {
          // Reload profile when returning from account screen
          _loadUserProfile();
        },
      ),
    ];
  }

  /// Handler for when you want to programmatically change
  /// the active index. Calling `setState()` here causes
  /// Flutter to re-render the tree, which `CurvedNavigationBar`
  /// responds to by running its normal animation.
  void _onTap(int index) {
    setState(() {
      activeIndex = index;
    });
  }

  @override
  void dispose() {
    _shrinkTimer?.cancel();
    _entryModeCheckTimer?.cancel();
    _profileSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Method to refresh both dashboard and stats screens
  void refreshScreens() {
    setState(() {
      // This will trigger a rebuild of all screens
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // allow content to draw behind the floating nav bar
      backgroundColor: Colors.white, // Keep white background for app content
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // Only react to primary, vertical scrolling to avoid graph pans/nested scrollables
              if (notification.depth != 0) return false;

              final axis = notification.metrics.axis;
              if (axis != Axis.vertical) return false;

              if (notification is ScrollStartNotification ||
                  notification is ScrollUpdateNotification) {
                _shrinkTimer?.cancel();
                if (!_navExpanded) setState(() => _navExpanded = true);
              } else if (notification is ScrollEndNotification) {
                _shrinkTimer?.cancel();
                _shrinkTimer = Timer(const Duration(milliseconds: 80), () {
                  if (mounted && _navExpanded) {
                    setState(() => _navExpanded = false);
                  }
                });
              }
              return false;
            },
            // ✅ FIX #3: Use conditional widget for EnhancedStatsScreen to prevent early initialization
            child: IndexedStack(
              index: activeIndex,
              children: [
                _pages[0], // Dashboard
                // Only create EnhancedStatsScreen when activeIndex is 1
                activeIndex == 1
                    ? const EnhancedStatsScreen()
                    : const SizedBox.shrink(),
                _pages[2], // Entry screen
                _pages[3], // History
                _pages[4], // Account
              ],
            ),
          ),

          AnimatedHamburgerMenu(
            menuButtons: _getMenuButtons(),
            headerWidget: _buildUserHeader(),
            selectedIndex: const [0, 1, 3, 4, 5][activeIndex],
            onMenuStateChanged: (isOpen) => setState(() => _menuOpen = isOpen),
          ),
        ],
      ),
      bottomNavigationBar: IgnorePointer(
        ignoring: _menuOpen,
        child: AnimatedSlide(
          offset: _menuOpen ? const Offset(0, 1.6) : Offset.zero,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: _SlidingPillNavigationBar(
            selectedIndex: activeIndex,
            onItemSelected: _onTap,
            items: const [
              Icons.home,
              Icons.bar_chart,
              Icons.add,
              Icons.history,
              Icons.person,
            ],
            labels: const ['Home', 'Stats', 'Log game', 'History', 'Account'],
            isExpanded: _navExpanded,
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final url = _profilePictureUrl;
    final placeholder = Icon(
      Icons.person_rounded,
      size: 22,
      color: dashMuted(isDark),
    );

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dashBorder(isDark),
            border: Border.all(color: dashBorder(isDark)),
          ),
          clipBehavior: Clip.antiAlias,
          child: url != null && url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => placeholder,
                )
              : placeholder,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _userName ?? 'Player',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: dashText(isDark),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _isProMode ? 'PRO MEMBER' : 'MEMBER',
                style: dashLabel(isDark, size: 9.5).copyWith(
                  color: _isProMode
                      ? const Color(0xFFD4A017)
                      : dashMuted(isDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<MenuButton> _getMenuButtons() {
    return [
      MenuButton(
        title: 'Dashboard',
        icon: Icons.dashboard,
        onTap: () => _onTap(0),
      ),
      MenuButton(
        title: 'Statistics',
        icon: Icons.bar_chart,
        onTap: () => _onTap(1),
      ),
      MenuButton(
        title: 'Performance Report',
        icon: Icons.analytics_outlined,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PerformanceReportScreen(),
            ),
          );
        },
      ),
      MenuButton(
        title: 'Enter Stats',
        icon: Icons.add_circle,
        onTap: () => _onTap(2),
      ),
      MenuButton(title: 'History', icon: Icons.history, onTap: () => _onTap(3)),
      MenuButton(title: 'Account', icon: Icons.person, onTap: () => _onTap(4)),
    ];
  }
}

class _SlidingPillNavigationBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<IconData> items;
  final List<String> labels;
  final bool isExpanded;

  const _SlidingPillNavigationBar({
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    required this.labels,
    required this.isExpanded,
  });

  @override
  State<_SlidingPillNavigationBar> createState() =>
      _SlidingPillNavigationBarState();
}

class _SlidingPillNavigationBarState extends State<_SlidingPillNavigationBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450), // medium speed
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant _SlidingPillNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          6,
        ), // lift slightly; reduce bottom gap
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double barHeight = widget.isExpanded ? 78 : 64;
            const double horizontalPadding = 12;
            final double slotWidth =
                (constraints.maxWidth - horizontalPadding * 2) /
                widget.items.length;
            final double indicatorWidth = slotWidth * 0.86;
            final double indicatorHeight = barHeight - 12;

            // The + tab draws its own filled circle, so no pill behind it.
            final bool hidePill =
                widget.items[widget.selectedIndex] == Icons.add;

            double xForIndex(int index) =>
                horizontalPadding +
                slotWidth * index +
                (slotWidth - indicatorWidth) / 2;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutQuad,
              height: barHeight,
              child: Stack(
                children: [
                  // Floating oval background (dynamic-island style)
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOutQuad,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF111214) : Colors.white,
                        borderRadius: BorderRadius.circular(barHeight / 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.5 : 0.08,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.04),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                    ),
                  ),

                  // Motion-blur trailing pill (fake motion blur by blur + opacity)
                  if (!hidePill)
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        final double t = _animation.value;
                        final double left = lerpDouble(
                          xForIndex(_previousIndex),
                          xForIndex(widget.selectedIndex),
                          t,
                        )!;
                        return Positioned(
                          left: left,
                          top: (barHeight - indicatorHeight) / 2,
                          width: indicatorWidth,
                          height: indicatorHeight,
                          child: Opacity(
                            opacity:
                                (1.0 - t) * 0.35, // fades out as it catches up
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 10,
                                sigmaY: 10,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: _navFill().withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(
                                    indicatorHeight / 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  // Main sliding pill indicator
                  if (!hidePill)
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        final double t = _animation.value;
                        final double left = lerpDouble(
                          xForIndex(_previousIndex),
                          xForIndex(widget.selectedIndex),
                          t,
                        )!;
                        return Positioned(
                          left: left,
                          top: (barHeight - indicatorHeight) / 2,
                          width: indicatorWidth,
                          height: indicatorHeight,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _navFill(),
                              borderRadius: BorderRadius.circular(
                                indicatorHeight / 2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  // Icons row
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (int i = 0; i < widget.items.length; i++)
                            _NavItem(
                              icon: widget.items[i],
                              label: widget.labels[i],
                              isSelected: i == widget.selectedIndex,
                              onTap: () => widget.onItemSelected(i),
                              scale: widget.isExpanded ? 1.08 : 0.95,
                              isPrimary: widget.items[i] == Icons.add,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Deep rank color (or brand blue) so white nav icons stay readable on pale tiers.
Color _navFill() => RankAccent.instance.tier?.deep ?? const Color(0xFF2563eb);

Color _navLabel(bool isDark) => RankAccent.instance.color(isDark) ?? const Color(0xFF2563eb);

List<Color> _navGlow() {
  final t = RankAccent.instance.tier;
  if (t == null) {
    return const [Color(0xFF1D4ED8), Color(0xFF60A5FA), Color(0xFFBFDBFE), Color(0xFF3B82F6), Color(0xFF1D4ED8)];
  }
  return [t.deep, t.bright, Color.lerp(t.bright, Colors.white, 0.6)!, t.bright, t.deep];
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double scale;

  /// The central "enter stats" action, drawn with a rainbow glow ring.
  final bool isPrimary;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.scale = 1.0,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color unselectedColor = theme.colorScheme.onSurface.withOpacity(0.5);

    final Color labelColor = isSelected
        ? (isPrimary ? _navLabel(isDark) : Colors.white)
        : unselectedColor;
    Widget content = Icon(
      icon,
      size: 24,
      color: isSelected ? Colors.white : unselectedColor,
    );
    if (isPrimary && isSelected) {
      content = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _navFill(),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      );
    } else if (isPrimary) {
      content = RainbowGlow(
        radius: 16,
        borderWidth: 2,
        blurSigma: 8,
        glowOpacity: isDark ? 0.6 : 0.45,
        colors: _navGlow(),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? _navFill()
                : (isDark ? const Color(0xFF111214) : Colors.white),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      );
    }

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(1000),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: SizedBox(
          height: 68,
          child: Center(
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 32, child: Center(child: content)),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
