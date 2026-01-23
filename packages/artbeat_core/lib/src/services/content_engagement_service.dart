import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/engagement_model.dart';
import 'engagement_config_service.dart';
import '../utils/logger.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

/// Content-specific engagement service for ARTbeat content types
/// Replaces UniversalEngagementService with content-specific engagement handling
class ContentEngagementService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Toggle engagement for any content type
  Future<bool> toggleEngagement({
    required String contentId,
    required String contentType,
    required EngagementType engagementType,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to engage with content');
    }

    // Validate engagement type is allowed for content type
    if (!EngagementConfigService.isEngagementTypeAvailable(
      contentType,
      engagementType,
    )) {
      throw Exception(
        'Engagement type ${engagementType.value} not available for content type $contentType',
      );
    }

    try {
      final engagementRef = _firestore
          .collection('engagements')
          .doc('${contentId}_${user.uid}_${engagementType.value}');

      final contentRef = _firestore
          .collection(_getCollectionName(contentType))
          .doc(contentId);

      final engagementDoc = await engagementRef.get();
      final isCurrentlyEngaged = engagementDoc.exists;

      await _firestore.runTransaction((transaction) async {
        final contentSnapshot = await transaction.get(contentRef);
        if (!contentSnapshot.exists) {
          throw Exception('Content not found');
        }

        final contentData = contentSnapshot.data() as Map<String, dynamic>;
        final currentStats = EngagementStats.fromFirestore(
          contentData['engagementStats'] as Map<String, dynamic>? ??
              contentData,
        );

        if (isCurrentlyEngaged) {
          // Remove engagement
          transaction.delete(engagementRef);

          // Update content stats
          final newStats = _decrementStat(currentStats, engagementType);
          transaction.update(contentRef, {
            'engagementStats': newStats.toFirestore(),
          });
        } else {
          // Add engagement
          final engagement = EngagementModel(
            id: engagementRef.id,
            contentId: contentId,
            contentType: contentType,
            userId: user.uid,
            type: engagementType,
            createdAt: DateTime.now(),
            metadata: metadata,
          );

          transaction.set(engagementRef, engagement.toFirestore());

          // Update content stats
          final newStats = _incrementStat(currentStats, engagementType);
          transaction.update(contentRef, {
            'engagementStats': newStats.toFirestore(),
          });

          // Create notification for content owner (except for own content)
          final contentOwnerId = contentSnapshot.data()?['userId'] as String?;
          if (contentOwnerId != null && contentOwnerId != user.uid) {
            await _createEngagementNotification(
              contentId: contentId,
              contentType: contentType,
              engagementType: engagementType,
              fromUserId: user.uid,
              toUserId: contentOwnerId,
            );
          }
        }
      });

      notifyListeners();
      return !isCurrentlyEngaged; // Return new engagement state
    } catch (e) {
      AppLogger.error('Error toggling engagement: $e');
      rethrow;
    }
  }

  /// Check if user has engaged with content
  Future<bool> hasUserEngaged({
    required String contentId,
    required EngagementType engagementType,
    String? userId,
  }) async {
    final targetUserId = userId ?? _auth.currentUser?.uid;
    if (targetUserId == null) return false;

    try {
      final engagementRef = _firestore
          .collection('engagements')
          .doc('${contentId}_${targetUserId}_${engagementType.value}');

      final doc = await engagementRef.get();
      return doc.exists;
    } catch (e) {
      AppLogger.error('Error checking engagement: $e');
      return false;
    }
  }

  /// Get engagement stats for content
  Future<EngagementStats> getEngagementStats({
    required String contentId,
    required String contentType,
  }) async {
    try {
      final contentRef = _firestore
          .collection(_getCollectionName(contentType))
          .doc(contentId);

      final doc = await contentRef.get();
      if (!doc.exists) {
        return EngagementStats(lastUpdated: DateTime.now());
      }

      final data = doc.data() as Map<String, dynamic>;
      return EngagementStats.fromFirestore(
        data['engagementStats'] as Map<String, dynamic>? ?? data,
      );
    } catch (e) {
      AppLogger.error('Error getting engagement stats: $e');
      return EngagementStats(lastUpdated: DateTime.now());
    }
  }

  /// Get users who engaged with content
  Future<List<EngagementModel>> getEngagements({
    required String contentId,
    required EngagementType engagementType,
    int limit = 50,
  }) async {
    try {
      final query = _firestore
          .collection('engagements')
          .where('contentId', isEqualTo: contentId)
          .where('type', isEqualTo: engagementType.value)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => EngagementModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting engagements: $e');
      return [];
    }
  }

  /// Track 'seen' engagement automatically
  Future<void> trackSeenEngagement({
    required String contentId,
    required String contentType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Only track if 'seen' is available for this content type
    if (!EngagementConfigService.isEngagementTypeAvailable(
      contentType,
      EngagementType.seen,
    )) {
      return;
    }

    try {
      final engagementRef = _firestore
          .collection('engagements')
          .doc('${contentId}_${user.uid}_seen');

      // Check if already seen
      final existingDoc = await engagementRef.get();
      if (existingDoc.exists) return;

      final contentRef = _firestore
          .collection(_getCollectionName(contentType))
          .doc(contentId);

      await _firestore.runTransaction((transaction) async {
        final contentSnapshot = await transaction.get(contentRef);
        if (!contentSnapshot.exists) return;

        final contentData = contentSnapshot.data() as Map<String, dynamic>;
        final currentStats = EngagementStats.fromFirestore(
          contentData['engagementStats'] as Map<String, dynamic>? ??
              contentData,
        );

        // Create seen engagement
        final engagement = EngagementModel(
          id: engagementRef.id,
          contentId: contentId,
          contentType: contentType,
          userId: user.uid,
          type: EngagementType.seen,
          createdAt: DateTime.now(),
        );

        transaction.set(engagementRef, engagement.toFirestore());

        // Update content stats
        final newStats = currentStats.copyWith(
          seenCount: currentStats.seenCount + 1,
          lastUpdated: DateTime.now(),
        );
        transaction.update(contentRef, {
          'engagementStats': newStats.toFirestore(),
        });
      });
    } catch (e) {
      AppLogger.error('Error tracking seen engagement: $e');
      // Don't throw - seen tracking is not critical
    }
  }

  /// Get user's followers (people who follow them)
  Future<List<String>> getUserFollowers(String userId) async {
    try {
      final query = _firestore
          .collection('engagements')
          .where('contentId', isEqualTo: userId)
          .where('type', isEqualTo: EngagementType.follow.value)
          .where('contentType', isEqualTo: 'profile');

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();
    } catch (e) {
      AppLogger.error('Error getting user followers: $e');
      return [];
    }
  }

  /// Get user's following (people they follow)
  Future<List<String>> getUserFollowing(String userId) async {
    try {
      final query = _firestore
          .collection('engagements')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: EngagementType.follow.value)
          .where('contentType', isEqualTo: 'profile');

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data()['contentId'] as String)
          .toList();
    } catch (e) {
      AppLogger.error('Error getting user following: $e');
      return [];
    }
  }

  /// Private helper methods

  String _getCollectionName(String contentType) {
    switch (contentType) {
      case 'post':
        return 'posts';
      case 'artwork':
        return 'artwork';
      case 'capture':
        return 'captures'; // Assuming captures have their own collection
      case 'art_walk':
        return 'artWalks';
      case 'event':
        return 'events';
      case 'profile':
      case 'artist':
        return 'users';
      case 'comment':
        return 'comments';
      default:
        throw Exception('Unknown content type: $contentType');
    }
  }

  EngagementStats _incrementStat(EngagementStats stats, EngagementType type) {
    switch (type) {
      case EngagementType.like:
        return stats.copyWith(
          likeCount: stats.likeCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.comment:
        return stats.copyWith(
          commentCount: stats.commentCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.reply:
        return stats.copyWith(
          replyCount: stats.replyCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.share:
        return stats.copyWith(
          shareCount: stats.shareCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.seen:
        return stats.copyWith(
          seenCount: stats.seenCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.rate:
        return stats.copyWith(
          rateCount: stats.rateCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.review:
        return stats.copyWith(
          reviewCount: stats.reviewCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.follow:
        return stats.copyWith(
          followCount: stats.followCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.boost:
        return stats.copyWith(
          boostCount: stats.boostCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.sponsor:
        return stats.copyWith(
          sponsorCount: stats.sponsorCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.message:
        return stats.copyWith(
          messageCount: stats.messageCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.commission:
        return stats.copyWith(
          commissionCount: stats.commissionCount + 1,
          lastUpdated: DateTime.now(),
        );
    }
  }

  EngagementStats _decrementStat(EngagementStats stats, EngagementType type) {
    switch (type) {
      case EngagementType.like:
        return stats.copyWith(
          likeCount: (stats.likeCount - 1).clamp(0, double.infinity).toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.comment:
        return stats.copyWith(
          commentCount: (stats.commentCount - 1)
              .clamp(0, double.infinity)
              .toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.reply:
        return stats.copyWith(
          replyCount: (stats.replyCount - 1).clamp(0, double.infinity).toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.share:
        return stats.copyWith(
          shareCount: (stats.shareCount - 1).clamp(0, double.infinity).toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.seen:
        return stats.copyWith(
          seenCount: (stats.seenCount - 1).clamp(0, double.infinity).toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.rate:
        return stats.copyWith(
          rateCount: (stats.rateCount - 1).clamp(0, double.infinity).toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.review:
        return stats.copyWith(
          reviewCount: (stats.reviewCount - 1)
              .clamp(0, double.infinity)
              .toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.follow:
        return stats.copyWith(
          followCount: (stats.followCount - 1)
              .clamp(0, double.infinity)
              .toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.boost:
        return stats.copyWith(
          boostCount: (stats.boostCount - 1).clamp(0, double.infinity).toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.sponsor:
        return stats.copyWith(
          sponsorCount: (stats.sponsorCount - 1)
              .clamp(0, double.infinity)
              .toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.message:
        return stats.copyWith(
          messageCount: (stats.messageCount - 1)
              .clamp(0, double.infinity)
              .toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.commission:
        return stats.copyWith(
          commissionCount: (stats.commissionCount - 1)
              .clamp(0, double.infinity)
              .toInt(),
          lastUpdated: DateTime.now(),
        );
    }
  }

  Future<void> _createEngagementNotification({
    required String contentId,
    required String contentType,
    required EngagementType engagementType,
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'type': 'engagement',
        'contentId': contentId,
        'contentType': contentType,
        'engagementType': engagementType.value,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'message': 'Someone ${engagementType.pastTense} your $contentType',
      });
    } catch (e) {
      AppLogger.error('Error creating engagement notification: $e');
      // Don't throw - notifications are not critical
    }
  }

  /// Get all ratings for a specific content
  Future<List<Map<String, dynamic>>> getRatings({
    required String contentId,
    required String contentType,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('engagements')
          .where('contentId', isEqualTo: contentId)
          .where('contentType', isEqualTo: contentType)
          .where('type', isEqualTo: 'rate')
          .orderBy('createdAt', descending: true)
          .get();

      final ratings = <Map<String, dynamic>>[];
      for (final doc in querySnapshot.docs) {
        final engagement = EngagementModel.fromFirestore(doc);

        // Get user info
        final userDoc = await _firestore
            .collection('users')
            .doc(engagement.userId)
            .get();

        final userData = userDoc.data();

        ratings.add({
          'rating': engagement.metadata?['rating'] ?? 0,
          'userId': engagement.userId,
          'userName':
              userData?['fullName'] ?? userData?['displayName'] ?? 'Anonymous',
          'userProfileImage': userData?['profileImageUrl'],
          'createdAt': engagement.createdAt,
        });
      }

      return ratings;
    } catch (e) {
      AppLogger.error('Error fetching ratings: $e');
      return [];
    }
  }

  /// Get all reviews for a specific content
  Future<List<Map<String, dynamic>>> getReviews({
    required String contentId,
    required String contentType,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('engagements')
          .where('contentId', isEqualTo: contentId)
          .where('contentType', isEqualTo: contentType)
          .where('type', isEqualTo: 'review')
          .orderBy('createdAt', descending: true)
          .get();

      final reviews = <Map<String, dynamic>>[];
      for (final doc in querySnapshot.docs) {
        final engagement = EngagementModel.fromFirestore(doc);

        // Get user info
        final userDoc = await _firestore
            .collection('users')
            .doc(engagement.userId)
            .get();

        final userData = userDoc.data();

        reviews.add({
          'review': engagement.metadata?['review'] ?? '',
          'userId': engagement.userId,
          'userName':
              userData?['fullName'] ?? userData?['displayName'] ?? 'Anonymous',
          'userProfileImage': userData?['profileImageUrl'],
          'createdAt': engagement.createdAt,
        });
      }

      return reviews;
    } catch (e) {
      AppLogger.error('Error fetching reviews: $e');
      return [];
    }
  }

  /// Get average rating for content
  Future<double> getAverageRating({
    required String contentId,
    required String contentType,
  }) async {
    try {
      final ratings = await getRatings(
        contentId: contentId,
        contentType: contentType,
      );

      if (ratings.isEmpty) return 0.0;

      final sum = ratings.fold<double>(
        0.0,
        (previous, rating) => previous + (rating['rating'] as int).toDouble(),
      );

      return sum / ratings.length;
    } catch (e) {
      AppLogger.error('Error calculating average rating: $e');
      return 0.0;
    }
  }

  // ========================================
  // INDIVIDUAL SOCIAL METHODS (Convenience Wrappers)
  // ========================================

  /// Like content (convenience wrapper around toggleEngagement)
  Future<bool> likeContent(String contentId, String contentType) async {
    return toggleEngagement(
      contentId: contentId,
      contentType: contentType,
      engagementType: EngagementType.like,
    );
  }

  /// Unlike content (convenience wrapper around toggleEngagement)
  Future<bool> unlikeContent(String contentId, String contentType) async {
    // toggleEngagement handles both like and unlike based on current state
    return toggleEngagement(
      contentId: contentId,
      contentType: contentType,
      engagementType: EngagementType.like,
    );
  }

  /// Add comment to content
  Future<String> addComment({
    required String contentId,
    required String contentType,
    required String comment,
    String? parentCommentId,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to comment');
    }

    try {
      // Create comment document
      final commentData = {
        'contentId': contentId,
        'contentType': contentType,
        'userId': user.uid,
        'comment': comment,
        'parentCommentId': parentCommentId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isDeleted': false,
        'likeCount': 0,
        'replyCount': 0,
        'metadata': metadata ?? {},
      };

      final commentRef = await _firestore
          .collection('comments')
          .add(commentData);

      // Update engagement stats using toggleEngagement
      await toggleEngagement(
        contentId: contentId,
        contentType: contentType,
        engagementType: EngagementType.comment,
        metadata: {
          'commentId': commentRef.id,
          'comment': comment,
          'parentCommentId': parentCommentId,
        },
      );

      // Track comment for challenge progress
      try {
        final challengeService = ChallengeService();
        await challengeService.recordComment();
      } catch (e) {
        AppLogger.error('Error recording comment to challenge: $e');
      }

      return commentRef.id;
    } catch (e) {
      AppLogger.error('Error adding comment: $e');
      rethrow;
    }
  }

  /// Share content to external platforms or within the app
  Future<bool> shareContent({
    required String contentId,
    required String contentType,
    String? platform,
    String? message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Track share engagement
      await toggleEngagement(
        contentId: contentId,
        contentType: contentType,
        engagementType: EngagementType.share,
        metadata: {
          'platform': platform ?? 'internal',
          'message': message,
          'sharedAt': DateTime.now().toIso8601String(),
          ...?metadata,
        },
      );

      // Here you would implement actual sharing logic based on platform
      // For now, we'll just track the engagement
      AppLogger.info('Content shared: $contentId to ${platform ?? 'internal'}');

      // Track share for challenge progress
      try {
        final challengeService = ChallengeService();
        await challengeService.recordSocialShare();
      } catch (e) {
        AppLogger.error('Error recording share to challenge: $e');
      }

      return true;
    } catch (e) {
      AppLogger.error('Error sharing content: $e');
      return false;
    }
  }

  /// Get comments for specific content
  Future<List<Map<String, dynamic>>> getComments({
    required String contentId,
    required String contentType,
    String? parentCommentId,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('comments')
          .where('contentId', isEqualTo: contentId)
          .where('contentType', isEqualTo: contentType)
          .where('isDeleted', isEqualTo: false);

      if (parentCommentId != null) {
        query = query.where('parentCommentId', isEqualTo: parentCommentId);
      } else {
        query = query.where('parentCommentId', isNull: true);
      }

      final querySnapshot = await query
          .orderBy('createdAt', descending: false)
          .limit(limit)
          .get();

      final comments = <Map<String, dynamic>>[];
      for (final doc in querySnapshot.docs) {
        final commentData = doc.data() as Map<String, dynamic>;

        // Get user info
        final userDoc = await _firestore
            .collection('users')
            .doc(commentData['userId'] as String)
            .get();

        final userData = userDoc.data();

        comments.add(<String, dynamic>{
          'id': doc.id,
          'comment': commentData['comment'],
          'userId': commentData['userId'],
          'userName':
              userData?['fullName'] ?? userData?['displayName'] ?? 'Anonymous',
          'userProfileImage': userData?['profileImageUrl'],
          'createdAt': commentData['createdAt'],
          'likeCount': commentData['likeCount'] ?? 0,
          'replyCount': commentData['replyCount'] ?? 0,
          'parentCommentId': commentData['parentCommentId'],
          'metadata': commentData['metadata'] ?? <String, dynamic>{},
        });
      }

      return comments;
    } catch (e) {
      AppLogger.error('Error fetching comments: $e');
      return [];
    }
  }

  /// Delete comment (soft delete)
  Future<bool> deleteComment(String commentId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to delete comments');
    }

    try {
      final commentDoc = await _firestore
          .collection('comments')
          .doc(commentId)
          .get();
      if (!commentDoc.exists) {
        throw Exception('Comment not found');
      }

      final commentData = commentDoc.data() as Map<String, dynamic>;

      // Check if user owns the comment
      if (commentData['userId'] != user.uid) {
        throw Exception('Not authorized to delete this comment');
      }

      // Soft delete the comment
      await _firestore.collection('comments').doc(commentId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      AppLogger.error('Error deleting comment: $e');
      return false;
    }
  }

  /// Check if user has liked specific content
  Future<bool> hasUserLiked(String contentId, String contentType) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final engagementDoc = await _firestore
          .collection('engagements')
          .doc('${contentId}_${user.uid}_like')
          .get();

      return engagementDoc.exists;
    } catch (e) {
      AppLogger.error('Error checking like status: $e');
      return false;
    }
  }

  /// Get user's engagement with specific content
  Future<Map<String, bool>> getUserEngagementStatus({
    required String contentId,
    required String contentType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'liked': false,
        'shared': false,
        'commented': false,
        'followed': false,
      };
    }

    try {
      final engagementTypes = ['like', 'share', 'comment', 'follow'];
      final engagementStatus = <String, bool>{};

      for (final type in engagementTypes) {
        final engagementDoc = await _firestore
            .collection('engagements')
            .doc('${contentId}_${user.uid}_$type')
            .get();

        engagementStatus['${type}d'] = engagementDoc.exists;
      }

      return engagementStatus;
    } catch (e) {
      AppLogger.error('Error getting user engagement status: $e');
      return {
        'liked': false,
        'shared': false,
        'commented': false,
        'followed': false,
      };
    }
  }
}
