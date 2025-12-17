import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/challenge_model.dart';
import 'rewards_service.dart';

/// Service for managing user challenges (daily/weekly goals and rewards)
class ChallengeService {
  static final ChallengeService _instance = ChallengeService._internal();

  factory ChallengeService() => _instance;

  ChallengeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RewardsService _rewardsService = RewardsService();

  /// Get today's daily challenge for the user
  Future<ChallengeModel?> getTodaysChallenge() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Get or create today's challenge
      final today = DateTime.now();
      final todayKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final challengeDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dailyChallenges')
          .doc(todayKey)
          .get();

      if (challengeDoc.exists) {
        return ChallengeModel.fromMap(challengeDoc.data()!);
      } else {
        // Create a new daily challenge
        final newChallenge = await _generateDailyChallenge(user.uid);
        await _saveChallenge(newChallenge, todayKey);
        return newChallenge;
      }
    } catch (e) {
      AppLogger.error('Error getting today\'s challenge: $e');
      return null;
    }
  }

  /// Generate a random daily challenge based on user progress
  Future<ChallengeModel> _generateDailyChallenge(String userId) async {
    // Get user stats to personalize challenges
    final userStats = await _getUserStats(userId);
    final userLevel = (userStats['level'] as int?) ?? 1;
    final completedChallenges = (userStats['completedChallenges'] as int?) ?? 0;

    // Expanded challenge pool with difficulty scaling
    final challenges = [
      // Discovery Challenges
      ChallengeModel(
        id: 'discover_art_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: 'quest_art_explorer_title'.tr(),
        description: 'quest_art_explorer_desc'.tr(
          namedArgs: {'count': _scaleTarget(3, userLevel).toString()},
        ),
        type: ChallengeType.daily,
        targetCount: _scaleTarget(3, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(50, userLevel),
        rewardDescription: 'quest_art_explorer_reward'.tr(
          namedArgs: {'xp': _scaleReward(50, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
      ChallengeModel(
        id: 'discover_neighborhood_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: 'quest_neighborhood_scout_title'.tr(),
        description: 'quest_neighborhood_scout_desc'.tr(
          namedArgs: {'count': _scaleTarget(2, userLevel).toString()},
        ),
        type: ChallengeType.daily,
        targetCount: _scaleTarget(2, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(65, userLevel),
        rewardDescription: 'quest_neighborhood_scout_reward'.tr(
          namedArgs: {'xp': _scaleReward(65, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),

      // Photography Challenges
      ChallengeModel(
        id: 'capture_photos_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: 'quest_photo_hunter_title'.tr(),
        description: 'quest_photo_hunter_desc'.tr(
          namedArgs: {'count': _scaleTarget(5, userLevel).toString()},
        ),
        type: ChallengeType.daily,
        targetCount: _scaleTarget(5, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(75, userLevel),
        rewardDescription: 'quest_photo_hunter_reward'.tr(
          namedArgs: {'xp': _scaleReward(75, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
      ChallengeModel(
        id: 'golden_hour_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: 'quest_golden_hour_artist_title'.tr(),
        description: 'quest_golden_hour_artist_desc'.tr(
          namedArgs: {'count': _scaleTarget(3, userLevel).toString()},
        ),
        type: ChallengeType.daily,
        targetCount: _scaleTarget(3, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(90, userLevel),
        rewardDescription: 'quest_golden_hour_artist_reward'.tr(
          namedArgs: {'xp': _scaleReward(90, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),

      // Social Challenges
      ChallengeModel(
        id: 'social_share_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: 'quest_art_sharer_title'.tr(),
        description: 'quest_art_sharer_desc'.tr(
          namedArgs: {'count': _scaleTarget(2, userLevel).toString()},
        ),
        type: ChallengeType.daily,
        targetCount: _scaleTarget(2, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(40, userLevel),
        rewardDescription: 'quest_art_sharer_reward'.tr(
          namedArgs: {'xp': _scaleReward(40, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
      ChallengeModel(
        id: 'community_connector_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: 'quest_community_connector_title'.tr(),
        description: 'quest_community_connector_desc'.tr(
          namedArgs: {'count': _scaleTarget(3, userLevel).toString()},
        ),
        type: ChallengeType.daily,
        targetCount: _scaleTarget(3, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(45, userLevel),
        rewardDescription: 'quest_community_connector_reward'.tr(
          namedArgs: {'xp': _scaleReward(45, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),

      // Walking/Exercise Challenges
      ChallengeModel(
        id: 'walk_distance_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: 'quest_urban_wanderer_title'.tr(),
        description: 'quest_urban_wanderer_desc'.tr(
          namedArgs: {'count': _scaleTarget(2, userLevel).toString()},
        ),
        type: ChallengeType.daily,
        targetCount: _scaleTarget(2000, userLevel), // meters
        currentCount: 0,
        rewardXP: _scaleReward(60, userLevel),
        rewardDescription: 'quest_urban_wanderer_reward'.tr(
          namedArgs: {'xp': _scaleReward(60, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
      ChallengeModel(
        id: 'step_master_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: 'quest_step_master_title'.tr(),
        description: 'quest_step_master_desc'.tr(
          namedArgs: {'count': _scaleTarget(5000, userLevel).toString()},
        ),
        type: ChallengeType.daily,
        targetCount: _scaleTarget(5000, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(70, userLevel),
        rewardDescription: 'quest_step_master_reward'.tr(
          namedArgs: {'xp': _scaleReward(70, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),

      // Time-based Challenges
      ChallengeModel(
        id: 'early_bird_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: 'quest_early_bird_title'.tr(),
        description: 'quest_early_bird_desc'.tr(),
        type: ChallengeType.daily,
        targetCount: _scaleTarget(2, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(55, userLevel),
        rewardDescription: 'quest_early_bird_reward'.tr(
          namedArgs: {'xp': _scaleReward(55, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
      ChallengeModel(
        id: 'night_owl_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: 'quest_night_owl_title'.tr(),
        description: 'quest_night_owl_desc'.tr(
          namedArgs: {'count': _scaleTarget(3, userLevel).toString()},
        ),
        type: ChallengeType.daily,
        targetCount: _scaleTarget(3, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(80, userLevel),
        rewardDescription: 'quest_night_owl_reward'.tr(
          namedArgs: {'xp': _scaleReward(80, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),

      // Engagement Challenges
      ChallengeModel(
        id: 'art_critic_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: 'quest_art_critic_title'.tr(),
        description: 'quest_art_critic_desc'.tr(
          namedArgs: {'count': _scaleTarget(3, userLevel).toString()},
        ),
        type: ChallengeType.daily,
        targetCount: _scaleTarget(3, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(50, userLevel),
        rewardDescription: 'quest_art_critic_reward'.tr(
          namedArgs: {'xp': _scaleReward(50, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
      ChallengeModel(
        id: 'style_collector_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: 'quest_style_collector_title'.tr(),
        description: 'quest_style_collector_desc'.tr(
          namedArgs: {'count': _scaleTarget(3, userLevel).toString()},
        ),
        type: ChallengeType.daily,
        targetCount: _scaleTarget(3, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(85, userLevel),
        rewardDescription: 'quest_style_collector_reward'.tr(
          namedArgs: {'xp': _scaleReward(85, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),

      // Streak Bonus Challenges (for users with active streaks)
      if (completedChallenges > 7)
        ChallengeModel(
          id: 'streak_warrior_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          title: 'quest_streak_warrior_title'.tr(),
          description: 'quest_streak_warrior_desc'.tr(
            namedArgs: {'count': _scaleTarget(2, userLevel).toString()},
          ),
          type: ChallengeType.daily,
          targetCount: _scaleTarget(2, userLevel),
          currentCount: 0,
          rewardXP: _scaleReward(100, userLevel),
          rewardDescription: 'quest_streak_warrior_reward'.tr(
            namedArgs: {'xp': _scaleReward(100, userLevel).toString()},
          ),
          isCompleted: false,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        ),
    ];

    // Smart selection based on day of week and user history
    final seed = DateTime.now().day + (userId.hashCode % 100);
    final selectedIndex = seed % challenges.length;

    return challenges[selectedIndex];
  }

  /// Scale target count based on user level
  int _scaleTarget(int baseTarget, int userLevel) {
    if (userLevel <= 5) return baseTarget;
    if (userLevel <= 10) return (baseTarget * 1.2).round();
    if (userLevel <= 20) return (baseTarget * 1.5).round();
    return (baseTarget * 2).round();
  }

  /// Scale reward XP based on user level
  int _scaleReward(int baseReward, int userLevel) {
    if (userLevel <= 5) return baseReward;
    if (userLevel <= 10) return (baseReward * 1.3).round();
    if (userLevel <= 20) return (baseReward * 1.6).round();
    return (baseReward * 2).round();
  }

  /// Get user statistics for challenge personalization
  Future<Map<String, dynamic>> _getUserStats(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return {};

      final userData = userDoc.data() ?? {};
      final stats = await getChallengeStats();

      return {
        'level': userData['level'] ?? 1,
        'totalXP': userData['totalXP'] ?? 0,
        'completedChallenges': stats['completedChallenges'] ?? 0,
        'currentStreak': stats['currentStreak'] ?? 0,
      };
    } catch (e) {
      AppLogger.error('Error getting user stats: $e');
      return {};
    }
  }

  /// Update challenge progress
  Future<void> updateChallengeProgress(
    String challengeId,
    int increment,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final today = DateTime.now();
      final todayKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final challengeRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dailyChallenges')
          .doc(todayKey);

      await _firestore.runTransaction((transaction) async {
        final challengeDoc = await transaction.get(challengeRef);

        if (!challengeDoc.exists) return;

        final challenge = ChallengeModel.fromMap(challengeDoc.data()!);
        final newCount = (challenge.currentCount + increment).clamp(
          0,
          challenge.targetCount,
        );

        if (newCount >= challenge.targetCount && !challenge.isCompleted) {
          // Challenge completed! Award XP with combo multiplier
          await _rewardsService.awardXPWithCombo(
            'challenge_completed',
            baseXP: challenge.rewardXP,
            isDailyChallenge: true,
            isWeeklyGoal: false,
          );

          // Check for streak badges
          final currentStreak = await _getCurrentStreak(user.uid);
          await _rewardsService.checkStreakBadges(user.uid, currentStreak);

          // Check quest milestones
          await _rewardsService.checkQuestMilestones(user.uid);

          // Track category-specific streak (extract category from challenge title)
          final category = _extractChallengeCategory(challenge.title);
          if (category != null) {
            await _rewardsService.trackCategoryStreak(user.uid, category);
          }

          // Send completion notification
          await NotificationService().sendNotification(
            userId: user.uid,
            title: '🎉 Challenge Complete!',
            message: '${challenge.title}: ${challenge.rewardDescription}',
            type: NotificationType.achievement,
            data: {
              'challengeId': challenge.id,
              'xpAwarded': challenge.rewardXP,
            },
          );
        }

        transaction.update(challengeRef, {
          'currentCount': newCount,
          'isCompleted': newCount >= challenge.targetCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      AppLogger.error('Error updating challenge progress: $e');
    }
  }

  /// Get user's challenge statistics
  Future<Map<String, dynamic>> getChallengeStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final challengesQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dailyChallenges')
          .where('isCompleted', isEqualTo: true)
          .get();

      final completedCount = challengesQuery.docs.length;
      final totalXP = challengesQuery.docs.fold<int>(0, (sum, doc) {
        final challenge = ChallengeModel.fromMap(doc.data());
        return sum + challenge.rewardXP;
      });

      return {
        'completedChallenges': completedCount,
        'totalXPEarned': totalXP,
        'currentStreak': await _getCurrentStreak(user.uid),
        'bestStreak': await _getBestStreak(user.uid),
      };
    } catch (e) {
      AppLogger.error('Error getting challenge stats: $e');
      return {};
    }
  }

  /// Get current challenge completion streak
  Future<int> _getCurrentStreak(String userId) async {
    try {
      // Get last 30 days of challenges
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final challengesQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyChallenges')
          .where('createdAt', isGreaterThan: thirtyDaysAgo)
          .orderBy('createdAt', descending: true)
          .get();

      int streak = 0;
      DateTime currentDate = DateTime.now();

      for (final doc in challengesQuery.docs) {
        final challenge = ChallengeModel.fromMap(doc.data());
        final challengeDate = DateTime(
          challenge.createdAt.year,
          challenge.createdAt.month,
          challenge.createdAt.day,
        );
        final expectedDate = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
        );

        if (challengeDate == expectedDate && challenge.isCompleted) {
          streak++;
          currentDate = currentDate.subtract(const Duration(days: 1));
        } else if (challengeDate != expectedDate) {
          // Gap in dates, streak broken
          break;
        }
      }

      return streak;
    } catch (e) {
      AppLogger.error('Error getting challenge streak: $e');
      return 0;
    }
  }

  /// Get user's best (longest) challenge completion streak
  Future<int> _getBestStreak(String userId) async {
    try {
      // Get all completed challenges, ordered by date
      final challengesQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyChallenges')
          .where('isCompleted', isEqualTo: true)
          .orderBy('createdAt', descending: false) // Oldest first
          .get();

      if (challengesQuery.docs.isEmpty) return 0;

      int bestStreak = 1;
      int currentStreak = 1;

      // Convert to date-only for comparison
      final completedDates = challengesQuery.docs.map((doc) {
        final challenge = ChallengeModel.fromMap(doc.data());
        return DateTime(
          challenge.createdAt.year,
          challenge.createdAt.month,
          challenge.createdAt.day,
        );
      }).toList();

      // Find longest consecutive streak
      for (int i = 1; i < completedDates.length; i++) {
        final prevDate = completedDates[i - 1];
        final currentDate = completedDates[i];

        // Check if dates are consecutive (difference of 1 day)
        final difference = currentDate.difference(prevDate).inDays;
        if (difference == 1) {
          currentStreak++;
          bestStreak = bestStreak > currentStreak ? bestStreak : currentStreak;
        } else {
          currentStreak = 1; // Reset streak
        }
      }

      return bestStreak;
    } catch (e) {
      AppLogger.error('Error getting best challenge streak: $e');
      return 0;
    }
  }

  /// Save challenge to Firestore
  Future<void> _saveChallenge(ChallengeModel challenge, String dateKey) async {
    try {
      await _firestore
          .collection('users')
          .doc(challenge.userId)
          .collection('dailyChallenges')
          .doc(dateKey)
          .set(challenge.toMap());
    } catch (e) {
      AppLogger.error('Error saving challenge: $e');
    }
  }

  /// Extract challenge category from title for category-specific streaks
  String? _extractChallengeCategory(String title) {
    final titleLower = title.toLowerCase();

    if (titleLower.contains('photo') || titleLower.contains('capture')) {
      return 'photography';
    } else if (titleLower.contains('discover') ||
        titleLower.contains('explore') ||
        titleLower.contains('neighborhood')) {
      return 'exploration';
    } else if (titleLower.contains('share') ||
        titleLower.contains('review') ||
        titleLower.contains('social')) {
      return 'social';
    } else if (titleLower.contains('walk') || titleLower.contains('route')) {
      return 'walking';
    }

    return null; // Unknown category
  }

  /// Record art discovery for challenge progress
  Future<void> recordArtDiscovery() async {
    final challenge = await getTodaysChallenge();
    if (challenge != null &&
        challenge.title.contains('Discover') &&
        !challenge.isCompleted) {
      await updateChallengeProgress(challenge.id, 1);
    }
  }

  /// Record photo capture for challenge progress
  Future<void> recordPhotoCapture() async {
    final challenge = await getTodaysChallenge();
    if (challenge != null &&
        challenge.title.contains('Photo') &&
        !challenge.isCompleted) {
      await updateChallengeProgress(challenge.id, 1);
    }
  }

  /// Record walk distance for challenge progress
  Future<void> recordWalkDistance(double meters) async {
    final challenge = await getTodaysChallenge();
    if (challenge != null &&
        (challenge.title.contains('Walk') ||
            challenge.title.contains('Wanderer')) &&
        !challenge.isCompleted) {
      await updateChallengeProgress(challenge.id, meters.round());
    }
  }

  /// Record steps for challenge progress
  Future<void> recordSteps(int steps) async {
    final challenge = await getTodaysChallenge();
    if (challenge != null &&
        challenge.title.contains('Step') &&
        !challenge.isCompleted) {
      await updateChallengeProgress(challenge.id, steps);
    }
  }

  /// Record social share for challenge progress
  Future<void> recordSocialShare() async {
    final challenge = await getTodaysChallenge();
    if (challenge != null &&
        challenge.title.contains('Sharer') &&
        !challenge.isCompleted) {
      await updateChallengeProgress(challenge.id, 1);
    }
  }

  /// Record comment for challenge progress
  Future<void> recordComment() async {
    final challenge = await getTodaysChallenge();
    if (challenge != null &&
        (challenge.title.contains('Community') ||
            challenge.title.contains('Connector')) &&
        !challenge.isCompleted) {
      await updateChallengeProgress(challenge.id, 1);
    }
  }

  /// Record neighborhood discovery for challenge progress
  Future<void> recordNeighborhoodDiscovery(String neighborhood) async {
    final challenge = await getTodaysChallenge();
    if (challenge != null &&
        challenge.title.contains('Neighborhood') &&
        !challenge.isCompleted) {
      // Track unique neighborhoods visited today
      await updateChallengeProgress(challenge.id, 1);
    }
  }

  /// Record time-based discovery (early bird or night owl)
  Future<void> recordTimeBasedDiscovery() async {
    final challenge = await getTodaysChallenge();
    if (challenge == null || challenge.isCompleted) return;

    final hour = DateTime.now().hour;

    // Early bird: before 9 AM
    if (hour < 9 && challenge.title.contains('Early Bird')) {
      await updateChallengeProgress(challenge.id, 1);
    }

    // Night owl: after sunset (simplified to after 6 PM)
    if (hour >= 18 && challenge.title.contains('Night Owl')) {
      await updateChallengeProgress(challenge.id, 1);
    }

    // Golden hour: sunrise (5-7 AM) or sunset (5-7 PM)
    if ((hour >= 5 && hour <= 7) || (hour >= 17 && hour <= 19)) {
      if (challenge.title.contains('Golden Hour')) {
        await updateChallengeProgress(challenge.id, 1);
      }
    }
  }

  /// Record detailed description for challenge progress
  Future<void> recordDetailedDescription(String description) async {
    final challenge = await getTodaysChallenge();
    if (challenge != null &&
        challenge.title.contains('Critic') &&
        !challenge.isCompleted &&
        description.length >= 50) {
      // Require at least 50 characters
      await updateChallengeProgress(challenge.id, 1);
    }
  }

  /// Record art style discovery for challenge progress
  Future<void> recordStyleDiscovery(String artStyle) async {
    final challenge = await getTodaysChallenge();
    if (challenge != null &&
        challenge.title.contains('Style Collector') &&
        !challenge.isCompleted) {
      // Track unique art styles discovered today
      await updateChallengeProgress(challenge.id, 1);
    }
  }

  /// Record any art activity for streak warrior challenge
  Future<void> recordAnyActivity() async {
    final challenge = await getTodaysChallenge();
    if (challenge != null &&
        challenge.title.contains('Streak Warrior') &&
        !challenge.isCompleted) {
      await updateChallengeProgress(challenge.id, 1);
    }
  }

  /// Get all available challenge types for reference
  List<String> getAvailableChallengeTypes() {
    return [
      'Art Explorer',
      'Neighborhood Scout',
      'Photo Hunter',
      'Golden Hour Artist',
      'Art Sharer',
      'Community Connector',
      'Urban Wanderer',
      'Step Master',
      'Early Bird Explorer',
      'Night Owl Artist',
      'Art Critic',
      'Style Collector',
      'Streak Warrior',
    ];
  }

  /// Get challenge completion rate for analytics
  Future<double> getChallengeCompletionRate() async {
    final user = _auth.currentUser;
    if (user == null) return 0.0;

    try {
      final allChallenges = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dailyChallenges')
          .get();

      if (allChallenges.docs.isEmpty) return 0.0;

      final completedCount = allChallenges.docs
          .where((doc) => doc.data()['isCompleted'] == true)
          .length;

      return completedCount / allChallenges.docs.length;
    } catch (e) {
      AppLogger.error('Error calculating completion rate: $e');
      return 0.0;
    }
  }
}
