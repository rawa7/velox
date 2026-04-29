import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/language_flag_asset.dart';
import '../main.dart';
import '../services/language_service.dart';
import '../services/storage_service.dart';
import 'onboarding_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  /// Default to English so the first option matches the highlighted state in onboarding.
  String? _selectedCode = 'en';
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  /// Order: English, Kurdish, Arabic.
  final _languages = [
    _LangOption(
      code: 'en',
      label: 'English',
      nativeLabel: 'English',
      flag: '🇬🇧',
      flagImagePath: 'assets/flag_gb.png',
      textDir: TextDirection.ltr,
    ),
    _LangOption(
      code: 'fa',
      label: 'Kurdish',
      nativeLabel: 'کوردی',
      flag: '🏳️',
      flagImagePath: 'assets/Flag_of_Kurdistan.png',
      textDir: TextDirection.rtl,
    ),
    _LangOption(
      code: 'ar',
      label: 'Arabic',
      nativeLabel: 'العربية',
      flag: '🇮🇶',
      flagImagePath: 'assets/flag_iq.png',
      textDir: TextDirection.rtl,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_selectedCode == null) return;
    await LanguageService.setLanguage(_selectedCode!);
    await StorageService.setInitialLaunchComplete();
    if (!mounted) return;
    MyApp.setLocale(context, Locale(_selectedCode!));
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const OnboardingScreen(exitToMain: false),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : LightColors.background;
    final cardBg = isDark ? AppColors.surface : LightColors.surface;
    final textPrimary =
        isDark ? AppColors.textPrimary : LightColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : LightColors.textSecondary;
    final headlineColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      body: FadeTransition(
        opacity: _fadeIn,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 1),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = MediaQuery.sizeOf(context).width;
                    final logoSize = (w * 0.62).clamp(200.0, 300.0);
                    final headlineSize = (logoSize * 0.085).clamp(16.0, 20.0);
                    return Column(
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.local_shipping_rounded,
                            size: logoSize * 0.75,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: logoSize * 0.06),
                        Text(
                          'Choose your language:',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: headlineSize,
                            fontWeight: FontWeight.w700,
                            color: headlineColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const Spacer(flex: 2),
                // Language cards
                ...List.generate(_languages.length, (i) {
                  final lang = _languages[i];
                  final selected = _selectedCode == lang.code;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _LanguageCard(
                      lang: lang,
                      selected: selected,
                      cardBg: cardBg,
                      textPrimary: textPrimary,
                      onTap: () => setState(() => _selectedCode = lang.code),
                    ),
                  );
                }),
                const Spacer(flex: 3),
                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _selectedCode != null ? _confirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                          isDark ? AppColors.surfaceLight : LightColors.border,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _selectedCode != null
                            ? Colors.white
                            : textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final _LangOption lang;
  final bool selected;
  final Color cardBg;
  final Color textPrimary;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.lang,
    required this.selected,
    required this.cardBg,
    required this.textPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.12)
              : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            LanguageFlagAsset(
              assetPath: lang.flagImagePath,
              fallback: Center(
                child: Text(lang.flag, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.nativeLabel,
                    textDirection: lang.textDir,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.primary : textPrimary,
                    ),
                  ),
                  Text(
                    lang.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selected
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 24, key: ValueKey(true))
                  : const SizedBox(width: 24, key: ValueKey(false)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangOption {
  final String code;
  final String label;
  final String nativeLabel;
  final String flag;
  /// Shown as fallback if the PNG fails to load.
  final String flagImagePath;
  final TextDirection textDir;

  const _LangOption({
    required this.code,
    required this.label,
    required this.nativeLabel,
    required this.flag,
    required this.flagImagePath,
    required this.textDir,
  });
}
