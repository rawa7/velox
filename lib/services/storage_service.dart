import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _onboardingSeenKey = 'onboarding_seen';
  /// First-time language selection finished (splash no longer shows [LanguageSelectionScreen]).
  static const String _initialLaunchKey = 'initial_launch_complete';

  // Save user data
  static Future<bool> saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userKey, userJson);
      await prefs.setBool(_isLoggedInKey, true);
      return true;
    } catch (e) {
      print('Error saving user: $e');
      return false;
    }
  }

  // Get user data
  static Future<User?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Onboarding slides completed (pre-login after language, or post-login; silver skips via [setOnboardingSeen]).
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  static Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }

  /// Language / first-launch path done — controls splash → [LanguageSelectionScreen] vs welcome.
  static Future<bool> hasCompletedInitialLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_initialLaunchKey) == true) return true;
    // Legacy: older builds stored "past first setup" only on onboarding_seen.
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  static Future<void> setInitialLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_initialLaunchKey, true);
  }

  // Clear user data (logout)
  static Future<bool> clearUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.setBool(_isLoggedInKey, false);
      return true;
    } catch (e) {
      print('Error clearing user: $e');
      return false;
    }
  }
}

