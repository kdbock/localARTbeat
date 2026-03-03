import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_core/src/models/subscription_tier.dart';

void main() {
  group('SubscriptionTier.fromLegacyName', () {
    test('maps legacy and new names correctly', () {
      expect(SubscriptionTier.fromLegacyName('free'), SubscriptionTier.free);
      expect(SubscriptionTier.fromLegacyName('none'), SubscriptionTier.free);

      expect(
        SubscriptionTier.fromLegacyName('artist_basic'),
        SubscriptionTier.starter,
      );
      expect(
        SubscriptionTier.fromLegacyName('basic'),
        SubscriptionTier.starter,
      );

      expect(
        SubscriptionTier.fromLegacyName('artist_pro'),
        SubscriptionTier.creator,
      );
      expect(
        SubscriptionTier.fromLegacyName('standard'),
        SubscriptionTier.creator,
      );

      expect(
        SubscriptionTier.fromLegacyName('gallery_business'),
        SubscriptionTier.business,
      );
      expect(
        SubscriptionTier.fromLegacyName('premium'),
        SubscriptionTier.business,
      );

      expect(
        SubscriptionTier.fromLegacyName('enterprise_plus'),
        SubscriptionTier.enterprise,
      );
    });

    test('falls back to free for unknown values', () {
      expect(
        SubscriptionTier.fromLegacyName('totally_unknown_tier'),
        SubscriptionTier.free,
      );
    });
  });

  group('SubscriptionTier pricing', () {
    test('free has Free price string', () {
      expect(SubscriptionTier.free.priceString, 'Free');
    });

    test('non-free tiers have positive monthly and yearly prices', () {
      for (final tier in SubscriptionTier.values.where(
        (tier) => tier != SubscriptionTier.free,
      )) {
        expect(tier.monthlyPrice, greaterThan(0));
        expect(tier.yearlyPrice, greaterThan(0));
      }
    });

    test('yearly price stays below 12x monthly for paid tiers', () {
      for (final tier in SubscriptionTier.values.where(
        (tier) => tier != SubscriptionTier.free,
      )) {
        expect(tier.yearlyPrice, lessThan(tier.monthlyPrice * 12));
      }
    });
  });
}
