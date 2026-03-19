import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/logger.dart';

class UserProgressionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static final Map<String, Future<Map<String, dynamic>>> _dailyLoginInFlight =
      {};

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

  String getLevelTitle(int level) {
    return (levelSystem[level]?['title'] as String?) ?? 'Unknown Level';
  }

  Map<String, int> getLevelXPRange(int level) {
    final levelData = levelSystem[level];
    if (levelData == null) return {'min': 0, 'max': 199};
    return {'min': levelData['minXP'] as int, 'max': levelData['maxXP'] as int};
  }

  double getLevelProgress(int currentXP, int level) {
    final range = getLevelXPRange(level);
    if (level >= 10) return 1.0;

    final progressXP = currentXP - range['min']!;
    final requiredXP = range['max']! - range['min']! + 1;
    return (progressXP / requiredXP).clamp(0.0, 1.0);
  }

  List<String> getLevelPerks(int level) {
    final perks = <String>[];
    for (final entry in levelPerks.entries) {
      if (level >= entry.key) {
        perks.addAll(entry.value);
      }
    }
    return perks;
  }

  Future<Map<String, dynamic>> processDailyLogin(String userId) async {
    final inFlight = _dailyLoginInFlight[userId];
    if (inFlight != null) return inFlight;

    final future = _processDailyLoginInternal(userId);
    _dailyLoginInFlight[userId] = future;
    try {
      return await future;
    } finally {
      _dailyLoginInFlight.remove(userId);
    }
  }

  Future<Map<String, dynamic>> _processDailyLoginInternal(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final today = DateTime.now();
      final todayKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      return await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        final userData = userDoc.data() ?? <String, dynamic>{};

        final lastLoginDate = userData['lastLoginDate'] as String?;
        final currentLoginStreak =
            userData['stats']?['loginStreak'] as int? ?? 0;
        final longestLoginStreak =
            userData['stats']?['longestLoginStreak'] as int? ?? 0;

        if (lastLoginDate == todayKey) {
          return {
            'alreadyLoggedIn': true,
            'streak': currentLoginStreak,
            'xpAwarded': 0,
          };
        }

        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayKey =
            '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

        final newStreak = lastLoginDate == yesterdayKey
            ? currentLoginStreak + 1
            : 1;

        var xpReward = 10;
        if (newStreak >= 7) {
          xpReward = 50;
        } else if (newStreak >= 3) {
          xpReward = 25;
        } else if (newStreak >= 2) {
          xpReward = 15;
        }

        if (newStreak == 7) xpReward += 50;
        if (newStreak == 30) xpReward += 100;
        if (newStreak == 100) xpReward += 500;

        final currentXP = userData['experiencePoints'] as int? ?? 0;
        final newXP = currentXP + xpReward;
        final newLevel = _calculateLevel(newXP);

        transaction.update(userRef, {
          'lastLoginDate': todayKey,
          'experiencePoints': newXP,
          'level': newLevel,
          'stats.loginStreak': newStreak,
          'stats.longestLoginStreak':
              newStreak > longestLoginStreak ? newStreak : longestLoginStreak,
          'lastXPGain': FieldValue.serverTimestamp(),
        });

        return {
          'alreadyLoggedIn': false,
          'streak': newStreak,
          'xpAwarded': xpReward,
          'newXP': newXP,
          'newLevel': newLevel,
        };
      });
    } catch (e) {
      AppLogger.error('Error processing daily login: $e');
      return {
        'alreadyLoggedIn': false,
        'streak': 0,
        'xpAwarded': 0,
      };
    }
  }

  Future<void> processCurrentUserDailyLogin() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    await processDailyLogin(userId);
  }

  int _calculateLevel(int xp) {
    for (final entry in levelSystem.entries.toList().reversed) {
      if (xp >= (entry.value['minXP'] as int)) {
        return entry.key;
      }
    }
    return 1;
  }
}
