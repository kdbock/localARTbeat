import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

import '../models/admin_community_moderation_models.dart';

class AdminCommunityModerationService {
  AdminCommunityModerationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<AdminModeratedPost>> getFlaggedPosts() async {
    try {
      final query = await _firestore
          .collection('posts')
          .where('flagged', isEqualTo: true)
          .orderBy('flaggedAt', descending: true)
          .get();

      return query.docs.map(AdminModeratedPost.fromFirestore).toList();
    } catch (e) {
      AppLogger.error('Error getting flagged posts: $e');
      return [];
    }
  }

  Future<List<AdminModeratedComment>> getFlaggedComments() async {
    try {
      final query = await _firestore
          .collection('comments')
          .where('flagged', isEqualTo: true)
          .orderBy('flaggedAt', descending: true)
          .get();

      return query.docs.map(AdminModeratedComment.fromFirestore).toList();
    } catch (e) {
      AppLogger.error('Error getting flagged comments: $e');
      return [];
    }
  }

  Future<void> approvePost(String postId) async {
    await _firestore.collection('posts').doc(postId).update({
      'flagged': false,
      'moderationStatus': 'approved',
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removePost(String postId) async {
    await _firestore.collection('posts').doc(postId).update({
      'isPublic': false,
      'flagged': false,
      'moderationStatus': 'removed',
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> approveComment(String commentId) async {
    await _firestore.collection('comments').doc(commentId).update({
      'flagged': false,
      'moderationStatus': 'approved',
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeComment(String commentId) async {
    await _firestore.collection('comments').doc(commentId).update({
      'isPublic': false,
      'flagged': false,
      'moderationStatus': 'removed',
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }
}
