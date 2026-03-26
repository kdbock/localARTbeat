import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminLocalAdZone { home, events, artists, community, featured }

extension AdminLocalAdZoneExtension on AdminLocalAdZone {
  String get displayName {
    switch (this) {
      case AdminLocalAdZone.home:
        return 'Home';
      case AdminLocalAdZone.events:
        return 'Events';
      case AdminLocalAdZone.artists:
        return 'Artists';
      case AdminLocalAdZone.community:
        return 'Community';
      case AdminLocalAdZone.featured:
        return 'Featured';
    }
  }

  String get placementDisplayName {
    switch (this) {
      case AdminLocalAdZone.community:
        return 'Community feed';
      case AdminLocalAdZone.artists:
        return 'Artists and artwork';
      case AdminLocalAdZone.events:
        return 'Events';
      case AdminLocalAdZone.home:
        return 'Home (not in launch rotation)';
      case AdminLocalAdZone.featured:
        return 'Featured (not in launch rotation)';
    }
  }

  static AdminLocalAdZone fromIndex(int idx) {
    if (idx < 0 || idx >= AdminLocalAdZone.values.length) {
      return AdminLocalAdZone.home;
    }
    return AdminLocalAdZone.values[idx];
  }
}

enum AdminLocalAdSize { small, big }

extension AdminLocalAdSizeExtension on AdminLocalAdSize {
  String get displayName {
    switch (this) {
      case AdminLocalAdSize.small:
        return 'Banner Ad';
      case AdminLocalAdSize.big:
        return 'Inline Ad';
    }
  }

  static AdminLocalAdSize fromIndex(int idx) {
    if (idx < 0 || idx >= AdminLocalAdSize.values.length) {
      return AdminLocalAdSize.small;
    }
    return AdminLocalAdSize.values[idx];
  }
}

enum AdminLocalAdStatus {
  active,
  expired,
  deleted,
  pendingReview,
  flagged,
  rejected,
}

extension AdminLocalAdStatusExtension on AdminLocalAdStatus {
  String get displayName {
    switch (this) {
      case AdminLocalAdStatus.active:
        return 'Active';
      case AdminLocalAdStatus.expired:
        return 'Expired';
      case AdminLocalAdStatus.deleted:
        return 'Deleted';
      case AdminLocalAdStatus.pendingReview:
        return 'Pending Review';
      case AdminLocalAdStatus.flagged:
        return 'Flagged';
      case AdminLocalAdStatus.rejected:
        return 'Rejected';
    }
  }

  int get firestoreIndex {
    switch (this) {
      case AdminLocalAdStatus.active:
        return 0;
      case AdminLocalAdStatus.expired:
        return 1;
      case AdminLocalAdStatus.deleted:
        return 2;
      case AdminLocalAdStatus.pendingReview:
        return 3;
      case AdminLocalAdStatus.flagged:
        return 4;
      case AdminLocalAdStatus.rejected:
        return 5;
    }
  }

  static AdminLocalAdStatus fromIndex(int idx) {
    if (idx < 0 || idx >= AdminLocalAdStatus.values.length) {
      return AdminLocalAdStatus.pendingReview;
    }
    return AdminLocalAdStatus.values[idx];
  }
}

class AdminLocalAd {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String? imageUrl;
  final List<String>? imageUrls;
  final String? contactInfo;
  final String? websiteUrl;
  final AdminLocalAdZone zone;
  final AdminLocalAdSize size;
  final DateTime createdAt;
  final DateTime expiresAt;
  final AdminLocalAdStatus status;
  final int reportCount;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final String? subscriptionProductId;
  final String? purchaseId;
  final String? transactionId;
  final double? monthlyPrice;
  final String? currencyCode;
  final bool autoRenewing;
  final String? purchaseFollowUpStatus;
  final String? purchaseFollowUpNotes;

  const AdminLocalAd({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.imageUrl,
    this.imageUrls,
    this.contactInfo,
    this.websiteUrl,
    required this.zone,
    required this.size,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
    required this.reportCount,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.subscriptionProductId,
    this.purchaseId,
    this.transactionId,
    this.monthlyPrice,
    this.currencyCode,
    this.autoRenewing = true,
    this.purchaseFollowUpStatus,
    this.purchaseFollowUpNotes,
  });

  factory AdminLocalAd.fromMap(Map<String, dynamic> map, String id) {
    return AdminLocalAd(
      id: id,
      userId: (map['userId'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      imageUrl: map['imageUrl'] as String?,
      imageUrls:
          (map['imageUrls'] as List?)?.whereType<String>().toList() ??
          (map['artworkUrls'] as List?)?.whereType<String>().toList(),
      contactInfo: map['contactInfo'] as String?,
      websiteUrl: map['websiteUrl'] as String?,
      zone: AdminLocalAdZoneExtension.fromIndex((map['zone'] ?? 0) as int),
      size: AdminLocalAdSizeExtension.fromIndex((map['size'] ?? 0) as int),
      createdAt: ((map['createdAt']) as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: ((map['expiresAt']) as Timestamp?)?.toDate() ?? DateTime.now(),
      status: AdminLocalAdStatusExtension.fromIndex((map['status'] ?? 3) as int),
      reportCount: (map['reportCount'] ?? 0) as int,
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: map['reviewedBy'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
      subscriptionProductId: map['subscriptionProductId'] as String?,
      purchaseId: map['purchaseId'] as String?,
      transactionId: map['transactionId'] as String?,
      monthlyPrice: (map['monthlyPrice'] as num?)?.toDouble(),
      currencyCode: map['currencyCode'] as String?,
      autoRenewing: map['autoRenewing'] as bool? ?? true,
      purchaseFollowUpStatus: map['purchaseFollowUpStatus'] as String?,
      purchaseFollowUpNotes: map['purchaseFollowUpNotes'] as String?,
    );
  }

  factory AdminLocalAd.fromSnapshot(DocumentSnapshot snapshot) {
    return AdminLocalAd.fromMap(
      snapshot.data() as Map<String, dynamic>,
      snapshot.id,
    );
  }

  bool get hasPaidSubscription =>
      subscriptionProductId != null ||
      purchaseId != null ||
      transactionId != null ||
      monthlyPrice != null;

  String get paymentSummaryLabel {
    final price = monthlyPrice;
    final currency = currencyCode?.trim();
    if (price == null) {
      return autoRenewing ? 'Monthly subscription' : 'Paid placement';
    }

    final formattedPrice = price.toStringAsFixed(2);
    if (currency != null && currency.isNotEmpty) {
      return autoRenewing
          ? '$currency $formattedPrice / month'
          : '$currency $formattedPrice';
    }
    return autoRenewing ? '$formattedPrice / month' : formattedPrice;
  }

  String get paymentFollowUpDisplayLabel {
    final raw = purchaseFollowUpStatus?.trim();
    if (raw == null || raw.isEmpty) {
      return hasPaidSubscription ? 'paid_submission' : 'none';
    }

    return raw
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
