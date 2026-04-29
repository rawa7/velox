import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../screens/main_navigation.dart';
import '../screens/onboarding_screen.dart';
import '../services/storage_service.dart';

/// After login or signup: main app, or onboarding first for non-silver users who have not seen slides.
abstract final class PostAuthNavigation {
  PostAuthNavigation._();

  static Future<Widget> _homeOrOnboarding(User user) async {
    if (user.isSilverAccount) {
      await StorageService.setOnboardingSeen();
      return const MainNavigation();
    }
    if (!await StorageService.hasSeenOnboarding()) {
      return const OnboardingScreen(exitToMain: true);
    }
    return const MainNavigation();
  }

  static Future<void> replaceFromLogin(BuildContext context, User user) async {
    if (!context.mounted) return;
    final next = await _homeOrOnboarding(user);
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => next),
    );
  }

  static Future<void> replaceStackFromSignup(BuildContext context, User user) async {
    if (!context.mounted) return;
    final next = await _homeOrOnboarding(user);
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => next),
      (_) => false,
    );
  }
}
