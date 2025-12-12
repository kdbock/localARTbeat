import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show ReadingAnalyticsModel, Bookmark, AppLogger;
import 'dart:io';

class ReadingAnalyticsService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<ReadingAnalyticsModel> startReadingSession({
    required String artworkId,
    String? chapterId,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final sessionId = _firestore.collection('reading_analytics').doc().id;
      final now = DateTime.now();

      final analytics = ReadingAnalyticsModel(
        id: sessionId,
        userId: userId,
        artworkId: artworkId,
        chapterId: chapterId,
        startedAt: now,
        timeSpentSeconds: 0,
        lastScrollPosition: 0.0,
        completionPercentage: 0.0,
        device: Platform.isAndroid
            ? 'android'
            : Platform.isIOS
                ? 'ios'
                : 'web',
      );

      await _firestore
          .collection('reading_analytics')
          .doc(sessionId)
          .set(analytics.toFirestore());

      AppLogger.info('Reading session started: $sessionId');
      return analytics;
    } catch (e) {
      AppLogger.error('Error starting reading session: $e');
      throw Exception('Failed to start reading session: $e');
    }
  }

  Future<void> updateReadingProgress({
    required String sessionId,
    required double scrollPosition,
    required double completionPercentage,
    required int elapsedSeconds,
  }) async {
    try {
      await _firestore.collection('reading_analytics').doc(sessionId).update({
        'lastScrollPosition': scrollPosition,
        'completionPercentage': completionPercentage,
        'timeSpentSeconds': elapsedSeconds,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      AppLogger.error('Error updating reading progress: $e');
    }
  }

  Future<void> completeReadingSession({
    required String sessionId,
  }) async {
    try {
      await _firestore.collection('reading_analytics').doc(sessionId).update({
        'completedAt': Timestamp.now(),
        'isCompleted': true,
        'updatedAt': Timestamp.now(),
      });

      AppLogger.info('Reading session completed: $sessionId');
    } catch (e) {
      AppLogger.error('Error completing reading session: $e');
      throw Exception('Failed to complete reading session: $e');
    }
  }

  Future<void> addBookmark({
    required String sessionId,
    required String chapterId,
    required double scrollPosition,
    String? note,
  }) async {
    try {
      final bookmark = Bookmark(
        chapterId: chapterId,
        scrollPosition: scrollPosition,
        savedAt: DateTime.now(),
        note: note,
      );

      await _firestore.collection('reading_analytics').doc(sessionId).update({
        'bookmarks': FieldValue.arrayUnion([bookmark.toJson()]),
      });

      AppLogger.info('Bookmark added to session: $sessionId');
    } catch (e) {
      AppLogger.error('Error adding bookmark: $e');
    }
  }

  Future<void> removeBookmark({
    required String sessionId,
    required String chapterId,
  }) async {
    try {
      final doc =
          await _firestore.collection('reading_analytics').doc(sessionId).get();

      if (!doc.exists) return;

      final data = doc.data() ?? {};
      final bookmarks = (data['bookmarks'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .where((b) => b['chapterId'] != chapterId)
          .toList();

      await _firestore.collection('reading_analytics').doc(sessionId).update({
        'bookmarks':
            bookmarks.map((b) => Bookmark.fromJson(b).toJson()).toList(),
      });

      AppLogger.info('Bookmark removed from session: $sessionId');
    } catch (e) {
      AppLogger.error('Error removing bookmark: $e');
    }
  }

  Future<ReadingAnalyticsModel?> getReadingSession(String sessionId) async {
    try {
      final doc =
          await _firestore.collection('reading_analytics').doc(sessionId).get();

      if (!doc.exists) return null;
      return ReadingAnalyticsModel.fromFirestore(doc);
    } catch (e) {
      AppLogger.error('Error fetching reading session: $e');
      return null;
    }
  }

  Future<List<ReadingAnalyticsModel>> getUserReadingHistory({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('reading_analytics')
          .where('userId', isEqualTo: userId)
          .orderBy('startedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ReadingAnalyticsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching user reading history: $e');
      return [];
    }
  }

  Future<List<ReadingAnalyticsModel>> getArtworkReadingStats(
      String artworkId) async {
    try {
      final snapshot = await _firestore
          .collection('reading_analytics')
          .where('artworkId', isEqualTo: artworkId)
          .orderBy('startedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReadingAnalyticsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching artwork reading stats: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getArtworkEngagementMetrics(
      String artworkId) async {
    try {
      final stats = await getArtworkReadingStats(artworkId);

      final totalReaders = stats.map((s) => s.userId).toSet().length;
      final completedReads = stats.where((s) => s.isCompleted).length;
      final totalTimeSpent =
          stats.fold<int>(0, (sum, s) => sum + s.timeSpentSeconds);
      final averageCompletion = stats.isNotEmpty
          ? stats.fold<double>(0.0, (sum, s) => sum + s.completionPercentage) /
              stats.length
          : 0.0;

      return {
        'totalReaders': totalReaders,
        'completedReads': completedReads,
        'totalTimeSpentSeconds': totalTimeSpent,
        'averageCompletionPercentage': averageCompletion.toStringAsFixed(2),
        'completionRate':
            ((completedReads / stats.length) * 100).toStringAsFixed(2),
      };
    } catch (e) {
      AppLogger.error('Error calculating engagement metrics: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getChapterReadingStats(
    String artworkId,
    String chapterId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('reading_analytics')
          .where('artworkId', isEqualTo: artworkId)
          .where('chapterId', isEqualTo: chapterId)
          .get();

      final stats = snapshot.docs
          .map((doc) => ReadingAnalyticsModel.fromFirestore(doc))
          .toList();

      final totalReads = stats.length;
      final completedReads = stats.where((s) => s.isCompleted).length;
      final totalTimeSpent =
          stats.fold<int>(0, (sum, s) => sum + s.timeSpentSeconds);
      final averageCompletion = stats.isNotEmpty
          ? stats.fold<double>(0.0, (sum, s) => sum + s.completionPercentage) /
              stats.length
          : 0.0;

      return {
        'totalReads': totalReads,
        'completedReads': completedReads,
        'averageTimeSpentSeconds':
            (totalTimeSpent / (totalReads > 0 ? totalReads : 1))
                .toStringAsFixed(0),
        'averageCompletionPercentage': averageCompletion.toStringAsFixed(2),
      };
    } catch (e) {
      AppLogger.error('Error fetching chapter reading stats: $e');
      return {};
    }
  }

  Future<void> deleteReadingSession(String sessionId) async {
    try {
      await _firestore.collection('reading_analytics').doc(sessionId).delete();
      AppLogger.info('Reading session deleted: $sessionId');
    } catch (e) {
      AppLogger.error('Error deleting reading session: $e');
    }
  }

  Future<int> getUserTotalReadingTimeSeconds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reading_analytics')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.fold<int>(
        0,
        (sum, doc) => sum + (doc.data()['timeSpentSeconds'] as int? ?? 0),
      );
    } catch (e) {
      AppLogger.error('Error calculating total reading time: $e');
      return 0;
    }
  }
}
