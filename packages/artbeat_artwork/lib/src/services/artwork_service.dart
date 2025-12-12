import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show
        SubscriptionTier,
        EnhancedStorageService,
        AppLogger,
        ArtworkContentType;
import 'package:artbeat_artist/artbeat_artist.dart' show SubscriptionService;
import 'package:artbeat_art_walk/artbeat_art_walk.dart'
    show SocialService, SocialActivityType;

/// Service for managing artwork
class ArtworkService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final SubscriptionService _subscriptionService = SubscriptionService();
  final EnhancedStorageService _enhancedStorage = EnhancedStorageService();

  // Collection references
  final CollectionReference _artworkCollection =
      FirebaseFirestore.instance.collection('artwork');

  /// Get the current authenticated user's ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get current user's subscription tier
  Future<SubscriptionTier> _getCurrentUserTier() async {
    try {
      final subscription = await _subscriptionService.getUserSubscription();
      return subscription?.tier ?? SubscriptionTier.free;
    } catch (e) {
      AppLogger.error('Error getting user subscription: $e');
      return SubscriptionTier.free;
    }
  }

  /// Check if user can upload more artwork based on subscription
  Future<void> _checkUploadLimit() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get user's subscription tier
      final tier = await _getCurrentUserTier();

      // Users on free/basic tier can only upload 5 artworks
      if (tier == SubscriptionTier.free || tier == SubscriptionTier.starter) {
        final snapshot = await _artworkCollection
            .where('userId', isEqualTo: userId)
            .count()
            .get();

        final artworkCount = snapshot.count ?? 0;
        if (artworkCount >= 5) {
          throw Exception(
              'You have reached the maximum number of artworks for the basic tier. Please upgrade to upload more artwork.');
        }
      }
    } catch (e) {
      throw Exception('Error checking upload limit: $e');
    }
  }

  /// Upload new artwork
  Future<String> uploadArtwork({
    required File imageFile,
    required String title,
    required String description,
    required String medium,
    required List<String> styles,
    List<String>? tags,
    String? dimensions,
    String? materials,
    String? location,
    double? price,
    bool isForSale = false,
    int? yearCreated,
    bool isPublic = true,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Check user's subscription and artwork limit
      await _checkUploadLimit();

      // Get artist profile ID
      final artistProfile =
          await _subscriptionService.getArtistProfileByUserId(userId);
      if (artistProfile == null) {
        throw Exception('Artist profile not found. Please create one first.');
      }

      // Upload image using enhanced storage service with optimization
      AppLogger.info('🎨 Uploading artwork image with optimization...');
      final uploadResult = await _enhancedStorage.uploadImageWithOptimization(
        imageFile: imageFile,
        category: 'artwork',
        generateThumbnail: true,
      );

      final imageUrl = uploadResult['imageUrl']!;
      final thumbnailUrl = uploadResult['thumbnailUrl'];

      AppLogger.info('✅ Artwork image uploaded successfully');
      AppLogger.analytics('📊 Original: ${uploadResult['originalSize']}');
      AppLogger.analytics('📊 Compressed: ${uploadResult['compressedSize']}');

      // Create artwork data
      final artworkData = {
        'userId': userId,
        'artistProfileId': artistProfile.id,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'thumbnailUrl': thumbnailUrl,
        'medium': medium,
        'styles': styles,
        'tags': tags ?? [],
        'dimensions': dimensions,
        'materials': materials,
        'location': location,
        'price': price,
        'isForSale': isForSale,
        'isSold': false,
        'yearCreated': yearCreated,
        'isFeatured': false,
        'isPublic': isPublic,
        'viewCount': 0,
        'likeCount': 0,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Create Firestore document
      final docRef = await _artworkCollection.add(artworkData);

      // Post social activity for artwork upload
      try {
        final user = _auth.currentUser;
        if (user != null) {
          await SocialService().postActivity(
            userId: user.uid,
            userName: user.displayName ?? 'Artist',
            userAvatar: user.photoURL,
            type: SocialActivityType.milestone,
            message: 'uploaded new artwork: "$title"',
            metadata: {'artworkId': docRef.id, 'artTitle': title},
          );
        }
      } catch (e) {
        AppLogger.warning(
            'Failed to post social activity for artwork upload: $e');
      }

      return docRef.id;
    } catch (e) {
      AppLogger.error('Error uploading artwork: $e');
      throw Exception('Failed to upload artwork: $e');
    }
  }

  /// Get artwork by ID
  Future<ArtworkModel?> getArtworkById(String id) async {
    try {
      final doc = await _artworkCollection.doc(id).get();
      if (doc.exists) {
        return ArtworkModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting artwork: $e');
      return null;
    }
  }

  /// Get artwork by artist profile ID
  Future<List<ArtworkModel>> getArtworkByArtistProfileId(
      String artistProfileId) async {
    try {
      debugPrint(
          '🔍 ArtworkService: Querying artwork for artistProfileId: $artistProfileId');

      // First get the artist profile to get the userId
      final artistProfileDoc = await FirebaseFirestore.instance
          .collection('artistProfiles')
          .doc(artistProfileId)
          .get();

      if (!artistProfileDoc.exists) {
        AppLogger.error('❌ ArtworkService: Artist profile not found');
        return [];
      }

      final userId = artistProfileDoc.data()?['userId'];
      if (userId == null) {
        AppLogger.error('❌ ArtworkService: No userId found in artist profile');
        return [];
      }

      debugPrint(
          '🔍 ArtworkService: Found userId: $userId for artistProfileId: $artistProfileId');

      // Try querying by artistProfileId first (for newer artwork)
      final snapshot = await _artworkCollection
          .where('artistProfileId', isEqualTo: artistProfileId)
          .get();

      debugPrint(
          '📊 ArtworkService: Found ${snapshot.docs.length} artwork documents by artistProfileId');

      final List<ArtworkModel> artworks =
          snapshot.docs.map((doc) => ArtworkModel.fromFirestore(doc)).toList();

      // Also query by artistId (for legacy artwork that might use this field)
      final legacySnapshot =
          await _artworkCollection.where('artistId', isEqualTo: userId).get();

      debugPrint(
          '📊 ArtworkService: Found ${legacySnapshot.docs.length} artwork documents by artistId (legacy)');

      if (legacySnapshot.docs.isNotEmpty) {
        final legacyArtworks = legacySnapshot.docs
            .map((doc) => ArtworkModel.fromFirestore(doc))
            .toList();
        artworks.addAll(legacyArtworks);
      }

      // Also query by userId as final fallback
      final userSnapshot =
          await _artworkCollection.where('userId', isEqualTo: userId).get();

      debugPrint(
          '📊 ArtworkService: Found ${userSnapshot.docs.length} artwork documents by userId');

      if (userSnapshot.docs.isNotEmpty) {
        final userArtworks = userSnapshot.docs
            .map((doc) => ArtworkModel.fromFirestore(doc))
            .toList();

        // Add only artworks that aren't already in the list (avoid duplicates)
        for (final artwork in userArtworks) {
          if (!artworks.any((existing) => existing.id == artwork.id)) {
            artworks.add(artwork);
          }
        }
      }

      // Sort by creation date (newest first)
      artworks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint(
          '🖼️ ArtworkService: Total unique artworks found: ${artworks.length}');

      return artworks;
    } catch (e) {
      AppLogger.error('❌ Error getting artist artwork: $e');
      return [];
    }
  }

  /// Update artwork details
  Future<void> updateArtwork({
    required String artworkId,
    String? title,
    String? description,
    String? medium,
    List<String>? styles,
    List<String>? tags,
    String? dimensions,
    String? materials,
    String? location,
    double? price,
    bool? isForSale,
    bool? isSold,
    int? yearCreated,
    String? externalLink,
    bool? isPublic,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Check if artwork exists and belongs to user
      final artwork = await getArtworkById(artworkId);
      if (artwork == null) {
        throw Exception('Artwork not found');
      }

      if (artwork.userId != userId) {
        throw Exception('You do not have permission to update this artwork');
      }

      // Create update data
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (medium != null) updateData['medium'] = medium;
      if (styles != null) updateData['styles'] = styles;
      if (tags != null) updateData['tags'] = tags;
      if (dimensions != null) updateData['dimensions'] = dimensions;
      if (materials != null) updateData['materials'] = materials;
      if (location != null) updateData['location'] = location;
      if (price != null) updateData['price'] = price;
      if (isForSale != null) updateData['isForSale'] = isForSale;
      if (isSold != null) updateData['isSold'] = isSold;
      if (yearCreated != null) updateData['yearCreated'] = yearCreated;
      if (externalLink != null) updateData['externalLink'] = externalLink;
      if (isPublic != null) updateData['isPublic'] = isPublic;

      // Update Firestore document
      await _artworkCollection.doc(artworkId).update(updateData);
    } catch (e) {
      AppLogger.error('Error updating artwork: $e');
      throw Exception('Failed to update artwork: $e');
    }
  }

  /// Update artwork moderation status (admin only)
  Future<void> updateArtworkModeration({
    required String artworkId,
    required ArtworkModerationStatus status,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'moderationStatus': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null && notes.isNotEmpty) {
        updateData['moderationNotes'] = notes;
      }

      // If rejecting, also mark as flagged
      if (status == ArtworkModerationStatus.rejected) {
        updateData['flagged'] = true;
        updateData['flaggedAt'] = FieldValue.serverTimestamp();
      }

      // Update Firestore document
      await _artworkCollection.doc(artworkId).update(updateData);
    } catch (e) {
      AppLogger.error('Error updating artwork moderation: $e');
      throw Exception('Failed to update artwork moderation: $e');
    }
  }

  /// Delete artwork and its image
  Future<void> deleteArtwork(String artworkId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Check if artwork exists and belongs to user
      final artwork = await getArtworkById(artworkId);
      if (artwork == null) {
        throw Exception('Artwork not found');
      }

      if (artwork.userId != userId) {
        throw Exception('You do not have permission to delete this artwork');
      }

      // Delete image from storage if it exists
      if (artwork.imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(artwork.imageUrl).delete();
        } catch (e) {
          AppLogger.error('Error deleting artwork image: $e');
          // Continue with deletion even if image deletion fails
        }
      }

      // Delete Firestore document
      await _artworkCollection.doc(artworkId).delete();
    } catch (e) {
      AppLogger.error('Error deleting artwork: $e');
      throw Exception('Failed to delete artwork: $e');
    }
  }

  /// Toggle like status for artwork
  Future<bool> toggleLike(String artworkId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final likeRef =
          _artworkCollection.doc(artworkId).collection('likes').doc(userId);

      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // Unlike artwork
        await likeRef.delete();
        await _artworkCollection.doc(artworkId).update({
          'likeCount': FieldValue.increment(-1),
        });
        return false;
      } else {
        // Like artwork
        await likeRef.set({
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await _artworkCollection.doc(artworkId).update({
          'likeCount': FieldValue.increment(1),
        });
        return true;
      }
    } catch (e) {
      AppLogger.error('Error toggling artwork like: $e');
      throw Exception('Failed to update like status: $e');
    }
  }

  /// Check if user has liked an artwork
  Future<bool> hasLiked(String artworkId) async {
    final userId = getCurrentUserId();
    if (userId == null) return false;

    try {
      final likeDoc = await _artworkCollection
          .doc(artworkId)
          .collection('likes')
          .doc(userId)
          .get();

      return likeDoc.exists;
    } catch (e) {
      AppLogger.error('Error checking like status: $e');
      return false;
    }
  }

  /// Increment view count for artwork
  Future<void> incrementViewCount(String artworkId) async {
    try {
      await _artworkCollection.doc(artworkId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      AppLogger.error('Error incrementing view count: $e');
      // Non-critical error, don't throw
    }
  }

  /// Search artwork by query
  Future<List<ArtworkModel>> searchArtwork(String query) async {
    try {
      final snapshot =
          await _artworkCollection.where('isPublic', isEqualTo: true).get();

      final lowercaseQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .where((artwork) {
        return artwork.title.toLowerCase().contains(lowercaseQuery) ||
            artwork.description.toLowerCase().contains(lowercaseQuery) ||
            artwork.medium.toLowerCase().contains(lowercaseQuery) ||
            artwork.styles
                .any((style) => style.toLowerCase().contains(lowercaseQuery)) ||
            (artwork.tags?.any(
                    (tag) => tag.toLowerCase().contains(lowercaseQuery)) ??
                false);
      }).toList();
    } catch (e) {
      AppLogger.error('Error searching artwork: $e');
      return [];
    }
  }

  /// Get featured artwork
  Future<List<ArtworkModel>> getFeaturedArtwork({int limit = 10}) async {
    try {
      final snapshot = await _artworkCollection
          .where('isFeatured', isEqualTo: true)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting featured artwork: $e');
      return [];
    }
  }

  /// Get all public artwork
  Future<List<ArtworkModel>> getAllPublicArtwork({int limit = 50}) async {
    try {
      // First try the optimal query (requires composite index)
      final snapshot = await _artworkCollection
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting public artwork with composite query: $e');

      // Fallback: Get all public artwork without ordering (doesn't require composite index)
      try {
        final fallbackSnapshot = await _artworkCollection
            .where('isPublic', isEqualTo: true)
            .limit(limit)
            .get();

        final artworks = fallbackSnapshot.docs
            .map((doc) => ArtworkModel.fromFirestore(doc))
            .toList();

        // Sort in memory by createdAt
        artworks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        debugPrint(
            'Fallback query successful: loaded ${artworks.length} artworks');
        return artworks;
      } catch (fallbackError) {
        AppLogger.error('Fallback query also failed: $fallbackError');
        return [];
      }
    }
  }

  /// Get all artwork (no filter on isPublic)
  Future<List<ArtworkModel>> getAllArtwork({int limit = 50}) async {
    try {
      final snapshot = await _artworkCollection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting all artwork: $e');
      // Fallback: Get all artwork without ordering
      try {
        final fallbackSnapshot = await _artworkCollection.limit(limit).get();

        final artworks = fallbackSnapshot.docs
            .map((doc) => ArtworkModel.fromFirestore(doc))
            .toList();

        // Sort in memory by createdAt if available
        artworks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        debugPrint(
            'Fallback query successful: loaded ${artworks.length} artworks');
        return artworks;
      } catch (fallbackError) {
        AppLogger.error('Fallback query also failed: $fallbackError');
        return [];
      }
    }
  }

  /// Advanced search with multiple filters
  Future<List<ArtworkModel>> advancedSearchArtwork({
    String? query,
    String? location,
    String? medium,
    List<String>? styles,
    double? minPrice,
    double? maxPrice,
    DateTime? startDate,
    DateTime? endDate,
    bool? isForSale,
    bool? isFeatured,
    int limit = 50,
  }) async {
    try {
      Query queryRef = _artworkCollection.where('isPublic', isEqualTo: true);

      // Apply filters
      if (location != null && location != 'All') {
        queryRef = queryRef.where('location', isEqualTo: location);
      }

      if (medium != null && medium != 'All') {
        queryRef = queryRef.where('medium', isEqualTo: medium);
      }

      if (isForSale != null) {
        queryRef = queryRef.where('isForSale', isEqualTo: isForSale);
      }

      if (isFeatured != null) {
        queryRef = queryRef.where('isFeatured', isEqualTo: isFeatured);
      }

      // Get results
      final snapshot = await queryRef
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      List<ArtworkModel> artworks =
          snapshot.docs.map((doc) => ArtworkModel.fromFirestore(doc)).toList();

      // Apply client-side filters that Firestore doesn't support well
      if (query != null && query.isNotEmpty) {
        final lowercaseQuery = query.toLowerCase();
        artworks = artworks.where((artwork) {
          return artwork.title.toLowerCase().contains(lowercaseQuery) ||
              artwork.description.toLowerCase().contains(lowercaseQuery) ||
              artwork.medium.toLowerCase().contains(lowercaseQuery) ||
              artwork.styles.any(
                  (style) => style.toLowerCase().contains(lowercaseQuery)) ||
              (artwork.tags?.any(
                      (tag) => tag.toLowerCase().contains(lowercaseQuery)) ??
                  false) ||
              (artwork.materials?.toLowerCase().contains(lowercaseQuery) ??
                  false);
        }).toList();
      }

      if (styles != null && styles.isNotEmpty) {
        artworks = artworks.where((artwork) {
          return styles.any((style) => artwork.styles.contains(style));
        }).toList();
      }

      if (minPrice != null) {
        artworks = artworks
            .where((artwork) =>
                artwork.price != null && artwork.price! >= minPrice)
            .toList();
      }

      if (maxPrice != null) {
        artworks = artworks
            .where((artwork) =>
                artwork.price != null && artwork.price! <= maxPrice)
            .toList();
      }

      if (startDate != null) {
        artworks = artworks
            .where((artwork) => artwork.createdAt.isAfter(startDate))
            .toList();
      }

      if (endDate != null) {
        artworks = artworks
            .where((artwork) => artwork.createdAt.isBefore(endDate))
            .toList();
      }

      // Track search analytics
      if (query != null && query.isNotEmpty) {
        await _trackSearchAnalytics(query, artworks.length);
      }

      return artworks;
    } catch (e) {
      AppLogger.error('Error in advanced search: $e');
      return [];
    }
  }

  /// Track search analytics
  Future<void> _trackSearchAnalytics(String query, int resultCount) async {
    try {
      final userId = getCurrentUserId();
      await FirebaseFirestore.instance.collection('search_analytics').add({
        'query': query,
        'resultCount': resultCount,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'searchType': 'artwork',
      });
    } catch (e) {
      AppLogger.error('Error tracking search analytics: $e');
      // Non-critical error, don't throw
    }
  }

  /// Save a search query for the current user
  Future<void> saveSearch(
      String searchName, Map<String, dynamic> searchCriteria) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('saved_searches').add({
        'userId': userId,
        'name': searchName,
        'criteria': searchCriteria,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUsed': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Error saving search: $e');
      throw Exception('Failed to save search');
    }
  }

  /// Get saved searches for the current user
  Future<List<Map<String, dynamic>>> getSavedSearches() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('saved_searches')
          .where('userId', isEqualTo: userId)
          .orderBy('lastUsed', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      AppLogger.error('Error getting saved searches: $e');
      return [];
    }
  }

  /// Delete a saved search
  Future<void> deleteSavedSearch(String searchId) async {
    try {
      await FirebaseFirestore.instance
          .collection('saved_searches')
          .doc(searchId)
          .delete();
    } catch (e) {
      AppLogger.error('Error deleting saved search: $e');
      throw Exception('Failed to delete saved search');
    }
  }

  /// Update last used timestamp for a saved search
  Future<void> updateSavedSearchUsage(String searchId) async {
    try {
      await FirebaseFirestore.instance
          .collection('saved_searches')
          .doc(searchId)
          .update({
        'lastUsed': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Error updating saved search usage: $e');
    }
  }

  /// Get search suggestions based on popular searches
  Future<List<String>> getSearchSuggestions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('search_analytics')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final queries = snapshot.docs
          .map((doc) => doc.data()['query'] as String?)
          .where((query) => query != null && query.isNotEmpty)
          .cast<String>()
          .toList();

      // Count frequency and return most popular
      final frequency = <String, int>{};
      for (final query in queries) {
        frequency[query] = (frequency[query] ?? 0) + 1;
      }

      final sortedQueries = frequency.keys.toList()
        ..sort((a, b) => frequency[b]!.compareTo(frequency[a]!));

      return sortedQueries.take(10).toList();
    } catch (e) {
      AppLogger.error('Error getting search suggestions: $e');
      return [];
    }
  }

  /// Get all public written content (books, stories, etc.)
  Future<List<ArtworkModel>> getWrittenContent({
    int limit = 50,
    bool includeSerialized = true,
    bool includeCompleted = true,
  }) async {
    try {
      // Query for written content
      var queryRef = _artworkCollection
          .where('isPublic', isEqualTo: true)
          .where('contentType', isEqualTo: ArtworkContentType.written.value);

      // Apply serialization filters if specified
      if (!includeSerialized && !includeCompleted) {
        // If both are false, return empty list
        return [];
      } else if (!includeSerialized) {
        // Only completed works
        queryRef = queryRef.where('isSerializing', isEqualTo: false);
      } else if (!includeCompleted) {
        // Only serialized works
        queryRef = queryRef.where('isSerializing', isEqualTo: true);
      }
      // If both are true, don't filter by serialization

      final snapshot = await queryRef
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting written content: $e');

      // Fallback: Get all public artwork and filter in memory
      try {
        final allArtwork = await getAllPublicArtwork(limit: limit * 2);
        final writtenContent = allArtwork
            .where(
                (artwork) => artwork.contentType == ArtworkContentType.written)
            .where((artwork) {
              if (!includeSerialized && !includeCompleted) return false;
              if (!includeSerialized) return !artwork.isSerializing;
              if (!includeCompleted) return artwork.isSerializing;
              return true;
            })
            .take(limit)
            .toList();

        return writtenContent;
      } catch (fallbackError) {
        AppLogger.error('Fallback query also failed: $fallbackError');
        return [];
      }
    }
  }
}
