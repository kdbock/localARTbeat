import 'dart:io' show Platform;

import 'package:artbeat_core/artbeat_core.dart' show PurchaseVerificationService;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/index.dart';

class LocalAdService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'localAds';
  static const String _recoveriesCollection = 'localAdPurchaseRecoveries';

  Future<String> createAd(LocalAd ad) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final newAd = ad.copyWith(id: docRef.id);
      await docRef.set(newAd.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create ad: $e');
    }
  }

  Future<({String? adId, String? recoveryId})> createPurchasedAd({
    required LocalAd ad,
    required String verificationData,
  }) async {
    try {
      final isVerified = await _verifyPurchase(
        ad: ad,
        verificationData: verificationData,
      );

      if (!isVerified) {
        throw Exception('Store purchase verification failed for ad checkout');
      }

      final adId = await createAd(
        ad.copyWith(
          purchaseFollowUpStatus: 'verified_pending_review',
          purchaseFollowUpNotes:
              'Store purchase verified server-side before ad creation.',
        ),
      );
      return (adId: adId, recoveryId: null);
    } catch (error) {
      try {
        final recoveryRef = _firestore.collection(_recoveriesCollection).doc();
        await recoveryRef.set({
          'userId': ad.userId,
          'createdAt': Timestamp.now(),
          'status': 'pending_manual_recovery',
          'error': error.toString(),
          'adPayload': ad.toMap(),
          'purchaseId': ad.purchaseId,
          'transactionId': ad.transactionId,
          'subscriptionProductId': ad.subscriptionProductId,
          'purchaseFollowUpStatus': ad.purchaseFollowUpStatus,
          'purchaseFollowUpNotes': ad.purchaseFollowUpNotes,
        });
        return (adId: null, recoveryId: recoveryRef.id);
      } catch (_) {
        rethrow;
      }
    }
  }

  Future<LocalAd?> getAd(String id) async {
    try {
      final snapshot = await _firestore.collection(_collection).doc(id).get();
      if (!snapshot.exists) return null;
      return LocalAd.fromSnapshot(snapshot);
    } catch (e) {
      throw Exception('Failed to fetch ad: $e');
    }
  }

  Future<List<LocalAd>> getAdsByZone(LocalAdZone zone) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_collection)
          .where('zone', isEqualTo: zone.index)
          .where('status', isEqualTo: LocalAdStatus.active.index)
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('expiresAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => LocalAd.fromSnapshot(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch ads by zone: $e');
    }
  }

  /// Get ads that need admin review
  Future<List<LocalAd>> getAdsForReview() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where(
            'status',
            whereIn: [
              LocalAdStatus.pendingReview.index,
              LocalAdStatus.flagged.index,
            ],
          )
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => LocalAd.fromSnapshot(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch ads for review: $e');
    }
  }

  /// Get ads for admin dashboard with all statuses
  Future<List<LocalAd>> getAllAdsForAdmin() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(50) // Limit for performance
          .get();

      return snapshot.docs.map((doc) => LocalAd.fromSnapshot(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch ads for admin: $e');
    }
  }

  /// Update ad status (admin only)
  Future<void> updateAdStatus({
    required String adId,
    required LocalAdStatus status,
    String? adminId,
    String? rejectionReason,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.index,
        if (adminId != null) 'reviewedBy': adminId,
        if (adminId != null) 'reviewedAt': Timestamp.now(),
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      };

      await _firestore.collection(_collection).doc(adId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update ad status: $e');
    }
  }

  Future<List<LocalAd>> getMyAds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => LocalAd.fromSnapshot(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user ads: $e');
    }
  }

  Future<void> deleteAd(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'status': LocalAdStatus.deleted.index,
      });
    } catch (e) {
      throw Exception('Failed to delete ad: $e');
    }
  }

  Future<void> expireOldAds() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: LocalAdStatus.active.index)
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'status': LocalAdStatus.expired.index});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to expire old ads: $e');
    }
  }

  Future<List<LocalAd>> searchAds(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: LocalAdStatus.active.index)
          .get();

      final query_lower = query.toLowerCase();
      return snapshot.docs
          .map((doc) => LocalAd.fromSnapshot(doc))
          .where(
            (ad) =>
                ad.title.toLowerCase().contains(query_lower) ||
                ad.description.toLowerCase().contains(query_lower),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to search ads: $e');
    }
  }

  Future<List<LocalAd>> getActiveAdsByZone(LocalAdZone zone) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_collection)
          .where('zone', isEqualTo: zone.index)
          .where('status', isEqualTo: LocalAdStatus.active.index)
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => LocalAd.fromSnapshot(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch active ads: $e');
    }
  }

  /// Stream for real-time admin dashboard
  Stream<List<LocalAd>> getAdsForReviewStream() {
    try {
      return _firestore
          .collection(_collection)
          .where(
            'status',
            whereIn: [
              LocalAdStatus.pendingReview.index,
              LocalAdStatus.flagged.index,
            ],
          )
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) => LocalAd.fromSnapshot(doc)).toList(),
          );
    } catch (e) {
      return Stream.error('Failed to stream ads for review: $e');
    }
  }

  /// Get ad statistics for admin dashboard
  Future<Map<String, int>> getAdStatistics() async {
    try {
      final allAds = await _firestore.collection(_collection).get();
      final stats = <String, int>{};

      for (final status in LocalAdStatus.values) {
        stats[status.displayName] = 0;
      }

      for (final doc in allAds.docs) {
        final data = doc.data();
        final statusIndex =
            data['status'] as int? ?? 3; // Default to pendingReview
        final status = LocalAdStatusExtension.fromIndex(statusIndex);
        stats[status.displayName] = (stats[status.displayName] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get ad statistics: $e');
    }
  }

  Future<bool> _verifyPurchase({
    required LocalAd ad,
    required String verificationData,
  }) async {
    final normalizedData = verificationData.trim();
    if (normalizedData.isEmpty) {
      throw Exception('Missing purchase verification payload');
    }

    final productId = ad.subscriptionProductId?.trim() ?? '';
    if (productId.isEmpty) {
      throw Exception('Missing product ID for purchase verification');
    }

    if (Platform.isIOS) {
      final userId = _auth.currentUser?.uid ?? ad.userId;
      if (userId.isEmpty) {
        throw Exception('Missing user ID for iOS purchase verification');
      }

      return PurchaseVerificationService.verifyAppStorePurchase(
        receiptData: normalizedData,
        productId: productId,
        userId: userId,
      );
    }

    if (Platform.isAndroid) {
      return PurchaseVerificationService.verifyGooglePlayPurchase(
        packageName: 'com.wordnerd.artbeat',
        productId: productId,
        purchaseToken: normalizedData,
      );
    }

    throw Exception('Unsupported platform for ad purchase verification');
  }
}
