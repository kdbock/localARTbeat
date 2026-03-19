import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

class AdminCaptureModerationService {
  AdminCaptureModerationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference get _capturesRef => _firestore.collection('captures');

  Future<List<CaptureModel>> getPendingCaptures({int limit = 50}) async {
    try {
      final querySnapshot = await _capturesRef
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: false)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => CaptureModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching pending captures: $e');
      try {
        final fallbackQuery = await _capturesRef
            .where('status', isEqualTo: 'pending')
            .limit(limit)
            .get();

        final captures = fallbackQuery.docs
            .map(
              (doc) => CaptureModel.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }),
            )
            .toList();
        captures.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return captures;
      } catch (fallbackError) {
        AppLogger.error(
          'Fallback pending captures query failed: $fallbackError',
        );
        return [];
      }
    }
  }

  Future<List<CaptureModel>> getCapturesByStatus(
    String status, {
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _capturesRef
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => CaptureModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching captures by status: $e');
      try {
        final fallbackQuery = await _capturesRef
            .where('status', isEqualTo: status)
            .limit(limit)
            .get();

        final captures = fallbackQuery.docs
            .map(
              (doc) => CaptureModel.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }),
            )
            .toList();
        captures.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return captures;
      } catch (fallbackError) {
        AppLogger.error(
          'Fallback status captures query failed: $fallbackError',
        );
        return [];
      }
    }
  }

  Future<List<CaptureModel>> getReportedCaptures({int limit = 50}) async {
    try {
      final querySnapshot = await _capturesRef
          .where('reportCount', isGreaterThan: 0)
          .orderBy('reportCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => CaptureModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching reported captures: $e');
      try {
        final fallbackQuery = await _capturesRef
            .where('reportCount', isGreaterThan: 0)
            .limit(limit)
            .get();

        final captures = fallbackQuery.docs
            .map(
              (doc) => CaptureModel.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }),
            )
            .toList();
        captures.sort((a, b) => b.reportCount.compareTo(a.reportCount));
        return captures;
      } catch (fallbackError) {
        AppLogger.error(
          'Fallback reported captures query failed: $fallbackError',
        );
        return [];
      }
    }
  }

  Future<bool> approveCapture(
    String captureId, {
    String? moderationNotes,
  }) async {
    try {
      await _capturesRef.doc(captureId).update({
        'status': 'approved',
        'moderationNotes': moderationNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      AppLogger.error('Error approving capture: $e');
      return false;
    }
  }

  Future<bool> rejectCapture(
    String captureId, {
    String? moderationNotes,
  }) async {
    try {
      await _capturesRef.doc(captureId).update({
        'status': 'rejected',
        'moderationNotes': moderationNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      AppLogger.error('Error rejecting capture: $e');
      return false;
    }
  }

  Future<bool> adminDeleteCapture(String captureId) async {
    try {
      final captureDoc = await _capturesRef.doc(captureId).get();
      if (!captureDoc.exists) {
        AppLogger.error('Capture $captureId not found');
        return false;
      }

      final data = captureDoc.data() as Map<String, dynamic>?;
      final userId = data?['userId'] as String?;
      await _capturesRef.doc(captureId).delete();

      if (userId != null) {
        await UserService().decrementUserCaptureCount(userId);
      }
      return true;
    } catch (e) {
      AppLogger.error('Error admin deleting capture: $e');
      return false;
    }
  }

  Future<void> backfillGeoFieldForCaptures({int batchSize = 100}) async {
    try {
      AppLogger.info('Starting geo field backfill for captures...');
      final querySnapshot = await _capturesRef
          .where('location', isNull: false)
          .limit(batchSize)
          .get();

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null || data.containsKey('geo')) {
            continue;
          }

          final location = data['location'] as GeoPoint?;
          if (location == null) {
            continue;
          }

          await doc.reference.update({
            'geo': {
              'geohash': _generateGeohash(
                location.latitude,
                location.longitude,
              ),
              'geopoint': location,
            },
          });
        } catch (e) {
          AppLogger.error('Error updating capture ${doc.id}: $e');
        }
      }
    } catch (e) {
      AppLogger.error('Geo field backfill failed: $e');
      rethrow;
    }
  }

  String _generateGeohash(double latitude, double longitude) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    final latRange = [-90.0, 90.0];
    final lonRange = [-180.0, 180.0];
    var hash = '';
    var isEven = true;
    var bit = 0;
    var ch = 0;

    while (hash.length < 9) {
      if (isEven) {
        final mid = (lonRange[0] + lonRange[1]) / 2;
        if (longitude > mid) {
          ch |= (1 << (4 - bit));
          lonRange[0] = mid;
        } else {
          lonRange[1] = mid;
        }
      } else {
        final mid = (latRange[0] + latRange[1]) / 2;
        if (latitude > mid) {
          ch |= (1 << (4 - bit));
          latRange[0] = mid;
        } else {
          latRange[1] = mid;
        }
      }

      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        hash += base32[ch];
        bit = 0;
        ch = 0;
      }
    }

    return hash;
  }
}
