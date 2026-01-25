import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/artwork_model.dart';
import '../models/artwork_rating_model.dart';

/// Advanced analytics service for comprehensive artwork performance tracking
///
/// Provides deep insights into artwork engagement, revenue, social metrics,
/// and cross-platform analytics integration.
class AdvancedArtworkAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Track detailed artwork engagement event
  Future<void> trackEngagementEvent({
    required String artworkId,
    required String
    eventType, // view, like, comment, share, save, purchase_inquiry
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get user location and device info if available
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      await _firestore
          .collection('analytics')
          .doc('artwork_engagement')
          .collection('events')
          .add({
            'artworkId': artworkId,
            'userId': user.uid,
            'eventType': eventType,
            'timestamp': Timestamp.now(),
            'userLocation': userData['location'] ?? 'Unknown',
            'userType': userData['userType'] ?? 'User',
            'deviceType': 'mobile', // Could be enhanced with device detection
            'sessionId': _generateSessionId(),
            'additionalData': additionalData ?? {},
          });

      // Update real-time counters
      await _updateRealTimeCounters(artworkId, eventType);
    } catch (e) {
      developer.log(
        'Error tracking engagement event: $e',
        name: 'AdvancedArtworkAnalytics',
      );
    }
  }

  /// Get comprehensive analytics for artwork owner
  Future<Map<String, dynamic>> getArtworkAnalytics(
    String artworkId, {
    int timeframeDays = 30,
  }) async {
    try {
      final cutoffDate = Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: timeframeDays)),
      );

      // Get artwork details
      final artworkDoc = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .get();
      if (!artworkDoc.exists) return {};

      final artwork = ArtworkModel.fromFirestore(artworkDoc);

      // Parallel execution of analytics queries
      final futures = await Future.wait([
        _getEngagementMetrics(artworkId, cutoffDate),
        _getViewerDemographics(artworkId, cutoffDate),
        _getSocialMetrics(artworkId),
        _getRevenueMetrics(artworkId, cutoffDate),
        _getShareMetrics(artworkId, cutoffDate),
        _getSearchMetrics(artworkId, cutoffDate),
      ]);

      return {
        'artworkId': artworkId,
        'artworkTitle': artwork.title,
        'timeframeDays': timeframeDays,
        'generatedAt': DateTime.now().toIso8601String(),
        'engagementMetrics': futures[0],
        'viewerDemographics': futures[1],
        'socialMetrics': futures[2],
        'revenueMetrics': futures[3],
        'shareMetrics': futures[4],
        'searchMetrics': futures[5],
        'overallScore': _calculateOverallScore(futures),
      };
    } catch (e) {
      developer.log(
        'Error getting artwork analytics: $e',
        name: 'AdvancedArtworkAnalytics',
      );
      return {};
    }
  }

  /// Get engagement metrics (views, interactions, time spent)
  Future<Map<String, dynamic>> _getEngagementMetrics(
    String artworkId,
    Timestamp cutoffDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('analytics')
          .doc('artwork_engagement')
          .collection('events')
          .where('artworkId', isEqualTo: artworkId)
          .where('timestamp', isGreaterThan: cutoffDate)
          .get();

      final events = snapshot.docs;
      final viewEvents = events
          .where((doc) => doc.data()['eventType'] == 'view')
          .toList();
      final likeEvents = events
          .where((doc) => doc.data()['eventType'] == 'like')
          .toList();
      final commentEvents = events
          .where((doc) => doc.data()['eventType'] == 'comment')
          .toList();
      final shareEvents = events
          .where((doc) => doc.data()['eventType'] == 'share')
          .toList();
      final saveEvents = events
          .where((doc) => doc.data()['eventType'] == 'save')
          .toList();

      // Calculate daily breakdown
      final dailyStats = <String, Map<String, int>>{};
      for (final doc in events) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp;
        final dateKey = _formatDateKey(timestamp.toDate());
        final eventType = data['eventType'] as String;

        dailyStats[dateKey] ??= {
          'views': 0,
          'likes': 0,
          'comments': 0,
          'shares': 0,
          'saves': 0,
        };
        dailyStats[dateKey]![eventType] =
            (dailyStats[dateKey]![eventType] ?? 0) + 1;
      }

      // Calculate unique viewers
      final uniqueViewers = viewEvents
          .map((doc) => doc.data()['userId'] as String)
          .toSet()
          .length;

      // Calculate engagement rate
      final totalViews = viewEvents.length;
      final totalInteractions =
          likeEvents.length +
          commentEvents.length +
          shareEvents.length +
          saveEvents.length;
      final engagementRate = totalViews > 0
          ? (totalInteractions / totalViews) * 100
          : 0.0;

      return {
        'totalViews': totalViews,
        'uniqueViewers': uniqueViewers,
        'totalLikes': likeEvents.length,
        'totalComments': commentEvents.length,
        'totalShares': shareEvents.length,
        'totalSaves': saveEvents.length,
        'engagementRate': engagementRate,
        'dailyBreakdown': dailyStats,
        'peakEngagementDay': _findPeakEngagementDay(dailyStats),
      };
    } catch (e) {
      developer.log(
        'Error getting engagement metrics: $e',
        name: 'AdvancedArtworkAnalytics',
      );
      return {};
    }
  }

  /// Get viewer demographics
  Future<Map<String, dynamic>> _getViewerDemographics(
    String artworkId,
    Timestamp cutoffDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('analytics')
          .doc('artwork_engagement')
          .collection('events')
          .where('artworkId', isEqualTo: artworkId)
          .where('eventType', isEqualTo: 'view')
          .where('timestamp', isGreaterThan: cutoffDate)
          .get();

      final locationCounts = <String, int>{};
      final userTypeCounts = <String, int>{};
      final deviceTypeCounts = <String, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Count locations
        final location = data['userLocation'] as String? ?? 'Unknown';
        locationCounts[location] = (locationCounts[location] ?? 0) + 1;

        // Count user types
        final userType = data['userType'] as String? ?? 'User';
        userTypeCounts[userType] = (userTypeCounts[userType] ?? 0) + 1;

        // Count device types
        final deviceType = data['deviceType'] as String? ?? 'Unknown';
        deviceTypeCounts[deviceType] = (deviceTypeCounts[deviceType] ?? 0) + 1;
      }

      return {
        'totalViews': snapshot.docs.length,
        'locationBreakdown': locationCounts,
        'userTypeBreakdown': userTypeCounts,
        'deviceTypeBreakdown': deviceTypeCounts,
        'topViewingLocation': _getTopEntry(locationCounts),
        'primaryAudience': _getTopEntry(userTypeCounts),
      };
    } catch (e) {
      developer.log(
        'Error getting viewer demographics: $e',
        name: 'AdvancedArtworkAnalytics',
      );
      return {};
    }
  }

  /// Get social metrics (ratings, comments analysis)
  Future<Map<String, dynamic>> _getSocialMetrics(String artworkId) async {
    try {
      // Get ratings data
      final ratingsSnapshot = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('ratings')
          .get();

      final ratings = ratingsSnapshot.docs
          .map((doc) => ArtworkRatingModel.fromFirestore(doc))
          .toList();

      final ratingStats = ArtworkRatingStats.fromRatings(ratings);

      // Get comments data
      final commentsSnapshot = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .collection('comments')
          .get();

      final comments = commentsSnapshot.docs;
      final commentAnalysis = _analyzeComments(comments);

      // Calculate social score
      final socialScore = _calculateSocialScore(ratingStats, comments.length);

      return {
        'ratingsData': {
          'averageRating': ratingStats.averageRating,
          'totalRatings': ratingStats.totalRatings,
          'ratingDistribution': ratingStats.ratingDistribution,
        },
        'commentsData': commentAnalysis,
        'socialScore': socialScore,
        'engagementLevel': _getEngagementLevel(socialScore),
      };
    } catch (e) {
      developer.log(
        'Error getting social metrics: $e',
        name: 'AdvancedArtworkAnalytics',
      );
      return {};
    }
  }

  /// Get revenue metrics
  Future<Map<String, dynamic>> _getRevenueMetrics(
    String artworkId,
    Timestamp cutoffDate,
  ) async {
    try {
      // Get sales data
      final salesSnapshot = await _firestore
          .collection('sales')
          .where('artworkId', isEqualTo: artworkId)
          .where('createdAt', isGreaterThan: cutoffDate)
          .get();

      // Get inquiry data
      final inquirySnapshot = await _firestore
          .collection('analytics')
          .doc('artwork_engagement')
          .collection('events')
          .where('artworkId', isEqualTo: artworkId)
          .where('eventType', isEqualTo: 'purchase_inquiry')
          .where('timestamp', isGreaterThan: cutoffDate)
          .get();

      double totalRevenue = 0.0;
      int totalSales = 0;

      for (final doc in salesSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        totalRevenue += amount;
        totalSales++;
      }

      final totalInquiries = inquirySnapshot.docs.length;
      final conversionRate = totalInquiries > 0
          ? (totalSales / totalInquiries) * 100
          : 0.0;

      return {
        'totalRevenue': totalRevenue,
        'totalSales': totalSales,
        'totalInquiries': totalInquiries,
        'conversionRate': conversionRate,
        'averageSaleAmount': totalSales > 0 ? totalRevenue / totalSales : 0.0,
        'revenuePerView': await _calculateRevenuePerView(
          artworkId,
          totalRevenue,
        ),
      };
    } catch (e) {
      developer.log(
        'Error getting revenue metrics: $e',
        name: 'AdvancedArtworkAnalytics',
      );
      return {};
    }
  }

  /// Get share metrics
  Future<Map<String, dynamic>> _getShareMetrics(
    String artworkId,
    Timestamp cutoffDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('analytics')
          .doc('artwork_engagement')
          .collection('events')
          .where('artworkId', isEqualTo: artworkId)
          .where('eventType', isEqualTo: 'share')
          .where('timestamp', isGreaterThan: cutoffDate)
          .get();

      final platformCounts = <String, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final additionalData =
            data['additionalData'] as Map<String, dynamic>? ?? {};
        final platform = additionalData['platform'] as String? ?? 'Unknown';
        platformCounts[platform] = (platformCounts[platform] ?? 0) + 1;
      }

      return {
        'totalShares': snapshot.docs.length,
        'platformBreakdown': platformCounts,
        'mostPopularPlatform': _getTopEntry(platformCounts),
        'viralityScore': _calculateViralityScore(snapshot.docs.length),
      };
    } catch (e) {
      developer.log(
        'Error getting share metrics: $e',
        name: 'AdvancedArtworkAnalytics',
      );
      return {};
    }
  }

  /// Get search metrics
  Future<Map<String, dynamic>> _getSearchMetrics(
    String artworkId,
    Timestamp cutoffDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('analytics')
          .doc('search_events')
          .collection('queries')
          .where('resultArtworkIds', arrayContains: artworkId)
          .where('timestamp', isGreaterThan: cutoffDate)
          .get();

      final searchTerms = <String, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final query = data['query'] as String? ?? '';
        searchTerms[query] = (searchTerms[query] ?? 0) + 1;
      }

      return {
        'totalSearchAppearances': snapshot.docs.length,
        'topSearchTerms': _getTopEntries(searchTerms, 10),
        'searchDiscoverability': _calculateDiscoverabilityScore(
          snapshot.docs.length,
        ),
      };
    } catch (e) {
      developer.log(
        'Error getting search metrics: $e',
        name: 'AdvancedArtworkAnalytics',
      );
      return {};
    }
  }

  /// Generate comprehensive performance report
  Future<Map<String, dynamic>> generatePerformanceReport(
    List<String> artworkIds, {
    int timeframeDays = 30,
  }) async {
    try {
      final reports = <String, Map<String, dynamic>>{};

      for (final artworkId in artworkIds) {
        reports[artworkId] = await getArtworkAnalytics(
          artworkId,
          timeframeDays: timeframeDays,
        );
      }

      // Calculate aggregate metrics
      final aggregateMetrics = _calculateAggregateMetrics(reports);

      return {
        'reportId': _generateReportId(),
        'generatedAt': DateTime.now().toIso8601String(),
        'timeframeDays': timeframeDays,
        'artworkCount': artworkIds.length,
        'individualReports': reports,
        'aggregateMetrics': aggregateMetrics,
        'recommendations': _generateRecommendations(aggregateMetrics),
      };
    } catch (e) {
      developer.log(
        'Error generating performance report: $e',
        name: 'AdvancedArtworkAnalytics',
      );
      return {};
    }
  }

  /// Helper methods
  Future<void> _updateRealTimeCounters(
    String artworkId,
    String eventType,
  ) async {
    final counterPath = 'artwork/$artworkId/counters/${eventType}_count';
    await _firestore.doc(counterPath).set({
      'count': FieldValue.increment(1),
      'lastUpdated': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  String _generateSessionId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_auth.currentUser?.uid ?? "anonymous"}';
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _findPeakEngagementDay(Map<String, Map<String, int>> dailyStats) {
    String peakDay = '';
    int maxEngagement = 0;

    for (final entry in dailyStats.entries) {
      final dayEngagement = entry.value.values.fold(
        0,
        (sum, count) => sum + count,
      );
      if (dayEngagement > maxEngagement) {
        maxEngagement = dayEngagement;
        peakDay = entry.key;
      }
    }

    return peakDay;
  }

  String _getTopEntry(Map<String, int> counts) {
    if (counts.isEmpty) return 'N/A';

    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  List<Map<String, dynamic>> _getTopEntries(
    Map<String, int> counts,
    int limit,
  ) {
    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries
        .take(limit)
        .map((e) => {'term': e.key, 'count': e.value})
        .toList();
  }

  Map<String, dynamic> _analyzeComments(List<QueryDocumentSnapshot> comments) {
    final int totalComments = comments.length;
    int totalLikes = 0;
    int repliesCount = 0;

    for (final doc in comments) {
      final data = doc.data() as Map<String, dynamic>;
      totalLikes += (data['likes'] as int?) ?? 0;
      if ((data['parentCommentId'] as String? ?? '').isNotEmpty) {
        repliesCount++;
      }
    }

    return {
      'totalComments': totalComments,
      'totalLikes': totalLikes,
      'repliesCount': repliesCount,
      'topLevelComments': totalComments - repliesCount,
      'averageLikesPerComment': totalComments > 0
          ? totalLikes / totalComments
          : 0.0,
    };
  }

  double _calculateSocialScore(
    ArtworkRatingStats ratingStats,
    int commentCount,
  ) {
    // Weighted scoring algorithm
    final ratingScore =
        ratingStats.averageRating * ratingStats.totalRatings * 0.3;
    final commentScore = commentCount * 0.2;
    return ratingScore + commentScore;
  }

  String _getEngagementLevel(double socialScore) {
    if (socialScore >= 100) return 'Viral';
    if (socialScore >= 50) return 'High';
    if (socialScore >= 20) return 'Medium';
    if (socialScore >= 5) return 'Low';
    return 'Minimal';
  }

  Future<double> _calculateRevenuePerView(
    String artworkId,
    double totalRevenue,
  ) async {
    try {
      final viewsSnapshot = await _firestore
          .collection('analytics')
          .doc('artwork_engagement')
          .collection('events')
          .where('artworkId', isEqualTo: artworkId)
          .where('eventType', isEqualTo: 'view')
          .get();

      final totalViews = viewsSnapshot.docs.length;
      return totalViews > 0 ? totalRevenue / totalViews : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  double _calculateViralityScore(int shareCount) {
    // Simple virality scoring
    if (shareCount >= 100) return 100.0;
    if (shareCount >= 50) return 75.0;
    if (shareCount >= 20) return 50.0;
    if (shareCount >= 10) return 25.0;
    return shareCount * 2.5;
  }

  double _calculateDiscoverabilityScore(int searchAppearances) {
    // Discoverability scoring based on search appearances
    return searchAppearances > 0 ? (searchAppearances / 10.0) * 100 : 0.0;
  }

  double _calculateOverallScore(List<dynamic> futures) {
    // Calculate composite performance score
    return 75.0; // Placeholder implementation
  }

  Map<String, dynamic> _calculateAggregateMetrics(
    Map<String, Map<String, dynamic>> reports,
  ) {
    // Calculate aggregate metrics across all artworks
    return {
      'totalArtworks': reports.length,
      'averageEngagementRate': 0.0, // Calculate from individual reports
      'totalRevenue': 0.0, // Sum from individual reports
    };
  }

  List<String> _generateRecommendations(Map<String, dynamic> aggregateMetrics) {
    return [
      'Increase engagement by responding to comments',
      'Consider optimizing artwork titles for better search discoverability',
      'Share your work on social media to increase visibility',
    ];
  }

  String _generateReportId() {
    return 'report_${DateTime.now().millisecondsSinceEpoch}';
  }
}
