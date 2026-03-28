import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../services/payment_analytics_service.dart';
import '../models/payment_models.dart';

/// Analytics dashboard for payment system monitoring and insights
class PaymentAnalyticsDashboard extends StatefulWidget {
  const PaymentAnalyticsDashboard({super.key});

  @override
  State<PaymentAnalyticsDashboard> createState() =>
      _PaymentAnalyticsDashboardState();
}

class _PaymentAnalyticsDashboardState extends State<PaymentAnalyticsDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late PaymentAnalyticsService _analyticsService;
  final List<AnalyticsReport> _reports = [];
  bool _isLoadingReports = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _analyticsService = context.read<PaymentAnalyticsService>();
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('payment_analytics_title'.tr()),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'payment_analytics_tab_overview'.tr(),
              icon: const Icon(Icons.dashboard),
            ),
            Tab(
              text: 'payment_analytics_tab_risk_analysis'.tr(),
              icon: const Icon(Icons.security),
            ),
            Tab(
              text: 'payment_analytics_tab_performance'.tr(),
              icon: const Icon(Icons.trending_up),
            ),
            Tab(
              text: 'payment_analytics_tab_reports'.tr(),
              icon: const Icon(Icons.analytics),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildRiskAnalysisTab(),
          _buildPerformanceTab(),
          _buildReportsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return StreamBuilder<PaymentMetrics>(
      stream: _analyticsService.getPaymentMetricsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'payment_analytics_error_generic'.tr(
                namedArgs: {'error': '${snapshot.error}'},
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final metrics = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetricsGrid(metrics),
              const SizedBox(height: 24),
              _buildRecentActivity(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricsGrid(PaymentMetrics metrics) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMetricCard(
          'payment_analytics_metric_total_transactions'.tr(),
          metrics.totalTransactions.toString(),
          Icons.payment,
          Colors.blue,
        ),
        _buildMetricCard(
          'payment_analytics_metric_success_rate'.tr(),
          '${(metrics.successRate * 100).toStringAsFixed(1)}%',
          Icons.check_circle,
          Colors.green,
        ),
        _buildMetricCard(
          'payment_analytics_metric_total_revenue'.tr(),
          '\$${metrics.totalRevenue.toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.purple,
        ),
        _buildMetricCard(
          'payment_analytics_metric_avg_transaction'.tr(),
          '\$${metrics.averageTransactionValue.toStringAsFixed(2)}',
          Icons.trending_up,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return FutureBuilder<List<PaymentEvent>>(
      future: _analyticsService.getRecentPaymentEvents(limit: 10),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'payment_analytics_recent_activity'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return ListTile(
                  leading: Icon(
                    event.status == 'completed'
                        ? Icons.check_circle
                        : Icons.error,
                    color: event.status == 'completed'
                        ? Colors.green
                        : Colors.red,
                  ),
                  title: Text('\$${event.amount.toStringAsFixed(2)}'),
                  subtitle: Text(event.timestamp.toString()),
                  trailing: Text(
                    event.paymentMethod ?? 'payment_analytics_unknown'.tr(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRiskAnalysisTab() {
    return FutureBuilder<List<RiskTrend>>(
      future: _analyticsService.getRiskTrends(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final trends = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trends.length,
          itemBuilder: (context, index) {
            final trend = trends[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  _getRiskIcon(trend.riskLevel),
                  color: _getRiskColor(trend.riskLevel),
                ),
                title: Text(trend.category),
                subtitle: Text(
                  'payment_analytics_risk_score'.tr(
                    namedArgs: {'score': trend.riskScore.toStringAsFixed(2)},
                  ),
                ),
                trailing: Text('${trend.trend}%'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPerformanceTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _analyticsService.getPerformanceMetrics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final performance = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPerformanceMetric(
              'payment_analytics_metric_conversion_rate'.tr(),
              '${(performance['conversionRate'] * 100).toStringAsFixed(2)}%',
              Icons.trending_up,
            ),
            _buildPerformanceMetric(
              'payment_analytics_metric_average_processing_time'.tr(),
              '${performance['avgProcessingTime']}ms',
              Icons.timer,
            ),
            _buildPerformanceMetric(
              'payment_analytics_metric_failure_rate'.tr(),
              '${(performance['failureRate'] * 100).toStringAsFixed(2)}%',
              Icons.error,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPerformanceMetric(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          onPressed: () => _generateReport('daily'),
          icon: const Icon(Icons.calendar_today),
          label: Text('payment_analytics_generate_daily_report'.tr()),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _generateReport('weekly'),
          icon: const Icon(Icons.calendar_view_week),
          label: Text('payment_analytics_generate_weekly_report'.tr()),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _generateReport('monthly'),
          icon: const Icon(Icons.calendar_month),
          label: Text('payment_analytics_generate_monthly_report'.tr()),
        ),
        const SizedBox(height: 24),
        Text(
          'payment_analytics_report_history'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // Report history list
        _isLoadingReports
            ? const Center(child: CircularProgressIndicator())
            : _reports.isEmpty
            ? Center(
                child: Text('payment_analytics_no_reports_generated_yet'.tr()),
              )
            : _buildReportHistoryList(),
      ],
    );
  }

  Widget _buildReportHistoryList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.description),
            title: Text(report.title),
            subtitle: Text(
              '${'payment_analytics_generated'.tr(namedArgs: {'timestamp': report.generatedAt.toString().split('.')[0]})}\n'
              '${'payment_analytics_period'.tr(namedArgs: {'period': _periodLabel(report.period)})}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadReport(report),
            ),
            onTap: () => _viewReport(report),
          ),
        );
      },
    );
  }

  void _generateReport(String period) async {
    try {
      // Generate report data based on period
      final reportData = await _generateReportData(period);

      // Create report metadata
      final report = AnalyticsReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'payment_analytics_report_title'.tr(
          namedArgs: {'period': _periodLabel(period)},
        ),
        period: period,
        generatedAt: DateTime.now(),
        generatedBy: 'payment_analytics_generated_by_system'.tr(),
        data: reportData,
      );

      // Save report (in a real app, this would save to Firestore or cloud storage)
      await _saveReport(report);

      // Reload reports to show the new one
      await _loadReports();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'payment_analytics_generate_success'.tr(
                namedArgs: {'period': _periodLabel(period)},
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'payment_analytics_generate_error'.tr(
                namedArgs: {'period': _periodLabel(period), 'error': '$e'},
              ),
            ),
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _generateReportData(String period) async {
    // Generate different data based on period
    switch (period.toLowerCase()) {
      case 'daily':
        final metrics = await _analyticsService.getPaymentMetrics(
          DateRange.last7Days(),
        );
        return {
          'type': 'daily',
          'metrics': metrics.toJson(),
          'generatedAt': DateTime.now().toIso8601String(),
        };
      case 'weekly':
        final metrics = await _analyticsService.getPaymentMetrics(
          DateRange.last7Days(),
        );
        final trends = await _analyticsService.getRiskTrends(days: 7);
        return {
          'type': 'weekly',
          'metrics': metrics.toJson(),
          'trends': trends.map((t) => t.toJson()).toList(),
          'generatedAt': DateTime.now().toIso8601String(),
        };
      case 'monthly':
        final metrics = await _analyticsService.getPaymentMetrics(
          DateRange.last30Days(),
        );
        final trends = await _analyticsService.getRiskTrends(days: 30);
        final conversionRates = await _analyticsService.getConversionRates();
        return {
          'type': 'monthly',
          'metrics': metrics.toJson(),
          'trends': trends.map((t) => t.toJson()).toList(),
          'conversionRates': conversionRates,
          'generatedAt': DateTime.now().toIso8601String(),
        };
      default:
        return {
          'type': 'unknown',
          'generatedAt': DateTime.now().toIso8601String(),
        };
    }
  }

  Future<void> _saveReport(AnalyticsReport report) async {
    // In a real implementation, this would save to Firestore
    // For now, we'll store in memory (in production, use persistent storage)
    _reports.insert(0, report); // Add to beginning of list
  }

  Future<void> _loadReports() async {
    setState(() => _isLoadingReports = true);
    try {
      // In a real implementation, this would load from Firestore
      // For now, just use the in-memory reports
      // Simulate loading delay
      await Future<void>.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) {
        setState(() => _isLoadingReports = false);
      }
    }
  }

  void _downloadReport(AnalyticsReport report) {
    // In a real implementation, this would download the report file
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'payment_analytics_downloading'.tr(
            namedArgs: {'title': report.title},
          ),
        ),
      ),
    );
  }

  void _viewReport(AnalyticsReport report) {
    // In a real implementation, this would open a detailed report view
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'payment_analytics_period'.tr(
                namedArgs: {'period': _periodLabel(report.period)},
              ),
            ),
            Text(
              'payment_analytics_generated'.tr(
                namedArgs: {
                  'timestamp': report.generatedAt.toString().split('.')[0],
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'payment_analytics_report_contains'.tr(
                namedArgs: {'count': '${report.data.length}'},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common_close'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _downloadReport(report);
            },
            child: Text('commission_detail_file_download'.tr()),
          ),
        ],
      ),
    );
  }

  String _periodLabel(String period) {
    switch (period.toLowerCase()) {
      case 'daily':
        return 'payment_analytics_period_daily'.tr();
      case 'weekly':
        return 'payment_analytics_period_weekly'.tr();
      case 'monthly':
        return 'payment_analytics_period_monthly'.tr();
      default:
        return period;
    }
  }

  IconData _getRiskIcon(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return Icons.check_circle;
      case 'medium':
        return Icons.warning;
      case 'high':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
