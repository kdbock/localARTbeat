import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/in_app_purchase_models.dart';
import '../utils/logger.dart';
import 'in_app_purchase_service.dart';
import 'artist_feature_service.dart';

/// Service for handling artist boost-specific in-app purchases
class ArtistBoostService {
  static final ArtistBoostService _instance = ArtistBoostService._internal();
  factory ArtistBoostService() => _instance;
  ArtistBoostService._internal();

  final InAppPurchaseService _purchaseService = InAppPurchaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Artist Boost configurations (Option 2: Game Pack Vibe)
  static const Map<String, Map<String, dynamic>> _boostProducts = {
    'artbeat_gift_small': {
      'amount': 4.99,
      'title': 'The Quick Spark',
      'description':
          '⚡ Instant Buff: 30 Days "Glow" effect on profile + Featured artist status!',
      'credits': 50,
      'powerLevel': 'Basic Buff',
    },
    'artbeat_gift_medium': {
      'amount': 9.99,
      'title': 'The Neon Surge',
      'description':
          '🌈 Chroma Pack: 90 Days Featured Artist + 1 "Shiny" Artwork slot!',
      'credits': 100,
      'powerLevel': 'Rare Expansion',
    },
    'artbeat_gift_large': {
      'amount': 24.99,
      'title': 'The Titan Overdrive',
      'description':
          '🛡️ Elite Gear: 180 Days Max Visibility + 5 Slots + Global Ad Rotation!',
      'credits': 250,
      'powerLevel': 'Epic Gear',
    },
    'artbeat_gift_premium': {
      'amount': 49.99,
      'title': 'The Mythic Expansion',
      'description':
          '💎 Ultimate DLC: 1 Year "Legendary" status + Zero Commission on next 3 sales!',
      'credits': 500,
      'powerLevel': 'Mythic Legacy',
    },
  };

  /// Purchase a boost for another user
  Future<bool> purchaseBoost({
    required String recipientId,
    required String boostProductId,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.info('🚀 Starting boost purchase process...');
      AppLogger.info('🚀 Product ID: $boostProductId');
      AppLogger.info('🚀 Recipient ID: $recipientId');

      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.error('❌ User not authenticated for boost purchase');
        throw Exception('You must be signed in to send boosts');
      }
      AppLogger.info('✅ User authenticated: ${user.uid}');

      // Check if in-app purchases are available
      if (!_purchaseService.isAvailable) {
        AppLogger.error('❌ In-app purchases not available');
        throw Exception(
          'In-app purchases are not available on this device. Please check your App Store connection.',
        );
      }
      AppLogger.info('✅ In-app purchases are available');

      // Validate recipient exists
      final recipientExists = await _validateRecipient(recipientId);
      if (!recipientExists) {
        AppLogger.error('❌ Recipient not found: $recipientId');
        throw Exception('Recipient artist not found');
      }
      AppLogger.info('✅ Recipient validated');

      // Validate boost product
      if (!_boostProducts.containsKey(boostProductId)) {
        AppLogger.error('❌ Invalid boost product: $boostProductId');
        AppLogger.error('Available products: ${_boostProducts.keys.join(', ')}');
        throw Exception('Invalid boost product: $boostProductId');
      }
      AppLogger.info('✅ Boost product validated');

      // Purchase the boost product
      AppLogger.info('🚀 Initiating purchase with metadata...');
      final success = await _purchaseService.purchaseProduct(
        boostProductId,
        metadata: {
          'type': 'boost',
          'senderId': user.uid,
          'recipientId': recipientId,
          'message': message,
          ...?metadata,
        },
      );

      if (success) {
        AppLogger.info(
          '✅ Boost purchase initiated: $boostProductId for $recipientId',
        );

        // The actual boost processing will happen in the purchase completion callback
        // We'll create a pending boost record here
        await _createPendingBoost(
          senderId: user.uid,
          recipientId: recipientId,
          productId: boostProductId,
          message: message,
        );
      } else {
        AppLogger.error('❌ Failed to initiate boost purchase');
        throw Exception(
          'Could not start purchase. The boost product may not be available in the App Store.',
        );
      }

      return success;
    } catch (e) {
      AppLogger.error('❌ Error purchasing boost: $e');
      rethrow; // Re-throw to show user the specific error
    }
  }

  /// Create a pending boost record
  Future<void> _createPendingBoost({
    required String senderId,
    required String recipientId,
    required String productId,
    required String message,
  }) async {
    try {
      final boostData = _boostProducts[productId]!;

      final boost = ArtistBoostPurchase(
        id: '', // Will be set by Firestore
        senderId: senderId,
        recipientId: recipientId,
        productId: productId,
        amount: boostData['amount'] as double,
        currency: 'USD',
        message: message,
        purchaseDate: DateTime.now(),
        status: 'pending',
      );

      await _firestore.collection('boosts').add(boost.toFirestore());

      AppLogger.info('✅ Pending boost created');
    } catch (e) {
      AppLogger.error('Error creating pending boost: $e');
    }
  }

  /// Complete boost purchase (called after successful payment)
  Future<void> completeBoostPurchase({
    required String senderId,
    required String recipientId,
    required String productId,
    required String transactionId,
    required String message,
  }) async {
    try {
      final boostData = _boostProducts[productId]!;

      // Create completed boost record
      final boost = ArtistBoostPurchase(
        id: transactionId,
        senderId: senderId,
        recipientId: recipientId,
        productId: productId,
        amount: boostData['amount'] as double,
        currency: 'USD',
        message: message,
        purchaseDate: DateTime.now(),
        status: 'completed',
        transactionId: transactionId,
      );

      // Save boost to Firestore
      await _firestore
          .collection('boosts')
          .doc(transactionId)
          .set(boost.toFirestore());

      // Add XP to recipient's account
      final xpAmount = boostData['credits'] as int;
      await _addXPToRecipient(recipientId, xpAmount);

      // Create artist features based on boost tier
      await _createArtistFeatures(senderId, recipientId, productId);

      // Send notification to recipient
      await _sendBoostNotification(senderId, recipientId, boostData, message);

      // Update pending boost to completed
      await _updatePendingBoosts(senderId, recipientId, productId, 'completed');

      AppLogger.info('✅ Boost purchase completed: $productId');
    } catch (e) {
      AppLogger.error('Error completing boost purchase: $e');
    }
  }

  /// Add XP to recipient's account
  Future<void> _addXPToRecipient(String recipientId, int xp) async {
    try {
      await _firestore.collection('users').doc(recipientId).update({
        'artistXP': FieldValue.increment(xp),
        'totalXPReceived': FieldValue.increment(xp),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Added $xp XP to artist: $recipientId');
    } catch (e) {
      AppLogger.error('Error adding XP to recipient: $e');
    }
  }

  /// Send boost notification to recipient
  Future<void> _sendBoostNotification(
    String senderId,
    String recipientId,
    Map<String, dynamic> giftData,
    String message,
  ) async {
    try {
      // Get sender information
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      final senderName = senderDoc.exists
          ? (senderDoc.data()!['displayName'] as String? ?? 'A Fan')
          : 'A Fan';

      // Create notification
      await _firestore.collection('notifications').add({
        'userId': recipientId,
        'type': 'boost_received',
        'title': 'Artist Power-Up!',
        'body': '$senderName activated ${giftData['title']} for you!',
        'data': {
          'senderId': senderId,
          'senderName': senderName,
          'boostType': giftData['title'],
          'amount': giftData['amount'],
          'xp': giftData['credits'],
          'message': message,
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Boost notification sent to: $recipientId');
    } catch (e) {
      AppLogger.error('Error sending boost notification: $e');
    }
  }

  /// Update pending boosts status
  Future<void> _updatePendingBoosts(
    String senderId,
    String recipientId,
    String productId,
    String status,
  ) async {
    try {
      final pendingBoosts = await _firestore
          .collection('boosts')
          .where('senderId', isEqualTo: senderId)
          .where('recipientId', isEqualTo: recipientId)
          .where('productId', isEqualTo: productId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in pendingBoosts.docs) {
        await doc.reference.update({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      AppLogger.error('Error updating pending boosts: $e');
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

  /// Get available boost products
  List<Map<String, dynamic>> getAvailableBoosts() {
    return _boostProducts.entries.map((entry) {
      return {'productId': entry.key, ...entry.value};
    }).toList();
  }

  /// Get user's sent boosts
  Future<List<ArtistBoostPurchase>> getSentBoosts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('boosts')
          .where('senderId', isEqualTo: userId)
          .orderBy('purchaseDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ArtistBoostPurchase.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting sent boosts: $e');
      return [];
    }
  }

  /// Get user's received boosts
  Future<List<ArtistBoostPurchase>> getReceivedBoosts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('boosts')
          .where('recipientId', isEqualTo: userId)
          .orderBy('purchaseDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ArtistBoostPurchase.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting received boosts: $e');
      return [];
    }
  }

  /// Get user's Artist XP balance
  Future<int> getArtistXPBalance(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        return data['artistXP'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      AppLogger.error('Error getting Artist XP balance: $e');
      return 0;
    }
  }

  /// Use Artist XP
  Future<bool> useArtistXP(String userId, int amount) async {
    try {
      final currentBalance = await getArtistXPBalance(userId);
      if (currentBalance < amount) {
        AppLogger.warning(
          'Insufficient Artist XP: $currentBalance < $amount',
        );
        return false;
      }

      await _firestore.collection('users').doc(userId).update({
        'artistXP': FieldValue.increment(-amount),
        'artistXPUsed': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Used $amount Artist XP for user: $userId');
      return true;
    } catch (e) {
      AppLogger.error('Error using Artist XP: $e');
      return false;
    }
  }

  /// Get boost statistics for user
  Future<Map<String, dynamic>> getBoostStatistics(String userId) async {
    try {
      final sentBoosts = await getSentBoosts(userId);
      final receivedBoosts = await getReceivedBoosts(userId);
      final currentBalance = await getArtistXPBalance(userId);

      final totalSent = sentBoosts.fold<double>(
        0,
        (sum, boost) => sum + boost.amount,
      );
      final totalReceived = receivedBoosts.fold<double>(
        0,
        (sum, boost) => sum + boost.amount,
      );

      return {
        'sentCount': sentBoosts.length,
        'receivedCount': receivedBoosts.length,
        'totalSentAmount': totalSent,
        'totalReceivedAmount': totalReceived,
        'currentXPBalance': currentBalance,
        'recentSent': sentBoosts.take(5).toList(),
        'recentReceived': receivedBoosts.take(5).toList(),
      };
    } catch (e) {
      AppLogger.error('Error getting boost statistics: $e');
      return {
        'sentCount': 0,
        'receivedCount': 0,
        'totalSentAmount': 0.0,
        'totalReceivedAmount': 0.0,
        'currentXPBalance': 0,
        'recentSent': <Map<String, dynamic>>[],
        'recentReceived': <Map<String, dynamic>>[],
      };
    }
  }

  /// Search for users to send boosts to
  Future<List<Map<String, dynamic>>> searchUsersForBoosts(String query) async {
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
      AppLogger.error('Error searching users for boosts: $e');
      return [];
    }
  }

  /// Get boost product details
  Map<String, dynamic>? getBoostProductDetails(String productId) {
    return _boostProducts[productId];
  }

  /// Check if in-app purchases are available
  bool get isAvailable => _purchaseService.isAvailable;

  /// Quick one-tap boost purchase (default $4.99 small boost)
  /// Returns true if purchase was initiated successfully
  Future<bool> purchaseQuickBoost(String recipientId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.error('User not authenticated for quick boost purchase');
        return false;
      }

      if (user.uid == recipientId) {
        AppLogger.warning('Cannot send boost to yourself');
        return false;
      }

      final recipientExists = await _validateRecipient(recipientId);
      if (!recipientExists) {
        AppLogger.error('Recipient not found: $recipientId');
        return false;
      }

      const boostProductId = 'artbeat_gift_small';
      const defaultMessage = 'A boost from an ArtBeat user';

      final success = await purchaseBoost(
        recipientId: recipientId,
        boostProductId: boostProductId,
        message: defaultMessage,
      );

      return success;
    } catch (e) {
      AppLogger.error('Error purchasing quick boost: $e');
      return false;
    }
  }

  /// Create artist features for a completed boost purchase
  Future<void> _createArtistFeatures(
    String senderId,
    String recipientId,
    String productId,
  ) async {
    try {
      final featureService = ArtistFeatureService();
      await featureService.createFeaturesForBoost(
        boostId: productId,
        artistId: recipientId,
        purchaserId: senderId,
      );

      AppLogger.info('✅ Artist features created for boost: $productId');
    } catch (e) {
      AppLogger.error('❌ Error creating artist features: $e');
      // Don't fail the boost purchase if feature creation fails
      // Features can be created manually later if needed
    }
  }
}
