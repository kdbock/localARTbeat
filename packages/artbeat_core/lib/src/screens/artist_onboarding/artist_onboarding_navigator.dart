import 'package:flutter/material.dart';

/// Navigation controller for artist onboarding flow
/// Manages screen transitions and progress tracking
class ArtistOnboardingNavigator {
  static const int totalScreens = 7;

  /// Route to specific onboarding screen
  static String getRouteForStep(int step) {
    switch (step) {
      case 0:
        return '/artist/onboarding/welcome';
      case 1:
        return '/artist/onboarding/introduction';
      case 2:
        return '/artist/onboarding/story';
      case 3:
        return '/artist/onboarding/artwork';
      case 4:
        return '/artist/onboarding/featured';
      case 5:
        return '/artist/onboarding/benefits';
      case 6:
        return '/artist/onboarding/selection';
      default:
        return '/artist/onboarding/welcome';
    }
  }

  /// Navigate to specific step
  static Future<void> navigateToStep(
    BuildContext context,
    int step, {
    bool replace = false,
  }) async {
    final route = getRouteForStep(step);

    if (replace) {
      await Navigator.of(context).pushReplacementNamed(route);
    } else {
      await Navigator.of(context).pushNamed(route);
    }
  }

  /// Navigate to next step
  static Future<void> navigateNext(
    BuildContext context,
    int currentStep,
  ) async {
    if (currentStep < totalScreens - 1) {
      await navigateToStep(context, currentStep + 1, replace: true);
    }
  }

  /// Navigate to previous step
  static Future<void> navigateBack(
    BuildContext context,
    int currentStep,
  ) async {
    if (currentStep > 0) {
      await navigateToStep(context, currentStep - 1, replace: true);
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Navigate to completion screen
  static Future<void> navigateToCompletion(BuildContext context) async {
    await Navigator.of(
      context,
    ).pushReplacementNamed('/artist/onboarding/complete');
  }

  /// Exit onboarding and return to previous screen or dashboard
  static void exitOnboarding(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Get progress indicator text
  static String getProgressText(int step) {
    if (step == 0) return 'Welcome';
    if (step >= totalScreens - 1) return 'Final Step!';
    return 'Step $step of ${totalScreens - 1}';
  }

  /// Get progress percentage (0.0 to 1.0)
  static double getProgressPercentage(int step) {
    return (step / (totalScreens - 1)).clamp(0.0, 1.0);
  }

  /// Check if current step is first
  static bool isFirstStep(int step) => step == 0;

  /// Check if current step is last
  static bool isLastStep(int step) => step >= totalScreens - 1;
}
