import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart' as intl;
import '../widgets/admin_drawer.dart';
import '../services/audit_trail_service.dart';
import '../services/security_service.dart';
import '../models/security_model.dart';

/// Admin Security Center Screen
/// Handles security monitoring, threat detection, and system security
class AdminSecurityCenterScreen extends StatefulWidget {
  const AdminSecurityCenterScreen({super.key});

  @override
  State<AdminSecurityCenterScreen> createState() =>
      _AdminSecurityCenterScreenState();
}

class _AdminSecurityCenterScreenState extends State<AdminSecurityCenterScreen> {
  final SecurityService _securityService = SecurityService();
  final AuditTrailService _auditService = AuditTrailService();
  final TextEditingController _logSearchController = TextEditingController();

  final List<String> _tabs = [
    'admin_security_tab_overview'.tr(),
    'admin_security_tab_threat_detection'.tr(),
    'admin_security_tab_access_control'.tr(),
    'admin_security_tab_audit_logs'.tr()
  ];

  String _selectedLogFilter = 'All';
  String _logSearchQuery = '';

  @override
  void dispose() {
    _logSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'admin_security_title_center'.tr(),
            style: const TextStyle(
              fontFamily: 'Limelight',
              color: Color(0xFF8C52FF),
            ),
          ),
          bottom: TabBar(
            tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
            labelColor: const Color(0xFF8C52FF),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF8C52FF),
          ),
        ),
        drawer: const AdminDrawer(),
        body: TabBarView(
          children: [
            _buildSecurityOverviewTab(),
            _buildThreatDetectionTab(),
            _buildAccessControlTab(),
            _buildAuditLogsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityOverviewTab() {
    return StreamBuilder<SecurityMetrics>(
      stream: _securityService.getSecurityMetrics(),
      builder: (context, snapshot) {
        final metrics = snapshot.data ?? SecurityMetrics.initial();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security Status Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      'admin_security_metric_score'.tr(),
                      '${metrics.securityScore}/100',
                      Icons.security,
                      _getScoreColor(metrics.securityScore),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatusCard(
                      'admin_security_metric_active_threats'.tr(),
                      metrics.activeThreats.toString(),
                      Icons.warning,
                      metrics.activeThreats > 0 ? Colors.orange : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      'admin_security_metric_failed_logins'.tr(),
                      metrics.failedLogins.toString(),
                      Icons.login,
                      metrics.failedLogins > 10 ? Colors.red : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatusCard(
                      'admin_security_metric_blocked_ips'.tr(),
                      metrics.blockedIps.toString(),
                      Icons.block,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Security Events
              Text(
                'admin_security_section_recent_events'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8C52FF),
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<SecurityEvent>>(
                stream: _securityService.getRecentSecurityEvents(),
                builder: (context, eventSnapshot) {
                  final events = eventSnapshot.data ?? [];
                  if (events.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('admin_security_no_recent_events'.tr()),
                      ),
                    );
                  }
                  return Column(
                    children: events
                        .map((event) => _buildSecurityEventItem(event))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  Widget _buildSecurityEventItem(SecurityEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.security,
          color: _getLogColor(event.severity),
        ),
        title: Text(event.title),
        subtitle: Text(
          intl.DateFormat('yyyy-MM-dd HH:mm').format(event.timestamp),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showEventDetails(event),
      ),
    );
  }

  void _showEventDetails(SecurityEvent event) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Severity: ${event.severity}'),
            const SizedBox(height: 8),
            Text(event.description),
            const SizedBox(height: 16),
            Text('Timestamp: ${intl.DateFormat('yyyy-MM-dd HH:mm:ss').format(event.timestamp)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('admin_admin_payment_text_close'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatDetectionTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Active Threats
        Text(
          'admin_security_section_active_threats'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8C52FF),
          ),
        ),
        const SizedBox(height: 16),
        _buildThreatCard(
          'admin_security_threat_suspicious_login'.tr(),
          'admin_security_threat_suspicious_login_desc'.tr(),
          'High',
          Colors.red,
        ),
        _buildThreatCard(
          'admin_security_threat_unusual_access'.tr(),
          'admin_security_threat_unusual_access_desc'.tr(),
          'Medium',
          Colors.orange,
        ),
        const SizedBox(height: 24),

        // Threat Detection Settings
        Text(
          'admin_security_section_detection_settings'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8C52FF),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                      'admin_admin_security_center_text_realtime_monitoring'
                          .tr()),
                  subtitle: Text(
                      'admin_admin_security_center_text_monitor_security_events'
                          .tr()),
                  value: true,
                  onChanged: (value) {},
                  activeThumbColor: const Color(0xFF8C52FF),
                ),
                SwitchListTile(
                  title: Text(
                      'admin_admin_security_center_text_automated_threat_response'
                          .tr()),
                  subtitle: Text(
                      'admin_admin_security_center_text_automatically_block_suspicious'
                          .tr()),
                  value: true,
                  onChanged: (value) {},
                  activeThumbColor: const Color(0xFF8C52FF),
                ),
                SwitchListTile(
                  title: Text(
                      'admin_admin_security_center_label_email_alerts'.tr()),
                  subtitle: Text(
                      'admin_admin_security_center_label_send_email_notifications'
                          .tr()),
                  value: false,
                  onChanged: (value) {},
                  activeThumbColor: const Color(0xFF8C52FF),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccessControlTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Admin Permissions
        const Text(
          'Admin Access Control',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8C52FF),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Admin user management is handled in the User Management section.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),

        const SizedBox(height: 24),

        // Blocked IPs
        const Text(
          'Blocked IP Addresses',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8C52FF),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<BlockedIP>>(
          stream: _securityService.getBlockedIPs(),
          builder: (context, snapshot) {
            final blockedIPs = snapshot.data ?? [];
            return Card(
              child: Column(
                children: [
                  if (blockedIPs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('admin_security_no_blocked_ips'.tr()),
                    ),
                  ...blockedIPs.map((ip) => ListTile(
                        title: Text(ip.ipAddress),
                        subtitle: Text(ip.reason),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _unblockIP(ip.id, ip.ipAddress),
                        ),
                      )),
                  ListTile(
                    leading: const Icon(Icons.add, color: Color(0xFF8C52FF)),
                    title: Text('admin_security_block_new_ip'.tr()),
                    onTap: () => _showAddIPDialog(),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAuditLogsTab() {
    return Column(
      children: [
        // Filter Controls
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _logSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search logs...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _logSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _logSearchController.clear();
                              setState(() {
                                _logSearchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _logSearchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedLogFilter,
                items: ['All', 'Login', 'Data Access', 'Settings Change', 'User Action']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedLogFilter = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),

        // Audit Log Entries
        Expanded(
          child: StreamBuilder<List<AuditLog>>(
            stream: _auditService.getAuditLogs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              var logs = snapshot.data ?? [];

              // Apply filtering
              if (_selectedLogFilter != 'All') {
                logs = logs.where((log) => log.category == _selectedLogFilter).toList();
              }

              if (_logSearchQuery.isNotEmpty) {
                logs = logs.where((log) => 
                  log.action.toLowerCase().contains(_logSearchQuery) ||
                  log.userId.toLowerCase().contains(_logSearchQuery) ||
                  log.ipAddress.toLowerCase().contains(_logSearchQuery) ||
                  log.metadata.toString().toLowerCase().contains(_logSearchQuery)
                ).toList();
              }
              
              if (logs.isEmpty) {
                return const Center(child: Text('No audit logs found matching criteria.'));
              }

              return ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) => _buildAuditLogEntry(logs[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreatCard(
      String title, String description, String severity, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.warning, color: color),
        title: Text(title),
        subtitle: Text(description),
        trailing: Chip(
          label: Text(severity),
          backgroundColor: color.withValues(alpha: 0.1),
          labelStyle: TextStyle(color: color),
        ),
        onTap: () => _showThreatDetails(title, description, severity),
      ),
    );
  }

  void _showThreatDetails(String title, String description, String severity) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('admin_admin_security_center_text_severity_severity'.tr()),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 16),
            Text('admin_admin_security_center_text_recommended_actions'.tr()),
            Text('admin_admin_security_center_text_monitor_the_ip'.tr()),
            Text('admin_admin_security_center_text_review_access_logs'.tr()),
            Text('admin_admin_security_center_text_consider_blocking_if'.tr()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('admin_admin_payment_text_close'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              // Audit Trail
              await _auditService.logAdminAction(
                action: 'resolve_threat',
                category: 'security',
                description: 'Resolved security threat: $title',
                metadata: {'threat_title': title, 'severity': severity},
              );

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'admin_admin_security_center_text_threat_marked_as'
                              .tr())),
                );
              }
            },
            child: Text('admin_admin_security_center_text_resolve'.tr()),
          ),
        ],
      ),
    );
  }

  void _unblockIP(String id, String ipAddress) async {
    try {
      await _securityService.unblockIP(id);
      
      // Audit Trail
      await _auditService.logAdminAction(
        action: 'unblock_ip',
        category: 'security',
        description: 'Unblocked IP: $ipAddress',
        metadata: {'ip': ipAddress},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('IP $ipAddress unblocked successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showAddIPDialog() {
    final ipController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin_security_block_new_ip'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.1.1',
              ),
            ),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Suspicious activity',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('admin_admin_payment_text_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              final ip = ipController.text.trim();
              final reason = reasonController.text.trim();
              if (ip.isNotEmpty && reason.isNotEmpty) {
                try {
                  await _securityService.blockIP(ip, reason);
                  
                  // Audit Trail
                  await _auditService.logAdminAction(
                    action: 'block_ip',
                    category: 'security',
                    description: 'Blocked IP: $ip. Reason: $reason',
                    metadata: {'ip': ip, 'reason': reason},
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('IP $ip blocked successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: Text('admin_admin_security_center_text_block'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogEntry(AuditLog log) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        dense: true,
        leading: Icon(
          _getLogIcon(log.action),
          color: _getLogColor(log.severity),
        ),
        title: Text(log.action),
        subtitle: Text(
          'User: ${log.userId} | IP: ${log.ipAddress}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          intl.DateFormat('HH:mm').format(log.timestamp),
          style: const TextStyle(color: Colors.grey),
        ),
        onTap: () => _showLogDetails(log),
      ),
    );
  }

  IconData _getLogIcon(String action) {
    if (action.contains('Login')) return Icons.login;
    if (action.contains('Delete')) return Icons.delete_forever;
    if (action.contains('Suspend')) return Icons.block;
    if (action.contains('Role')) return Icons.admin_panel_settings;
    return Icons.info_outline;
  }

  Color _getLogColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
        return Colors.red;
      case 'medium':
      case 'warning':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  void _showLogDetails(AuditLog log) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin_admin_security_center_text_audit_log_details'.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Action', log.action),
              _detailRow('User ID', log.userId),
              _detailRow('Timestamp', intl.DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp)),
              _detailRow('IP Address', log.ipAddress),
              _detailRow('Severity', log.severity),
              const SizedBox(height: 8),
              const Text('Metadata:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(log.metadata.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('admin_admin_payment_text_close'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 14),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
