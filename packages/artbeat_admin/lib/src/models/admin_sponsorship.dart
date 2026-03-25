import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSponsorship {
  const AdminSponsorship({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.tier,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.placementKeys,
    required this.createdAt,
    this.businessAddress,
    this.relatedEntityName,
    this.paymentStatus,
    this.contactEmail,
    this.phone,
    this.logoUrl,
    this.linkUrl,
    this.stripeSubscriptionId,
    this.stripePriceId,
    this.moderationNotes,
    this.reviewedBy,
    this.reviewedAt,
  });

  final String id;
  final String businessId;
  final String businessName;
  final String tier;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> placementKeys;
  final DateTime createdAt;
  final String? businessAddress;
  final String? relatedEntityName;
  final String? paymentStatus;
  final String? contactEmail;
  final String? phone;
  final String? logoUrl;
  final String? linkUrl;
  final String? stripeSubscriptionId;
  final String? stripePriceId;
  final String? moderationNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  factory AdminSponsorship.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return AdminSponsorship(
      id: snapshot.id,
      businessId: (data['businessId'] ?? '') as String,
      businessName: (data['businessName'] ?? 'Local Business') as String,
      tier: (data['tier'] ?? 'capture') as String,
      status: (data['status'] ?? 'pending') as String,
      startDate: ((data['startDate']) as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: ((data['endDate']) as Timestamp?)?.toDate() ?? DateTime.now(),
      placementKeys:
          (data['placementKeys'] as List<dynamic>? ?? [])
              .whereType<String>()
              .toList(),
      createdAt:
          ((data['createdAt']) as Timestamp?)?.toDate() ?? DateTime.now(),
      businessAddress: data['businessAddress'] as String?,
      relatedEntityName:
          data['relatedEntityName'] as String? ??
          data['relatedEntityId'] as String?,
      paymentStatus: data['paymentStatus'] as String?,
      contactEmail: data['contactEmail'] as String?,
      phone: data['phone'] as String?,
      logoUrl: data['logoUrl'] as String?,
      linkUrl: data['linkUrl'] as String?,
      stripeSubscriptionId: data['stripeSubscriptionId'] as String?,
      stripePriceId: data['stripePriceId'] as String?,
      moderationNotes: data['moderationNotes'] as String?,
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
    );
  }
}
