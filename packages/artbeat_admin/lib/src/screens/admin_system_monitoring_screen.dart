import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'dart:math' as math;

import '../services/consolidated_admin_service.dart';
import '../widgets/admin_metrics_card.dart';
import '../widgets/admin_data_table.dart';

/// System Monitoring Dashboard for real-time performance monitoring
/// Provides comprehensive system health, performance metrics, and alerts
class AdminSystemMonitoringScreen extends StatefulWidget {
  AdminSystemMonitoringScreen({super.key});

  @override
  State<AdminSystemMonitoringScreen> createState() =>
      _AdminSystemMonitoringScreenState();
}

class _AdminSystemMonitoringScreenState
    extends State<AdminSystemMonitoringScreen> with TickerProviderStateMixin {
  final ConsolidatedAdminService _adminService = ConsolidatedAdminService();

  // Real-time monitoring
  Timer? _refreshTimer;
  bool _isLoading = true;
  bool _isRealTimeEnabled = true;

  // Tab controller
  late TabController _tabController;

  // System metrics
  Map<String, dynamic> _systemMetrics = {};
  List<Map<String, dynamic>> _performanceData = [];
  List<Map<String, dynamic>> _systemAlerts = [];
  List<Map<String, dynamic>> _activeUsers = [];
  List<Map<String, dynamic>> _serverStatus = [];

  // Chart data
  final List<double> _cpuUsageData = [];
  final List<double> _memoryUsageData = [];
  final List<double> _networkData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSystemData();
    _startRealTimeMonitoring();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startRealTimeMonitoring() {
    if (_isRealTimeEnabled) {
      _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
        if (mounted) {
          _loadSystemData();
        }
      });
    }
  }

  void _stopRealTimeMonitoring() {
    _refreshTimer?.cancel();
  }

  Future<void> _loadSystemData() async {
    try {
      // Load system metrics
      final metrics = await _adminService.getSystemMetrics();
      final performance = await _adminService.getPerformanceMetrics();
      final alerts = await _adminService.getSystemAlerts();
      final users = await _adminService.getActiveUsers();
      final servers = await _adminService.getServerStatus();

      if (mounted) {
        setState(() {
          _systemMetrics = metrics;
          _performanceData = [performance];
          _systemAlerts = alerts;
          _activeUsers = [
            {'count': users}
          ];
          _serverStatus = [servers];
          _isLoading = false;

          // Update chart data
          _updateChartData();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_admin_system_monitoring_error_error_loading_system'.tr())),
        );
      }
    }
  }

  void _updateChartData() {
    // Simulate real-time data updates
    final random = math.Random();

    // CPU Usage (0-100%)
    _cpuUsageData.add(((_systemMetrics['cpuUsage'] as num?) ?? 0.0).toDouble() +
        random.nextDouble() * 10 -
        5);
    if (_cpuUsageData.length > 50) _cpuUsageData.removeAt(0);

    // Memory Usage (0-100%)
    _memoryUsageData.add(
        ((_systemMetrics['memoryUsage'] as num?) ?? 0.0).toDouble() +
            random.nextDouble() * 8 -
            4);
    if (_memoryUsageData.length > 50) _memoryUsageData.removeAt(0);

    // Network throughput (MB/s)
    _networkData.add(
        ((_systemMetrics['networkThroughput'] as num?) ?? 0.0).toDouble() +
            random.nextDouble() * 20 -
            10);
    if (_networkData.length > 50) _networkData.removeAt(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('admin_admin_system_monitoring_text_system_monitoring'.tr()),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isRealTimeEnabled ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                _isRealTimeEnabled = !_isRealTimeEnabled;
                if (_isRealTimeEnabled) {
                  _startRealTimeMonitoring();
                } else {
                  _stopRealTimeMonitoring();
                }
              });
            },
            tooltip: _isRealTimeEnabled ? 'Pause Real-time' : 'Start Real-time',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSystemData,
            tooltip: 'Refresh Data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Performance', icon: Icon(Icons.speed)),
            Tab(text: 'Alerts', icon: Icon(Icons.warning)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildPerformanceTab(),
                _buildAlertsTab(),
                _buildUsersTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // System Status Header
          Row(
            children: [
              Icon(
                _systemMetrics['systemHealth'] == 'healthy'
                    ? Icons.check_circle
                    : Icons.error,
                color: _systemMetrics['systemHealth'] == 'healthy'
                    ? Colors.green
                    : Colors.red,
                size: 32,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Status: ${_systemMetrics['systemHealth']?.toString().toUpperCase() ?? 'UNKNOWN'}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Last updated: ${DateTime.now().toString().substring(0, 19)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isRealTimeEnabled ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isRealTimeEnabled ? Icons.circle : Icons.pause_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isRealTimeEnabled ? 'LIVE' : 'PAUSED',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Key Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              AdminMetricsCard(
                title: 'CPU Usage',
                value:
                    '${(_systemMetrics['cpuUsage'] ?? 0).toStringAsFixed(1)}%',
                icon: Icons.memory,
                color: _getCpuColor((_systemMetrics['cpuUsage'] as num?) ?? 0),
                trend: (_systemMetrics['cpuTrend'] as num?)?.toDouble(),
              ),
              AdminMetricsCard(
                title: 'Memory Usage',
                value:
                    '${(_systemMetrics['memoryUsage'] ?? 0).toStringAsFixed(1)}%',
                icon: Icons.storage,
                color: _getMemoryColor(
                    (_systemMetrics['memoryUsage'] as num?) ?? 0),
                trend: (_systemMetrics['memoryTrend'] as num?)?.toDouble(),
              ),
              AdminMetricsCard(
                title: 'Active Users',
                value: '${_systemMetrics['activeUsers'] ?? 0}',
                icon: Icons.people,
                color: Colors.blue,
                trend: (_systemMetrics['usersTrend'] as num?)?.toDouble(),
              ),
              AdminMetricsCard(
                title: 'Response Time',
                value:
                    '${(_systemMetrics['responseTime'] ?? 0).toStringAsFixed(0)}ms',
                icon: Icons.speed,
                color: _getResponseTimeColor(
                    (_systemMetrics['responseTime'] as num?) ?? 0),
                trend: (_systemMetrics['responseTrend'] as num?)?.toDouble(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Server Status
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Server Status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ..._serverStatus
                      .map((server) => _buildServerStatusItem(server)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Recent Alerts
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Alerts',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () => _tabController.animateTo(2),
                        child: Text('admin_admin_system_monitoring_text_view_all'.tr()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_systemAlerts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text('admin_admin_system_monitoring_text_no_recent_alerts'.tr()),
                      ),
                    )
                  else
                    ..._systemAlerts
                        .take(3)
                        .map((alert) => _buildAlertItem(alert)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Charts
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Real-time Performance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildPerformanceChart(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Performance Metrics Table
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Metrics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  AdminDataTable(
                    columns: const [
                      'Metric',
                      'Current',
                      'Average',
                      'Peak',
                      'Status',
                    ],
                    rows: _performanceData
                        .map((metric) => [
                              metric['name'] as String? ?? '',
                              metric['current']?.toString() ?? '',
                              metric['average']?.toString() ?? '',
                              metric['peak']?.toString() ?? '',
                              _buildStatusChip(
                                  metric['status'] as String? ?? 'unknown'),
                            ])
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert Summary
          Row(
            children: [
              Expanded(
                child: AdminMetricsCard(
                  title: 'Critical Alerts',
                  value:
                      '${_systemAlerts.where((a) => a['severity'] == 'critical').length}',
                  icon: Icons.error,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AdminMetricsCard(
                  title: 'Warning Alerts',
                  value:
                      '${_systemAlerts.where((a) => a['severity'] == 'warning').length}',
                  icon: Icons.warning,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Alerts List
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Alerts',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (_systemAlerts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text('admin_admin_system_monitoring_text_no_system_alerts'.tr()),
                      ),
                    )
                  else
                    ..._systemAlerts
                        .map((alert) => _buildDetailedAlertItem(alert)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Metrics
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              AdminMetricsCard(
                title: 'Online Users',
                value: '${_systemMetrics['onlineUsers'] ?? 0}',
                icon: Icons.circle,
                color: Colors.green,
              ),
              AdminMetricsCard(
                title: 'Peak Today',
                value: '${_systemMetrics['peakUsers'] ?? 0}',
                icon: Icons.trending_up,
                color: Colors.blue,
              ),
              AdminMetricsCard(
                title: 'Avg Session',
                value:
                    '${(_systemMetrics['avgSession'] ?? 0).toStringAsFixed(1)}m',
                icon: Icons.timer,
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Active Users Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Users',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  AdminDataTable(
                    columns: const [
                      'User',
                      'Status',
                      'Location',
                      'Session Time',
                      'Actions',
                    ],
                    rows: _activeUsers
                        .map((user) => [
                              user['name'] as String? ?? 'Unknown',
                              _buildStatusChip(
                                  user['status'] as String? ?? 'offline'),
                              user['location'] as String? ?? 'Unknown',
                              user['sessionTime'] as String? ?? '0m',
                              user['actions']?.toString() ?? '0',
                            ])
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerStatusItem(Map<String, dynamic> server) {
    final isHealthy = server['status'] == 'healthy';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isHealthy ? Icons.check_circle : Icons.error,
            color: isHealthy ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  server['name'] as String? ?? 'Unknown Server',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${server['location'] ?? 'Unknown'} • Load: ${server['load'] ?? 0}%',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${server['responseTime'] ?? 0}ms',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    final severity = alert['severity'] ?? 'info';
    Color color;
    IconData icon;

    switch (severity) {
      case 'critical':
        color = Colors.red;
        icon = Icons.error;
        break;
      case 'warning':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      default:
        color = Colors.blue;
        icon = Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['message'] as String? ?? 'Unknown alert',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  alert['timestamp'] as String? ?? 'Unknown time',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAlertItem(Map<String, dynamic> alert) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          alert['severity'] == 'critical' ? Icons.error : Icons.warning,
          color: alert['severity'] == 'critical' ? Colors.red : Colors.orange,
        ),
        title: Text(alert['message'] as String? ?? 'Unknown alert'),
        subtitle: Text(alert['details'] as String? ?? 'No details available'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              alert['timestamp'] as String? ?? 'Unknown',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            _buildStatusChip(alert['status'] as String? ?? 'active'),
          ],
        ),
        onTap: () {
          // Handle alert details
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'healthy':
      case 'online':
      case 'active':
        color = Colors.green;
        break;
      case 'warning':
        color = Colors.orange;
        break;
      case 'critical':
      case 'offline':
      case 'error':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    // Simplified chart representation
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'Performance Chart\n(Real-time data visualization)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Color _getCpuColor(num usage) {
    if (usage > 80) return Colors.red;
    if (usage > 60) return Colors.orange;
    return Colors.green;
  }

  Color _getMemoryColor(num usage) {
    if (usage > 85) return Colors.red;
    if (usage > 70) return Colors.orange;
    return Colors.green;
  }

  Color _getResponseTimeColor(num time) {
    if (time > 1000) return Colors.red;
    if (time > 500) return Colors.orange;
    return Colors.green;
  }
}
