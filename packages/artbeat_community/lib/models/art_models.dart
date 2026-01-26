import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

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
      userId: FirestoreUtils.safeStringDefault(data['userId']),
      userName: FirestoreUtils.safeStringDefault(data['userName']),
      userAvatarUrl: FirestoreUtils.safeStringDefault(data['userAvatarUrl']),
      content: FirestoreUtils.safeStringDefault(data['content']),
      imageUrls: (data['imageUrls'] as Iterable? ?? [])
          .map((e) => e.toString())
          .toList(),
      tags: (data['tags'] as Iterable? ?? [])
          .map((e) => e.toString())
          .toList(),
      createdAt: FirestoreUtils.safeDateTime(data['createdAt']),
      likesCount: FirestoreUtils.safeInt(data['likesCount']),
      commentsCount: FirestoreUtils.safeInt(data['commentsCount']),
      reportCount: FirestoreUtils.safeInt(data['reportCount']),
      isArtistPost: FirestoreUtils.safeBool(data['isArtistPost'], false),
      isUserVerified: FirestoreUtils.safeBool(data['isUserVerified'], false),
      isLikedByCurrentUser: FirestoreUtils.safeBool(data['isLikedByCurrentUser']),
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
        FirestoreUtils.safeStringDefault(data['avatarUrl'] ?? data['profileImageUrl'] ?? data['photoURL']);

    // Try multiple field names for portfolio images
    // First check for portfolioImages array
    List<String> portfolioImages = (data['portfolioImages'] as Iterable? ?? [])
        .map((e) => e.toString())
        .toList();

    // If empty, check for artworkImages array
    if (portfolioImages.isEmpty) {
      portfolioImages = (data['artworkImages'] as Iterable? ?? [])
          .map((e) => e.toString())
          .toList();
    }

    // If still empty, check for coverImageUrl (single image)
    if (portfolioImages.isEmpty) {
      final coverImageUrl = FirestoreUtils.safeString(data['coverImageUrl']);
      if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
        portfolioImages = [coverImageUrl];
      }
    }

    // Try multiple field names for specialties
    List<String> specialties =
        (data['specialties'] as Iterable? ?? []).map((e) => e.toString()).toList();
    if (specialties.isEmpty) {
      specialties = (data['mediums'] as Iterable? ?? []).map((e) => e.toString()).toList();
    }

    return ArtistProfile(
      userId: FirestoreUtils.safeStringDefault(data['userId'], doc.id),
      displayName: FirestoreUtils.safeStringDefault(data['displayName'] ?? data['fullName']),
      bio: FirestoreUtils.safeStringDefault(data['bio']),
      avatarUrl: avatarUrl,
      specialties: specialties,
      portfolioImages: portfolioImages,
      isVerified: FirestoreUtils.safeBool(data['isVerified'], false),
      followersCount: FirestoreUtils.safeInt(data['followersCount']),
      createdAt: FirestoreUtils.safeDateTime(data['createdAt']),
      boostScore: FirestoreUtils.safeDouble(
        data['boostScore'] ?? data['artistMomentum'] ?? data['momentum'],
      ),
      lastBoostAt: data['lastBoostAt'] != null || data['boostedAt'] != null
          ? FirestoreUtils.safeDateTime(data['lastBoostAt'] ?? data['boostedAt'])
          : null,
      boostStreakMonths: FirestoreUtils.safeInt(data['boostStreakMonths']),
      boostStreakUpdatedAt: data['boostStreakUpdatedAt'] != null
          ? FirestoreUtils.safeDateTime(data['boostStreakUpdatedAt'])
          : null,
      location: FirestoreUtils.safeString(data['location'] ?? data['zipCode']),
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
      boostStreakUpdatedAt: boostStreakUpdatedAt ?? this.boostStreakUpdatedAt,
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
