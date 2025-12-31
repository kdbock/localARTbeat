import '../models/sponsorship_tier.dart';
import 'sponsorship_placements.dart';

class SponsorshipValidator {
  /// Whether this tier requires a radius
  static bool requiresRadius(SponsorshipTier tier) {
    switch (tier) {
      case SponsorshipTier.capture:
      case SponsorshipTier.discover:
        return true;
      case SponsorshipTier.title:
      case SponsorshipTier.event:
      case SponsorshipTier.artWalk:
        return false;
    }
  }

  /// Whether this tier requires a related entity ID
  static bool requiresRelatedEntity(SponsorshipTier tier) {
    switch (tier) {
      case SponsorshipTier.event:
      case SponsorshipTier.artWalk:
        return true;
      case SponsorshipTier.title:
      case SponsorshipTier.capture:
      case SponsorshipTier.discover:
        return false;
    }
  }

  /// Validate that a placement is allowed for a tier
  static bool isPlacementAllowed(
    SponsorshipTier tier,
    String placementKey,
  ) {
    switch (tier) {
      case SponsorshipTier.title:
        return placementKey == SponsorshipPlacements.splash ||
            placementKey == SponsorshipPlacements.dashboardTop ||
            placementKey == SponsorshipPlacements.dashboardFooter;

      case SponsorshipTier.event:
        return placementKey == SponsorshipPlacements.eventHeader;

      case SponsorshipTier.artWalk:
        return placementKey == SponsorshipPlacements.artWalkHeader ||
            placementKey == SponsorshipPlacements.artWalkStopCard;

      case SponsorshipTier.capture:
        return placementKey ==
            SponsorshipPlacements.captureDetailBanner;

      case SponsorshipTier.discover:
        return placementKey ==
            SponsorshipPlacements.discoverRadarBanner;
    }
  }

  /// Validate a full sponsorship configuration
  static List<String> validate({
    required SponsorshipTier tier,
    required List<String> placementKeys,
    double? radiusMiles,
    String? relatedEntityId,
  }) {
    final errors = <String>[];

    if (requiresRadius(tier) && radiusMiles == null) {
      errors.add('This sponsorship type requires a radius.');
    }

    if (!requiresRadius(tier) && radiusMiles != null) {
      errors.add('Radius is not allowed for this sponsorship type.');
    }

    if (requiresRelatedEntity(tier) && relatedEntityId == null) {
      errors.add('This sponsorship type requires a related entity.');
    }

    for (final key in placementKeys) {
      if (!isPlacementAllowed(tier, key)) {
        errors.add('Placement "$key" is not allowed for this tier.');
      }
    }

    return errors;
  }
}
