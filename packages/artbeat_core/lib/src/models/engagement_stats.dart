import 'package:cloud_firestore/cloud_firestore.dart';

class EngagementStats {
  final int connectCount;
  final int captureCount;
  final int shareCount;
  final int createdCount;
  final int celebrateCount;
  final int likeCount;
  final int commentCount;
  final int seenCount;
  final int followCount;
  final double averageRating;
  final int totalRatings;
  final DateTime lastUpdated;

  EngagementStats({
    this.connectCount = 0,
    this.captureCount = 0,
    this.shareCount = 0,
    this.createdCount = 0,
    this.celebrateCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.seenCount = 0,
    this.followCount = 0,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    required this.lastUpdated,
  });

  factory EngagementStats.fromJson(Map<String, dynamic> json) {
    return EngagementStats(
      connectCount: json['connectCount'] as int? ?? 0,
      captureCount: json['captureCount'] as int? ?? 0,
      shareCount: json['shareCount'] as int? ?? 0,
      createdCount: json['createdCount'] as int? ?? 0,
      celebrateCount: json['celebrateCount'] as int? ?? 0,
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      seenCount: json['seenCount'] as int? ?? 0,
      followCount: json['followCount'] as int? ?? 0,
      averageRating: (json['averageRating'] as num? ?? 0.0).toDouble(),
      totalRatings: json['totalRatings'] as int? ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? (json['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'connectCount': connectCount,
      'captureCount': captureCount,
      'shareCount': shareCount,
      'createdCount': createdCount,
      'celebrateCount': celebrateCount,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'seenCount': seenCount,
      'followCount': followCount,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  Map<String, dynamic> toFirestore() => toJson();

  factory EngagementStats.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) {
      return EngagementStats(lastUpdated: DateTime.now());
    }
    return EngagementStats.fromJson(data);
  }
}
