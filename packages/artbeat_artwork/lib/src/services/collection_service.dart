import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppLogger;
import '../models/collection_model.dart';
import '../models/artwork_model.dart';
import 'artwork_service.dart';

/// Service for managing artwork collections and portfolios
class CollectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ArtworkService _artworkService = ArtworkService();

  static const String _collectionsCollection = 'collections';

  /// Create a new collection
  Future<String> createCollection({
    required String title,
    required String description,
    required String artistProfileId,
    String? coverImageUrl,
    List<String> artworkIds = const [],
    List<String> tags = const [],
    CollectionType type = CollectionType.personal,
    CollectionVisibility visibility = CollectionVisibility.public,
    bool isPortfolio = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final collection = CollectionModel(
        id: '', // Will be set by Firestore
        userId: user.uid,
        artistProfileId: artistProfileId,
        title: title,
        description: description,
        coverImageUrl: coverImageUrl,
        artworkIds: artworkIds,
        tags: tags,
        type: type,
        visibility: visibility,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPortfolio: isPortfolio,
      );

      final docRef = await _firestore
          .collection(_collectionsCollection)
          .add(collection.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create collection: $e');
    }
  }

  /// Get collection by ID
  Future<CollectionModel?> getCollectionById(String collectionId) async {
    try {
      final doc = await _firestore
          .collection(_collectionsCollection)
          .doc(collectionId)
          .get();

      if (!doc.exists) return null;

      return CollectionModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get collection: $e');
    }
  }

  /// Get all collections for an artist
  Future<List<CollectionModel>> getCollectionsByArtist(
    String artistProfileId,
  ) async {
    try {
      final query = await _firestore
          .collection(_collectionsCollection)
          .where('artistProfileId', isEqualTo: artistProfileId)
          .orderBy('sortOrder')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => CollectionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get artist collections: $e');
    }
  }

  /// Get public collections (for browsing)
  Future<List<CollectionModel>> getPublicCollections({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    CollectionType? filterByType,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionsCollection)
          .where('visibility', isEqualTo: CollectionVisibility.public.name);

      if (filterByType != null) {
        query = query.where('type', isEqualTo: filterByType.name);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => CollectionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get public collections: $e');
    }
  }

  /// Get featured collections
  Future<List<CollectionModel>> getFeaturedCollections({int limit = 10}) async {
    try {
      final query = await _firestore
          .collection(_collectionsCollection)
          .where('isFeatured', isEqualTo: true)
          .where('visibility', isEqualTo: CollectionVisibility.public.name)
          .orderBy('sortOrder')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => CollectionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get featured collections: $e');
    }
  }

  /// Update collection
  Future<void> updateCollection(
    String collectionId, {
    String? title,
    String? description,
    String? coverImageUrl,
    List<String>? artworkIds,
    List<String>? tags,
    CollectionType? type,
    CollectionVisibility? visibility,
    bool? isPortfolio,
    int? sortOrder,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (coverImageUrl != null) updateData['coverImageUrl'] = coverImageUrl;
      if (artworkIds != null) updateData['artworkIds'] = artworkIds;
      if (tags != null) updateData['tags'] = tags;
      if (type != null) updateData['type'] = type.name;
      if (visibility != null) updateData['visibility'] = visibility.name;
      if (isPortfolio != null) updateData['isPortfolio'] = isPortfolio;
      if (sortOrder != null) updateData['sortOrder'] = sortOrder;

      await _firestore
          .collection(_collectionsCollection)
          .doc(collectionId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update collection: $e');
    }
  }

  /// Add artwork to collection
  Future<void> addArtworkToCollection(
    String collectionId,
    String artworkId,
  ) async {
    try {
      final collection = await getCollectionById(collectionId);
      if (collection == null) {
        throw Exception('Collection not found');
      }

      // Check if artwork already in collection
      if (collection.artworkIds.contains(artworkId)) {
        return; // Already in collection
      }

      final updatedArtworkIds = [...collection.artworkIds, artworkId];

      await updateCollection(collectionId, artworkIds: updatedArtworkIds);
    } catch (e) {
      throw Exception('Failed to add artwork to collection: $e');
    }
  }

  /// Remove artwork from collection
  Future<void> removeArtworkFromCollection(
    String collectionId,
    String artworkId,
  ) async {
    try {
      final collection = await getCollectionById(collectionId);
      if (collection == null) {
        throw Exception('Collection not found');
      }

      final updatedArtworkIds = collection.artworkIds
          .where((id) => id != artworkId)
          .toList();

      await updateCollection(collectionId, artworkIds: updatedArtworkIds);
    } catch (e) {
      throw Exception('Failed to remove artwork from collection: $e');
    }
  }

  /// Get artworks in a collection with full artwork data
  Future<List<ArtworkModel>> getCollectionArtworks(String collectionId) async {
    try {
      final collection = await getCollectionById(collectionId);
      if (collection == null) {
        throw Exception('Collection not found');
      }

      if (collection.artworkIds.isEmpty) {
        return [];
      }

      // Batch fetch artworks
      final artworks = <ArtworkModel>[];
      for (final artworkId in collection.artworkIds) {
        try {
          final artwork = await _artworkService.getArtworkById(artworkId);
          if (artwork != null) {
            artworks.add(artwork);
          }
        } catch (e) {
          // Skip individual artwork errors
          continue;
        }
      }

      return artworks;
    } catch (e) {
      throw Exception('Failed to get collection artworks: $e');
    }
  }

  /// Delete collection
  Future<void> deleteCollection(String collectionId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Verify ownership
      final collection = await getCollectionById(collectionId);
      if (collection == null) {
        throw Exception('Collection not found');
      }

      if (collection.userId != user.uid) {
        throw Exception('Not authorized to delete this collection');
      }

      await _firestore
          .collection(_collectionsCollection)
          .doc(collectionId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete collection: $e');
    }
  }

  /// Search collections
  Future<List<CollectionModel>> searchCollections(
    String searchTerm, {
    CollectionType? filterByType,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionsCollection)
          .where('visibility', isEqualTo: CollectionVisibility.public.name);

      if (filterByType != null) {
        query = query.where('type', isEqualTo: filterByType.name);
      }

      final querySnapshot = await query.get();

      // Client-side filtering for search term (Firestore doesn't support full-text search)
      final searchLower = searchTerm.toLowerCase();
      final results = querySnapshot.docs
          .map((doc) => CollectionModel.fromFirestore(doc))
          .where((collection) {
            return collection.title.toLowerCase().contains(searchLower) ||
                collection.description.toLowerCase().contains(searchLower) ||
                collection.tags.any(
                  (tag) => tag.toLowerCase().contains(searchLower),
                );
          })
          .take(limit)
          .toList();

      return results;
    } catch (e) {
      throw Exception('Failed to search collections: $e');
    }
  }

  /// Increment collection view count
  Future<void> incrementViewCount(String collectionId) async {
    try {
      await _firestore
          .collection(_collectionsCollection)
          .doc(collectionId)
          .update({'viewCount': FieldValue.increment(1)});
    } catch (e) {
      // Don't throw error for view count increment failures
      AppLogger.warning('Failed to increment collection view count: $e');
    }
  }

  /// Get user's collections (private access)
  Future<List<CollectionModel>> getUserCollections() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final query = await _firestore
          .collection(_collectionsCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('isPortfolio', descending: true) // Portfolio first
          .orderBy('sortOrder')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => CollectionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user collections: $e');
    }
  }

  /// Get artist's main portfolio
  Future<CollectionModel?> getArtistPortfolio(String artistProfileId) async {
    try {
      final query = await _firestore
          .collection(_collectionsCollection)
          .where('artistProfileId', isEqualTo: artistProfileId)
          .where('isPortfolio', isEqualTo: true)
          .where(
            'visibility',
            whereIn: [
              CollectionVisibility.public.name,
              CollectionVisibility.unlisted.name,
            ],
          )
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      return CollectionModel.fromFirestore(query.docs.first);
    } catch (e) {
      throw Exception('Failed to get artist portfolio: $e');
    }
  }

  /// Create default portfolio for artist
  Future<String> createDefaultPortfolio(String artistProfileId) async {
    try {
      return await createCollection(
        title: 'My Portfolio',
        description: 'Showcase of my best artwork',
        artistProfileId: artistProfileId,
        type: CollectionType.portfolio,
        visibility: CollectionVisibility.public,
        isPortfolio: true,
        tags: ['portfolio', 'artwork'],
      );
    } catch (e) {
      throw Exception('Failed to create default portfolio: $e');
    }
  }
}
