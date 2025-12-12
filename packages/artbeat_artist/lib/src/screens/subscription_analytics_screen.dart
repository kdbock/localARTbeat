import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription_model.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../services/subscription_service.dart' as artist_service;
import '../services/analytics_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:logger/logger.dart';

/// Screen for showing artists detailed subscription analytics
class SubscriptionAnalyticsScreen extends StatefulWidget {
  const SubscriptionAnalyticsScreen({super.key});

  @override
  State<SubscriptionAnalyticsScreen> createState() =>
      _SubscriptionAnalyticsScreenState();
}

class _SubscriptionAnalyticsScreenState
    extends State<SubscriptionAnalyticsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final artist_service.SubscriptionService _subscriptionService =
      artist_service.SubscriptionService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final Logger _logger = Logger();

  bool _isLoading = true;
  bool _hasProAccess = false;
  SubscriptionModel? _subscription;
  Map<String, dynamic> _subscriptionDetails = {};
  Map<String, dynamic> _analyticsData = {};

  // Date range for analytics
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load subscription and analytics data
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final subscription = await _subscriptionService.getUserSubscription();
      final hasProAccess = subscription != null &&
          (subscription.tier == core.SubscriptionTier.creator ||
              subscription.tier == core.SubscriptionTier.business ||
              subscription.tier == core.SubscriptionTier.enterprise) &&
          (subscription.status == 'active' ||
              subscription.status == 'trialing');

      if (!hasProAccess) {
        setState(() {
          _hasProAccess = false;
          _isLoading = false;
        });
        return;
      }

      // Load subscription details
      final details = await _getSubscriptionDetails(subscription);

      // Calculate analytics data based on selected date range
      final analytics = await _calculateAnalytics();

      if (mounted) {
        setState(() {
          _subscription = subscription;
          _hasProAccess = hasProAccess;
          _subscriptionDetails = details;
          _analyticsData = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'artist_subscription_analytics_error_error_loading_analytics'
                      .tr())),
        );
        setState(() {
          _isLoading = false;
          _hasProAccess = false;
        });
      }
    }
  }

  /// Get detailed subscription information
  Future<Map<String, dynamic>> _getSubscriptionDetails(
      SubscriptionModel subscription) async {
    final Map<String, dynamic> details = {};
    details['tier'] = subscription.tier;
    details['isActive'] =
        (subscription.status == 'active' || subscription.status == 'trialing');
    details['startDate'] = subscription.startDate;
    details['endDate'] = subscription.endDate;
    details['autoRenew'] = subscription.autoRenew;

    // Get billing history
    try {
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      details['recentPayments'] =
          paymentsSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      _logger.e('Error loading payment history: $e');
      details['recentPayments'] = <Map<String, dynamic>>[];
    }

    return details;
  }

  /// Calculate analytics data based on date range
  Future<Map<String, dynamic>> _calculateAnalytics() async {
    final analytics = <String, dynamic>{};

    try {
      // Get profile views analytics
      final profileAnalytics = await _analyticsService.getProfileAnalytics(
        startDate: _startDate,
        endDate: _endDate,
      );

      // Get artwork views analytics
      final artworkAnalytics = await _analyticsService.getArtworkAnalytics(
        startDate: _startDate,
        endDate: _endDate,
      );

      // Get follower analytics
      final followerAnalytics = await _analyticsService.getFollowerAnalytics(
        startDate: _startDate,
        endDate: _endDate,
      );

      // Combine all analytics
      analytics.addAll(profileAnalytics);
      analytics.addAll(artworkAnalytics);
      analytics.addAll(followerAnalytics);

      // Calculate engagement metrics
      analytics['engagementRate'] = _calculateEngagementRate(
        (analytics['totalProfileViews'] ?? 0) as int,
        (analytics['totalViews'] ?? 0) as int,
        (analytics['newFollowers'] ?? 0) as int,
      );

      // Get artwork count
      final artworkSnapshot = await _firestore
          .collection('artwork')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .get();

      analytics['artworkCount'] = artworkSnapshot.size;
    } catch (e) {
      _logger.e('Error calculating analytics: $e');
    }

    return analytics;
  }

  /// Calculate engagement rate based on views and follows
  double _calculateEngagementRate(
      int profileViews, int artworkViews, int newFollowers) {
    final totalViews = profileViews + artworkViews;

    if (totalViews == 0) {
      return 0.0;
    }

    // Simple engagement rate calculation: (new followers / total views) * 100
    return (newFollowers / totalViews) * 100;
  }

  /// Update the date range and reload data
  void _updateDateRange(String range) {
    final DateTime now = DateTime.now();
    DateTime start;

    switch (range) {
      case 'last_30_days':
        start = now.subtract(const Duration(days: 30));
        break;
      case 'last_90_days':
        start = now.subtract(const Duration(days: 90));
        break;
      case 'this_year':
        start = DateTime(now.year, 1, 1);
        break;
      case 'all_time':
        start = now.subtract(const Duration(days: 365));
        break;
      default:
        start = now.subtract(const Duration(days: 30));
    }

    setState(() {
      _startDate = start;
      _endDate = now;
    });

    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const core.MainLayout(
        currentIndex: -1,
        child: Scaffold(
          appBar: core.EnhancedUniversalHeader(
            title: 'Subscription Analytics',
            showLogo: false,
          ),
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Show upgrade prompt for users without Pro access
    if (!_hasProAccess) {
      return core.MainLayout(
          currentIndex: -1,
          child: Scaffold(
            appBar: const core.EnhancedUniversalHeader(
              title: 'Subscription Analytics',
              showLogo: false,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.analytics, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(tr('art_walk_subscription_analytics'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(tr('art_walk_get_detailed_insights_about_your_subscription_performance'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Text(tr('art_walk_available_with_artist_pro_plan'),
                    style: const TextStyle(fontSize: 18, color: Colors.deepPurple),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/artist/subscription');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child:
                        Text(tr('artist_event_creation_text_upgrade_to_pro')),
                  ),
                ],
              ),
            ),
          ));
    }

    return core.MainLayout(
        currentIndex: -1,
        child: Scaffold(
          appBar: core.EnhancedUniversalHeader(
            title: 'Subscription Analytics',
            showLogo: false,
            actions: [
              PopupMenuButton<String>(
                onSelected: _updateDateRange,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'last_30_days',
                    child: Text(
                        'artist_gallery_analytics_dashboard_text_last_30_days'
                            .tr()),
                  ),
                  PopupMenuItem(
                    value: 'last_90_days',
                    child: Text(
                        'artist_gallery_analytics_dashboard_text_last_90_days'
                            .tr()),
                  ),
                  PopupMenuItem(
                    value: 'this_year',
                    child: Text(
                        tr('artist_subscription_analytics_text_this_year')),
                  ),
                  PopupMenuItem(
                    value: 'all_time',
                    child: Text(
                        tr('artist_subscription_analytics_text_all_time')),
                  ),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubscriptionCard(),
                  const SizedBox(height: 24),
                  _buildAnalyticsSummary(),
                  const SizedBox(height: 32),
                  _buildPerformanceChart(),
                  const SizedBox(height: 32),
                  _buildFollowerGrowthChart(),
                  const SizedBox(height: 32),
                  _buildRecentPayments(),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildSubscriptionCard() {
    if (_subscription == null) {
      return const SizedBox.shrink();
    }

    final DateFormat formatter = DateFormat('MMM d, yyyy');
    final String tierName = _getTierName(_subscription!.tier);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getTierColor(_subscription!.tier),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tierName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  (_subscription!.status == 'active' ||
                          _subscription!.status == 'trialing')
                      ? 'Active'
                      : 'Inactive',
                  style: TextStyle(
                    color: (_subscription!.status == 'active' ||
                            _subscription!.status == 'trialing')
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('art_walk_start_date'),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      formatter.format(_subscription!.startDate),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(tr('art_walk_next_billing_date'),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      formatter
                          .format(_subscription!.endDate ?? DateTime.now()),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Auto-renew: ${_subscription!.autoRenew ? 'Enabled' : 'Disabled'}',
                  style: TextStyle(
                    color: (_subscription!.autoRenew)
                        ? Colors.green.shade700
                        : Colors.grey.shade700,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/artist/subscription');
                  },
                  child: Text(
                      'artist_subscription_analytics_text_manage_subscription'
                          .tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSummary() {
    final totalProfileViews = _analyticsData['totalProfileViews'] ?? 0;
    final totalArtworkViews = _analyticsData['totalViews'] ?? 0;
    final totalFollowers = _analyticsData['totalFollowers'] ?? 0;
    final newFollowers = _analyticsData['newFollowers'] ?? 0;
    final engagementRate = _analyticsData['engagementRate'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Summary',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
              'Profile Views',
              totalProfileViews.toString(),
              Icons.visibility,
              Colors.blue,
            ),
            _buildStatCard(
              'Artwork Views',
              totalArtworkViews.toString(),
              Icons.image,
              Colors.orange,
            ),
            _buildStatCard(
              'Total Followers',
              totalFollowers.toString(),
              Icons.people,
              Colors.purple,
            ),
            _buildStatCard(
              'New Followers',
              newFollowers.toString(),
              Icons.person_add,
              Colors.green,
            ),
            _buildStatCard(
              'Engagement Rate',
              '${engagementRate.toStringAsFixed(1)}%',
              Icons.trending_up,
              Colors.red,
            ),
            _buildStatCard(
              'Artwork Count',
              (_analyticsData['artworkCount'] ?? 0).toString(),
              Icons.brush,
              Colors.indigo,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    // Extract profile view data by day
    final profileViewsByDay =
        _analyticsData['profileViewsByDay'] as Map<String, int>? ?? {};

    // Prepare data for the chart
    final List<FlSpot> spots = [];
    final List<String> dates = [];

    // Sort the dates
    final sortedDates = profileViewsByDay.keys.toList()..sort();

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final views = profileViewsByDay[date] ?? 0;
      spots.add(FlSpot(i.toDouble(), views.toDouble()));
      dates.add(date);
    }

    if (spots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(tr('art_walk_profile_views_over_time'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                  tr('artist_subscription_analytics_text_no_data_available')),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('art_walk_profile_views_over_time'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(tr('art_walk_'));
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      reservedSize: 40,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      color: Colors.blue.withAlpha(51),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowerGrowthChart() {
    // Extract follower data by day
    final followersByDay =
        _analyticsData['followersByDay'] as Map<String, int>? ?? {};

    // Prepare data for the chart
    final List<FlSpot> spots = [];
    final List<String> dates = [];

    // Sort the dates
    final sortedDates = followersByDay.keys.toList()..sort();

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final followers = followersByDay[date] ?? 0;
      spots.add(FlSpot(i.toDouble(), followers.toDouble()));
      dates.add(date);
    }

    if (spots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(tr('art_walk_new_followers_over_time'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                  tr('artist_subscription_analytics_text_no_data_available')),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('art_walk_new_followers_over_time'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPayments() {
    final recentPayments =
        _subscriptionDetails['recentPayments'] as List<dynamic>? ?? [];

    if (recentPayments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('art_walk_recent_payments'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...recentPayments.map((payment) {
          final createdAt = (payment['createdAt'] as Timestamp?)?.toDate();
          final amount = payment['amount'] as int? ?? 0;
          final currency = payment['currency'] as String? ?? 'usd';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('art_walk_payment_completed'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          DateFormat.yMMMd().format(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '\$${(amount / 100).toStringAsFixed(2)} ${currency.toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Helper to get tier name string
  String _getTierName(core.SubscriptionTier tier) {
    return tier.displayName;
  }

  /// Helper to get tier color
  Color _getTierColor(core.SubscriptionTier tier) {
    switch (tier) {
      case core.SubscriptionTier.creator:
        return Colors.blue.shade700;
      case core.SubscriptionTier.business:
        return Colors.purple.shade700;
      case core.SubscriptionTier.enterprise:
        return Colors.amber.shade700;
      case core.SubscriptionTier.starter:
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
