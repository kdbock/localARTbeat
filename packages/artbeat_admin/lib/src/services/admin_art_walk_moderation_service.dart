import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

import '../models/admin_art_walk_model.dart';

class AdminArtWalkModerationService {
  AdminArtWalkModerationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference get _artWalksCollection => _firestore.collection('artWalks');

  Future<List<AdminArtWalkModel>> getAllArtWalks({int limit = 100}) async {
    try {
      final snapshot = await _artWalksCollection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(AdminArtWalkModel.fromFirestore).toList();
    } catch (e) {
      AppLogger.error('Error getting all art walks: $e');
      return [];
    }
  }

  Future<List<AdminArtWalkModel>> getReportedArtWalks({int limit = 100}) async {
    try {
      try {
        final snapshot = await _artWalksCollection
            .where('reportCount', isGreaterThan: 0)
            .orderBy('reportCount', descending: true)
            .limit(limit)
            .get();

        return snapshot.docs.map(AdminArtWalkModel.fromFirestore).toList();
      } catch (e) {
        final snapshot = await _artWalksCollection
            .where('reportCount', isGreaterThan: 0)
            .limit(limit)
            .get();

        final walks = snapshot.docs.map(AdminArtWalkModel.fromFirestore).toList();
        walks.sort((a, b) => b.reportCount.compareTo(a.reportCount));
        return walks;
      }
    } catch (e) {
      AppLogger.error('Error getting reported art walks: $e');
      return [];
    }
  }

  Future<void> clearArtWalkReports(String walkId) async {
    await _artWalksCollection.doc(walkId).update({
      'reportCount': 0,
      'isFlagged': false,
    });
  }

  Future<void> adminDeleteArtWalk(String walkId) async {
    await _artWalksCollection.doc(walkId).delete();
  }
}
