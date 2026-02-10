import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart' show ChapterService;
import '../models/content_model.dart';

/// Unified Admin Service
///
/// Provides content management specifically for the unified admin dashboard
/// Avoids conflicts with existing ContentReviewService
class UnifiedAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChapterService _chapterService = ChapterService();

  /// Get all content for admin dashboard
  Future<List<ContentModel>> getAllContent({
    AdminContentType? contentType,
    AdminContentStatus? status,
    int? limit,
  }) async {
    try {
      List<ContentModel> allContent = [];

      // Get artworks
      if (contentType == null ||
          contentType == AdminContentType.all ||
          contentType == AdminContentType.artwork) {
        final artworksQuery = _firestore
            .collection('artwork')
            .orderBy('createdAt', descending: true);

        final artworksSnapshot = await (limit != null
            ? artworksQuery.limit(limit).get()
            : artworksQuery.get());

        for (final doc in artworksSnapshot.docs) {
          final content = ContentModel.fromArtwork(doc);
          if (status == null ||
              status == AdminContentStatus.all ||
              content.status == status.value) {
            allContent.add(content);
          }
        }
      }

      // Get posts
      if (contentType == null ||
          contentType == AdminContentType.all ||
          contentType == AdminContentType.post) {
        final postsQuery = _firestore
            .collection('posts')
            .orderBy('createdAt', descending: true);

        final postsSnapshot = await (limit != null
            ? postsQuery.limit(limit).get()
            : postsQuery.get());

        for (final doc in postsSnapshot.docs) {
          final content = ContentModel.fromPost(doc);
          if (status == null ||
              status == AdminContentStatus.all ||
              content.status == status.value) {
            allContent.add(content);
          }
        }
      }

      // Get events
      if (contentType == null ||
          contentType == AdminContentType.all ||
          contentType == AdminContentType.event) {
        final eventsQuery = _firestore
            .collection('events')
            .orderBy('createdAt', descending: true);

        final eventsSnapshot = await (limit != null
            ? eventsQuery.limit(limit).get()
            : eventsQuery.get());

        for (final doc in eventsSnapshot.docs) {
          final content = ContentModel.fromEvent(doc);
          if (status == null ||
              status == AdminContentStatus.all ||
              content.status == status.value) {
            allContent.add(content);
          }
        }
      }

      // Get captures
      if (contentType == null ||
          contentType == AdminContentType.all ||
          contentType == AdminContentType.capture) {
        final capturesQuery = _firestore
            .collection('captures')
            .orderBy('createdAt', descending: true);

        final capturesSnapshot = await (limit != null
            ? capturesQuery.limit(limit).get()
            : capturesQuery.get());

        for (final doc in capturesSnapshot.docs) {
          final content = ContentModel.fromCapture(doc);
          if (status == null ||
              status == AdminContentStatus.all ||
              content.status == status.value) {
            allContent.add(content);
          }
        }
      }
      
      // Get chapters (using collectionGroup to get all chapters from all artwork)
      if (contentType == null ||
          contentType == AdminContentType.all ||
          contentType == AdminContentType.chapter) {
        final chaptersQuery = _firestore
            .collectionGroup('chapters')
            .orderBy('createdAt', descending: true);

        final chaptersSnapshot = await (limit != null
            ? chaptersQuery.limit(limit).get()
            : chaptersQuery.get());

        for (final doc in chaptersSnapshot.docs) {
          final content = ContentModel.fromChapter(doc);
          if (status == null ||
              status == AdminContentStatus.all ||
              content.status == status.value) {
            allContent.add(content);
          }
        }
      }

      // Sort by creation date (most recent first)
      allContent.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Apply limit if specified
      if (limit != null && allContent.length > limit) {
        allContent = allContent.take(limit).toList();
      }

      return allContent;
    } catch (e) {
      throw Exception('Failed to get all content: $e');
    }
  }

  /// Approve content by ID
  Future<void> approveContent(String contentId, {String? artworkId}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // If artworkId is provided, it's definitely a chapter
      if (artworkId != null) {
        final docRef = _firestore
            .collection('artwork')
            .doc(artworkId)
            .collection('chapters')
            .doc(contentId);

        await docRef.update({
          'moderationStatus': 'approved',
          'moderatedBy': user.uid,
          'moderatedAt': FieldValue.serverTimestamp(),
          'isFlagged': false,
        });

        await _chapterService.updateArtworkCountsForAdmin(artworkId);

        await _logModerationAction(
          contentId: contentId,
          action: 'approved',
          moderatorId: user.uid,
          contentType: 'chapter',
        );
        return;
      }

      // Try to find and update the content in different collections
      final collections = ['artwork', 'posts', 'events', 'captures'];

      for (final collection in collections) {
        final doc =
            await _firestore.collection(collection).doc(contentId).get();
        if (doc.exists) {
          final updateData = {
            'moderatedBy': user.uid,
            'moderatedAt': FieldValue.serverTimestamp(),
            'isFlagged': false,
          };

          // For artworks, update moderationStatus; for others, update status
          if (collection == 'artwork') {
            updateData['moderationStatus'] = 'approved';
          } else {
            updateData['status'] = 'approved';
          }

          await doc.reference.update(updateData);

          // Log the moderation action
          await _logModerationAction(
            contentId: contentId,
            action: 'approved',
            moderatorId: user.uid,
            contentType: collection,
          );

          return;
        }
      }

      // Check for chapters if not found in top-level collections
      final chapterQuery = await _firestore
          .collectionGroup('chapters')
          .where(FieldPath.documentId, isEqualTo: contentId)
          .get();

      if (chapterQuery.docs.isNotEmpty) {
        final chapterDoc = chapterQuery.docs.first;
        final docRef = chapterDoc.reference;
        final artworkId = chapterDoc.data()['artworkId'] as String?;

        await docRef.update({
          'moderationStatus': 'approved',
          'moderatedBy': user.uid,
          'moderatedAt': FieldValue.serverTimestamp(),
          'isFlagged': false,
        });

        if (artworkId != null) {
          await _chapterService.updateArtworkCountsForAdmin(artworkId);
        }

        await _logModerationAction(
          contentId: contentId,
          action: 'approved',
          moderatorId: user.uid,
          contentType: 'chapter',
        );
        return;
      }

      throw Exception('Content not found');
    } catch (e) {
      throw Exception('Failed to approve content: $e');
    }
  }

  /// Reject content by ID
  Future<void> rejectContent(String contentId,
      {String? reason, String? artworkId}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // If artworkId is provided, it's definitely a chapter
      if (artworkId != null) {
        final docRef = _firestore
            .collection('artwork')
            .doc(artworkId)
            .collection('chapters')
            .doc(contentId);

        await docRef.update({
          'moderationStatus': 'rejected',
          'moderatedBy': user.uid,
          'moderatedAt': FieldValue.serverTimestamp(),
          'rejectionReason':
              reason ?? 'Content does not meet community guidelines',
          'isFlagged': false,
        });

        await _chapterService.updateArtworkCountsForAdmin(artworkId);

        await _logModerationAction(
          contentId: contentId,
          action: 'rejected',
          moderatorId: user.uid,
          contentType: 'chapter',
          reason: reason,
        );
        return;
      }

      // Try to find and update the content in different collections
      final collections = ['artwork', 'posts', 'events', 'captures'];

      for (final collection in collections) {
        final doc =
            await _firestore.collection(collection).doc(contentId).get();
        if (doc.exists) {
          final updateData = {
            'moderatedBy': user.uid,
            'moderatedAt': FieldValue.serverTimestamp(),
            'rejectionReason':
                reason ?? 'Content does not meet community guidelines',
            'isFlagged': false,
          };

          // For artworks, update moderationStatus; for others, update status
          if (collection == 'artwork') {
            updateData['moderationStatus'] = 'rejected';
          } else {
            updateData['status'] = 'rejected';
          }

          await doc.reference.update(updateData);

          // Log the moderation action
          await _logModerationAction(
            contentId: contentId,
            action: 'rejected',
            moderatorId: user.uid,
            contentType: collection,
            reason: reason,
          );

          return;
        }
      }

      // Check for chapters if not found in top-level collections
      final chapterQuery = await _firestore
          .collectionGroup('chapters')
          .where(FieldPath.documentId, isEqualTo: contentId)
          .get();

      if (chapterQuery.docs.isNotEmpty) {
        final chapterDoc = chapterQuery.docs.first;
        final docRef = chapterDoc.reference;
        final artworkId = chapterDoc.data()['artworkId'] as String?;

        await docRef.update({
          'moderationStatus': 'rejected',
          'moderatedBy': user.uid,
          'moderatedAt': FieldValue.serverTimestamp(),
          'rejectionReason':
              reason ?? 'Content does not meet community guidelines',
          'isFlagged': false,
        });

        if (artworkId != null) {
          await _chapterService.updateArtworkCountsForAdmin(artworkId);
        }

        await _logModerationAction(
          contentId: contentId,
          action: 'rejected',
          moderatorId: user.uid,
          contentType: 'chapter',
          reason: reason,
        );
        return;
      }

      throw Exception('Content not found');
    } catch (e) {
      throw Exception('Failed to reject content: $e');
    }
  }

  /// Log moderation action for audit trail
  Future<void> _logModerationAction({
    required String contentId,
    required String action,
    required String moderatorId,
    required String contentType,
    String? reason,
  }) async {
    try {
      await _firestore.collection('moderation_logs').add({
        'contentId': contentId,
        'contentType': contentType,
        'action': action,
        'moderatorId': moderatorId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log error but don't throw - moderation action should still succeed
      // Failed to log moderation action: $e
    }
  }

  /// Bulk approve multiple content items
  Future<void> bulkApproveContent(List<String> contentIds) async {
    final futures = contentIds.map((id) => approveContent(id));
    await Future.wait(futures);
  }

  /// Bulk reject multiple content items
  Future<void> bulkRejectContent(List<String> contentIds,
      {String? reason}) async {
    final futures = contentIds.map((id) => rejectContent(id, reason: reason));
    await Future.wait(futures);
  }

  /// Get content statistics for dashboard
  Future<Map<String, dynamic>> getContentStatistics() async {
    try {
      final results = await Future.wait([
        _firestore.collection('artwork').get(),
        _firestore.collection('posts').get(),
        _firestore.collection('events').get(),
        _firestore.collection('captures').get(),
        _firestore.collectionGroup('chapters').get(),
        _firestore
            .collection('artwork')
            .where('moderationStatus', isEqualTo: 'pending')
            .get(),
        _firestore
            .collection('posts')
            .where('status', isEqualTo: 'pending')
            .get(),
        _firestore
            .collection('events')
            .where('status', isEqualTo: 'pending')
            .get(),
        _firestore
            .collection('captures')
            .where('status', isEqualTo: 'pending')
            .get(),
        _firestore
            .collectionGroup('chapters')
            .where('moderationStatus', isEqualTo: 'pending')
            .get(),
        _firestore
            .collection('artwork')
            .where('isFlagged', isEqualTo: true)
            .get(),
        _firestore
            .collection('posts')
            .where('isFlagged', isEqualTo: true)
            .get(),
        _firestore
            .collection('events')
            .where('isFlagged', isEqualTo: true)
            .get(),
        _firestore
            .collection('captures')
            .where('isFlagged', isEqualTo: true)
            .get(),
        _firestore
            .collectionGroup('chapters')
            .where('moderationStatus', isEqualTo: 'underReview')
            .get(),
      ]);

      final totalArtworks = results[0].docs.length;
      final totalPosts = results[1].docs.length;
      final totalEvents = results[2].docs.length;
      final totalCaptures = results[3].docs.length;
      final totalChapters = results[4].docs.length;
      final pendingArtworks = results[5].docs.length;
      final pendingPosts = results[6].docs.length;
      final pendingEvents = results[7].docs.length;
      final pendingCaptures = results[8].docs.length;
      final pendingChapters = results[9].docs.length;
      final flaggedArtworks = results[10].docs.length;
      final flaggedPosts = results[11].docs.length;
      final flaggedEvents = results[12].docs.length;
      final flaggedCaptures = results[13].docs.length;
      final flaggedChapters = results[14].docs.length;

      return {
        'total': totalArtworks +
            totalPosts +
            totalEvents +
            totalCaptures +
            totalChapters,
        'artworks': totalArtworks,
        'posts': totalPosts,
        'events': totalEvents,
        'captures': totalCaptures,
        'chapters': totalChapters,
        'pending': pendingArtworks +
            pendingPosts +
            pendingEvents +
            pendingCaptures +
            pendingChapters,
        'flagged': flaggedArtworks +
            flaggedPosts +
            flaggedEvents +
            flaggedCaptures +
            flaggedChapters,
        'breakdown': {
          'artworks': {
            'total': totalArtworks,
            'pending': pendingArtworks,
            'flagged': flaggedArtworks,
          },
          'posts': {
            'total': totalPosts,
            'pending': pendingPosts,
            'flagged': flaggedPosts,
          },
          'events': {
            'total': totalEvents,
            'pending': pendingEvents,
            'flagged': flaggedEvents,
          },
          'captures': {
            'total': totalCaptures,
            'pending': pendingCaptures,
            'flagged': flaggedCaptures,
          },
          'chapters': {
            'total': totalChapters,
            'pending': pendingChapters,
            'flagged': flaggedChapters,
          },
        },
      };
    } catch (e) {
      throw Exception('Failed to get content statistics: $e');
    }
  }
}
