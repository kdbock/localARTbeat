import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recent_activity_model.dart';

/// Service for recent activity operations
class RecentActivityService {
  final FirebaseFirestore _firestore;

  RecentActivityService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get recent activities
  Future<List<RecentActivityModel>> getRecentActivities({
    int limit = 50,
    ActivityType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('recent_activities')
          .orderBy('timestamp', descending: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => RecentActivityModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent activities: $e');
    }
  }

  /// Create a new activity entry
  Future<void> createActivity({
    required ActivityType type,
    required String title,
    required String description,
    String? userId,
    String? userName,
    String? targetId,
    String? targetType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final activity = RecentActivityModel(
        id: '',
        type: type,
        title: title,
        description: description,
        userId: userId,
        userName: userName,
        targetId: targetId,
        targetType: targetType,
        timestamp: DateTime.now(),
        metadata: metadata ?? {},
      );

      await _firestore
          .collection('recent_activities')
          .add(activity.toDocument());
    } catch (e) {
      throw Exception('Failed to create activity: $e');
    }
  }

  /// Log user registration activity
  Future<void> logUserRegistration(String userId, String userName) async {
    await createActivity(
      type: ActivityType.userRegistered,
      title: 'New User Registration',
      description: '$userName joined the platform',
      userId: userId,
      userName: userName,
    );
  }

  /// Log user login activity
  Future<void> logUserLogin(String userId, String userName) async {
    await createActivity(
      type: ActivityType.userLogin,
      title: 'User Login',
      description: '$userName logged in',
      userId: userId,
      userName: userName,
    );
  }

  /// Log artwork upload activity
  Future<void> logArtworkUpload(String userId, String userName,
      String artworkId, String artworkTitle) async {
    await createActivity(
      type: ActivityType.artworkUploaded,
      title: 'Artwork Uploaded',
      description: '$userName uploaded "$artworkTitle"',
      userId: userId,
      userName: userName,
      targetId: artworkId,
      targetType: 'artwork',
    );
  }

  /// Log artwork approval activity
  Future<void> logArtworkApproval(
      String artworkId, String artworkTitle, String reviewerId) async {
    await createActivity(
      type: ActivityType.artworkApproved,
      title: 'Artwork Approved',
      description: 'Artwork "$artworkTitle" was approved',
      userId: reviewerId,
      targetId: artworkId,
      targetType: 'artwork',
    );
  }

  /// Log artwork rejection activity
  Future<void> logArtworkRejection(String artworkId, String artworkTitle,
      String reviewerId, String reason) async {
    await createActivity(
      type: ActivityType.artworkRejected,
      title: 'Artwork Rejected',
      description: 'Artwork "$artworkTitle" was rejected',
      userId: reviewerId,
      targetId: artworkId,
      targetType: 'artwork',
      metadata: {'reason': reason},
    );
  }

  /// Log post creation activity
  Future<void> logPostCreation(
      String userId, String userName, String postId) async {
    await createActivity(
      type: ActivityType.postCreated,
      title: 'Post Created',
      description: '$userName created a new post',
      userId: userId,
      userName: userName,
      targetId: postId,
      targetType: 'post',
    );
  }

  /// Log comment activity
  Future<void> logComment(String userId, String userName, String targetId,
      String targetType) async {
    await createActivity(
      type: ActivityType.commentAdded,
      title: 'Comment Added',
      description: '$userName commented on a $targetType',
      userId: userId,
      userName: userName,
      targetId: targetId,
      targetType: targetType,
    );
  }

  /// Log event creation activity
  Future<void> logEventCreation(
      String userId, String userName, String eventId, String eventTitle) async {
    await createActivity(
      type: ActivityType.eventCreated,
      title: 'Event Created',
      description: '$userName created event "$eventTitle"',
      userId: userId,
      userName: userName,
      targetId: eventId,
      targetType: 'event',
    );
  }

  /// Log user suspension activity
  Future<void> logUserSuspension(
      String userId, String userName, String suspendedBy, String reason) async {
    await createActivity(
      type: ActivityType.userSuspended,
      title: 'User Suspended',
      description: '$userName was suspended',
      userId: suspendedBy,
      targetId: userId,
      targetType: 'user',
      metadata: {'reason': reason, 'suspendedUser': userName},
    );
  }

  /// Log user verification activity
  Future<void> logUserVerification(
      String userId, String userName, String verifiedBy) async {
    await createActivity(
      type: ActivityType.userVerified,
      title: 'User Verified',
      description: '$userName was verified',
      userId: verifiedBy,
      targetId: userId,
      targetType: 'user',
      metadata: {'verifiedUser': userName},
    );
  }

  /// Log content report activity
  Future<void> logContentReport(String reporterId, String reporterName,
      String contentId, String contentType) async {
    await createActivity(
      type: ActivityType.contentReported,
      title: 'Content Reported',
      description: '$reporterName reported $contentType content',
      userId: reporterId,
      userName: reporterName,
      targetId: contentId,
      targetType: contentType,
    );
  }

  /// Log system error activity
  Future<void> logSystemError(String errorMessage,
      {Map<String, dynamic>? errorDetails}) async {
    await createActivity(
      type: ActivityType.systemError,
      title: 'System Error',
      description: errorMessage,
      metadata: errorDetails ?? {},
    );
  }

  /// Log admin action activity
  Future<void> logAdminAction(String adminId, String adminName, String action,
      String description) async {
    await createActivity(
      type: ActivityType.adminAction,
      title: 'Admin Action',
      description: '$adminName performed: $description',
      userId: adminId,
      userName: adminName,
      metadata: {'action': action},
    );
  }

  /// Get activities by user
  Future<List<RecentActivityModel>> getActivitiesByUser(String userId,
      {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('recent_activities')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => RecentActivityModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get activities by user: $e');
    }
  }

  /// Get activities by type
  Future<List<RecentActivityModel>> getActivitiesByType(ActivityType type,
      {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('recent_activities')
          .where('type', isEqualTo: type.name)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => RecentActivityModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get activities by type: $e');
    }
  }

  /// Get activity statistics
  Future<Map<String, int>> getActivityStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('recent_activities');

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      final activities = snapshot.docs
          .map((doc) => RecentActivityModel.fromDocument(doc))
          .toList();

      final stats = <String, int>{};

      for (final type in ActivityType.values) {
        stats[type.name] = 0;
      }

      for (final activity in activities) {
        stats[activity.type.name] = (stats[activity.type.name] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get activity stats: $e');
    }
  }

  /// Clean up old activities
  Future<void> cleanupOldActivities({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final snapshot = await _firestore
          .collection('recent_activities')
          .where('timestamp', isLessThan: cutoffDate)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to cleanup old activities: $e');
    }
  }

  /// Get activity by ID
  Future<RecentActivityModel?> getActivityById(String id) async {
    try {
      final doc =
          await _firestore.collection('recent_activities').doc(id).get();
      if (doc.exists) {
        return RecentActivityModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get activity: $e');
    }
  }

  /// Delete activity
  Future<void> deleteActivity(String id) async {
    try {
      await _firestore.collection('recent_activities').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete activity: $e');
    }
  }

  /// Stream recent activities (for real-time updates)
  Stream<List<RecentActivityModel>> streamRecentActivities({
    int limit = 20,
    ActivityType? type,
  }) {
    try {
      Query query = _firestore
          .collection('recent_activities')
          .orderBy('timestamp', descending: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      query = query.limit(limit);

      return query.snapshots().map((snapshot) => snapshot.docs
          .map((doc) => RecentActivityModel.fromDocument(doc))
          .toList());
    } catch (e) {
      throw Exception('Failed to stream recent activities: $e');
    }
  }
}
