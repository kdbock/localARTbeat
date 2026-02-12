import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show ChapterModel, AppLogger, ChapterModerationStatus;

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
      // Get parent artwork to copy metadata
      final artworkDoc = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .get();
      if (!artworkDoc.exists) throw Exception('Parent artwork not found');
      final artworkData = artworkDoc.data()!;

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
        thumbnailUrl: artworkData['thumbnailUrl'] as String?,
        authorId:
            (artworkData['artistProfileId'] as String?) ??
            (artworkData['userId'] as String?) ??
            '',
        authorName:
            (artworkData['artistName'] as String?) ??
            (artworkData['authorName'] as String?) ??
            'Unknown Author',
        createdAt: now,
        updatedAt: now,
        contentWarnings: contentWarnings.isNotEmpty ? contentWarnings : null,
        tags: tags.isNotEmpty ? tags : null,
        moderationStatus: ChapterModerationStatus.pending,
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
    String artworkId,
    String chapterId,
  ) async {
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

  Future<List<ChapterModel>> getChaptersForArtwork(
    String artworkId, {
    String? currentUserId,
    bool isModerator = false,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('chapters')
          .orderBy('chapterNumber', descending: false)
          .get();

      final chapters = snapshot.docs
          .map((doc) => ChapterModel.fromFirestore(doc))
          .toList();

      // If moderator, return all chapters
      if (isModerator) return chapters;

      // If current user is author, return all chapters
      if (currentUserId != null) {
        final artworkDoc = await _firestore
            .collection('artwork')
            .doc(artworkId)
            .get();
        if (artworkDoc.exists) {
          final authorId =
              (artworkDoc.data()?['artistProfileId'] as String?) ??
              (artworkDoc.data()?['userId'] as String?);
          if (authorId == currentUserId) {
            return chapters;
          }
        }
      }

      // Default: Return only released and approved for public
      return chapters.where((c) {
        return c.isReleased &&
            c.moderationStatus == ChapterModerationStatus.approved;
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching chapters: $e');
      return [];
    }
  }

  Future<List<ChapterModel>> getReleasedChapters(
    String artworkId, {
    String? authorId,
    String? currentUserId,
    bool isModerator = false,
  }) async {
    return getChaptersForArtwork(
      artworkId,
      currentUserId: currentUserId,
      isModerator: isModerator,
    );
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
        moderationStatus: ChapterModerationStatus.pending,
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

  Future<void> updateArtworkCountsForAdmin(String artworkId) async {
    await _updateArtworkChapterCount(artworkId);
  }

  Future<void> _updateArtworkChapterCount(String artworkId) async {
    try {
      final snapshot = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('chapters')
          .get();

      final chapters = snapshot.docs
          .map((doc) => ChapterModel.fromFirestore(doc))
          .toList();

      final totalChapters = chapters.length;
      final releasedApprovedChapters = chapters
          .where(
            (c) =>
                c.isReleased &&
                c.moderationStatus == ChapterModerationStatus.approved,
          )
          .length;

      await _firestore.collection('artwork').doc(artworkId).update({
        'totalChapters': totalChapters,
        'releasedChapters': releasedApprovedChapters,
        'updatedAt': Timestamp.now(),
      });

      AppLogger.info(
        'Updated artwork $artworkId: total=$totalChapters, released=$releasedApprovedChapters',
      );
    } catch (e) {
      AppLogger.error('Error updating artwork chapter count: $e');
    }
  }

  Future<void> _updateArtworkReleasedChapterCount(String artworkId) async {
    try {
      final snapshot = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('chapters')
          .get();

      final chapters = snapshot.docs
          .map((doc) => ChapterModel.fromFirestore(doc))
          .toList();

      final releasedApprovedChapters = chapters
          .where(
            (c) =>
                c.isReleased &&
                c.moderationStatus == ChapterModerationStatus.approved,
          )
          .length;

      await _firestore.collection('artwork').doc(artworkId).update({
        'releasedChapters': releasedApprovedChapters,
        'updatedAt': Timestamp.now(),
      });

      AppLogger.info(
        'Updated artwork $artworkId: released=$releasedApprovedChapters',
      );
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
