import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/artwork_content_type.dart';
import '../models/artwork_model.dart';
import '../utils/logger.dart';

class ArtworkReadService {
  FirebaseFirestore? _firestoreInstance;

  void initialize() {
    _firestoreInstance ??= FirebaseFirestore.instance;
  }

  FirebaseFirestore get _firestore {
    initialize();
    return _firestoreInstance!;
  }

  CollectionReference<Map<String, dynamic>> get _artworkCollection =>
      _firestore.collection('artwork');

  Future<List<ArtworkModel>> getFeaturedArtwork({
    int limit = 10,
    String? chapterId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _artworkCollection
          .where('isFeatured', isEqualTo: true)
          .where('isPublic', isEqualTo: true);

      if (chapterId != null) {
        query = query.where('chapterId', isEqualTo: chapterId);
      } else {
        query = query.where('chapterId', isNull: true);
      }

      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(ArtworkModel.fromFirestore).toList();
    } catch (e) {
      AppLogger.error('Error getting featured artwork: $e');
      return [];
    }
  }

  Future<List<ArtworkModel>> getAllPublicArtwork({
    int limit = 50,
    String? chapterId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _artworkCollection.where(
        'isPublic',
        isEqualTo: true,
      );

      if (chapterId != null) {
        query = query.where('chapterId', isEqualTo: chapterId);
      } else {
        query = query.where('chapterId', isNull: true);
      }

      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(ArtworkModel.fromFirestore).toList();
    } catch (e) {
      AppLogger.error('Error getting public artwork with composite query: $e');

      try {
        final fallbackSnapshot = await _artworkCollection
            .where('isPublic', isEqualTo: true)
            .limit(limit)
            .get();

        final artworks = fallbackSnapshot.docs
            .map(ArtworkModel.fromFirestore)
            .toList();
        artworks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return artworks;
      } catch (fallbackError) {
        AppLogger.error('Fallback query also failed: $fallbackError');
        return [];
      }
    }
  }

  Future<List<ArtworkModel>> getWrittenContent({
    int limit = 50,
    bool includeSerialized = true,
    bool includeCompleted = true,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _artworkCollection
          .where('isPublic', isEqualTo: true)
          .where('contentType', isEqualTo: ArtworkContentType.written.value);

      if (!includeSerialized && !includeCompleted) {
        return [];
      } else if (!includeSerialized) {
        query = query.where('isSerializing', isEqualTo: false);
      } else if (!includeCompleted) {
        query = query.where('isSerializing', isEqualTo: true);
      }

      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(ArtworkModel.fromFirestore).toList();
    } catch (e) {
      AppLogger.error('Error getting written content: $e');

      try {
        final allArtwork = await getAllPublicArtwork(limit: limit * 2);
        return allArtwork
            .where((artwork) => artwork.contentType == ArtworkContentType.written)
            .where((artwork) {
              if (!includeSerialized && !includeCompleted) return false;
              if (!includeSerialized) return !artwork.isSerializing;
              if (!includeCompleted) return artwork.isSerializing;
              return true;
            })
            .take(limit)
            .toList();
      } catch (fallbackError) {
        AppLogger.error('Fallback query also failed: $fallbackError');
        return [];
      }
    }
  }
}
