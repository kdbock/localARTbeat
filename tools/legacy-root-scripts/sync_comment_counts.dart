import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Script to sync comment counts on all posts
Future<void> syncCommentCounts() async {
  final firestore = FirebaseFirestore.instance;

  if (kDebugMode) {
    print('🔄 Starting comment count synchronization...');
  }

  try {
    // Get all posts
    final postsSnapshot = await firestore.collection('posts').get();

    if (kDebugMode) {
      print('📊 Found ${postsSnapshot.docs.length} posts to check');
    }

    int updatedCount = 0;

    for (final postDoc in postsSnapshot.docs) {
      final postId = postDoc.id;
      final postData = postDoc.data();

      // Count actual comments for this post
      final commentsSnapshot = await firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .get();

      final actualCommentCount = commentsSnapshot.docs.length;

      // Get current comment count from engagement stats
      final engagementStats =
          postData['engagementStats'] as Map<String, dynamic>? ?? {};
      final currentCommentCount = engagementStats['commentCount'] as int? ?? 0;

      if (kDebugMode) {
        print(
          '📝 Post $postId: actual=$actualCommentCount, stored=$currentCommentCount',
        );
      }

      // If they don't match, update the post
      if (actualCommentCount != currentCommentCount) {
        await firestore.collection('posts').doc(postId).update({
          'engagementStats.commentCount': actualCommentCount,
          'engagementStats.lastUpdated': FieldValue.serverTimestamp(),
        });

        updatedCount++;
        if (kDebugMode) {
          print(
            '✅ Updated post $postId: $currentCommentCount → $actualCommentCount',
          );
        }
      }
    }

    if (kDebugMode) {
      print('🎉 Synchronization complete! Updated $updatedCount posts.');
    }
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error during synchronization: $e');
    }
  }
}
