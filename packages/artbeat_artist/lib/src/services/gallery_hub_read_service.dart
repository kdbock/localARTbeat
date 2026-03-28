import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/activity_model.dart';

class GalleryHubReadService {
  GalleryHubReadService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const double _momentumDecayRateWeekly = 0.10;

  String? getCurrentUserId() => _auth.currentUser?.uid;

  Future<Map<String, dynamic>> loadVisibilityData({
    required String userId,
    required double totalSales,
  }) async {
    try {
      final artworkCount = await _getArtworkCount(userId);
      final profileViews = await _getProfileViews(userId);

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final artistXP = userDoc.exists
          ? (userDoc.data()?['artistXP'] as int? ?? 0)
          : 0;

      final profileDoc = await _firestore
          .collection('artistProfiles')
          .doc(userId)
          .get();
      final followerCount = profileDoc.exists
          ? (profileDoc.data()?['followerCount'] as int? ?? 0)
          : 0;

      final momentumDoc = await _firestore
          .collection('artist_momentum')
          .doc(userId)
          .get();
      final momentumData = momentumDoc.data() ?? {};
      final rawMomentum = (momentumData['momentum'] as num?)?.toDouble() ?? 0.0;
      final weeklyMomentum =
          (momentumData['weeklyMomentum'] as num?)?.toDouble() ?? 0.0;
      final momentumLastUpdated =
          (momentumData['momentumLastUpdated'] as Timestamp?)?.toDate();
      final weeklyWindowStart =
          (momentumData['weeklyWindowStart'] as Timestamp?)?.toDate();

      return {
        'artworkCount': artworkCount,
        'profileViews': profileViews,
        'totalSales': totalSales,
        'followerCount': followerCount,
        'artistXP': artistXP,
        'momentum': _calculateDecayedMomentum(rawMomentum, momentumLastUpdated),
        'weeklyMomentum': weeklyMomentum,
        'weeklyWindowStart': weeklyWindowStart,
        'momentumLastUpdated': momentumLastUpdated,
      };
    } catch (_) {
      return {};
    }
  }

  Future<List<ActivityModel>> loadRecentActivities(String userId) async {
    final activities = <ActivityModel>[];

    try {
      activities.addAll(await _loadSalesActivities(userId));
      activities.addAll(await _loadCommissionActivities(userId));
      activities.addAll(await _loadAuctionActivities(userId));
      activities.addAll(await _loadGiftActivities(userId));

      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return activities.take(5).toList();
    } catch (_) {
      return activities;
    }
  }

  double _calculateDecayedMomentum(double momentum, DateTime? lastUpdated) {
    if (momentum <= 0 || lastUpdated == null) return momentum;
    final elapsedHours = DateTime.now().difference(lastUpdated).inHours;
    if (elapsedHours <= 0) return momentum;
    final weeksElapsed = elapsedHours / (24 * 7);
    return momentum * math.pow(1 - _momentumDecayRateWeekly, weeksElapsed);
  }

  Future<int> _getArtworkCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('artwork')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _getProfileViews(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('artistProfileViews')
          .where('artistId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }

  Future<List<ActivityModel>> _loadSalesActivities(String userId) async {
    final activities = <ActivityModel>[];

    try {
      final snapshot = await _firestore
          .collection('artwork_sales')
          .where('artistID', isEqualTo: userId)
          .orderBy('soldAt', descending: true)
          .limit(3)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final artworkTitle = data['artworkTitle'] as String? ?? 'Artwork';
        final soldAt =
            (data['soldAt'] as Timestamp?)?.toDate() ?? DateTime.now();

        activities.add(
          ActivityModel(
            type: ActivityType.sale,
            title: 'Artwork Sold',
            description: '"$artworkTitle" was sold',
            timeAgo: _formatTimeAgo(soldAt),
            timestamp: soldAt,
          ),
        );
      }
    } catch (_) {}

    return activities;
  }

  Future<List<ActivityModel>> _loadCommissionActivities(String userId) async {
    final activities = <ActivityModel>[];

    try {
      final snapshot = await _firestore
          .collection('commission_requests')
          .where('artistId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final createdAt =
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

        activities.add(
          ActivityModel(
            type: ActivityType.commission,
            title: 'Commission Request',
            description: 'New commission inquiry received',
            timeAgo: _formatTimeAgo(createdAt),
            timestamp: createdAt,
          ),
        );
      }
    } catch (_) {}

    return activities;
  }

  Future<List<ActivityModel>> _loadAuctionActivities(String userId) async {
    final activities = <ActivityModel>[];

    try {
      final artworkSnapshot = await _firestore
          .collection('artwork')
          .where('userId', isEqualTo: userId)
          .where('auctionEnabled', isEqualTo: true)
          .orderBy('auctionEnd', descending: true)
          .limit(10)
          .get();

      for (final artworkDoc in artworkSnapshot.docs) {
        final bidsSnapshot = await _firestore
            .collection('artwork')
            .doc(artworkDoc.id)
            .collection('bids')
            .orderBy('timestamp', descending: true)
            .limit(3)
            .get();

        for (final bidDoc in bidsSnapshot.docs) {
          final bidData = bidDoc.data();
          final timestamp =
              (bidData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bidAmount = bidData['amount'] as num? ?? 0;

          activities.add(
            ActivityModel(
              type: ActivityType.auction,
              title: 'New Bid',
              description: 'Bid of \$${bidAmount.toStringAsFixed(2)} placed',
              timeAgo: _formatTimeAgo(timestamp),
              timestamp: timestamp,
            ),
          );
        }
      }
    } catch (_) {}

    return activities;
  }

  Future<List<ActivityModel>> _loadGiftActivities(String userId) async {
    final activities = <ActivityModel>[];

    try {
      final snapshot = await _firestore
          .collection('boosts')
          .where('recipientId', isEqualTo: userId)
          .orderBy('purchaseDate', descending: true)
          .limit(3)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final purchaseDate =
            (data['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final productId = data['productId'] as String? ?? '';

        var boostName = 'Artist Boost';
        if (productId.contains('spark')) boostName = 'Spark Boost';
        if (productId.contains('surge')) boostName = 'Surge Boost';
        if (productId.contains('overdrive')) boostName = 'Overdrive Boost';

        activities.add(
          ActivityModel(
            type: ActivityType.gift,
            title: 'Boost Activated!',
            description: '$boostName received (\$${amount.toStringAsFixed(2)})',
            timeAgo: _formatTimeAgo(purchaseDate),
            timestamp: purchaseDate,
          ),
        );
      }
    } catch (_) {}

    return activities;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}
