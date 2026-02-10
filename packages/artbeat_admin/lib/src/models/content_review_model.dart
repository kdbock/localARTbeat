import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of content that can be reviewed
enum ContentType {
  ads,
  captures,
  posts,
  comments,
  artwork,
  chapters,
  all;

  String get displayName {
    switch (this) {
      case ContentType.ads:
        return 'Ads';
      case ContentType.captures:
        return 'Captures';
      case ContentType.posts:
        return 'Posts';
      case ContentType.comments:
        return 'Comments';
      case ContentType.artwork:
        return 'Artwork';
      case ContentType.chapters:
        return 'Chapters';
      case ContentType.all:
        return 'All Content';
    }
  }

  static ContentType fromString(String value) {
    return ContentType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ContentType.captures,
    );
  }
}

/// Review status for content
enum ReviewStatus {
  pending,
  approved,
  rejected,
  flagged,
  underReview;

  String get displayName {
    switch (this) {
      case ReviewStatus.pending:
        return 'Pending Review';
      case ReviewStatus.approved:
        return 'Approved';
      case ReviewStatus.rejected:
        return 'Rejected';
      case ReviewStatus.flagged:
        return 'Flagged';
      case ReviewStatus.underReview:
        return 'Under Review';
    }
  }
}

/// Unified moderation status enum for standardizing across all content types
enum ModerationStatus {
  pending,
  approved,
  rejected,
  flagged,
  underReview;

  String get displayName {
    switch (this) {
      case ModerationStatus.pending:
        return 'Pending Review';
      case ModerationStatus.approved:
        return 'Approved';
      case ModerationStatus.rejected:
        return 'Rejected';
      case ModerationStatus.flagged:
        return 'Flagged';
      case ModerationStatus.underReview:
        return 'Under Review';
    }
  }

  /// Convert to ReviewStatus for backward compatibility
  ReviewStatus toReviewStatus() {
    switch (this) {
      case ModerationStatus.pending:
        return ReviewStatus.pending;
      case ModerationStatus.approved:
        return ReviewStatus.approved;
      case ModerationStatus.rejected:
        return ReviewStatus.rejected;
      case ModerationStatus.flagged:
        return ReviewStatus.flagged;
      case ModerationStatus.underReview:
        return ReviewStatus.underReview;
    }
  }

  /// Create from ReviewStatus for backward compatibility
  static ModerationStatus fromReviewStatus(ReviewStatus status) {
    switch (status) {
      case ReviewStatus.pending:
        return ModerationStatus.pending;
      case ReviewStatus.approved:
        return ModerationStatus.approved;
      case ReviewStatus.rejected:
        return ModerationStatus.rejected;
      case ReviewStatus.flagged:
        return ModerationStatus.flagged;
      case ReviewStatus.underReview:
        return ModerationStatus.underReview;
    }
  }
}

/// Model for content that needs admin review
class ContentReviewModel {
  final String id;
  final String contentId;
  final ContentType contentType;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final ReviewStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final Map<String, dynamic>? metadata;

  ContentReviewModel({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.metadata,
  });

  factory ContentReviewModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ContentReviewModel(
      id: doc.id,
      contentId: (data['contentId'] as String?) ?? '',
      contentType: ContentType.values.firstWhere(
        (type) => type.name == data['contentType'],
        orElse: () => ContentType.captures,
      ),
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      authorId: (data['authorId'] as String?) ?? '',
      authorName: (data['authorName'] as String?) ?? '',
      status: ReviewStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => ReviewStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: data['reviewedBy'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // Alias for fromFirestore to maintain compatibility
  factory ContentReviewModel.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return ContentReviewModel.fromFirestore(doc);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'contentId': contentId,
      'contentType': contentType.name,
      'title': title,
      'description': description,
      'authorId': authorId,
      'authorName': authorName,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
      'metadata': metadata,
    };
  }

  // Alias for toFirestore to maintain compatibility
  Map<String, dynamic> toDocument() {
    return toFirestore();
  }

  /// Create a copy with updated fields
  ContentReviewModel copyWith({
    String? id,
    String? contentId,
    ContentType? contentType,
    String? title,
    String? description,
    String? authorId,
    String? authorName,
    ReviewStatus? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
    Map<String, dynamic>? metadata,
  }) {
    return ContentReviewModel(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      title: title ?? this.title,
      description: description ?? this.description,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Priority levels for content moderation
enum ModerationPriority {
  low,
  normal,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case ModerationPriority.low:
        return 'Low';
      case ModerationPriority.normal:
        return 'Normal';
      case ModerationPriority.high:
        return 'High';
      case ModerationPriority.urgent:
        return 'Urgent';
    }
  }
}

/// Filters for content moderation
class ModerationFilters {
  final ContentType? contentType;
  final ReviewStatus? status;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? searchQuery;
  final ModerationPriority? priority;
  final String? flagReason;
  final String? userId;
  final String? authorName;
  final int? limit;

  const ModerationFilters({
    this.contentType,
    this.status,
    this.dateFrom,
    this.dateTo,
    this.searchQuery,
    this.priority,
    this.flagReason,
    this.userId,
    this.authorName,
    this.limit,
  });

  /// Create a copy with updated filters
  ModerationFilters copyWith({
    ContentType? contentType,
    ReviewStatus? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? searchQuery,
    ModerationPriority? priority,
    String? flagReason,
    String? userId,
    String? authorName,
    int? limit,
  }) {
    return ModerationFilters(
      contentType: contentType ?? this.contentType,
      status: status ?? this.status,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      searchQuery: searchQuery ?? this.searchQuery,
      priority: priority ?? this.priority,
      flagReason: flagReason ?? this.flagReason,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      limit: limit ?? this.limit,
    );
  }

  /// Clear all filters
  ModerationFilters clear() {
    return const ModerationFilters();
  }

  /// Check if any filters are active
  bool get hasActiveFilters {
    return contentType != null ||
        status != null ||
        dateFrom != null ||
        dateTo != null ||
        (searchQuery != null && searchQuery!.isNotEmpty) ||
        priority != null ||
        (flagReason != null && flagReason!.isNotEmpty) ||
        (userId != null && userId!.isNotEmpty) ||
        (authorName != null && authorName!.isNotEmpty);
  }

  /// Get active filter count
  int get activeFilterCount {
    int count = 0;
    if (contentType != null) count++;
    if (status != null) count++;
    if (dateFrom != null || dateTo != null) count++;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    if (priority != null) count++;
    if (flagReason != null && flagReason!.isNotEmpty) count++;
    if (userId != null && userId!.isNotEmpty) count++;
    if (authorName != null && authorName!.isNotEmpty) count++;
    return count;
  }
}
