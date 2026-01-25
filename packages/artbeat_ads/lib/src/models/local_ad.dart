import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_ad_zone.dart';
import 'local_ad_status.dart';
import 'local_ad_size.dart';

class LocalAd {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String? imageUrl;
  final List<String>? imageUrls;
  final String? contactInfo;
  final String? websiteUrl;
  final LocalAdZone zone;
  final LocalAdSize size;
  final DateTime createdAt;
  final DateTime expiresAt;
  final LocalAdStatus status;
  final int reportCount;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  LocalAd({
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
    this.status = LocalAdStatus.pendingReview, // New ads need review
    this.reportCount = 0,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  int get daysRemaining {
    final difference = expiresAt.difference(DateTime.now()).inDays;
    return difference < 0 ? 0 : difference;
  }

  factory LocalAd.fromMap(Map<String, dynamic> map, String id) {
    return LocalAd(
      id: id,
      userId: (map['userId'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      imageUrl: map['imageUrl'] as String?,
      imageUrls: (map['imageUrls'] as List?)
          ?.whereType<String>()
          .toList() ??
          (map['artworkUrls'] as List?)?.whereType<String>().toList(),
      contactInfo: map['contactInfo'] as String?,
      websiteUrl: map['websiteUrl'] as String?,
      zone: LocalAdZoneExtension.fromIndex((map['zone'] ?? 0) as int),
      size: LocalAdSizeExtension.fromIndex((map['size'] ?? 0) as int),
      createdAt: ((map['createdAt']) as Timestamp).toDate(),
      expiresAt: ((map['expiresAt']) as Timestamp).toDate(),
      status: LocalAdStatusExtension.fromIndex(
        (map['status'] ?? 3) as int,
      ), // Default to pendingReview
      reportCount: (map['reportCount'] ?? 0) as int,
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: map['reviewedBy'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  factory LocalAd.fromSnapshot(DocumentSnapshot snapshot) {
    return LocalAd.fromMap(
      snapshot.data() as Map<String, dynamic>,
      snapshot.id,
    );
  }

  Map<String, dynamic> toMap() {
    final urls = imageUrls?.where((url) => url.isNotEmpty).toList();
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl ?? (urls != null && urls.isNotEmpty ? urls.first : null),
      if (urls != null && urls.isNotEmpty) 'imageUrls': urls,
      'contactInfo': contactInfo,
      'websiteUrl': websiteUrl,
      'zone': zone.index,
      'size': size.index,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': status.index,
      'reportCount': reportCount,
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
  }

  LocalAd copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? imageUrl,
    List<String>? imageUrls,
    String? contactInfo,
    String? websiteUrl,
    LocalAdZone? zone,
    LocalAdSize? size,
    DateTime? createdAt,
    DateTime? expiresAt,
    LocalAdStatus? status,
    int? reportCount,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return LocalAd(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      contactInfo: contactInfo ?? this.contactInfo,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      zone: zone ?? this.zone,
      size: size ?? this.size,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      reportCount: reportCount ?? this.reportCount,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  /// Check if this ad has been flagged due to multiple reports
  bool get isFlagged => reportCount >= 3;

  /// Check if this ad needs admin review
  bool get needsReview => status.needsReview || isFlagged;

  /// Check if this ad is visible to users
  bool get isVisibleToUsers => status.isVisible && !isExpired && !isFlagged;
}
