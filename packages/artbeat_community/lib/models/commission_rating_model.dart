import 'package:cloud_firestore/cloud_firestore.dart';

/// Commission rating and review model
class CommissionRating {
  final String id;
  final String commissionId;
  final String ratedById;
  final String ratedByName;
  final String ratedUserId;
  final String ratedUserName;
  final double overallRating; // 1-5 stars
  final double qualityRating; // 1-5 stars
  final double communicationRating; // 1-5 stars
  final double timelinessRating; // 1-5 stars
  final String comment;
  final bool wouldRecommend;
  final List<String>
  tags; // excellent-quality, great-communication, fast-delivery, etc.
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isArtistRating; // true if artist rated, false if client rated
  final int helpfulCount; // Number of people who found this helpful
  final bool? isPublic; // Whether visible to others
  final Map<String, dynamic> metadata;

  CommissionRating({
    required this.id,
    required this.commissionId,
    required this.ratedById,
    required this.ratedByName,
    required this.ratedUserId,
    required this.ratedUserName,
    required this.overallRating,
    required this.qualityRating,
    required this.communicationRating,
    required this.timelinessRating,
    required this.comment,
    required this.wouldRecommend,
    required this.tags,
    required this.createdAt,
    this.updatedAt,
    required this.isArtistRating,
    this.helpfulCount = 0,
    this.isPublic = true,
    required this.metadata,
  });

  // Calculate average rating
  double get averageRating =>
      (qualityRating + communicationRating + timelinessRating) / 3;

  factory CommissionRating.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CommissionRating(
      id: doc.id,
      commissionId: data['commissionId'] as String? ?? '',
      ratedById: data['ratedById'] as String? ?? '',
      ratedByName: data['ratedByName'] as String? ?? '',
      ratedUserId: data['ratedUserId'] as String? ?? '',
      ratedUserName: data['ratedUserName'] as String? ?? '',
      overallRating: (data['overallRating'] as num?)?.toDouble() ?? 0.0,
      qualityRating: (data['qualityRating'] as num?)?.toDouble() ?? 0.0,
      communicationRating:
          (data['communicationRating'] as num?)?.toDouble() ?? 0.0,
      timelinessRating: (data['timelinessRating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] as String? ?? '',
      wouldRecommend: data['wouldRecommend'] as bool? ?? false,
      tags: List<String>.from(data['tags'] as List<dynamic>? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isArtistRating: data['isArtistRating'] as bool? ?? false,
      helpfulCount: data['helpfulCount'] as int? ?? 0,
      isPublic: data['isPublic'] as bool? ?? true,
      metadata: Map<String, dynamic>.from(
        data['metadata'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = {
      'commissionId': commissionId,
      'ratedById': ratedById,
      'ratedByName': ratedByName,
      'ratedUserId': ratedUserId,
      'ratedUserName': ratedUserName,
      'overallRating': overallRating,
      'qualityRating': qualityRating,
      'communicationRating': communicationRating,
      'timelinessRating': timelinessRating,
      'comment': comment,
      'wouldRecommend': wouldRecommend,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isArtistRating': isArtistRating,
      'helpfulCount': helpfulCount,
      'isPublic': isPublic,
      'metadata': metadata,
    };
    // Remove null values to prevent iOS crash in cloud_firestore plugin
    map.removeWhere((key, value) => value == null);
    return map;
  }

  CommissionRating copyWith({
    String? id,
    String? commissionId,
    String? ratedById,
    String? ratedByName,
    String? ratedUserId,
    String? ratedUserName,
    double? overallRating,
    double? qualityRating,
    double? communicationRating,
    double? timelinessRating,
    String? comment,
    bool? wouldRecommend,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArtistRating,
    int? helpfulCount,
    bool? isPublic,
    Map<String, dynamic>? metadata,
  }) {
    return CommissionRating(
      id: id ?? this.id,
      commissionId: commissionId ?? this.commissionId,
      ratedById: ratedById ?? this.ratedById,
      ratedByName: ratedByName ?? this.ratedByName,
      ratedUserId: ratedUserId ?? this.ratedUserId,
      ratedUserName: ratedUserName ?? this.ratedUserName,
      overallRating: overallRating ?? this.overallRating,
      qualityRating: qualityRating ?? this.qualityRating,
      communicationRating: communicationRating ?? this.communicationRating,
      timelinessRating: timelinessRating ?? this.timelinessRating,
      comment: comment ?? this.comment,
      wouldRecommend: wouldRecommend ?? this.wouldRecommend,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArtistRating: isArtistRating ?? this.isArtistRating,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      isPublic: isPublic ?? this.isPublic,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Artist reputation summary
class ArtistReputation {
  final String artistId;
  final String artistName;
  final double overallRating; // 1-5 average
  final double qualityRating;
  final double communicationRating;
  final double timelinessRating;
  final int totalRatings;
  final int recommendCount;
  final List<CommissionRating> recentRatings;
  final Map<String, int> ratingDistribution; // {"5": 10, "4": 5, ...}
  final DateTime updatedAt;

  ArtistReputation({
    required this.artistId,
    required this.artistName,
    required this.overallRating,
    required this.qualityRating,
    required this.communicationRating,
    required this.timelinessRating,
    required this.totalRatings,
    required this.recommendCount,
    required this.recentRatings,
    required this.ratingDistribution,
    required this.updatedAt,
  });

  // Calculate recommendation percentage
  double get recommendPercentage =>
      totalRatings > 0 ? (recommendCount / totalRatings) * 100 : 0;

  factory ArtistReputation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ArtistReputation(
      artistId: data['artistId'] as String? ?? '',
      artistName: data['artistName'] as String? ?? '',
      overallRating: (data['overallRating'] as num?)?.toDouble() ?? 0.0,
      qualityRating: (data['qualityRating'] as num?)?.toDouble() ?? 0.0,
      communicationRating:
          (data['communicationRating'] as num?)?.toDouble() ?? 0.0,
      timelinessRating: (data['timelinessRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: data['totalRatings'] as int? ?? 0,
      recommendCount: data['recommendCount'] as int? ?? 0,
      recentRatings: [],
      ratingDistribution: Map<String, int>.from(
        data['ratingDistribution'] as Map<String, dynamic>? ?? {},
      ),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'artistId': artistId,
      'artistName': artistName,
      'overallRating': overallRating,
      'qualityRating': qualityRating,
      'communicationRating': communicationRating,
      'timelinessRating': timelinessRating,
      'totalRatings': totalRatings,
      'recommendCount': recommendCount,
      'ratingDistribution': ratingDistribution,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
