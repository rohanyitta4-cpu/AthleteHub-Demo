import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme_provider.dart';
import '../services/enter_stats_navigator.dart';
import '../utils/responsive_helper.dart';
import '../widgets/haptic_helper.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();

  static const _keyCompleted = 'has_completed_onboarding';

  /// Persisted until first account sign-up; used when creating the first season.
  static const String pendingSeasonNamePrefKey = 'onboarding_pending_season_name';

  /// Whether the user has finished onboarding (first launch only; never re-shown).
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCompleted) ?? false;
  }

  static Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCompleted, true);
  }
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String _prefThemeId = 'light_bw';
  String _prefEntryMode = EnterStatsNavigator.flashcardMode;
  late final TextEditingController _seasonNameController;

  // Main page animation controller
  late AnimationController _pageAnimationController;
  late Animation<double> _pageAnimation;

  static const Color _zunoGreen = Color(0xFF10B981);
  static const Color _zunoTeal = Color(0xFF14B8A6);
  static const Color _zunoDark = Color(0xFF0D9668);

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: "Track Every Moment",
      description: "Log your stats in seconds and watch your progress unfold. Never lose a at-bat or inning again—everything in one place.",
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_zunoDark, _zunoGreen],
      ),
      demoWidget: _buildTrackingDemo,
    ),
    OnboardingPageData(
      title: "Zuno, Your AI Coach",
      description: "Just say \"I went 2 for 3 with a double\" and Zuno updates your stats instantly. Get personalized tips and feedback to level up your game.",
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_zunoGreen, _zunoTeal],
      ),
      demoWidget: _buildAIChatDemo,
    ),
    OnboardingPageData(
      title: "Visualize Your Growth",
      description: "See where you're improving and where to focus next. Charts and insights reveal patterns that help you make smarter decisions.",
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_zunoTeal, Color(0xFF0EA5E9)],
      ),
      demoWidget: _buildAnalyticsDemo,
    ),
    OnboardingPageData(
      title: "Your preferences",
      description: "Name your season, then choose how the app looks and how you enter stats. You can change these later in settings.",
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF404040), Color(0xFF0A0A0A)],
      ),
      isPreferencesStep: true,
    ),
    OnboardingPageData(
      title: "Ready to Dominate?",
      description: "Your best season starts now. Sign in or create an account and start tracking in under a minute.",
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_zunoGreen, _zunoDark],
      ),
      demoWidget: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _seasonNameController = TextEditingController(
      text: '${DateTime.now().year} Season',
    );

    // Use single animation controller to prevent native crashes
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200), // Slower for better visibility
      vsync: this,
    );

    _pageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageAnimationController, curve: Curves.easeOut),
    );

    // Start animation after a small delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pageAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    // Stop animation before disposing
    try {
      _pageAnimationController.stop();
    } catch (e) {
      // Ignore errors during disposal
    }
    
    _pageController.dispose();
    _pageAnimationController.dispose();
    _seasonNameController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (!mounted) return;
    HapticHelper.selection();
    setState(() {
      _currentPage = index;
    });
    if (mounted) {
      _pageAnimationController.reset();
      _pageAnimationController.forward();
    }
  }

  Future<void> _handleComplete() async {
    if (!mounted) return;
    HapticHelper.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    final themeId = canonicalThemeId(_prefThemeId);
    await prefs.setString('currentTheme', themeId);
    await EnterStatsNavigator.setEntryMode(_prefEntryMode);
    final seasonName = _seasonNameController.text.trim();
    if (seasonName.isNotEmpty) {
      await prefs.setString(OnboardingScreen.pendingSeasonNamePrefKey, seasonName);
    } else {
      await prefs.remove(OnboardingScreen.pendingSeasonNamePrefKey);
    }
    if (mounted) {
      try {
        Provider.of<ThemeProvider>(context, listen: false).setTheme(themeId);
      } catch (_) {}
    }
    await OnboardingScreen.setOnboardingComplete();
    if (mounted) {
      widget.onComplete();
    }
  }

  void _skipOnboarding() {
    _handleComplete();
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) {
      return const SizedBox.shrink();
    }
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final responsive = ResponsiveHelper(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (_currentPage < _pages.length - 1)
              Padding(
                padding: EdgeInsets.only(
                  top: responsive.spacingMedium,
                  right: responsive.spacingMedium,
                  left: responsive.spacingMedium,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      HapticHelper.lightImpact();
                      _skipOnboarding();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacingMedium,
                        vertical: responsive.spacingSmall,
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.inter(
                        fontSize: responsive.fontSizeMedium,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], isDark, responsive);
                },
              ),
            ),

            // Page indicator
            Padding(
              padding: EdgeInsets.symmetric(vertical: responsive.spacingMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  final isCompleted = index <= _currentPage;
                  final fillColor = isCompleted ? Colors.black : Colors.white;
                  final outlineColor = isCompleted
                      ? Colors.black
                      : (isDark ? Colors.grey[500]! : Colors.grey[400]!);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.symmetric(
                      horizontal: responsive.spacingXSmall / 2,
                    ),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: fillColor,
                      border: Border.all(
                        color: outlineColor,
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Get started only on the last page.
            if (_currentPage >= _pages.length - 1)
              Padding(
                padding: EdgeInsets.only(
                  top: responsive.spacingSmall,
                  bottom: responsive.spacingLarge,
                ),
                child: _AnimatedActionButton(
                  isLastPage: true,
                  onPressed: _handleComplete,
                  theme: theme,
                  responsive: responsive,
                  vsync: this,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPageData pageData, bool isDark, ResponsiveHelper responsive) {
    if (!mounted) {
      return const SizedBox.shrink();
    }
    
    // Use opacity fade with proper structure
    return FadeTransition(
      opacity: _pageAnimation,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: responsive.spacingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: responsive.spacingLarge),
              
              // Gradient header with illustration
              Container(
                width: double.infinity,
                height: responsive.screenHeight * 0.30, // Further reduced to prevent overflow
                decoration: BoxDecoration(
                  gradient: pageData.gradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: pageData.gradient.colors.first.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Decorative elements
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    // Content
                    if (pageData.isPreferencesStep)
                      Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            vertical: responsive.spacingSmall,
                            horizontal: responsive.spacingSmall,
                          ),
                          child: _buildPreferencesControls(isDark, responsive),
                        ),
                      )
                    else if (pageData.demoWidget != null)
                      Center(
                        child: AnimatedBuilder(
                          animation: _pageAnimation,
                          builder: (context, child) {
                            if (!context.mounted) {
                              return const SizedBox.shrink();
                            }
                            return pageData.demoWidget!(
                              context, 
                              isDark, 
                              responsive, 
                              pageData.gradient,
                              _pageAnimation,
                            );
                          },
                        ),
                      )
                    else
                      Center(
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: responsive.spacingXLarge * 1.5),

              // Title
              Text(
                pageData.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: responsive.fontSizeXXLarge,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),

              SizedBox(height: responsive.spacingMedium),

              // Description
              Text(
                pageData.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: responsive.fontSizeBody,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.6,
                ),
              ),

              SizedBox(height: responsive.spacingXLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesControls(bool isDark, ResponsiveHelper responsive) {
    final inputFill = Colors.white.withValues(alpha: 0.12);
    final inputBorder = Colors.white.withValues(alpha: 0.35);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.spacingMedium),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Season name',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: responsive.spacingSmall),
          TextField(
            controller: _seasonNameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'e.g. Spring ${DateTime.now().year}',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.45),
              ),
              filled: true,
              fillColor: inputFill,
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.spacingMedium,
                vertical: responsive.spacingSmall,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white, width: 1.5),
              ),
            ),
          ),
          SizedBox(height: responsive.spacingLarge),
          Text(
            'Appearance',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: responsive.spacingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _prefChip(
                label: 'Light',
                selected: _prefThemeId == 'light_bw',
                onTap: () => setState(() => _prefThemeId = 'light_bw'),
              ),
              SizedBox(width: responsive.spacingSmall),
              _prefChip(
                label: 'Dark',
                selected: _prefThemeId == 'dark_bw_simple',
                onTap: () => setState(() => _prefThemeId = 'dark_bw_simple'),
              ),
            ],
          ),
          SizedBox(height: responsive.spacingLarge),
          Text(
            'Enter stats',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: responsive.spacingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _prefChip(
                label: 'Flashcards',
                selected: _prefEntryMode == EnterStatsNavigator.flashcardMode,
                onTap: () => setState(() => _prefEntryMode = EnterStatsNavigator.flashcardMode),
              ),
              SizedBox(width: responsive.spacingSmall),
              _prefChip(
                label: 'Form',
                selected: _prefEntryMode == EnterStatsNavigator.formMode,
                onTap: () => setState(() => _prefEntryMode = EnterStatsNavigator.formMode),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _prefChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticHelper.selection();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: selected ? 0.9 : 0.35)),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.black87 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildTrackingDemo(BuildContext context, bool isDark, ResponsiveHelper responsive, Gradient gradient, Animation<double> animation) {
    return Container(
      width: responsive.screenWidth * 0.75,
      height: responsive.screenHeight * 0.28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(responsive.spacingSmall), // Reduced padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnimatedStatCard('AVG', '.315', gradient, animation, 0.0),
                _buildAnimatedStatCard('H', '45', gradient, animation, 0.1),
                _buildAnimatedStatCard('AB', '142', gradient, animation, 0.2),
              ],
            ),
            SizedBox(height: responsive.spacingXSmall), // Reduced spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnimatedStatCard('HR', '8', gradient, animation, 0.3),
                _buildAnimatedStatCard('RBI', '32', gradient, animation, 0.4),
                _buildAnimatedStatCard('SB', '12', gradient, animation, 0.5),
              ],
            ),
            SizedBox(height: responsive.spacingSmall), // Reduced spacing
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacingSmall,
                vertical: responsive.spacingXSmall / 2, // Further reduced
              ),
              decoration: BoxDecoration(
                color: gradient.colors.first.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up, size: 14, color: gradient.colors.first), // Smaller icon
                  const SizedBox(width: 4),
                  Text(
                    'Season stats tracked',
                    style: GoogleFonts.inter(
                      fontSize: 10, // Reduced font size
                      fontWeight: FontWeight.w500,
                      color: gradient.colors.first,
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

  static Widget _buildStatCard(String label, String value, Gradient gradient) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), // Reduced padding
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20, // Slightly smaller
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6), // Reduced spacing
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9, // Further reduced
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  static Widget _buildAnimatedStatCard(String label, String value, Gradient gradient, Animation<double> animation, double delay) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Check if context is still valid (widget not disposed)
        if (!context.mounted) {
          return const SizedBox.shrink();
        }
        
        // Slower animation - use smaller delay multiplier for smoother stagger
        final adjustedDelay = delay * 0.4; // Reduce delay to make animation slower/more visible
        final animatedValue = ((animation.value - adjustedDelay) / (1.0 - adjustedDelay)).clamp(0.0, 1.0);
        final scale = Curves.easeOutBack.transform(animatedValue);
        final opacity = Curves.easeOut.transform(animatedValue);
        
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: _buildStatCard(label, value, gradient),
          ),
        );
      },
    );
  }

  static Widget _buildAIChatDemo(BuildContext context, bool isDark, ResponsiveHelper responsive, Gradient gradient, Animation<double> animation) {
    return Container(
      width: responsive.screenWidth * 0.75,
      height: responsive.screenHeight * 0.28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(responsive.spacingMedium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // User message (appears first)
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                if (!context.mounted) {
                  return const SizedBox.shrink();
                }
                final userOpacity = (animation.value * 2).clamp(0.0, 1.0);
                return Opacity(
                  opacity: userOpacity,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - userOpacity)),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: responsive.screenWidth * 0.5),
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.spacingMedium,
                          vertical: responsive.spacingSmall,
                        ),
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        child: Text(
                          'I went 2 for 3 with a double',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: responsive.spacingSmall),
            // AI response - single message (stat logging with tip)
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                if (!context.mounted) {
                  return const SizedBox.shrink();
                }
                const aiDelay = 0.2;
                final aiProgress = ((animation.value - aiDelay) / (1.0 - aiDelay)).clamp(0.0, 1.0);
                final aiOpacity = Curves.easeOut.transform(aiProgress);
                const fullResponse = 'Logging your stats, your contact has been improving.';
                final typedLength = (fullResponse.length * aiProgress).round();
                final displayedText = fullResponse.substring(0, typedLength.clamp(0, fullResponse.length));
                
                return Opacity(
                  opacity: aiOpacity,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - aiProgress)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: gradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.smart_toy,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: responsive.spacingSmall),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(responsive.spacingMedium),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    displayedText,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                                if (typedLength < fullResponse.length && animation.value > aiDelay)
                                  Container(
                                    width: 2,
                                    height: 16,
                                    margin: const EdgeInsets.only(left: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildAnalyticsDemo(BuildContext context, bool isDark, ResponsiveHelper responsive, Gradient gradient, Animation<double> animation) {
    return Container(
      width: responsive.screenWidth * 0.75,
      height: responsive.screenHeight * 0.28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(responsive.spacingMedium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Chart type selector mock
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChartTypeChip('Line', true, gradient),
                const SizedBox(width: 8),
                _buildChartTypeChip('Bar', false, gradient),
                const SizedBox(width: 8),
                _buildChartTypeChip('Heatmap', false, gradient),
              ],
            ),
            SizedBox(height: responsive.spacingMedium),
            // Multi-chart preview
            Expanded(
              child: Row(
                children: [
                  // Line chart preview
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Batting Avg',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              if (!context.mounted) {
                                return const SizedBox.shrink();
                              }
                              return CustomPaint(
                                painter: _LineChartPainter(
                                  data: [0.250, 0.280, 0.265, 0.310, 0.295, 0.315],
                                  color: gradient.colors.first,
                                  progress: animation.value,
                                ),
                                child: Container(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bar chart preview
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Home Runs',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              if (!context.mounted) {
                                return const SizedBox.shrink();
                              }
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildAnimatedChartBar(0.3, gradient, animation, 0.0),
                                  _buildAnimatedChartBar(0.5, gradient, animation, 0.1),
                                  _buildAnimatedChartBar(0.4, gradient, animation, 0.2),
                                  _buildAnimatedChartBar(0.7, gradient, animation, 0.3),
                                  _buildAnimatedChartBar(0.6, gradient, animation, 0.4),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.spacingSmall),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacingMedium,
                vertical: responsive.spacingSmall / 2,
              ),
              decoration: BoxDecoration(
                color: gradient.colors.first.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insights, size: 16, color: gradient.colors.first),
                  const SizedBox(width: 4),
                  Text(
                    'Multiple chart types available',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: gradient.colors.first,
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

  static Widget _buildChartTypeChip(String label, bool isSelected, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected 
            ? gradient.colors.first 
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
      ),
    );
  }

  static Widget _buildAnimatedChartBar(double height, Gradient gradient, Animation<double> animation, double delay) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        if (!context.mounted) {
          return const SizedBox.shrink();
        }
        // Slower bar animation - use smaller delay multiplier
        final adjustedDelay = delay * 0.3; // Reduce delay to make animation slower/more visible
        final barProgress = ((animation.value - adjustedDelay) / (1.0 - adjustedDelay)).clamp(0.0, 1.0);
        final animatedHeight = height * Curves.easeOutCubic.transform(barProgress);
        
        return Container(
          width: 16,
          height: 50 * animatedHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: gradient.colors,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}

// Line chart painter for the preview
class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double progress;

  _LineChartPainter({required this.data, required this.color, this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    if (range == 0) return;

    final visiblePoints = (data.length * progress).ceil();
    
    for (int i = 0; i < visiblePoints; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minValue) / range) * size.height * 0.8 - size.height * 0.1;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Animate the line drawing
        final segmentProgress = (progress * data.length - i).clamp(0.0, 1.0);
        if (segmentProgress > 0) {
          final prevX = ((i - 1) / (data.length - 1)) * size.width;
          final prevY = size.height - ((data[i - 1] - minValue) / range) * size.height * 0.8 - size.height * 0.1;
          final currentX = prevX + (x - prevX) * Curves.easeOut.transform(segmentProgress);
          final currentY = prevY + (y - prevY) * Curves.easeOut.transform(segmentProgress);
          path.lineTo(currentX, currentY);
        }
      }

      // Draw point only if segment is fully animated
      if (i < visiblePoints - 1 || (i == visiblePoints - 1 && progress >= i / data.length)) {
        canvas.drawCircle(Offset(x, y), 3, Paint()..color = color..style = PaintingStyle.fill);
      }
    }

    if (visiblePoints > 0) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! _LineChartPainter) return true;
    return oldDelegate.progress != progress;
  }
}

// Animated Back Button with better lifecycle management
class _AnimatedBackButton extends StatefulWidget {
  final VoidCallback onPressed;
  final ThemeData theme;
  final ResponsiveHelper responsive;
  final TickerProvider vsync;

  const _AnimatedBackButton({
    required this.onPressed,
    required this.theme,
    required this.responsive,
    required this.vsync,
  });

  @override
  State<_AnimatedBackButton> createState() => _AnimatedBackButtonState();
}

class _AnimatedBackButtonState extends State<_AnimatedBackButton> {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300), // Slower for better visibility
      vsync: widget.vsync,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (mounted) _controller.forward();
      },
      onTapUp: (_) {
        if (mounted) {
          _controller.reverse();
          widget.onPressed();
        }
      },
      onTapCancel: () {
        if (mounted) _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          if (!mounted) return const SizedBox.shrink();
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.responsive.spacingLarge,
                vertical: widget.responsive.spacingMedium,
              ),
              decoration: BoxDecoration(
                color: widget.theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: widget.theme.colorScheme.primary,
                  ),
                  SizedBox(width: widget.responsive.spacingSmall / 2),
                  Text(
                    'Back',
                    style: GoogleFonts.inter(
                      fontSize: widget.responsive.fontSizeMedium,
                      fontWeight: FontWeight.w600,
                      color: widget.theme.colorScheme.primary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Animated Action Button with better lifecycle management
class _AnimatedActionButton extends StatefulWidget {
  final bool isLastPage;
  final VoidCallback onPressed;
  final ThemeData theme;
  final ResponsiveHelper responsive;
  final TickerProvider vsync;

  const _AnimatedActionButton({
    required this.isLastPage,
    required this.onPressed,
    required this.theme,
    required this.responsive,
    required this.vsync,
  });

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton> {
  late AnimationController _controller;
  AnimationController? _pulseController; // Not late, can be null
  late Animation<double> _scaleAnimation;
  Animation<double>? _pulseAnimation; // Not late, can be null

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: widget.vsync,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    // Only create pulse controller for last page
    _initializePulseController();
  }
  
  void _initializePulseController() {
    if (widget.isLastPage && _pulseController == null) {
      _pulseController = AnimationController(
        duration: const Duration(milliseconds: 3000), // Slower pulse for better visibility
        vsync: widget.vsync,
      );
      _pulseAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
      _pulseController!.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_AnimatedActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mounted) return;
    
    if (widget.isLastPage != oldWidget.isLastPage) {
      if (widget.isLastPage) {
        _initializePulseController();
      } else if (_pulseController != null) {
        _pulseController!.stop();
        _pulseController!.dispose();
        _pulseController = null;
        _pulseAnimation = null;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animations = _pulseController != null 
        ? Listenable.merge([_controller, _pulseController!])
        : _controller;
        
    return GestureDetector(
      onTapDown: (_) {
        if (mounted) _controller.forward();
      },
      onTapUp: (_) {
        if (mounted) {
          _controller.reverse();
          widget.onPressed();
        }
      },
      onTapCancel: () {
        if (mounted) _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: animations,
        builder: (context, child) {
          if (!mounted) return const SizedBox.shrink();
          
          final scale = _scaleAnimation.value * 
              (widget.isLastPage && _pulseAnimation != null 
                  ? _pulseAnimation!.value 
                  : 1.0);
          
          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.theme.colorScheme.primary,
                    widget.theme.colorScheme.primary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.theme.colorScheme.primary.withValues(
                      alpha: widget.isLastPage && _pulseAnimation != null
                          ? 0.3 + (0.2 * _pulseAnimation!.value)
                          : 0.3,
                    ),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.responsive.spacingXLarge,
                      vertical: widget.responsive.spacingMedium,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.isLastPage ? 'Get Started' : 'Next',
                          style: GoogleFonts.inter(
                            fontSize: widget.responsive.fontSizeMedium,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(width: widget.responsive.spacingSmall),
                        Icon(
                          widget.isLastPage ? Icons.rocket_launch : Icons.arrow_forward_ios,
                          size: widget.isLastPage ? 20 : 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final LinearGradient gradient;
  final Widget Function(BuildContext, bool, ResponsiveHelper, Gradient, Animation<double>)? demoWidget;
  final bool isPreferencesStep;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.gradient,
    this.demoWidget,
    this.isPreferencesStep = false,
  });
}
