import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/admin_drawer.dart';

/// Admin Security Center Screen
/// Handles security monitoring, threat detection, and system security
class AdminSecurityCenterScreen extends StatefulWidget {
  const AdminSecurityCenterScreen({super.key});

  @override
  State<AdminSecurityCenterScreen> createState() =>
      _AdminSecurityCenterScreenState();
}

class _AdminSecurityCenterScreenState extends State<AdminSecurityCenterScreen> {
  final List<String> _tabs = [
    'admin_security_tab_overview'.tr(),
    'admin_security_tab_threat_detection'.tr(),
    'admin_security_tab_access_control'.tr(),
    'admin_security_tab_audit_logs'.tr()
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'admin_security_title_center'.tr(),
            style: TextStyle(
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
                  '94/100',
                  Icons.security,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusCard(
                  'admin_security_metric_active_threats'.tr(),
                  '2',
                  Icons.warning,
                  Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  'admin_security_metric_failed_logins'.tr(),
                  '15',
                  Icons.login,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusCard(
                  'admin_security_metric_blocked_ips'.tr(),
                  '8',
                  Icons.block,
                  Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Recent Security Events
          Text(
            'admin_security_section_recent_events'.tr(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8C52FF),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (index) => _buildSecurityEventCard(index)),
        ],
      ),
    );
  }

  Widget _buildThreatDetectionTab() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Active Threats
        Text(
          'admin_security_section_active_threats'.tr(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8C52FF),
          ),
        ),
        SizedBox(height: 16),
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
        SizedBox(height: 24),

        // Threat Detection Settings
        Text(
          'admin_security_section_detection_settings'.tr(),
          style: TextStyle(
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
        Text(
          'Admin Access Control',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8C52FF),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(3, (index) => _buildAdminUserCard(index)),

        const SizedBox(height: 24),

        // IP Whitelist
        Text(
          'IP Whitelist',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8C52FF),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text('admin_admin_security_center_text_1921681024'.tr()),
                subtitle: Text(
                    'admin_admin_security_center_text_office_network'.tr()),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {},
                ),
              ),
              ListTile(
                title: Text('admin_admin_security_center_text_100008'.tr()),
                subtitle:
                    Text('admin_admin_security_center_text_vpn_network'.tr()),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {},
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add, color: Color(0xFF8C52FF)),
                title:
                    Text('admin_admin_security_center_text_add_ip_range'.tr()),
                onTap: () => _showAddIPDialog(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuditLogsTab() {
    return Column(
      children: [
        // Filter Controls
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search logs...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {},
                ),
              ),
              SizedBox(width: 16),
              DropdownButton<String>(
                value: 'All',
                items: ['All', 'Login', 'Data Access', 'Settings Change']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {},
              ),
            ],
          ),
        ),

        // Audit Log Entries
        Expanded(
          child: ListView.builder(
            itemCount: 20,
            itemBuilder: (context, index) => _buildAuditLogEntry(index),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityEventCard(int index) {
    final events = [
      'admin_security_event_failed_login'.tr(),
      'admin_security_event_new_admin'.tr(),
      'admin_security_event_suspicious_access'.tr(),
      'admin_security_event_password_policy'.tr(),
      'admin_security_event_security_scan'.tr(),
    ];

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.security, color: Color(0xFF8C52FF)),
        title: Text(events[index % events.length]),
        subtitle: Text(
            '2024-12-${(index + 1).toString().padLeft(2, '0')} 10:${(index * 5).toString().padLeft(2, '0')} AM'),
        trailing: Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }

  Widget _buildThreatCard(
      String title, String description, String severity, Color color) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
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

  Widget _buildAdminUserCard(int index) {
    final users = ['John Admin', 'Sarah Security', 'Mike Manager'];

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFF8C52FF),
          child: Text(users[index][0]),
        ),
        title: Text(users[index]),
        subtitle: Text('admin_admin_security_center_text_role_rolesindex'.tr()),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
                value: 'edit',
                child: Text(
                    'admin_admin_security_center_text_edit_permissions'.tr())),
            PopupMenuItem(
                value: 'disable',
                child: Text(
                    'admin_admin_security_center_text_disable_account'.tr())),
            PopupMenuItem(
                value: 'remove',
                child:
                    Text('admin_admin_security_center_text_remove_admin'.tr())),
          ],
          onSelected: (value) => _handleAdminAction(value, users[index]),
        ),
      ),
    );
  }

  Widget _buildAuditLogEntry(int index) {
    final actions = [
      'User Login',
      'Data Export',
      'Settings Change',
      'User Created',
      'Content Deleted'
    ];
    final users = [
      'john.admin',
      'sarah.security',
      'mike.manager',
      'system',
      'auto.moderator'
    ];

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        dense: true,
        title: Text(actions[index % actions.length]),
        subtitle: Text(
            'User: ${users[index % users.length]} | IP: 192.168.1.${100 + index}'),
        trailing:
            Text('${10 + index}:${(index * 3).toString().padLeft(2, '0')}'),
        onTap: () => _showLogDetails(index),
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
            SizedBox(height: 8),
            Text(description),
            SizedBox(height: 16),
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'admin_admin_security_center_text_threat_marked_as'
                            .tr())),
              );
            },
            child: Text('admin_admin_security_center_text_resolve'.tr()),
          ),
        ],
      ),
    );
  }

  void _showAddIPDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin_admin_security_center_text_add_ip_range'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'IP Address/Range',
                hintText: '192.168.1.0/24',
              ),
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Office Network',
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'admin_admin_security_center_text_ip_range_added'
                            .tr())),
              );
            },
            child: Text('admin_admin_security_center_text_add'.tr()),
          ),
        ],
      ),
    );
  }

  void _handleAdminAction(Object? value, String user) {
    String message;
    switch (value) {
      case 'edit':
        message = 'Edit permissions for $user';
        break;
      case 'disable':
        message = 'Disabled account for $user';
        break;
      case 'remove':
        message = 'Removed admin privileges for $user';
        break;
      default:
        message = 'Unknown action';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showLogDetails(int index) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin_admin_security_center_text_audit_log_details'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('admin_admin_security_center_text_log_id_log1000'.tr()),
            Text(
                'Timestamp: 2024-12-24 ${10 + index}:${(index * 3).toString().padLeft(2, '0')}:00'),
            Text('admin_admin_security_center_text_user_userindex_1'.tr()),
            Text('admin_admin_security_center_text_ip_address_1921681100'.tr()),
            Text('admin_admin_security_center_text_user_agent_mozilla50'.tr()),
            Text(
                'admin_admin_security_center_success_additional_details_success'
                    .tr()),
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
}
