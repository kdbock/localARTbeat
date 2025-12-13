import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/profile_activity_model.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Service for managing profile activity tracking
class ProfileActivityService extends ChangeNotifier {
  static final ProfileActivityService _instance =
      ProfileActivityService._internal();
  factory ProfileActivityService() => _instance;
  ProfileActivityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _activityCollection =>
      _firestore.collection('profile_activities');

  /// Record a new profile activity
  Future<void> recordActivity({
    required String userId,
    required String activityType,
    String? targetUserId,
    String? targetUserName,
    String? targetUserAvatar,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final activity = ProfileActivityModel(
        id: '', // Firestore will generate ID
        userId: userId,
        activityType: activityType,
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        targetUserAvatar: targetUserAvatar,
        description: description,
        metadata: metadata,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await _activityCollection.add(activity.toFirestore());
    } catch (e) {
      AppLogger.error('Error recording activity: $e');
    }
  }

  /// Get activities for a user's profile
  Future<List<ProfileActivityModel>> getProfileActivities(
    String userId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
    bool unreadOnly = false,
  }) async {
    try {
      // Build query with all where clauses before orderBy
      Query query = _activityCollection.where('userId', isEqualTo: userId);

      if (unreadOnly) {
        query = query.where('isRead', isEqualTo: false);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ProfileActivityModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting profile activities: $e');
      return [];
    }
  }

  /// Get unread activity count
  Future<int> getUnreadActivityCount(String userId) async {
    try {
      final snapshot = await _activityCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark activities as read
  Future<void> markActivitiesAsRead(List<String> activityIds) async {
    try {
      final batch = _firestore.batch();

      for (final id in activityIds) {
        batch.update(_activityCollection.doc(id), {'isRead': true});
      }

      await batch.commit();
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error marking activities as read: $e');
    }
  }

  /// Mark all activities as read for a user
  Future<void> markAllActivitiesAsRead(String userId) async {
    try {
      final snapshot = await _activityCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();

        for (final doc in snapshot.docs) {
          batch.update(doc.reference, {'isRead': true});
        }

        await batch.commit();
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Error marking all activities as read: $e');
    }
  }

  /// Delete old activities (cleanup)
  Future<void> deleteOldActivities(String userId, {int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final snapshot = await _activityCollection
          .where('userId', isEqualTo: userId)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();

        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }
    } catch (e) {
      AppLogger.error('Error deleting old activities: $e');
    }
  }

  /// Stream of real-time activities
  Stream<List<ProfileActivityModel>> streamProfileActivities(
    String userId, {
    int limit = 20,
    bool unreadOnly = false,
  }) {
    try {
      // Build query with all where clauses before orderBy
      Query query = _activityCollection.where('userId', isEqualTo: userId);

      if (unreadOnly) {
        query = query.where('isRead', isEqualTo: false);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      return query.snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => ProfileActivityModel.fromFirestore(doc))
            .toList(),
      );
    } catch (e) {
      AppLogger.error('Error streaming activities: $e');
      return Stream.value([]);
    }
  }

  // Convenience methods for common activities
  Future<void> recordProfileView(
    String viewedUserId,
    String viewerUserId,
    String viewerName,
    String? viewerAvatar,
  ) async {
    await recordActivity(
      userId: viewedUserId,
      activityType: 'profile_view',
      targetUserId: viewerUserId,
      targetUserName: viewerName,
      targetUserAvatar: viewerAvatar,
      description: '$viewerName viewed your profile',
    );
  }

  Future<void> recordFollow(
    String followedUserId,
    String followerUserId,
    String followerName,
    String? followerAvatar,
  ) async {
    await recordActivity(
      userId: followedUserId,
      activityType: 'follow',
      targetUserId: followerUserId,
      targetUserName: followerName,
      targetUserAvatar: followerAvatar,
      description: '$followerName started following you',
    );
  }

  Future<void> recordUnfollow(
    String unfollowedUserId,
    String unfollowerUserId,
    String unfollowerName,
    String? unfollowerAvatar,
  ) async {
    await recordActivity(
      userId: unfollowedUserId,
      activityType: 'unfollow',
      targetUserId: unfollowerUserId,
      targetUserName: unfollowerName,
      targetUserAvatar: unfollowerAvatar,
      description: '$unfollowerName unfollowed you',
    );
  }

  @override
  void dispose() {
    // Singleton pattern - don't dispose
    super.dispose();
  }
}
