import 'package:flutter/material.dart';
import '../screens/screens.dart';

/// Service for handling navigation within the artist module
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  /// Navigate to gallery hub
  static Future<void> navigateToGalleryHub(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (context) => const GalleryHubScreen()),
    );
  }

  /// Navigate to artist profile edit screen
  static Future<void> navigateToProfileEdit(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const ArtistProfileEditScreen(),
      ),
    );
  }

  /// Navigate to earnings hub
  static Future<void> navigateToEarnings(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (context) => const ArtistEarningsHub()),
    );
  }

  /// Navigate to visibility insights
  static Future<void> navigateToVisibility(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const VisibilityInsightsScreen(),
      ),
    );
  }

  /// Navigate to subscription analytics
  static Future<void> navigateToSubscriptionAnalytics(
    BuildContext context,
  ) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const SubscriptionAnalyticsScreen(),
      ),
    );
  }

  /// Navigate to gallery management screen
  static Future<void> navigateToGalleryManagement(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const GalleryArtistsManagementScreen(),
      ),
    );
  }

  /// Navigate to event creation screen
  static Future<void> navigateToEventCreation(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const EventCreationScreen(),
      ),
    );
  }

  /// Navigate to payment methods screen
  static Future<void> navigateToPaymentMethods(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const PaymentMethodsScreen(),
      ),
    );
  }

  /// Navigate to payout request screen
  static Future<void> navigateToPayoutRequest(
    BuildContext context, {
    required double availableBalance,
    VoidCallback? onPayoutRequested,
  }) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => PayoutRequestScreen(
          availableBalance: availableBalance,
          onPayoutRequested: onPayoutRequested ?? () {},
        ),
      ),
    );
  }

  /// Navigate to artist onboarding
  static Future<void> navigateToOnboarding(
    BuildContext context, {
    VoidCallback? onComplete,
  }) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const ArtistOnboardScreen(),
      ),
    );
  }

  /// Navigate with replacement (no back navigation)
  static Future<void> navigateAndReplace(
    BuildContext context,
    Widget screen,
  ) async {
    await Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute<void>(builder: (context) => screen),
    );
  }

  /// Navigate and clear stack
  static Future<void> navigateAndClear(
    BuildContext context,
    Widget screen,
  ) async {
    await Navigator.pushAndRemoveUntil<void>(
      context,
      MaterialPageRoute<void>(builder: (context) => screen),
      (route) => false,
    );
  }

  /// Pop with result
  static void popWithResult<T>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }
}
