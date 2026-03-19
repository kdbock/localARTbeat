import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ArtWalkCaptureReadService {
  ArtWalkCaptureReadService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference get _capturesRef => _firestore.collection('captures');
  CollectionReference get _publicArtRef => _firestore.collection('publicArt');

  Future<List<CaptureModel>> getCapturesForUser(String? userId) async {
    if (userId == null) return [];

    try {
      final querySnapshot = await _capturesRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
            try {
              return CaptureModel.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              });
            } catch (_) {
              return null;
            }
          })
          .whereType<CaptureModel>()
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching user captures for art walk: $e');
      return [];
    }
  }

  Future<List<CaptureModel>> getAllCaptures({int limit = 100}) async {
    return getPublicCaptures(limit: limit);
  }

  Future<List<CaptureModel>> getAllCapturesFresh({int limit = 500}) async {
    try {
      final querySnapshot = await _capturesRef
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) {
            try {
              return CaptureModel.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              });
            } catch (_) {
              return null;
            }
          })
          .whereType<CaptureModel>()
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Art walk fresh capture query failed with orderBy, trying fallback: $e',
      );
      try {
        final fallbackQuery = await _capturesRef.limit(limit).get();
        final captures = fallbackQuery.docs
            .map((doc) {
              try {
                return CaptureModel.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                });
              } catch (_) {
                return null;
              }
            })
            .whereType<CaptureModel>()
            .toList();
        captures.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return captures;
      } catch (fallbackError) {
        AppLogger.error(
          'Error fetching fresh art walk captures fallback: $fallbackError',
        );
        return [];
      }
    }
  }

  Future<List<CaptureModel>> getPublicCaptures({int limit = 50}) async {
    final results = <CaptureModel>[];
    final seenIds = <String>{};

    try {
      final publicArtSnapshot = await _publicArtRef
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      for (final doc in publicArtSnapshot.docs) {
        try {
          final capture = CaptureModel.fromJson({
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          });
          results.add(capture);
          seenIds.add(capture.id);
        } catch (_) {}
      }
    } catch (e) {
      AppLogger.warning('Error fetching publicArt captures for art walk: $e');
      try {
        final fallbackSnapshot = await _publicArtRef.limit(limit).get();
        for (final doc in fallbackSnapshot.docs) {
          if (seenIds.contains(doc.id)) continue;
          try {
            final capture = CaptureModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            });
            results.add(capture);
            seenIds.add(capture.id);
          } catch (_) {}
        }
      } catch (_) {}
    }

    try {
      final capturesSnapshot = await _capturesRef
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      for (final doc in capturesSnapshot.docs) {
        if (seenIds.contains(doc.id)) continue;
        try {
          final capture = CaptureModel.fromJson({
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          });
          results.add(capture);
          seenIds.add(capture.id);
        } catch (_) {}
      }
    } catch (e) {
      AppLogger.warning('Error fetching public captures for art walk: $e');
      try {
        final fallbackSnapshot = await _capturesRef
            .where('isPublic', isEqualTo: true)
            .limit(limit)
            .get();
        for (final doc in fallbackSnapshot.docs) {
          if (seenIds.contains(doc.id)) continue;
          try {
            final capture = CaptureModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            });
            results.add(capture);
            seenIds.add(capture.id);
          } catch (_) {}
        }
      } catch (_) {}
    }

    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results.length > limit ? results.sublist(0, limit) : results;
  }
}
