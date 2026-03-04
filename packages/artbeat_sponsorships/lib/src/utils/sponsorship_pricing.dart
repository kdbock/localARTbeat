import '../models/sponsorship_tier.dart';

class SponsorshipPricing {
  /// Price in USD
  static double priceFor(SponsorshipTier tier) {
    switch (tier) {
      case SponsorshipTier.artWalk:
        return 249;
      case SponsorshipTier.capture:
        return 99;
      case SponsorshipTier.discover:
        return 49;
    }
  }

  /// Duration in days
  static int durationDaysFor(SponsorshipTier tier) {
    switch (tier) {
      case SponsorshipTier.artWalk:
        return 30;
      case SponsorshipTier.capture:
        return 30;
      case SponsorshipTier.discover:
        return 30;
    }
  }

  /// Whether duration is user-configurable
  static bool isFixedDuration(SponsorshipTier tier) {
    switch (tier) {
      case SponsorshipTier.artWalk:
      case SponsorshipTier.capture:
      case SponsorshipTier.discover:
        return true;
    }
  }
}
