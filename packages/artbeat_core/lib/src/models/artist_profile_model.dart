import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_utils.dart';
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
  final double? locationLat;
  final double? locationLng;
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
  final double boostScore;
  final DateTime? lastBoostAt;
  final int boostStreakMonths;
  final DateTime? boostStreakUpdatedAt;
  final DateTime? mapGlowUntil;
  final DateTime? kioskLaneUntil;

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
    this.locationLat,
    this.locationLng,
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
    this.boostScore = 0.0,
    this.lastBoostAt,
    this.boostStreakMonths = 0,
    this.boostStreakUpdatedAt,
    this.mapGlowUntil,
    this.kioskLaneUntil,
  });

  /// Create from Firestore document
  factory ArtistProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Check if this is a user document (has fullName) or artist profile document
    final isUserDoc = data['fullName'] != null && data['userId'] == null;

    final String userId = isUserDoc
        ? doc.id
        : FirestoreUtils.safeStringDefault(data['userId']);
    final String displayName = isUserDoc
        ? FirestoreUtils.safeStringDefault(data['fullName'], 'Unknown Artist')
        : FirestoreUtils.safeStringDefault(data['displayName'], 'Unknown Artist');

    return ArtistProfileModel(
      id: doc.id,
      userId: userId,
      displayName: displayName,
      username: FirestoreUtils.safeStringDefault(data['username']),
      bio: FirestoreUtils.safeString(data['bio']),
      profileImageUrl: FirestoreUtils.safeString(
        data['profileImageUrl'] ?? data['avatarUrl'],
      ),
      coverImageUrl: FirestoreUtils.safeString(data['coverImageUrl']),
      website: FirestoreUtils.safeString(data['website']),
      location: FirestoreUtils.safeString(data['location'] ?? data['zipCode']),
      locationLat: FirestoreUtils.safeDouble(data['locationLat']),
      locationLng: FirestoreUtils.safeDouble(data['locationLng']),
      userType: _parseUserType(data['userType']),
      subscriptionTier: _parseSubscriptionTier(data['subscriptionTier']),
      isVerified: FirestoreUtils.safeBool(data['isVerified'], false),
      isFeatured: FirestoreUtils.safeBool(data['isFeatured'], false),
      isPortfolioPublic: FirestoreUtils.safeBool(data['isPortfolioPublic'], true),
      mediums: _parseStringList(data['mediums']),
      styles: _parseStringList(data['styles']),
      socialLinks: _parseStringMap(data['socialLinks']),
      createdAt: FirestoreUtils.safeDateTime(data['createdAt']),
      updatedAt: FirestoreUtils.safeDateTime(data['updatedAt']),
      isFollowing: FirestoreUtils.safeBool(data['isFollowing'], false),
      likesCount: FirestoreUtils.safeInt(data['likesCount']),
      viewsCount: FirestoreUtils.safeInt(data['viewsCount']),
      artworksCount: FirestoreUtils.safeInt(data['artworksCount']),
      followersCount: FirestoreUtils.safeInt(
        data['followersCount'] ?? data['followerCount'],
      ),
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
      mapGlowUntil: data['mapGlowUntil'] != null
          ? FirestoreUtils.safeDateTime(data['mapGlowUntil'])
          : null,
      kioskLaneUntil: data['kioskLaneUntil'] != null
          ? FirestoreUtils.safeDateTime(data['kioskLaneUntil'])
          : null,
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
      if (locationLat != null) 'locationLat': locationLat,
      if (locationLng != null) 'locationLng': locationLng,
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
      'boostScore': boostScore,
      if (lastBoostAt != null) 'lastBoostAt': Timestamp.fromDate(lastBoostAt!),
      if (boostStreakMonths > 0) 'boostStreakMonths': boostStreakMonths,
      if (boostStreakUpdatedAt != null)
        'boostStreakUpdatedAt': Timestamp.fromDate(boostStreakUpdatedAt!),
      if (mapGlowUntil != null)
        'mapGlowUntil': Timestamp.fromDate(mapGlowUntil!),
      if (kioskLaneUntil != null)
        'kioskLaneUntil': Timestamp.fromDate(kioskLaneUntil!),
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

  bool get hasActiveBoost {
    if (boostScore <= 0 || lastBoostAt == null) return false;
    return DateTime.now().difference(lastBoostAt!).inDays <= 7;
  }

  bool get hasMapGlow {
    if (mapGlowUntil == null) return false;
    return mapGlowUntil!.isAfter(DateTime.now());
  }

  bool get hasKioskLane {
    if (kioskLaneUntil == null) return false;
    return kioskLaneUntil!.isAfter(DateTime.now());
  }

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
    double? boostScore,
    DateTime? lastBoostAt,
    int? boostStreakMonths,
    DateTime? boostStreakUpdatedAt,
    DateTime? mapGlowUntil,
    DateTime? kioskLaneUntil,
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
      boostScore: boostScore ?? this.boostScore,
      lastBoostAt: lastBoostAt ?? this.lastBoostAt,
      boostStreakMonths: boostStreakMonths ?? this.boostStreakMonths,
      boostStreakUpdatedAt: boostStreakUpdatedAt ?? this.boostStreakUpdatedAt,
      mapGlowUntil: mapGlowUntil ?? this.mapGlowUntil,
      kioskLaneUntil: kioskLaneUntil ?? this.kioskLaneUntil,
    );
  }
}
