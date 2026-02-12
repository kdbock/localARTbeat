import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

enum FlaggedItemType {
  post,
  comment,
  artwork,
  capture,
  event,
  report,
}

class FlaggedItem {
  final String id;
  final FlaggedItemType type;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime flaggedAt;
  final String? reason;
  final Map<String, dynamic> rawData;

  FlaggedItem({
    required this.id,
    required this.type,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.flaggedAt,
    this.reason,
    required this.rawData,
  });
}

class FlaggingQueueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all flagged items from various collections
  Future<List<FlaggedItem>> getFlaggedQueue({int limit = 100}) async {
    final List<FlaggedItem> items = [];

    try {
      // 1. Get flagged posts
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('flagged', isEqualTo: true)
          .limit(limit)
          .get();

      for (var doc in postsSnapshot.docs) {
        final data = doc.data();
        items.add(FlaggedItem(
          id: doc.id,
          type: FlaggedItemType.post,
          content: data['content'] as String? ?? '',
          authorId: data['authorId'] as String? ?? '',
          authorName: data['authorName'] as String? ?? 'Unknown',
          flaggedAt: (data['flaggedAt'] as Timestamp?)?.toDate() ??
              (data['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
          reason: data['moderationReason'] as String?,
          rawData: data,
        ));
      }

      // 2. Get flagged comments
      final commentsSnapshot = await _firestore
          .collection('comments')
          .where('flagged', isEqualTo: true)
          .limit(limit)
          .get();

      for (var doc in commentsSnapshot.docs) {
        final data = doc.data();
        items.add(FlaggedItem(
          id: doc.id,
          type: FlaggedItemType.comment,
          content: data['content'] as String? ?? '',
          authorId: data['authorId'] as String? ?? '',
          authorName: data['authorName'] as String? ?? 'Unknown',
          flaggedAt: (data['flaggedAt'] as Timestamp?)?.toDate() ??
              (data['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
          reason: data['moderationReason'] as String?,
          rawData: data,
        ));
      }

      // 3. Get flagged artworks
      final artworksSnapshot = await _firestore
          .collection('artworks')
          .where('flagged', isEqualTo: true)
          .limit(limit)
          .get();

      for (var doc in artworksSnapshot.docs) {
        final data = doc.data();
        items.add(FlaggedItem(
          id: doc.id,
          type: FlaggedItemType.artwork,
          content:
              data['title'] as String? ?? data['description'] as String? ?? '',
          authorId: data['artistId'] as String? ?? '',
          authorName: data['artistName'] as String? ?? 'Unknown Artist',
          flaggedAt: (data['flaggedAt'] as Timestamp?)?.toDate() ??
              (data['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
          reason: data['moderationReason'] as String?,
          rawData: data,
        ));
      }

      // 4. Get direct reports
      final reportsSnapshot = await _firestore
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .limit(limit)
          .get();

      for (var doc in reportsSnapshot.docs) {
        final data = doc.data();
        items.add(FlaggedItem(
          id: doc.id,
          type: FlaggedItemType.report,
          content: data['description'] as String? ??
              data['reasonDisplay'] as String? ??
              '',
          authorId: data['reportedUserId'] as String? ?? '',
          authorName: 'User Report',
          flaggedAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          reason: data['reasonDisplay'] as String?,
          rawData: data,
        ));
      }

      // Sort items by flaggedAt descending
      items.sort((a, b) => b.flaggedAt.compareTo(a.flaggedAt));

      return items.take(limit).toList();
    } catch (e) {
      AppLogger.error('Error fetching flagged queue: $e');
      return items;
    }
  }

  /// Resolve a flagged item
  Future<void> resolveItem(FlaggedItem item, bool approve,
      {String? notes}) async {
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    switch (item.type) {
      case FlaggedItemType.post:
        batch.update(_firestore.collection('posts').doc(item.id), {
          'flagged': false,
          'moderationStatus': approve ? 'approved' : 'rejected',
          'isPublic': approve,
          'moderatedAt': now,
          'moderationNotes': notes,
        });
        break;
      case FlaggedItemType.comment:
        batch.update(_firestore.collection('comments').doc(item.id), {
          'flagged': false,
          'moderationStatus': approve ? 'approved' : 'rejected',
          'isPublic': approve,
          'moderatedAt': now,
          'moderationNotes': notes,
        });
        break;
      case FlaggedItemType.artwork:
        batch.update(_firestore.collection('artworks').doc(item.id), {
          'flagged': false,
          'moderationStatus': approve ? 'approved' : 'rejected',
          'moderatedAt': now,
          'moderationNotes': notes,
        });
        break;
      case FlaggedItemType.report:
        batch.update(_firestore.collection('reports').doc(item.id), {
          'status': approve ? 'resolved' : 'dismissed',
          'resolved': true,
          'resolvedAt': now,
          'moderationNotes': notes,
        });
        break;
      default:
        // Handle other types if necessary
        break;
    }

    await batch.commit();
  }
}
