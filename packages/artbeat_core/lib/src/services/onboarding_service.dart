import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class OnboardingService {
  static const String _kOnboardingCompletedKey = 'onboarding_completed';
  static const String _kCaptureOnboardingCompletedKey =
      'capture_onboarding_completed';
  static const String _kDiscoverOnboardingCompletedKey =
      'discover_onboarding_completed';
  static const String _kExploreOnboardingCompletedKey =
      'explore_onboarding_completed';
  static const String _kArtCommunityOnboardingCompletedKey =
      'art_community_onboarding_completed';
  static const String _kEventsOnboardingCompletedKey =
      'events_onboarding_completed';

  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  /// Check if the user has already completed the onboarding carousel
  Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kOnboardingCompletedKey) ?? false;
    } catch (e) {
      AppLogger.error('Error checking onboarding status: $e');
      return false;
    }
  }

  /// Mark onboarding as completed
  Future<void> markOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kOnboardingCompletedKey, true);
      AppLogger.info('Onboarding marked as completed');
    } catch (e) {
      AppLogger.error('Error saving onboarding status: $e');
    }
  }

  /// Check if the user has already completed the capture onboarding
  Future<bool> isCaptureOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kCaptureOnboardingCompletedKey) ?? false;
    } catch (e) {
      AppLogger.error('Error checking capture onboarding status: $e');
      return false;
    }
  }

  /// Mark capture onboarding as completed
  Future<void> markCaptureOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kCaptureOnboardingCompletedKey, true);
      AppLogger.info('Capture onboarding marked as completed');
    } catch (e) {
      AppLogger.error('Error saving capture onboarding status: $e');
    }
  }

  /// Check if the user has already completed the discover onboarding
  Future<bool> isDiscoverOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kDiscoverOnboardingCompletedKey) ?? false;
    } catch (e) {
      AppLogger.error('Error checking discover onboarding status: $e');
      return false;
    }
  }

  /// Mark discover onboarding as completed
  Future<void> markDiscoverOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDiscoverOnboardingCompletedKey, true);
      AppLogger.info('Discover onboarding marked as completed');
    } catch (e) {
      AppLogger.error('Error saving discover onboarding status: $e');
    }
  }

  /// Check if the user has already completed the explore onboarding
  Future<bool> isExploreOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kExploreOnboardingCompletedKey) ?? false;
    } catch (e) {
      AppLogger.error('Error checking explore onboarding status: $e');
      return false;
    }
  }

  /// Mark explore onboarding as completed
  Future<void> markExploreOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kExploreOnboardingCompletedKey, true);
      AppLogger.info('Explore onboarding marked as completed');
    } catch (e) {
      AppLogger.error('Error saving explore onboarding status: $e');
    }
  }

  /// Check if the user has already completed the art community onboarding
  Future<bool> isArtCommunityOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kArtCommunityOnboardingCompletedKey) ?? false;
    } catch (e) {
      AppLogger.error('Error checking art community onboarding status: $e');
      return false;
    }
  }

  /// Mark art community onboarding as completed
  Future<void> markArtCommunityOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kArtCommunityOnboardingCompletedKey, true);
      AppLogger.info('Art community onboarding marked as completed');
    } catch (e) {
      AppLogger.error('Error saving art community onboarding status: $e');
    }
  }

  /// Check if the user has already completed the events onboarding
  Future<bool> isEventsOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kEventsOnboardingCompletedKey) ?? false;
    } catch (e) {
      AppLogger.error('Error checking events onboarding status: $e');
      return false;
    }
  }

  /// Mark events onboarding as completed
  Future<void> markEventsOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kEventsOnboardingCompletedKey, true);
      AppLogger.info('Events onboarding marked as completed');
    } catch (e) {
      AppLogger.error('Error saving events onboarding status: $e');
    }
  }

  /// Reset onboarding status (for testing/debugging)
  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kOnboardingCompletedKey);
      await prefs.remove(_kCaptureOnboardingCompletedKey);
      await prefs.remove(_kDiscoverOnboardingCompletedKey);
      await prefs.remove(_kExploreOnboardingCompletedKey);
      await prefs.remove(_kArtCommunityOnboardingCompletedKey);
      await prefs.remove(_kEventsOnboardingCompletedKey);
      AppLogger.info('Onboarding status reset');
    } catch (e) {
      AppLogger.error('Error resetting onboarding status: $e');
    }
  }
}
