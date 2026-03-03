import 'package:artbeat_artist/src/services/subscription_plan_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionPlanValidator', () {
    final validator = SubscriptionPlanValidator();

    test('hasFeatureAccess follows tier feature mapping', () {
      expect(
        validator.hasFeatureAccess(
          subscriptionTier: 'free',
          feature: 'basic_profile',
        ),
        isTrue,
      );
      expect(
        validator.hasFeatureAccess(
          subscriptionTier: 'free',
          feature: 'advanced_analytics',
        ),
        isFalse,
      );
      expect(
        validator.hasFeatureAccess(
          subscriptionTier: 'artist_pro',
          feature: 'advanced_analytics',
        ),
        isTrue,
      );
    });

    test('upgrade and downgrade validation use tier hierarchy', () {
      expect(
        validator.isValidUpgrade(currentTier: 'free', targetTier: 'gallery'),
        isTrue,
      );
      expect(
        validator.isValidUpgrade(
          currentTier: 'artist_pro',
          targetTier: 'artist_basic',
        ),
        isFalse,
      );
      expect(
        validator.isValidDowngrade(
          currentTier: 'artist_pro',
          targetTier: 'artist_basic',
        ),
        isTrue,
      );
    });

    test('isWithinLimits handles finite and unlimited caps', () {
      expect(
        validator.isWithinLimits(
          subscriptionTier: 'free',
          limitType: 'artworks',
          currentValue: 10,
        ),
        isTrue,
      );
      expect(
        validator.isWithinLimits(
          subscriptionTier: 'free',
          limitType: 'artworks',
          currentValue: 11,
        ),
        isFalse,
      );
      expect(
        validator.isWithinLimits(
          subscriptionTier: 'artist_pro',
          limitType: 'artworks',
          currentValue: 10000,
        ),
        isTrue,
      );
    });
  });
}
