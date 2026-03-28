import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show AppLogger, ChapterModel, ChapterModerationStatus;

import '../models/admin_artwork_model.dart';

class AdminArtworkService {
  AdminArtworkService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference get _artworkCollection =>
      _firestore.collection('artwork');

  Future<List<AdminArtworkModel>> getArtworksForModeration({
    required String filter,
    int limit = 50,
  }) async {
    Query query = _artworkCollection;

    switch (filter) {
      case 'pending':
        query = query.where('moderationStatus', isEqualTo: 'pending');
        break;
      case 'flagged':
        query = query.where('flagged', isEqualTo: true);
        break;
      case 'approved':
        query = query.where('moderationStatus', isEqualTo: 'approved');
        break;
      case 'rejected':
        query = query.where('moderationStatus', isEqualTo: 'rejected');
        break;
      case 'all':
        break;
    }

    final snapshot =
        await query.orderBy('createdAt', descending: true).limit(limit).get();
    return snapshot.docs.map(AdminArtworkModel.fromFirestore).toList();
  }

  Future<void> updateArtworkModeration({
    required String artworkId,
    required AdminArtworkModerationStatus status,
    String? notes,
  }) async {
    final updateData = <String, dynamic>{
      'moderationStatus': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (notes != null && notes.isNotEmpty) {
      updateData['moderationNotes'] = notes;
    }

    if (status == AdminArtworkModerationStatus.rejected) {
      updateData['flagged'] = true;
      updateData['flaggedAt'] = FieldValue.serverTimestamp();
    }

    await _artworkCollection.doc(artworkId).update(updateData);
  }

  Future<List<AdminArtworkModel>> getFeaturedArtwork({
    int limit = 10,
    String? chapterId,
  }) async {
    Query query = _artworkCollection
        .where('isFeatured', isEqualTo: true)
        .where('isPublic', isEqualTo: true);

    if (chapterId != null) {
      query = query.where('chapterId', isEqualTo: chapterId);
    } else {
      query = query.where('chapterId', isNull: true);
    }

    final snapshot =
        await query.orderBy('createdAt', descending: true).limit(limit).get();

    return snapshot.docs.map(AdminArtworkModel.fromFirestore).toList();
  }

  Future<void> setArtworkFeatured(String artworkId, bool isFeatured) async {
    await _artworkCollection.doc(artworkId).update({
      'isFeatured': isFeatured,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateArtworkCountsForAdmin(String artworkId) async {
    try {
      final snapshot =
          await _artworkCollection.doc(artworkId).collection('chapters').get();

      final chapters =
          snapshot.docs.map((doc) => ChapterModel.fromFirestore(doc)).toList();

      final totalChapters = chapters.length;
      final releasedApprovedChapters = chapters
          .where(
            (c) =>
                c.isReleased &&
                c.moderationStatus == ChapterModerationStatus.approved,
          )
          .length;

      await _artworkCollection.doc(artworkId).update({
        'totalChapters': totalChapters,
        'releasedChapters': releasedApprovedChapters,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      AppLogger.error('Error updating artwork chapter count: $e');
    }
  }
}
