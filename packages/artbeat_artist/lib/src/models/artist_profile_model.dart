// filepath: /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/models/artist_profile_model.dart
import 'package:artbeat_core/artbeat_core.dart' show UserType, SubscriptionTier, FirestoreUtils;

// Using UserType from core module

/// Model for artist profile data
class ArtistProfileModel {
  final String id;
  final String userId;
  final String displayName;
  final String bio;
  final UserType userType;
  final String? location;
  final double? locationLat;
  final double? locationLng;
  final List<String> mediums;
  final List<String> styles;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final Map<String, String> socialLinks;
  final bool isVerified;
  final bool isFeatured;
  final SubscriptionTier subscriptionTier;
  final int followerCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ArtistProfileModel({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.bio,
    required this.userType,
    this.location,
    this.locationLat,
    this.locationLng,
    required this.mediums,
    required this.styles,
    this.profileImageUrl,
    this.coverImageUrl,
    Map<String, String>? socialLinks,
    this.isVerified = false,
    this.isFeatured = false,
    required this.subscriptionTier,
    this.followerCount = 0,
    required this.createdAt,
    required this.updatedAt,
  }) : socialLinks = socialLinks ?? {};

  factory ArtistProfileModel.fromMap(Map<String, dynamic> map) {
    return ArtistProfileModel(
      id: FirestoreUtils.getString(map, 'id'),
      userId: FirestoreUtils.getString(map, 'userId'),
      displayName: FirestoreUtils.getString(map, 'displayName'),
      bio: FirestoreUtils.getString(map, 'bio'),
      userType: _userTypeFromString(FirestoreUtils.getString(map, 'userType', 'artist')),
      location: FirestoreUtils.getOptionalString(map, 'location'),
      locationLat: map['locationLat'] != null
          ? FirestoreUtils.getDouble(map, 'locationLat')
          : null,
      locationLng: map['locationLng'] != null
          ? FirestoreUtils.getDouble(map, 'locationLng')
          : null,
      mediums: FirestoreUtils.getStringList(map, 'mediums'),
      styles: FirestoreUtils.getStringList(map, 'styles'),
      profileImageUrl: FirestoreUtils.getOptionalString(map, 'profileImageUrl'),
      coverImageUrl: FirestoreUtils.getOptionalString(map, 'coverImageUrl'),
      socialLinks: (map['socialLinks'] as Map?)?.map(
            (key, value) => MapEntry(
              FirestoreUtils.safeStringDefault(key),
              FirestoreUtils.safeStringDefault(value),
            ),
          ) ??
          <String, String>{},
      isVerified: FirestoreUtils.getBool(map, 'isVerified'),
      isFeatured: FirestoreUtils.getBool(map, 'isFeatured'),
      subscriptionTier: _tierFromString(
        FirestoreUtils.getString(map, 'subscriptionTier', 'starter'),
      ),
      followerCount: FirestoreUtils.getInt(map, 'followerCount'),
      createdAt: FirestoreUtils.getDateTime(map, 'createdAt'),
      updatedAt: FirestoreUtils.getDateTime(map, 'updatedAt'),
    );
  }

  /// Convert profile to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'bio': bio,
      'userType': _userTypeToString(userType),
      'location': location,
      if (locationLat != null) 'locationLat': locationLat,
      if (locationLng != null) 'locationLng': locationLng,
      'mediums': mediums,
      'styles': styles,
      'profileImageUrl': profileImageUrl,
      'coverImageUrl': coverImageUrl,
      'socialLinks': socialLinks,
      'isVerified': isVerified,
      'isFeatured': isFeatured,
      'subscriptionTier': _tierToString(subscriptionTier),
      'followerCount': followerCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Helper methods for type conversion
  static String _userTypeToString(UserType userType) {
    return userType.name;
  }

  static UserType _userTypeFromString(String typeString) {
    return UserType.fromString(typeString);
  }

  /// Map subscription tier to string for storage
  static String _tierToString(SubscriptionTier tier) {
    return tier.apiName;
  }

  /// Parse tier from string, using legacy conversion when needed
  static SubscriptionTier _tierFromString(String tierString) {
    return SubscriptionTier.fromLegacyName(tierString);
  }

  /// Create a copy of this model with the given fields replaced with new values
  ArtistProfileModel copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? bio,
    String? profileImageUrl,
    String? coverImageUrl,
    String? location,
    UserType? userType,
    SubscriptionTier? subscriptionTier,
    bool? isVerified,
    bool? isFeatured,
    List<String>? mediums,
    List<String>? styles,
    Map<String, String>? socialLinks,
    int? followerCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ArtistProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      location: location ?? this.location,
      userType: userType ?? this.userType,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      isVerified: isVerified ?? this.isVerified,
      isFeatured: isFeatured ?? this.isFeatured,
      mediums: mediums ?? this.mediums,
      styles: styles ?? this.styles,
      socialLinks: socialLinks ?? this.socialLinks,
      followerCount: followerCount ?? this.followerCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
