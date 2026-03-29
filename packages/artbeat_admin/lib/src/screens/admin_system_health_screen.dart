import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:provider/provider.dart';

import '../services/consolidated_admin_service.dart';
import '../widgets/admin_metrics_card.dart';
import '../widgets/admin_data_table.dart';

/// System Health & Monitoring Dashboard
/// Provides comprehensive system health, performance metrics, remote config, and feedback
class AdminSystemHealthScreen extends StatefulWidget {
  const AdminSystemHealthScreen({super.key});

  @override
  State<AdminSystemHealthScreen> createState() =>
      _AdminSystemHealthScreenState();
}

class _AdminSystemHealthScreenState extends State<AdminSystemHealthScreen>
    with TickerProviderStateMixin {
  late ConsolidatedAdminService _adminService;
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

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

  // Remote Config
  Map<String, RemoteConfigValue> _configValues = {};

  // App Check
  final bool _appCheckEnabled = true; // Placeholder

  // Chart data
  final List<double> _cpuUsageData = [];
  final List<double> _memoryUsageData = [];
  final List<double> _networkData = [];

  @override
  void initState() {
    super.initState();
    _adminService = context.read<ConsolidatedAdminService>();
    _tabController = TabController(length: 7, vsync: this);
    _loadSystemData();
    _loadRemoteConfig();
    _startRealTimeMonitoring();
  }

  Future<void> _loadRemoteConfig() async {
    try {
      await _remoteConfig.fetchAndActivate();
      if (mounted) {
        setState(() {
          _configValues = _remoteConfig.getAll();
        });
      }
    } catch (e) {
      debugPrint('Error loading remote config: $e');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startRealTimeMonitoring() {
    if (_isRealTimeEnabled) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
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
          SnackBar(
              content: Text(
                  'admin_admin_system_monitoring_error_error_loading_system'
                      .tr())),
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
        title:
            Text('admin_admin_system_monitoring_text_system_monitoring'.tr()),
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
            tooltip: _isRealTimeEnabled
                ? 'admin_admin_system_monitoring_tooltip_pause_realtime'.tr()
                : 'admin_admin_system_monitoring_tooltip_start_realtime'.tr(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSystemData,
            tooltip: 'admin_admin_system_monitoring_tooltip_refresh_data'.tr(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: [
            Tab(
              text: 'admin_admin_system_monitoring_tab_overview'.tr(),
              icon: const Icon(Icons.dashboard),
            ),
            Tab(
              text: 'admin_admin_system_monitoring_tab_performance'.tr(),
              icon: const Icon(Icons.speed),
            ),
            Tab(
              text: 'admin_admin_system_monitoring_tab_alerts'.tr(),
              icon: const Icon(Icons.warning),
            ),
            Tab(
              text: 'admin_admin_system_monitoring_tab_users'.tr(),
              icon: const Icon(Icons.people),
            ),
            Tab(
              text: 'admin_admin_system_monitoring_tab_remote_config'.tr(),
              icon: const Icon(Icons.settings_remote),
            ),
            Tab(
              text: 'admin_admin_system_monitoring_tab_app_check'.tr(),
              icon: const Icon(Icons.verified_user),
            ),
            Tab(
              text: 'admin_admin_system_monitoring_tab_feedback'.tr(),
              icon: const Icon(Icons.feedback),
            ),
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
                _buildRemoteConfigTab(),
                _buildAppCheckTab(),
                _buildFeedbackTab(),
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
                    'admin_admin_system_monitoring_system_status'.tr(
                      namedArgs: {
                        'status': _systemMetrics['systemHealth']
                                ?.toString()
                                .toUpperCase() ??
                            'UNKNOWN',
                      },
                    ),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'admin_admin_system_monitoring_last_updated'.tr(
                      namedArgs: {
                        'timestamp': DateTime.now().toString().substring(0, 19),
                      },
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      _isRealTimeEnabled
                          ? 'admin_admin_system_monitoring_status_live'.tr()
                          : 'admin_admin_system_monitoring_status_paused'.tr(),
                      style: const TextStyle(
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
          const SizedBox(height: 24),

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
                title: 'admin_admin_system_monitoring_text_cpu_usage'.tr(),
                value:
                    '${(_systemMetrics['cpuUsage'] ?? 0).toStringAsFixed(1)}%',
                icon: Icons.memory,
                color: _getCpuColor((_systemMetrics['cpuUsage'] as num?) ?? 0),
                trend: (_systemMetrics['cpuTrend'] as num?)?.toDouble(),
              ),
              AdminMetricsCard(
                title: 'admin_admin_system_monitoring_text_memory_usage'.tr(),
                value:
                    '${(_systemMetrics['memoryUsage'] ?? 0).toStringAsFixed(1)}%',
                icon: Icons.storage,
                color: _getMemoryColor(
                    (_systemMetrics['memoryUsage'] as num?) ?? 0),
                trend: (_systemMetrics['memoryTrend'] as num?)?.toDouble(),
              ),
              AdminMetricsCard(
                title: 'admin_admin_system_monitoring_text_active_users'.tr(),
                value: '${_systemMetrics['activeUsers'] ?? 0}',
                icon: Icons.people,
                color: Colors.blue,
                trend: (_systemMetrics['usersTrend'] as num?)?.toDouble(),
              ),
              AdminMetricsCard(
                title: 'admin_admin_system_monitoring_text_response_time'.tr(),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'admin_admin_system_monitoring_server_status'.tr(),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'admin_admin_system_monitoring_recent_alerts'.tr(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () => _tabController.animateTo(2),
                        child: Text(
                            'admin_admin_system_monitoring_text_view_all'.tr()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_systemAlerts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                            'admin_admin_system_monitoring_text_no_recent_alerts'
                                .tr()),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'admin_admin_system_monitoring_realtime_performance'.tr(),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'admin_admin_system_monitoring_performance_metrics'.tr(),
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
                  title:
                      'admin_admin_system_monitoring_text_critical_alerts'.tr(),
                  value:
                      '${_systemAlerts.where((a) => a['severity'] == 'critical').length}',
                  icon: Icons.error,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AdminMetricsCard(
                  title:
                      'admin_admin_system_monitoring_text_warning_alerts'.tr(),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'admin_admin_system_monitoring_system_alerts'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (_systemAlerts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                            'admin_admin_system_monitoring_text_no_system_alerts'
                                .tr()),
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
                title: 'admin_admin_system_monitoring_text_online_users'.tr(),
                value: '${_systemMetrics['onlineUsers'] ?? 0}',
                icon: Icons.circle,
                color: Colors.green,
              ),
              AdminMetricsCard(
                title: 'admin_admin_system_monitoring_text_peak_today'.tr(),
                value: '${_systemMetrics['peakUsers'] ?? 0}',
                icon: Icons.trending_up,
                color: Colors.blue,
              ),
              AdminMetricsCard(
                title: 'admin_admin_system_monitoring_text_avg_session'.tr(),
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
                    'admin_admin_system_monitoring_text_active_users'.tr(),
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
      child: Center(
        child: Text(
          'admin_admin_system_monitoring_performance_chart_placeholder'.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(
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

  Widget _buildRemoteConfigTab() {
    final keys = _configValues.keys.toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'admin_admin_system_monitoring_remote_config_title'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loadRemoteConfig,
                icon: const Icon(Icons.refresh),
                label: Text(
                  'admin_admin_system_monitoring_remote_config_fetch_activate'
                      .tr(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              final value = _configValues[key]!;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(key,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'admin_admin_system_monitoring_remote_config_value'.tr(
                      namedArgs: {'value': value.asString()},
                    ),
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _showEditConfigDialog(key, value.asString()),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppCheckTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: _appCheckEnabled ? Colors.green[50] : Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _appCheckEnabled ? Icons.verified_user : Icons.gpp_maybe,
                    color: _appCheckEnabled ? Colors.green : Colors.red,
                    size: 48,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'admin_admin_system_monitoring_app_check_status'.tr(
                            namedArgs: {
                              'status': _appCheckEnabled
                                  ? 'admin_admin_system_monitoring_app_check_enabled'
                                      .tr()
                                  : 'admin_admin_system_monitoring_app_check_disabled'
                                      .tr(),
                            },
                          ),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'admin_admin_system_monitoring_app_check_subtitle'
                              .tr(),
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'admin_admin_system_monitoring_app_check_enforcement_status'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildAppCheckStatusItem(
              'admin_admin_system_monitoring_service_firestore'.tr(),
              'admin_admin_system_monitoring_enforced'.tr(),
              Colors.green),
          _buildAppCheckStatusItem(
              'admin_admin_system_monitoring_service_storage'.tr(),
              'admin_admin_system_monitoring_enforced'.tr(),
              Colors.green),
          _buildAppCheckStatusItem(
              'admin_admin_system_monitoring_service_auth'.tr(),
              'admin_admin_system_monitoring_enforced'.tr(),
              Colors.green),
          _buildAppCheckStatusItem(
              'admin_admin_system_monitoring_service_functions'.tr(),
              'admin_admin_system_monitoring_unenforced'.tr(),
              Colors.orange),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'admin_admin_system_monitoring_app_check_note'.tr(),
                    style: const TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCheckStatusItem(String service, String status, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(service),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Text(
            status,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText:
                  'admin_admin_system_monitoring_feedback_search_hint'.tr(),
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: const Icon(Icons.person, color: Colors.blue),
                  ),
                  title: Text(
                    'admin_admin_system_monitoring_feedback_item_title'.tr(
                      namedArgs: {'id': '${1000 + index}'},
                    ),
                  ),
                  subtitle: Text(
                    'admin_admin_system_monitoring_feedback_item_summary'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing:
                      _buildStatusChip(index % 3 == 0 ? 'new' : 'resolved'),
                  onTap: () => _showFeedbackDetails(index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEditConfigDialog(String key, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'admin_admin_system_monitoring_edit_config_title'.tr(
            namedArgs: {'key': key},
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText:
                'admin_admin_system_monitoring_remote_config_value_label'.tr(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              // Note: Remote config cannot be updated from the client SDK directly for security
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'admin_admin_system_monitoring_remote_config_update_note'
                        .tr(),
                  ),
                ),
              );
            },
            child: Text(
              'admin_admin_system_monitoring_remote_config_update_button'.tr(),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDetails(int index) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'admin_admin_system_monitoring_feedback_item_title'.tr(
            namedArgs: {'id': '${1000 + index}'},
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'admin_admin_system_monitoring_feedback_user'.tr(
                namedArgs: {'user': 'user_456'},
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('admin_admin_system_monitoring_feedback_message_label'.tr()),
            Text(
              'admin_admin_system_monitoring_feedback_message_body'.tr(),
            ),
            const SizedBox(height: 16),
            Text(
              'admin_admin_system_monitoring_feedback_metadata_label'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'admin_admin_system_monitoring_feedback_device'.tr(
                namedArgs: {'device': 'iPhone 15 Pro'},
              ),
            ),
            Text(
              'admin_admin_system_monitoring_feedback_os'.tr(
                namedArgs: {'os': 'iOS 17.4'},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common_close'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'admin_admin_system_monitoring_feedback_mark_resolved'.tr(),
            ),
          ),
        ],
      ),
    );
  }
}
