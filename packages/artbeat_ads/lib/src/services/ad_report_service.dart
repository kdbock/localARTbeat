import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/ad_report_model.dart';
import '../models/local_ad.dart';
import '../models/local_ad_status.dart';

/// Service for handling advertisement reporting and moderation
class AdReportService extends ChangeNotifier {
  AdReportService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _reportsCollection = 'ad_reports';
  static const String _adsCollection = 'localAds';
  static const int _flagThreshold = 3;

  /// Submit a report for an advertisement
  Future<bool> reportAd({
    required String adId,
    required String reason,
    String? additionalDetails,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        AppLogger.error('User not authenticated for ad reporting');
        throw Exception('You must be logged in to report ads');
      }

      AppLogger.info(
        '🚩 Submitting report for ad: $adId by user: ${currentUser.uid}',
      );

      // Check if user has already reported this ad
      final existingReport = await _firestore
          .collection(_reportsCollection)
          .where('adId', isEqualTo: adId)
          .where('reportedBy', isEqualTo: currentUser.uid)
          .get();

      if (existingReport.docs.isNotEmpty) {
        AppLogger.warning('User ${currentUser.uid} already reported ad $adId');
        throw Exception('You have already reported this ad');
      }

      // Create the report
      final report = AdReportModel(
        id: '', // Will be set by Firestore
        adId: adId,
        reportedBy: currentUser.uid,
        reason: reason,
        additionalDetails: additionalDetails,
        createdAt: DateTime.now(),
      );

      // Add report to Firestore
      final docRef = await _firestore
          .collection(_reportsCollection)
          .add(report.toMap());

      AppLogger.info('🚩 Report created with ID: ${docRef.id}');

      // Check if ad should be flagged due to multiple reports
      await _checkAndFlagAd(adId);

      return true;
    } catch (e) {
      AppLogger.error('Failed to submit ad report: $e');
      rethrow;
    }
  }

  /// Check if an ad should be flagged based on report count
  Future<void> _checkAndFlagAd(String adId) async {
    try {
      // Count total reports for this ad
      final reportsQuery = await _firestore
          .collection(_reportsCollection)
          .where('adId', isEqualTo: adId)
          .get();

      final reportCount = reportsQuery.docs.length;

      AppLogger.info('🚩 Ad $adId has $reportCount reports');

      if (reportCount >= _flagThreshold) {
        // Flag the ad and remove from circulation
        await _firestore.collection(_adsCollection).doc(adId).update({
          'status': LocalAdStatus.flagged.index,
          'reportCount': reportCount,
          'flaggedAt': Timestamp.now(),
        });

        AppLogger.info('🚩 Ad $adId flagged due to $reportCount reports');

        // Log admin activity for flagged ad
        await _logAdminActivity(
          'system',
          'Ad Auto-Flagged',
          'Ad $adId automatically flagged due to $reportCount reports',
          {'adId': adId, 'reportCount': reportCount},
        );
      } else {
        // Just update the report count
        await _firestore.collection(_adsCollection).doc(adId).update({
          'reportCount': reportCount,
        });
      }
    } catch (e) {
      AppLogger.error('Failed to check and flag ad: $e');
      // Don't rethrow - reporting should still succeed even if flagging fails
    }
  }

  /// Get all reports for a specific ad (admin only)
  Stream<List<AdReportModel>> getReportsForAd(String adId) {
    try {
      return _firestore
          .collection(_reportsCollection)
          .where('adId', isEqualTo: adId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AdReportModel.fromFirestore(doc))
                .toList(),
          );
    } catch (e) {
      AppLogger.error('Failed to get reports for ad: $e');
      return Stream.value([]);
    }
  }

  /// Get all pending reports (admin only)
  Stream<List<AdReportModel>> getPendingReports() {
    try {
      return _firestore
          .collection(_reportsCollection)
          .where('status', isEqualTo: AdReportStatus.pending.value)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AdReportModel.fromFirestore(doc))
                .toList(),
          );
    } catch (e) {
      AppLogger.error('Failed to get pending reports: $e');
      return Stream.value([]);
    }
  }

  /// Review a report (admin only)
  Future<void> reviewReport({
    required String reportId,
    required AdReportStatus newStatus,
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

      AppLogger.info('🏛️ Report $reportId reviewed by admin $adminId');

      // Log admin activity
      await _logAdminActivity(
        adminId,
        'Report Reviewed',
        'Admin reviewed report $reportId with status: ${newStatus.displayName}',
        {
          'reportId': reportId,
          'status': newStatus.value,
          'adminNotes': adminNotes,
        },
      );
    } catch (e) {
      AppLogger.error('Failed to review report: $e');
      rethrow;
    }
  }

  /// Approve an ad after review (admin only)
  Future<void> approveAd({
    required String adId,
    required String adminId,
    String? adminNotes,
  }) async {
    try {
      await _firestore.collection(_adsCollection).doc(adId).update({
        'status': LocalAdStatus.active.index,
        'reviewedBy': adminId,
        'reviewedAt': Timestamp.now(),
        if (adminNotes != null)
          'rejectionReason': null, // Clear any previous rejection
      });

      AppLogger.info('✅ Ad $adId approved by admin $adminId');

      // Log admin activity
      await _logAdminActivity(
        adminId,
        'Ad Approved',
        'Admin approved ad $adId',
        {'adId': adId, 'adminNotes': adminNotes},
      );
    } catch (e) {
      AppLogger.error('Failed to approve ad: $e');
      rethrow;
    }
  }

  /// Reject an ad (admin only)
  Future<void> rejectAd({
    required String adId,
    required String adminId,
    required String reason,
    String? adminNotes,
  }) async {
    try {
      await _firestore.collection(_adsCollection).doc(adId).update({
        'status': LocalAdStatus.rejected.index,
        'reviewedBy': adminId,
        'reviewedAt': Timestamp.now(),
        'rejectionReason': reason,
      });

      AppLogger.info('❌ Ad $adId rejected by admin $adminId');

      // Log admin activity
      await _logAdminActivity(
        adminId,
        'Ad Rejected',
        'Admin rejected ad $adId: $reason',
        {'adId': adId, 'rejectionReason': reason, 'adminNotes': adminNotes},
      );
    } catch (e) {
      AppLogger.error('Failed to reject ad: $e');
      rethrow;
    }
  }

  /// Delete an ad (admin only)
  Future<void> deleteAd({
    required String adId,
    required String adminId,
    String? reason,
  }) async {
    try {
      await _firestore.collection(_adsCollection).doc(adId).update({
        'status': LocalAdStatus.deleted.index,
        'reviewedBy': adminId,
        'reviewedAt': Timestamp.now(),
        if (reason != null) 'rejectionReason': reason,
      });

      AppLogger.info('🗑️ Ad $adId deleted by admin $adminId');

      // Log admin activity
      await _logAdminActivity(
        adminId,
        'Ad Deleted',
        'Admin deleted ad $adId${reason != null ? ": $reason" : ""}',
        {'adId': adId, 'reason': reason},
      );
    } catch (e) {
      AppLogger.error('Failed to delete ad: $e');
      rethrow;
    }
  }

  /// Get ads that need review (admin only)
  Stream<List<LocalAd>> getAdsNeedingReview() {
    try {
      return _firestore
          .collection(_adsCollection)
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
            (snapshot) => snapshot.docs
                .map((doc) => LocalAd.fromMap(doc.data(), doc.id))
                .toList(),
          );
    } catch (e) {
      AppLogger.error('Failed to get ads needing review: $e');
      return Stream.value([]);
    }
  }

  /// Get report statistics (admin only)
  Future<Map<String, dynamic>> getReportStatistics() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      // Get report counts
      final allReports = await _firestore.collection(_reportsCollection).get();
      final todayReports = await _firestore
          .collection(_reportsCollection)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
          )
          .get();
      final weekReports = await _firestore
          .collection(_reportsCollection)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart),
          )
          .get();
      final monthReports = await _firestore
          .collection(_reportsCollection)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
          )
          .get();

      // Get pending reports
      final pendingReports = await _firestore
          .collection(_reportsCollection)
          .where('status', isEqualTo: AdReportStatus.pending.value)
          .get();

      // Get flagged ads
      final flaggedAds = await _firestore
          .collection(_adsCollection)
          .where('status', isEqualTo: LocalAdStatus.flagged.index)
          .get();

      return {
        'totalReports': allReports.docs.length,
        'todayReports': todayReports.docs.length,
        'weekReports': weekReports.docs.length,
        'monthReports': monthReports.docs.length,
        'pendingReports': pendingReports.docs.length,
        'flaggedAds': flaggedAds.docs.length,
      };
    } catch (e) {
      AppLogger.error('Failed to get report statistics: $e');
      return {};
    }
  }

  /// Log admin activity
  Future<void> _logAdminActivity(
    String adminId,
    String action,
    String description,
    Map<String, dynamic> metadata,
  ) async {
    try {
      await _firestore.collection('admin_activities').add({
        'adminId': adminId,
        'action': action,
        'description': description,
        'metadata': metadata,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      AppLogger.error('Failed to log admin activity: $e');
      // Don't rethrow - this is just logging
    }
  }
}
