import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/auction_models.dart';
import '../models/artwork_model.dart';

/// Service for handling auction operations
class AuctionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  /// Get auction details for a specific artwork
  Future<ArtworkModel?> getAuctionForArtwork(String artworkId) async {
    try {
      final doc = await _firestore.collection('artworks').doc(artworkId).get();
      if (!doc.exists) return null;

      final artwork = ArtworkModel.fromFirestore(doc);
      return artwork.auctionEnabled ? artwork : null;
    } catch (e) {
      if (kDebugMode) {
        _logger.e('Error getting auction for artwork: $e');
      }
      return null;
    }
  }

  /// Get current highest bid for an artwork
  Future<double?> getCurrentHighestBid(String artworkId) async {
    try {
      final doc = await _firestore.collection('artworks').doc(artworkId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return data['currentHighestBid'] != null
          ? (data['currentHighestBid'] as num).toDouble()
          : null;
    } catch (e) {
      if (kDebugMode) {
        _logger.e('Error getting current highest bid: $e');
      }
      return null;
    }
  }

  /// Place a bid on an artwork (calls Cloud Function)
  Future<Map<String, dynamic>> placeBid(String artworkId, double amount) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      // Call Cloud Function
      final callable = FirebaseFunctions.instance.httpsCallable('placeBid');
      final result = await callable.call<Map<String, dynamic>>({
        'artworkId': artworkId,
        'amount': amount,
      });

      return {
        'success': true,
        'bidId': result.data['bidId'],
        'amount': result.data['amount'],
        'timestamp': result.data['timestamp'],
      };
    } catch (e) {
      if (kDebugMode) {
        _logger.e('Error placing bid: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get all bids for a specific user
  Future<List<Map<String, dynamic>>> getUserBids(String userId) async {
    try {
      // Get all artworks that have bids from this user
      final artworksSnapshot = await _firestore
          .collection('artwork')
          .where('currentHighestBidder', isEqualTo: userId)
          .get();

      final userBids = <Map<String, dynamic>>[];

      for (final artworkDoc in artworksSnapshot.docs) {
        final artwork = ArtworkModel.fromFirestore(artworkDoc);

        // Get bid details from subcollection
        final bidsSnapshot = await _firestore
            .collection('artwork')
            .doc(artwork.id)
            .collection('bids')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (bidsSnapshot.docs.isNotEmpty) {
          final bidDoc = bidsSnapshot.docs.first;
          final bid = AuctionBidModel.fromFirestore(bidDoc);

          userBids.add({
            'artwork': artwork,
            'bid': bid,
            'isWinning': artwork.currentHighestBidder == userId,
            'auctionStatus': artwork.auctionStatus,
          });
        }
      }

      return userBids;
    } catch (e) {
      _logger.e('Error getting user bids: $e');
      return [];
    }
  }

  /// Get bid history for an artwork (for display)
  Future<List<AuctionBidModel>> getBidHistory(String artworkId) async {
    try {
      final snapshot = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('bids')
          .orderBy('timestamp', descending: true)
          .limit(10) // Limit for performance
          .get();

      return snapshot.docs
          .map((doc) => AuctionBidModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Error getting bid history: $e');
      return [];
    }
  }

  /// Check if user can bid on artwork
  Future<Map<String, dynamic>> canUserBid(
    String artworkId,
    String userId,
  ) async {
    try {
      final artworkDoc = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .get();
      if (!artworkDoc.exists) {
        return {'canBid': false, 'reason': 'Artwork not found'};
      }

      final artwork = ArtworkModel.fromFirestore(artworkDoc);

      if (!artwork.auctionEnabled) {
        return {'canBid': false, 'reason': 'Not an auction'};
      }

      if (artwork.auctionStatus != 'open') {
        return {'canBid': false, 'reason': 'Auction not open'};
      }

      if (artwork.userId == userId) {
        return {'canBid': false, 'reason': 'Cannot bid on own artwork'};
      }

      if (artwork.auctionEnd != null &&
          artwork.auctionEnd!.isBefore(DateTime.now())) {
        return {'canBid': false, 'reason': 'Auction ended'};
      }

      return {'canBid': true};
    } catch (e) {
      _logger.e('Error checking if user can bid: $e');
      return {'canBid': false, 'reason': 'Error checking bid eligibility'};
    }
  }

  /// Get minimum next bid amount
  double getMinimumNextBid(double? currentHighestBid, double? startingPrice) {
    final baseAmount = currentHighestBid ?? startingPrice ?? 0.0;

    // Simple increment logic - can be made more sophisticated
    if (baseAmount < 100) return baseAmount + 5;
    if (baseAmount < 500) return baseAmount + 10;
    if (baseAmount < 1000) return baseAmount + 25;
    if (baseAmount < 5000) return baseAmount + 50;
    return baseAmount + 100;
  }

  /// Stream auction updates for an artwork (polling approach)
  Stream<ArtworkModel?> streamAuctionUpdates(String artworkId) {
    return _firestore.collection('artworks').doc(artworkId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      final artwork = ArtworkModel.fromFirestore(doc);
      return artwork.auctionEnabled ? artwork : null;
    });
  }
}
