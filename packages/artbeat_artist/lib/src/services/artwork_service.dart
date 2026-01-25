import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/artwork_model.dart';
import '../utils/artist_logger.dart';

/// Service for artwork management
class ArtworkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get all artwork by artist profile ID
  Future<List<ArtworkModel>> getArtworkByArtistProfileId(
    String artistProfileId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('artwork')
          .where('artistProfileId', isEqualTo: artistProfileId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ArtworkModel.fromMap({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      ArtistLogger.error('Error getting artwork: $e');
      return [];
    }
  }

  /// Get artwork by ID
  Future<ArtworkModel?> getArtworkById(String artworkId) async {
    try {
      final doc = await _firestore.collection('artwork').doc(artworkId).get();

      if (!doc.exists) return null;

      return ArtworkModel.fromMap({'id': doc.id, ...doc.data()!});
    } catch (e) {
      ArtistLogger.error('Error getting artwork by ID: $e');
      return null;
    }
  }

  /// Create new artwork
  Future<String?> createArtwork({
    required String title,
    required String description,
    required String imageUrl,
    required String medium,
    List<String>? styles,
    double? price,
    bool isForSale = false,
    String? dimensions,
    int? yearCreated,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // First get the artist profile ID
      final artistProfileSnapshot = await _firestore
          .collection('artistProfiles')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (artistProfileSnapshot.docs.isEmpty) {
        throw Exception('Artist profile not found');
      }

      final artistProfileId = artistProfileSnapshot.docs.first.id;

      final docRef = await _firestore.collection('artwork').add({
        'artistProfileId': artistProfileId,
        'userId': userId,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'medium': medium,
        'styles': styles ?? [],
        'price': price,
        'isForSale': isForSale,
        'dimensions': dimensions,
        'yearCreated': yearCreated,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      ArtistLogger.error('Error creating artwork: $e');
      return null;
    }
  }

  /// Update existing artwork
  Future<bool> updateArtwork({
    required String artworkId,
    String? title,
    String? description,
    String? imageUrl,
    String? medium,
    List<String>? styles,
    double? price,
    bool? isForSale,
    String? dimensions,
    int? yearCreated,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Check if user owns this artwork
      final artwork = await getArtworkById(artworkId);
      if (artwork == null || artwork.userId != userId) {
        throw Exception('Unauthorized');
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only include fields that are being updated
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (medium != null) updateData['medium'] = medium;
      if (styles != null) updateData['styles'] = styles;
      if (price != null) updateData['price'] = price;
      if (isForSale != null) updateData['isForSale'] = isForSale;
      if (dimensions != null) updateData['dimensions'] = dimensions;
      if (yearCreated != null) updateData['yearCreated'] = yearCreated;

      await _firestore.collection('artwork').doc(artworkId).update(updateData);

      return true;
    } catch (e) {
      ArtistLogger.error('Error updating artwork: $e');
      return false;
    }
  }

  /// Delete artwork
  Future<bool> deleteArtwork(String artworkId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Check if user owns this artwork
      final artwork = await getArtworkById(artworkId);
      if (artwork == null || artwork.userId != userId) {
        throw Exception('Unauthorized');
      }

      await _firestore.collection('artwork').doc(artworkId).delete();

      return true;
    } catch (e) {
      ArtistLogger.error('Error deleting artwork: $e');
      return false;
    }
  }

  /// Get featured artwork
  Future<List<ArtworkModel>> getFeaturedArtwork({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('artwork')
          .where('isFeatured', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return ArtworkModel.fromMap({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      ArtistLogger.error('Error getting featured artwork: $e');
      return [];
    }
  }

  /// Get artwork by location
  Future<List<ArtworkModel>> getArtworkByLocation(
    String location, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('artwork')
          .where('location', isEqualTo: location)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return ArtworkModel.fromMap({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      ArtistLogger.error('Error getting artwork by location: $e');
      return [];
    }
  }

  /// Get all artwork by user ID
  Future<List<ArtworkModel>> getArtworkByUserId(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('artwork')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ArtworkModel.fromMap({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      ArtistLogger.error('Error getting artwork by user ID: $e');
      return [];
    }
  }
}
