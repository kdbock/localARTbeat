import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/artist_feature_model.dart';
import '../utils/logger.dart';

/// Service for managing artist features granted by gifts
class ArtistFeatureService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _featuresCollection = FirebaseFirestore.instance
      .collection('artist_features');

  /// Create features for a gift purchase
  Future<List<ArtistFeature>> createFeaturesForGift({
    required String giftId,
    required String artistId,
    required String purchaserId,
  }) async {
    final config = GiftTierConfig.fromGiftId(giftId);
    if (config == null) {
      throw Exception('Unknown gift ID: $giftId');
    }

    final features = <ArtistFeature>[];
    final now = DateTime.now();

    // Create a feature for each type in the gift config
    for (final entry in config.features.entries) {
      final featureType = entry.key;
      final duration = entry.value;

      final feature = ArtistFeature(
        id: '', // Will be set by Firestore
        artistId: artistId,
        giftId: giftId,
        purchaserId: purchaserId,
        type: featureType,
        startDate: now,
        endDate: now.add(duration),
        isActive: true,
        metadata: {
          'giftPrice': config.price,
          'creditsGranted': config.credits,
          'durationDays': duration.inDays,
        },
      );

      // Save to Firestore
      final docRef = await _featuresCollection.add(feature.toFirestore());
      final savedFeature = feature.copyWith(id: docRef.id);

      features.add(savedFeature);

      AppLogger.info(
        '🎁 Created feature: ${featureType.name} for artist $artistId, expires ${savedFeature.endDate}',
      );
    }

    return features;
  }

  /// Get all active features for an artist
  Future<List<ArtistFeature>> getActiveFeaturesForArtist(
    String artistId,
  ) async {
    final now = DateTime.now();

    final query = _featuresCollection
        .where('artistId', isEqualTo: artistId)
        .where('isActive', isEqualTo: true)
        .where('endDate', isGreaterThan: Timestamp.fromDate(now));

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => ArtistFeature.fromFirestore(doc))
        .where((feature) => feature.isCurrentlyActive)
        .toList();
  }

  /// Get features by type for an artist
  Future<List<ArtistFeature>> getFeaturesByType(
    String artistId,
    FeatureType type,
  ) async {
    final query = _featuresCollection
        .where('artistId', isEqualTo: artistId)
        .where('type', isEqualTo: type.name)
        .where('isActive', isEqualTo: true);

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => ArtistFeature.fromFirestore(doc))
        .where((feature) => feature.isCurrentlyActive)
        .toList();
  }

  /// Check if artist has active feature of specific type
  Future<bool> hasActiveFeature(String artistId, FeatureType type) async {
    final features = await getFeaturesByType(artistId, type);
    return features.isNotEmpty;
  }

  /// Get feature statistics for an artist
  Future<Map<String, dynamic>> getFeatureStats(String artistId) async {
    final allFeatures = await getActiveFeaturesForArtist(artistId);

    final stats = {
      'totalActiveFeatures': allFeatures.length,
      'featuresByType': <String, int>{},
      'totalDaysRemaining': 0,
      'expiringSoon': <ArtistFeature>[], // Features expiring in < 7 days
    };

    for (final feature in allFeatures) {
      final typeName = feature.type.name;
      final featuresByType = stats['featuresByType'] as Map<String, int>;
      featuresByType[typeName] = (featuresByType[typeName] ?? 0) + 1;

      stats['totalDaysRemaining'] =
          (stats['totalDaysRemaining'] as int) + feature.daysRemaining;

      if (feature.daysRemaining <= 7) {
        (stats['expiringSoon'] as List<ArtistFeature>).add(feature);
      }
    }

    return stats;
  }

  /// Deactivate expired features (called by cron job)
  Future<int> deactivateExpiredFeatures() async {
    final now = DateTime.now();
    final batch = _firestore.batch();

    // Find expired features
    final expiredQuery = _featuresCollection
        .where('isActive', isEqualTo: true)
        .where('endDate', isLessThan: Timestamp.fromDate(now));

    final snapshot = await expiredQuery.get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isActive': false});
    }

    if (snapshot.docs.isNotEmpty) {
      await batch.commit();
      AppLogger.info('🔄 Deactivated ${snapshot.docs.length} expired features');
    }

    return snapshot.docs.length;
  }

  /// Extend feature duration (for renewals or upgrades)
  Future<void> extendFeature(String featureId, Duration extension) async {
    final docRef = _featuresCollection.doc(featureId);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception('Feature not found: $featureId');
    }

    final feature = ArtistFeature.fromFirestore(doc);
    final newEndDate = feature.endDate.add(extension);

    await docRef.update({
      'endDate': Timestamp.fromDate(newEndDate),
      'metadata.extendedBy': extension.inDays,
      'metadata.extendedAt': Timestamp.fromDate(DateTime.now()),
    });

    AppLogger.info(
      '⏰ Extended feature $featureId by ${extension.inDays} days, new end date: $newEndDate',
    );
  }

  /// Get features expiring soon (for notifications)
  Future<List<ArtistFeature>> getFeaturesExpiringSoon({
    int withinDays = 7,
  }) async {
    final futureDate = DateTime.now().add(Duration(days: withinDays));

    final query = _featuresCollection
        .where('isActive', isEqualTo: true)
        .where('endDate', isLessThanOrEqualTo: Timestamp.fromDate(futureDate))
        .where('endDate', isGreaterThan: Timestamp.fromDate(DateTime.now()));

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => ArtistFeature.fromFirestore(doc))
        .toList();
  }

  /// Get gift purchase history for a user
  Future<List<Map<String, dynamic>>> getGiftPurchaseHistory(
    String userId,
  ) async {
    final query = _featuresCollection
        .where('purchaserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50);

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      final feature = ArtistFeature.fromFirestore(doc);
      return {
        'featureId': feature.id,
        'artistId': feature.artistId,
        'giftId': feature.giftId,
        'type': feature.type.name,
        'startDate': feature.startDate,
        'endDate': feature.endDate,
        'isActive': feature.isActive,
        'metadata': feature.metadata,
      };
    }).toList();
  }

  /// Get all artists with active featured status
  Future<List<String>> getFeaturedArtistIds() async {
    final now = DateTime.now();

    final query = _featuresCollection
        .where('type', isEqualTo: FeatureType.artistFeatured.name)
        .where('isActive', isEqualTo: true)
        .where('endDate', isGreaterThan: Timestamp.fromDate(now));

    final snapshot = await query.get();

    // Extract unique artist IDs
    final artistIds = snapshot.docs
        .map((doc) => ArtistFeature.fromFirestore(doc).artistId)
        .toSet() // Remove duplicates
        .toList();

    return artistIds;
  }
}
