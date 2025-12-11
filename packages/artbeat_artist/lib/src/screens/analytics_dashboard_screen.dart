import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

// Import the models and services from our packages
import 'package:artbeat_artist/src/services/analytics_service.dart';
import 'package:artbeat_artist/src/services/artwork_service.dart';
import 'package:artbeat_artist/src/models/artwork_model.dart';
import 'package:artbeat_artist/src/services/subscription_service.dart'
    as artist_subscription;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_core/src/widgets/secure_network_image.dart';
// Import provider for subscriptions

/// Analytics Dashboard Screen for Artists with Pro and Gallery plans
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final artist_subscription.SubscriptionService _subscriptionService =
      artist_subscription.SubscriptionService();
  final ArtworkService _artworkService = ArtworkService();
  final AnalyticsService _analyticsService = AnalyticsService();

  bool _isLoading = true;
  bool _hasProAccess = false;
  List<ArtworkModel> _artworks = [];
  Map<String, dynamic> _analytics = {};

  // Date range for analytics
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  final DateTime _endDate = DateTime.now();
  String _selectedRange = '30d'; // 7d, 30d, 90d, 1y

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user has pro subscription
      final String userId = _auth.currentUser?.uid ?? '';
      final userSubscription =
          await _subscriptionService.getCurrentSubscription(userId);
      final hasProAccess =
          userSubscription != null && userSubscription.isActive;

      // Load artwork
      final artworks = await _artworkService.getArtworkByUserId(userId);

      // Load analytics data based on subscription
      Map<String, dynamic> analyticsData;
      if (hasProAccess) {
        analyticsData = await _analyticsService.getArtistAnalyticsData(
          userId,
          _startDate,
          _endDate,
        );
      } else {
        analyticsData = await _analyticsService.getBasicArtistAnalyticsData(
          userId,
          _startDate,
          _endDate,
        );
      }

      setState(() {
        _hasProAccess = hasProAccess;
        _artworks = artworks;
        _analytics = analyticsData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'artist_analytics_dashboard_error_error_loading_analytics'.tr()),
        ),
      );
    }
  }

  // Update the date range and reload data
  Future<void> _updateDateRange(String range) async {
    DateTime startDate;
    switch (range) {
      case '7d':
        startDate = DateTime.now().subtract(const Duration(days: 7));
        break;
      case '30d':
        startDate = DateTime.now().subtract(const Duration(days: 30));
        break;
      case '90d':
        startDate = DateTime.now().subtract(const Duration(days: 90));
        break;
      case '1y':
        startDate = DateTime.now().subtract(const Duration(days: 365));
        break;
      default:
        startDate = DateTime.now().subtract(const Duration(days: 30));
    }

    setState(() {
      _startDate = startDate;
      _selectedRange = range;
    });

    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: -1,
      appBar: core.EnhancedUniversalHeader(
        title: 'Analytics Dashboard',
        showLogo: false,
        showBackButton: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildDateRangeSelector(),
                    const SizedBox(height: 16),
                    _buildOverviewMetrics(),
                    const SizedBox(height: 24),
                    _buildVisitorsChart(),
                    const SizedBox(height: 24),
                    if (_hasProAccess) ...<Widget>[
                      _buildLocationBreakdown(),
                      const SizedBox(height: 24),
                      _buildTopArtworks(),
                      const SizedBox(height: 24),
                      _buildReferralSources(),
                    ],
                    if (!_hasProAccess) _buildSubscriptionUpgradeCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildDateRangeButton('7d', '7 Days'),
            _buildDateRangeButton('30d', '30 Days'),
            _buildDateRangeButton('90d', '90 Days'),
            _buildDateRangeButton('1y', 'Year'),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeButton(String range, String label) {
    final isSelected = _selectedRange == range;
    return InkWell(
      onTap: () => _updateDateRange(range),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewMetrics() {
    // Safely extract int values from analytics with proper type handling
    int getIntValue(String key) {
      final dynamic value = _analytics[key];
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return int.tryParse(value.toString()) ?? 0;
    }

    // Get values with proper type casting
    final int profileViews = getIntValue('profileViews');
    final int artworkViews = getIntValue('artworkViews');
    final int favorites = getIntValue('favorites');
    final int leadClicks = getIntValue('leadClicks');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('art_walk_overview'.tr(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            _buildMetricCard('Profile Views', profileViews, Icons.visibility),
            _buildMetricCard('Artwork Views', artworkViews, Icons.image),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            _buildMetricCard('Favorites', favorites, Icons.favorite),
            _buildMetricCard('Lead Clicks', leadClicks, Icons.link),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, int value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                NumberFormat.compact().format(value),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisitorsChart() {
    final List<dynamic> visitorsData =
        _analytics['visitorsOverTime'] as List<dynamic>? ?? [];

    if (visitorsData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text('artist_analytics_dashboard_text_no_visitor_data'.tr()),
          ),
        ),
      );
    }

    final List<FlSpot> spots = visitorsData.asMap().entries.map<FlSpot>((e) {
      final dynamic value = e.value['value'];
      final double yValue = value is double
          ? value
          : (value is int
              ? value.toDouble()
              : (double.tryParse(value.toString()) ?? 0.0));
      return FlSpot(e.key.toDouble(), yValue);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Profile Visitors',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.7,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationBreakdown() {
    final locationData =
        _analytics['locationBreakdown'] as Map<dynamic, dynamic>? ?? {};

    if (locationData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child:
                Text('artist_analytics_dashboard_text_no_location_data'.tr()),
          ),
        ),
      );
    }

    // Convert to a list of entries sorted by value
    final sortedLocations = locationData.entries.toList()
      ..sort((a, b) {
        final aValue = a.value is num ? (a.value as num) : 0;
        final bValue = b.value is num ? (b.value as num) : 0;
        return bValue.compareTo(aValue);
      });

    // Take top 5 locations
    final topLocations = sortedLocations.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Top Locations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...topLocations.map<Widget>((entry) {
              final String locationName = entry.key.toString();
              final int locationValue = entry.value is num
                  ? (entry.value as num).toInt()
                  : int.tryParse(entry.value.toString()) ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(locationName),
                    ),
                    Text(
                      NumberFormat.compact().format(locationValue),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopArtworks() {
    final List<String> topArtworkIds =
        (_analytics['topArtworks'] as List<dynamic>? ?? [])
            .map<String>((dynamic id) => id?.toString() ?? '')
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('art_walk_top_performing_artwork'.tr(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (topArtworkIds.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                    'artist_analytics_dashboard_text_no_artwork_data'.tr()),
              ),
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: topArtworkIds.length > 5 ? 5 : topArtworkIds.length,
              itemBuilder: (context, index) {
                final String artworkId = topArtworkIds[index];
                final artwork = _artworks.firstWhere(
                  (a) => a.id == artworkId,
                  orElse: () => ArtworkModel(
                    id: artworkId,
                    userId: '',
                    artistProfileId: '',
                    title: 'Unknown Artwork',
                    description: '',
                    imageUrl: '',
                    price: 0,
                    medium: '',
                    isForSale: false,
                    styles: <String>[],
                  ),
                );

                return Card(
                  margin: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 180,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AspectRatio(
                          aspectRatio: 1.2,
                          child: artwork.imageUrl.isNotEmpty &&
                                  Uri.tryParse(artwork.imageUrl)?.hasScheme ==
                                      true
                              ? SecureNetworkImage(
                                  imageUrl: artwork.imageUrl,
                                  fit: BoxFit.cover,
                                  enableThumbnailFallback: true,
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          artwork.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          artwork.isForSale
                              ? '\$${artwork.price?.toStringAsFixed(2) ?? '0.00'}'
                              : 'Not for Sale',
                          style: TextStyle(
                            color:
                                artwork.isForSale ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildReferralSources() {
    final referralData =
        _analytics['referralSources'] as Map<dynamic, dynamic>? ?? {};

    if (referralData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child:
                Text('artist_analytics_dashboard_text_no_referral_data'.tr()),
          ),
        ),
      );
    }

    // Convert to a list of entries sorted by value
    final sortedReferrals = referralData.entries.toList()
      ..sort((a, b) {
        final aValue = a.value is num ? (a.value as num) : 0;
        final bValue = b.value is num ? (b.value as num) : 0;
        return bValue.compareTo(aValue);
      });

    // Take top 5 referrals
    final topReferrals = sortedReferrals.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Top Referral Sources',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...topReferrals.map<Widget>((entry) {
              final String sourceName = entry.key.toString();
              final int sourceValue = entry.value is num
                  ? (entry.value as num).toInt()
                  : int.tryParse(entry.value.toString()) ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(_formatReferralSource(sourceName)),
                    ),
                    Text(
                      NumberFormat.compact().format(sourceValue),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _formatReferralSource(String source) {
    switch (source.toLowerCase()) {
      case 'direct':
        return 'Direct Traffic';
      case 'google':
      case 'google.com':
        return 'Google';
      case 'facebook':
      case 'facebook.com':
        return 'Facebook';
      case 'instagram':
      case 'instagram.com':
        return 'Instagram';
      case 'pinterest':
      case 'pinterest.com':
        return 'Pinterest';
      case 'twitter':
      case 'twitter.com':
      case 'x.com':
        return 'Twitter / X';
      default:
        return source;
    }
  }

  Widget _buildSubscriptionUpgradeCard() {
    return Card(
      color: Theme.of(context).primaryColor.withAlpha(26), // ~0.1 opacity
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('art_walk_upgrade_to_pro_for_advanced_analytics'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('art_walk_get_access_to_location_breakdown__top_artwork_performance__referral_sources__and_more_detailed_insights'.tr(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to subscription screen
                Navigator.pushNamed(context, '/subscription');
              },
              child: Text('artist_analytics_dashboard_text_upgrade_now'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
