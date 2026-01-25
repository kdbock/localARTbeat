import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Service for managing artwork analytics
class ArtworkAnalyticsService {
  FirebaseAuth? _auth;
  FirebaseAuth get auth => _auth ??= FirebaseAuth.instance;

  FirebaseFirestore? _firestore;
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;

  /// Get the current authenticated user's ID
  String? getCurrentUserId() {
    return auth.currentUser?.uid;
  }

  /// Track artwork view
  Future<void> trackArtworkView(String artworkId, {String? source}) async {
    try {
      final userId = getCurrentUserId();
      await firestore.collection('artwork_analytics').add({
        'artworkId': artworkId,
        'userId': userId,
        'action': 'view',
        'source': source,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Error tracking artwork view: $e');
      // Non-critical error, don't throw
    }
  }

  /// Track search analytics
  Future<void> trackSearch(
    String query,
    int resultCount, {
    String? source,
  }) async {
    try {
      final userId = getCurrentUserId();
      await firestore.collection('search_analytics').add({
        'query': query,
        'resultCount': resultCount,
        'userId': userId,
        'source': source,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Error tracking search: $e');
      // Non-critical error, don't throw
    }
  }

  /// Track artwork sale/revenue
  Future<void> trackArtworkSale(
    String artworkId,
    double amount, {
    String? buyerId,
    String? paymentMethod,
  }) async {
    try {
      final userId = getCurrentUserId();
      await firestore.collection('sales_analytics').add({
        'artworkId': artworkId,
        'sellerId': userId,
        'buyerId': buyerId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Also track in general analytics
      await firestore.collection('artwork_analytics').add({
        'artworkId': artworkId,
        'userId': buyerId,
        'action': 'purchase',
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Error tracking artwork sale: $e');
      // Non-critical error, don't throw
    }
  }

  /// Get artwork performance metrics
  Future<Map<String, dynamic>> getArtworkPerformance(String artworkId) async {
    try {
      // Get view count
      final viewsSnapshot = await firestore
          .collection('artwork_analytics')
          .where('artworkId', isEqualTo: artworkId)
          .where('action', isEqualTo: 'view')
          .get();

      final viewCount = viewsSnapshot.docs.length;

      // Get engagement metrics (likes, comments, shares)
      final engagementSnapshot = await firestore
          .collection('artwork_analytics')
          .where('artworkId', isEqualTo: artworkId)
          .get();

      final engagementCount = engagementSnapshot.docs.length;

      // Get recent activity (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentViews = viewsSnapshot.docs.where((doc) {
        final timestamp = doc.data()['timestamp'] as Timestamp?;
        return timestamp != null && timestamp.toDate().isAfter(thirtyDaysAgo);
      }).length;

      return {
        'totalViews': viewCount,
        'totalEngagement': engagementCount,
        'recentViews': recentViews,
        'engagementRate': viewCount > 0
            ? (engagementCount / viewCount) * 100
            : 0.0,
      };
    } catch (e) {
      AppLogger.error('Error getting artwork performance: $e');
      return {
        'totalViews': 0,
        'totalEngagement': 0,
        'recentViews': 0,
        'engagementRate': 0.0,
      };
    }
  }

  /// Get top performing artworks for an artist
  Future<List<Map<String, dynamic>>> getTopArtworks(
    String artistId, {
    int limit = 10,
  }) async {
    try {
      // Get artist's artworks
      final artworksSnapshot = await firestore
          .collection('artwork')
          .where('userId', isEqualTo: artistId)
          .get();

      final artworkIds = artworksSnapshot.docs.map((doc) => doc.id).toList();

      if (artworkIds.isEmpty) return [];

      // Get view counts for each artwork
      final performanceData = <Map<String, dynamic>>[];

      for (final artworkId in artworkIds) {
        final performance = await getArtworkPerformance(artworkId);
        final artworkDoc = artworksSnapshot.docs.firstWhere(
          (doc) => doc.id == artworkId,
        );
        final artworkData = artworkDoc.data();

        performanceData.add({
          'artworkId': artworkId,
          'title': artworkData['title'] ?? 'Untitled',
          ...performance,
        });
      }

      // Sort by total views
      performanceData.sort(
        (a, b) => (b['totalViews'] as int).compareTo(a['totalViews'] as int),
      );

      return performanceData.take(limit).toList();
    } catch (e) {
      AppLogger.error('Error getting top artworks: $e');
      return [];
    }
  }

  /// Get geographic distribution of views
  Future<Map<String, int>> getGeographicDistribution(String artworkId) async {
    try {
      final snapshot = await firestore
          .collection('artwork_analytics')
          .where('artworkId', isEqualTo: artworkId)
          .where('action', isEqualTo: 'view')
          .get();

      final distribution = <String, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final location = data['location'] as String? ?? 'Unknown';

        distribution[location] = (distribution[location] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      AppLogger.error('Error getting geographic distribution: $e');
      return {};
    }
  }

  /// Get view trends over time
  Future<List<Map<String, dynamic>>> getViewTrends(
    String artworkId, {
    int days = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await firestore
          .collection('artwork_analytics')
          .where('artworkId', isEqualTo: artworkId)
          .where('action', isEqualTo: 'view')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(startDate))
          .orderBy('timestamp')
          .get();

      final trends = <Map<String, dynamic>>[];
      final dailyViews = <DateTime, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final date = DateTime(timestamp.year, timestamp.month, timestamp.day);

        dailyViews[date] = (dailyViews[date] ?? 0) + 1;
      }

      // Fill in missing dates with 0 views
      for (int i = 0; i < days; i++) {
        final date = startDate.add(Duration(days: i));
        final viewCount =
            dailyViews[DateTime(date.year, date.month, date.day)] ?? 0;

        trends.add({'date': date, 'views': viewCount});
      }

      return trends;
    } catch (e) {
      AppLogger.error('Error getting view trends: $e');
      return [];
    }
  }

  /// Get search analytics
  Future<Map<String, dynamic>> getSearchAnalytics({int days = 7}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await firestore
          .collection('search_analytics')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(startDate))
          .orderBy('timestamp', descending: true)
          .get();

      final totalSearches = snapshot.docs.length;
      final uniqueQueries = <String>{};
      final queryFrequency = <String, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final query = data['query'] as String? ?? '';

        if (query.isNotEmpty) {
          uniqueQueries.add(query);
          queryFrequency[query] = (queryFrequency[query] ?? 0) + 1;
        }
      }

      // Get top queries
      final queryEntries = queryFrequency.entries.toList();
      queryEntries.sort(
        (MapEntry<String, int> a, MapEntry<String, int> b) =>
            b.value.compareTo(a.value),
      );

      final topQueries = queryEntries
          .take(10)
          .map(
            (MapEntry<String, int> entry) => {
              'query': entry.key,
              'count': entry.value,
            },
          )
          .toList();

      return {
        'totalSearches': totalSearches,
        'uniqueQueries': uniqueQueries.length,
        'topQueries': topQueries,
        'averageResults': snapshot.docs.isNotEmpty
            ? snapshot.docs
                      .map((doc) => (doc.data()['resultCount'] as int?) ?? 0)
                      .reduce((a, b) => a + b) /
                  snapshot.docs.length
            : 0.0,
      };
    } catch (e) {
      AppLogger.error('Error getting search analytics: $e');
      return {
        'totalSearches': 0,
        'uniqueQueries': 0,
        'topQueries': <Map<String, dynamic>>[],
        'averageResults': 0.0,
      };
    }
  }

  /// Get revenue analytics for an artist
  Future<Map<String, dynamic>> getRevenueAnalytics(
    String artistId, {
    int days = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await firestore
          .collection('sales_analytics')
          .where('sellerId', isEqualTo: artistId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(startDate))
          .orderBy('timestamp', descending: true)
          .get();

      final totalRevenue = snapshot.docs.fold<double>(
        0,
        (sum, doc) => sum + (doc.data()['amount'] as double? ?? 0),
      );

      final totalSales = snapshot.docs.length;

      final averageSale = totalSales > 0 ? totalRevenue / totalSales : 0.0;

      // Group by payment method
      final paymentMethods = <String, double>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final method = data['paymentMethod'] as String? ?? 'unknown';
        final amount = data['amount'] as double? ?? 0;
        paymentMethods[method] = (paymentMethods[method] ?? 0) + amount;
      }

      // Calculate daily revenue trend
      final dailyRevenue = <DateTime, double>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
        final amount = data['amount'] as double? ?? 0;
        dailyRevenue[date] = (dailyRevenue[date] ?? 0) + amount;
      }

      final revenueTrend =
          dailyRevenue.entries
              .map((entry) => {'date': entry.key, 'revenue': entry.value})
              .toList()
            ..sort(
              (a, b) =>
                  (a['date'] as DateTime).compareTo(b['date'] as DateTime),
            );

      return {
        'totalRevenue': totalRevenue,
        'totalSales': totalSales,
        'averageSale': averageSale,
        'paymentMethods': paymentMethods,
        'revenueTrend': revenueTrend,
      };
    } catch (e) {
      AppLogger.error('Error getting revenue analytics: $e');
      return {
        'totalRevenue': 0.0,
        'totalSales': 0,
        'averageSale': 0.0,
        'paymentMethods': <String, double>{},
        'revenueTrend': <Map<String, dynamic>>[],
      };
    }
  }

  /// Get cross-package analytics correlation
  Future<Map<String, dynamic>> getCrossPackageAnalytics(String artistId) async {
    try {
      // Get artwork analytics
      final topArtworks = await getTopArtworks(artistId);

      // Get revenue analytics
      final revenueAnalytics = await getRevenueAnalytics(artistId);

      // Get search analytics for artist's artworks
      final searchAnalytics = await getSearchAnalytics();

      // Calculate correlations
      final totalViews = topArtworks.fold<int>(
        0,
        (sum, artwork) => sum + (artwork['totalViews'] as int? ?? 0),
      );

      final totalRevenue = revenueAnalytics['totalRevenue'] as double? ?? 0.0;

      final conversionRate = totalViews > 0
          ? (totalRevenue / totalViews) * 100
          : 0.0;

      // Engagement to revenue correlation
      final totalEngagement = topArtworks.fold<int>(
        0,
        (sum, artwork) => sum + (artwork['totalEngagement'] as int? ?? 0),
      );

      final engagementToRevenueRatio = totalRevenue > 0
          ? totalEngagement / totalRevenue
          : 0.0;

      return {
        'totalViews': totalViews,
        'totalRevenue': totalRevenue,
        'conversionRate': conversionRate,
        'engagementToRevenueRatio': engagementToRevenueRatio,
        'topArtworks': topArtworks.take(5),
        'revenueAnalytics': revenueAnalytics,
        'searchAnalytics': searchAnalytics,
      };
    } catch (e) {
      AppLogger.error('Error getting cross-package analytics: $e');
      return {
        'totalViews': 0,
        'totalRevenue': 0.0,
        'conversionRate': 0.0,
        'engagementToRevenueRatio': 0.0,
        'topArtworks': <Map<String, dynamic>>[],
        'revenueAnalytics': <String, dynamic>{},
        'searchAnalytics': <String, dynamic>{},
      };
    }
  }

  /// Export analytics data
  Future<String> exportAnalytics(
    String artistId, {
    String format = 'json',
  }) async {
    try {
      final crossPackageData = await getCrossPackageAnalytics(artistId);

      if (format == 'json') {
        // Return JSON string
        return '''
{
  "exportDate": "${DateTime.now().toIso8601String()}",
  "artistId": "$artistId",
  "summary": {
    "totalViews": ${crossPackageData['totalViews']},
    "totalRevenue": ${crossPackageData['totalRevenue']},
    "conversionRate": ${crossPackageData['conversionRate']},
    "engagementToRevenueRatio": ${crossPackageData['engagementToRevenueRatio']}
  },
  "topArtworks": ${crossPackageData['topArtworks']},
  "revenueAnalytics": ${crossPackageData['revenueAnalytics']},
  "searchAnalytics": ${crossPackageData['searchAnalytics']}
}
''';
      } else if (format == 'csv') {
        // Return CSV format
        final buffer = StringBuffer();

        // Summary section
        buffer.writeln('ARTWORK ANALYTICS EXPORT');
        buffer.writeln('Export Date,${DateTime.now().toIso8601String()}');
        buffer.writeln('Artist ID,$artistId');
        buffer.writeln('');
        buffer.writeln('SUMMARY METRICS');
        buffer.writeln('Metric,Value');
        buffer.writeln('Total Views,${crossPackageData['totalViews']}');
        buffer.writeln('Total Revenue,${crossPackageData['totalRevenue']}');
        buffer.writeln(
          'Conversion Rate,${crossPackageData['conversionRate']}%',
        );
        buffer.writeln(
          'Engagement to Revenue Ratio,${crossPackageData['engagementToRevenueRatio']}',
        );
        buffer.writeln('');

        // Top artworks section
        buffer.writeln('TOP ARTWORKS');
        buffer.writeln('Title,Views,Engagement,Engagement Rate');
        final topArtworks = crossPackageData['topArtworks'] as List<dynamic>;
        for (final artwork in topArtworks) {
          final data = artwork as Map<String, dynamic>;
          buffer.writeln(
            '${data['title']},${data['totalViews']},${data['totalEngagement']},${data['engagementRate']}',
          );
        }

        return buffer.toString();
      }

      throw Exception('Unsupported export format: $format');
    } catch (e) {
      AppLogger.error('Error exporting analytics: $e');
      throw Exception('Failed to export analytics data');
    }
  }

  /// Optimize analytics queries with caching
  Future<Map<String, dynamic>> getOptimizedAnalytics(String artistId) async {
    try {
      // Use Firestore aggregation queries for better performance
      final analyticsQuery = firestore
          .collection('artwork_analytics')
          .where('userId', isEqualTo: artistId);

      final salesQuery = firestore
          .collection('sales_analytics')
          .where('sellerId', isEqualTo: artistId);

      // Execute queries in parallel for better performance
      final results = await Future.wait([
        analyticsQuery.count().get(),
        salesQuery.count().get(),
        analyticsQuery.get(),
        salesQuery.get(),
      ]);

      final analyticsCount = results[0] as AggregateQuerySnapshot;
      final salesCount = results[1] as AggregateQuerySnapshot;
      final analyticsDocs = results[2] as QuerySnapshot;
      final salesDocs = results[3] as QuerySnapshot;

      // Process analytics data
      final actionCounts = <String, int>{};
      for (final doc in analyticsDocs.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final action = data['action'] as String? ?? 'unknown';
        actionCounts[action] = (actionCounts[action] ?? 0) + 1;
      }

      // Process sales data
      final totalRevenue = salesDocs.docs.fold<double>(
        0,
        (sum, doc) =>
            sum +
            ((doc.data() as Map<String, dynamic>)['amount'] as double? ?? 0),
      );

      return {
        'totalAnalytics': analyticsCount.count,
        'totalSales': salesCount.count,
        'actionBreakdown': actionCounts,
        'totalRevenue': totalRevenue,
        'averageRevenuePerSale': (salesCount.count ?? 0) > 0
            ? totalRevenue / (salesCount.count ?? 1)
            : 0.0,
      };
    } catch (e) {
      AppLogger.error('Error getting optimized analytics: $e');
      return {
        'totalAnalytics': 0,
        'totalSales': 0,
        'actionBreakdown': <String, int>{},
        'totalRevenue': 0.0,
        'averageRevenuePerSale': 0.0,
      };
    }
  }
}
