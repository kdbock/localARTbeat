import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/artwork_rating_model.dart';

/// Service for managing artwork ratings and reviews
///
/// Handles CRUD operations for artwork ratings, statistics calculation,
/// and integration with user profiles and purchase verification.
class ArtworkRatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  /// Submit or update a rating for an artwork
  ///
  /// Returns the rating ID if successful, null if failed
  Future<String?> submitRating({
    required String artworkId,
    required int rating,
    String? reviewText,
    String? purchaseId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to submit ratings');
      }

      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      // Get user profile for display name and avatar
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Check if user has already rated this artwork
      final existingRating = await getUserRatingForArtwork(artworkId, user.uid);

      final ratingData = ArtworkRatingModel(
        id: existingRating?.id ?? '',
        artworkId: artworkId,
        userId: user.uid,
        userName:
            userData['displayName'] as String? ??
            user.displayName ??
            'Anonymous',
        userAvatarUrl: userData['profileImageUrl'] as String? ?? '',
        rating: rating,
        reviewText: reviewText,
        createdAt: existingRating?.createdAt ?? Timestamp.now(),
        updatedAt: Timestamp.now(),
        isVerifiedPurchaser: purchaseId != null,
        purchaseId: purchaseId,
      );

      DocumentReference ratingRef;
      if (existingRating != null) {
        // Update existing rating
        ratingRef = _firestore
            .collection('artwork')
            .doc(artworkId)
            .collection('ratings')
            .doc(existingRating.id);
        await ratingRef.update(ratingData.toFirestore());
      } else {
        // Create new rating
        ratingRef = await _firestore
            .collection('artwork')
            .doc(artworkId)
            .collection('ratings')
            .add(ratingData.toFirestore());
      }

      // Update artwork aggregate statistics
      await _updateArtworkRatingStats(artworkId);

      return ratingRef.id;
    } catch (e) {
      _logger.e('Error submitting rating: $e', error: e);
      return null;
    }
  }

  /// Get all ratings for a specific artwork
  Future<List<ArtworkRatingModel>> getArtworkRatings(String artworkId) async {
    try {
      final snapshot = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('ratings')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ArtworkRatingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Error getting artwork ratings: $e', error: e);
      return [];
    }
  }

  /// Get a user's rating for a specific artwork
  Future<ArtworkRatingModel?> getUserRatingForArtwork(
    String artworkId,
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('ratings')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ArtworkRatingModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting user rating: $e', error: e);
      return null;
    }
  }

  /// Get rating statistics for an artwork
  Future<ArtworkRatingStats> getArtworkRatingStats(String artworkId) async {
    try {
      final ratings = await getArtworkRatings(artworkId);
      return ArtworkRatingStats.fromRatings(ratings);
    } catch (e) {
      _logger.e('Error getting rating stats: $e', error: e);
      return ArtworkRatingStats.empty();
    }
  }

  /// Delete a rating (only by the rating owner)
  Future<bool> deleteRating(String artworkId, String ratingId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Verify the rating belongs to the current user
      final ratingDoc = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('ratings')
          .doc(ratingId)
          .get();

      if (!ratingDoc.exists) return false;

      final ratingData = ratingDoc.data() as Map<String, dynamic>;
      if (ratingData['userId'] != user.uid) return false;

      await ratingDoc.reference.delete();

      // Update artwork aggregate statistics
      await _updateArtworkRatingStats(artworkId);

      return true;
    } catch (e) {
      _logger.e('Error deleting rating: $e', error: e);
      return false;
    }
  }

  /// Get top-rated artworks
  Future<List<String>> getTopRatedArtworks({int limit = 10}) async {
    try {
      // This would require a composite index on artwork collection
      // For now, we'll use a simplified approach
      final snapshot = await _firestore
          .collection('artwork')
          .where('averageRating', isGreaterThan: 4.0)
          .orderBy('averageRating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      _logger.e('Error getting top rated artworks: $e', error: e);
      return [];
    }
  }

  /// Get recent reviews with text content
  Future<List<ArtworkRatingModel>> getRecentReviews({int limit = 20}) async {
    try {
      // Get reviews across all artworks - this would require a collection group query
      final snapshot = await _firestore
          .collectionGroup('ratings')
          .where('reviewText', isNotEqualTo: null)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ArtworkRatingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Error getting recent reviews: $e', error: e);
      return [];
    }
  }

  /// Report inappropriate rating/review
  Future<bool> reportRating(
    String artworkId,
    String ratingId,
    String reason,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('reports').add({
        'type': 'rating',
        'artworkId': artworkId,
        'ratingId': ratingId,
        'reporterId': user.uid,
        'reason': reason,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      _logger.e('Error reporting rating: $e', error: e);
      return false;
    }
  }

  /// Update artwork's aggregate rating statistics
  Future<void> _updateArtworkRatingStats(String artworkId) async {
    try {
      final ratings = await getArtworkRatings(artworkId);
      final stats = ArtworkRatingStats.fromRatings(ratings);

      await _firestore.collection('artwork').doc(artworkId).update({
        'averageRating': stats.averageRating,
        'totalRatings': stats.totalRatings,
        'ratingDistribution': stats.ratingDistribution,
        'ratingsUpdatedAt': Timestamp.now(),
      });
    } catch (e) {
      _logger.e('Error updating artwork rating stats: $e', error: e);
    }
  }

  /// Verify if user has purchased the artwork (for verified purchaser status)
  Future<bool> hasUserPurchasedArtwork(String artworkId, String userId) async {
    try {
      // Check in purchases collection
      final snapshot = await _firestore
          .collection('purchases')
          .where('artworkId', isEqualTo: artworkId)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      _logger.e('Error checking purchase status: $e', error: e);
      return false;
    }
  }

  /// Stream ratings for real-time updates
  Stream<List<ArtworkRatingModel>> streamArtworkRatings(String artworkId) {
    return _firestore
        .collection('artwork')
        .doc(artworkId)
        .collection('ratings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ArtworkRatingModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream rating stats for real-time updates
  Stream<ArtworkRatingStats> streamArtworkRatingStats(String artworkId) {
    return streamArtworkRatings(
      artworkId,
    ).map((ratings) => ArtworkRatingStats.fromRatings(ratings));
  }
}
