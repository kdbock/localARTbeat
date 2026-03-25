import 'package:cloud_firestore/cloud_firestore.dart';

import 'sponsorship_status.dart';
import 'sponsorship_tier.dart';

class Sponsorship {
  Sponsorship({
    required this.id,
    required this.businessId,
    required this.businessName,
    this.businessDescription,
    required this.tier,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.placementKeys,
    required this.logoUrl,
    required this.linkUrl,
    required this.createdAt,
    this.radiusMiles,
    this.latitude,
    this.longitude,
    this.bannerUrl,
    this.relatedEntityId,
    this.relatedEntityName,
    this.chapterId,
    this.businessAddress,
    this.contactEmail,
    this.phone,
    this.brandingNotes,
    this.additionalNotes,
    this.paymentStatus,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.stripePriceId,
    this.stripeProductId,
    this.moderationNotes,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory Sponsorship.fromSnapshot(DocumentSnapshot snapshot) =>
      Sponsorship.fromMap(snapshot.id, snapshot.data() as Map<String, dynamic>);

  factory Sponsorship.fromMap(String id, Map<String, dynamic> data) =>
      Sponsorship(
        id: id,
        businessId: data['businessId'] as String,
        businessName: data['businessName'] as String? ?? 'Local Business',
        businessDescription: data['businessDescription'] as String?,
        tier: SponsorshipTierExtension.fromString(
          data['tier'] as String? ?? '',
        ),
        status: SponsorshipStatusExtension.fromString(
          data['status'] as String? ?? '',
        ),
        startDate: (data['startDate'] as Timestamp).toDate(),
        endDate: (data['endDate'] as Timestamp).toDate(),
        radiusMiles: (data['radiusMiles'] as num?)?.toDouble(),
        latitude: _extractLatitude(data),
        longitude: _extractLongitude(data),
        placementKeys: (data['placementKeys'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        logoUrl: data['logoUrl'] as String,
        bannerUrl: data['bannerUrl'] as String?,
        linkUrl: data['linkUrl'] as String,
        relatedEntityId: data['relatedEntityId'] as String?,
        relatedEntityName:
            data['relatedEntityName'] as String? ??
            data['relatedEntityId'] as String?,
        chapterId: data['chapterId'] as String?,
        businessAddress:
            data['businessAddress'] as String? ?? data['chapterId'] as String?,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        contactEmail: data['contactEmail'] as String?,
        phone: data['phone'] as String?,
        brandingNotes: data['brandingNotes'] as String?,
        additionalNotes: data['additionalNotes'] as String?,
        paymentStatus: data['paymentStatus'] as String?,
        stripeCustomerId: data['stripeCustomerId'] as String?,
        stripeSubscriptionId: data['stripeSubscriptionId'] as String?,
        stripePriceId: data['stripePriceId'] as String?,
        stripeProductId: data['stripeProductId'] as String?,
        moderationNotes: data['moderationNotes'] as String?,
        reviewedBy: data['reviewedBy'] as String?,
        reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      );
  final String id;
  final String businessId;
  final String businessName;
  final String? businessDescription;
  final SponsorshipTier tier;
  final SponsorshipStatus status;

  final DateTime startDate;
  final DateTime endDate;

  final double? radiusMiles; // null = global
  final double? latitude; // null = no geo targeting center
  final double? longitude; // null = no geo targeting center
  final List<String> placementKeys;

  final String logoUrl;
  final String? bannerUrl;
  final String linkUrl;

  final String? relatedEntityId; // eventId, artWalkId, etc
  final String? relatedEntityName;
  final String? chapterId;
  final String? businessAddress;
  final DateTime createdAt;
  final String? contactEmail;
  final String? phone;
  final String? brandingNotes;
  final String? additionalNotes;
  final String? paymentStatus;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final String? stripePriceId;
  final String? stripeProductId;
  final String? moderationNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  Map<String, dynamic> toMap() => {
    'businessId': businessId,
    'businessName': businessName,
    'businessDescription': businessDescription,
    'tier': tier.value,
    'status': status.value,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'radiusMiles': radiusMiles,
    'latitude': latitude,
    'longitude': longitude,
    'placementKeys': placementKeys,
    'logoUrl': logoUrl,
    'bannerUrl': bannerUrl,
    'linkUrl': linkUrl,
    'relatedEntityId': relatedEntityId,
    'relatedEntityName': relatedEntityName,
    'chapterId': chapterId,
    'businessAddress': businessAddress,
    'createdAt': Timestamp.fromDate(createdAt),
    'contactEmail': contactEmail,
    'phone': phone,
    'brandingNotes': brandingNotes,
    'additionalNotes': additionalNotes,
    'paymentStatus': paymentStatus,
    'stripeCustomerId': stripeCustomerId,
    'stripeSubscriptionId': stripeSubscriptionId,
    'stripePriceId': stripePriceId,
    'stripeProductId': stripeProductId,
    'moderationNotes': moderationNotes,
    'reviewedBy': reviewedBy,
    if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
  };

  /// ----- Pure logic helpers (no UI concerns) -----

  bool get isActive =>
      status.isActive &&
      DateTime.now().isAfter(startDate) &&
      DateTime.now().isBefore(endDate);

  bool get isExpired => DateTime.now().isAfter(endDate);

  bool get isGlobal => radiusMiles == null;

  bool get hasRenderableCreative =>
      logoUrl.trim().isNotEmpty && normalizedLinkUrl != null;

  String? get normalizedLinkUrl {
    final raw = linkUrl.trim();
    if (raw.isEmpty) return null;
    final withScheme = raw.contains('://') ? raw : 'https://$raw';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    return uri.toString();
  }

  static double? _extractLatitude(Map<String, dynamic> data) {
    final topLevel = (data['latitude'] as num?)?.toDouble();
    if (topLevel != null) return topLevel;

    final location = data['location'];
    if (location is GeoPoint) return location.latitude;

    final coordinates = data['coordinates'];
    if (coordinates is Map<String, dynamic>) {
      return (coordinates['latitude'] as num?)?.toDouble() ??
          (coordinates['lat'] as num?)?.toDouble();
    }
    return null;
  }

  static double? _extractLongitude(Map<String, dynamic> data) {
    final topLevel = (data['longitude'] as num?)?.toDouble();
    if (topLevel != null) return topLevel;

    final location = data['location'];
    if (location is GeoPoint) return location.longitude;

    final coordinates = data['coordinates'];
    if (coordinates is Map<String, dynamic>) {
      return (coordinates['longitude'] as num?)?.toDouble() ??
          (coordinates['lng'] as num?)?.toDouble() ??
          (coordinates['lon'] as num?)?.toDouble();
    }
    return null;
  }
}
