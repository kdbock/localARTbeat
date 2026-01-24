import 'package:cloud_firestore/cloud_firestore.dart';

enum FeatureType {
  artistFeatured, // Artist profile featured in discovery
  artworkFeatured, // Specific artworks featured
  adRotation, // Artist ads in rotation
}

/// Represents an active feature granted by an artist boost
class ArtistFeature {
  final String id;
  final String artistId;
  final String boostId;
  final String purchaserId;
  final FeatureType type;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  ArtistFeature({
    required this.id,
    required this.artistId,
    required this.boostId,
    required this.purchaserId,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.metadata,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ArtistFeature.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ArtistFeature(
      id: doc.id,
      artistId: data['artistId'] as String,
      boostId: data['boostId'] as String? ?? data['giftId'] as String? ?? '',
      purchaserId: data['purchaserId'] as String,
      type: _parseFeatureType(data['type'] as String),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool? ?? true,
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'artistId': artistId,
      'boostId': boostId,
      'purchaserId': purchaserId,
      'type': _featureTypeToString(type),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      if (metadata != null) 'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static String _featureTypeToString(FeatureType type) {
    switch (type) {
      case FeatureType.artistFeatured:
        return 'artist_featured';
      case FeatureType.artworkFeatured:
        return 'artwork_featured';
      case FeatureType.adRotation:
        return 'ad_rotation';
    }
  }

  static FeatureType _parseFeatureType(String typeString) {
    switch (typeString) {
      case 'artist_featured':
      case 'artistFeatured':
        return FeatureType.artistFeatured;
      case 'artwork_featured':
      case 'artworkFeatured':
        return FeatureType.artworkFeatured;
      case 'ad_rotation':
      case 'adRotation':
        return FeatureType.adRotation;
      default:
        return FeatureType.artistFeatured;
    }
  }

  /// Check if feature is currently active
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Check if feature is expired
  bool get isExpired {
    return DateTime.now().isAfter(endDate);
  }

  /// Get days remaining until expiration
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  ArtistFeature copyWith({
    String? id,
    String? artistId,
    String? boostId,
    String? purchaserId,
    FeatureType? type,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return ArtistFeature(
      id: id ?? this.id,
      artistId: artistId ?? this.artistId,
      boostId: boostId ?? this.boostId,
      purchaserId: purchaserId ?? this.purchaserId,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Configuration for different boost tiers
class BoostTierConfig {
  final String boostId;
  final double price;
  final int momentum;
  final Map<FeatureType, Duration> features;

  const BoostTierConfig({
    required this.boostId,
    required this.price,
    required this.momentum,
    required this.features,
  });

  static const supporter = BoostTierConfig(
    boostId: 'artbeat_boost_spark',
    price: 4.99,
    momentum: 50,
    features: {FeatureType.artistFeatured: Duration(days: 7)},
  );

  static const fan = BoostTierConfig(
    boostId: 'artbeat_boost_surge',
    price: 9.99,
    momentum: 120,
    features: {
      FeatureType.artistFeatured: Duration(days: 14),
      FeatureType.artworkFeatured: Duration(days: 14), // 1 artwork
    },
  );

  static const patron = BoostTierConfig(
    boostId: 'artbeat_boost_overdrive',
    price: 24.99,
    momentum: 350,
    features: {
      FeatureType.artistFeatured: Duration(days: 21),
      FeatureType.artworkFeatured: Duration(days: 21), // 3 artworks
      FeatureType.adRotation: Duration(days: 14),
    },
  );

  static BoostTierConfig? fromBoostId(String boostId) {
    switch (boostId) {
      case 'artbeat_boost_spark':
        return supporter;
      case 'artbeat_boost_surge':
        return fan;
      case 'artbeat_boost_overdrive':
        return patron;
      default:
        return null;
    }
  }
}
