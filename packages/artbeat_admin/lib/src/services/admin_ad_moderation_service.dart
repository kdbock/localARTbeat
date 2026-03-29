import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';

import '../models/admin_ad_report_model.dart';
import '../models/admin_local_ad_purchase_recovery.dart';
import '../models/admin_local_ad.dart';

class AdminAdModerationService {
  AdminAdModerationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _adsCollection = 'localAds';
  static const String _reportsCollection = 'ad_reports';
  static const String _recoveriesCollection = 'localAdPurchaseRecoveries';

  String get currentAdminId => _auth.currentUser?.uid ?? 'system';

  Future<List<AdminLocalAd>> getAdsForReview() async {
    try {
      final snapshot = await _firestore
          .collection(_adsCollection)
          .where(
            'status',
            whereIn: [
              AdminLocalAdStatus.pendingReview.firestoreIndex,
              AdminLocalAdStatus.flagged.firestoreIndex,
            ],
          )
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AdminLocalAd.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch ads for review: $e');
    }
  }

  Future<Map<String, int>> getAdStatistics() async {
    try {
      final allAds = await _firestore.collection(_adsCollection).get();
      final stats = <String, int>{};

      for (final status in AdminLocalAdStatus.values) {
        stats[status.displayName] = 0;
      }

      for (final doc in allAds.docs) {
        final data = doc.data();
        final status = AdminLocalAdStatusExtension.fromIndex(
          data['status'] as int? ??
              AdminLocalAdStatus.pendingReview.firestoreIndex,
        );
        stats[status.displayName] = (stats[status.displayName] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get ad statistics: $e');
    }
  }

  Future<List<AdminLocalAd>> getAdsNeedingPaymentFollowUp() async {
    try {
      final snapshot = await _firestore
          .collection(_adsCollection)
          .where('purchaseFollowUpStatus', isEqualTo: 'pending_refund_review')
          .orderBy('reviewedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AdminLocalAd.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch ads needing payment follow-up: $e');
    }
  }

  Future<List<AdminLocalAdPurchaseRecovery>> getPurchaseRecoveries() async {
    try {
      final snapshot = await _firestore
          .collection(_recoveriesCollection)
          .where('status', isEqualTo: 'pending_manual_recovery')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AdminLocalAdPurchaseRecovery.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch purchase recoveries: $e');
    }
  }

  Stream<List<AdminAdReportModel>> getPendingReports() {
    try {
      return _firestore
          .collection(_reportsCollection)
          .where('status', isEqualTo: AdminAdReportStatus.pending.value)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AdminAdReportModel.fromFirestore(doc))
                .toList(),
          );
    } catch (e) {
      AppLogger.error('Failed to get pending ad reports: $e');
      return Stream.value([]);
    }
  }

  Future<void> reviewReport({
    required String reportId,
    required AdminAdReportStatus newStatus,
    String? adminId,
    String? adminNotes,
  }) async {
    try {
      await _firestore.collection(_reportsCollection).doc(reportId).update({
        'status': newStatus.value,
        'reviewedBy': adminId ?? currentAdminId,
        'reviewedAt': Timestamp.now(),
        if (adminNotes != null) 'adminNotes': adminNotes,
      });
    } catch (e) {
      AppLogger.error('Failed to review ad report: $e');
      rethrow;
    }
  }

  Future<void> approveAd({
    required String adId,
    String? adminId,
    String? adminNotes,
  }) async {
    try {
      await _firestore.collection(_adsCollection).doc(adId).update({
        'status': AdminLocalAdStatus.active.firestoreIndex,
        'reviewedBy': adminId ?? currentAdminId,
        'reviewedAt': Timestamp.now(),
        if (adminNotes != null) 'adminNotes': adminNotes,
        'rejectionReason': null,
        'purchaseFollowUpStatus': 'active_subscription',
        'purchaseFollowUpNotes': FieldValue.delete(),
      });
    } catch (e) {
      AppLogger.error('Failed to approve ad: $e');
      rethrow;
    }
  }

  Future<void> rejectAd({
    required String adId,
    String? adminId,
    required String reason,
  }) async {
    try {
      await _firestore.collection(_adsCollection).doc(adId).update({
        'status': AdminLocalAdStatus.rejected.firestoreIndex,
        'reviewedBy': adminId ?? currentAdminId,
        'reviewedAt': Timestamp.now(),
        'rejectionReason': reason,
        'purchaseFollowUpStatus': 'pending_refund_review',
        'purchaseFollowUpNotes':
            'Rejected after payment. Review Apple/Google subscription cancellation or refund handling.',
      });
    } catch (e) {
      AppLogger.error('Failed to reject ad: $e');
      rethrow;
    }
  }

  Future<void> markPurchaseRecoveryReviewed({
    required String recoveryId,
    String? adminId,
    required String resolutionNotes,
  }) async {
    try {
      await _firestore
          .collection(_recoveriesCollection)
          .doc(recoveryId)
          .update({
        'status': 'reviewed_manual_follow_up',
        'reviewedBy': adminId ?? currentAdminId,
        'reviewedAt': Timestamp.now(),
        'resolutionNotes': resolutionNotes,
      });
    } catch (e) {
      AppLogger.error('Failed to mark ad purchase recovery reviewed: $e');
      rethrow;
    }
  }

  Future<void> updateAdPurchaseFollowUp({
    required String adId,
    required String status,
    String? adminId,
    String? notes,
    bool? autoRenewing,
  }) async {
    try {
      await _firestore.collection(_adsCollection).doc(adId).update({
        'purchaseFollowUpStatus': status,
        'purchaseFollowUpNotes': notes ?? FieldValue.delete(),
        'reviewedBy': adminId ?? currentAdminId,
        'reviewedAt': Timestamp.now(),
        if (autoRenewing != null) 'autoRenewing': autoRenewing,
      });
    } catch (e) {
      AppLogger.error('Failed to update ad purchase follow-up: $e');
      rethrow;
    }
  }
}
