import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_community/artbeat_community.dart' as community;
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/activity_model.dart';
import '../widgets/local_artists_row_widget.dart';
import '../widgets/local_galleries_widget.dart';
import '../widgets/upcoming_events_row_widget.dart';
import '../services/earnings_service.dart';
import '../services/visibility_service.dart';
import '../models/earnings_model.dart';

class GalleryHubScreen extends StatefulWidget {
  const GalleryHubScreen({super.key});

  @override
  State<GalleryHubScreen> createState() => _GalleryHubScreenState();
}

class _GalleryHubScreenState extends State<GalleryHubScreen> {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Services
  final EarningsService _earningsService = EarningsService();
  final VisibilityService _analyticsService = VisibilityService();
  final core.ArtistFeatureService _featureService = core.ArtistFeatureService();
  static const double _momentumDecayRateWeekly = 0.10;
  static const int _weeklyMomentumCap = 600;

  bool _isLoading = true;
  String? _error;
  EarningsModel? _earnings;
  Map<String, dynamic> _analytics = {};
  List<ActivityModel> _recentActivities = [];
  List<Map<String, dynamic>> _discoveryHighlights = [];
  List<core.ArtistFeature> _activeBoosts = [];

  @override
  void initState() {
    super.initState();
    _loadArtistData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadArtistData() async {
    try {
      debugPrint('🚀 DEBUG: Starting to load artist data...');
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userId = _analyticsService.getCurrentUserId();
      final futures = <Future<Object?>>[
        _withTimeline<Object?>(
          'GalleryHub.loadArtistData.earnings',
          () => _earningsService.getArtistEarnings(),
        ),
        _withTimeline<Object?>(
          'GalleryHub.loadArtistData.visibility',
          _loadVisibilityData,
        ),
        _withTimeline<Object?>(
          'GalleryHub.loadArtistData.activities',
          _loadRecentActivities,
        ),
      ];

      final results = await Future.wait(futures);
      final earnings = results[0] as EarningsModel?;
      final analytics = results[1] as Map<String, dynamic>;
      final activities = results[2] as List<ActivityModel>;

      List<Map<String, dynamic>> highlights = [];
      List<core.ArtistFeature> activeBoosts = [];
      if (userId != null) {
        highlights = await _withTimeline(
          'GalleryHub.loadArtistData.highlights',
          () {
            return _analyticsService.getDiscoveryBoostHighlights(userId);
          },
        );
        activeBoosts = await _withTimeline(
          'GalleryHub.loadArtistData.features',
          () => _featureService.getActiveFeaturesForArtist(userId),
        );
      }

      if (mounted) {
        debugPrint('✅ DEBUG: All data loaded successfully');
        setState(() {
          _earnings = earnings;
          _analytics = analytics;
          _recentActivities = activities;
          _discoveryHighlights = highlights;
          _activeBoosts = activeBoosts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ DEBUG: Error in _loadArtistData: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<T> _withTimeline<T>(String name, Future<T> Function() action) async {
    final task = developer.TimelineTask();
    task.start(name);
    try {
      return await action();
    } finally {
      task.finish();
    }
  }

  Future<Map<String, dynamic>> _loadVisibilityData() async {
    try {
      final userId = _analyticsService.getCurrentUserId();
      if (userId == null) return {};

      // Get artwork count and other analytics
      final artworkCount = await _getArtworkCount(userId);
      final profileViews = await _getProfileViews(userId);
      final artBattleStats = await _getArtBattleStats(userId);

      // Get Artist XP from user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final artistXP = userDoc.exists
          ? (userDoc.data()?['artistXP'] as int? ?? 0)
          : 0;

      final momentumDoc = await FirebaseFirestore.instance
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
      final decayedMomentum = _calculateDecayedMomentum(
        rawMomentum,
        momentumLastUpdated,
      );

      return {
        'artworkCount': artworkCount,
        'profileViews': profileViews,
        'totalSales': _earnings?.totalEarnings ?? 0.0,
        'artBattleVotes': artBattleStats['totalVotes'] ?? 0,
        'artBattleAppearances': artBattleStats['totalAppearances'] ?? 0,
        'artBattleWins': artBattleStats['totalWins'] ?? 0,
        'artistXP': artistXP,
        'momentum': decayedMomentum,
        'weeklyMomentum': weeklyMomentum,
        'weeklyWindowStart': weeklyWindowStart,
        'momentumLastUpdated': momentumLastUpdated,
      };
    } catch (e) {
      return {};
    }
  }

  double _calculateDecayedMomentum(double momentum, DateTime? lastUpdated) {
    if (momentum <= 0 || lastUpdated == null) return momentum;
    final elapsedHours = DateTime.now().difference(lastUpdated).inHours;
    if (elapsedHours <= 0) return momentum;
    final weeksElapsed = elapsedHours / (24 * 7);
    return momentum * math.pow(1 - _momentumDecayRateWeekly, weeksElapsed);
  }

  String _calculatePowerLevel(int xp) {
    if (xp >= 5000) return 'Mythic Legend';
    if (xp >= 2500) return 'Titan';
    if (xp >= 1000) return 'Elite';
    if (xp >= 500) return 'Pro';
    if (xp >= 100) return 'Rising Star';
    return 'Rookie';
  }

  Future<int> _getArtworkCount(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('artwork')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getProfileViews(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('artistProfileViews')
          .where('artistId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, int>> _getArtBattleStats(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('artworks')
          .where('artistId', isEqualTo: userId)
          .get();

      int totalVotes = 0;
      int totalAppearances = 0;
      int totalWins = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalVotes += (data['artBattleScore'] as int?) ?? 0;
        totalAppearances += (data['artBattleAppearances'] as int?) ?? 0;
        totalWins += (data['artBattleWins'] as int?) ?? 0;
      }

      return {
        'totalVotes': totalVotes,
        'totalAppearances': totalAppearances,
        'totalWins': totalWins,
      };
    } catch (e) {
      return {'totalVotes': 0, 'totalAppearances': 0, 'totalWins': 0};
    }
  }

  Future<List<ActivityModel>> _loadRecentActivities() async {
    final activities = <ActivityModel>[];

    try {
      final userId = _analyticsService.getCurrentUserId();
      if (userId == null) return activities;

      // Load recent artwork sales
      final salesActivities = await _loadSalesActivities(userId);
      activities.addAll(salesActivities);

      // Load recent commission requests
      final commissionActivities = await _loadCommissionActivities(userId);
      activities.addAll(commissionActivities);

      // Load recent auction activities
      final auctionActivities = await _loadAuctionActivities(userId);
      activities.addAll(auctionActivities);

      // Load recent gift activities
      final giftActivities = await _loadGiftActivities(userId);
      activities.addAll(giftActivities);

      // Sort by most recent (descending by timestamp)
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return activities.take(5).toList();
    } catch (e) {
      return activities;
    }
  }

  Future<List<ActivityModel>> _loadSalesActivities(String userId) async {
    final activities = <ActivityModel>[];

    try {
      debugPrint('🔍 DEBUG: Loading sales activities for user: $userId');
      final snapshot = await FirebaseFirestore.instance
          .collection('artwork_sales')
          .where('artistID', isEqualTo: userId)
          .orderBy('soldAt', descending: true)
          .limit(3)
          .get();
      debugPrint(
        '✅ DEBUG: Sales activities loaded successfully: ${snapshot.docs.length} docs',
      );

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
    } catch (e) {
      debugPrint('❌ DEBUG: Error loading sales activities: $e');
    }

    return activities;
  }

  Future<List<ActivityModel>> _loadCommissionActivities(String userId) async {
    final activities = <ActivityModel>[];

    try {
      debugPrint('🔍 DEBUG: Loading commission activities for user: $userId');
      final snapshot = await FirebaseFirestore.instance
          .collection('commission_requests')
          .where('artistId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();
      debugPrint(
        '✅ DEBUG: Commission activities loaded successfully: ${snapshot.docs.length} docs',
      );

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
    } catch (e) {
      debugPrint('❌ DEBUG: Error loading commission activities: $e');
    }

    return activities;
  }

  Future<List<ActivityModel>> _loadAuctionActivities(String userId) async {
    final activities = <ActivityModel>[];

    try {
      debugPrint('🔍 DEBUG: Loading auction activities for user: $userId');
      // Get user's artworks that have auctions
      final artworkSnapshot = await FirebaseFirestore.instance
          .collection('artwork')
          .where('userId', isEqualTo: userId)
          .where('auctionEnabled', isEqualTo: true)
          .orderBy('auctionEnd', descending: true)
          .limit(10)
          .get();

      debugPrint(
        '✅ DEBUG: Found ${artworkSnapshot.docs.length} artworks with auctions',
      );

      for (final artworkDoc in artworkSnapshot.docs) {
        final artworkId = artworkDoc.id;

        // Get recent bids for this artwork
        final bidsSnapshot = await FirebaseFirestore.instance
            .collection('artwork')
            .doc(artworkId)
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
    } catch (e) {
      debugPrint('❌ DEBUG: Error loading auction activities: $e');
    }

    return activities;
  }

  Future<List<ActivityModel>> _loadGiftActivities(String userId) async {
    final activities = <ActivityModel>[];

    try {
      debugPrint('🔍 DEBUG: Loading boost activities for user: $userId');
      final snapshot = await FirebaseFirestore.instance
          .collection('boosts')
          .where('recipientId', isEqualTo: userId)
          .orderBy('purchaseDate', descending: true)
          .limit(3)
          .get();
      debugPrint(
        '✅ DEBUG: Boost activities loaded successfully: ${snapshot.docs.length} docs',
      );

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final purchaseDate =
            (data['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final productId = data['productId'] as String? ?? '';

        String boostName = 'Artist Boost';
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
    } catch (e) {
      debugPrint('❌ DEBUG: Error loading boost activities: $e');
    }

    return activities;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildCompactStatsSection() {
    developer.Timeline.instantSync(
      'GalleryHub.renderCompactStats',
      arguments: {
        'artworkCount': _analytics['artworkCount'] ?? 0,
        'profileViews': _analytics['profileViews'] ?? 0,
        'momentum': _analytics['momentum'] ?? 0,
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('art_walk_overview'),
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/artist/analytics'),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Details'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF00F5FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00F5FF).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildCompactStat(
                      '${_analytics['artistXP'] ?? 0}',
                      'Artist XP',
                      Icons.bolt,
                      const Color(0xFFFFD700),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    child: _buildCompactStat(
                      _calculatePowerLevel(
                        (_analytics['artistXP'] as num?)?.toInt() ?? 0,
                      ),
                      'Level',
                      Icons.workspace_premium,
                      const Color(0xFF00F5FF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMomentumMeter(),
              const SizedBox(height: 12),
              _buildMomentumInsights(),
              const SizedBox(height: 16),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCompactStat(
                      _analytics['artworkCount']?.toString() ?? '0',
                      'Artworks',
                      Icons.palette,
                      const Color(0xFFFF00F5),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    child: _buildCompactStat(
                      _analytics['profileViews']?.toString() ?? '0',
                      'Views',
                      Icons.visibility,
                      const Color(0xFF00F5FF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCompactStat(
                      '\$${_earnings?.totalEarnings.toStringAsFixed(2) ?? '0.00'}',
                      'Earnings',
                      Icons.payments,
                      const Color(0xFF34D399),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    child: _buildCompactStat(
                      _analytics['artBattleWins']?.toString() ?? '0',
                      'Battle Wins',
                      Icons.emoji_events,
                      Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStat(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMomentumMeter() {
    final momentum = (_analytics['momentum'] as num?)?.toDouble() ?? 0.0;
    final weeklyMomentum =
        (_analytics['weeklyMomentum'] as num?)?.toDouble() ?? 0.0;
    final weekStart = _analytics['weeklyWindowStart'] as DateTime?;
    final daysSinceStart = weekStart != null
        ? DateTime.now().difference(weekStart).inDays
        : null;
    final effectiveWeekly = (daysSinceStart != null && daysSinceStart >= 7)
        ? 0.0
        : weeklyMomentum;
    final progress = (effectiveWeekly / _weeklyMomentumCap)
        .clamp(0.0, 1.0)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Color(0xFFFF8C42),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Momentum Meter',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                momentum.toStringAsFixed(0),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF22D3EE),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Weekly: ${effectiveWeekly.toStringAsFixed(0)} / $_weeklyMomentumCap',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBoostsSection() {
    if (_activeBoosts.isEmpty) return const SizedBox.shrink();

    developer.Timeline.instantSync(
      'GalleryHub.renderActiveBoosts',
      arguments: {'count': _activeBoosts.length},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Power-Ups',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _activeBoosts.length,
            itemBuilder: (context, index) {
              final boost = _activeBoosts[index];
              return _buildBoostCard(boost);
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMomentumInsights() {
    final weeklyMomentum =
        (_analytics['weeklyMomentum'] as num?)?.toDouble() ?? 0.0;
    final nextTier = _nextBoostTier(weeklyMomentum);
    final remaining = nextTier.remaining;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Impact Preview',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nextTier.preview,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                remaining > 0
                    ? 'Next unlock: ${nextTier.label} in ${remaining.toStringAsFixed(0)} momentum'
                    : 'Next unlock: ${nextTier.label} ready',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _BoostTierInsight _nextBoostTier(double weeklyMomentum) {
    if (weeklyMomentum < 50) {
      return _BoostTierInsight(
        label: 'Spark Boost',
        remaining: 50 - weeklyMomentum,
        preview: 'Local discovery weighting + supporter badge momentum.',
      );
    }
    if (weeklyMomentum < 120) {
      return _BoostTierInsight(
        label: 'Surge Boost',
        remaining: 120 - weeklyMomentum,
        preview: 'Map glow + enhanced follow suggestions.',
      );
    }
    if (weeklyMomentum < 350) {
      return _BoostTierInsight(
        label: 'Overdrive Boost',
        remaining: 350 - weeklyMomentum,
        preview: 'Kiosk lane rotation slot + peak discovery window.',
      );
    }
    return _BoostTierInsight(
      label: 'Momentum Maxed',
      remaining: 0,
      preview: 'You are at peak momentum this week.',
    );
  }

  Widget _buildBoostCard(core.ArtistFeature boost) {
    IconData icon;
    String name;
    Color color;

    switch (boost.type) {
      case core.FeatureType.artistFeatured:
        icon = Icons.bolt;
        name = 'Profile Glow';
        color = const Color(0xFF00F5FF);
        break;
      case core.FeatureType.artworkFeatured:
        icon = Icons.auto_awesome;
        name = 'Shiny Art';
        color = const Color(0xFFFF00F5);
        break;
      case core.FeatureType.adRotation:
        icon = Icons.rocket_launch;
        name = 'Titan Reach';
        color = const Color(0xFFFFD700);
        break;
    }

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${boost.daysRemaining}d left',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E27),
        elevation: 0,
        title: Text(
          'My Gallery Hub',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF00F5FF),
            ),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      drawer: const core.ArtbeatDrawer(),
      body: _buildHubContent(),
    );
  }

  Widget _buildHubContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F5FF)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFFF00F5)),
            const SizedBox(height: 16),
            Text(
              tr('art_walk_error_loading_hub'),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadArtistData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F5FF),
                foregroundColor: const Color(0xFF0A0E27),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: Text(tr('admin_admin_settings_text_retry')),
            ),
          ],
        ),
      );
    }

    _maybeLogGalleryHubImageStats();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0E27), Color(0xFF1A1E37)],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Discovery Boost Section for New Artists
                  if (_discoveryHighlights.isNotEmpty) ...[
                    _buildDiscoveryBoostSection(),
                    const SizedBox(height: 24),
                  ],

                  // Compact Stats Overview Section
                  _buildCompactStatsSection(),
                  const SizedBox(height: 24),

                  // Quick Actions Section - Moved to top
                  _buildQuickActionsSection(context),
                  const SizedBox(height: 24),

                  // Local Artists Section
                  Text(
                    tr('art_walk_local_artists'),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LocalArtistsRowWidget(
                    zipCode:
                        '10001', // Default NYC zip code - should be user's location
                    onSeeAllPressed: () =>
                        Navigator.pushNamed(context, '/artist/browse'),
                  ),
                  const SizedBox(height: 24),

                  // Local Galleries Section
                  Text(
                    tr('art_walk_local_galleries___museums'),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LocalGalleriesWidget(
                    zipCode:
                        '10001', // Default NYC zip code - should be user's location
                    onSeeAllPressed: () =>
                        Navigator.pushNamed(context, '/galleries/browse'),
                  ),
                  const SizedBox(height: 24),

                  // Upcoming Events Section
                  Text(
                    tr('art_walk_upcoming_events'),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  UpcomingEventsRowWidget(
                    zipCode:
                        '10001', // Default NYC zip code - should be user's location
                    onSeeAllPressed: () =>
                        Navigator.pushNamed(context, '/events/browse'),
                  ),
                  const SizedBox(height: 24),

                  // Active Boosts Section
                  _buildActiveBoostsSection(),

                  // Recent Activity Section
                  if (_recentActivities.isNotEmpty) ...[
                    Text(
                      tr('art_walk_recent_activity'),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        developer.Timeline.instantSync(
                          'GalleryHub.renderRecentActivityList',
                          arguments: {'count': _recentActivities.length},
                        );
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentActivities.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final activity = _recentActivities[index];
                            final activityColor = activity.type.color;
                            developer.Timeline.instantSync(
                              'GalleryHub.activityCard',
                              arguments: {
                                'type': activity.type.name,
                                'timestamp': activity.timestamp
                                    .toIso8601String(),
                              },
                            );
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF00F5FF,
                                  ).withValues(alpha: 0.1),
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: activityColor.withValues(
                                    alpha: 0.2,
                                  ),
                                  child: Icon(
                                    activity.type.icon,
                                    color: activityColor,
                                  ),
                                ),
                                title: Text(
                                  activity.title,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  activity.description,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Text(
                                  activity.timeAgo,
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF00F5FF),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/artist/activity');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00F5FF),
                          side: const BorderSide(color: Color(0xFF00F5FF)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: Text(
                          tr('artist_artist_hub_text_view_all_activity'),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('art_walk_quick_actions'),
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildThemedActionButton(
                context,
                title: 'My Artworks',
                subtitle: 'View & manage your art',
                icon: Icons.collections_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) =>
                        const artwork.ArtistArtworkManagementScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildThemedActionButton(
                context,
                title: 'Upload Artwork',
                subtitle: 'Add new artwork to your portfolio',
                icon: Icons.add_photo_alternate,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00F5FF), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => Navigator.pushNamed(context, '/artwork/upload'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildThemedActionButton(
                context,
                title: 'Add Post',
                subtitle: 'Share updates with your community',
                icon: Icons.post_add,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF00F5), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => _showCreatePostOptions(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildThemedActionButton(
                context,
                title: 'Views & Interest',
                subtitle: 'Track your gallery reach',
                icon: Icons.visibility,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00F5FF), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => Navigator.pushNamed(context, '/artist/analytics'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildThemedActionButton(
                context,
                title: 'Create Event',
                subtitle: 'Host exhibitions and gatherings',
                icon: Icons.event,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF00F5), Color(0xFFFF6B6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => Navigator.pushNamed(context, '/events/create'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildThemedActionButton(
                context,
                title: 'Commission Wizard',
                subtitle: 'Set up commission settings',
                icon: Icons.auto_awesome,
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFFF00F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => _navigateToCommissionWizard(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildThemedActionButton(
                context,
                title: 'Commission Hub',
                subtitle: 'Manage your commissions',
                icon: Icons.work_outline,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00F5FF), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => Navigator.pushNamed(context, '/commission/hub'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildThemedActionButton(
                context,
                title: 'Auction Wizard',
                subtitle: 'Set up auction settings',
                icon: Icons.gavel,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFF7B801)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => _navigateToAuctionWizard(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildThemedActionButton(
                context,
                title: 'Auction Hub',
                subtitle: 'Manage your auctions',
                icon: Icons.store,
                gradient: const LinearGradient(
                  colors: [Color(0xFF9333EA), Color(0xFFC026D3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => Navigator.pushNamed(context, '/auction/hub'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCreatePostOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.post_add, color: Colors.purple, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('art_walk_create_post'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            tr('art_walk_share_updates_with_your_community'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Create options
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildPostOption(
                      context,
                      title: 'Text Post',
                      subtitle: 'Share your thoughts and updates',
                      icon: Icons.text_fields,
                      color: Colors.purple,
                      onTap: () => _createTextPost(context),
                    ),
                    const SizedBox(height: 12),
                    _buildPostOption(
                      context,
                      title: 'Artwork Post',
                      subtitle: 'Showcase your latest creation',
                      icon: Icons.palette,
                      color: Colors.blue,
                      onTap: () => _createArtworkPost(context),
                    ),
                    const SizedBox(height: 12),
                    _buildPostOption(
                      context,
                      title: 'Event Post',
                      subtitle: 'Announce upcoming events',
                      icon: Icons.event,
                      color: Colors.orange,
                      onTap: () => _createEventPost(context),
                    ),
                    const SizedBox(height: 12),
                    _buildPostOption(
                      context,
                      title: 'Photo Post',
                      subtitle: 'Share photos from your studio',
                      icon: Icons.photo_camera,
                      color: Colors.green,
                      onTap: () => _createPhotoPost(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _createTextPost(BuildContext context) {
    Navigator.pop(context);
    // Navigate to general post creation screen
    Navigator.pushNamed(context, '/community/create');
  }

  void _createArtworkPost(BuildContext context) {
    Navigator.pop(context);
    // Navigate to general post creation screen
    Navigator.pushNamed(context, '/community/create');
  }

  void _createEventPost(BuildContext context) {
    Navigator.pop(context);
    // Navigate to general post creation screen
    Navigator.pushNamed(context, '/community/create');
  }

  void _createPhotoPost(BuildContext context) {
    Navigator.pop(context);
    // Navigate to general post creation screen
    Navigator.pushNamed(context, '/community/create');
  }

  Widget _buildDiscoveryBoostSection() {
    developer.Timeline.instantSync(
      'GalleryHub.renderDiscoveryBoosts',
      arguments: {'count': _discoveryHighlights.length},
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Text(
              'Your Studio Launch Wins',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _discoveryHighlights.length,
            itemBuilder: (context, index) {
              final highlight = _discoveryHighlights[index];
              final color = _getHighlightColor(highlight['color'] as String);

              return Container(
                width: 240,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getHighlightIcon(highlight['icon'] as String),
                          color: color,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            highlight['title'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      highlight['message'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getHighlightColor(String colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue.shade700;
      case 'green':
        return Colors.green.shade700;
      case 'orange':
        return Colors.orange.shade700;
      case 'purple':
        return Colors.purple.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  IconData _getHighlightIcon(String iconName) {
    switch (iconName) {
      case 'visibility':
        return Icons.visibility;
      case 'map':
        return Icons.map;
      case 'bookmark':
        return Icons.bookmark;
      case 'auto_awesome':
        return Icons.auto_awesome;
      default:
        return Icons.info;
    }
  }

  Widget _buildThemedActionButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 140, // Increased from 120 to prevent overflow
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14, // Slightly smaller font
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2), // Reduced from 4
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11, // Slightly smaller font
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCommissionWizard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const community.CommissionSetupWizardScreen(
          mode: community.SetupMode.firstTime,
        ),
      ),
    );
  }

  void _navigateToAuctionWizard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const artwork.AuctionSetupWizardScreen(
          mode: artwork.AuctionSetupMode.firstTime,
        ),
      ),
    );
  }

  void _maybeLogGalleryHubImageStats() {
    if (kReleaseMode) return;
    final imageService = core.ImageManagementService();
    imageService.logCacheStats(label: 'GalleryHub.cards');
    imageService.logDecodeDimensions(
      label: 'GalleryHub.boostCard',
      width: 240,
      height: 120,
    );
    imageService.logDecodeDimensions(
      label: 'GalleryHub.activityIcon',
      width: 48,
      height: 48,
    );
  }
}

class _BoostTierInsight {
  final String label;
  final double remaining;
  final String preview;

  _BoostTierInsight({
    required this.label,
    required this.remaining,
    required this.preview,
  });
}
