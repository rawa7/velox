import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/onboarding_slide_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'main_navigation.dart';
import 'welcome_screen.dart';

/// Next / Get Started and page-indicator accent on onboarding.
const Color _onboardingAccent = Color(0xFF062A69);
const Color _onboardingTitleColor = Color(0xFF042B6A);
const Color _onboardingBodyColor = Color(0xFF132453);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.exitToMain = false});

  /// After login/signup: go to [MainNavigation] when done instead of [WelcomeScreen].
  final bool exitToMain;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  List<OnboardingSlide> _slides = [];
  bool _loading = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadSlides();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSlides() async {
    final result = await ApiService.getOnboardingSlides();
    if (mounted) {
      setState(() {
        _slides = result['success'] == true
            ? List<OnboardingSlide>.from(result['slides'])
            : _fallbackSlides();
        _loading = false;
      });
    }
  }

  List<OnboardingSlide> _fallbackSlides() {
    return [
      const OnboardingSlide(
        id: 1,
        slideOrder: 1,
        imageUrl: null,
        titleEn: 'Welcome',
        titleKu: 'بخێربێیت',
        titleAr: 'مرحباً',
        bodyEn: 'Welcome to Velox Shopping',
        bodyKu: 'بخێربێیت بۆ ڤێلۆکس',
        bodyAr: 'مرحباً بك في فيلوكس',
      ),
      const OnboardingSlide(
        id: 2,
        slideOrder: 2,
        imageUrl: null,
        titleEn: 'Track Orders',
        titleKu: 'شوێنکردنی داواکاری',
        titleAr: 'تتبع الطلبات',
        bodyEn: 'Track all your orders easily',
        bodyKu: 'بە ئاسانی هەموو داواکارییەکانت بشوێنبکەوە',
        bodyAr: 'تتبع جميع طلباتك بسهولة',
      ),
      const OnboardingSlide(
        id: 3,
        slideOrder: 3,
        imageUrl: null,
        titleEn: 'Fast Delivery',
        titleKu: 'گەیاندنی خێرا',
        titleAr: 'توصيل سريع',
        bodyEn: 'Fast and reliable delivery to your door',
        bodyKu: 'گەیاندنی خێرا و متمانەپێکراو بۆ دەرگاکەت',
        bodyAr: 'توصيل سريع وموثوق إلى بابك',
      ),
    ];
  }

  Future<void> _finish() async {
    await StorageService.setOnboardingSeen();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            widget.exitToMain ? const MainNavigation() : const WelcomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _prev() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Swipe on the Next / Get Started control (LTR: left = forward, right = back; mirrored in RTL).
  void _onNextButtonHorizontalDragEnd(DragEndDetails details) {
    final dx = details.velocity.pixelsPerSecond.dx;
    const threshold = 180.0;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    if (rtl) {
      if (dx > threshold) {
        _next();
      } else if (dx < -threshold) {
        _prev();
      }
    } else {
      if (dx < -threshold) {
        _next();
      } else if (dx > threshold) {
        _prev();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;

    if (_loading) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.background : LightColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: _onboardingAccent),
        ),
      );
    }

    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : LightColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: skip
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot indicator top-left
                  _DotsIndicator(
                    count: _slides.length,
                    current: _currentPage,
                    accent: _onboardingAccent,
                  ),
                  // Skip stays in layout on last slide (invisible) so bar height does not jump.
                  Opacity(
                    opacity: isLast ? 0.0 : 1.0,
                    child: IgnorePointer(
                      ignoring: isLast,
                      child: GestureDetector(
                        onTap: _finish,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surface
                                : LightColors.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textSecondary
                                  : LightColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  return _SlidePage(
                    slide: _slides[index],
                    languageCode: locale,
                    isDark: isDark,
                  );
                },
              ),
            ),

            // Navigation buttons
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
              child: Row(
                children: [
                  // Previous
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prev,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: const BorderSide(
                              color: _onboardingAccent, width: 1.5),
                        ),
                        child: const Text(
                          'Previous',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _onboardingAccent,
                          ),
                        ),
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),

                  if (_currentPage > 0) const SizedBox(width: 14),

                  // Next / Get Started — tap or horizontal fling (see [_onNextButtonHorizontalDragEnd]).
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragEnd: _onNextButtonHorizontalDragEnd,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: _onboardingAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isLast ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
}

// ─── Single slide page ──────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  final OnboardingSlide slide;
  final String languageCode;
  final bool isDark;

  const _SlidePage({
    required this.slide,
    required this.languageCode,
    required this.isDark,
  });

  bool get _isRtl => languageCode == 'ar' || languageCode == 'fa';

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final imageMaxW = mq.width * 0.52;
    final imageMaxH = mq.height * 0.20;
    final bodyFontFamily = languageCode == 'en' ? 'CanvaSans' : 'DroidKufi';

    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: mq.height * 0.08),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: imageMaxW,
                  height: imageMaxH,
                  child: _SlideImage(
                    imageUrl: slide.imageUrl,
                    isDark: isDark,
                    slideOrder: slide.slideOrder,
                    maxWidth: imageMaxW,
                    maxHeight: imageMaxH,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 58),

            // Title — Droid Arabic Kufi Bold for all locales
            Text(
              slide.titleFor(languageCode),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DroidKufiBold',
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: _onboardingTitleColor,
                height: 1.28,
              ),
            ),
            const SizedBox(height: 20),

            // Body — Canva Sans (EN) / Droid Kufi (AR, Kurdish)
            Text(
              slide.bodyFor(languageCode),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: bodyFontFamily,
                fontSize: languageCode == 'en' ? 20 : 18,
                color: _onboardingBodyColor,
                height: 1.5,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// ─── Slide image / placeholder ───────────────────────────────────────────────

class _SlideImage extends StatelessWidget {
  final String? imageUrl;
  final bool isDark;
  final int slideOrder;
  final double maxWidth;
  final double maxHeight;

  const _SlideImage({
    this.imageUrl,
    required this.isDark,
    required this.slideOrder,
    required this.maxWidth,
    required this.maxHeight,
  });

  static const _placeholderIcons = [
    Icons.local_shipping_rounded,
    Icons.track_changes_rounded,
    Icons.flash_on_rounded,
  ];

  IconData get _icon =>
      _placeholderIcons[(slideOrder - 1).clamp(0, _placeholderIcons.length - 1)];

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    final fallbackSize = math.min(
      math.min(maxWidth * 0.92, maxHeight * 0.95),
      math.min(mq.width * 0.36, mq.height * 0.14),
    );
    final cardBg = isDark ? AppColors.surface : LightColors.surface;
    final w = maxWidth;
    final h = maxHeight;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Align(
          alignment: Alignment.topCenter,
          child: Image.network(
            imageUrl!,
            width: w,
            height: h,
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => _placeholder(
              fallbackSize,
              cardBg,
              Icons.image_not_supported_rounded,
            ),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                width: w,
                height: h,
                child: const Center(
                  child: CircularProgressIndicator(color: _onboardingAccent),
                ),
              );
            },
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: _placeholder(fallbackSize, cardBg, _icon),
    );
  }

  Widget _placeholder(double size, Color bg, IconData icon) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _onboardingAccent.withValues(alpha: 0.12),
            AppColors.secondary.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(
        child: Icon(icon, size: size * 0.38, color: _onboardingAccent),
      ),
    );
  }
}

// ─── Dots indicator ──────────────────────────────────────────────────────────

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int current;
  final Color accent;

  const _DotsIndicator({
    required this.count,
    required this.current,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? accent : accent.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
