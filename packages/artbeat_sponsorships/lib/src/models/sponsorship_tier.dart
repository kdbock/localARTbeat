/// Defines the type of sponsorship purchased by a business.
/// Tiers control placement behavior, scope, and pricing,
/// but NOT rendering or payment logic.
enum SponsorshipTier {
  /// Global, exclusive sponsor of the entire app
  title,

  /// Sponsor of a specific Local ARTbeat event or tour
  event,

  /// Sponsor of an Art Walk created by or featuring a business
  artWalk,

  /// Sponsor shown on art capture detail views within a radius
  capture,

  /// Sponsor shown on instant discovery radar views within a radius
  discover,
}

extension SponsorshipTierExtension on SponsorshipTier {
  /// Stable string value for Firestore storage
  String get value => name;

  /// Convert Firestore string back to enum
  static SponsorshipTier fromString(String value) =>
      SponsorshipTier.values.firstWhere(
        (tier) => tier.name == value,
        orElse: () => SponsorshipTier.capture,
      );

  /// Logical helpers (no UI text, no pricing)
  bool get isGlobal => this == SponsorshipTier.title;
  bool get isRadiusBased =>
      this == SponsorshipTier.capture || this == SponsorshipTier.discover;
  bool get isEventScoped =>
      this == SponsorshipTier.event || this == SponsorshipTier.artWalk;
}
