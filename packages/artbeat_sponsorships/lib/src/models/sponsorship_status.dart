/// Represents the lifecycle status of a sponsorship.
/// Sponsorships are manually reviewed and controlled by admins,
/// unlike self-serve local ads.
enum SponsorshipStatus {
  /// Submitted by a business but not yet approved
  pending,

  /// Approved and currently active within its date range
  active,

  /// Automatically or manually expired
  expired,

  /// Rejected by an admin and never activated
  rejected,
}

extension SponsorshipStatusExtension on SponsorshipStatus {
  /// Convert enum to a stable string value for Firestore
  String get value => name;

  /// Convert a stored string value back into enum
  static SponsorshipStatus fromString(String value) =>
      SponsorshipStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => SponsorshipStatus.pending,
      );

  /// Convenience checks (logic only, no UI concerns)
  bool get isActive => this == SponsorshipStatus.active;
  bool get isPending => this == SponsorshipStatus.pending;
  bool get isExpired => this == SponsorshipStatus.expired;
  bool get isRejected => this == SponsorshipStatus.rejected;
}
