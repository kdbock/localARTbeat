import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/in_app_purchase_models.dart';
import '../utils/logger.dart';
import 'in_app_purchase_service.dart';
import 'artist_feature_service.dart';

/// Service for handling gift-specific in-app purchases
class InAppGiftService {
  static final InAppGiftService _instance = InAppGiftService._internal();
  factory InAppGiftService() => _instance;
  InAppGiftService._internal();

  final InAppPurchaseService _purchaseService = InAppPurchaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Gift product configurations
  static const Map<String, Map<String, dynamic>> _giftProducts = {
    'artbeat_gift_small': {
      'amount': 4.99,
      'title': 'Supporter Gift',
      'description':
          'Artist featured for 30 days - Give your favorite artist more visibility!',
      'credits': 50,
    },
    'artbeat_gift_medium': {
      'amount': 9.99,
      'title': 'Fan Gift',
      'description':
          'Artist featured for 90 days + 1 artwork featured for 90 days - Boost their exposure!',
      'credits': 100,
    },
    'artbeat_gift_large': {
      'amount': 24.99,
      'title': 'Patron Gift',
      'description':
          'Artist featured for 180 days + 5 artworks featured for 180 days + Artist ad in rotation for 180 days - Maximum support!',
      'credits': 250,
    },
    'artbeat_gift_premium': {
      'amount': 49.99,
      'title': 'Benefactor Gift',
      'description':
          'Artist featured for 1 year + 5 artworks featured for 1 year + Artist ad in rotation for 1 year - Ultimate artist support!',
      'credits': 500,
    },
  };

  /// Purchase a gift for another user
  Future<bool> purchaseGift({
    required String recipientId,
    required String giftProductId,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.info('🎁 Starting gift purchase process...');
      AppLogger.info('🎁 Product ID: $giftProductId');
      AppLogger.info('🎁 Recipient ID: $recipientId');

      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.error('❌ User not authenticated for gift purchase');
        return false;
      }
      AppLogger.info('✅ User authenticated: ${user.uid}');

      // Check if in-app purchases are available
      if (!_purchaseService.isAvailable) {
        AppLogger.error('❌ In-app purchases not available');
        return false;
      }
      AppLogger.info('✅ In-app purchases are available');

      // Validate recipient exists
      final recipientExists = await _validateRecipient(recipientId);
      if (!recipientExists) {
        AppLogger.error('❌ Recipient not found: $recipientId');
        return false;
      }
      AppLogger.info('✅ Recipient validated');

      // Validate gift product
      if (!_giftProducts.containsKey(giftProductId)) {
        AppLogger.error('❌ Invalid gift product: $giftProductId');
        AppLogger.error('Available products: ${_giftProducts.keys.join(', ')}');
        return false;
      }
      AppLogger.info('✅ Gift product validated');

      // Purchase the gift product
      AppLogger.info('🎁 Initiating purchase with metadata...');
      final success = await _purchaseService.purchaseProduct(
        giftProductId,
        metadata: {
          'type': 'gift',
          'senderId': user.uid,
          'recipientId': recipientId,
          'message': message,
          ...?metadata,
        },
      );

      if (success) {
        AppLogger.info(
          '✅ Gift purchase initiated: $giftProductId for $recipientId',
        );

        // The actual gift processing will happen in the purchase completion callback
        // We'll create a pending gift record here
        await _createPendingGift(
          senderId: user.uid,
          recipientId: recipientId,
          productId: giftProductId,
          message: message,
        );
      } else {
        AppLogger.error('❌ Failed to initiate gift purchase');
      }

      return success;
    } catch (e) {
      AppLogger.error('❌ Error purchasing gift: $e');
      return false;
    }
  }

  /// Create a pending gift record
  Future<void> _createPendingGift({
    required String senderId,
    required String recipientId,
    required String productId,
    required String message,
  }) async {
    try {
      final giftData = _giftProducts[productId]!;

      final gift = InAppGiftPurchase(
        id: '', // Will be set by Firestore
        senderId: senderId,
        recipientId: recipientId,
        productId: productId,
        amount: giftData['amount'] as double,
        currency: 'USD',
        message: message,
        purchaseDate: DateTime.now(),
        status: 'pending',
      );

      await _firestore.collection('gifts').add(gift.toFirestore());

      AppLogger.info('✅ Pending gift created');
    } catch (e) {
      AppLogger.error('Error creating pending gift: $e');
    }
  }

  /// Complete gift purchase (called after successful payment)
  Future<void> completeGiftPurchase({
    required String senderId,
    required String recipientId,
    required String productId,
    required String transactionId,
    required String message,
  }) async {
    try {
      final giftData = _giftProducts[productId]!;

      // Create completed gift record
      final gift = InAppGiftPurchase(
        id: transactionId,
        senderId: senderId,
        recipientId: recipientId,
        productId: productId,
        amount: giftData['amount'] as double,
        currency: 'USD',
        message: message,
        purchaseDate: DateTime.now(),
        status: 'completed',
        transactionId: transactionId,
      );

      // Save gift to Firestore
      await _firestore
          .collection('gifts')
          .doc(transactionId)
          .set(gift.toFirestore());

      // Add credits to recipient's account
      final credits = giftData['credits'] as int;
      await _addCreditsToRecipient(recipientId, credits);

      // Create artist features based on gift tier
      await _createArtistFeatures(senderId, recipientId, productId);

      // Send notification to recipient
      await _sendGiftNotification(senderId, recipientId, giftData, message);

      // Update pending gift to completed
      await _updatePendingGifts(senderId, recipientId, productId, 'completed');

      AppLogger.info('✅ Gift purchase completed: $productId');
    } catch (e) {
      AppLogger.error('Error completing gift purchase: $e');
    }
  }

  /// Add credits to recipient's account
  Future<void> _addCreditsToRecipient(String recipientId, int credits) async {
    try {
      await _firestore.collection('users').doc(recipientId).update({
        'giftCredits': FieldValue.increment(credits),
        'totalGiftCreditsReceived': FieldValue.increment(credits),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Added $credits credits to recipient: $recipientId');
    } catch (e) {
      AppLogger.error('Error adding credits to recipient: $e');
    }
  }

  /// Send gift notification to recipient
  Future<void> _sendGiftNotification(
    String senderId,
    String recipientId,
    Map<String, dynamic> giftData,
    String message,
  ) async {
    try {
      // Get sender information
      final senderDoc = await _firestore
          .collection('users')
          .doc(senderId)
          .get();
      final senderName = senderDoc.exists
          ? (senderDoc.data()!['displayName'] as String? ?? 'Someone')
          : 'Someone';

      // Create notification
      await _firestore.collection('notifications').add({
        'userId': recipientId,
        'type': 'gift_received',
        'title': 'You received a gift!',
        'body': '$senderName sent you a ${giftData['title']}',
        'data': {
          'senderId': senderId,
          'senderName': senderName,
          'giftType': giftData['title'],
          'amount': giftData['amount'],
          'credits': giftData['credits'],
          'message': message,
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Gift notification sent to: $recipientId');
    } catch (e) {
      AppLogger.error('Error sending gift notification: $e');
    }
  }

  /// Update pending gifts status
  Future<void> _updatePendingGifts(
    String senderId,
    String recipientId,
    String productId,
    String status,
  ) async {
    try {
      final pendingGifts = await _firestore
          .collection('gifts')
          .where('senderId', isEqualTo: senderId)
          .where('recipientId', isEqualTo: recipientId)
          .where('productId', isEqualTo: productId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in pendingGifts.docs) {
        await doc.reference.update({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      AppLogger.error('Error updating pending gifts: $e');
    }
  }

  /// Validate recipient exists
  Future<bool> _validateRecipient(String recipientId) async {
    try {
      final doc = await _firestore.collection('users').doc(recipientId).get();
      return doc.exists;
    } catch (e) {
      AppLogger.error('Error validating recipient: $e');
      return false;
    }
  }

  /// Get available gift products
  List<Map<String, dynamic>> getAvailableGifts() {
    return _giftProducts.entries.map((entry) {
      return {'productId': entry.key, ...entry.value};
    }).toList();
  }

  /// Get user's sent gifts
  Future<List<InAppGiftPurchase>> getSentGifts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('gifts')
          .where('senderId', isEqualTo: userId)
          .orderBy('purchaseDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => InAppGiftPurchase.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting sent gifts: $e');
      return [];
    }
  }

  /// Get user's received gifts
  Future<List<InAppGiftPurchase>> getReceivedGifts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('gifts')
          .where('recipientId', isEqualTo: userId)
          .orderBy('purchaseDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => InAppGiftPurchase.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting received gifts: $e');
      return [];
    }
  }

  /// Get user's gift credits balance
  Future<int> getGiftCreditsBalance(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        return data['giftCredits'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      AppLogger.error('Error getting gift credits balance: $e');
      return 0;
    }
  }

  /// Use gift credits
  Future<bool> useGiftCredits(String userId, int amount) async {
    try {
      final currentBalance = await getGiftCreditsBalance(userId);
      if (currentBalance < amount) {
        AppLogger.warning(
          'Insufficient gift credits: $currentBalance < $amount',
        );
        return false;
      }

      await _firestore.collection('users').doc(userId).update({
        'giftCredits': FieldValue.increment(-amount),
        'giftCreditsUsed': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Used $amount gift credits for user: $userId');
      return true;
    } catch (e) {
      AppLogger.error('Error using gift credits: $e');
      return false;
    }
  }

  /// Get gift statistics for user
  Future<Map<String, dynamic>> getGiftStatistics(String userId) async {
    try {
      final sentGifts = await getSentGifts(userId);
      final receivedGifts = await getReceivedGifts(userId);
      final currentBalance = await getGiftCreditsBalance(userId);

      final totalSent = sentGifts.fold<double>(
        0,
        (sum, gift) => sum + gift.amount,
      );
      final totalReceived = receivedGifts.fold<double>(
        0,
        (sum, gift) => sum + gift.amount,
      );

      return {
        'sentCount': sentGifts.length,
        'receivedCount': receivedGifts.length,
        'totalSentAmount': totalSent,
        'totalReceivedAmount': totalReceived,
        'currentCreditsBalance': currentBalance,
        'recentSent': sentGifts.take(5).toList(),
        'recentReceived': receivedGifts.take(5).toList(),
      };
    } catch (e) {
      AppLogger.error('Error getting gift statistics: $e');
      return {
        'sentCount': 0,
        'receivedCount': 0,
        'totalSentAmount': 0.0,
        'totalReceivedAmount': 0.0,
        'currentCreditsBalance': 0,
        'recentSent': <Map<String, dynamic>>[],
        'recentReceived': <Map<String, dynamic>>[],
      };
    }
  }

  /// Search for users to send gifts to
  Future<List<Map<String, dynamic>>> searchUsersForGifts(String query) async {
    try {
      if (query.isEmpty) return [];

      // Search by display name or username
      final snapshot = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'displayName': data['displayName'] ?? 'Unknown',
          'username': data['username'] ?? '',
          'profileImageUrl': data['profileImageUrl'] ?? '',
          'userType': data['userType'] ?? 'user',
        };
      }).toList();
    } catch (e) {
      AppLogger.error('Error searching users for gifts: $e');
      return [];
    }
  }

  /// Get gift product details
  Map<String, dynamic>? getGiftProductDetails(String productId) {
    return _giftProducts[productId];
  }

  /// Check if in-app purchases are available
  bool get isAvailable => _purchaseService.isAvailable;

  /// Quick one-tap gift purchase (default $4.99 small gift)
  /// Returns true if purchase was initiated successfully
  Future<bool> purchaseQuickGift(String recipientId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.error('User not authenticated for quick gift purchase');
        return false;
      }

      if (user.uid == recipientId) {
        AppLogger.warning('Cannot send gift to yourself');
        return false;
      }

      final recipientExists = await _validateRecipient(recipientId);
      if (!recipientExists) {
        AppLogger.error('Recipient not found: $recipientId');
        return false;
      }

      const giftProductId = 'artbeat_gift_small';
      const defaultMessage = 'A gift from an ArtBeat user';

      final success = await purchaseGift(
        recipientId: recipientId,
        giftProductId: giftProductId,
        message: defaultMessage,
      );

      return success;
    } catch (e) {
      AppLogger.error('Error purchasing quick gift: $e');
      return false;
    }
  }

  /// Create artist features for a completed gift purchase
  Future<void> _createArtistFeatures(
    String senderId,
    String recipientId,
    String productId,
  ) async {
    try {
      final featureService = ArtistFeatureService();
      await featureService.createFeaturesForGift(
        giftId: productId,
        artistId: recipientId,
        purchaserId: senderId,
      );

      AppLogger.info('✅ Artist features created for gift: $productId');
    } catch (e) {
      AppLogger.error('❌ Error creating artist features: $e');
      // Don't fail the gift purchase if feature creation fails
      // Features can be created manually later if needed
    }
  }
}
