import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'constants/app_colors.dart';
import 'utils/app_theme.dart';
import 'services/language_service.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';
import 'screens/main_navigation.dart';
import 'screens/language_selection_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'generated/app_localizations.dart';

// Firebase imports - commented out until configured
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'services/firebase_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  
  // TODO: Uncomment when Firebase is configured
  // try {
  //   await Firebase.initializeApp();
  //   FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  //   await FirebaseNotificationService().initialize();
  // } catch (e) {
  //   debugPrint('Firebase initialization failed: $e');
  // }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  static void setThemeMode(BuildContext context, ThemeMode mode) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setThemeMode(mode);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
    _loadSavedTheme();
  }

  Future<void> _loadSavedLanguage() async {
    final locale = await LanguageService.getSelectedLanguage();
    if (mounted) setState(() => _locale = locale);
  }

  Future<void> _loadSavedTheme() async {
    final mode = await ThemeService.getSavedTheme();
    if (mounted) {
      setState(() => _themeMode = mode);
      _applySystemUiOverlay(mode);
    }
  }

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    ThemeService.saveTheme(mode);
    _applySystemUiOverlay(mode);
  }

  void _applySystemUiOverlay(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDark ? AppColors.background : LightColors.background,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Velox',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('fa'),
      ],
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final initialLaunchDone = await StorageService.hasCompletedInitialLaunch();
    final isLoggedIn = await StorageService.isLoggedIn();

    if (!mounted) return;

    Widget destination;
    if (!initialLaunchDone) {
      destination = const LanguageSelectionScreen();
    } else if (isLoggedIn) {
      destination = const MainNavigation();
    } else {
      final seenOnboarding = await StorageService.hasSeenOnboarding();
      destination = seenOnboarding
          ? const WelcomeScreen()
          : const OnboardingScreen(exitToMain: false);
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Sampled from corner pixels of `assets/logo.png` (same as the logo’s flat canvas).
  static const Color _splashLogoBackground = Color(0xFFF8F2DA);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    // Large mark: most of the screen width, capped for tablets.
    final logoSize = (w * 0.72).clamp(260.0, 360.0);

    return Scaffold(
      backgroundColor: _splashLogoBackground,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.local_shipping_rounded,
                    size: logoSize * 0.65,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: logoSize * 0.14),
                SizedBox(
                  width: 38,
                  height: 38,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
