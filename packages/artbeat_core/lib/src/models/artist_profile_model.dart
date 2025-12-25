import 'package:cloud_firestore/cloud_firestore.dart';
import 'subscription_tier.dart';

import 'user_type.dart';

/// Model for artist profiles
class ArtistProfileModel {
  final String id;
  final String userId;
  final String displayName;
  final String username;
  final String? bio;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final String? website;
  final String? location;
  final UserType userType;
  final SubscriptionTier subscriptionTier;
  final bool isVerified;
  final bool isFeatured;
  final bool isPortfolioPublic;
  final List<String> mediums;
  final List<String> styles;
  final Map<String, String> socialLinks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFollowing;
  final int likesCount;
  final int viewsCount;
  final int artworksCount;
  final int followersCount;

  ArtistProfileModel({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.username,
    this.bio,
    this.profileImageUrl,
    this.coverImageUrl,
    this.website,
    this.location,
    required this.userType,
    this.subscriptionTier = SubscriptionTier.starter,
    this.isVerified = false,
    this.isFeatured = false,
    this.isPortfolioPublic = true,
    this.mediums = const [],
    this.styles = const [],
    this.socialLinks = const {},
    required this.createdAt,
    required this.updatedAt,
    this.isFollowing = false,
    this.likesCount = 0,
    this.viewsCount = 0,
    this.artworksCount = 0,
    this.followersCount = 0,
  });

  /// Create from Firestore document
  factory ArtistProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Check if this is a user document (has fullName) or artist profile document
    final isUserDoc = data['fullName'] != null && data['userId'] == null;

    final String userId = isUserDoc
        ? doc.id
        : (data['userId'] as String?) ?? '';
    final String displayName = isUserDoc
        ? (data['fullName'] as String?) ?? 'Unknown Artist'
        : (data['displayName'] as String?) ?? 'Unknown Artist';

    return ArtistProfileModel(
      id: doc.id,
      userId: userId,
      displayName: displayName,
      username: data['username'] as String? ?? '',
      bio: data['bio'] as String?,
      profileImageUrl:
          data['profileImageUrl'] as String? ?? data['avatarUrl'] as String?,
      coverImageUrl: data['coverImageUrl'] as String?,
      website: data['website'] as String?,
      location: data['location'] as String? ?? data['zipCode'] as String?,
      userType: _parseUserType(data['userType']),
      subscriptionTier: _parseSubscriptionTier(data['subscriptionTier']),
      isVerified: data['isVerified'] as bool? ?? false,
      isFeatured: data['isFeatured'] as bool? ?? false,
      isPortfolioPublic: data['isPortfolioPublic'] as bool? ?? true,
      mediums: _parseStringList(data['mediums']),
      styles: _parseStringList(data['styles']),
      socialLinks: _parseStringMap(data['socialLinks']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isFollowing: data['isFollowing'] as bool? ?? false,
      likesCount: data['likesCount'] as int? ?? 0,
      viewsCount: data['viewsCount'] as int? ?? 0,
      artworksCount: data['artworksCount'] as int? ?? 0,
      followersCount:
          data['followersCount'] as int? ?? data['followerCount'] as int? ?? 0,
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'coverImageUrl': coverImageUrl,
      'website': website,
      'location': location,
      'userType': userType.name,
      'subscriptionTier': subscriptionTier.name,
      'isVerified': isVerified,
      'isFeatured': isFeatured,
      'isPortfolioPublic': isPortfolioPublic,
      'mediums': mediums,
      'styles': styles,
      'socialLinks': socialLinks,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'likesCount': likesCount,
      'viewsCount': viewsCount,
      'artworksCount': artworksCount,
      'followersCount': followersCount,
      // isFollowing is not stored in Firestore as it's user-specific
    };
  }

  /// Parse user type from string or int
  static UserType _parseUserType(dynamic value) {
    if (value is String) {
      return UserType.fromString(value);
    } else if (value is int && value >= 0 && value < UserType.values.length) {
      return UserType.values[value];
    }
    return UserType.regular;
  }

  /// Parse subscription tier from string or int
  static SubscriptionTier _parseSubscriptionTier(dynamic value) {
    if (value is String) {
      return SubscriptionTier.fromLegacyName(value);
    } else if (value is int &&
        value >= 0 &&
        value < SubscriptionTier.values.length) {
      return SubscriptionTier.values[value];
    }
    return SubscriptionTier.free;
  }

  /// Parse list of strings from dynamic value
  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  /// Parse map of strings from dynamic value
  static Map<String, String> _parseStringMap(dynamic value) {
    if (value is Map) {
      return Map<String, String>.from(value);
    }
    return {};
  }

  /// Check if artist has a free subscription
  bool get isBasicSubscription =>
      subscriptionTier == SubscriptionTier.free ||
      subscriptionTier == SubscriptionTier.starter;

  /// Check if artist has a pro subscription
  bool get isProSubscription => subscriptionTier == SubscriptionTier.creator;

  /// Check if artist has a gallery subscription
  bool get isGallerySubscription =>
      subscriptionTier == SubscriptionTier.business;

  /// Get maximum number of artworks allowed for this subscription
  int get maxArtworkCount {
    switch (subscriptionTier) {
      case SubscriptionTier.free:
      case SubscriptionTier.starter:
        return 5;
      case SubscriptionTier.creator:
        return 100;
      case SubscriptionTier.business:
        return 1000;
      case SubscriptionTier.enterprise:
        return 10000;
    }
  }

  /// Check if artist can upload more artwork
  Future<bool> canUploadMoreArtwork() async {
    final artworkRef = FirebaseFirestore.instance.collection('artwork');
    final count = await artworkRef
        .where('userId', isEqualTo: userId)
        .count()
        .get();

    return (count.count ?? 0) < maxArtworkCount;
  }

  /// Create a copy of this model with the given fields replaced with new values
  ArtistProfileModel copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? username,
    String? bio,
    String? profileImageUrl,
    String? coverImageUrl,
    String? website,
    String? location,
    UserType? userType,
    SubscriptionTier? subscriptionTier,
    bool? isVerified,
    bool? isFeatured,
    bool? isPortfolioPublic,
    List<String>? mediums,
    List<String>? styles,
    Map<String, String>? socialLinks,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFollowing,
    int? likesCount,
    int? viewsCount,
    int? artworksCount,
    int? followersCount,
  }) {
    return ArtistProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      website: website ?? this.website,
      location: location ?? this.location,
      userType: userType ?? this.userType,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      isVerified: isVerified ?? this.isVerified,
      isFeatured: isFeatured ?? this.isFeatured,
      isPortfolioPublic: isPortfolioPublic ?? this.isPortfolioPublic,
      mediums: mediums ?? this.mediums,
      styles: styles ?? this.styles,
      socialLinks: socialLinks ?? this.socialLinks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFollowing: isFollowing ?? this.isFollowing,
      likesCount: likesCount ?? this.likesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      artworksCount: artworksCount ?? this.artworksCount,
      followersCount: followersCount ?? this.followersCount,
    );
  }
}
