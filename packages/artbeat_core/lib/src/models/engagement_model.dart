import 'package:cloud_firestore/cloud_firestore.dart';

/// Universal engagement model for all ARTbeat content
/// Replaces the complex mix of likes, applause, follows, etc.
class EngagementModel {
  final String id;
  final String contentId;
  final String contentType; // 'post', 'artwork', 'art_walk', 'event', 'profile'
  final String userId;
  final EngagementType type;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  EngagementModel({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.userId,
    required this.type,
    required this.createdAt,
    this.metadata,
  });

  factory EngagementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EngagementModel(
      id: doc.id,
      contentId: data['contentId'] as String,
      contentType: data['contentType'] as String,
      userId: data['userId'] as String,
      type: EngagementType.fromString(data['type'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'contentId': contentId,
      'contentType': contentType,
      'userId': userId,
      'type': type.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }
}

/// Content-specific engagement types for ARTbeat
enum EngagementType {
  like('like'),
  comment('comment'),
  reply('reply'),
  share('share'),
  seen('seen'),
  rate('rate'),
  review('review'),
  follow('follow'),
  boost('boost'),
  sponsor('sponsor'),
  message('message'),
  commission('commission'); // available for commission

  const EngagementType(this.value);
  final String value;

  static EngagementType fromString(String value) {
    if (value == 'gift') return EngagementType.boost;
    return EngagementType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => EngagementType.like,
    );
  }

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case EngagementType.like:
        return 'Like';
      case EngagementType.comment:
        return 'Comment';
      case EngagementType.reply:
        return 'Reply';
      case EngagementType.share:
        return 'Share';
      case EngagementType.seen:
        return 'Seen';
      case EngagementType.rate:
        return 'Rate';
      case EngagementType.review:
        return 'Review';
      case EngagementType.follow:
        return 'Follow';
      case EngagementType.boost:
        return 'Boost';
      case EngagementType.sponsor:
        return 'Sponsor';
      case EngagementType.message:
        return 'Message';
      case EngagementType.commission:
        return 'Commission';
    }
  }

  /// Get icon name for UI
  String get iconName {
    switch (this) {
      case EngagementType.like:
        return 'favorite'; // heart icon
      case EngagementType.comment:
        return 'chat_bubble_outline'; // chat bubble
      case EngagementType.reply:
        return 'reply'; // reply arrow
      case EngagementType.share:
        return 'share'; // share icon
      case EngagementType.seen:
        return 'visibility'; // eye icon
      case EngagementType.rate:
        return 'star_border'; // star for rating
      case EngagementType.review:
        return 'rate_review'; // review icon
      case EngagementType.follow:
        return 'person_add'; // follow icon
      case EngagementType.boost:
        return 'rocket_launch'; // boost icon
      case EngagementType.sponsor:
        return 'volunteer_activism'; // sponsor icon
      case EngagementType.message:
        return 'message'; // message icon
      case EngagementType.commission:
        return 'palette'; // commission icon (more art-related)
    }
  }

  /// Get past tense for notifications
  String get pastTense {
    switch (this) {
      case EngagementType.like:
        return 'liked';
      case EngagementType.comment:
        return 'commented on';
      case EngagementType.reply:
        return 'replied to';
      case EngagementType.share:
        return 'shared';
      case EngagementType.seen:
        return 'viewed';
      case EngagementType.rate:
        return 'rated';
      case EngagementType.review:
        return 'reviewed';
      case EngagementType.follow:
        return 'followed';
      case EngagementType.boost:
        return 'boosted';
      case EngagementType.sponsor:
        return 'sponsored';
      case EngagementType.message:
        return 'messaged';
      case EngagementType.commission:
        return 'requested a commission from';
    }
  }
}

/// Engagement statistics for any content
class EngagementStats {
  final int likeCount;
  final int commentCount;
  final int replyCount;
  final int shareCount;
  final int seenCount;
  final int rateCount;
  final int reviewCount;
  final int followCount;
  final int boostCount;
  final int sponsorCount;
  final int messageCount;
  final int commissionCount;
  final double totalBoostValue; // Total monetary value of boosts received
  final double
  totalSponsorValue; // Total monetary value of sponsorships received
  final DateTime lastUpdated;

  EngagementStats({
    this.likeCount = 0,
    this.commentCount = 0,
    this.replyCount = 0,
    this.shareCount = 0,
    this.seenCount = 0,
    this.rateCount = 0,
    this.reviewCount = 0,
    this.followCount = 0,
    this.boostCount = 0,
    this.sponsorCount = 0,
    this.messageCount = 0,
    this.commissionCount = 0,
    this.totalBoostValue = 0.0,
    this.totalSponsorValue = 0.0,
    required this.lastUpdated,
  });

  factory EngagementStats.fromFirestore(Map<String, dynamic> data) {
    return EngagementStats(
      // New fields with backward compatibility fallbacks
      likeCount:
          data['likeCount'] as int? ??
          data['appreciateCount'] as int? ??
          data['applauseCount'] as int? ??
          0,
      commentCount:
          data['commentCount'] as int? ?? data['discussCount'] as int? ?? 0,
      replyCount: data['replyCount'] as int? ?? 0,
      shareCount:
          data['shareCount'] as int? ?? data['amplifyCount'] as int? ?? 0,
      seenCount: data['seenCount'] as int? ?? 0,
      rateCount: data['rateCount'] as int? ?? 0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      followCount:
          data['followCount'] as int? ?? data['connectCount'] as int? ?? 0,
      boostCount: data['boostCount'] as int? ?? data['giftCount'] as int? ?? 0,
      sponsorCount: data['sponsorCount'] as int? ?? 0,
      messageCount: data['messageCount'] as int? ?? 0,
      commissionCount: data['commissionCount'] as int? ?? 0,
      totalBoostValue:
          (data['totalBoostValue'] as num? ?? data['totalGiftValue'] as num?)
              ?.toDouble() ??
          0.0,
      totalSponsorValue: (data['totalSponsorValue'] as num?)?.toDouble() ?? 0.0,
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory EngagementStats.fromMap(Map<String, dynamic> data) {
    return EngagementStats(
      likeCount: data['likeCount'] as int? ?? 0,
      commentCount: data['commentCount'] as int? ?? 0,
      replyCount: data['replyCount'] as int? ?? 0,
      shareCount: data['shareCount'] as int? ?? 0,
      seenCount: data['seenCount'] as int? ?? 0,
      rateCount: data['rateCount'] as int? ?? 0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      followCount: data['followCount'] as int? ?? 0,
      boostCount: data['boostCount'] as int? ?? data['giftCount'] as int? ?? 0,
      sponsorCount: data['sponsorCount'] as int? ?? 0,
      messageCount: data['messageCount'] as int? ?? 0,
      commissionCount: data['commissionCount'] as int? ?? 0,
      totalBoostValue:
          (data['totalBoostValue'] as num? ?? data['totalGiftValue'] as num?)
              ?.toDouble() ??
          0.0,
      totalSponsorValue: (data['totalSponsorValue'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: data['lastUpdated'] is Timestamp
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.tryParse(data['lastUpdated'] as String? ?? '') ??
                DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'likeCount': likeCount,
      'commentCount': commentCount,
      'replyCount': replyCount,
      'shareCount': shareCount,
      'seenCount': seenCount,
      'rateCount': rateCount,
      'reviewCount': reviewCount,
      'followCount': followCount,
      'boostCount': boostCount,
      'sponsorCount': sponsorCount,
      'messageCount': messageCount,
      'commissionCount': commissionCount,
      'totalBoostValue': totalBoostValue,
      'totalSponsorValue': totalSponsorValue,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'likeCount': likeCount,
      'commentCount': commentCount,
      'replyCount': replyCount,
      'shareCount': shareCount,
      'seenCount': seenCount,
      'rateCount': rateCount,
      'reviewCount': reviewCount,
      'followCount': followCount,
      'boostCount': boostCount,
      'sponsorCount': sponsorCount,
      'messageCount': messageCount,
      'commissionCount': commissionCount,
      'totalBoostValue': totalBoostValue,
      'totalSponsorValue': totalSponsorValue,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  EngagementStats copyWith({
    int? likeCount,
    int? commentCount,
    int? replyCount,
    int? shareCount,
    int? seenCount,
    int? rateCount,
    int? reviewCount,
    int? followCount,
    int? boostCount,
    int? sponsorCount,
    int? messageCount,
    int? commissionCount,
    double? totalBoostValue,
    double? totalSponsorValue,
    DateTime? lastUpdated,
  }) {
    return EngagementStats(
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      replyCount: replyCount ?? this.replyCount,
      shareCount: shareCount ?? this.shareCount,
      seenCount: seenCount ?? this.seenCount,
      rateCount: rateCount ?? this.rateCount,
      reviewCount: reviewCount ?? this.reviewCount,
      followCount: followCount ?? this.followCount,
      boostCount: boostCount ?? this.boostCount,
      sponsorCount: sponsorCount ?? this.sponsorCount,
      messageCount: messageCount ?? this.messageCount,
      commissionCount: commissionCount ?? this.commissionCount,
      totalBoostValue: totalBoostValue ?? this.totalBoostValue,
      totalSponsorValue: totalSponsorValue ?? this.totalSponsorValue,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get total engagement count
  int get totalEngagement =>
      likeCount +
      commentCount +
      replyCount +
      shareCount +
      seenCount +
      rateCount +
      reviewCount +
      followCount +
      boostCount +
      sponsorCount +
      messageCount +
      commissionCount;

  int get captureCount => 0;

  /// Get count for specific engagement type
  int getCount(EngagementType type) {
    switch (type) {
      case EngagementType.like:
        return likeCount;
      case EngagementType.comment:
        return commentCount;
      case EngagementType.reply:
        return replyCount;
      case EngagementType.share:
        return shareCount;
      case EngagementType.seen:
        return seenCount;
      case EngagementType.rate:
        return rateCount;
      case EngagementType.review:
        return reviewCount;
      case EngagementType.follow:
        return followCount;
      case EngagementType.boost:
        return boostCount;
      case EngagementType.sponsor:
        return sponsorCount;
      case EngagementType.message:
        return messageCount;
      case EngagementType.commission:
        return commissionCount;
    }
  }
}
