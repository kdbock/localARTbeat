import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_utils.dart';

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
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EngagementModel(
      id: doc.id,
      contentId: FirestoreUtils.safeStringDefault(data['contentId']),
      contentType: FirestoreUtils.safeStringDefault(data['contentType']),
      userId: FirestoreUtils.safeStringDefault(data['userId']),
      type: EngagementType.fromString(
        FirestoreUtils.safeStringDefault(data['type']),
      ),
      createdAt: FirestoreUtils.safeDateTime(data['createdAt']),
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
      likeCount: FirestoreUtils.safeInt(
        data['likeCount'] ?? data['appreciateCount'] ?? data['applauseCount'],
      ),
      commentCount: FirestoreUtils.safeInt(
        data['commentCount'] ?? data['discussCount'],
      ),
      replyCount: FirestoreUtils.safeInt(data['replyCount']),
      shareCount: FirestoreUtils.safeInt(
        data['shareCount'] ?? data['amplifyCount'],
      ),
      seenCount: FirestoreUtils.safeInt(data['seenCount']),
      rateCount: FirestoreUtils.safeInt(data['rateCount']),
      reviewCount: FirestoreUtils.safeInt(data['reviewCount']),
      followCount: FirestoreUtils.safeInt(
        data['followCount'] ?? data['connectCount'],
      ),
      boostCount: FirestoreUtils.safeInt(data['boostCount'] ?? data['giftCount']),
      sponsorCount: FirestoreUtils.safeInt(data['sponsorCount']),
      messageCount: FirestoreUtils.safeInt(data['messageCount']),
      commissionCount: FirestoreUtils.safeInt(data['commissionCount']),
      totalBoostValue: FirestoreUtils.safeDouble(
        data['totalBoostValue'] ?? data['totalGiftValue'],
      ),
      totalSponsorValue: FirestoreUtils.safeDouble(data['totalSponsorValue']),
      lastUpdated: FirestoreUtils.safeDateTime(data['lastUpdated']),
    );
  }

  factory EngagementStats.fromMap(Map<String, dynamic> data) {
    return EngagementStats(
      likeCount: FirestoreUtils.safeInt(data['likeCount']),
      commentCount: FirestoreUtils.safeInt(data['commentCount']),
      replyCount: FirestoreUtils.safeInt(data['replyCount']),
      shareCount: FirestoreUtils.safeInt(data['shareCount']),
      seenCount: FirestoreUtils.safeInt(data['seenCount']),
      rateCount: FirestoreUtils.safeInt(data['rateCount']),
      reviewCount: FirestoreUtils.safeInt(data['reviewCount']),
      followCount: FirestoreUtils.safeInt(data['followCount']),
      boostCount: FirestoreUtils.safeInt(data['boostCount'] ?? data['giftCount']),
      sponsorCount: FirestoreUtils.safeInt(data['sponsorCount']),
      messageCount: FirestoreUtils.safeInt(data['messageCount']),
      commissionCount: FirestoreUtils.safeInt(data['commissionCount']),
      totalBoostValue: FirestoreUtils.safeDouble(
        data['totalBoostValue'] ?? data['totalGiftValue'],
      ),
      totalSponsorValue: FirestoreUtils.safeDouble(data['totalSponsorValue']),
      lastUpdated: FirestoreUtils.safeDateTime(data['lastUpdated']),
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
