import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'theme_provider.dart';
import 'theme/rank_accent.dart';
import 'theme/zuno_colors.dart';
import 'theme/app_title_style.dart';

import 'stats_quiz_screen.dart';
import 'notification_service.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'main_navigation_screen.dart';
import 'simple_loading_screen.dart';
import 'performance_optimizations.dart';
import 'widgets/app_width_limit.dart';
import 'screens/team_selector.dart';
import 'screens/roster_editor.dart';
import 'screens/game_editor.dart';
import 'screens/team_analytics.dart';
import 'history_screen.dart';
import 'screens/personalization_screen.dart';
import 'services/baseball_migration_service.dart';
import 'screens/coach_navigation_screen.dart';
import 'screens/onboarding_screen.dart';

/// Brand accent used by legacy screens that still import [zunoGreen] from `main.dart`.
const Color zunoGreen = Color(0xFF10B981);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize performance optimizations
  PerformanceOptimizations.initialize();
  
  // Initialize Firebase with offline persistence
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
  await Firebase.initializeApp();
      debugPrint('Firebase initialized successfully');
    } else {
      debugPrint('Firebase already initialized: ${Firebase.apps.map((a) => a.name).toList()}');
    }
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    // Try to continue anyway - Firebase might still work if it was initialized elsewhere
    if (Firebase.apps.isEmpty) {
      rethrow; // Only rethrow if we truly failed to initialize
    }
  }
  
  // Enable offline persistence for Firestore
  try {
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  } catch (e) {
    debugPrint('Error setting Firestore settings: $e');
    // Continue without offline persistence if it fails
  }
  
  // Initialize notification service
  final notificationService = NotificationService();
  try {
  await notificationService.initialize();
  } catch (e) {
    debugPrint('Error initializing notification service: $e');
    // Continue without notifications if initialization fails
  }
  
  runApp(MyApp(notificationService: notificationService));
}

class AuthWrapper extends StatefulWidget {
  final NotificationService notificationService;

  const AuthWrapper({super.key, required this.notificationService});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _currentUser;
  bool _isLoading = true;
  bool _shouldShowOnboarding = true;
  bool _isCheckingOnboarding = true;
  late StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
    _setupAuthListener();
  }

  Future<void> _checkOnboardingStatus() async {
    final completed = await OnboardingScreen.hasCompletedOnboarding();
    if (mounted) {
      setState(() {
        // First install / first launch only — never re-show after completion.
        _shouldShowOnboarding = !completed;
        _isCheckingOnboarding = false;
      });
    }
  }

  void _setupAuthListener() {
    // Set initial user state immediately
    _currentUser = FirebaseAuth.instance.currentUser;
    _isLoading = false; // Don't show loading if user is already logged in
    
    debugPrint('AuthWrapper: Initial user state - User: ${_currentUser?.uid}');
    
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      debugPrint('AuthWrapper: Auth state changed - User: ${user?.uid}');
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking onboarding status
    if (_isLoading || _isCheckingOnboarding) {
      return const SimpleLoadingScreen(title: 'Loading...');
    }

    // User is authenticated - show main app
    if (_currentUser != null) {
      return MainNavigationScreen(notificationService: widget.notificationService);
    }

    // Show onboarding once per install, before login
    if (_shouldShowOnboarding) {
      return OnboardingScreen(
        onComplete: () {
          setState(() {
            _shouldShowOnboarding = false;
          });
        },
      );
    }

    return const LoginScreen();
  }
}

class MyApp extends StatefulWidget {
  final NotificationService notificationService;

  const MyApp({super.key, required this.notificationService});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = ThemeProvider();
    _themeProvider.loadThemePreference();
    RankAccent.instance.load();
    _checkAndRunMigration();
  }

  Future<void> _checkAndRunMigration() async {
    try {
      final needsMigration = await BaseballMigrationService.isMigrationNeeded();
      if (needsMigration) {
        debugPrint('Running baseball structure migration...');
        await BaseballMigrationService.migrateToBaseballStructure();
        debugPrint('Migration completed successfully');
      }
    } catch (e) {
      debugPrint('Migration failed: $e');
      // Don't crash the app if migration fails
    }
  }

  ThemeData _getThemeForCurrentSelection(String themeName) {
    final id = canonicalThemeId(themeName);
    switch (id) {
      case 'dark_bw_simple':
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: ZunoColors.darkBg,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.white,
            brightness: Brightness.dark,
            primary: Colors.white,
            secondary: Colors.grey[400]!,
            surface: ZunoColors.darkSurface,
            onPrimary: Colors.black,
            onSurface: Colors.white,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: ZunoColors.darkBg,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: appTitleStyle(color: Colors.white),
          ),
          textTheme: GoogleFonts.poppinsTextTheme().apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[300],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            hintStyle: GoogleFonts.poppins(color: Colors.black54),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        );
      default:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: ZunoColors.lightBg,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black,
            brightness: Brightness.light,
            primary: Colors.black,
            secondary: Colors.grey,
            tertiary: Colors.grey[800]!,
            surface: ZunoColors.lightSurface,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: ZunoColors.lightBg,
            foregroundColor: Colors.black,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            surfaceTintColor: Colors.transparent,
            titleTextStyle: appTitleStyle(color: Colors.black),
            iconTheme: const IconThemeData(color: Colors.black),
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
          textTheme: GoogleFonts.interTextTheme().apply(
            bodyColor: Colors.black,
            displayColor: Colors.black,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            labelStyle: GoogleFonts.inter(color: Colors.grey[700]),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _themeProvider,
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) => ListenableBuilder(
          listenable: RankAccent.instance,
          builder: (context, _) {
          final base = _getThemeForCurrentSelection(themeProvider.currentTheme);
          final rankColor = RankAccent.instance.color(base.brightness == Brightness.dark);
          final appTheme = base.copyWith(
            extensions: [RankAccentTheme(rankColor)],
            progressIndicatorTheme: rankColor == null ? null : ProgressIndicatorThemeData(color: rankColor),
            textSelectionTheme: rankColor == null
                ? null
                : TextSelectionThemeData(
                    cursorColor: rankColor,
                    selectionColor: rankColor.withValues(alpha: 0.3),
                    selectionHandleColor: rankColor,
                  ),
          );
          return MaterialApp(
            title: 'AthleteHub',
            debugShowCheckedModeBanner: false,
            builder: (context, child) => AppWidthLimit(
              backgroundColor: appTheme.scaffoldBackgroundColor,
              child: child ?? const SizedBox.shrink(),
            ),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/onboarding': (context) => OnboardingScreen(
                onComplete: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
              '/stats-quiz': (context) => const StatsQuizScreen(),
              '/dashboard': (context) => MainNavigationScreen(notificationService: widget.notificationService),
              '/team-selector': (context) => const TeamSelectorScreen(),
              '/coach-dashboard': (context) => const CoachNavigationScreen(),
              '/roster-editor': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                return RosterEditorScreen(
                  teamId: args['teamId'],
                  teamName: args['teamName'],
                );
              },
              '/game-editor': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                return GameEditorScreen(
                  teamId: args['teamId'],
                  seasonId: args['seasonId'],
                  teamName: args['teamName'],
                );
              },
              '/team-analytics': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                return TeamAnalyticsScreen(
                  teamId: args['teamId'],
                  seasonId: args['seasonId'],
                  teamName: args['teamName'],
                );
              },
              '/history': (context) => const HistoryScreen(),
              '/personalization': (context) => const PersonalizationScreen(),
            },
            theme: appTheme,
            home: AuthWrapper(
              notificationService: widget.notificationService,
            ),
          );
          },
        ),
      ),
    );
  }
}