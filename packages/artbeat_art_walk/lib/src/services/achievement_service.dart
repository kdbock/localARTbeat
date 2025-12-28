import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:artbeat_art_walk/src/models/achievement_model.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show NotificationService, NotificationType;

/// Service for managing user achievements
class AchievementService {
  FirebaseFirestore? _firestoreInstance;
  FirebaseAuth? _authInstance;

  // Lazy initialization getters
  FirebaseFirestore get _firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authInstance ??= FirebaseAuth.instance;

  final Logger _logger = Logger();
  final NotificationService _notificationService = NotificationService();

  /// Get the current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get all achievements for the current user
  Future<List<AchievementModel>> getUserAchievements({String? userId}) async {
    try {
      final uid = userId ?? getCurrentUserId();
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      final achievementsSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('achievements')
          .get();

      return achievementsSnapshot.docs
          .map((doc) => AchievementModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Error getting user achievements: $e');
      return [];
    }
  }

  /// Get achievements of a specific type for the current user
  Future<List<AchievementModel>> getUserAchievementsByType(
    AchievementType type, {
    String? userId,
  }) async {
    try {
      final uid = userId ?? getCurrentUserId();
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      final achievementsSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('achievements')
          .where('type', isEqualTo: type.name)
          .get();

      return achievementsSnapshot.docs
          .map((doc) => AchievementModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Error getting user achievements by type: $e');
      return [];
    }
  }

  /// Get unviewed achievements for the current user
  Future<List<AchievementModel>> getUnviewedAchievements({
    String? userId,
  }) async {
    try {
      final uid = userId ?? getCurrentUserId();
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      final achievementsSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('achievements')
          .where('isNew', isEqualTo: true)
          .get();

      return achievementsSnapshot.docs
          .map((doc) => AchievementModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Error getting unviewed achievements: $e');
      return [];
    }
  }

  /// Mark an achievement as viewed
  Future<bool> markAchievementAsViewed(
    String achievementId, {
    String? userId,
  }) async {
    try {
      final uid = userId ?? getCurrentUserId();
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('achievements')
          .doc(achievementId)
          .update({'isNew': false});

      return true;
    } catch (e) {
      _logger.e('Error marking achievement as viewed: $e');
      return false;
    }
  }

  /// Award an achievement to a user
  Future<bool> awardAchievement(
    String userId,
    AchievementType type,
    Map<String, dynamic> metadata,
  ) async {
    try {
      // Check if user already has this achievement
      final existingQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .where('type', isEqualTo: type.name)
          .limit(1)
          .get();

      if (existingQuery.docs.isEmpty) {
        // Award the achievement
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('achievements')
            .add({
              'userId': userId,
              'type': type.name,
              'earnedAt': FieldValue.serverTimestamp(),
              'isNew': true,
              'metadata': metadata,
            });

        // Send notification to user about the new achievement
        await _sendAchievementNotification(userId, type, metadata);

        return true;
      }

      // Achievement already exists
      return false;
    } catch (e) {
      _logger.e('Error awarding achievement: $e');
      return false;
    }
  }

  /// Send notification to user about a new achievement
  Future<void> _sendAchievementNotification(
    String userId,
    AchievementType type,
    Map<String, dynamic> metadata,
  ) async {
    try {
      const String title = 'New Achievement Unlocked!';
      final String message = _getAchievementNotificationMessage(type, metadata);

      await _notificationService.sendNotification(
        userId: userId,
        title: title,
        message: message,
        type: NotificationType.achievement,
        data: {'achievementType': type.name, 'metadata': metadata},
      );
    } catch (e) {
      _logger.e('Error sending achievement notification: $e');
    }
  }

  /// Get the notification message for an achievement
  String _getAchievementNotificationMessage(
    AchievementType type,
    Map<String, dynamic> metadata,
  ) {
    switch (type) {
      case AchievementType.firstWalk:
        return 'Congratulations! You completed your first Art Walk!';
      case AchievementType.walkMaster:
        final walkCount = metadata['walkCount'] ?? 10;
        return 'Amazing! You\'ve completed $walkCount Art Walks!';
      case AchievementType.walkExplorer:
        return 'Walk Explorer badge earned! You\'ve discovered new walks!';
      case AchievementType.artCollector:
        return 'Art Collector achievement unlocked! Keep discovering great art!';
      case AchievementType.socialButterfly:
        return 'Social Butterfly earned! Thanks for connecting with the community!';
      case AchievementType.earlyAdopter:
        final eventName = metadata['eventName'] ?? 'early adoption program';
        return 'Early Adopter achievement! You were part of $eventName!';
      default:
        return 'Congratulations on your new achievement!';
    }
  }

  /// Check if user has completed a specific art walk
  Future<bool> hasCompletedArtWalk(String userId, String walkId) async {
    try {
      final completedWalkDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('completedWalks')
          .doc(walkId)
          .get();

      return completedWalkDoc.exists;
    } catch (e) {
      _logger.e('Error checking if user completed art walk: $e');
      return false;
    }
  }

  /// Get count of completed art walks for a user
  Future<int> getCompletedArtWalkCount(String userId) async {
    try {
      final completedWalks = await _firestore
          .collection('users')
          .doc(userId)
          .collection('completedWalks')
          .count()
          .get();

      return completedWalks.count ??
          0; // Make sure we handle null case by returning 0
    } catch (e) {
      _logger.e('Error getting completed art walk count: $e');
      return 0;
    }
  }

  /// Check for new achievements based on user actions
  Future<List<AchievementModel>> checkForNewAchievements({
    required String userId,
    bool walkCompleted = false,
    double distanceWalked = 0.0,
    int artPiecesVisited = 0,
  }) async {
    final newAchievements = <AchievementModel>[];

    try {
      // Check for walk completion achievements
      if (walkCompleted) {
        final completedWalks = await getCompletedArtWalkCount(userId);

        // First walk achievement
        if (completedWalks == 1) {
          final awarded = await awardAchievement(
            userId,
            AchievementType.firstWalk,
            {'completedWalks': completedWalks},
          );
          if (awarded) {
            final achievement = await getUserAchievementsByType(
              AchievementType.firstWalk,
              userId: userId,
            );
            newAchievements.addAll(achievement.where((a) => a.isNew));
          }
        }

        // Multiple walks achievements
        if (completedWalks == 5) {
          final awarded = await awardAchievement(
            userId,
            AchievementType.walkExplorer,
            {'completedWalks': completedWalks},
          );
          if (awarded) {
            final achievement = await getUserAchievementsByType(
              AchievementType.walkExplorer,
              userId: userId,
            );
            newAchievements.addAll(achievement.where((a) => a.isNew));
          }
        }
      }

      // Check for distance-based achievements
      if (distanceWalked > 0) {
        // Implement distance-based achievement checks here if needed
        // For now, this is a placeholder
      }

      // Check for art pieces visited achievements
      if (artPiecesVisited > 0) {
        // Implement art pieces visited achievement checks here if needed
        // For now, this is a placeholder
      }
    } catch (e) {
      _logger.e('Error checking for new achievements: $e');
    }

    return newAchievements;
  }
}
