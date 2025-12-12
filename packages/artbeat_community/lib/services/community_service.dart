import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'package:artbeat_core/artbeat_core.dart';

class CommunityService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to pick images for a post
  Future<List<File>> pickPostImages() async {
    // This is a placeholder.
    // Actual implementation would use image_picker or a similar package
    // to allow the user to select images from their gallery or camera.
    AppLogger.info('pickPostImages called - placeholder implementation');
    return []; // Return an empty list for now
  }

  // Get all posts
  Future<List<PostModel>> getPosts({int limit = 10, String? lastPostId}) async {
    try {
      Query query = _firestore
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastPostId != null) {
        // Get the last document for pagination
        final lastDocSnapshot = await _firestore
            .collection('posts')
            .doc(lastPostId)
            .get();
        query = query.startAfterDocument(lastDocSnapshot);
      }

      final querySnapshot = await query.get();

      // Load posts and add like status for current user
      final posts = <PostModel>[];
      for (final doc in querySnapshot.docs) {
        final post = PostModel.fromFirestore(doc);
        final isLiked = await hasUserLikedPost(post.id);
        final postWithLikeStatus = post.copyWith(isLikedByCurrentUser: isLiked);
        posts.add(postWithLikeStatus);
      }

      return posts;
    } catch (e) {
      AppLogger.error('Error getting posts: $e');
      return [];
    }
  }

  // Get posts by user ID
  Future<List<PostModel>> getPostsByUserId(
    String userId, {
    int limit = 10,
    String? lastPostId,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastPostId != null) {
        final lastDocSnapshot = await _firestore
            .collection('posts')
            .doc(lastPostId)
            .get();
        query = query.startAfterDocument(lastDocSnapshot);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting posts by user ID: $e');
      return [];
    }
  }

  // Create a new post
  Future<String?> createPost({
    required String userId,
    required String userName,
    required String userPhotoUrl,
    required String content,
    required List<String> imageUrls,
    required List<String> tags,
    required String location,
    GeoPoint? geoPoint,
    String? zipCode,
    bool isPublic = true,
    List<String>? mentionedUsers,
    Map<String, dynamic>? metadata,
    String? groupType, // Add groupType parameter
  }) async {
    try {
      AppLogger.info('🔄 Creating post for user: $userId');
      AppLogger.info('📝 Post content: $content');
      AppLogger.info('🖼️ Image URLs: $imageUrls');
      AppLogger.info('🏷️ Tags: $tags');
      AppLogger.info('📍 Location: $location');
      AppLogger.info('👥 Group Type: $groupType');

      final docRef = await _firestore.collection('posts').add({
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'content': content,
        'imageUrls': imageUrls,
        'tags': tags,
        'location': location,
        'geoPoint': geoPoint,
        'zipCode': zipCode,
        'createdAt': FieldValue.serverTimestamp(),
        'applauseCount': 0,
        'commentCount': 0,
        'shareCount': 0,
        'isPublic': isPublic,
        'mentionedUsers': mentionedUsers,
        'metadata': metadata,
        'groupType':
            groupType ?? 'general', // Default to 'general' if not specified
      });

      AppLogger.info('✅ Post created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      AppLogger.error('❌ Error creating post: $e');
      AppLogger.info('📍 Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Delete a post
  Future<bool> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      return true;
    } catch (e) {
      AppLogger.error('Error deleting post: $e');
      return false;
    }
  }

  // Add a comment to a post
  Future<String?> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String userPhotoUrl,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      // Add the comment to Firestore
      final commentRef = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
            'userId': userId,
            'userName': userName,
            'userAvatarUrl': userPhotoUrl, // Changed to match the model
            'content': content,
            'createdAt': FieldValue.serverTimestamp(),
            'parentCommentId': parentCommentId ?? '',
            'type': 'Appreciation', // Add default type
          });

      // Update the comment count on the post
      await _firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      return commentRef.id;
    } catch (e) {
      AppLogger.error('Error adding comment: $e');
      AppLogger.error('Error type: ${e.runtimeType}');
      if (e.toString().contains('permission')) {
        AppLogger.error('Permission error details: $e');
        AppLogger.info('User ID: $userId');
        AppLogger.info('Post ID: $postId');
      }
      return null;
    }
  }

  // Get comments for a post
  Future<List<CommentModel>> getComments(
    String postId, {
    int limit = 50,
    String? lastCommentId,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt', descending: false) // Oldest first
          .limit(limit);

      if (lastCommentId != null) {
        final lastDocSnapshot = await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(lastCommentId)
            .get();
        query = query.startAfterDocument(lastDocSnapshot);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .where(
            (comment) => comment.parentCommentId.isEmpty,
          ) // Filter top-level comments
          .toList();
    } catch (e) {
      AppLogger.error('Error getting comments: $e');
      return [];
    }
  }

  // Get replies to a comment
  Future<List<CommentModel>> getReplies(
    String postId,
    String commentId, {
    int limit = 50,
    String? lastReplyId,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .where('parentCommentId', isEqualTo: commentId)
          .orderBy('createdAt', descending: false) // Oldest first
          .limit(limit);

      if (lastReplyId != null) {
        final lastDocSnapshot = await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(lastReplyId)
            .get();
        query = query.startAfterDocument(lastDocSnapshot);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting replies: $e');
      return [];
    }
  }

  // Get unread posts count for the current user
  Stream<int> getUnreadPostsCount(String userId) {
    try {
      return _firestore
          .collection('user_activity')
          .doc(userId)
          .snapshots()
          .asyncMap((doc) async {
            if (!doc.exists) {
              // If no user activity doc exists, count all posts as unread
              final postsSnapshot = await _firestore
                  .collection('posts')
                  .where('isPublic', isEqualTo: true)
                  .get();
              return postsSnapshot.docs.length;
            }

            final data = doc.data()!;
            final lastSeenTimestamp = data['lastCommunityVisit'] as Timestamp?;

            if (lastSeenTimestamp == null) {
              // If never visited, count all posts as unread
              final postsSnapshot = await _firestore
                  .collection('posts')
                  .where('isPublic', isEqualTo: true)
                  .get();
              return postsSnapshot.docs.length;
            }

            // Count posts created after last visit
            final unreadPostsSnapshot = await _firestore
                .collection('posts')
                .where('isPublic', isEqualTo: true)
                .where('createdAt', isGreaterThan: lastSeenTimestamp)
                .get();

            return unreadPostsSnapshot.docs.length;
          });
    } catch (e) {
      AppLogger.error('Error getting unread posts count: $e');
      return Stream.value(0);
    }
  }

  // Mark community as visited (reset unread count)
  Future<void> markCommunityAsVisited(String userId) async {
    try {
      await _firestore.collection('user_activity').doc(userId).set({
        'lastCommunityVisit': FieldValue.serverTimestamp(),
        'userId': userId,
      }, SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('Error marking community as visited: $e');
    }
  }

  // Toggle like for a post
  Future<bool> toggleLike(String postId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        AppLogger.error('User not authenticated for like action');
        return false;
      }

      // Reference to the post document
      final postRef = _firestore.collection('posts').doc(postId);

      // Reference to the user's like document
      final likeRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId);

      // Use a transaction to ensure consistency
      return await _firestore.runTransaction<bool>((transaction) async {
        // Check if user has already liked this post
        final likeDoc = await transaction.get(likeRef);
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final postData = postDoc.data() as Map<String, dynamic>;
        final currentLikeCount =
            (postData['engagementStats']?['likeCount'] ?? 0) as int;

        if (likeDoc.exists) {
          // User has liked - remove like
          transaction.delete(likeRef);
          transaction.update(postRef, {
            'engagementStats.likeCount': currentLikeCount > 0
                ? currentLikeCount - 1
                : 0,
            'engagementStats.lastUpdated': FieldValue.serverTimestamp(),
          });
          AppLogger.info('Removed like for post $postId by user $userId');
          return true; // Changed from false to true - operation succeeded
        } else {
          // User hasn't liked - add like
          transaction.set(likeRef, {
            'userId': userId,
            'likedAt': FieldValue.serverTimestamp(),
          });
          transaction.update(postRef, {
            'engagementStats.likeCount': currentLikeCount + 1,
            'engagementStats.lastUpdated': FieldValue.serverTimestamp(),
          });
          AppLogger.info('Added like for post $postId by user $userId');
          return true; // true = liked
        }
      });
    } catch (e) {
      AppLogger.error('Error toggling like for post $postId: $e');
      return false;
    }
  }

  // Check if current user has liked a post
  Future<bool> hasUserLikedPost(String postId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;

      final likeDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .get();

      return likeDoc.exists;
    } catch (e) {
      AppLogger.error('Error checking if user liked post $postId: $e');
      return false;
    }
  }

  // Get users who liked a post
  Future<List<String>> getPostLikes(String postId) async {
    try {
      final likesSnapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .get();

      return likesSnapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();
    } catch (e) {
      AppLogger.error('Error getting likes for post $postId: $e');
      return [];
    }
  }
}
