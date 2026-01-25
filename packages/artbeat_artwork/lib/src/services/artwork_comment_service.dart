import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment_model.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppLogger;
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

/// Enhanced comment service specifically for artwork interactions
///
/// Handles artwork-specific comments with features like threading,
/// moderation, reactions, and integration with artist profiles.
class ArtworkCommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Post a comment on an artwork
  Future<String?> postComment({
    required String artworkId,
    required String content,
    String? parentCommentId,
    String commentType = 'Comment',
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to post comments');
      }

      if (content.trim().isEmpty) {
        throw Exception('Comment content cannot be empty');
      }

      // Get user profile for display name and avatar
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final commentData = {
        'postId':
            artworkId, // Reusing the existing field name for compatibility
        'artworkId': artworkId, // More specific field for artwork comments
        'userId': user.uid,
        'userName':
            userData['displayName'] as String? ??
            user.displayName ??
            'Anonymous',
        'userAvatarUrl': userData['profileImageUrl'] as String? ?? '',
        'content': content.trim(),
        'parentCommentId': parentCommentId ?? '',
        'type': commentType,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'likes': 0,
        'replies': 0,
        'isEdited': false,
        'moderationStatus': 'approved', // Auto-approve for now
        'isArtistComment': false, // Will be updated if user is the artist
      };

      // Check if the user is the artist of this artwork
      final artworkDoc = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .get();
      if (artworkDoc.exists) {
        final artworkData = artworkDoc.data() as Map<String, dynamic>;
        if (artworkData['userId'] == user.uid ||
            artworkData['artistProfileId'] == user.uid) {
          commentData['isArtistComment'] = true;
        }
      }

      final commentRef = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('comments')
          .add(commentData);

      // If this is a reply, increment the parent comment's reply count
      if (parentCommentId != null && parentCommentId.isNotEmpty) {
        await _firestore
            .collection('artwork')
            .doc(artworkId)
            .collection('comments')
            .doc(parentCommentId)
            .update({
              'replies': FieldValue.increment(1),
              'updatedAt': Timestamp.now(),
            });
      }

      // Update artwork's comment count
      await _firestore.collection('artwork').doc(artworkId).update({
        'commentCount': FieldValue.increment(1),
        'lastCommentAt': Timestamp.now(),
      });

      // Create notification for artist (if commenter is not the artist)
      if (!(commentData['isArtistComment'] as bool? ?? false)) {
        await _createCommentNotification(artworkId, commentRef.id, commentType);
      }

      // Track comment for challenge progress
      try {
        final challengeService = ChallengeService();
        await challengeService.recordComment();
      } catch (e) {
        AppLogger.error('Error recording comment to challenge: $e');
      }

      return commentRef.id;
    } catch (e) {
      AppLogger.error('Error posting comment: $e');
      return null;
    }
  }

  /// Get comments for an artwork with pagination
  Future<List<CommentModel>> getArtworkComments(
    String artworkId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
    bool includeReplies = true,
  }) async {
    try {
      Query query = _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('comments')
          .orderBy('createdAt', descending: true);

      if (!includeReplies) {
        query = query.where('parentCommentId', isEqualTo: '');
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting artwork comments: $e');
      return [];
    }
  }

  /// Get replies to a specific comment
  Future<List<CommentModel>> getCommentReplies(
    String artworkId,
    String parentCommentId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('comments')
          .where('parentCommentId', isEqualTo: parentCommentId)
          .orderBy('createdAt', descending: false)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting comment replies: $e');
      return [];
    }
  }

  /// Edit a comment (only by the comment author)
  Future<bool> editComment(
    String artworkId,
    String commentId,
    String newContent,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      if (newContent.trim().isEmpty) {
        throw Exception('Comment content cannot be empty');
      }

      // Verify the comment belongs to the current user
      final commentDoc = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('comments')
          .doc(commentId)
          .get();

      if (!commentDoc.exists) return false;

      final commentData = commentDoc.data() as Map<String, dynamic>;
      if (commentData['userId'] != user.uid) return false;

      await commentDoc.reference.update({
        'content': newContent.trim(),
        'updatedAt': Timestamp.now(),
        'isEdited': true,
      });

      return true;
    } catch (e) {
      AppLogger.error('Error editing comment: $e');
      return false;
    }
  }

  /// Delete a comment (only by the comment author or artwork owner)
  Future<bool> deleteComment(String artworkId, String commentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get comment and artwork data
      final commentDoc = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('comments')
          .doc(commentId)
          .get();

      if (!commentDoc.exists) return false;

      final commentData = commentDoc.data() as Map<String, dynamic>;
      final artworkDoc = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .get();

      if (!artworkDoc.exists) return false;

      final artworkData = artworkDoc.data() as Map<String, dynamic>;

      // Check if user can delete (comment author or artwork owner)
      final canDelete =
          commentData['userId'] == user.uid ||
          artworkData['userId'] == user.uid ||
          artworkData['artistProfileId'] == user.uid;

      if (!canDelete) return false;

      // Delete the comment
      await commentDoc.reference.delete();

      // Update artwork's comment count
      await _firestore.collection('artwork').doc(artworkId).update({
        'commentCount': FieldValue.increment(-1),
      });

      // If this comment had a parent, decrement the parent's reply count
      final parentCommentId = commentData['parentCommentId'] as String?;
      if (parentCommentId != null && parentCommentId.isNotEmpty) {
        await _firestore
            .collection('artwork')
            .doc(artworkId)
            .collection('comments')
            .doc(parentCommentId)
            .update({'replies': FieldValue.increment(-1)});
      }

      return true;
    } catch (e) {
      AppLogger.error('Error deleting comment: $e');
      return false;
    }
  }

  /// Like or unlike a comment
  Future<bool> toggleCommentLike(String artworkId, String commentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final likeDoc = _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('comments')
          .doc(commentId)
          .collection('likes')
          .doc(user.uid);

      final likeSnapshot = await likeDoc.get();

      if (likeSnapshot.exists) {
        // Unlike
        await likeDoc.delete();
        await _firestore
            .collection('artwork')
            .doc(artworkId)
            .collection('comments')
            .doc(commentId)
            .update({'likes': FieldValue.increment(-1)});
      } else {
        // Like
        await likeDoc.set({'userId': user.uid, 'createdAt': Timestamp.now()});
        await _firestore
            .collection('artwork')
            .doc(artworkId)
            .collection('comments')
            .doc(commentId)
            .update({'likes': FieldValue.increment(1)});
      }

      return true;
    } catch (e) {
      AppLogger.error('Error toggling comment like: $e');
      return false;
    }
  }

  /// Check if user has liked a comment
  Future<bool> hasUserLikedComment(String artworkId, String commentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final likeDoc = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('comments')
          .doc(commentId)
          .collection('likes')
          .doc(user.uid)
          .get();

      return likeDoc.exists;
    } catch (e) {
      AppLogger.error('Error checking comment like status: $e');
      return false;
    }
  }

  /// Report inappropriate comment
  Future<bool> reportComment(
    String artworkId,
    String commentId,
    String reason,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('reports').add({
        'type': 'comment',
        'artworkId': artworkId,
        'commentId': commentId,
        'reporterId': user.uid,
        'reason': reason,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      AppLogger.error('Error reporting comment: $e');
      return false;
    }
  }

  /// Stream comments for real-time updates
  Stream<List<CommentModel>> streamArtworkComments(
    String artworkId, {
    int limit = 50,
    bool includeReplies = true,
  }) {
    Query query = _firestore
        .collection('artwork')
        .doc(artworkId)
        .collection('comments')
        .orderBy('createdAt', descending: true);

    if (!includeReplies) {
      query = query.where('parentCommentId', isEqualTo: '');
    }

    return query
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get comment statistics for an artwork
  Future<Map<String, dynamic>> getCommentStats(String artworkId) async {
    try {
      final snapshot = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('comments')
          .get();

      final comments = snapshot.docs;
      final totalComments = comments.length;
      final topLevelComments = comments.where((doc) {
        final data = doc.data();
        return data['parentCommentId'] == '' || data['parentCommentId'] == null;
      }).length;

      final replies = totalComments - topLevelComments;

      // Calculate engagement metrics
      int totalLikes = 0;
      for (final doc in comments) {
        final data = doc.data();
        totalLikes += (data['likes'] as int?) ?? 0;
      }

      return {
        'totalComments': totalComments,
        'topLevelComments': topLevelComments,
        'replies': replies,
        'totalLikes': totalLikes,
        'engagementScore': totalLikes + (totalComments * 2),
      };
    } catch (e) {
      AppLogger.error('Error getting comment stats: $e');
      return {
        'totalComments': 0,
        'topLevelComments': 0,
        'replies': 0,
        'totalLikes': 0,
        'engagementScore': 0,
      };
    }
  }

  /// Create notification for new comment
  Future<void> _createCommentNotification(
    String artworkId,
    String commentId,
    String commentType,
  ) async {
    try {
      // Get artwork to find the artist
      final artworkDoc = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .get();
      if (!artworkDoc.exists) return;

      final artworkData = artworkDoc.data() as Map<String, dynamic>;
      final artistId =
          artworkData['userId'] as String? ??
          artworkData['artistProfileId'] as String?;

      if (artistId == null) return;

      // Create notification for the artist
      await _firestore.collection('notifications').add({
        'userId': artistId,
        'type': 'artwork_comment',
        'title': 'New comment on your artwork',
        'message':
            'Someone left a $commentType on "${artworkData['title'] ?? 'your artwork'}"',
        'data': {
          'artworkId': artworkId,
          'commentId': commentId,
          'artworkTitle': artworkData['title'] ?? '',
        },
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      AppLogger.error('Error creating comment notification: $e');
    }
  }
}
