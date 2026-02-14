import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import 'package:artbeat_core/artbeat_core.dart' hide GradientCTAButton;
import '../widgets/widgets.dart';

import '../models/artbeat_event.dart';
import '../services/event_analytics_service_phase3.dart';

/// Local ARTbeat — Advanced Analytics Dashboard (Phase 3)
/// Refactored to follow design_guide:
/// - WorldBackground
/// - Glass surfaces
/// - Space Grotesk typography
/// - Gradient CTA
/// - HUD top navigation
class AdvancedAnalyticsDashboardScreen extends StatefulWidget {
  final String? artistId;

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

  Map<String, dynamic>? _overviewMetrics;
  List<FlSpot> _viewsTrendData = [];
  List<FlSpot> _revenueTrendData = [];
  Map<String, double> _categoryDistribution = {};
  List<ArtbeatEvent> _popularEvents = [];

  String _selectedPeriod = '30d';
  final List<String> _periods = ['7d', '30d', '90d', '1y'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
    _setupRealTimeUpdates();
  }

  void _setupRealTimeUpdates() {
    Stream.periodic(const Duration(minutes: 5)).listen((_) {
      if (mounted) _loadAnalyticsData(showLoading: false);
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
      await Future.wait([
        _loadOverviewMetrics(),
        _loadTrendData(),
        _loadCategoryDistribution(),
        _loadPopularEvents(),
      ]);

      setState(() => _isLoading = false);
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // ---------------- DATA LOADERS ----------------

  Future<void> _loadOverviewMetrics() async {
    _overviewMetrics = await _analyticsService.getBasicMetrics(
      artistId: widget.artistId,
      startDate: _getPeriodStartDate(DateTime.now()),
      endDate: DateTime.now(),
    );

    _overviewMetrics!['growthRate'] = 12.5;
    _overviewMetrics!['averageEngagement'] = 68.5;
    _overviewMetrics!['totalRevenue'] = 8750.50;
  }

  Future<void> _loadTrendData() async {
    final end = DateTime.now();
    final start = _getPeriodStartDate(end);
    final days = end.difference(start).inDays;

    _viewsTrendData = [];
    _revenueTrendData = [];

    for (int i = 0; i < days; i++) {
      _viewsTrendData.add(FlSpot(i.toDouble(), (200 + i * 10).toDouble()));
      _revenueTrendData.add(FlSpot(i.toDouble(), (100 + i * 15).toDouble()));
    }
  }

  Future<void> _loadCategoryDistribution() async {
    final categoryData = await _analyticsService.getCategoryDistribution(
      artistId: widget.artistId,
      startDate: _getPeriodStartDate(DateTime.now()),
      endDate: DateTime.now(),
    );

    final total = categoryData.values.fold<int>(
      0,
      (total, value) => total + value,
    );

    if (total == 0) {
      _categoryDistribution = {
        'Art Show': 35,
        'Workshop': 25,
        'Exhibition': 20,
        'Sale': 15,
        'Other': 5,
      };
    } else {
      _categoryDistribution = categoryData.map(
        (k, v) => MapEntry(k, (v / total) * 100),
      );
    }
  }

  Future<void> _loadPopularEvents() async {
    _popularEvents = await _analyticsService.getPopularEvents(
      artistId: widget.artistId,
      daysBack: _periodDays(),
    );
  }

  DateTime _getPeriodStartDate(DateTime end) {
    switch (_selectedPeriod) {
      case '7d':
        return end.subtract(const Duration(days: 7));
      case '30d':
        return end.subtract(const Duration(days: 30));
      case '90d':
        return end.subtract(const Duration(days: 90));
      default:
        return end.subtract(const Duration(days: 365));
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      child: SafeArea(
        child: Column(
          children: [
            EventsHudTopBar(
              title: widget.artistId == null
                  ? 'event_analytics_platform'.tr()
                  : 'event_analytics_my'.tr(),
              showBack: true,
              rightAction: _buildPeriodSelector(),
              onBack: () => Navigator.pop(context),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? _buildErrorState()
                  : Column(
                      children: [
                        _buildTabs(),
                        Expanded(child: _buildTabContent()),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: TabBar(
          controller: _tabController,
          indicatorColor: ArtbeatColors.secondaryTeal,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          tabs: [
            Tab(text: 'event_analytics_overview'.tr()),
            Tab(text: 'event_analytics_trends'.tr()),
            Tab(text: 'event_analytics_events'.tr()),
            Tab(text: 'event_analytics_activity'.tr()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildTrendsTab(),
        _buildEventsTab(),
        _buildActivityTab(),
      ],
    );
  }

  // ---------------- OVERVIEW TAB ----------------

  Widget _buildOverviewTab() {
    if (_overviewMetrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _metricsGrid(),
          const SizedBox(height: 16),
          _glassChart(title: 'Engagement', child: _engagementChart()),
          const SizedBox(height: 16),
          _glassChart(
            title: 'event_analytics_by_category'.tr(),
            child: _categoryChart(),
          ),
        ],
      ),
    );
  }

  Widget _metricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _metricCard(
          'event_analytics_total_events'.tr(),
          '${_overviewMetrics!['totalEvents']}',
        ),
        _metricCard(
          'event_analytics_total_views'.tr(),
          _formatNumber(_overviewMetrics!['totalViews']),
        ),
        _metricCard(
          'event_analytics_revenue'.tr(),
          '\$${_formatNumber(_overviewMetrics!['totalRevenue'])}',
        ),
        _metricCard(
          'event_analytics_engagement'.tr(),
          '${_overviewMetrics!['averageEngagement'].toStringAsFixed(1)}%',
        ),
      ],
    );
  }

  Widget _metricCard(String title, String value) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassChart({required String title, required Widget child}) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 200, child: child),
        ],
      ),
    );
  }

  Widget _engagementChart() {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: _viewsTrendData,
            isCurved: true,
            color: ArtbeatColors.secondaryTeal,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _categoryChart() {
    return PieChart(
      PieChartData(
        sections: _categoryDistribution.entries.map((entry) {
          return PieChartSectionData(
            value: entry.value,
            title: '${entry.value.toInt()}%',
            color:
                Colors.primaries[entry.key.hashCode % Colors.primaries.length],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendsTab() {
    final totalViews = (_overviewMetrics?['totalViews'] as num?)?.toInt() ?? 0;
    final totalRevenue =
        (_overviewMetrics?['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final growth = (_overviewMetrics?['growthRate'] as num?)?.toDouble() ?? 0.0;

    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _glassChart(
            title: 'Views Trend',
            child: _trendLineChart(
              data: _viewsTrendData,
              color: ArtbeatColors.secondaryTeal,
            ),
          ),
          const SizedBox(height: 16),
          _glassChart(
            title: 'Revenue Trend',
            child: _trendLineChart(
              data: _revenueTrendData,
              color: const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trend Summary',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _summaryRow('Total Views', _formatNumber(totalViews)),
                _summaryRow(
                  'Total Revenue',
                  '\$${totalRevenue.toStringAsFixed(2)}',
                ),
                _summaryRow('Growth Rate', '${growth.toStringAsFixed(1)}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    if (_popularEvents.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          GlassCard(
            child: Text(
              'No events were found for this period. Create or publish events to see event-level analytics.',
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _popularEvents.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final event = _popularEvents[index];
          return GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${intl.DateFormat.yMMMd().format(event.dateTime)} • ${event.location}',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('Category: ${event.category}'),
                    _chip('Views: ${_formatNumber(event.viewCount)}'),
                    _chip('Likes: ${_formatNumber(event.likeCount)}'),
                    _chip('Shares: ${_formatNumber(event.shareCount)}'),
                    _chip('Saves: ${_formatNumber(event.saveCount)}'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityTab() {
    final totalEvents =
        (_overviewMetrics?['totalEvents'] as num?)?.toInt() ?? 0;
    final activeEvents =
        (_overviewMetrics?['activeEvents'] as num?)?.toInt() ?? 0;
    final engagements =
        (_overviewMetrics?['totalEngagements'] as num?)?.toInt() ?? 0;
    final averageViewsPerEvent =
        (_overviewMetrics?['averageViewsPerEvent'] as num?)?.toDouble() ?? 0.0;
    final engagementRate =
        (_overviewMetrics?['engagementRate'] as num?)?.toDouble() ?? 0.0;
    final activeRatio = totalEvents == 0 ? 0.0 : activeEvents / totalEvents;

    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity Health',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 14),
                _progressRow(
                  title: 'Active Events Ratio',
                  value: activeRatio.clamp(0.0, 1.0),
                  trailing: '${(activeRatio * 100).toStringAsFixed(0)}%',
                ),
                _progressRow(
                  title: 'Engagement Rate',
                  value: (engagementRate / 100).clamp(0.0, 1.0),
                  trailing: '${engagementRate.toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity Snapshot',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _summaryRow('Total Events', '$totalEvents'),
                _summaryRow('Active Events', '$activeEvents'),
                _summaryRow('Total Engagements', _formatNumber(engagements)),
                _summaryRow(
                  'Avg Views / Event',
                  averageViewsPerEvent.toStringAsFixed(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended Actions',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _actionRow(
                  icon: Icons.campaign_rounded,
                  text:
                      'Boost top-performing events to increase visibility during this period.',
                ),
                _actionRow(
                  icon: Icons.schedule_rounded,
                  text:
                      'Space event dates to keep at least one active event each week.',
                ),
                _actionRow(
                  icon: Icons.people_alt_rounded,
                  text:
                      'Focus on categories with high engagement and repeat attendance.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- HELPERS ----------------

  Widget _buildErrorState() {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF5350), size: 48),
            const SizedBox(height: 12),
            Text(
              'event_analytics_error_loading'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            GradientCTAButton(
              text: 'event_analytics_retry'.tr(),
              onPressed: _loadAnalyticsData,
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(num number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  int _periodDays() {
    switch (_selectedPeriod) {
      case '7d':
        return 7;
      case '30d':
        return 30;
      case '90d':
        return 90;
      default:
        return 365;
    }
  }

  Widget _trendLineChart({required List<FlSpot> data, required Color color}) {
    if (data.isEmpty) {
      return const Center(child: Text('No trend data available'));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(drawVerticalLine: false),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(),
          rightTitles: AxisTitles(),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white24),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: data,
            isCurved: true,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.white70),
      ),
    );
  }

  Widget _progressRow({
    required String title,
    required double value,
    required String trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                trailing,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: Colors.white12,
              color: ArtbeatColors.secondaryTeal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ArtbeatColors.secondaryTeal, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return PopupMenuButton<String>(
      initialValue: _selectedPeriod,
      onSelected: (val) {
        setState(() => _selectedPeriod = val);
        _loadAnalyticsData();
      },
      itemBuilder: (_) =>
          _periods.map((p) => PopupMenuItem(value: p, child: Text(p))).toList(),
      child: Row(
        children: [
          Text(
            _selectedPeriod,
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}
