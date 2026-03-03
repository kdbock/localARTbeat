import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artbeat_core/src/services/onboarding_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingService', () {
    late OnboardingService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = OnboardingService();
    });

    test('starts with all onboarding flags false', () async {
      expect(await service.isOnboardingCompleted(), isFalse);
      expect(await service.isCaptureOnboardingCompleted(), isFalse);
      expect(await service.isDiscoverOnboardingCompleted(), isFalse);
      expect(await service.isExploreOnboardingCompleted(), isFalse);
      expect(await service.isArtCommunityOnboardingCompleted(), isFalse);
      expect(await service.isEventsOnboardingCompleted(), isFalse);
    });

    test('mark methods persist each onboarding flag', () async {
      await service.markOnboardingCompleted();
      await service.markCaptureOnboardingCompleted();
      await service.markDiscoverOnboardingCompleted();
      await service.markExploreOnboardingCompleted();
      await service.markArtCommunityOnboardingCompleted();
      await service.markEventsOnboardingCompleted();

      expect(await service.isOnboardingCompleted(), isTrue);
      expect(await service.isCaptureOnboardingCompleted(), isTrue);
      expect(await service.isDiscoverOnboardingCompleted(), isTrue);
      expect(await service.isExploreOnboardingCompleted(), isTrue);
      expect(await service.isArtCommunityOnboardingCompleted(), isTrue);
      expect(await service.isEventsOnboardingCompleted(), isTrue);
    });

    test('resetOnboarding clears all persisted flags', () async {
      await service.markOnboardingCompleted();
      await service.markCaptureOnboardingCompleted();
      await service.markDiscoverOnboardingCompleted();
      await service.markExploreOnboardingCompleted();
      await service.markArtCommunityOnboardingCompleted();
      await service.markEventsOnboardingCompleted();

      await service.resetOnboarding();

      expect(await service.isOnboardingCompleted(), isFalse);
      expect(await service.isCaptureOnboardingCompleted(), isFalse);
      expect(await service.isDiscoverOnboardingCompleted(), isFalse);
      expect(await service.isExploreOnboardingCompleted(), isFalse);
      expect(await service.isArtCommunityOnboardingCompleted(), isFalse);
      expect(await service.isEventsOnboardingCompleted(), isFalse);
    });
  });
}
