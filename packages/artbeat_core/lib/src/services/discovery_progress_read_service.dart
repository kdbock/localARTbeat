import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/logger.dart';

class DiscoveryProgressReadService {
  FirebaseFirestore? _firestoreInstance;
  FirebaseAuth? _authInstance;

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

  Future<Map<String, int>> getUserProgressStats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {'totalDiscoveries': 0, 'currentStreak': 0, 'weeklyProgress': 0};
      }

      final totalDiscoveries = await getDiscoveryCount(userId);
      final streak = await getDiscoveryStreak(userId);

      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDate = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );

      final weeklySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('discoveries')
          .where('discoveredAt', isGreaterThanOrEqualTo: startOfWeekDate)
          .count()
          .get();

      final weeklyProgress = weeklySnapshot.count ?? 0;

      return {
        'totalDiscoveries': totalDiscoveries,
        'currentStreak': streak,
        'weeklyProgress': weeklyProgress,
      };
    } catch (e) {
      AppLogger.error('Error getting user progress stats: $e');
      return {'totalDiscoveries': 0, 'currentStreak': 0, 'weeklyProgress': 0};
    }
  }

  Future<int> getDiscoveryCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('discoveries')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Error getting discovery count: $e');
      return 0;
    }
  }

  Future<int> getDiscoveryStreak(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('discoveries')
          .where('discoveredAt', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .orderBy('discoveredAt', descending: true)
          .get();

      if (snapshot.docs.isEmpty) return 0;

      final discoveryDates = <String, bool>{};
      for (final doc in snapshot.docs) {
        final discoveredAtTimestamp = doc.data()['discoveredAt'] as Timestamp?;
        final discoveredAt = (discoveredAtTimestamp ?? Timestamp.now())
            .toDate();
        final dateKey =
            '${discoveredAt.year}-${discoveredAt.month.toString().padLeft(2, '0')}-${discoveredAt.day.toString().padLeft(2, '0')}';
        discoveryDates[dateKey] = true;
      }

      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayKey =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      int startOffset = 0;
      if (discoveryDates.containsKey(today)) {
        startOffset = 0;
      } else if (discoveryDates.containsKey(yesterdayKey)) {
        startOffset = 1;
      } else {
        return 0;
      }

      var streak = 0;
      for (int i = startOffset; i < 30; i++) {
        final checkDate = now.subtract(Duration(days: i));
        final dateKey =
            '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

        if (discoveryDates.containsKey(dateKey)) {
          streak++;
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      AppLogger.error('Error getting discovery streak: $e');
      return 0;
    }
  }
}
