import '../models/sponsorship_tier.dart';

class SponsorshipPricing {
  /// Price in USD
  static double priceFor(SponsorshipTier tier) {
    switch (tier) {
      case SponsorshipTier.title:
        return 25000;
      case SponsorshipTier.event:
        return 1000;
      case SponsorshipTier.artWalk:
        return 500;
      case SponsorshipTier.capture:
        return 250;
      case SponsorshipTier.discover:
        return 250;
    }
  }

  /// Duration in days
  static int durationDaysFor(SponsorshipTier tier) {
    switch (tier) {
      case SponsorshipTier.title:
        return 365;
      case SponsorshipTier.event:
        return 0; // Event-based; dates supplied externally
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
      case SponsorshipTier.event:
        return false;
      default:
        return true;
    }
  }
}
