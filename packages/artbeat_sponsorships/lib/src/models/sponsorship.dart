import 'package:cloud_firestore/cloud_firestore.dart';

import 'sponsorship_status.dart';
import 'sponsorship_tier.dart';

class Sponsorship {
  Sponsorship({
    required this.id,
    required this.businessId,
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
    this.chapterId,
  });

  factory Sponsorship.fromSnapshot(DocumentSnapshot snapshot) =>
      Sponsorship.fromMap(snapshot.id, snapshot.data() as Map<String, dynamic>);

  factory Sponsorship.fromMap(String id, Map<String, dynamic> data) =>
      Sponsorship(
        id: id,
        businessId: data['businessId'] as String,
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
        chapterId: data['chapterId'] as String?,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
  final String id;
  final String businessId;
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
  final String? chapterId;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'businessId': businessId,
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
    'chapterId': chapterId,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  /// ----- Pure logic helpers (no UI concerns) -----

  bool get isActive =>
      status.isActive &&
      DateTime.now().isAfter(startDate) &&
      DateTime.now().isBefore(endDate);

  bool get isExpired => DateTime.now().isAfter(endDate);

  bool get isGlobal => radiusMiles == null;

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
