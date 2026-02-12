import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/analytics_model.dart';

/// Service for analytics operations
class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get analytics data for the specified date range
  Future<AnalyticsModel> getAnalytics({
    required DateRange dateRange,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = dateRange.startDate;

      // Get previous period for comparison
      final previousPeriod = endDate.difference(startDate);
      final previousStartDate = startDate.subtract(previousPeriod);

      // Fetch all data in parallel
      final futures = await Future.wait([
        _getUserMetrics(startDate, endDate),
        _getUserMetrics(previousStartDate, startDate), // Previous period
        _getContentMetrics(startDate, endDate),
        _getContentMetrics(previousStartDate, startDate), // Previous period
        _getEngagementMetrics(startDate, endDate),
        _getEngagementMetrics(previousStartDate, startDate), // Previous period
        _getTechnicalMetrics(startDate, endDate),
        _getTechnicalMetrics(previousStartDate, startDate), // Previous period
        _getTopContent(startDate, endDate),
      ]);

      final currentUserMetrics = futures[0] as Map<String, dynamic>;
      final previousUserMetrics = futures[1] as Map<String, dynamic>;
      final currentContentMetrics = futures[2] as Map<String, dynamic>;
      final previousContentMetrics = futures[3] as Map<String, dynamic>;
      final currentEngagementMetrics = futures[4] as Map<String, dynamic>;
      final previousEngagementMetrics = futures[5] as Map<String, dynamic>;
      final currentTechnicalMetrics = futures[6] as Map<String, dynamic>;
      final previousTechnicalMetrics = futures[7] as Map<String, dynamic>;
      final topContent = futures[8] as List<TopContentItem>;

      return AnalyticsModel(
        // User metrics
        totalUsers: (currentUserMetrics['totalUsers'] as int?) ?? 0,
        activeUsers: (currentUserMetrics['activeUsers'] as int?) ?? 0,
        newUsers: (currentUserMetrics['newUsers'] as int?) ?? 0,
        retentionRate:
            ((currentUserMetrics['retentionRate'] as num?) ?? 0.0).toDouble(),
        userGrowth: _calculateGrowth(
          currentUserMetrics['totalUsers'],
          previousUserMetrics['totalUsers'],
        ),
        activeUserGrowth: _calculateGrowth(
          currentUserMetrics['activeUsers'],
          previousUserMetrics['activeUsers'],
        ),
        newUserGrowth: _calculateGrowth(
          currentUserMetrics['newUsers'],
          previousUserMetrics['newUsers'],
        ),
        retentionChange: _calculateGrowth(
          currentUserMetrics['retentionRate'],
          previousUserMetrics['retentionRate'],
        ),

        // Content metrics
        totalArtworks: (currentContentMetrics['totalArtworks'] as int?) ?? 0,
        totalPosts: (currentContentMetrics['totalPosts'] as int?) ?? 0,
        totalComments: (currentContentMetrics['totalComments'] as int?) ?? 0,
        totalEvents: (currentContentMetrics['totalEvents'] as int?) ?? 0,
        artworkGrowth: _calculateGrowth(
          currentContentMetrics['totalArtworks'],
          previousContentMetrics['totalArtworks'],
        ),
        postGrowth: _calculateGrowth(
          currentContentMetrics['totalPosts'],
          previousContentMetrics['totalPosts'],
        ),
        commentGrowth: _calculateGrowth(
          currentContentMetrics['totalComments'],
          previousContentMetrics['totalComments'],
        ),
        eventGrowth: _calculateGrowth(
          currentContentMetrics['totalEvents'],
          previousContentMetrics['totalEvents'],
        ),

        // Engagement metrics
        avgSessionDuration:
            (currentEngagementMetrics['avgSessionDuration'] as double?) ?? 0.0,
        pageViews: (currentEngagementMetrics['pageViews'] as int?) ?? 0,
        bounceRate: (currentEngagementMetrics['bounceRate'] as double?) ?? 0.0,
        totalLikes: (currentEngagementMetrics['totalLikes'] as int?) ?? 0,
        sessionDurationChange: _calculateGrowth(
          currentEngagementMetrics['avgSessionDuration'] as double? ?? 0.0,
          previousEngagementMetrics['avgSessionDuration'] as double? ?? 0.0,
        ),
        pageViewGrowth: _calculateGrowth(
          currentEngagementMetrics['pageViews'] as int? ?? 0,
          previousEngagementMetrics['pageViews'] as int? ?? 0,
        ),
        bounceRateChange: _calculateGrowth(
          currentEngagementMetrics['bounceRate'] as double? ?? 0.0,
          previousEngagementMetrics['bounceRate'] as double? ?? 0.0,
        ),
        likeGrowth: _calculateGrowth(
          currentEngagementMetrics['totalLikes'] as int? ?? 0,
          previousEngagementMetrics['totalLikes'] as int? ?? 0,
        ),

        // Technical metrics
        errorRate: (currentTechnicalMetrics['errorRate'] as double?) ?? 0.0,
        avgResponseTime:
            (currentTechnicalMetrics['avgResponseTime'] as double?) ?? 0.0,
        storageUsed: (currentTechnicalMetrics['storageUsed'] as int?) ?? 0,
        bandwidthUsed: (currentTechnicalMetrics['bandwidthUsed'] as int?) ?? 0,
        errorRateChange: _calculateGrowth(
          currentTechnicalMetrics['errorRate'] as double? ?? 0.0,
          previousTechnicalMetrics['errorRate'] as double? ?? 0.0,
        ),
        responseTimeChange: _calculateGrowth(
          currentTechnicalMetrics['avgResponseTime'] as double? ?? 0.0,
          previousTechnicalMetrics['avgResponseTime'] as double? ?? 0.0,
        ),
        storageGrowth: _calculateGrowth(
          currentTechnicalMetrics['storageUsed'] as int? ?? 0,
          previousTechnicalMetrics['storageUsed'] as int? ?? 0,
        ),
        bandwidthChange: _calculateGrowth(
          currentTechnicalMetrics['bandwidthUsed'] as int? ?? 0,
          previousTechnicalMetrics['bandwidthUsed'] as int? ?? 0,
        ),

        // Top content
        topContent: topContent,

        // Meta data
        startDate: startDate,
        endDate: endDate,
        generatedAt: DateTime.now(),

        // Additional required parameters with default values
        financialMetrics: FinancialMetrics(
          totalRevenue: 0.0,
          subscriptionRevenue: 0.0,
          eventRevenue: 0.0,
          commissionRevenue: 0.0,
          averageRevenuePerUser: 0.0,
          monthlyRecurringRevenue: 0.0,
          churnRate: 0.0,
          lifetimeValue: 0.0,
          totalTransactions: 0,
          revenueGrowth: 0.0,
          subscriptionGrowth: 0.0,
          commissionGrowth: 0.0,
          revenueByCategory: const {},
          revenueTimeSeries: const [],
        ),
        cohortAnalysis: const [],
        usersByCountry: const {},
        deviceBreakdown: const {},
        topUserJourneys: const [],
        conversionFunnels: const {},
      );
    } catch (e) {
      throw Exception('Failed to get analytics: $e');
    }
  }

  /// Get user metrics for the specified date range
  Future<Map<String, dynamic>> _getUserMetrics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      final users = usersSnapshot.docs;

      final int totalUsers = users.length;
      int activeUsers = 0;
      int newUsers = 0;
      int retainedUsers = 0;

      for (var doc in users) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final lastActiveAt = (data['lastActiveAt'] as Timestamp?)?.toDate();

        // Count new users
        if (createdAt != null &&
            createdAt.isAfter(startDate) &&
            createdAt.isBefore(endDate)) {
          newUsers++;
        }

        // Count active users
        if (lastActiveAt != null &&
            lastActiveAt.isAfter(startDate) &&
            lastActiveAt.isBefore(endDate)) {
          activeUsers++;
        }

        // Count retained users (created before period, active during period)
        if (createdAt != null &&
            createdAt.isBefore(startDate) &&
            lastActiveAt != null &&
            lastActiveAt.isAfter(startDate) &&
            lastActiveAt.isBefore(endDate)) {
          retainedUsers++;
        }
      }

      // Calculate retention rate
      final double retentionRate =
          totalUsers > 0 ? (retainedUsers / totalUsers) * 100 : 0.0;

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'newUsers': newUsers,
        'retentionRate': retentionRate,
      };
    } catch (e) {
      throw Exception('Failed to get user metrics: $e');
    }
  }

  /// Get content metrics for the specified date range
  Future<Map<String, dynamic>> _getContentMetrics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final futures = await Future.wait([
        _getCollectionCount('artwork', startDate, endDate),
        _getCollectionCount('posts', startDate, endDate),
        _getCollectionCount('comments', startDate, endDate),
        _getCollectionCount('events', startDate, endDate),
      ]);

      return {
        'totalArtworks': futures[0],
        'totalPosts': futures[1],
        'totalComments': futures[2],
        'totalEvents': futures[3],
      };
    } catch (e) {
      throw Exception('Failed to get content metrics: $e');
    }
  }

  /// Get engagement metrics for the specified date range
  Future<Map<String, dynamic>> _getEngagementMetrics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Get session data (if available)
      final sessionSnapshot = await _firestore
          .collection('analytics_sessions')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .get();

      double avgSessionDuration = 0.0;
      int pageViews = 0;
      double bounceRate = 0.0;

      if (sessionSnapshot.docs.isNotEmpty) {
        double totalDuration = 0.0;
        final int totalSessions = sessionSnapshot.docs.length;
        int bounces = 0;

        for (var doc in sessionSnapshot.docs) {
          final data = doc.data();
          final duration = (data['duration'] as num?)?.toDouble() ?? 0.0;
          final views = (data['pageViews'] as num?)?.toInt() ?? 0;
          final isBounce = (data['isBounce'] as bool?) ?? false;

          totalDuration += duration;
          pageViews += views;
          if (isBounce) bounces++;
        }

        avgSessionDuration = totalDuration / totalSessions;
        bounceRate = (bounces / totalSessions) * 100;
      }

      // Get total likes
      int totalLikes = 0;
      final likesSnapshot = await _firestore
          .collection('likes')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .get();
      totalLikes = likesSnapshot.docs.length;

      return {
        'avgSessionDuration': avgSessionDuration,
        'pageViews': pageViews,
        'bounceRate': bounceRate,
        'totalLikes': totalLikes,
      };
    } catch (e) {
      throw Exception('Failed to get engagement metrics: $e');
    }
  }

  /// Get technical metrics for the specified date range
  Future<Map<String, dynamic>> _getTechnicalMetrics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Get error logs (if available)
      final errorSnapshot = await _firestore
          .collection('error_logs')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .get();

      // Get request logs (if available)
      final requestSnapshot = await _firestore
          .collection('request_logs')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .get();

      double errorRate = 0.0;
      double avgResponseTime = 0.0;

      if (requestSnapshot.docs.isNotEmpty) {
        final int totalRequests = requestSnapshot.docs.length;
        final int errors = errorSnapshot.docs.length;
        double totalResponseTime = 0.0;

        for (var doc in requestSnapshot.docs) {
          final data = doc.data();
          final responseTime =
              (data['responseTime'] as num?)?.toDouble() ?? 0.0;
          totalResponseTime += responseTime;
        }

        errorRate = (errors / totalRequests) * 100;
        avgResponseTime = totalResponseTime / totalRequests;
      }

      // Get actual storage and bandwidth data
      final storageMetrics = await _getStorageMetrics(startDate, endDate);
      final bandwidthMetrics = await _getBandwidthMetrics(startDate, endDate);

      return {
        'errorRate': errorRate,
        'avgResponseTime': avgResponseTime,
        'storageUsed': storageMetrics['storageUsed'] ?? 0,
        'bandwidthUsed': bandwidthMetrics['bandwidthUsed'] ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to get technical metrics: $e');
    }
  }

  /// Get top content for the specified date range
  Future<List<TopContentItem>> _getTopContent(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final List<TopContentItem> topContent = [];

      // Get top artworks
      final artworkSnapshot = await _firestore
          .collection('artwork')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .orderBy('views', descending: true)
          .limit(5)
          .get();

      for (var doc in artworkSnapshot.docs) {
        final data = doc.data();
        topContent.add(TopContentItem(
          id: doc.id,
          title:
              (data['title'] is String) ? data['title'] as String : 'Untitled',
          type: 'artwork',
          views: (data['views'] is int)
              ? data['views'] as int
              : int.tryParse(data['views']?.toString() ?? '') ?? 0,
          likes: (data['likes'] is int)
              ? data['likes'] as int
              : int.tryParse(data['likes']?.toString() ?? '') ?? 0,
          authorName: (data['authorName'] is String)
              ? data['authorName'] as String
              : 'Unknown',
          createdAt: (data['createdAt'] is Timestamp)
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
        ));
      }

      // Get top posts
      final postSnapshot = await _firestore
          .collection('posts')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .orderBy('views', descending: true)
          .limit(5)
          .get();

      for (var doc in postSnapshot.docs) {
        final data = doc.data();
        topContent.add(TopContentItem(
          id: doc.id,
          title: (data['content'] is String)
              ? data['content'] as String
              : 'Untitled Post',
          type: 'post',
          views: (data['views'] is int)
              ? data['views'] as int
              : int.tryParse(data['views']?.toString() ?? '') ?? 0,
          likes: (data['likes'] is int)
              ? data['likes'] as int
              : int.tryParse(data['likes']?.toString() ?? '') ?? 0,
          authorName: (data['authorName'] is String)
              ? data['authorName'] as String
              : 'Unknown',
          createdAt: (data['createdAt'] is Timestamp)
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
        ));
      }

      // Sort by views and return top 10
      topContent.sort((a, b) => b.views.compareTo(a.views));
      return topContent.take(10).toList();
    } catch (e) {
      throw Exception('Failed to get top content: $e');
    }
  }

  /// Get count of documents in a collection within date range
  Future<int> _getCollectionCount(
    String collection,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      // If the collection doesn't exist or query fails, return 0
      return 0;
    }
  }

  /// Calculate growth percentage
  double _calculateGrowth(dynamic current, dynamic previous) {
    if (previous == null || previous == 0) return 0.0;

    final currentValue = (current as num?)?.toDouble() ?? 0.0;
    final previousValue = (previous as num?)?.toDouble() ?? 0.0;

    if (previousValue == 0) return 0.0;

    return ((currentValue - previousValue) / previousValue) * 100;
  }

  /// Get storage metrics for the specified date range
  Future<Map<String, int>> _getStorageMetrics(
      DateTime startDate, DateTime endDate) async {
    try {
      // Query storage usage logs
      final storageSnapshot = await _firestore
          .collection('storage_logs')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .get();

      int totalStorageUsed = 0;
      for (var doc in storageSnapshot.docs) {
        final data = doc.data();
        final size = (data['fileSize'] as num?)?.toInt() ?? 0;
        totalStorageUsed += size;
      }

      // If no logs exist, estimate from uploaded content
      if (totalStorageUsed == 0) {
        totalStorageUsed =
            await _estimateStorageFromUploads(startDate, endDate);
      }

      return {'storageUsed': totalStorageUsed};
    } catch (e) {
      // Fallback to estimation
      final estimated = await _estimateStorageFromUploads(startDate, endDate);
      return {'storageUsed': estimated};
    }
  }

  /// Get bandwidth metrics for the specified date range
  Future<Map<String, int>> _getBandwidthMetrics(
      DateTime startDate, DateTime endDate) async {
    try {
      // Query bandwidth usage logs
      final bandwidthSnapshot = await _firestore
          .collection('bandwidth_logs')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .get();

      int totalBandwidthUsed = 0;
      for (var doc in bandwidthSnapshot.docs) {
        final data = doc.data();
        final bytes = (data['bytesTransferred'] as num?)?.toInt() ?? 0;
        totalBandwidthUsed += bytes;
      }

      // If no logs exist, estimate from downloads
      if (totalBandwidthUsed == 0) {
        totalBandwidthUsed =
            await _estimateBandwidthFromDownloads(startDate, endDate);
      }

      return {'bandwidthUsed': totalBandwidthUsed};
    } catch (e) {
      // Fallback to estimation
      final estimated =
          await _estimateBandwidthFromDownloads(startDate, endDate);
      return {'bandwidthUsed': estimated};
    }
  }

  /// Estimate storage used from uploaded content
  Future<int> _estimateStorageFromUploads(
      DateTime startDate, DateTime endDate) async {
    try {
      // Estimate from artworks
      final artworksSnapshot = await _firestore
          .collection('artworks')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .get();

      // Estimate from user profiles with images
      final profilesSnapshot = await _firestore
          .collection('users')
          .where('profileImageUrl', isNotEqualTo: null)
          .get();

      // Rough estimate: 500KB per artwork, 200KB per profile image
      final artworksStorage =
          artworksSnapshot.docs.length * 500 * 1024; // 500KB each
      final profilesStorage =
          profilesSnapshot.docs.length * 200 * 1024; // 200KB each

      return artworksStorage + profilesStorage;
    } catch (e) {
      return 1024 * 1024 * 1024; // 1GB fallback
    }
  }

  /// Estimate bandwidth used from downloads/views
  Future<int> _estimateBandwidthFromDownloads(
      DateTime startDate, DateTime endDate) async {
    try {
      // Estimate from artwork views
      final viewsSnapshot = await _firestore
          .collection('artwork_views')
          .where('viewedAt', isGreaterThanOrEqualTo: startDate)
          .where('viewedAt', isLessThanOrEqualTo: endDate)
          .get();

      // Rough estimate: 300KB per view (image load)
      final bandwidthFromViews = viewsSnapshot.docs.length * 300 * 1024;

      // Add some buffer for other content
      return bandwidthFromViews + (5 * 1024 * 1024 * 1024); // +5GB buffer
    } catch (e) {
      return 10 * 1024 * 1024 * 1024; // 10GB fallback
    }
  }
}
