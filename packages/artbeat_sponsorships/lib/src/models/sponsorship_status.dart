/// Represents the lifecycle status of a sponsorship.
/// Sponsorships are manually reviewed and controlled by admins,
/// unlike self-serve local ads.
enum SponsorshipStatus {
  /// Submitted by a business but not yet approved
  pending,

  /// Payment succeeded, but the sponsorship still needs creative/assets
  needsCreative,

  /// Approved by admin and ready for display
  approved,

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

  String get displayName {
    switch (this) {
      case SponsorshipStatus.pending:
        return 'Pending Review';
      case SponsorshipStatus.needsCreative:
        return 'Needs Creative';
      case SponsorshipStatus.approved:
        return 'Approved';
      case SponsorshipStatus.active:
        return 'Active';
      case SponsorshipStatus.expired:
        return 'Expired';
      case SponsorshipStatus.rejected:
        return 'Rejected';
    }
  }

  /// Convenience checks (logic only, no UI concerns)
  bool get isActive =>
      this == SponsorshipStatus.active || this == SponsorshipStatus.approved;
  bool get isPending => this == SponsorshipStatus.pending;
  bool get needsCreative => this == SponsorshipStatus.needsCreative;
  bool get isExpired => this == SponsorshipStatus.expired;
  bool get isRejected => this == SponsorshipStatus.rejected;
}
