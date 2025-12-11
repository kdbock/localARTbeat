import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:artbeat_artist/artbeat_artist.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;

/// Advanced Analytics Dashboard for galleries to track performance metrics
class GalleryAnalyticsDashboardScreen extends StatefulWidget {
  const GalleryAnalyticsDashboardScreen({super.key});

  @override
  State<GalleryAnalyticsDashboardScreen> createState() =>
      _GalleryAnalyticsDashboardScreenState();
}

class _GalleryAnalyticsDashboardScreenState
    extends State<GalleryAnalyticsDashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SubscriptionService _subscriptionService = SubscriptionService();
  final AnalyticsService _analyticsService = AnalyticsService();

  bool _isLoading = true;
  bool _isPremiumGallery = false;
  String? _errorMessage;
  String _selectedTimeRange = 'month';

  // Analytics data
  Map<String, dynamic> _galleryAnalytics = {};
  List<Map<String, dynamic>> _artistPerformance = [];
  Map<String, dynamic> _commissionMetrics = {};
  List<Map<String, dynamic>> _revenueData = [];

  @override
  void initState() {
    super.initState();
    _checkSubscriptionAndLoadData();
  }

  /// Check if user has premium gallery subscription and load data
  Future<void> _checkSubscriptionAndLoadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if user has premium subscription
      final subscription = await _subscriptionService.getUserSubscription();
      final hasPremium = subscription != null &&
          (subscription.tier == core.SubscriptionTier.business ||
              subscription.tier == core.SubscriptionTier.enterprise) &&
          (subscription.status == 'active' ||
              subscription.status == 'trialing');

      if (!hasPremium) {
        setState(() {
          _isPremiumGallery = false;
          _isLoading = false;
          _errorMessage =
              'Gallery analytics requires a Gallery Plan subscription.';
        });
        return;
      }

      // Get gallery profile
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final galleryProfile =
          await _subscriptionService.getArtistProfileByUserId(userId);
      if (galleryProfile == null ||
          galleryProfile.userType != core.UserType.gallery) {
        setState(() {
          _errorMessage = 'No gallery profile found. Please create one first.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isPremiumGallery = true;
      });

      // Load analytics data
      await _loadAnalyticsData(galleryProfile.id);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading gallery data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Load analytics data based on selected time range and metric
  Future<void> _loadAnalyticsData(String galleryProfileId) async {
    try {
      // Get date range for filtering data
      final now = DateTime.now();
      DateTime startDate;
      switch (_selectedTimeRange) {
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'quarter':
          startDate = DateTime(now.year, now.month - 3, now.day);
          break;
        case 'year':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        default:
          startDate = DateTime(now.year, now.month - 1, now.day);
      }

      // Get gallery analytics overview
      final galleryAnalytics = await _analyticsService.getGalleryAnalytics(
        galleryProfileId: galleryProfileId,
        startDate: startDate,
        endDate: now,
      );

      // Get artist performance data
      final artistPerformance =
          await _analyticsService.getArtistPerformanceAnalytics(
        galleryProfileId: galleryProfileId,
        startDate: startDate,
        endDate: now,
      );

      // Get commission metrics
      final commissionMetrics = await _analyticsService.getCommissionMetrics(
        galleryProfileId: galleryProfileId,
        startDate: startDate,
        endDate: now,
      );

      // Get revenue data for chart
      final revenueData = await _analyticsService.getRevenueTimelineData(
        galleryProfileId: galleryProfileId,
        startDate: startDate,
        endDate: now,
        groupBy: _selectedTimeRange == 'week' || _selectedTimeRange == 'month'
            ? 'day'
            : 'month',
      );

      setState(() {
        _galleryAnalytics = galleryAnalytics;
        _artistPerformance = artistPerformance;
        _commissionMetrics = commissionMetrics;
        _revenueData = revenueData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading analytics data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Build a metric card for displaying analytics numbers
  Widget _buildMetricCard(
      String title, dynamic value, String subtitle, IconData icon) {
    String displayValue;

    if (value is double) {
      if (title.contains('Revenue') || title.contains('Sales')) {
        displayValue = '\$${value.toStringAsFixed(2)}';
      } else {
        displayValue = value.toStringAsFixed(1);
      }
    } else if (value is int) {
      displayValue = NumberFormat('#,###').format(value);
    } else {
      displayValue = value.toString();
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              displayValue,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the revenue chart
  Widget _buildRevenueChart() {
    if (_revenueData.isEmpty) {
      return Center(
        child: Text(
            'artist_gallery_analytics_dashboard_text_no_revenue_data'.tr()),
      );
    }

    // Extract chart data
    final List<FlSpot> spots = [];
    double maxY = 0;

    for (int i = 0; i < _revenueData.length; i++) {
      final entry = _revenueData[i];
      final value = entry['revenue'] as double;
      spots.add(FlSpot(i.toDouble(), value));
      if (value > maxY) maxY = value;
    }

    // We'll use a simpler approach without custom labels for now

    return SizedBox(
      height: 300,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: const FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: false,
            ),
            minX: 0,
            maxX: (_revenueData.length - 1).toDouble(),
            minY: 0,
            maxY: maxY * 1.2,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Theme.of(context).primaryColor,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build table of top performing artists
  Widget _buildArtistPerformanceTable() {
    if (_artistPerformance.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
              'artist_gallery_analytics_dashboard_text_no_artist_performance'
                  .tr()),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
              label:
                  Text('artist_gallery_analytics_dashboard_text_artist'.tr())),
          DataColumn(
              label: Text(
                  'artist_gallery_analytics_dashboard_text_artwork_views'
                      .tr())),
          DataColumn(
              label:
                  Text('artist_gallery_analytics_dashboard_text_sales'.tr())),
          DataColumn(
              label:
                  Text('artist_gallery_analytics_dashboard_text_revenue'.tr())),
          DataColumn(
              label: Text(
                  'artist_gallery_analytics_dashboard_text_commission'.tr())),
        ],
        rows: _artistPerformance
            .map((artist) => DataRow(cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: artist['profileImageUrl'] != null
                              ? NetworkImage(
                                  artist['profileImageUrl'] as String)
                              : null,
                          child: artist['profileImageUrl'] == null
                              ? const Icon(Icons.person, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(artist['displayName'] as String? ??
                            'Unknown Artist'),
                      ],
                    ),
                  ),
                  DataCell(Text(NumberFormat('#,###')
                      .format(artist['artworkViews'] ?? 0))),
                  DataCell(
                      Text(NumberFormat('#,###').format(artist['sales'] ?? 0))),
                  DataCell(Text(
                      '\$${(artist['revenue'] as double).toStringAsFixed(2)}')),
                  DataCell(Text(
                      '\$${(artist['commission'] as double).toStringAsFixed(2)}')),
                ]))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
            title: Text(
                'artist_gallery_analytics_dashboard_text_gallery_analytics'
                    .tr())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show upgrade prompt for non-premium users
    if (!_isPremiumGallery) {
      return Scaffold(
        appBar: AppBar(
            title: Text(
                'artist_gallery_analytics_dashboard_text_gallery_analytics'
                    .tr())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.analytics,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Gallery Analytics Dashboard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ??
                      'This feature is available with the Gallery Plan.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/artist/subscription');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                      'artist_gallery_analytics_dashboard_text_upgrade_to_gallery'
                          .tr()),
                ),
              ],
            ),
          ),
        ),
      ); // End of Scaffold
    } // End of if (!_isPremiumGallery)

    // Format the gallery profile data for display
    final totalViews = _galleryAnalytics['totalViews'] ?? 0;
    final totalSales = _galleryAnalytics['totalSales'] ?? 0;
    final totalRevenue = _galleryAnalytics['totalRevenue'] ?? 0.0;
    final totalCommission = _galleryAnalytics['totalCommission'] ?? 0.0;
    final viewsToSalesRate = _galleryAnalytics['viewsToSalesRate'] ?? 0.0;

    // Commission metrics
    final avgCommissionRate = _commissionMetrics['avgCommissionRate'] ?? 0.0;
    final totalPendingCommission =
        _commissionMetrics['pendingCommission'] ?? 0.0;
    final totalPaidCommission = _commissionMetrics['paidCommission'] ?? 0.0;

    // FIX: Add missing return for premium gallery analytics UI
    return core.MainLayout(
      currentIndex: -1, // Gallery analytics doesn't use bottom navigation
      appBar: core.EnhancedUniversalHeader(
        title: 'Gallery Analytics',
        showBackButton: true,
        showSearch: false,
        showDeveloperTools: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Select Time Range',
            onSelected: (value) {
              setState(() {
                _selectedTimeRange = value;
                _isLoading = true;
              });
              // Reload data with new time range
              final userId = _auth.currentUser?.uid;
              if (userId != null) {
                _subscriptionService
                    .getArtistProfileByUserId(userId)
                    .then((profile) {
                  if (profile != null) {
                    _loadAnalyticsData(profile.id);
                  }
                });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'week',
                child: Text(
                    'artist_gallery_analytics_dashboard_text_last_7_days'.tr()),
              ),
              PopupMenuItem(
                value: 'month',
                child: Text(
                    'artist_gallery_analytics_dashboard_text_last_30_days'
                        .tr()),
              ),
              PopupMenuItem(
                value: 'quarter',
                child: Text(
                    'artist_gallery_analytics_dashboard_text_last_90_days'
                        .tr()),
              ),
              PopupMenuItem(
                value: 'year',
                child: Text(
                    'artist_gallery_analytics_dashboard_text_last_12_months'
                        .tr()),
              ),
            ],
          ),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _checkSubscriptionAndLoadData,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time range indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Showing data for: ${_selectedTimeRange == 'week' ? 'Last 7 Days' : _selectedTimeRange == 'month' ? 'Last 30 Days' : _selectedTimeRange == 'quarter' ? 'Last 90 Days' : 'Last 12 Months'}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Overview metrics
                const Text('art_walk_performance_overview'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.5,
                  children: [
                    _buildMetricCard('Total Views', totalViews,
                        'Artwork views in period', Icons.visibility),
                    _buildMetricCard('Total Sales', totalSales,
                        'Artworks sold in period', Icons.shopping_cart),
                    _buildMetricCard('Total Revenue', totalRevenue,
                        'Sales revenue in period', Icons.attach_money),
                    _buildMetricCard('Commission Earned', totalCommission,
                        'Total gallery commission', Icons.monetization_on),
                    _buildMetricCard('Conversion Rate', viewsToSalesRate,
                        'Views to sales percentage', Icons.trending_up),
                    _buildMetricCard('Avg. Commission', avgCommissionRate,
                        'Average commission rate', Icons.percent),
                  ],
                ),

                const SizedBox(height: 32),

                // Revenue chart
                const Text('art_walk_revenue_trend'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  child: _buildRevenueChart(),
                ),

                const SizedBox(height: 32),

                // Artist performance
                const Text('art_walk_artist_performance'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildArtistPerformanceTable(),
                  ),
                ),

                const SizedBox(height: 32),

                // Commission summary
                const Text('art_walk_commission_summary'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                              'artist_gallery_analytics_dashboard_text_pending_commissions'
                                  .tr()),
                          trailing: Text(
                            '\$${totalPendingCommission.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          title: Text(
                              'artist_gallery_analytics_dashboard_text_paid_commissions'
                                  .tr()),
                          trailing: Text(
                            '\$${totalPaidCommission.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          title: Text(
                              'artist_gallery_analytics_dashboard_text_total_commissions'
                                  .tr()),
                          trailing: Text(
                            '\$${(totalPendingCommission + totalPaidCommission).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Export report button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('art_walk_generating_report_pdf__check_your_downloads_folder'.tr()),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: Text(
                        'artist_gallery_analytics_dashboard_text_export_report'
                            .tr()),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
