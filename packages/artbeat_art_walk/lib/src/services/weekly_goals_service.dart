import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/src/models/weekly_goal_model.dart';
import 'package:artbeat_art_walk/src/constants/quest_tuning_defaults.dart';
import 'package:easy_localization/easy_localization.dart';
import 'rewards_service.dart';

/// Service for managing weekly goals (longer-term challenges)
class WeeklyGoalsService {
  static final WeeklyGoalsService _instance = WeeklyGoalsService._internal();

  factory WeeklyGoalsService() => _instance;

  WeeklyGoalsService._internal();

  FirebaseFirestore? _firestoreInstance;
  FirebaseAuth? _authInstance;
  final RewardsService _rewardsService = RewardsService();

  void initialize() {
    _firestoreInstance ??= FirebaseFirestore.instance;
    _authInstance ??= FirebaseAuth.instance;
  }

  FirebaseFirestore get _firestore {
    initialize();
    return _firestoreInstance!;
  }

  FirebaseAuth get _auth {
    initialize();
    return _authInstance!;
  }

  /// Get current week's goals for the user
  Future<List<WeeklyGoalModel>> getCurrentWeekGoals() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final now = DateTime.now();
      final weekKey = _getWeekKey(now);

      final goalsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weeklyGoals')
          .where('weekNumber', isEqualTo: _getWeekNumber(now))
          .where('year', isEqualTo: now.year)
          .get();

      if (goalsSnapshot.docs.isNotEmpty) {
        return goalsSnapshot.docs
            .map((doc) => WeeklyGoalModel.fromMap(doc.data()))
            .toList();
      } else {
        // Generate new weekly goals
        final newGoals = await _generateWeeklyGoals(user.uid);
        for (final goal in newGoals) {
          await _saveWeeklyGoal(goal, weekKey);
        }
        return newGoals;
      }
    } catch (e) {
      AppLogger.error('Error getting current week goals: $e');
      return [];
    }
  }

  /// Generate weekly goals for the user (3 goals per week)
  Future<List<WeeklyGoalModel>> _generateWeeklyGoals(String userId) async {
    final userStats = await _getUserStats(userId);
    final userLevel = (userStats['level'] as int?) ?? 1;
    final now = DateTime.now();
    final weekNumber = _getWeekNumber(now);
    final weekStart = _getWeekStart(now);
    final weekEnd = weekStart.add(const Duration(days: 7));

    // Pool of weekly goals across different categories
    final allGoals = [
      // Exploration Goals
      WeeklyGoalModel(
        id: 'weekly_explorer_${now.millisecondsSinceEpoch}',
        userId: userId,
        templateId: 'weekly_explorer',
        title: 'goal_weekly_art_explorer_title'.tr(),
        description: 'goal_weekly_art_explorer_desc'.tr(
          namedArgs: {'count': _scaleTarget(15, userLevel).toString()},
        ),
        category: WeeklyGoalCategory.exploration,
        targetCount: _scaleTarget(15, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(500, userLevel),
        rewardDescription: 'goal_weekly_art_explorer_reward'.tr(
          namedArgs: {'xp': _scaleReward(500, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '🗺️',
        milestones: [
          'goal_weekly_art_explorer_milestone_1'.tr(),
          'goal_weekly_art_explorer_milestone_2'.tr(),
          'goal_weekly_art_explorer_milestone_3'.tr(),
        ],
      ),
      WeeklyGoalModel(
        id: 'weekly_neighborhoods_${now.millisecondsSinceEpoch}',
        userId: userId,
        templateId: 'weekly_neighborhoods',
        title: 'goal_neighborhood_navigator_title'.tr(),
        description: 'goal_neighborhood_navigator_desc'.tr(
          namedArgs: {'count': _scaleTarget(5, userLevel).toString()},
        ),
        category: WeeklyGoalCategory.exploration,
        targetCount: _scaleTarget(5, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(600, userLevel),
        rewardDescription: 'goal_neighborhood_navigator_reward'.tr(
          namedArgs: {'xp': _scaleReward(600, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '🏘️',
        milestones: [
          'goal_neighborhood_navigator_milestone_1'.tr(),
          'goal_neighborhood_navigator_milestone_2'.tr(),
          'goal_neighborhood_navigator_milestone_3'.tr(),
        ],
      ),

      // Photography Goals
      WeeklyGoalModel(
        id: 'weekly_photographer_${now.millisecondsSinceEpoch}',
        userId: userId,
        templateId: 'weekly_photographer',
        title: 'goal_master_photographer_title'.tr(),
        description: 'goal_master_photographer_desc'.tr(
          namedArgs: {'count': _scaleTarget(20, userLevel).toString()},
        ),
        category: WeeklyGoalCategory.photography,
        targetCount: _scaleTarget(20, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(550, userLevel),
        rewardDescription: 'goal_master_photographer_reward'.tr(
          namedArgs: {'xp': _scaleReward(550, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '📸',
        milestones: [
          'goal_master_photographer_milestone_1'.tr(),
          'goal_master_photographer_milestone_2'.tr(),
          'goal_master_photographer_milestone_3'.tr(),
        ],
      ),
      WeeklyGoalModel(
        id: 'weekly_golden_hour_${now.millisecondsSinceEpoch}',
        userId: userId,
        templateId: 'weekly_golden_hour',
        title: 'goal_golden_hour_master_title'.tr(),
        description: 'goal_golden_hour_master_desc'.tr(
          namedArgs: {'count': _scaleTarget(10, userLevel).toString()},
        ),
        category: WeeklyGoalCategory.photography,
        targetCount: _scaleTarget(10, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(700, userLevel),
        rewardDescription: 'goal_golden_hour_master_reward'.tr(
          namedArgs: {'xp': _scaleReward(700, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '🌅',
        milestones: [
          'goal_golden_hour_master_milestone_1'.tr(),
          'goal_golden_hour_master_milestone_2'.tr(),
          'goal_golden_hour_master_milestone_3'.tr(),
        ],
      ),

      // Social Goals
      WeeklyGoalModel(
        id: 'weekly_social_butterfly_${now.millisecondsSinceEpoch}',
        userId: userId,
        templateId: 'weekly_social_butterfly',
        title: 'goal_social_butterfly_title'.tr(),
        description: 'goal_social_butterfly_desc'.tr(
          namedArgs: {
            'count': _scaleTarget(10, userLevel).toString(),
            'likes': _scaleTarget(20, userLevel).toString(),
          },
        ),
        category: WeeklyGoalCategory.social,
        targetCount: _scaleTarget(10, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(450, userLevel),
        rewardDescription: 'goal_social_butterfly_reward'.tr(
          namedArgs: {'xp': _scaleReward(450, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '🦋',
        milestones: [
          'goal_social_butterfly_milestone_1'.tr(),
          'goal_social_butterfly_milestone_2'.tr(),
          'goal_social_butterfly_milestone_3'.tr(),
        ],
      ),
      WeeklyGoalModel(
        id: 'weekly_community_builder_${now.millisecondsSinceEpoch}',
        userId: userId,
        templateId: 'weekly_community_builder',
        title: 'goal_community_builder_title'.tr(),
        description: 'goal_community_builder_desc'.tr(
          namedArgs: {'count': _scaleTarget(15, userLevel).toString()},
        ),
        category: WeeklyGoalCategory.social,
        targetCount: _scaleTarget(15, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(500, userLevel),
        rewardDescription: 'goal_community_builder_reward'.tr(
          namedArgs: {'xp': _scaleReward(500, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '🤝',
        milestones: [
          'goal_community_builder_milestone_1'.tr(),
          'goal_community_builder_milestone_2'.tr(),
          'goal_community_builder_milestone_3'.tr(),
        ],
      ),

      // Fitness Goals
      WeeklyGoalModel(
        id: 'weekly_walker_${now.millisecondsSinceEpoch}',
        userId: userId,
        templateId: 'weekly_walker',
        title: 'goal_urban_walker_title'.tr(),
        description: 'goal_urban_walker_desc'.tr(
          namedArgs: {'count': _scaleTarget(15, userLevel).toString()},
        ),
        category: WeeklyGoalCategory.fitness,
        targetCount: _scaleTarget(15000, userLevel), // meters
        currentCount: 0,
        rewardXP: _scaleReward(650, userLevel),
        rewardDescription: 'goal_urban_walker_reward'.tr(
          namedArgs: {'xp': _scaleReward(650, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '🚶',
        milestones: [
          'goal_urban_walker_milestone_1'.tr(),
          'goal_urban_walker_milestone_2'.tr(),
          'goal_urban_walker_milestone_3'.tr(),
        ],
      ),
      WeeklyGoalModel(
        id: 'weekly_step_champion_${now.millisecondsSinceEpoch}',
        userId: userId,
        templateId: 'weekly_step_champion',
        title: 'goal_step_champion_title'.tr(),
        description: 'goal_step_champion_desc'.tr(
          namedArgs: {'count': _scaleTarget(35000, userLevel).toString()},
        ),
        category: WeeklyGoalCategory.fitness,
        targetCount: _scaleTarget(35000, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(600, userLevel),
        rewardDescription: 'goal_step_champion_reward'.tr(
          namedArgs: {'xp': _scaleReward(600, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '👟',
        milestones: [
          'goal_step_champion_milestone_1'.tr(),
          'goal_step_champion_milestone_2'.tr(),
          'goal_step_champion_milestone_3'.tr(),
        ],
      ),

      // Mastery Goals
      WeeklyGoalModel(
        id: 'weekly_quest_master_${now.millisecondsSinceEpoch}',
        userId: userId,
        templateId: 'weekly_quest_master',
        title: 'goal_quest_master_title'.tr(),
        description: 'goal_quest_master_desc'.tr(
          namedArgs: {'count': _scaleTarget(5, userLevel).toString()},
        ),
        category: WeeklyGoalCategory.mastery,
        targetCount: _scaleTarget(5, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(800, userLevel),
        rewardDescription: 'goal_quest_master_reward'.tr(
          namedArgs: {'xp': _scaleReward(800, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '🏆',
        milestones: [
          'goal_quest_master_milestone_1'.tr(),
          'goal_quest_master_milestone_2'.tr(),
          'goal_quest_master_milestone_3'.tr(),
        ],
      ),
      WeeklyGoalModel(
        id: 'weekly_streak_keeper_${now.millisecondsSinceEpoch}',
        userId: userId,
        templateId: 'weekly_streak_keeper',
        title: 'goal_streak_keeper_title'.tr(),
        description: 'goal_streak_keeper_desc'.tr(),
        category: WeeklyGoalCategory.mastery,
        targetCount: 7,
        currentCount: 0,
        rewardXP: _scaleReward(1000, userLevel),
        rewardDescription: 'goal_streak_keeper_reward'.tr(
          namedArgs: {'xp': _scaleReward(1000, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '🔥',
        milestones: [
          'goal_streak_keeper_milestone_1'.tr(),
          'goal_streak_keeper_milestone_2'.tr(),
          'goal_streak_keeper_milestone_3'.tr(),
        ],
      ),

      // Collection Goals
      WeeklyGoalModel(
        id: 'weekly_style_collector_${now.millisecondsSinceEpoch}',
        userId: userId,
        templateId: 'weekly_style_collector',
        title: 'goal_style_collector_title'.tr(),
        description: 'goal_style_collector_desc'.tr(
          namedArgs: {'count': _scaleTarget(8, userLevel).toString()},
        ),
        category: WeeklyGoalCategory.collection,
        targetCount: _scaleTarget(8, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(750, userLevel),
        rewardDescription: 'goal_style_collector_reward'.tr(
          namedArgs: {'xp': _scaleReward(750, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '🎨',
        milestones: [
          'goal_style_collector_milestone_1'.tr(),
          'goal_style_collector_milestone_2'.tr(),
          'goal_style_collector_milestone_3'.tr(),
        ],
      ),
      WeeklyGoalModel(
        id: 'weekly_artist_fan_${now.millisecondsSinceEpoch}',
        userId: userId,
        templateId: 'weekly_artist_fan',
        title: 'goal_artist_fan_title'.tr(),
        description: 'goal_artist_fan_desc'.tr(
          namedArgs: {'count': _scaleTarget(10, userLevel).toString()},
        ),
        category: WeeklyGoalCategory.collection,
        targetCount: _scaleTarget(10, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(700, userLevel),
        rewardDescription: 'goal_artist_fan_reward'.tr(
          namedArgs: {'xp': _scaleReward(700, userLevel).toString()},
        ),
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '🎭',
        milestones: [
          'goal_artist_fan_milestone_1'.tr(),
          'goal_artist_fan_milestone_2'.tr(),
          'goal_artist_fan_milestone_3'.tr(),
        ],
      ),
    ];

    // Select 3 goals from different categories
    final selectedGoals = <WeeklyGoalModel>[];
    final usedCategories = <WeeklyGoalCategory>{};

    // Use week number and user ID as seed for consistent selection
    final seed = weekNumber + (userId.hashCode % 100);
    final random = Random(seed);

    // Shuffle goals deterministically based on seed
    final shuffledGoals = List<WeeklyGoalModel>.from(allGoals);
    shuffledGoals.shuffle(random);

    // Select 3 goals from different categories
    for (final goal in shuffledGoals) {
      if (!usedCategories.contains(goal.category)) {
        selectedGoals.add(goal);
        usedCategories.add(goal.category);
        if (selectedGoals.length == 3) break;
      }
    }

    // If we couldn't get 3 different categories, just take the first 3
    if (selectedGoals.length < 3) {
      return shuffledGoals.take(3).toList();
    }

    return selectedGoals;
  }

  /// Scale target count based on user level
  int _scaleTarget(int baseTarget, int userLevel) {
    final tier = QuestTuningDefaults.scalingTiers.firstWhere(
      (t) => t.containsLevel(userLevel),
      orElse: () => QuestTuningDefaults.level1to5,
    );
    return (baseTarget * tier.targetMultiplier).round();
  }

  /// Scale reward XP based on user level
  int _scaleReward(int baseReward, int userLevel) {
    final tier = QuestTuningDefaults.scalingTiers.firstWhere(
      (t) => t.containsLevel(userLevel),
      orElse: () => QuestTuningDefaults.level1to5,
    );
    return (baseReward * tier.rewardMultiplier).round();
  }

  /// Get user statistics for goal personalization
  Future<Map<String, dynamic>> _getUserStats(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return {};

      final userData = userDoc.data() ?? {};

      return {
        'level': userData['level'] ?? 1,
        'totalXP':
            userData['experiencePoints'] ?? userData['totalXP'] ?? 0,
      };
    } catch (e) {
      AppLogger.error('Error getting user stats: $e');
      return {};
    }
  }

  /// Update weekly goal progress
  Future<Map<String, dynamic>> updateWeeklyGoalProgress(
    String goalId,
    int increment,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      return {'counted': false, 'reason': 'not_authenticated'};
    }

    try {
      final now = DateTime.now();
      final weekKey = _getWeekKey(now);

      final goalRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weeklyGoals')
          .doc('${weekKey}_$goalId');

      Map<String, dynamic> result = {'counted': false, 'reason': 'no_change'};
      await _firestore.runTransaction((transaction) async {
        final goalDoc = await transaction.get(goalRef);

        if (!goalDoc.exists) {
          result = {'counted': false, 'reason': 'goal_not_found'};
          return;
        }

        final goal = WeeklyGoalModel.fromMap(goalDoc.data()!);
        if (goal.isCompleted) {
          result = {'counted': false, 'reason': 'already_completed'};
          return;
        }
        final newCount = (goal.currentCount + increment).clamp(
          0,
          goal.targetCount,
        );
        if (newCount == goal.currentCount) {
          result = {'counted': false, 'reason': 'no_progress'};
          return;
        }

        if (newCount >= goal.targetCount && !goal.isCompleted) {
          // Goal completed! Award XP with combo multiplier
          final awardedXP = await _rewardsService.awardXPWithCombo(
            'weekly_goal_completed',
            baseXP: goal.rewardXP,
            isDailyChallenge: false,
            isWeeklyGoal: true,
          );
          final multiplier = goal.rewardXP > 0 ? (awardedXP / goal.rewardXP) : 1.0;

          transaction.update(goalRef, {
            'currentCount': newCount,
            'isCompleted': true,
            'completedAt': Timestamp.now(),
            'lastBaseXP': goal.rewardXP,
            'lastAwardedXP': awardedXP,
            'lastMultiplier': multiplier,
          });

          AppLogger.info('Weekly goal completed: ${goal.title}');

          // Check for perfect week badge (after transaction completes)
          final weekKey = _getWeekKey(DateTime.now());
          await _rewardsService.checkPerfectWeek(user.uid, weekKey);

          // Check quest milestones
          await _rewardsService.checkQuestMilestones(user.uid);
          result = {
            'counted': true,
            'reason': 'completed',
            'newProgress': newCount,
            'target': goal.targetCount,
            'xpAwarded': awardedXP,
            'baseXP': goal.rewardXP,
          };
        } else {
          transaction.update(goalRef, {'currentCount': newCount});
          result = {
            'counted': true,
            'reason': 'progress_updated',
            'newProgress': newCount,
            'target': goal.targetCount,
            'xpAwarded': 0,
            'baseXP': goal.rewardXP,
          };
        }
      });
      if (QuestRuntimeConfig.eventLoggingEnabled) {
        AppLogger.info(
          'quest_event_weekly goalId=$goalId increment=$increment result=$result',
        );
      }
      await _recordQuestEvent(
        userId: user.uid,
        eventType: 'weekly_progress_update',
        entityId: goalId,
        increment: increment,
        payload: result,
      );
      return result;
    } catch (e) {
      AppLogger.error('Error updating weekly goal progress: $e');
      return {'counted': false, 'reason': 'error', 'error': e.toString()};
    }
  }

  /// Save weekly goal to Firestore
  Future<void> _saveWeeklyGoal(WeeklyGoalModel goal, String weekKey) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weeklyGoals')
          .doc('${weekKey}_${goal.id}')
          .set(goal.toMap());
    } catch (e) {
      AppLogger.error('Error saving weekly goal: $e');
    }
  }

  /// Get weekly goal statistics
  Future<Map<String, dynamic>> getWeeklyGoalStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final allGoals = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weeklyGoals')
          .get();

      final completedGoals = allGoals.docs.where(
        (doc) => doc.data()['isCompleted'] == true,
      );

      final totalGoals = allGoals.docs.length;
      final completedCount = completedGoals.length;
      final completionRate = totalGoals > 0
          ? (completedCount / totalGoals * 100).round()
          : 0;

      // Calculate total XP earned from weekly goals
      final totalXPEarned = completedGoals.fold<int>(
        0,
        (sum, doc) => sum + (doc.data()['rewardXP'] as int? ?? 0),
      );

      return {
        'totalGoals': totalGoals,
        'completedGoals': completedCount,
        'completionRate': completionRate,
        'totalXPEarned': totalXPEarned,
      };
    } catch (e) {
      AppLogger.error('Error getting weekly goal stats: $e');
      return {};
    }
  }

  /// Get week number (ISO 8601 week date)
  int _getWeekNumber(DateTime date) {
    final dayOfYear = int.parse(
      date.difference(DateTime(date.year, 1, 1)).inDays.toString(),
    );
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  /// Get week key for Firestore document ID (format: YYYY-Www)
  String _getWeekKey(DateTime date) {
    final weekNumber = _getWeekNumber(date);
    return '${date.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// Get start of week (Monday)
  DateTime _getWeekStart(DateTime date) {
    final daysToSubtract = date.weekday - 1;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: daysToSubtract));
  }

  /// Track daily quest completion for weekly mastery goals
  Future<void> trackDailyQuestCompletion() async {
    final goals = await getCurrentWeekGoals();
    for (final goal in goals) {
      if (goal.category == WeeklyGoalCategory.mastery &&
          goal.templateId == 'weekly_quest_master') {
        await updateWeeklyGoalProgress(goal.id, 1);
      }
    }
  }

  /// Track streak maintenance for weekly mastery goals
  Future<void> trackStreakDay() async {
    final goals = await getCurrentWeekGoals();
    for (final goal in goals) {
      if (goal.category == WeeklyGoalCategory.mastery &&
          goal.templateId == 'weekly_streak_keeper') {
        await updateWeeklyGoalProgress(goal.id, 1);
      }
    }
  }

  Future<void> _recordQuestEvent({
    required String userId,
    required String eventType,
    required String entityId,
    required int increment,
    required Map<String, dynamic> payload,
  }) async {
    if (!QuestRuntimeConfig.eventLoggingEnabled) return;
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('questEvents')
          .add({
            'eventType': eventType,
            'entityId': entityId,
            'increment': increment,
            'counted': payload['counted'] == true,
            'reason': payload['reason'],
            'payload': payload,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      AppLogger.error('Failed to record weekly quest event: $e');
    }
  }
}
