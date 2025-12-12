import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for tracking top engaged followers
class TopFollowerModel {
  final String followerId;
  final String followerName;
  final String? followerAvatarUrl;
  final int engagementScore;
  final int giftCount;
  final int likeCount;
  final int messageCount;
  final int viewCount;
  final DateTime lastEngagementAt;
  final bool isVerified;

  TopFollowerModel({
    required this.followerId,
    required this.followerName,
    this.followerAvatarUrl,
    required this.engagementScore,
    this.giftCount = 0,
    this.likeCount = 0,
    this.messageCount = 0,
    this.viewCount = 0,
    required this.lastEngagementAt,
    this.isVerified = false,
  });

  factory TopFollowerModel.fromMap(Map<String, dynamic> map) {
    return TopFollowerModel(
      followerId: (map['followerId'] ?? '').toString(),
      followerName: (map['followerName'] ?? '').toString(),
      followerAvatarUrl: map['followerAvatarUrl'] != null
          ? map['followerAvatarUrl'].toString()
          : null,
      engagementScore:
          map['engagementScore'] is int ? map['engagementScore'] as int : 0,
      giftCount: map['giftCount'] is int ? map['giftCount'] as int : 0,
      likeCount: map['likeCount'] is int ? map['likeCount'] as int : 0,
      messageCount: map['messageCount'] is int ? map['messageCount'] as int : 0,
      viewCount: map['viewCount'] is int ? map['viewCount'] as int : 0,
      lastEngagementAt: map['lastEngagementAt'] is Timestamp
          ? (map['lastEngagementAt'] as Timestamp).toDate()
          : DateTime.now(),
      isVerified: map['isVerified'] is bool ? map['isVerified'] as bool : false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'followerId': followerId,
      'followerName': followerName,
      'followerAvatarUrl': followerAvatarUrl,
      'engagementScore': engagementScore,
      'giftCount': giftCount,
      'likeCount': likeCount,
      'messageCount': messageCount,
      'viewCount': viewCount,
      'lastEngagementAt': lastEngagementAt,
      'isVerified': isVerified,
    };
  }

  TopFollowerModel copyWith({
    String? followerId,
    String? followerName,
    String? followerAvatarUrl,
    int? engagementScore,
    int? giftCount,
    int? likeCount,
    int? messageCount,
    int? viewCount,
    DateTime? lastEngagementAt,
    bool? isVerified,
  }) {
    return TopFollowerModel(
      followerId: followerId ?? this.followerId,
      followerName: followerName ?? this.followerName,
      followerAvatarUrl: followerAvatarUrl ?? this.followerAvatarUrl,
      engagementScore: engagementScore ?? this.engagementScore,
      giftCount: giftCount ?? this.giftCount,
      likeCount: likeCount ?? this.likeCount,
      messageCount: messageCount ?? this.messageCount,
      viewCount: viewCount ?? this.viewCount,
      lastEngagementAt: lastEngagementAt ?? this.lastEngagementAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
