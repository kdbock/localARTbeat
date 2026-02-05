import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';

/// Service for admin management of artwork content
class AdminArtworkManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all artwork with optional filtering
  Future<List<ArtworkModel>> getArtworkList({
    String filterType = 'all',
    String? contentType, // 'visual', 'written', 'audio', 'video', or null for all
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection('artwork');

      // Filter by content type if specified
      if (contentType != null && contentType.isNotEmpty) {
        query = query.where('contentType', isEqualTo: contentType);
      }

      switch (filterType) {
        case 'reported':
          query = query.where('reports', isNotEqualTo: null);
          break;
        case 'flagged':
          query = query.where('moderationStatus', isEqualTo: 'flagged');
          break;
        case 'pending':
          query = query.where('moderationStatus', isEqualTo: 'pending');
          break;
        case 'approved':
          query = query.where('moderationStatus', isEqualTo: 'approved');
          break;
        case 'rejected':
          query = query.where('moderationStatus', isEqualTo: 'rejected');
          break;
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);
      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching artwork: $e');
    }
  }

  /// Get detailed report information for artwork
  Future<Map<String, dynamic>> getArtworkReportDetails(String artworkId) async {
    try {
      final doc = await _firestore.collection('artwork').doc(artworkId).get();
      if (!doc.exists) {
        throw Exception('Artwork not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final reports = data['reports'] as List<dynamic>? ?? [];
      final comments = await _getArtworkComments(artworkId);

      return {
        'artwork': ArtworkModel.fromFirestore(doc),
        'totalReports': reports.length,
        'reports': reports,
        'comments': comments,
        'analyticsData': await _getArtworkAnalytics(artworkId),
      };
    } catch (e) {
      throw Exception('Error fetching report details: $e');
    }
  }

  /// Get all comments for an artwork
  Future<List<CommentModel>> _getArtworkComments(String artworkId) async {
    try {
      final snapshot = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get analytics data for an artwork
  Future<Map<String, dynamic>> _getArtworkAnalytics(String artworkId) async {
    try {
      final doc = await _firestore.collection('artwork').doc(artworkId).get();
      if (!doc.exists) {
        return {};
      }

      final data = doc.data() as Map<String, dynamic>;
      return {
        'viewCount': data['viewCount'] ?? 0,
        'likeCount': data['likeCount'] ?? 0,
        'commentCount': data['commentCount'] ?? 0,
        'shareCount': data['shareCount'] ?? 0,
        'reportCount': (data['reports'] as List<dynamic>?)?.length ?? 0,
      };
    } catch (e) {
      return {};
    }
  }

  /// Update artwork moderation status
  Future<void> updateArtworkStatus(
    String artworkId,
    String newStatus, {
    String? reason,
  }) async {
    try {
      await _firestore.collection('artwork').doc(artworkId).update({
        'moderationStatus': newStatus,
        'moderationReason': reason,
        'moderatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating artwork status: $e');
    }
  }

  /// Delete artwork
  Future<void> deleteArtwork(String artworkId, {String? reason}) async {
    try {
      await _firestore.collection('artwork').doc(artworkId).update({
        'isDeleted': true,
        'deletionReason': reason,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error deleting artwork: $e');
    }
  }

  /// Update artwork content (title, description, tags, etc.)
  Future<void> updateArtworkContent(
    String artworkId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('artwork').doc(artworkId).update(updates);
    } catch (e) {
      throw Exception('Error updating artwork content: $e');
    }
  }

  /// Delete a specific comment
  Future<void> deleteComment(String artworkId, String commentId,
      {String? reason}) async {
    try {
      await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('comments')
          .doc(commentId)
          .update({
        'isDeleted': true,
        'deletionReason': reason,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('artwork').doc(artworkId).update({
        'commentCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Error deleting comment: $e');
    }
  }

  /// Flag a comment as inappropriate
  Future<void> flagComment(
      String artworkId, String commentId, String reason) async {
    try {
      await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('comments')
          .doc(commentId)
          .update({
        'flagged': true,
        'flagReason': reason,
        'flaggedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error flagging comment: $e');
    }
  }

  /// Add a report to artwork
  Future<void> addReport(
    String artworkId, {
    required String reason,
    required String reportedBy,
  }) async {
    try {
      final report = {
        'reason': reason,
        'reportedBy': reportedBy,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('artwork').doc(artworkId).update({
        'reports': FieldValue.arrayUnion([report]),
      });
    } catch (e) {
      throw Exception('Error adding report: $e');
    }
  }

  /// Clear all reports for artwork
  Future<void> clearReports(String artworkId) async {
    try {
      await _firestore.collection('artwork').doc(artworkId).update({
        'reports': [],
      });
    } catch (e) {
      throw Exception('Error clearing reports: $e');
    }
  }

  /// Get analytics summary for all artwork
  Future<Map<String, dynamic>> getArtworkAnalyticsSummary() async {
    try {
      final allArtwork = await _firestore.collection('artwork').get();

      final int totalArtwork = allArtwork.size;
      int reportedCount = 0;
      int flaggedCount = 0;
      int pendingCount = 0;
      int totalViews = 0;
      int totalLikes = 0;
      int totalComments = 0;

      for (final doc in allArtwork.docs) {
        final data = doc.data();
        final reports = data['reports'] as List<dynamic>? ?? [];
        final status = data['moderationStatus'] as String? ?? '';

        if (reports.isNotEmpty) reportedCount++;
        if (status == 'flagged') flaggedCount++;
        if (status == 'pending') pendingCount++;

        totalViews += data['viewCount'] as int? ?? 0;
        totalLikes += data['likeCount'] as int? ?? 0;
        totalComments += data['commentCount'] as int? ?? 0;
      }

      return {
        'totalArtwork': totalArtwork,
        'reportedCount': reportedCount,
        'flaggedCount': flaggedCount,
        'pendingCount': pendingCount,
        'totalViews': totalViews,
        'totalLikes': totalLikes,
        'totalComments': totalComments,
        'averageEngagement': totalArtwork > 0
            ? '${((totalLikes + totalComments) / totalArtwork).toStringAsFixed(1)}'
            : '0',
      };
    } catch (e) {
      throw Exception('Error getting analytics summary: $e');
    }
  }

  /// Search artwork by title or description
  Future<List<ArtworkModel>> searchArtwork(String query) async {
    try {
      final results = await _firestore
          .collection('artwork')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '${query}z')
          .limit(20)
          .get();

      return results.docs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch all written content (books, stories, etc.) with chapter information
  Future<List<Map<String, dynamic>>> getWrittenContentWithChapters({
    String filterType = 'all',
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection('artwork').where('contentType', isEqualTo: 'written');

      switch (filterType) {
        case 'reported':
          query = query.where('reports', isNotEqualTo: null);
          break;
        case 'flagged':
          query = query.where('moderationStatus', isEqualTo: 'flagged');
          break;
        case 'pending':
          query = query.where('moderationStatus', isEqualTo: 'pending');
          break;
        case 'approved':
          query = query.where('moderationStatus', isEqualTo: 'approved');
          break;
        case 'rejected':
          query = query.where('moderationStatus', isEqualTo: 'rejected');
          break;
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);
      final snapshot = await query.get();

      final List<Map<String, dynamic>> writtenContent = [];

      for (final doc in snapshot.docs) {
        final artwork = ArtworkModel.fromFirestore(doc);
        
        // Fetch chapters for this written content
        final chaptersSnapshot = await _firestore
            .collection('artwork')
            .doc(artwork.id)
            .collection('chapters')
            .orderBy('number', descending: false)
            .get();

        final chapters = chaptersSnapshot.docs
            .map((chapterDoc) => {
              'id': chapterDoc.id,
              'number': chapterDoc.data()['number'] ?? 0,
              'title': chapterDoc.data()['title'] ?? 'Unknown',
              'wordCount': chapterDoc.data()['wordCount'] ?? 0,
              'readingTime': chapterDoc.data()['readingTime'] ?? 0,
              'viewCount': chapterDoc.data()['viewCount'] ?? 0,
              'readCount': chapterDoc.data()['readCount'] ?? 0,
            })
            .toList();

        writtenContent.add({
          'artwork': artwork,
          'chapters': chapters,
          'totalChapters': chapters.length,
          'totalWordCount': chapters.fold<int>(
            0,
            (sum, chapter) => sum + (chapter['wordCount'] as int),
          ),
        });
      }

      return writtenContent;
    } catch (e) {
      throw Exception('Error fetching written content: $e');
    }
  }

  /// Get detailed information about a specific written content including all chapters
  Future<Map<String, dynamic>> getWrittenContentDetails(String artworkId) async {
    try {
      final doc = await _firestore.collection('artwork').doc(artworkId).get();
      if (!doc.exists) {
        throw Exception('Written content not found');
      }

      final artwork = ArtworkModel.fromFirestore(doc);
      
      // Verify it's actually written content
      if (artwork.contentType != 'written') {
        throw Exception('This artwork is not written content');
      }

      // Fetch all chapters
      final chaptersSnapshot = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('chapters')
          .orderBy('number', descending: false)
          .get();

      final chapters = chaptersSnapshot.docs
          .map((chapterDoc) => {
            'id': chapterDoc.id,
            'number': chapterDoc.data()['number'] ?? 0,
            'title': chapterDoc.data()['title'] ?? 'Unknown',
            'wordCount': chapterDoc.data()['wordCount'] ?? 0,
            'readingTime': chapterDoc.data()['readingTime'] ?? 0,
            'viewCount': chapterDoc.data()['viewCount'] ?? 0,
            'readCount': chapterDoc.data()['readCount'] ?? 0,
            'content': chapterDoc.data()['content'] ?? '',
            'createdAt': chapterDoc.data()['createdAt'],
            'updatedAt': chapterDoc.data()['updatedAt'],
          })
          .toList();

      return {
        'artwork': artwork,
        'chapters': chapters,
        'totalChapters': chapters.length,
        'totalWordCount': chapters.fold<int>(
          0,
          (sum, chapter) => sum + (chapter['wordCount'] as int),
        ),
        'totalViews': chapters.fold<int>(
          0,
          (sum, chapter) => sum + (chapter['viewCount'] as int),
        ),
        'totalReads': chapters.fold<int>(
          0,
          (sum, chapter) => sum + (chapter['readCount'] as int),
        ),
      };
    } catch (e) {
      throw Exception('Error fetching written content details: $e');
    }
  }
}
