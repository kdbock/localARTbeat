import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

/// Service for handling Stripe payment processing
class StripePaymentService {
  static final StripePaymentService _instance =
      StripePaymentService._internal();
  factory StripePaymentService() => _instance;
  StripePaymentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize Stripe (placeholder for actual Stripe init)
  Future<void> initializeStripe(String publishableKey) async {
    try {
      // In production, initialize actual Stripe SDK here
      // import 'package:flutter_stripe/flutter_stripe.dart';
      // Stripe.publishableKey = publishableKey;

      AppLogger.info('✅ Stripe initialized with publishable key');
    } catch (e) {
      AppLogger.error('❌ Error initializing Stripe: $e');
      rethrow;
    }
  }

  /// Create a payment intent for artwork purchase
  Future<Map<String, dynamic>> createPaymentIntent({
    required String artworkId,
    required String artistId,
    required double amount,
    required String currency,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // In production, call a Cloud Function that creates a Stripe PaymentIntent
      // For now, return mock response
      final paymentIntentData = {
        'clientSecret': 'pi_mock_${DateTime.now().millisecondsSinceEpoch}',
        'paymentIntentId': 'pi_${DateTime.now().millisecondsSinceEpoch}',
        'amount': (amount * 100).toInt(), // Convert to cents
        'currency': currency,
        'artworkId': artworkId,
        'artistId': artistId,
        'buyerId': user.uid,
      };

      AppLogger.info(
        '✅ Payment intent created: ${paymentIntentData['paymentIntentId']}',
      );
      return paymentIntentData;
    } catch (e) {
      AppLogger.error('❌ Error creating payment intent: $e');
      rethrow;
    }
  }

  /// Create a payment intent for auction payment
  Future<Map<String, dynamic>> createAuctionPaymentIntent({
    required String artworkId,
    required String artistId,
    required double amount,
    required String currency,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // In production, call a Cloud Function that creates a Stripe PaymentIntent
      // For now, return mock response
      final paymentIntentData = {
        'clientSecret':
            'pi_auction_mock_${DateTime.now().millisecondsSinceEpoch}',
        'paymentIntentId':
            'pi_auction_${DateTime.now().millisecondsSinceEpoch}',
        'amount': (amount * 100).toInt(), // Convert to cents
        'currency': currency,
        'artworkId': artworkId,
        'artistId': artistId,
        'buyerId': user.uid,
        'type': 'auction',
      };

      AppLogger.info(
        '✅ Auction payment intent created: ${paymentIntentData['paymentIntentId']}',
      );
      return paymentIntentData;
    } catch (e) {
      AppLogger.error('❌ Error creating auction payment intent: $e');
      rethrow;
    }
  }

  /// Confirm auction payment
  Future<String> confirmAuctionPayment({
    required String paymentIntentId,
    required String artworkId,
    required String artistId,
    required double amount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create payment record in Firestore
      final paymentDoc = _firestore.collection('transactions').doc();

      final transactionData = {
        'artworkId': artworkId,
        'artistId': artistId,
        'buyerId': user.uid,
        'amount': amount,
        'currency': 'USD',
        'type': 'auction',
        'paymentIntentId': paymentIntentId,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await paymentDoc.set(transactionData);

      // Update auction result
      await _firestore.collection('auction_results').doc(artworkId).update({
        'paymentStatus': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
      });

      // Update artwork status
      await _firestore.collection('artworks').doc(artworkId).update({
        'auctionStatus': 'paid',
        'ownerId': user.uid,
        'purchasedAt': FieldValue.serverTimestamp(),
        'purchasePrice': amount,
      });

      AppLogger.info('✅ Auction payment confirmed for artwork: $artworkId');
      return paymentDoc.id;
    } catch (e) {
      AppLogger.error('❌ Error confirming auction payment: $e');
      throw Exception('Failed to confirm auction payment: $e');
    }
  }

  /// Process artwork purchase
  Future<String> purchaseArtwork({
    required String artworkId,
    required String artistId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create payment record in Firestore
      final paymentDoc = _firestore.collection('transactions').doc();

      final transactionData = {
        'artworkId': artworkId,
        'artistId': artistId,
        'buyerId': user.uid,
        'amount': amount,
        'currency': 'USD',
        'paymentMethod': paymentMethod,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await paymentDoc.set(transactionData);

      // Update artwork with ownership
      await _firestore.collection('artworks').doc(artworkId).update({
        'ownerId': user.uid,
        'purchasedAt': FieldValue.serverTimestamp(),
        'purchasePrice': amount,
      });

      // Record transaction in user's profile
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('purchases')
          .doc(artworkId)
          .set({
            'artworkId': artworkId,
            'artistId': artistId,
            'amount': amount,
            'transactionId': paymentDoc.id,
            'purchasedAt': FieldValue.serverTimestamp(),
          });

      AppLogger.info('✅ Artwork purchased successfully: $artworkId');
      return paymentDoc.id;
    } catch (e) {
      AppLogger.error('❌ Error purchasing artwork: $e');
      rethrow;
    }
  }

  /// Verify payment status
  Future<bool> verifyPaymentStatus(String paymentIntentId) async {
    try {
      // In production, verify with Stripe API
      final transaction = await _firestore
          .collection('transactions')
          .where('stripePaymentId', isEqualTo: paymentIntentId)
          .limit(1)
          .get();

      if (transaction.docs.isEmpty) return false;

      final status = transaction.docs.first['status'] as String;
      return status == 'completed';
    } catch (e) {
      AppLogger.error('❌ Error verifying payment: $e');
      return false;
    }
  }

  /// Get user's purchase history
  Future<List<Map<String, dynamic>>> getPurchaseHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('purchases')
          .orderBy('purchasedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching purchase history: $e');
      return [];
    }
  }

  /// Refund a purchase
  Future<void> refundPurchase(String transactionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Update transaction status
      await _firestore.collection('transactions').doc(transactionId).update({
        'status': 'refunded',
        'refundedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Refund processed for transaction: $transactionId');
    } catch (e) {
      AppLogger.error('❌ Error processing refund: $e');
      rethrow;
    }
  }

  /// Calculate artist payout after fees
  double calculateArtistPayout(
    double purchaseAmount, {
    double platformFeePercentage = 0.15,
  }) {
    // Platform takes 15% fee, artist gets 85%
    return purchaseAmount * (1 - platformFeePercentage);
  }

  /// Get artist earnings
  Future<double> getArtistEarnings(String artistId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('artistId', isEqualTo: artistId)
          .where('status', isEqualTo: 'completed')
          .get();

      double totalEarnings = 0;
      for (final doc in snapshot.docs) {
        final amount = doc['amount'] as double? ?? 0;
        totalEarnings += calculateArtistPayout(amount);
      }

      return totalEarnings;
    } catch (e) {
      AppLogger.error('❌ Error fetching artist earnings: $e');
      return 0;
    }
  }
}
