import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_core/src/screens/artist_onboarding/artist_onboarding_navigator.dart';

void main() {
  group('ArtistOnboardingNavigator routes', () {
    test('maps steps to expected routes', () {
      expect(
        ArtistOnboardingNavigator.getRouteForStep(0),
        '/artist/onboarding/welcome',
      );
      expect(
        ArtistOnboardingNavigator.getRouteForStep(1),
        '/artist/onboarding/introduction',
      );
      expect(
        ArtistOnboardingNavigator.getRouteForStep(2),
        '/artist/onboarding/story',
      );
      expect(
        ArtistOnboardingNavigator.getRouteForStep(3),
        '/artist/onboarding/artwork',
      );
      expect(
        ArtistOnboardingNavigator.getRouteForStep(4),
        '/artist/onboarding/featured',
      );
      expect(
        ArtistOnboardingNavigator.getRouteForStep(5),
        '/artist/onboarding/benefits',
      );
      expect(
        ArtistOnboardingNavigator.getRouteForStep(6),
        '/artist/onboarding/selection',
      );
    });

    test('falls back to welcome for invalid step', () {
      expect(
        ArtistOnboardingNavigator.getRouteForStep(999),
        '/artist/onboarding/welcome',
      );
      expect(
        ArtistOnboardingNavigator.getRouteForStep(-1),
        '/artist/onboarding/welcome',
      );
    });
  });

  group('ArtistOnboardingNavigator progress helpers', () {
    test('returns expected progress text', () {
      expect(ArtistOnboardingNavigator.getProgressText(0), 'Welcome');
      expect(ArtistOnboardingNavigator.getProgressText(1), 'Step 1 of 6');
      expect(ArtistOnboardingNavigator.getProgressText(5), 'Step 5 of 6');
      expect(ArtistOnboardingNavigator.getProgressText(6), 'Final Step!');
      expect(ArtistOnboardingNavigator.getProgressText(999), 'Final Step!');
    });

    test('returns clamped progress percentage', () {
      expect(ArtistOnboardingNavigator.getProgressPercentage(0), 0.0);
      expect(ArtistOnboardingNavigator.getProgressPercentage(3), 0.5);
      expect(ArtistOnboardingNavigator.getProgressPercentage(6), 1.0);
      expect(ArtistOnboardingNavigator.getProgressPercentage(999), 1.0);
      expect(ArtistOnboardingNavigator.getProgressPercentage(-5), 0.0);
    });

    test('correctly identifies first/last step', () {
      expect(ArtistOnboardingNavigator.isFirstStep(0), isTrue);
      expect(ArtistOnboardingNavigator.isFirstStep(1), isFalse);

      expect(ArtistOnboardingNavigator.isLastStep(6), isTrue);
      expect(ArtistOnboardingNavigator.isLastStep(10), isTrue);
      expect(ArtistOnboardingNavigator.isLastStep(5), isFalse);
    });
  });
}
