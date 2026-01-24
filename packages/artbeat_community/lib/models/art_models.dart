import 'package:cloud_firestore/cloud_firestore.dart';

/// Simplified post model focused on art sharing
class ArtPost {
  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String content;
  final List<String> imageUrls;
  final List<String> tags;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final int reportCount;
  final bool isArtistPost;
  final bool isUserVerified;
  final bool? isLikedByCurrentUser;

  const ArtPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.content,
    required this.imageUrls,
    required this.tags,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.reportCount = 0,
    this.isArtistPost = false,
    this.isUserVerified = false,
    this.isLikedByCurrentUser,
  });

  /// Create from Firestore document
  factory ArtPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ArtPost(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userAvatarUrl: data['userAvatarUrl'] as String? ?? '',
      content: data['content'] as String? ?? '',
      imageUrls: List<String>.from(data['imageUrls'] as Iterable? ?? []),
      tags: List<String>.from(data['tags'] as Iterable? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likesCount: data['likesCount'] as int? ?? 0,
      commentsCount: data['commentsCount'] as int? ?? 0,
      reportCount: data['reportCount'] as int? ?? 0,
      isArtistPost: data['isArtistPost'] as bool? ?? false,
      isUserVerified: data['isUserVerified'] as bool? ?? false,
      isLikedByCurrentUser: data['isLikedByCurrentUser'] as bool?,
    );
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'content': content,
      'imageUrls': imageUrls,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'reportCount': reportCount,
      'isArtistPost': isArtistPost,
      'isUserVerified': isUserVerified,
      if (isLikedByCurrentUser != null)
        'isLikedByCurrentUser': isLikedByCurrentUser,
    };
  }

  /// Create copy with updated fields
  ArtPost copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? content,
    List<String>? imageUrls,
    List<String>? tags,
    DateTime? createdAt,
    int? likesCount,
    int? commentsCount,
    int? reportCount,
    bool? isArtistPost,
    bool? isUserVerified,
    bool? isLikedByCurrentUser,
  }) {
    return ArtPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      reportCount: reportCount ?? this.reportCount,
      isArtistPost: isArtistPost ?? this.isArtistPost,
      isUserVerified: isUserVerified ?? this.isUserVerified,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
    );
  }
}

/// Simplified artist profile model
class ArtistProfile {
  final String userId;
  final String displayName;
  final String bio;
  final String avatarUrl;
  final List<String> specialties;
  final List<String> portfolioImages;
  final bool isVerified;
  final int followersCount;
  final DateTime createdAt;
  final bool isFollowedByCurrentUser;
  final double boostScore;
  final DateTime? lastBoostAt;
  final int boostStreakMonths;
  final DateTime? boostStreakUpdatedAt;
  final String? location;

  const ArtistProfile({
    required this.userId,
    required this.displayName,
    required this.bio,
    required this.avatarUrl,
    required this.specialties,
    required this.portfolioImages,
    this.isVerified = false,
    this.followersCount = 0,
    required this.createdAt,
    this.isFollowedByCurrentUser = false,
    this.boostScore = 0.0,
    this.lastBoostAt,
    this.boostStreakMonths = 0,
    this.boostStreakUpdatedAt,
    this.location,
  });

  /// Create from Firestore document
  factory ArtistProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Try both 'avatarUrl' and 'profileImageUrl' for avatar
    final String avatarUrl =
        (data['avatarUrl'] as String?) ??
        (data['profileImageUrl'] as String?) ??
        (data['photoURL'] as String?) ??
        '';

    // Try multiple field names for portfolio images
    // First check for portfolioImages array
    List<String> portfolioImages = List<String>.from(
      data['portfolioImages'] as Iterable? ?? [],
    );

    // If empty, check for artworkImages array
    if (portfolioImages.isEmpty) {
      portfolioImages = List<String>.from(
        data['artworkImages'] as Iterable? ?? [],
      );
    }

    // If still empty, check for coverImageUrl (single image)
    if (portfolioImages.isEmpty) {
      final coverImageUrl = data['coverImageUrl'] as String?;
      if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
        portfolioImages = [coverImageUrl];
      }
    }

    // Try multiple field names for specialties
    final List<String> specialties =
        List<String>.from(data['specialties'] as Iterable? ?? []).isNotEmpty
        ? List<String>.from(data['specialties'] as Iterable? ?? [])
        : List<String>.from(data['mediums'] as Iterable? ?? []);

    return ArtistProfile(
      userId: data['userId'] as String? ?? doc.id,
      displayName:
          data['displayName'] as String? ?? data['fullName'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      avatarUrl: avatarUrl,
      specialties: specialties,
      portfolioImages: portfolioImages,
      isVerified: data['isVerified'] as bool? ?? false,
      followersCount: data['followersCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      boostScore: (data['boostScore'] as num?)?.toDouble() ??
          (data['artistMomentum'] as num?)?.toDouble() ??
          (data['momentum'] as num?)?.toDouble() ??
          0.0,
      lastBoostAt:
          (data['lastBoostAt'] as Timestamp?)?.toDate() ??
          (data['boostedAt'] as Timestamp?)?.toDate(),
      boostStreakMonths: (data['boostStreakMonths'] as num?)?.toInt() ?? 0,
      boostStreakUpdatedAt:
          (data['boostStreakUpdatedAt'] as Timestamp?)?.toDate(),
      location: data['location'] as String? ?? data['zipCode'] as String?,
    );
  }

  bool get hasActiveBoost {
    if (boostScore <= 0 || lastBoostAt == null) return false;
    return DateTime.now().difference(lastBoostAt!).inDays <= 7;
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'displayName': displayName,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'specialties': specialties,
      'portfolioImages': portfolioImages,
      'isVerified': isVerified,
      'followersCount': followersCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create copy with updated fields
  ArtistProfile copyWith({
    String? userId,
    String? displayName,
    String? bio,
    String? avatarUrl,
    List<String>? specialties,
    List<String>? portfolioImages,
    bool? isVerified,
    int? followersCount,
    DateTime? createdAt,
    bool? isFollowedByCurrentUser,
    double? boostScore,
    DateTime? lastBoostAt,
    int? boostStreakMonths,
    DateTime? boostStreakUpdatedAt,
    String? location,
  }) {
    return ArtistProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      specialties: specialties ?? this.specialties,
      portfolioImages: portfolioImages ?? this.portfolioImages,
      isVerified: isVerified ?? this.isVerified,
      followersCount: followersCount ?? this.followersCount,
      createdAt: createdAt ?? this.createdAt,
      isFollowedByCurrentUser:
          isFollowedByCurrentUser ?? this.isFollowedByCurrentUser,
      boostScore: boostScore ?? this.boostScore,
      lastBoostAt: lastBoostAt ?? this.lastBoostAt,
      boostStreakMonths: boostStreakMonths ?? this.boostStreakMonths,
      boostStreakUpdatedAt:
          boostStreakUpdatedAt ?? this.boostStreakUpdatedAt,
      location: location ?? this.location,
    );
  }
}

/// Simplified comment model
class ArtComment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String content;
  final DateTime createdAt;
  final int likesCount;

  const ArtComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.content,
    required this.createdAt,
    this.likesCount = 0,
  });

  /// Create from Firestore document
  factory ArtComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ArtComment(
      id: doc.id,
      postId: data['postId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userAvatarUrl: data['userAvatarUrl'] as String? ?? '',
      content: data['content'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likesCount: data['likesCount'] as int? ?? 0,
    );
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'likesCount': likesCount,
    };
  }
}
