import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/artwork_model.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppLogger;

/// Service for artwork discovery algorithms and recommendations
class ArtworkDiscoveryService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  final CollectionReference _artworkCollection = FirebaseFirestore.instance
      .collection('artwork');
  final CollectionReference _userPreferencesCollection = FirebaseFirestore
      .instance
      .collection('user_artwork_preferences');

  /// Get similar artworks based on tags, styles, and medium
  Future<List<ArtworkModel>> getSimilarArtworks(
    String artworkId, {
    int limit = 10,
  }) async {
    try {
      // Get the source artwork
      final sourceDoc = await _artworkCollection.doc(artworkId).get();
      if (!sourceDoc.exists) {
        return [];
      }

      final sourceArtwork = ArtworkModel.fromFirestore(sourceDoc);
      final similarArtworks = <ArtworkModel>[];
      final scoredArtworks = <String, double>{};

      // Get artworks with similar characteristics
      final queries = await Future.wait([
        // Same medium
        _artworkCollection
            .where('medium', isEqualTo: sourceArtwork.medium)
            .limit(limit * 2)
            .get(),
        // Same styles
        _artworkCollection
            .where(
              'styles',
              arrayContainsAny: sourceArtwork.styles.take(3).toList(),
            )
            .limit(limit * 2)
            .get(),
        // Same tags
        if (sourceArtwork.tags != null && sourceArtwork.tags!.isNotEmpty)
          _artworkCollection
              .where(
                'tags',
                arrayContainsAny: sourceArtwork.tags!.take(3).toList(),
              )
              .limit(limit * 2)
              .get()
        else
          Future.value(null),
      ]);

      // Score and rank artworks
      for (final query in queries) {
        if (query != null) {
          for (final doc in query.docs) {
            if (doc.id == artworkId) continue; // Skip the source artwork

            final artwork = ArtworkModel.fromFirestore(doc);
            final score = _calculateSimilarityScore(sourceArtwork, artwork);

            if (score > 0) {
              scoredArtworks[doc.id] = (scoredArtworks[doc.id] ?? 0) + score;
            }
          }
        }
      }

      // Sort by score and take top results
      final sortedIds = scoredArtworks.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final entry in sortedIds.take(limit)) {
        try {
          final doc = await _artworkCollection.doc(entry.key).get();
          if (doc.exists) {
            similarArtworks.add(ArtworkModel.fromFirestore(doc));
          }
        } catch (e) {
          AppLogger.error('Error fetching similar artwork ${entry.key}: $e');
        }
      }

      return similarArtworks;
    } catch (e) {
      AppLogger.error('Error getting similar artworks: $e');
      return [];
    }
  }

  /// Get trending artworks based on recent activity
  Future<List<ArtworkModel>> getTrendingArtworks({
    int limit = 20,
    Duration timeWindow = const Duration(days: 7),
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(timeWindow);

      // Get artworks with recent activity
      final query = await _artworkCollection
          .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .orderBy('createdAt', descending: true)
          .limit(limit * 3) // Get more to filter
          .get();

      final artworks = query.docs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();

      // Calculate trending score for each artwork
      final scoredArtworks = <ArtworkModel, double>{};

      for (final artwork in artworks) {
        final score = _calculateTrendingScore(artwork, timeWindow);
        if (score > 0) {
          scoredArtworks[artwork] = score;
        }
      }

      // Sort by trending score
      final sortedArtworks = scoredArtworks.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedArtworks.take(limit).map((entry) => entry.key).toList();
    } catch (e) {
      AppLogger.error('Error getting trending artworks: $e');
      return [];
    }
  }

  /// Get personalized artwork recommendations for a user
  Future<List<ArtworkModel>> getPersonalizedRecommendations({
    int limit = 20,
    String? userId,
  }) async {
    try {
      final currentUserId = userId ?? _auth.currentUser?.uid;
      if (currentUserId == null) {
        // Return trending artworks for anonymous users
        return getTrendingArtworks(limit: limit);
      }

      // Get user's preferences and interaction history
      final likedArtworks = await _getUserLikedArtworks(currentUserId);
      final viewedArtworks = await _getUserViewedArtworks(currentUserId);

      // Analyze user preferences
      final preferredMediums = <String, double>{};
      final preferredStyles = <String, double>{};
      final preferredTags = <String, double>{};

      for (final artwork in [...likedArtworks, ...viewedArtworks]) {
        // Weight liked artworks more heavily
        final weight = likedArtworks.contains(artwork) ? 2.0 : 1.0;

        if (artwork.medium.isNotEmpty) {
          preferredMediums[artwork.medium] =
              (preferredMediums[artwork.medium] ?? 0) + weight;
        }

        for (final style in artwork.styles) {
          preferredStyles[style] = (preferredStyles[style] ?? 0) + weight;
        }

        if (artwork.tags != null) {
          for (final tag in artwork.tags!) {
            preferredTags[tag] = (preferredTags[tag] ?? 0) + weight;
          }
        }
      }

      // Get artworks matching user preferences
      final candidateArtworks = <ArtworkModel>[];
      final scoredArtworks = <ArtworkModel, double>{};

      // Query for preferred mediums
      for (final medium in preferredMediums.keys.take(3)) {
        final query = await _artworkCollection
            .where('medium', isEqualTo: medium)
            .limit(10)
            .get();

        for (final doc in query.docs) {
          final artwork = ArtworkModel.fromFirestore(doc);
          if (!likedArtworks.contains(artwork) &&
              !viewedArtworks.contains(artwork)) {
            candidateArtworks.add(artwork);
          }
        }
      }

      // Score candidates based on user preferences
      for (final artwork in candidateArtworks) {
        final score = _calculatePersonalizedScore(
          artwork,
          preferredMediums,
          preferredStyles,
          preferredTags,
        );
        scoredArtworks[artwork] = score;
      }

      // Sort by score and return top results
      final sortedArtworks = scoredArtworks.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedArtworks.take(limit).map((entry) => entry.key).toList();
    } catch (e) {
      AppLogger.error('Error getting personalized recommendations: $e');
      // Fallback to trending
      return getTrendingArtworks(limit: limit);
    }
  }

  /// Get discovery feed combining multiple algorithms
  Future<List<ArtworkModel>> getDiscoveryFeed({
    int limit = 30,
    String? userId,
  }) async {
    try {
      final feed = <ArtworkModel>[];

      // Get personalized recommendations (40% of feed)
      final personalized = await getPersonalizedRecommendations(
        limit: (limit * 0.4).round(),
        userId: userId,
      );
      feed.addAll(personalized);

      // Get trending artworks (30% of feed)
      final trending = await getTrendingArtworks(limit: (limit * 0.3).round());
      // Remove duplicates
      final trendingFiltered = trending
          .where(
            (artwork) => !feed.any((existing) => existing.id == artwork.id),
          )
          .toList();
      feed.addAll(trendingFiltered);

      // Get featured/popular artworks (30% of feed)
      final featured = await _getFeaturedArtworks(limit: (limit * 0.3).round());
      final featuredFiltered = featured
          .where(
            (artwork) => !feed.any((existing) => existing.id == artwork.id),
          )
          .toList();
      feed.addAll(featuredFiltered);

      // Shuffle to mix different types
      feed.shuffle(Random());

      return feed.take(limit).toList();
    } catch (e) {
      AppLogger.error('Error getting discovery feed: $e');
      return [];
    }
  }

  /// Calculate similarity score between two artworks
  double _calculateSimilarityScore(ArtworkModel source, ArtworkModel target) {
    double score = 0;

    // Medium match (high weight)
    if (source.medium == target.medium) {
      score += 3.0;
    }

    // Style matches
    final commonStyles = source.styles.toSet().intersection(
      target.styles.toSet(),
    );
    score += commonStyles.length * 2.0;

    // Tag matches
    if (source.tags != null && target.tags != null) {
      final commonTags = source.tags!.toSet().intersection(
        target.tags!.toSet(),
      );
      score += commonTags.length * 1.5;
    }

    // Location proximity (if both have location)
    if (source.location != null && target.location != null) {
      // Simple location similarity (could be enhanced with actual distance calculation)
      if (source.location == target.location) {
        score += 1.0;
      }
    }

    // Price range similarity (if both for sale)
    if (source.isForSale &&
        target.isForSale &&
        source.price != null &&
        target.price != null) {
      final priceDiff = (source.price! - target.price!).abs();
      final avgPrice = (source.price! + target.price!) / 2;
      final priceSimilarity = 1 - (priceDiff / avgPrice);
      if (priceSimilarity > 0) {
        score += priceSimilarity * 0.5;
      }
    }

    return score;
  }

  /// Calculate trending score based on recent activity
  double _calculateTrendingScore(ArtworkModel artwork, Duration timeWindow) {
    double score = 0;

    // Base score from view count
    score += artwork.viewCount * 0.1;

    // Engagement score from likes and comments (simplified)
    // For now, we'll use basic engagement indicators
    score += (artwork.viewCount * 0.05); // Additional engagement proxy

    // Recency boost (newer artworks get higher scores)
    final ageInHours = DateTime.now().difference(artwork.createdAt).inHours;
    final recencyScore =
        max(0, 24 - ageInHours) / 24; // Higher for newer content
    score *= (1 + recencyScore);

    // Featured artworks get a boost
    if (artwork.isFeatured) {
      score *= 1.5;
    }

    return score;
  }

  /// Calculate personalized score based on user preferences
  double _calculatePersonalizedScore(
    ArtworkModel artwork,
    Map<String, double> preferredMediums,
    Map<String, double> preferredStyles,
    Map<String, double> preferredTags,
  ) {
    double score = 0;

    // Medium preference
    final mediumWeight = preferredMediums[artwork.medium] ?? 0;
    score += mediumWeight * 2.0;

    // Style preferences
    for (final style in artwork.styles) {
      final styleWeight = preferredStyles[style] ?? 0;
      score += styleWeight * 1.5;
    }

    // Tag preferences
    if (artwork.tags != null) {
      for (final tag in artwork.tags!) {
        final tagWeight = preferredTags[tag] ?? 0;
        score += tagWeight * 1.0;
      }
    }

    // Boost for featured artworks
    if (artwork.isFeatured) {
      score *= 1.2;
    }

    return score;
  }

  /// Get user's artwork preferences
  Future<Map<String, dynamic>> _getUserPreferences(String userId) async {
    try {
      final doc = await _userPreferencesCollection.doc(userId).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : {};
    } catch (e) {
      AppLogger.error('Error getting user preferences: $e');
      return {};
    }
  }

  /// Get artworks liked by user
  Future<List<ArtworkModel>> _getUserLikedArtworks(String userId) async {
    try {
      final query = await _artworkCollection
          .where('likes', arrayContains: userId)
          .limit(20)
          .get();

      return query.docs.map((doc) => ArtworkModel.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('Error getting user liked artworks: $e');
      return [];
    }
  }

  /// Get recently viewed artworks by user
  Future<List<ArtworkModel>> _getUserViewedArtworks(String userId) async {
    try {
      // This would typically come from a separate collection tracking views
      // For now, return some recent artworks as a placeholder
      final query = await _artworkCollection
          .where('isPublic', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .limit(10)
          .get();

      return query.docs.map((doc) => ArtworkModel.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('Error getting user viewed artworks: $e');
      return [];
    }
  }

  /// Get featured artworks
  Future<List<ArtworkModel>> _getFeaturedArtworks({int limit = 10}) async {
    try {
      final query = await _artworkCollection
          .where('isFeatured', isEqualTo: true)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => ArtworkModel.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('Error getting featured artworks: $e');
      return [];
    }
  }

  /// Update user preferences based on interactions
  Future<void> updateUserPreferences(
    String userId,
    ArtworkModel artwork,
  ) async {
    try {
      final preferences = await _getUserPreferences(userId);

      // Update medium preferences
      final mediums =
          preferences['preferredMediums'] as Map<String, dynamic>? ?? {};
      mediums[artwork.medium] = (mediums[artwork.medium] as num? ?? 0) + 1;
      preferences['preferredMediums'] = mediums;

      // Update style preferences
      final styles =
          preferences['preferredStyles'] as Map<String, dynamic>? ?? {};
      for (final style in artwork.styles) {
        styles[style] = (styles[style] as num? ?? 0) + 1;
      }
      preferences['preferredStyles'] = styles;

      // Update tag preferences
      if (artwork.tags != null) {
        final tags =
            preferences['preferredTags'] as Map<String, dynamic>? ?? {};
        for (final tag in artwork.tags!) {
          tags[tag] = (tags[tag] as num? ?? 0) + 1;
        }
        preferences['preferredTags'] = tags;
      }

      await _userPreferencesCollection.doc(userId).set(preferences);
    } catch (e) {
      AppLogger.error('Error updating user preferences: $e');
    }
  }
}
