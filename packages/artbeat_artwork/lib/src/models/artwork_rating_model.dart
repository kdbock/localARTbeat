import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

/// Model representing an artwork rating in the ARTbeat platform
///
/// This model handles star ratings (1-5) for artwork pieces with user
/// attribution, timestamps, and optional review text.
class ArtworkRatingModel {
  final String id;
  final String artworkId;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final int rating; // 1-5 stars
  final String? reviewText; // Optional text review
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final bool isVerifiedPurchaser; // Did this user purchase the artwork?
  final String? purchaseId; // Link to purchase if applicable

  ArtworkRatingModel({
    required this.id,
    required this.artworkId,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.rating,
    this.reviewText,
    required this.createdAt,
    required this.updatedAt,
    this.isVerifiedPurchaser = false,
    this.purchaseId,
  });

  factory ArtworkRatingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ArtworkRatingModel(
      id: doc.id,
      artworkId: FirestoreUtils.safeStringDefault(data['artworkId']),
      userId: FirestoreUtils.safeStringDefault(data['userId']),
      userName: FirestoreUtils.safeStringDefault(data['userName'], 'Anonymous'),
      userAvatarUrl: FirestoreUtils.safeStringDefault(data['userAvatarUrl']),
      rating: FirestoreUtils.safeInt(data['rating'], 5),
      reviewText: FirestoreUtils.safeString(data['reviewText']),
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : Timestamp.fromDate(FirestoreUtils.safeDateTime(data['createdAt'])),
      updatedAt: data['updatedAt'] is Timestamp
          ? data['updatedAt'] as Timestamp
          : Timestamp.fromDate(FirestoreUtils.safeDateTime(data['updatedAt'])),
      isVerifiedPurchaser:
          FirestoreUtils.safeBool(data['isVerifiedPurchaser'], false),
      purchaseId: FirestoreUtils.safeString(data['purchaseId']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'artworkId': artworkId,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'rating': rating,
      'reviewText': reviewText,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isVerifiedPurchaser': isVerifiedPurchaser,
      'purchaseId': purchaseId,
    };
  }

  ArtworkRatingModel copyWith({
    String? id,
    String? artworkId,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    int? rating,
    String? reviewText,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    bool? isVerifiedPurchaser,
    String? purchaseId,
  }) {
    return ArtworkRatingModel(
      id: id ?? this.id,
      artworkId: artworkId ?? this.artworkId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerifiedPurchaser: isVerifiedPurchaser ?? this.isVerifiedPurchaser,
      purchaseId: purchaseId ?? this.purchaseId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArtworkRatingModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ArtworkRatingModel(id: $id, artworkId: $artworkId, rating: $rating, userName: $userName)';
  }
}

/// Aggregated rating statistics for an artwork
class ArtworkRatingStats {
  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingDistribution; // star -> count
  final int oneStarCount;
  final int twoStarCount;
  final int threeStarCount;
  final int fourStarCount;
  final int fiveStarCount;

  ArtworkRatingStats({
    required this.averageRating,
    required this.totalRatings,
    required this.ratingDistribution,
    required this.oneStarCount,
    required this.twoStarCount,
    required this.threeStarCount,
    required this.fourStarCount,
    required this.fiveStarCount,
  });

  factory ArtworkRatingStats.empty() {
    return ArtworkRatingStats(
      averageRating: 0.0,
      totalRatings: 0,
      ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      oneStarCount: 0,
      twoStarCount: 0,
      threeStarCount: 0,
      fourStarCount: 0,
      fiveStarCount: 0,
    );
  }

  factory ArtworkRatingStats.fromRatings(List<ArtworkRatingModel> ratings) {
    if (ratings.isEmpty) {
      return ArtworkRatingStats.empty();
    }

    final ratingDistribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    double totalScore = 0.0;

    for (final rating in ratings) {
      totalScore += rating.rating;
      ratingDistribution[rating.rating] =
          (ratingDistribution[rating.rating] ?? 0) + 1;
    }

    return ArtworkRatingStats(
      averageRating: totalScore / ratings.length,
      totalRatings: ratings.length,
      ratingDistribution: ratingDistribution,
      oneStarCount: ratingDistribution[1] ?? 0,
      twoStarCount: ratingDistribution[2] ?? 0,
      threeStarCount: ratingDistribution[3] ?? 0,
      fourStarCount: ratingDistribution[4] ?? 0,
      fiveStarCount: ratingDistribution[5] ?? 0,
    );
  }
}
