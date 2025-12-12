import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'social_service.dart';

/// Service for managing user rewards, XP, and achievements
class RewardsService {
  FirebaseFirestore? _firestoreInstance;
  FirebaseAuth? _authInstance;

  // Lazy initialization getters
  FirebaseFirestore get _firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authInstance ??= FirebaseAuth.instance;

  final Logger _logger = Logger();

  /// XP rewards for different actions
  static const Map<String, int> _xpRewards = {
    'art_capture_created': 25, // Creating a new capture
    'art_capture_approved': 50, // When capture gets approved
    'art_walk_completion': 100,
    'art_walk_creation': 75, // Creating a new art walk
    'art_visit': 10, // For individual art visits during walks
    'art_visit_verified': 15, // Within 30m + photo
    'art_visit_proximity': 10, // Within 30m
    'art_visit_general': 5, // General check-in
    'first_art_visit': 25, // Bonus for first visit
    'art_walk_milestone_25': 10, // 25% progress bonus
    'art_walk_milestone_50': 15, // 50% progress bonus
    'art_walk_milestone_75': 20, // 75% progress bonus
    'review_submission': 30, // Minimum 50 words required
    'helpful_vote_received': 10,
    'public_walk_popular': 75, // When your walk is used by 5+ users
    'walk_edit': 20, // Editing or updating existing walk
  };

  /// Level system with art movement titles and XP thresholds
  static const Map<int, Map<String, dynamic>> levelSystem = {
    1: {'title': 'Sketcher (Frida Kahlo)', 'minXP': 0, 'maxXP': 199},
    2: {'title': 'Color Blender (Jacob Lawrence)', 'minXP': 200, 'maxXP': 499},
    3: {
      'title': 'Brush Trailblazer (Yayoi Kusama)',
      'minXP': 500,
      'maxXP': 999,
    },
    4: {
      'title': 'Street Master (Jean-Michel Basquiat)',
      'minXP': 1000,
      'maxXP': 1499,
    },
    5: {'title': 'Mural Maven (Faith Ringgold)', 'minXP': 1500, 'maxXP': 2499},
    6: {
      'title': 'Avant-Garde Explorer (Zarina Hashmi)',
      'minXP': 2500,
      'maxXP': 3999,
    },
    7: {
      'title': 'Visionary Creator (El Anatsui)',
      'minXP': 4000,
      'maxXP': 5999,
    },
    8: {
      'title': 'Art Legend (Leonardo da Vinci)',
      'minXP': 6000,
      'maxXP': 7999,
    },
    9: {
      'title': 'Cultural Curator (Shirin Neshat)',
      'minXP': 8000,
      'maxXP': 9999,
    },
    10: {'title': 'Art Walk Influencer', 'minXP': 10000, 'maxXP': 999999},
  };

  /// Badge definitions with requirements
  static const Map<String, Map<String, dynamic>> badges = {
    // First achievements
    'first_walk_completed': {
      'name': 'First Walk Completed',
      'description': 'Complete your first art walk',
      'icon': '🚶',
      'requirement': {'type': 'walks_completed', 'count': 1},
    },
    'first_walk_created': {
      'name': 'First Walk Created',
      'description': 'Create your first art walk',
      'icon': '🎨',
      'requirement': {'type': 'walks_created', 'count': 1},
    },
    'first_capture_approved': {
      'name': 'First Capture Approved',
      'description': 'Get your first art capture approved',
      'icon': '📸',
      'requirement': {'type': 'captures_approved', 'count': 1},
    },
    'first_review_submitted': {
      'name': 'First Review Submitted',
      'description': 'Submit your first review',
      'icon': '✍️',
      'requirement': {'type': 'reviews_submitted', 'count': 1},
    },
    'first_helpful_vote': {
      'name': 'First Helpful Vote Received',
      'description': 'Receive your first helpful vote on a review',
      'icon': '👍',
      'requirement': {'type': 'helpful_votes', 'count': 1},
    },

    // Milestone achievements
    'ten_walks_completed': {
      'name': 'Ten Walks Completed',
      'description': 'Complete 10 art walks',
      'icon': '🏃',
      'requirement': {'type': 'walks_completed', 'count': 10},
    },
    'ten_captures_approved': {
      'name': 'Ten Captures Approved',
      'description': 'Get 10 art captures approved',
      'icon': '📷',
      'requirement': {'type': 'captures_approved', 'count': 10},
    },
    'ten_reviews_submitted': {
      'name': 'Ten Reviews Submitted',
      'description': 'Submit 10 reviews',
      'icon': '📝',
      'requirement': {'type': 'reviews_submitted', 'count': 10},
    },
    'ten_helpful_votes': {
      'name': 'Ten Helpful Votes Received',
      'description': 'Receive 10 helpful votes on reviews',
      'icon': '🌟',
      'requirement': {'type': 'helpful_votes', 'count': 10},
    },

    // Creator achievements
    'gallery_builder': {
      'name': 'Gallery Builder',
      'description': 'Create 5 art walks',
      'icon': '🏛️',
      'requirement': {'type': 'walks_created', 'count': 5},
    },
    'reviewer_extraordinaire': {
      'name': 'Reviewer Extraordinaire',
      'description': 'Submit 50 reviews',
      'icon': '🎭',
      'requirement': {'type': 'reviews_submitted', 'count': 50},
    },
    'popular_walk_creator': {
      'name': 'Popular Walk Creator',
      'description': 'Create a walk used by 10+ users',
      'icon': '🔥',
      'requirement': {'type': 'walk_popularity', 'count': 10},
    },

    // XP Level achievements
    'contributor_level_1': {
      'name': 'Contributor Level 1',
      'description': 'Reach 100 XP',
      'icon': '🥉',
      'requirement': {'type': 'total_xp', 'count': 100},
    },
    'contributor_level_2': {
      'name': 'Contributor Level 2',
      'description': 'Reach 500 XP',
      'icon': '🥈',
      'requirement': {'type': 'total_xp', 'count': 500},
    },
    'contributor_level_3': {
      'name': 'Contributor Level 3',
      'description': 'Reach 1000 XP',
      'icon': '🥇',
      'requirement': {'type': 'total_xp', 'count': 1000},
    },

    // Explorer achievements
    'artistic_explorer': {
      'name': 'Artistic Explorer',
      'description': 'Visit 10 different art locations',
      'icon': '🗺️',
      'requirement': {'type': 'locations_visited', 'count': 10},
    },
    'consistent_walker': {
      'name': 'Consistent Walker',
      'description': 'Complete 5 walks in a week',
      'icon': '📅',
      'requirement': {'type': 'walks_per_week', 'count': 5},
    },
    'helpful_reviewer': {
      'name': 'Helpful Reviewer',
      'description': 'Receive 20 helpful votes',
      'icon': '💡',
      'requirement': {'type': 'helpful_votes', 'count': 20},
    },

    // Special achievements
    'art_historian': {
      'name': 'Art Historian',
      'description': 'Review 25 different artworks',
      'icon': '📚',
      'requirement': {'type': 'unique_artworks_reviewed', 'count': 25},
    },
    'community_voice': {
      'name': 'Community Voice',
      'description': 'Submit 50 reviews with helpful votes',
      'icon': '📢',
      'requirement': {'type': 'helpful_reviews', 'count': 50},
    },
    'top_rated_walk': {
      'name': 'Top Rated Walk',
      'description': 'Create a walk with 5 stars and 10+ votes',
      'icon': '⭐',
      'requirement': {'type': 'top_rated_walk', 'rating': 5.0, 'votes': 10},
    },

    // Advanced achievements
    'capture_collector': {
      'name': 'Capture Collector',
      'description': 'Get 50 captures approved',
      'icon': '🎯',
      'requirement': {'type': 'captures_approved', 'count': 50},
    },
    'daily_walker': {
      'name': 'Daily Walker',
      'description': 'Complete 1 walk per day for 7 days',
      'icon': '🌅',
      'requirement': {'type': 'daily_streak', 'count': 7},
    },
    'local_guide': {
      'name': 'Local Guide',
      'description': 'Capture 10 artworks from your home area',
      'icon': '🏠',
      'requirement': {'type': 'local_captures', 'count': 10},
    },
    'art_enthusiast': {
      'name': 'Art Enthusiast',
      'description': 'Reach 1000 XP total',
      'icon': '🎨',
      'requirement': {'type': 'total_xp', 'count': 1000},
    },
    'seasoned_contributor': {
      'name': 'Seasoned Contributor',
      'description': 'Reach 5000 XP total',
      'icon': '🏆',
      'requirement': {'type': 'total_xp', 'count': 5000},
    },
    'artistic_influencer': {
      'name': 'Artistic Influencer',
      'description': 'Reach 10000 XP and create 20 public walks',
      'icon': '👑',
      'requirement': {'type': 'influencer', 'xp': 10000, 'walks': 20},
    },

    // Quest achievements - Daily Challenges
    'quest_starter': {
      'name': 'Quest Starter',
      'description': 'Complete your first daily challenge',
      'icon': '🎯',
      'requirement': {'type': 'challenges_completed', 'count': 1},
    },
    'quest_enthusiast': {
      'name': 'Quest Enthusiast',
      'description': 'Complete 10 daily challenges',
      'icon': '🎲',
      'requirement': {'type': 'challenges_completed', 'count': 10},
    },
    'quest_master': {
      'name': 'Quest Master',
      'description': 'Complete 50 daily challenges',
      'icon': '🏅',
      'requirement': {'type': 'challenges_completed', 'count': 50},
    },
    'quest_legend': {
      'name': 'Quest Legend',
      'description': 'Complete 100 daily challenges',
      'icon': '🎖️',
      'requirement': {'type': 'challenges_completed', 'count': 100},
    },

    // Quest achievements - Weekly Goals
    'weekly_warrior': {
      'name': 'Weekly Warrior',
      'description': 'Complete your first weekly goal',
      'icon': '⚔️',
      'requirement': {'type': 'weekly_goals_completed', 'count': 1},
    },
    'weekly_champion': {
      'name': 'Weekly Champion',
      'description': 'Complete 10 weekly goals',
      'icon': '🏆',
      'requirement': {'type': 'weekly_goals_completed', 'count': 10},
    },
    'weekly_legend': {
      'name': 'Weekly Legend',
      'description': 'Complete 25 weekly goals',
      'icon': '👑',
      'requirement': {'type': 'weekly_goals_completed', 'count': 25},
    },
    'perfect_week': {
      'name': 'Perfect Week',
      'description': 'Complete all 3 weekly goals in one week',
      'icon': '💎',
      'requirement': {'type': 'perfect_week', 'count': 1},
    },

    // Streak achievements
    'streak_starter': {
      'name': 'Streak Starter',
      'description': 'Maintain a 3-day challenge streak',
      'icon': '🔥',
      'requirement': {'type': 'challenge_streak', 'count': 3},
    },
    'streak_master': {
      'name': 'Streak Master',
      'description': 'Maintain a 7-day challenge streak',
      'icon': '🔥🔥',
      'requirement': {'type': 'challenge_streak', 'count': 7},
    },
    'streak_legend': {
      'name': 'Streak Legend',
      'description': 'Maintain a 30-day challenge streak',
      'icon': '🔥🔥🔥',
      'requirement': {'type': 'challenge_streak', 'count': 30},
    },
    'unstoppable': {
      'name': 'Unstoppable',
      'description': 'Maintain a 100-day challenge streak',
      'icon': '⚡',
      'requirement': {'type': 'challenge_streak', 'count': 100},
    },

    // Daily Login Rewards Badges
    'daily_devotee': {
      'name': 'Daily Devotee',
      'description': 'Log in for 7 consecutive days',
      'icon': '📅',
      'requirement': {'type': 'login_streak', 'count': 7},
    },
    'weekly_regular': {
      'name': 'Weekly Regular',
      'description': 'Log in for 30 consecutive days',
      'icon': '🗓️',
      'requirement': {'type': 'login_streak', 'count': 30},
    },
    'dedicated_explorer': {
      'name': 'Dedicated Explorer',
      'description': 'Log in for 100 consecutive days',
      'icon': '🎖️',
      'requirement': {'type': 'login_streak', 'count': 100},
    },

    // Quest Milestone Badges
    'century_quester': {
      'name': 'Century Quester',
      'description': 'Complete 100 total quests (challenges + weekly goals)',
      'icon': '💯',
      'requirement': {'type': 'total_quests', 'count': 100},
    },
    'quest_veteran': {
      'name': 'Quest Veteran',
      'description': 'Complete 250 total quests',
      'icon': '🎯',
      'requirement': {'type': 'total_quests', 'count': 250},
    },
    'quest_grandmaster': {
      'name': 'Quest Grandmaster',
      'description': 'Complete 500 total quests',
      'icon': '👑',
      'requirement': {'type': 'total_quests', 'count': 500},
    },
    'perfect_month': {
      'name': 'Perfect Month',
      'description': 'Complete 4 perfect weeks in a row',
      'icon': '🌟',
      'requirement': {'type': 'perfect_weeks_streak', 'count': 4},
    },
    'combo_master': {
      'name': 'Combo Master',
      'description':
          'Complete a daily challenge and weekly goal on the same day 10 times',
      'icon': '⚡',
      'requirement': {'type': 'combo_completions', 'count': 10},
    },
  };

  /// Level unlockable perks
  static const Map<int, List<String>> levelPerks = {
    3: ['Suggest edits to any public artwork'],
    5: ['Moderate reviews (report abuse, vote quality)'],
    7: ['Early access to beta features'],
    10: [
      'Become an Art Walk Influencer',
      'Post updates and thoughts on art walks',
      'Featured profile section',
      'Eligible for community spotlight',
    ],
  };

  /// Award XP to the current user
  Future<void> awardXP(String action, {int? customAmount}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final xpAmount = customAmount ?? _xpRewards[action] ?? 0;
    if (xpAmount <= 0) return;

    try {
      final userRef = _firestore.collection('users').doc(user.uid);

      int newXP = 0;
      int oldLevel = 0;
      int newLevel = 0;

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        final userData = userDoc.data() ?? {};

        final currentXP = userData['experiencePoints'] as int? ?? 0;
        newXP = currentXP + xpAmount;
        newLevel = _calculateLevel(newXP);
        oldLevel = _calculateLevel(currentXP);

        // Update user stats
        final updates = <String, dynamic>{
          'experiencePoints': newXP,
          'level': newLevel,
          'lastXPGain': FieldValue.serverTimestamp(),
        };

        // Track action-specific stats
        switch (action) {
          case 'art_capture_created':
            updates['stats.capturesCreated'] = FieldValue.increment(1);
            break;
          case 'art_capture_approved':
            updates['stats.capturesApproved'] = FieldValue.increment(1);
            break;
          case 'art_walk_completion':
            updates['stats.walksCompleted'] = FieldValue.increment(1);
            break;
          case 'art_walk_creation':
            updates['stats.walksCreated'] = FieldValue.increment(1);
            break;
          case 'review_submission':
            updates['stats.reviewsSubmitted'] = FieldValue.increment(1);
            break;
          case 'helpful_vote_received':
            updates['stats.helpfulVotes'] = FieldValue.increment(1);
            break;
          case 'public_walk_popular':
            updates['stats.popularWalks'] = FieldValue.increment(1);
            break;
          case 'walk_edit':
            updates['stats.walksEdited'] = FieldValue.increment(1);
            break;
          case 'challenge_completed':
            updates['stats.challengesCompleted'] = FieldValue.increment(1);
            break;
          case 'weekly_goal_completed':
            updates['stats.weeklyGoalsCompleted'] = FieldValue.increment(1);
            break;
        }

        transaction.update(userRef, updates);

        // Check for new achievements if level increased
        if (newLevel > oldLevel) {
          _checkLevelAchievements(user.uid, newLevel, newXP);
        }

        // Check for action-specific achievements
        _checkActionAchievements(user.uid, action, userData);
      });

      // Post social activity for level up
      if (newLevel > oldLevel) {
        try {
          final socialService = SocialService();
          await socialService.postActivity(
            userId: user.uid,
            userName: user.displayName ?? 'Explorer',
            userAvatar: user.photoURL,
            type: SocialActivityType.milestone,
            message: 'reached level $newLevel: ${getLevelTitle(newLevel)}',
            metadata: {
              'newLevel': newLevel,
              'oldLevel': oldLevel,
              'artTitle': getLevelTitle(newLevel),
            },
          );
        } catch (e) {
          _logger.w('Failed to post social activity for level up: $e');
        }
      }

      _logger.i('Awarded $xpAmount XP for $action to user ${user.uid}');
    } catch (e) {
      _logger.e('Error awarding XP: $e');
    }
  }

  /// Calculate user level based on XP
  int _calculateLevel(int xp) {
    for (int level = 10; level >= 1; level--) {
      final levelData = levelSystem[level]!;
      if (xp >= (levelData['minXP'] as int)) {
        return level;
      }
    }
    return 1;
  }

  /// Get level title for a given level
  String getLevelTitle(int level) {
    return (levelSystem[level]?['title'] as String?) ?? 'Unknown Level';
  }

  /// Get XP range for a level
  Map<String, int> getLevelXPRange(int level) {
    final levelData = levelSystem[level];
    if (levelData == null) return {'min': 0, 'max': 199};
    return {'min': levelData['minXP'] as int, 'max': levelData['maxXP'] as int};
  }

  /// Get level progress (0.0 to 1.0)
  double getLevelProgress(int currentXP, int level) {
    final range = getLevelXPRange(level);
    if (level >= 10) return 1.0; // Max level

    final progressXP = currentXP - range['min']!;
    final requiredXP = range['max']! - range['min']! + 1;

    return (progressXP / requiredXP).clamp(0.0, 1.0);
  }

  /// Check for level-based achievements
  Future<void> _checkLevelAchievements(
    String userId,
    int newLevel,
    int xp,
  ) async {
    // Check XP milestone badges
    final xpBadges = [
      'contributor_level_1',
      'contributor_level_2',
      'contributor_level_3',
      'art_enthusiast',
      'seasoned_contributor',
    ];

    for (final badgeId in xpBadges) {
      final badge = badges[badgeId]!;
      final requirement = badge['requirement'] as Map<String, dynamic>;

      if (requirement['type'] == 'total_xp' &&
          xp >= (requirement['count'] as int)) {
        await _awardBadge(userId, badgeId);
      }
    }

    // Check for influencer status
    if (xp >= 10000) {
      // Need to check if user also has 20 public walks
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final walksCreated =
          userDoc.data()?['stats']?['walksCreated'] as int? ?? 0;

      if (walksCreated >= 20) {
        await _awardBadge(userId, 'artistic_influencer');
      }
    }
  }

  /// Check for action-specific achievements
  Future<void> _checkActionAchievements(
    String userId,
    String action,
    Map<String, dynamic> userData,
  ) async {
    final stats = userData['stats'] as Map<String, dynamic>? ?? {};

    switch (action) {
      case 'art_walk_completion':
        final walksCompleted = (stats['walksCompleted'] as int? ?? 0) + 1;
        if (walksCompleted == 1)
          await _awardBadge(userId, 'first_walk_completed');
        if (walksCompleted == 10)
          await _awardBadge(userId, 'ten_walks_completed');
        break;

      case 'art_walk_creation':
        final walksCreated = (stats['walksCreated'] as int? ?? 0) + 1;
        if (walksCreated == 1) await _awardBadge(userId, 'first_walk_created');
        if (walksCreated == 5) await _awardBadge(userId, 'gallery_builder');
        if (walksCreated == 20) {
          // Check if user also has 10k XP for influencer status
          final userDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();
          final xp = userDoc.data()?['experiencePoints'] as int? ?? 0;
          if (xp >= 10000) {
            await _awardBadge(userId, 'artistic_influencer');
          }
        }
        break;

      case 'art_capture_approved':
        final capturesApproved = (stats['capturesApproved'] as int? ?? 0) + 1;
        if (capturesApproved == 1)
          await _awardBadge(userId, 'first_capture_approved');
        if (capturesApproved == 10)
          await _awardBadge(userId, 'ten_captures_approved');
        if (capturesApproved == 50)
          await _awardBadge(userId, 'capture_collector');
        break;

      case 'review_submission':
        final reviewsSubmitted = (stats['reviewsSubmitted'] as int? ?? 0) + 1;
        if (reviewsSubmitted == 1)
          await _awardBadge(userId, 'first_review_submitted');
        if (reviewsSubmitted == 10)
          await _awardBadge(userId, 'ten_reviews_submitted');
        if (reviewsSubmitted == 50)
          await _awardBadge(userId, 'reviewer_extraordinaire');
        break;

      case 'helpful_vote_received':
        final helpfulVotes = (stats['helpfulVotes'] as int? ?? 0) + 1;
        if (helpfulVotes == 1) await _awardBadge(userId, 'first_helpful_vote');
        if (helpfulVotes == 10) await _awardBadge(userId, 'ten_helpful_votes');
        if (helpfulVotes == 20) await _awardBadge(userId, 'helpful_reviewer');
        break;

      case 'challenge_completed':
        final challengesCompleted =
            (stats['challengesCompleted'] as int? ?? 0) + 1;
        if (challengesCompleted == 1)
          await _awardBadge(userId, 'quest_starter');
        if (challengesCompleted == 10)
          await _awardBadge(userId, 'quest_enthusiast');
        if (challengesCompleted == 50)
          await _awardBadge(userId, 'quest_master');
        if (challengesCompleted == 100)
          await _awardBadge(userId, 'quest_legend');
        break;

      case 'weekly_goal_completed':
        final weeklyGoalsCompleted =
            (stats['weeklyGoalsCompleted'] as int? ?? 0) + 1;
        if (weeklyGoalsCompleted == 1)
          await _awardBadge(userId, 'weekly_warrior');
        if (weeklyGoalsCompleted == 10)
          await _awardBadge(userId, 'weekly_champion');
        if (weeklyGoalsCompleted == 25)
          await _awardBadge(userId, 'weekly_legend');
        break;
    }
  }

  /// Award a badge to a user (public method for debugging)
  Future<void> awardBadge(String userId, String badgeId) async {
    await _awardBadge(userId, badgeId);
  }

  /// Award a badge to a user (private method)
  Future<void> _awardBadge(String userId, String badgeId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      final badgesMap =
          userDoc.data()?['badges'] as Map<String, dynamic>? ?? {};

      // Only award if not already present
      if (badgesMap.containsKey(badgeId)) {
        _logger.i('Badge $badgeId already awarded to user $userId');
        return;
      }

      await userRef.set({
        'badges': {
          badgeId: {'earnedAt': FieldValue.serverTimestamp(), 'viewed': false},
        },
      }, SetOptions(merge: true));

      _logger.i('Awarded badge $badgeId to user $userId');

      // Post social activity for badge earned
      try {
        final badgeInfo = badges[badgeId];
        if (badgeInfo != null) {
          final user = _auth.currentUser;
          final badge = badgeInfo;
          final badgeName = badge['name'] ?? 'Unknown Badge';
          final badgeIcon = badge['icon'] ?? '🏅';

          final socialService = SocialService();
          await socialService.postActivity(
            userId: userId,
            userName: user?.displayName ?? 'Explorer',
            userAvatar: user?.photoURL,
            type: SocialActivityType.achievement,
            message: 'earned badge: $badgeIcon $badgeName',
            metadata: {
              'badgeId': badgeId,
              'badgeName': badgeName,
              'artTitle': '$badgeIcon $badgeName',
            },
          );
        }
      } catch (e) {
        _logger.w('Failed to post social activity for badge: $e');
      }
    } catch (e) {
      _logger.e('Error awarding badge: $e');
    }
  }

  /// Get user's badges
  Future<Map<String, dynamic>> getUserBadges(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['badges'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      _logger.e('Error getting user badges: $e');
      return {};
    }
  }

  /// Get unviewed badges for showing notifications
  Future<List<String>> getUnviewedBadges(String userId) async {
    try {
      final badges = await getUserBadges(userId);
      return badges.entries
          .where((entry) => entry.value['viewed'] == false)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      _logger.e('Error getting unviewed badges: $e');
      return [];
    }
  }

  /// Mark badges as viewed
  Future<void> markBadgesAsViewed(String userId, List<String> badgeIds) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final updates = <String, dynamic>{};

      for (final badgeId in badgeIds) {
        updates['badges.$badgeId.viewed'] = true;
      }

      await userRef.update(updates);
    } catch (e) {
      _logger.e('Error marking badges as viewed: $e');
    }
  }

  /// Get level perks for a user
  List<String> getLevelPerks(int level) {
    final perks = <String>[];
    for (final entry in levelPerks.entries) {
      if (level >= entry.key) {
        perks.addAll(entry.value);
      }
    }
    return perks;
  }

  /// Check if user has specific perk
  bool hasLevelPerk(int level, String perk) {
    final perks = getLevelPerks(level);
    return perks.any((p) => p.toLowerCase().contains(perk.toLowerCase()));
  }

  /// Check and award streak badges based on current streak
  Future<void> checkStreakBadges(String userId, int currentStreak) async {
    if (currentStreak >= 3) await _awardBadge(userId, 'streak_starter');
    if (currentStreak >= 7) await _awardBadge(userId, 'streak_master');
    if (currentStreak >= 30) await _awardBadge(userId, 'streak_legend');
    if (currentStreak >= 100) await _awardBadge(userId, 'unstoppable');
  }

  /// Check and award perfect week badge
  /// Call this when a weekly goal is completed
  Future<void> checkPerfectWeek(String userId, String weekKey) async {
    try {
      // Get all weekly goals for this week
      final goalsQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('weeklyGoals')
          .where('weekNumber', isEqualTo: int.parse(weekKey.split('_')[0]))
          .where('year', isEqualTo: int.parse(weekKey.split('_')[1]))
          .get();

      // Check if all 3 goals are completed
      if (goalsQuery.docs.length >= 3) {
        final allCompleted = goalsQuery.docs.every((doc) {
          final data = doc.data();
          return data['isCompleted'] == true;
        });

        if (allCompleted) {
          await _awardBadge(userId, 'perfect_week');

          // Check for perfect month (4 perfect weeks in a row)
          await _checkPerfectMonth(userId);
        }
      }
    } catch (e) {
      _logger.e('Error checking perfect week: $e');
    }
  }

  /// Check for perfect month achievement (4 perfect weeks in a row)
  Future<void> _checkPerfectMonth(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      final userData = userDoc.data() ?? {};

      final consecutivePerfectWeeks =
          userData['stats']?['consecutivePerfectWeeks'] as int? ?? 0;

      if (consecutivePerfectWeeks >= 4) {
        await _awardBadge(userId, 'perfect_month');
      }
    } catch (e) {
      _logger.e('Error checking perfect month: $e');
    }
  }

  /// Process daily login and award rewards
  /// Call this when user opens the app
  Future<Map<String, dynamic>> processDailyLogin(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final today = DateTime.now();
      final todayKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final result = await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        final userData = userDoc.data() ?? {};

        final lastLoginDate = userData['lastLoginDate'] as String?;
        final currentLoginStreak =
            userData['stats']?['loginStreak'] as int? ?? 0;
        final longestLoginStreak =
            userData['stats']?['longestLoginStreak'] as int? ?? 0;

        // Check if already logged in today
        if (lastLoginDate == todayKey) {
          return {
            'alreadyLoggedIn': true,
            'streak': currentLoginStreak,
            'xpAwarded': 0,
          };
        }

        // Calculate new streak
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayKey =
            '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

        int newStreak;
        if (lastLoginDate == yesterdayKey) {
          // Continuing streak
          newStreak = currentLoginStreak + 1;
        } else {
          // Streak broken or first login
          newStreak = 1;
        }

        // Calculate XP reward based on streak
        int xpReward = 10; // Base reward
        if (newStreak >= 7)
          xpReward = 50;
        else if (newStreak >= 3)
          xpReward = 25;
        else if (newStreak >= 2)
          xpReward = 15;

        // Bonus for milestone days
        if (newStreak == 7) xpReward += 50; // Day 7 bonus
        if (newStreak == 30) xpReward += 100; // Day 30 bonus
        if (newStreak == 100) xpReward += 500; // Day 100 bonus

        // Update user data
        final currentXP = userData['experiencePoints'] as int? ?? 0;
        final newXP = currentXP + xpReward;
        final newLevel = _calculateLevel(newXP);

        final updates = <String, dynamic>{
          'lastLoginDate': todayKey,
          'experiencePoints': newXP,
          'level': newLevel,
          'stats.loginStreak': newStreak,
          'stats.longestLoginStreak': newStreak > longestLoginStreak
              ? newStreak
              : longestLoginStreak,
          'stats.totalLogins': FieldValue.increment(1),
        };

        transaction.update(userRef, updates);

        return {
          'alreadyLoggedIn': false,
          'streak': newStreak,
          'xpAwarded': xpReward,
          'isNewStreak': newStreak == 1 && lastLoginDate != null,
        };
      });

      // Check for login streak badges (outside transaction)
      if (result['alreadyLoggedIn'] != true) {
        final streak = result['streak'] as int;
        await _checkLoginStreakBadges(userId, streak);
      }

      return result;
    } catch (e) {
      _logger.e('Error processing daily login: $e');
      return {'error': true, 'message': e.toString()};
    }
  }

  /// Check and award login streak badges
  Future<void> _checkLoginStreakBadges(String userId, int streak) async {
    if (streak >= 7) await _awardBadge(userId, 'daily_devotee');
    if (streak >= 30) await _awardBadge(userId, 'weekly_regular');
    if (streak >= 100) await _awardBadge(userId, 'dedicated_explorer');
  }

  /// Calculate XP with combo multiplier
  /// Returns the final XP amount after applying multipliers
  int calculateXPWithMultiplier({
    required int baseXP,
    required bool isDailyChallenge,
    required bool isWeeklyGoal,
    required int questsCompletedToday,
  }) {
    double multiplier = 1.0;

    // Combo multiplier for completing multiple quests in one day
    if (questsCompletedToday >= 3) {
      multiplier = 1.5; // +50% for 3+ quests
    } else if (questsCompletedToday >= 2) {
      multiplier = 1.25; // +25% for 2 quests
    }

    // Bonus for completing both daily challenge and weekly goal on same day
    if (isDailyChallenge && isWeeklyGoal) {
      multiplier += 0.25; // Additional +25% bonus
    }

    final finalXP = (baseXP * multiplier).round();

    _logger.i(
      'XP Calculation: Base=$baseXP, Multiplier=${multiplier}x, Final=$finalXP',
    );

    return finalXP;
  }

  /// Award XP with combo multiplier support
  /// Call this instead of awardXP when you want to apply combo bonuses
  Future<void> awardXPWithCombo(
    String action, {
    required int baseXP,
    bool isDailyChallenge = false,
    bool isWeeklyGoal = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get today's quest completion count
      final today = DateTime.now();
      final todayKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();
      final userData = userDoc.data() ?? {};

      final dailyStats =
          userData['dailyQuestStats'] as Map<String, dynamic>? ?? {};
      final todayStats = dailyStats[todayKey] as Map<String, dynamic>? ?? {};
      final questsCompletedToday = (todayStats['questsCompleted'] as int? ?? 0);

      // Calculate final XP with multiplier
      final finalXP = calculateXPWithMultiplier(
        baseXP: baseXP,
        isDailyChallenge: isDailyChallenge,
        isWeeklyGoal: isWeeklyGoal,
        questsCompletedToday: questsCompletedToday,
      );

      // Award the XP
      await awardXP(action, customAmount: finalXP);

      // Update daily quest stats
      await _updateDailyQuestStats(
        user.uid,
        todayKey,
        isDailyChallenge,
        isWeeklyGoal,
        questsCompletedToday + 1,
      );

      // Check for combo badge
      await _checkComboAchievements(user.uid, isDailyChallenge && isWeeklyGoal);
    } catch (e) {
      _logger.e('Error awarding XP with combo: $e');
    }
  }

  /// Update daily quest statistics
  Future<void> _updateDailyQuestStats(
    String userId,
    String todayKey,
    bool isDailyChallenge,
    bool isWeeklyGoal,
    int newCount,
  ) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      final updates = <String, dynamic>{
        'dailyQuestStats.$todayKey.questsCompleted': newCount,
        'dailyQuestStats.$todayKey.lastUpdated': FieldValue.serverTimestamp(),
      };

      // Track if both types completed on same day
      if (isDailyChallenge && isWeeklyGoal) {
        updates['stats.comboCompletions'] = FieldValue.increment(1);
      }

      await userRef.update(updates);
    } catch (e) {
      _logger.e('Error updating daily quest stats: $e');
    }
  }

  /// Check and award combo achievement badges
  Future<void> _checkComboAchievements(String userId, bool isCombo) async {
    if (!isCombo) return;

    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      final userData = userDoc.data() ?? {};

      final comboCount = userData['stats']?['comboCompletions'] as int? ?? 0;

      if (comboCount >= 10) {
        await _awardBadge(userId, 'combo_master');
      }
    } catch (e) {
      _logger.e('Error checking combo achievements: $e');
    }
  }

  /// Check quest milestone badges
  /// Call this after any quest completion
  Future<void> checkQuestMilestones(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      final userData = userDoc.data() ?? {};

      final challengesCompleted =
          userData['stats']?['challengesCompleted'] as int? ?? 0;
      final weeklyGoalsCompleted =
          userData['stats']?['weeklyGoalsCompleted'] as int? ?? 0;
      final totalQuests = challengesCompleted + weeklyGoalsCompleted;

      // Award milestone badges
      if (totalQuests >= 100) await _awardBadge(userId, 'century_quester');
      if (totalQuests >= 250) await _awardBadge(userId, 'quest_veteran');
      if (totalQuests >= 500) await _awardBadge(userId, 'quest_grandmaster');
    } catch (e) {
      _logger.e('Error checking quest milestones: $e');
    }
  }

  /// Track category-specific streaks
  /// Call this when a challenge of a specific category is completed
  Future<void> trackCategoryStreak(
    String userId,
    String category, // 'photography', 'exploration', 'social', etc.
  ) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final today = DateTime.now();
      final todayKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        final userData = userDoc.data() ?? {};

        final categoryStreaks =
            userData['categoryStreaks'] as Map<String, dynamic>? ?? {};
        final categoryData =
            categoryStreaks[category] as Map<String, dynamic>? ?? {};

        final lastCompletionDate = categoryData['lastDate'] as String?;
        final currentStreak = categoryData['currentStreak'] as int? ?? 0;
        final longestStreak = categoryData['longestStreak'] as int? ?? 0;

        // Calculate new streak
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayKey =
            '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

        int newStreak;
        if (lastCompletionDate == todayKey) {
          // Already completed today, don't update
          return;
        } else if (lastCompletionDate == yesterdayKey) {
          // Continuing streak
          newStreak = currentStreak + 1;
        } else {
          // New streak
          newStreak = 1;
        }

        final updates = <String, dynamic>{
          'categoryStreaks.$category.currentStreak': newStreak,
          'categoryStreaks.$category.longestStreak': newStreak > longestStreak
              ? newStreak
              : longestStreak,
          'categoryStreaks.$category.lastDate': todayKey,
          'categoryStreaks.$category.totalCompleted': FieldValue.increment(1),
        };

        transaction.update(userRef, updates);
      });

      _logger.i('Updated $category streak for user $userId');
    } catch (e) {
      _logger.e('Error tracking category streak: $e');
    }
  }

  /// Get category streak information
  Future<Map<String, dynamic>> getCategoryStreaks(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};

      return userData['categoryStreaks'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      _logger.e('Error getting category streaks: $e');
      return {};
    }
  }

  /// Get today's quest completion count
  Future<int> getTodayQuestCount(String userId) async {
    try {
      final today = DateTime.now();
      final todayKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};

      final dailyStats =
          userData['dailyQuestStats'] as Map<String, dynamic>? ?? {};
      final todayStats = dailyStats[todayKey] as Map<String, dynamic>? ?? {};

      return todayStats['questsCompleted'] as int? ?? 0;
    } catch (e) {
      _logger.e('Error getting today quest count: $e');
      return 0;
    }
  }
}
