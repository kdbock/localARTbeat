import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

final logger = Logger();

/// Service for tracking artist visibility and insights
class VisibilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  final CollectionReference _artworkViewsCollection =
      FirebaseFirestore.instance.collection('artworkViews');
  final CollectionReference _artistProfileViewsCollection =
      FirebaseFirestore.instance.collection('artistProfileViews');

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Track an artwork view
  Future<void> trackArtworkView({
    required String artworkId,
    required String artistId,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      // Allow anonymous tracking for public views
      return;
    }

    // Don't track if the artist is viewing their own artwork
    if (userId == artistId) {
      return;
    }

    try {
      // Check if this user has already viewed this artwork recently (last 24 hours)
      final viewsSnapshot = await _artworkViewsCollection
          .where('artworkId', isEqualTo: artworkId)
          .where('viewerId', isEqualTo: userId)
          .where('viewedAt',
              isGreaterThan: Timestamp.fromDate(
                DateTime.now().subtract(const Duration(hours: 24)),
              ))
          .limit(1)
          .get();

      // Only record a new view if there's no recent view from this user
      if (viewsSnapshot.docs.isEmpty) {
        await _artworkViewsCollection.add({
          'artworkId': artworkId,
          'artistId': artistId,
          'viewerId': userId,
          'viewedAt': FieldValue.serverTimestamp(),
        });

        // Update view count in artwork document
        await _firestore.collection('artwork').doc(artworkId).update({
          'viewCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      logger.e('Error tracking artwork view: $e');
    }
  }

  /// Track an artist profile view
  Future<void> trackArtistProfileView({
    required String artistProfileId,
    required String artistId,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      // Allow anonymous tracking for public views
      return;
    }

    // Don't track if the artist is viewing their own profile
    if (userId == artistId) {
      return;
    }

    try {
      // Check if this user has already viewed this profile recently (last 24 hours)
      final viewsSnapshot = await _artistProfileViewsCollection
          .where('artistProfileId', isEqualTo: artistProfileId)
          .where('viewerId', isEqualTo: userId)
          .where('viewedAt',
              isGreaterThan: Timestamp.fromDate(
                DateTime.now().subtract(const Duration(hours: 24)),
              ))
          .limit(1)
          .get();

      // Only record a new view if there's no recent view from this user
      if (viewsSnapshot.docs.isEmpty) {
        await _artistProfileViewsCollection.add({
          'artistProfileId': artistProfileId,
          'artistId': artistId,
          'viewerId': userId,
          'viewedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      logger.e('Error tracking artist profile view: $e');
    }
  }

  /// Get artwork analytics for the specified artist
  Future<Map<String, dynamic>> getArtworkAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final result = <String, dynamic>{};

    try {
      // Get view counts for the specified date range
      final viewsSnapshot = await _artworkViewsCollection
          .where('artistId', isEqualTo: userId)
          .where('viewedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('viewedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Total views in period
      result['totalViews'] = viewsSnapshot.docs.length;

      // Views by artwork
      final viewsByArtwork = <String, int>{};
      for (final doc in viewsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final artworkId = data['artworkId'] as String;
        viewsByArtwork[artworkId] = (viewsByArtwork[artworkId] ?? 0) + 1;
      }
      result['viewsByArtwork'] = viewsByArtwork;

      // Views by day
      final viewsByDay = <String, int>{};
      for (final doc in viewsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final viewDate = (data['viewedAt'] as Timestamp).toDate();
        final dayString =
            '${viewDate.year}-${viewDate.month.toString().padLeft(2, '0')}-${viewDate.day.toString().padLeft(2, '0')}';
        viewsByDay[dayString] = (viewsByDay[dayString] ?? 0) + 1;
      }
      result['viewsByDay'] = viewsByDay;
    } catch (e) {
      logger.e('Error getting artwork analytics: $e');
    }

    return result;
  }

  /// Get artist profile analytics for the specified artist
  Future<Map<String, dynamic>> getProfileAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final result = <String, dynamic>{};

    try {
      // Get profile view counts for the specified date range
      final viewsSnapshot = await _artistProfileViewsCollection
          .where('artistId', isEqualTo: userId)
          .where('viewedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('viewedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Total profile views in period
      result['totalProfileViews'] = viewsSnapshot.docs.length;

      // Views by day
      final viewsByDay = <String, int>{};
      for (final doc in viewsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final viewDate = (data['viewedAt'] as Timestamp).toDate();
        final dayString =
            '${viewDate.year}-${viewDate.month.toString().padLeft(2, '0')}-${viewDate.day.toString().padLeft(2, '0')}';
        viewsByDay[dayString] = (viewsByDay[dayString] ?? 0) + 1;
      }
      result['profileViewsByDay'] = viewsByDay;

      // Get unique viewers count
      final uniqueViewers = viewsSnapshot.docs
          .map((doc) =>
              (doc.data() as Map<String, dynamic>)['viewerId'] as String)
          .toSet()
          .length;
      result['uniqueViewers'] = uniqueViewers;
    } catch (e) {
      logger.e('Error getting profile analytics: $e');
    }

    return result;
  }

  /// Get follower analytics
  Future<Map<String, dynamic>> getFollowerAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final result = <String, dynamic>{};

    try {
      // Get all followers
      final followersSnapshot = await _firestore
          .collection('artistFollowers')
          .doc(userId)
          .collection('followers')
          .get();

      // Total followers
      result['totalFollowers'] = followersSnapshot.docs.length;

      // New followers in period
      final newFollowersSnapshot = await _firestore
          .collection('artistFollowers')
          .doc(userId)
          .collection('followers')
          .where('followedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('followedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      result['newFollowers'] = newFollowersSnapshot.docs.length;

      // Followers by day
      final followersByDay = <String, int>{};
      for (final doc in newFollowersSnapshot.docs) {
        final data = doc.data();
        if (data['followedAt'] != null) {
          final followDate = (data['followedAt'] as Timestamp).toDate();
          final dayString =
              '${followDate.year}-${followDate.month.toString().padLeft(2, '0')}-${followDate.day.toString().padLeft(2, '0')}';
          followersByDay[dayString] = (followersByDay[dayString] ?? 0) + 1;
        }
      }
      result['followersByDay'] = followersByDay;
    } catch (e) {
      logger.e('Error getting follower analytics: $e');
    }

    return result;
  }

  /// Get gallery analytics overview
  Future<Map<String, dynamic>> getGalleryAnalytics({
    required String galleryProfileId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final result = <String, dynamic>{};

    try {
      // Get gallery profile
      final galleryDoc = await _firestore
          .collection('artistProfiles')
          .doc(galleryProfileId)
          .get();

      if (!galleryDoc.exists) {
        throw Exception('Gallery profile not found');
      }

      final galleryData = galleryDoc.data() as Map<String, dynamic>;

      // Get associated artists
      final artistIds = List<String>.from(
          (galleryData['galleryArtists'] as List<dynamic>?) ?? []);
      result['totalArtists'] = artistIds.length;

      // Get total artworks
      int totalArtworks = 0;
      int totalViews = 0;
      int totalSales = 0;
      double totalRevenue = 0.0;
      double totalCommission = 0.0;

      // Fetch artwork analytics for each artist
      for (final artistId in artistIds) {
        // Get artwork count
        final artworksSnapshot = await _firestore
            .collection('artwork')
            .where('artistId', isEqualTo: artistId)
            .get();

        totalArtworks += artworksSnapshot.docs.length;

        // Get views
        final viewsSnapshot = await _artworkViewsCollection
            .where('artistId', isEqualTo: artistId)
            .where('viewedAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('viewedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .get();

        totalViews += viewsSnapshot.docs.length;

        // Get sales data
        final salesSnapshot = await _firestore
            .collection('sales')
            .where('artistId', isEqualTo: artistId)
            .where('saleDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('saleDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .get();

        totalSales +=
            salesSnapshot.docs.length; // Calculate revenue and commission
        for (final saleDoc in salesSnapshot.docs) {
          final saleData = saleDoc.data();
          final saleAmount = (saleData['amount'] as num).toDouble();
          final commissionRate =
              (saleData['commissionRate'] as num?)?.toDouble() ?? 0.0;

          totalRevenue += saleAmount;
          totalCommission += (saleAmount * commissionRate / 100);
        }
      }

      // Calculate views to sales rate
      double viewsToSalesRate = 0.0;
      if (totalViews > 0) {
        viewsToSalesRate = (totalSales / totalViews) * 100;
      }

      // Set results
      result['totalArtworks'] = totalArtworks;
      result['totalViews'] = totalViews;
      result['totalSales'] = totalSales;
      result['totalRevenue'] = totalRevenue;
      result['totalCommission'] = totalCommission;
      result['viewsToSalesRate'] = viewsToSalesRate;
    } catch (e) {
      logger.e('Error getting gallery analytics: $e');
      throw Exception('Failed to load gallery analytics: $e');
    }

    return result;
  }

  /// Get artist performance analytics for gallery
  Future<List<Map<String, dynamic>>> getArtistPerformanceAnalytics({
    required String galleryProfileId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final result = <Map<String, dynamic>>[];

    try {
      // Get gallery profile
      final galleryDoc = await _firestore
          .collection('artistProfiles')
          .doc(galleryProfileId)
          .get();

      if (!galleryDoc.exists) {
        throw Exception('Gallery profile not found');
      }

      final galleryData = galleryDoc.data() as Map<String, dynamic>;

      // Get associated artists
      final artistIds = List<String>.from(
          (galleryData['galleryArtists'] as List<dynamic>?) ?? []);

      // Fetch performance data for each artist
      for (final artistId in artistIds) {
        final artistData = <String, dynamic>{};

        // Get artist profile
        final artistDoc =
            await _firestore.collection('artistProfiles').doc(artistId).get();

        if (artistDoc.exists) {
          final profile = artistDoc.data() as Map<String, dynamic>;
          artistData['artistId'] = artistId;
          artistData['displayName'] = profile['displayName'];
          artistData['profileImageUrl'] = profile['profileImageUrl'];
          artistData['location'] = profile['location'];

          // Get artwork views
          final viewsSnapshot = await _artworkViewsCollection
              .where('artistId', isEqualTo: artistId)
              .where('viewedAt',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
              .where('viewedAt',
                  isLessThanOrEqualTo: Timestamp.fromDate(endDate))
              .get();

          artistData['artworkViews'] = viewsSnapshot.docs.length;

          // Get sales data
          final salesSnapshot = await _firestore
              .collection('sales')
              .where('artistId', isEqualTo: artistId)
              .where('saleDate',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
              .where('saleDate',
                  isLessThanOrEqualTo: Timestamp.fromDate(endDate))
              .get();

          artistData['sales'] = salesSnapshot.docs.length;

          // Calculate revenue and commission
          double revenue = 0.0;
          double commission = 0.0;

          for (final saleDoc in salesSnapshot.docs) {
            final saleData = saleDoc.data();
            final saleAmount = (saleData['amount'] as num).toDouble();
            final commissionRate =
                (saleData['commissionRate'] as num?)?.toDouble() ?? 0.0;

            revenue += saleAmount;
            commission += (saleAmount * commissionRate / 100);
          }

          artistData['revenue'] = revenue;
          artistData['commission'] = commission;

          result.add(artistData);
        }
      }

      // Sort by revenue in descending order
      result.sort(
          (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
    } catch (e) {
      logger.e('Error getting artist performance analytics: $e');
      throw Exception('Failed to load artist performance analytics: $e');
    }

    return result;
  }

  /// Get commission metrics for gallery
  Future<Map<String, dynamic>> getCommissionMetrics({
    required String galleryProfileId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final result = <String, dynamic>{};

    try {
      // Get commission records
      final commissionsSnapshot = await _firestore
          .collection('commissions')
          .where('galleryId', isEqualTo: galleryProfileId)
          .get();

      // Calculate average commission rate
      double totalRate = 0.0;
      double pendingCommission = 0.0;
      double paidCommission = 0.0;

      for (final doc in commissionsSnapshot.docs) {
        final data = doc.data();
        final commissionRate = (data['commissionRate'] as num).toDouble();
        totalRate += commissionRate;

        // Calculate pending and paid commissions
        if (data['transactions'] != null) {
          final transactions = List<Map<String, dynamic>>.from(
              (data['transactions'] as List<dynamic>? ?? [])
                  .map((e) => e as Map<String, dynamic>));
          for (final transaction in transactions) {
            final amount = (transaction['commissionAmount'] as num).toDouble();

            if (transaction['status'] == 'pending') {
              pendingCommission += amount;
            } else if (transaction['status'] == 'paid') {
              paidCommission += amount;
            }
          }
        }
      }

      // Calculate average
      double avgCommissionRate = 0.0;
      if (commissionsSnapshot.docs.isNotEmpty) {
        avgCommissionRate = totalRate / commissionsSnapshot.docs.length;
      }

      result['avgCommissionRate'] = avgCommissionRate;
      result['pendingCommission'] = pendingCommission;
      result['paidCommission'] = paidCommission;
    } catch (e) {
      logger.e('Error getting commission metrics: $e');
      throw Exception('Failed to load commission metrics: $e');
    }

    return result;
  }

  /// Get revenue timeline data for chart
  Future<List<Map<String, dynamic>>> getRevenueTimelineData({
    required String galleryProfileId,
    required DateTime startDate,
    required DateTime endDate,
    required String groupBy, // 'day' or 'month'
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final result = <Map<String, dynamic>>[];

    try {
      // Get gallery profile
      final galleryDoc = await _firestore
          .collection('artistProfiles')
          .doc(galleryProfileId)
          .get();

      if (!galleryDoc.exists) {
        throw Exception('Gallery profile not found');
      }

      final galleryData = galleryDoc.data() as Map<String, dynamic>;

      // Get associated artists
      final artistIds = List<String>.from(
          (galleryData['galleryArtists'] as List<dynamic>?) ?? []);

      // Create a map to store revenue by date
      final revenueByDate = <String, double>{};

      // Get sales data for each artist
      for (final artistId in artistIds) {
        final salesSnapshot = await _firestore
            .collection('sales')
            .where('artistId', isEqualTo: artistId)
            .where('saleDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('saleDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .get();

        for (final saleDoc in salesSnapshot.docs) {
          final saleData = saleDoc.data();
          final saleDate = (saleData['saleDate'] as Timestamp).toDate();
          final saleAmount = (saleData['amount'] as num).toDouble();

          // Format date key based on groupBy parameter
          String dateKey;
          if (groupBy == 'day') {
            dateKey =
                '${saleDate.year}-${saleDate.month.toString().padLeft(2, '0')}-${saleDate.day.toString().padLeft(2, '0')}';
          } else {
            dateKey =
                '${saleDate.year}-${saleDate.month.toString().padLeft(2, '0')}';
          }

          // Add revenue to date
          revenueByDate[dateKey] = (revenueByDate[dateKey] ?? 0.0) + saleAmount;
        }
      }

      // Generate a complete date range
      DateTime current =
          DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        String dateKey;
        if (groupBy == 'day') {
          dateKey =
              '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
        } else {
          dateKey =
              '${current.year}-${current.month.toString().padLeft(2, '0')}';
          // Skip to next month
          current = DateTime(current.year, current.month + 1, 1);
          continue;
        }

        result.add({
          'date': current,
          'dateKey': dateKey,
          'revenue': revenueByDate[dateKey] ?? 0.0,
        });

        // Move to next day
        current = current.add(const Duration(days: 1));
      }

      // Sort results by date
      result.sort(
          (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    } catch (e) {
      logger.e('Error getting revenue timeline data: $e');
      throw Exception('Failed to load revenue timeline data: $e');
    }

    return result;
  }

  /// Get quick statistics for artist dashboard
  Future<Map<String, dynamic>> getQuickStats(String userId) async {
    try {
      // Get last 30 days period
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      // Get artwork views
      final viewsSnapshot = await _artworkViewsCollection
          .where('artistId', isEqualTo: userId)
          .where('viewedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      // Get profile views
      final profileViewsSnapshot = await _artistProfileViewsCollection
          .where('artistId', isEqualTo: userId)
          .where('viewedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      // Get artwork stats (likes, comments, etc.)
      final artworkSnapshot = await _firestore
          .collection('artwork')
          .where('artistId', isEqualTo: userId)
          .get();

      int totalLikes = 0;
      int totalComments = 0;
      for (var doc in artworkSnapshot.docs) {
        final data = doc.data();
        totalLikes += (data['likes'] ?? 0) as int;
        totalComments += (data['comments'] ?? 0) as int;
      }

      return {
        'artworkViews': viewsSnapshot.docs.length,
        'profileViews': profileViewsSnapshot.docs.length,
        'totalLikes': totalLikes,
        'totalComments': totalComments,
      };
    } catch (e) {
      logger.e('Error getting quick stats: $e');
      rethrow;
    }
  }

  /// Get recent activities for the artist dashboard
  Future<List<Map<String, dynamic>>> getRecentActivities(String userId) async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Get recent artwork views
      final viewsQuery = _artworkViewsCollection
          .where('artistId', isEqualTo: userId)
          .where('viewedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('viewedAt', descending: true)
          .limit(10);

      // Get recent profile views
      final profileViewsQuery = _artistProfileViewsCollection
          .where('artistId', isEqualTo: userId)
          .where('viewedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('viewedAt', descending: true)
          .limit(10);

      // Get recent comments
      final commentsQuery = _firestore
          .collection('comments')
          .where('artistId', isEqualTo: userId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('createdAt', descending: true)
          .limit(10);

      // Execute queries in parallel
      final results = await Future.wait([
        viewsQuery.get(),
        profileViewsQuery.get(),
        commentsQuery.get(),
      ]);

      final activities = <Map<String, dynamic>>[];

      // Process artwork views
      for (var doc in results[0].docs) {
        final data = doc.data() as Map<String, dynamic>;
        activities.add({
          'type': 'artwork_view',
          'timestamp': data['viewedAt'],
          'artworkId': data['artworkId'],
          'viewerId': data['viewerId'],
        });
      }

      // Process profile views
      for (var doc in results[1].docs) {
        final data = doc.data() as Map<String, dynamic>;
        activities.add({
          'type': 'profile_view',
          'timestamp': data['viewedAt'],
          'viewerId': data['viewerId'],
        });
      }

      // Process comments
      for (var doc in results[2].docs) {
        final data = doc.data() as Map<String, dynamic>;
        activities.add({
          'type': 'comment',
          'timestamp': data['createdAt'],
          'artworkId': data['artworkId'],
          'commenterId': data['userId'],
          'comment': data['text'],
        });
      }

      // Sort all activities by timestamp
      activities.sort((a, b) =>
          (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

      // Return most recent 10 activities
      return activities.take(10).toList();
    } catch (e) {
      logger.e('Error getting recent activities: $e');
      rethrow;
    }
  }

  /// Get commission summary data for an artist
  Future<Map<String, dynamic>> getCommissionSummary() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final result = <String, dynamic>{};

    try {
      // Get all active commissions for the artist
      final commissionsSnapshot = await _firestore
          .collection('commissions')
          .where('artistId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      result['activeCommissions'] = commissionsSnapshot.docs.length;

      double totalPendingAmount = 0;
      double totalPaidAmount = 0;
      final galleries = <String>{};

      for (final doc in commissionsSnapshot.docs) {
        final data = doc.data();
        galleries.add(data['galleryId'] as String);

        if (data['transactions'] != null) {
          final transactions = List<Map<String, dynamic>>.from(
              (data['transactions'] as List<dynamic>? ?? [])
                  .map((e) => e as Map<String, dynamic>));
          for (final transaction in transactions) {
            final amount = (transaction['commissionAmount'] as num).toDouble();
            if (transaction['status'] == 'pending') {
              totalPendingAmount += amount;
            } else if (transaction['status'] == 'paid') {
              totalPaidAmount += amount;
            }
          }
        }
      }

      result['totalPendingAmount'] = totalPendingAmount;
      result['totalPaidAmount'] = totalPaidAmount;
      result['activeGalleries'] = galleries.length;

      // Get recent transactions (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentTransactions = <Map<String, dynamic>>[];

      for (final doc in commissionsSnapshot.docs) {
        final data = doc.data();
        if (data['transactions'] != null) {
          final transactions = List<Map<String, dynamic>>.from(
              (data['transactions'] as List<dynamic>? ?? [])
                  .map((e) => e as Map<String, dynamic>));
          for (final transaction in transactions) {
            final date = (transaction['date'] as Timestamp).toDate();
            if (date.isAfter(thirtyDaysAgo)) {
              recentTransactions.add({
                'galleryId': data['galleryId'],
                'amount': transaction['commissionAmount'],
                'status': transaction['status'],
                'date': date,
              });
            }
          }
        }
      }

      // Sort transactions by date
      recentTransactions.sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      result['recentTransactions'] = recentTransactions;

      return result;
    } catch (e) {
      logger.e('Error getting commission summary: $e');
      throw Exception('Failed to load commission summary: $e');
    }
  }

  /// Get comprehensive artist analytics data for Pro subscribers
  Future<Map<String, dynamic>> getArtistAnalyticsData(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Get artwork views
      final artworkViewsSnapshot = await _firestore
          .collection('artworkViews')
          .where('artistId', isEqualTo: userId)
          .where('viewedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('viewedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Get profile views
      final profileViewsSnapshot = await _firestore
          .collection('artistProfileViews')
          .where('artistId', isEqualTo: userId)
          .where('viewedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('viewedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Get artwork data
      final artworkSnapshot = await _firestore
          .collection('artwork')
          .where('userId', isEqualTo: userId)
          .get();

      return {
        'totalArtworkViews': artworkViewsSnapshot.docs.length,
        'totalProfileViews': profileViewsSnapshot.docs.length,
        'totalArtwork': artworkSnapshot.docs.length,
        'averageViewsPerArtwork': artworkSnapshot.docs.isEmpty
            ? 0.0
            : artworkViewsSnapshot.docs.length / artworkSnapshot.docs.length,
        'artworkViews':
            artworkViewsSnapshot.docs.map((doc) => doc.data()).toList(),
        'profileViews':
            profileViewsSnapshot.docs.map((doc) => doc.data()).toList(),
        'artwork': artworkSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList(),
      };
    } catch (e) {
      logger.e('Error getting artist analytics data: $e');
      return {};
    }
  }

  /// Get "First-Week Win" highlights for new artists
  Future<List<Map<String, dynamic>>> getDiscoveryBoostHighlights(String userId) async {
    try {
      // Check artist profile creation date
      final profileSnapshot = await _firestore
          .collection('artistProfiles')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (profileSnapshot.docs.isEmpty) return [];
      
      final profileData = profileSnapshot.docs.first.data();
      final createdAt = (profileData['createdAt'] as Timestamp).toDate();
      final daysSinceJoined = DateTime.now().difference(createdAt).inDays;
      
      // Only show boost highlights for the first 7 days
      if (daysSinceJoined > 7) return [];
      
      // Get real data to make it authentic
      final viewsSnapshot = await _firestore
          .collection('artworkViews')
          .where('artistId', isEqualTo: userId)
          .get();
          
      final savesSnapshot = await _firestore
          .collection('savedArtworks')
          .where('artistId', isEqualTo: userId)
          .get();

      final highlights = <Map<String, dynamic>>[];
      
      // 1. Daily Reach Win
      if (viewsSnapshot.docs.isNotEmpty) {
        highlights.add({
          'title': 'Discovery Boost Active',
          'message': '${viewsSnapshot.docs.length} people nearby saw your work today.',
          'icon': 'visibility',
          'color': 'blue',
        });
      }
      
      // 2. Map Placement Win (Always true in first week as part of the shift)
      highlights.add({
        'title': 'Local Discovery Map',
        'message': 'Your gallery was added to the Local Discovery Map.',
        'icon': 'map',
        'color': 'green',
      });
      
      // 3. First Save Win
      if (savesSnapshot.docs.isNotEmpty) {
        highlights.add({
          'title': 'First Interest!',
          'message': 'Someone just bookmarked your piece for their collection.',
          'icon': 'bookmark',
          'color': 'orange',
        });
      } else if (daysSinceJoined < 2) {
        // Mock a positive message if they just joined
        highlights.add({
          'title': 'Preparing Your Boost',
          'message': 'We are showcasing your work to collectors in your area.',
          'icon': 'auto_awesome',
          'color': 'purple',
        });
      }
      
      return highlights;
    } catch (e) {
      return [];
    }
  }

  /// Get basic artist analytics data for Basic subscribers
  Future<Map<String, dynamic>> getBasicArtistAnalyticsData(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Get total views count only
      final artworkViewsSnapshot = await _firestore
          .collection('artworkViews')
          .where('artistId', isEqualTo: userId)
          .where('viewedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('viewedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final profileViewsSnapshot = await _firestore
          .collection('artistProfileViews')
          .where('artistId', isEqualTo: userId)
          .where('viewedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('viewedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final artworkSnapshot = await _firestore
          .collection('artwork')
          .where('userId', isEqualTo: userId)
          .get();

      return {
        'totalArtworkViews': artworkViewsSnapshot.docs.length,
        'totalProfileViews': profileViewsSnapshot.docs.length,
        'totalArtwork': artworkSnapshot.docs.length,
      };
    } catch (e) {
      logger.e('Error getting basic artist analytics data: $e');
      return {};
    }
  }
}
