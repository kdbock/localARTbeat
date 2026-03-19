import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

import '../models/admin_ad_report_model.dart';
import '../models/admin_local_ad.dart';

class AdminAdModerationService {
  AdminAdModerationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _adsCollection = 'localAds';
  static const String _reportsCollection = 'ad_reports';

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

      return snapshot.docs.map((doc) => AdminLocalAd.fromSnapshot(doc)).toList();
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
          data['status'] as int? ?? AdminLocalAdStatus.pendingReview.firestoreIndex,
        );
        stats[status.displayName] = (stats[status.displayName] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get ad statistics: $e');
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
    required String adminId,
    String? adminNotes,
  }) async {
    try {
      await _firestore.collection(_reportsCollection).doc(reportId).update({
        'status': newStatus.value,
        'reviewedBy': adminId,
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
    required String adminId,
    String? adminNotes,
  }) async {
    try {
      await _firestore.collection(_adsCollection).doc(adId).update({
        'status': AdminLocalAdStatus.active.firestoreIndex,
        'reviewedBy': adminId,
        'reviewedAt': Timestamp.now(),
        if (adminNotes != null) 'adminNotes': adminNotes,
        'rejectionReason': null,
      });
    } catch (e) {
      AppLogger.error('Failed to approve ad: $e');
      rethrow;
    }
  }

  Future<void> rejectAd({
    required String adId,
    required String adminId,
    required String reason,
  }) async {
    try {
      await _firestore.collection(_adsCollection).doc(adId).update({
        'status': AdminLocalAdStatus.rejected.firestoreIndex,
        'reviewedBy': adminId,
        'reviewedAt': Timestamp.now(),
        'rejectionReason': reason,
      });
    } catch (e) {
      AppLogger.error('Failed to reject ad: $e');
      rethrow;
    }
  }
}
