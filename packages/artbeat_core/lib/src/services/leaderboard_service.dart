import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

enum LeaderboardCategory {
  totalXP,
  capturesCreated,
  artWalksCompleted,
  artWalksCreated,
  level,
  highestRatedCapture,
  highestRatedArtWalk,
}

extension LeaderboardCategoryExtension on LeaderboardCategory {
  String get displayName {
    switch (this) {
      case LeaderboardCategory.totalXP:
        return 'Total Experience';
      case LeaderboardCategory.capturesCreated:
        return 'Captures Created';
      case LeaderboardCategory.artWalksCompleted:
        return 'Art Walks Completed';
      case LeaderboardCategory.artWalksCreated:
        return 'Art Walks Created';
      case LeaderboardCategory.level:
        return 'Highest Level';
      case LeaderboardCategory.highestRatedCapture:
        return 'Highest Rated Capture';
      case LeaderboardCategory.highestRatedArtWalk:
        return 'Highest Rated Art Walk';
    }
  }

  String get icon {
    switch (this) {
      case LeaderboardCategory.totalXP:
        return '⚡';
      case LeaderboardCategory.capturesCreated:
        return '📸';
      case LeaderboardCategory.artWalksCompleted:
        return '🚶';
      case LeaderboardCategory.artWalksCreated:
        return '🎨';
      case LeaderboardCategory.level:
        return '👑';
      case LeaderboardCategory.highestRatedCapture:
        return '⭐';
      case LeaderboardCategory.highestRatedArtWalk:
        return '🏆';
    }
  }

  String get fieldPath {
    switch (this) {
      case LeaderboardCategory.totalXP:
        return 'experiencePoints';
      case LeaderboardCategory.capturesCreated:
        return 'stats.capturesCreated';
      case LeaderboardCategory.artWalksCompleted:
        return 'stats.walksCompleted';
      case LeaderboardCategory.artWalksCreated:
        return 'stats.walksCreated';
      case LeaderboardCategory.level:
        return 'level';
      case LeaderboardCategory.highestRatedCapture:
        return 'stats.highestRatedCapture';
      case LeaderboardCategory.highestRatedArtWalk:
        return 'stats.highestRatedArtWalk';
    }
  }
}

class LeaderboardEntry {
  final String userId;
  final String username;
  final String? fullName;
  final String? profileImageUrl;
  final int value;
  final int rank;
  final int level;
  final int experiencePoints;
  final Map<String, int> stats;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    this.fullName,
    this.profileImageUrl,
    required this.value,
    required this.rank,
    required this.level,
    required this.experiencePoints,
    required this.stats,
  });

  factory LeaderboardEntry.fromUserData(
    Map<String, dynamic> userData,
    LeaderboardCategory category,
    int rank,
  ) {
    final stats = userData['stats'] as Map<String, dynamic>? ?? {};
    final statsInt = stats.map(
      (key, value) => MapEntry(key, value as int? ?? 0),
    );

    int value;
    switch (category) {
      case LeaderboardCategory.totalXP:
        value = userData['experiencePoints'] as int? ?? 0;
        break;
      case LeaderboardCategory.level:
        value = userData['level'] as int? ?? 1;
        break;
      case LeaderboardCategory.capturesCreated:
        value = statsInt['capturesCreated'] ?? 0;
        break;
      case LeaderboardCategory.artWalksCompleted:
        value = statsInt['walksCompleted'] ?? 0;
        break;
      case LeaderboardCategory.artWalksCreated:
        value = statsInt['walksCreated'] ?? 0;
        break;
      case LeaderboardCategory.highestRatedCapture:
        // For ratings, we'll use a scaled value (rating * 100) to handle decimals
        final rating = statsInt['highestRatedCapture'] ?? 0;
        value = rating;
        break;
      case LeaderboardCategory.highestRatedArtWalk:
        // For ratings, we'll use a scaled value (rating * 100) to handle decimals
        final rating = statsInt['highestRatedArtWalk'] ?? 0;
        value = rating;
        break;
    }

    return LeaderboardEntry(
      userId: userData['id'] as String,
      username: userData['username'] as String? ?? 'Unknown User',
      fullName: userData['fullName'] as String?,
      profileImageUrl: userData['profileImageUrl'] as String?,
      value: value,
      rank: rank,
      level: userData['level'] as int? ?? 1,
      experiencePoints: userData['experiencePoints'] as int? ?? 0,
      stats: statsInt,
    );
  }

  String get displayName => fullName ?? username;
}

class LeaderboardService extends ChangeNotifier {
  static final LeaderboardService _instance = LeaderboardService._internal();
  factory LeaderboardService() => _instance;
  LeaderboardService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Get leaderboard for a specific category
  Future<List<LeaderboardEntry>> getLeaderboard(
    LeaderboardCategory category, {
    int limit = 50,
    String? currentUserId,
  }) async {
    try {
      AppLogger.info('🏆 Getting leaderboard for ${category.displayName} from collection: ${_usersCollection.path}');

      Query query;

      // For some categories, we want to include users with 0 values if they have related activity
      if (category == LeaderboardCategory.totalXP) {
        // Include all users, even those with 0 XP, but order by XP descending
        query = _usersCollection
            .orderBy(category.fieldPath, descending: true)
            .limit(limit);
      } else if (category == LeaderboardCategory.capturesCreated) {
        // Include users who have created captures, even if stats show 0
        query = _usersCollection
            .orderBy(category.fieldPath, descending: true)
            .limit(limit);
      } else if (category == LeaderboardCategory.artWalksCreated ||
          category == LeaderboardCategory.artWalksCompleted) {
        // Include users who might have art walk activity, even if stats show 0
        query = _usersCollection
            .orderBy(category.fieldPath, descending: true)
            .limit(limit);
      } else {
        // For rating categories, only show users with positive values
        query = _usersCollection
            .where(category.fieldPath, isGreaterThan: 0)
            .orderBy(category.fieldPath, descending: true)
            .limit(limit);
      }

      final snapshot = await query.get();
      AppLogger.info('🏆 Firestore returned ${snapshot.docs.length} documents for ${category.displayName}');

      final List<LeaderboardEntry> entries = [];

      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final userData = doc.data() as Map<String, dynamic>;
        userData['id'] = doc.id; // Add document ID

        final entry = LeaderboardEntry.fromUserData(userData, category, i + 1);
        entries.add(entry);

        // Debug logging
        AppLogger.info(
          '🏆 Entry ${i + 1}: ID: ${doc.id}, Name: ${entry.fullName ?? entry.username}, XP: ${entry.experiencePoints}, Value: ${entry.value}',
        );
      }

      AppLogger.info('🏆 Found ${entries.length} leaderboard entries total');
      return entries;
    } catch (e) {
      AppLogger.error('❌ Error getting leaderboard: $e');
      // If the ordered query fails (e.g. index missing), try a simple fetch as last resort
      try {
        AppLogger.warning('🏆 Trying fallback simple fetch for ${category.displayName}...');
        final fallbackSnapshot = await _usersCollection.limit(limit).get();
        final List<LeaderboardEntry> fallbackEntries = [];
        for (int i = 0; i < fallbackSnapshot.docs.length; i++) {
          final doc = fallbackSnapshot.docs[i];
          final userData = doc.data() as Map<String, dynamic>;
          userData['id'] = doc.id;
          fallbackEntries.add(LeaderboardEntry.fromUserData(userData, category, i + 1));
        }
        return fallbackEntries;
      } catch (fallbackError) {
        AppLogger.error('❌ Fallback fetch also failed: $fallbackError');
        return [];
      }
    }
  }

  /// Get user's rank in a specific category
  Future<int?> getUserRank(String userId, LeaderboardCategory category) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data() as Map<String, dynamic>;
      int userValue;

      switch (category) {
        case LeaderboardCategory.totalXP:
          userValue = userData['experiencePoints'] as int? ?? 0;
          break;
        case LeaderboardCategory.level:
          userValue = userData['level'] as int? ?? 1;
          break;
        case LeaderboardCategory.capturesCreated:
          userValue = userData['stats']?['capturesCreated'] as int? ?? 0;
          break;
        case LeaderboardCategory.artWalksCompleted:
          userValue = userData['stats']?['walksCompleted'] as int? ?? 0;
          break;
        case LeaderboardCategory.artWalksCreated:
          userValue = userData['stats']?['walksCreated'] as int? ?? 0;
          break;
        case LeaderboardCategory.highestRatedCapture:
          userValue = userData['stats']?['highestRatedCapture'] as int? ?? 0;
          break;
        case LeaderboardCategory.highestRatedArtWalk:
          userValue = userData['stats']?['highestRatedArtWalk'] as int? ?? 0;
          break;
      }

      // Count users with higher values
      final higherUsersSnapshot = await _usersCollection
          .where(category.fieldPath, isGreaterThan: userValue)
          .get();

      return higherUsersSnapshot.docs.length + 1;
    } catch (e) {
      AppLogger.error('❌ Error getting user rank: $e');
      return null;
    }
  }

  /// Get current user's position and nearby users in leaderboard
  Future<Map<String, dynamic>?> getCurrentUserLeaderboardInfo(
    LeaderboardCategory category,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    try {
      final userRank = await getUserRank(currentUser.uid, category);
      if (userRank == null) return null;

      // Get users around current user (5 above, current user, 5 below)
      final fullLeaderboard = await getLeaderboard(category, limit: 200);

      final userIndex = fullLeaderboard.indexWhere(
        (entry) => entry.userId == currentUser.uid,
      );
      if (userIndex == -1) return null;

      final start = (userIndex - 5).clamp(0, fullLeaderboard.length);
      final end = (userIndex + 6).clamp(0, fullLeaderboard.length);

      final nearbyUsers = fullLeaderboard.sublist(start, end);
      final currentUserEntry = fullLeaderboard[userIndex];

      return {
        'currentUser': currentUserEntry,
        'nearbyUsers': nearbyUsers,
        'totalUsers': fullLeaderboard.length,
      };
    } catch (e) {
      AppLogger.error('❌ Error getting current user leaderboard info: $e');
      return null;
    }
  }

  /// Get multiple leaderboard categories at once
  Future<Map<LeaderboardCategory, List<LeaderboardEntry>>>
  getMultipleLeaderboards({
    List<LeaderboardCategory> categories = const [
      LeaderboardCategory.totalXP,
      LeaderboardCategory.capturesCreated,
      LeaderboardCategory.artWalksCompleted,
      LeaderboardCategory.artWalksCreated,
      LeaderboardCategory.level,
      LeaderboardCategory.highestRatedCapture,
      LeaderboardCategory.highestRatedArtWalk,
    ],
    int limit = 10,
  }) async {
    final Map<LeaderboardCategory, List<LeaderboardEntry>> results = {};

    for (final category in categories) {
      results[category] = await getLeaderboard(category, limit: limit);
    }

    return results;
  }

  /// Get leaderboard stats summary
  Future<Map<String, dynamic>> getLeaderboardStats() async {
    try {
      final usersSnapshot = await _usersCollection
          .where('experiencePoints', isGreaterThan: 0)
          .get();

      final int totalUsers = usersSnapshot.docs.length;
      int totalXP = 0;
      int totalCaptures = 0;
      int totalWalksCompleted = 0;
      int totalWalksCreated = 0;

      final Map<int, int> levelDistribution = {};

      for (final doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final stats = data['stats'] as Map<String, dynamic>? ?? {};

        totalXP += data['experiencePoints'] as int? ?? 0;
        totalCaptures += stats['capturesCreated'] as int? ?? 0;
        totalWalksCompleted += stats['walksCompleted'] as int? ?? 0;
        totalWalksCreated += stats['walksCreated'] as int? ?? 0;

        final level = data['level'] as int? ?? 1;
        levelDistribution[level] = (levelDistribution[level] ?? 0) + 1;
      }

      return {
        'totalUsers': totalUsers,
        'totalXP': totalXP,
        'averageXP': totalUsers > 0 ? (totalXP / totalUsers).round() : 0,
        'totalCaptures': totalCaptures,
        'totalWalksCompleted': totalWalksCompleted,
        'totalWalksCreated': totalWalksCreated,
        'levelDistribution': levelDistribution,
      };
    } catch (e) {
      AppLogger.error('❌ Error getting leaderboard stats: $e');
      return {};
    }
  }
}
