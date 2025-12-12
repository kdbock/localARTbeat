import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' show ChapterModel, AppLogger;

class ChapterService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<ChapterModel> createChapter({
    required String artworkId,
    required int chapterNumber,
    required String title,
    required String description,
    required String content,
    required int estimatedReadingTime,
    required int wordCount,
    required DateTime releaseDate,
    int? episodeNumber,
    bool isPaid = false,
    double? price,
    List<String> contentWarnings = const [],
    List<String> tags = const [],
  }) async {
    try {
      final chapterId = _firestore.collection('artwork').doc().id;
      final now = DateTime.now();

      final chapter = ChapterModel(
        id: chapterId,
        artworkId: artworkId,
        chapterNumber: chapterNumber,
        episodeNumber: episodeNumber,
        title: title,
        description: description,
        content: content,
        estimatedReadingTime: estimatedReadingTime,
        wordCount: wordCount,
        releaseDate: releaseDate,
        isReleased: releaseDate.isBefore(now),
        isPaid: isPaid,
        price: price,
        createdAt: now,
        updatedAt: now,
        contentWarnings: contentWarnings.isNotEmpty ? contentWarnings : null,
        tags: tags.isNotEmpty ? tags : null,
      );

      await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('chapters')
          .doc(chapterId)
          .set(chapter.toFirestore());

      await _updateArtworkChapterCount(artworkId);

      AppLogger.info('Chapter created: $chapterId for artwork: $artworkId');
      return chapter;
    } catch (e) {
      AppLogger.error('Error creating chapter: $e');
      throw Exception('Failed to create chapter: $e');
    }
  }

  Future<ChapterModel?> getChapterById(
      String artworkId, String chapterId) async {
    try {
      final doc = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('chapters')
          .doc(chapterId)
          .get();

      if (!doc.exists) return null;
      return ChapterModel.fromFirestore(doc);
    } catch (e) {
      AppLogger.error('Error fetching chapter: $e');
      return null;
    }
  }

  Future<List<ChapterModel>> getChaptersForArtwork(String artworkId) async {
    try {
      final snapshot = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('chapters')
          .orderBy('chapterNumber', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ChapterModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching chapters: $e');
      return [];
    }
  }

  Future<List<ChapterModel>> getReleasedChapters(String artworkId) async {
    try {
      final snapshot = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('chapters')
          .where('isReleased', isEqualTo: true)
          .orderBy('chapterNumber', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ChapterModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching released chapters: $e');
      return [];
    }
  }

  Future<void> updateChapter(String artworkId, ChapterModel chapter) async {
    try {
      await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('chapters')
          .doc(chapter.id)
          .update(chapter.toFirestore());

      AppLogger.info('Chapter updated: ${chapter.id}');
    } catch (e) {
      AppLogger.error('Error updating chapter: $e');
      throw Exception('Failed to update chapter: $e');
    }
  }

  Future<void> publishChapter(String artworkId, String chapterId) async {
    try {
      final chapter = await getChapterById(artworkId, chapterId);
      if (chapter == null) throw Exception('Chapter not found');

      final updatedChapter = chapter.copyWith(
        isReleased: true,
        updatedAt: DateTime.now(),
      );

      await updateChapter(artworkId, updatedChapter);
      await _updateArtworkReleasedChapterCount(artworkId);
    } catch (e) {
      AppLogger.error('Error publishing chapter: $e');
      throw Exception('Failed to publish chapter: $e');
    }
  }

  Future<void> deleteChapter(String artworkId, String chapterId) async {
    try {
      await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('chapters')
          .doc(chapterId)
          .delete();

      await _updateArtworkChapterCount(artworkId);
      AppLogger.info('Chapter deleted: $chapterId');
    } catch (e) {
      AppLogger.error('Error deleting chapter: $e');
      throw Exception('Failed to delete chapter: $e');
    }
  }

  Future<void> _updateArtworkChapterCount(String artworkId) async {
    try {
      final chapters = await getChaptersForArtwork(artworkId);
      final releasedChapters = chapters.where((c) => c.isReleased).length;

      await _firestore.collection('artwork').doc(artworkId).update({
        'totalChapters': chapters.length,
        'releasedChapters': releasedChapters,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      AppLogger.error('Error updating artwork chapter count: $e');
    }
  }

  Future<void> _updateArtworkReleasedChapterCount(String artworkId) async {
    try {
      final releasedChapters = await getReleasedChapters(artworkId);
      await _firestore.collection('artwork').doc(artworkId).update({
        'releasedChapters': releasedChapters.length,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      AppLogger.error('Error updating released chapter count: $e');
    }
  }

  Future<int> getTotalWordCount(String artworkId) async {
    try {
      final chapters = await getChaptersForArtwork(artworkId);
      return chapters.fold<int>(0, (sum, ch) => sum + ch.wordCount);
    } catch (e) {
      AppLogger.error('Error calculating total word count: $e');
      return 0;
    }
  }

  Future<int> getTotalReadingTime(String artworkId) async {
    try {
      final chapters = await getChaptersForArtwork(artworkId);
      return chapters.fold<int>(0, (sum, ch) => sum + ch.estimatedReadingTime);
    } catch (e) {
      AppLogger.error('Error calculating total reading time: $e');
      return 0;
    }
  }
}
