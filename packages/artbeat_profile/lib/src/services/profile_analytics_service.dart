import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/profile_analytics_model.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Service for managing profile analytics and user engagement metrics
class ProfileAnalyticsService extends ChangeNotifier {
  static final ProfileAnalyticsService _instance =
      ProfileAnalyticsService._internal();
  factory ProfileAnalyticsService() => _instance;
  ProfileAnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _analyticsCollection =>
      _firestore.collection('profile_analytics');

  /// Get profile analytics for a user
  Future<ProfileAnalyticsModel?> getProfileAnalytics(String userId) async {
    try {
      final doc = await _analyticsCollection.doc(userId).get();
      if (doc.exists) {
        return ProfileAnalyticsModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting profile analytics: $e');
      return null;
    }
  }

  /// Get profile view statistics for a specific time period
  Future<Map<String, int>> getProfileViewStats(
    String userId, {
    int days = 30,
  }) async {
    try {
      final analytics = await getProfileAnalytics(userId);
      if (analytics == null) return {};

      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: days));

      final filteredViews = <String, int>{};
      analytics.dailyViews.forEach((date, views) {
        final dateTime = DateTime.parse(date);
        if (dateTime.isAfter(cutoffDate)) {
          filteredViews[date] = views;
        }
      });

      return filteredViews;
    } catch (e) {
      AppLogger.error('Error getting profile view stats: $e');
      return {};
    }
  }

  /// Get comprehensive engagement metrics for a user
  Future<Map<String, dynamic>> getEngagementMetrics(String userId) async {
    try {
      final analytics = await getProfileAnalytics(userId);
      if (analytics == null) {
        return {
          'totalEngagements': 0,
          'engagementRate': 0.0,
          'avgViewsPerDay': 0.0,
          'peakEngagementDay': null,
          'growthTrend': 'stable',
        };
      }

      // Calculate average views per day
      final totalDays = analytics.dailyViews.length;
      final totalViews = analytics.dailyViews.values.fold(
        0,
        (sum, views) => sum + views,
      );
      final avgViewsPerDay = totalDays > 0 ? totalViews / totalDays : 0.0;

      // Find peak engagement day
      String? peakDay;
      int maxViews = 0;
      analytics.dailyViews.forEach((date, views) {
        if (views > maxViews) {
          maxViews = views;
          peakDay = date;
        }
      });

      // Calculate growth trend (simplified)
      String growthTrend = 'stable';
      if (analytics.dailyViews.length >= 6) {
        final values = analytics.dailyViews.values.toList();
        final recentViews = values
            .skip(values.length - 3)
            .fold<int>(0, (int sum, int views) => sum + views);
        final olderViews = values
            .take(3)
            .fold<int>(0, (int sum, int views) => sum + views);

        if (recentViews > olderViews * 1.2) {
          growthTrend = 'growing';
        } else if (recentViews < olderViews * 0.8) {
          growthTrend = 'declining';
        }
      }

      return {
        'totalEngagements': analytics.totalEngagements,
        'engagementRate': analytics.engagementRate,
        'avgViewsPerDay': avgViewsPerDay,
        'peakEngagementDay': peakDay,
        'growthTrend': growthTrend,
        'totalPosts': analytics.totalPosts,
        'profileViews': analytics.profileViews,
      };
    } catch (e) {
      AppLogger.error('Error getting engagement metrics: $e');
      return {};
    }
  }

  /// Update profile view count (called when someone views a profile)
  Future<void> updateProfileViewCount(
    String userId, {
    String? viewerUserId,
  }) async {
    try {
      final today = DateTime.now();
      final todayString = today.toIso8601String().split(
        'T',
      )[0]; // YYYY-MM-DD format

      await _firestore.runTransaction((transaction) async {
        final docRef = _analyticsCollection.doc(userId);
        final doc = await transaction.get(docRef);

        if (doc.exists) {
          final analytics = ProfileAnalyticsModel.fromFirestore(doc);
          final updatedDailyViews = Map<String, int>.from(analytics.dailyViews);
          updatedDailyViews[todayString] =
              (updatedDailyViews[todayString] ?? 0) + 1;

          // Add viewer to recent interactions if provided
          final updatedRecentInteractions = List<String>.from(
            analytics.recentInteractions,
          );
          if (viewerUserId != null &&
              !updatedRecentInteractions.contains(viewerUserId)) {
            updatedRecentInteractions.insert(0, viewerUserId);
            // Keep only the last 50 interactions
            if (updatedRecentInteractions.length > 50) {
              updatedRecentInteractions.removeRange(
                50,
                updatedRecentInteractions.length,
              );
            }
          }

          final updatedAnalytics = analytics.copyWith(
            profileViews: analytics.profileViews + 1,
            dailyViews: updatedDailyViews,
            recentInteractions: updatedRecentInteractions,
            lastUpdated: today,
          );

          transaction.update(docRef, updatedAnalytics.toFirestore());
        } else {
          // Create new analytics document
          final newAnalytics = ProfileAnalyticsModel(
            userId: userId,
            profileViews: 1,
            dailyViews: {todayString: 1},
            recentInteractions: viewerUserId != null ? [viewerUserId] : [],
            lastUpdated: today,
            periodStart: today,
            periodEnd: today.add(
              const Duration(days: 365),
            ), // Default 1-year period
          );

          transaction.set(docRef, newAnalytics.toFirestore());
        }
      });

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error updating profile view count: $e');
    }
  }

  /// Update engagement metrics (likes, comments, shares, etc.)
  Future<void> updateEngagementMetrics(
    String userId, {
    int? likes,
    int? comments,
    int? shares,
    int? mentions,
  }) async {
    try {
      final docRef = _analyticsCollection.doc(userId);
      final doc = await docRef.get();

      if (doc.exists) {
        final analytics = ProfileAnalyticsModel.fromFirestore(doc);

        final updatedAnalytics = analytics.copyWith(
          totalLikes: likes != null
              ? analytics.totalLikes + likes
              : analytics.totalLikes,
          totalComments: comments != null
              ? analytics.totalComments + comments
              : analytics.totalComments,
          totalShares: shares != null
              ? analytics.totalShares + shares
              : analytics.totalShares,
          totalMentions: mentions != null
              ? analytics.totalMentions + mentions
              : analytics.totalMentions,
          lastUpdated: DateTime.now(),
        );

        await docRef.update(updatedAnalytics.toFirestore());
      } else {
        // Create new analytics with initial engagement
        final newAnalytics = ProfileAnalyticsModel(
          userId: userId,
          totalLikes: likes ?? 0,
          totalComments: comments ?? 0,
          totalShares: shares ?? 0,
          totalMentions: mentions ?? 0,
          lastUpdated: DateTime.now(),
          periodStart: DateTime.now(),
          periodEnd: DateTime.now().add(const Duration(days: 365)),
        );

        await docRef.set(newAnalytics.toFirestore());
      }

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error updating engagement metrics: $e');
    }
  }

  /// Get analytics for multiple users (for comparison or leaderboards)
  Future<List<ProfileAnalyticsModel>> getBulkAnalytics(
    List<String> userIds,
  ) async {
    try {
      if (userIds.isEmpty) return [];

      final analytics = <ProfileAnalyticsModel>[];

      // Process in batches of 10 (Firestore limit for 'in' queries)
      for (int i = 0; i < userIds.length; i += 10) {
        final batchUserIds = userIds.skip(i).take(10).toList();

        final query = await _analyticsCollection
            .where(FieldPath.documentId, whereIn: batchUserIds)
            .get();

        for (final doc in query.docs) {
          analytics.add(ProfileAnalyticsModel.fromFirestore(doc));
        }
      }

      return analytics;
    } catch (e) {
      AppLogger.error('Error getting bulk analytics: $e');
      return [];
    }
  }

  /// Get top performing profiles by a specific metric
  Future<List<ProfileAnalyticsModel>> getTopProfiles({
    String orderBy = 'profileViews',
    int limit = 10,
    DateTime? since,
  }) async {
    try {
      Query query = _analyticsCollection
          .orderBy(orderBy, descending: true)
          .limit(limit);

      if (since != null) {
        query = query.where(
          'lastUpdated',
          isGreaterThan: Timestamp.fromDate(since),
        );
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => ProfileAnalyticsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting top profiles: $e');
      return [];
    }
  }

  /// Reset analytics for a user (useful for testing or user request)
  Future<void> resetAnalytics(String userId) async {
    try {
      await _analyticsCollection.doc(userId).delete();
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error resetting analytics: $e');
    }
  }

  /// Stream profile analytics for real-time updates
  Stream<ProfileAnalyticsModel?> streamProfileAnalytics(String userId) {
    return _analyticsCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return ProfileAnalyticsModel.fromFirestore(doc);
      }
      return null;
    });
  }
}
