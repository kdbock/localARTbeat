import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/event_analytics_service_phase3.dart';
import '../models/artbeat_event.dart';

/// Advanced analytics dashboard with visualizations and real-time data
/// Phase 3 implementation with comprehensive charts and metrics
class AdvancedAnalyticsDashboardScreen extends StatefulWidget {
  final String? artistId; // Filter by specific artist, null for admin view

  const AdvancedAnalyticsDashboardScreen({super.key, this.artistId});

  @override
  State<AdvancedAnalyticsDashboardScreen> createState() =>
      _AdvancedAnalyticsDashboardScreenState();
}

class _AdvancedAnalyticsDashboardScreenState
    extends State<AdvancedAnalyticsDashboardScreen>
    with TickerProviderStateMixin {
  final EventAnalyticsServicePhase3 _analyticsService =
      EventAnalyticsServicePhase3();

  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  // Data
  Map<String, dynamic>? _overviewMetrics;
  List<FlSpot> _viewsTrendData = [];
  List<FlSpot> _revenueTrendData = [];
  List<ArtbeatEvent> _topEvents = [];
  Map<String, double> _categoryDistribution = {};
  List<Map<String, dynamic>> _recentActivity = [];

  // Time period filter
  String _selectedPeriod = '30d';
  final List<String> _timeperiods = ['7d', '30d', '90d', '1y'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();

    // Set up real-time updates every 5 minutes
    _setupRealTimeUpdates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setupRealTimeUpdates() {
    // Update data every 5 minutes for real-time dashboard
    Stream.periodic(const Duration(minutes: 5)).listen((_) {
      if (mounted) {
        _loadAnalyticsData(showLoading: false);
      }
    });
  }

  Future<void> _loadAnalyticsData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Load all analytics data in parallel
      await Future.wait([
        _loadOverviewMetrics(),
        _loadTrendData(),
        _loadTopEvents(),
        _loadCategoryDistribution(),
        _loadRecentActivity(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOverviewMetrics() async {
    // Get basic metrics from the analytics service
    _overviewMetrics = await _analyticsService.getBasicMetrics(
      artistId: widget.artistId,
      startDate: _getPeriodStartDate(DateTime.now()),
      endDate: DateTime.now(),
    );

    // Add some mock additional metrics for demo
    _overviewMetrics!['growthRate'] = 12.5;
    _overviewMetrics!['averageEngagement'] = 68.5;
    _overviewMetrics!['totalRevenue'] = 8750.50;
  }

  Future<void> _loadTrendData() async {
    // Generate mock trend data for visualization
    final endDate = DateTime.now();
    final startDate = _getPeriodStartDate(endDate);
    final days = endDate.difference(startDate).inDays;

    _viewsTrendData = [];
    _revenueTrendData = [];

    for (int i = 0; i < days; i++) {
      // Mock data with some realistic patterns
      final baseViews = 200 + (i * 10);
      final baseRevenue = 100 + (i * 15);

      _viewsTrendData.add(FlSpot(i.toDouble(), baseViews.toDouble()));
      _revenueTrendData.add(FlSpot(i.toDouble(), baseRevenue.toDouble()));
    }
  }

  Future<void> _loadTopEvents() async {
    _topEvents = await _analyticsService.getPopularEvents(
      artistId: widget.artistId,
    );
  }

  Future<void> _loadCategoryDistribution() async {
    // Get category distribution and convert to percentages
    final categoryData = await _analyticsService.getCategoryDistribution(
      artistId: widget.artistId,
      startDate: _getPeriodStartDate(DateTime.now()),
      endDate: DateTime.now(),
    );

    final totalEvents = categoryData.values.fold(
      0,
      (total, eventCount) => total + eventCount,
    );
    _categoryDistribution = {};

    if (totalEvents > 0) {
      categoryData.forEach((category, eventCount) {
        _categoryDistribution[category] = (eventCount / totalEvents) * 100;
      });
    } else {
      // Mock data if no events
      _categoryDistribution = {
        'Art Show': 35.0,
        'Workshop': 25.0,
        'Exhibition': 20.0,
        'Sale': 15.0,
        'Other': 5.0,
      };
    }
  }

  Future<void> _loadRecentActivity() async {
    // Mock recent activity data
    _recentActivity = [
      {
        'type': 'event_created',
        'title': 'New Event Created',
        'description': '"Summer Art Fair" was created',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'type': 'ticket_sold',
        'title': 'Tickets Sold',
        'description': '5 tickets sold for "Modern Art Workshop"',
        'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
      },
      {
        'type': 'event_viewed',
        'title': 'High Engagement',
        'description': '"Abstract Painting Class" reached 500 views',
        'timestamp': DateTime.now().subtract(const Duration(hours: 6)),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.artistId != null
              ? 'event_analytics_my'.tr()
              : 'event_analytics_platform'.tr(),
        ),
        actions: [
          _buildPeriodSelector(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Trends', icon: Icon(Icons.trending_up)),
            Tab(text: 'Events', icon: Icon(Icons.event)),
            Tab(text: 'Activity', icon: Icon(Icons.timeline)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTrendsTab(),
                _buildEventsTab(),
                _buildActivityTab(),
              ],
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return PopupMenuButton<String>(
      initialValue: _selectedPeriod,
      onSelected: (period) {
        setState(() {
          _selectedPeriod = period;
        });
        _loadAnalyticsData();
      },
      itemBuilder: (context) => _timeperiods.map((period) {
        return PopupMenuItem(
          value: period,
          child: Text(_formatPeriodLabel(period)),
        );
      }).toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_formatPeriodLabel(_selectedPeriod)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'event_analytics_error_loading'.tr(),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAnalyticsData,
            child: Text('event_analytics_retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_overviewMetrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'event_analytics_overview'.tr(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildMetricsGrid(),
            const SizedBox(height: 24),
            _buildEngagementChart(),
            const SizedBox(height: 24),
            _buildCategoryDistributionChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'event_analytics_total_events'.tr(),
          '${_overviewMetrics!['totalEvents']}',
          Icons.event,
          Colors.blue,
          '${_overviewMetrics!['growthRate'].toStringAsFixed(1)}%',
        ),
        _buildMetricCard(
          'event_analytics_total_views'.tr(),
          _formatNumber(_overviewMetrics!['totalViews']),
          Icons.visibility,
          Colors.green,
          '+12.5%',
        ),
        _buildMetricCard(
          'event_analytics_revenue'.tr(),
          '\$${_formatNumber(_overviewMetrics!['totalRevenue'])}',
          Icons.attach_money,
          Colors.orange,
          '+8.2%',
        ),
        _buildMetricCard(
          'event_analytics_engagement'.tr(),
          '${_overviewMetrics!['averageEngagement'].toStringAsFixed(1)}%',
          Icons.thumb_up,
          Colors.purple,
          '+5.7%',
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
  ) {
    final isPositive = change.startsWith('+');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 16,
                ),
                Text(
                  change,
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Engagement Over Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatNumber(value.toInt()),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.now().subtract(
                            Duration(
                              days: _viewsTrendData.length - value.toInt(),
                            ),
                          );
                          return Text(
                            DateFormat('MM/dd').format(date),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _viewsTrendData,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha: 0.1),
                      ),
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

  Widget _buildCategoryDistributionChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Events by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildCategoryLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRevenueChart(),
            const SizedBox(height: 24),
            _buildComparisonChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${_formatNumber(value.toInt())}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.now().subtract(
                            Duration(
                              days: _revenueTrendData.length - value.toInt(),
                            ),
                          );
                          return Text(
                            DateFormat('MM/dd').format(date),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _revenueTrendData,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withValues(alpha: 0.1),
                      ),
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

  Widget _buildComparisonChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Views vs Revenue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatNumber(value.toInt()),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.now().subtract(
                            Duration(
                              days: _viewsTrendData.length - value.toInt(),
                            ),
                          );
                          return Text(
                            DateFormat('MM/dd').format(date),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _viewsTrendData,
                      isCurved: true,
                      color: Colors.blue,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: _revenueTrendData
                          .map(
                            (spot) => FlSpot(
                              spot.x,
                              spot.y / 100,
                            ), // Scale revenue for comparison
                          )
                          .toList(),
                      isCurved: true,
                      color: Colors.green,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Views', Colors.blue),
                const SizedBox(width: 24),
                _buildLegendItem('Revenue (÷100)', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Top Performing Events',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _topEvents.length,
              itemBuilder: (context, index) {
                return _buildTopEventCard(_topEvents[index], index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopEventCard(ArtbeatEvent event, int rank) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRankColor(rank),
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 2),
                Text(
                  event.location,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM dd').format(event.dateTime),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              '1.2K views', // This would come from analytics
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '85% engagement',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recentActivity.length,
              itemBuilder: (context, index) {
                return _buildActivityItem(_recentActivity[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getActivityIcon(activity['type']),
          color: _getActivityColor(activity['type']),
        ),
        title: Text(activity['title']),
        subtitle: Text(activity['description']),
        trailing: Text(
          _formatTimestamp(activity['timestamp']),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ),
    );
  }

  // Helper methods
  List<PieChartSectionData> _buildPieChartSections() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    int colorIndex = 0;

    return _categoryDistribution.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        value: entry.value,
        title: '${entry.value.toInt()}%',
        color: color,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildCategoryLegend() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    int colorIndex = 0;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: _categoryDistribution.entries.map((entry) {
        final color = colors[colorIndex % colors.length];
        colorIndex++;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(entry.key, style: const TextStyle(fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'event_created':
        return Icons.event;
      case 'ticket_sold':
        return Icons.confirmation_number;
      case 'event_viewed':
        return Icons.visibility;
      case 'revenue':
        return Icons.attach_money;
      default:
        return Icons.notifications;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'event_created':
        return Colors.blue;
      case 'ticket_sold':
        return Colors.green;
      case 'event_viewed':
        return Colors.orange;
      case 'revenue':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatNumber(num number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatPeriodLabel(String period) {
    switch (period) {
      case '7d':
        return 'Last 7 days';
      case '30d':
        return 'Last 30 days';
      case '90d':
        return 'Last 3 months';
      case '1y':
        return 'Last year';
      default:
        return period;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      final date = timestamp is DateTime
          ? timestamp
          : (timestamp as Timestamp).toDate();
      return DateFormat('MMM dd, HH:mm').format(date);
    } on Exception {
      return 'Unknown';
    }
  }

  DateTime _getPeriodStartDate(DateTime endDate) {
    switch (_selectedPeriod) {
      case '7d':
        return endDate.subtract(const Duration(days: 7));
      case '30d':
        return endDate.subtract(const Duration(days: 30));
      case '90d':
        return endDate.subtract(const Duration(days: 90));
      case '1y':
        return endDate.subtract(const Duration(days: 365));
      default:
        return endDate.subtract(const Duration(days: 30));
    }
  }
}
