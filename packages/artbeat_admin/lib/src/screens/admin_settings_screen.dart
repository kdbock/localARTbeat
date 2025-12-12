import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/admin_settings_model.dart';
import '../services/admin_settings_service.dart';
import '../widgets/admin_drawer.dart';

/// Admin Settings Screen
///
/// Allows administrators to configure system settings, manage configurations,
/// and control various aspects of the application.
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final AdminSettingsService _settingsService = AdminSettingsService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  AdminSettingsModel? _settings;
  bool _isLoading = true;
  String? _error;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final settings = await _settingsService.getSettings();

      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    try {
      await _settingsService.updateSettings(_settings!);
      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'admin_admin_settings_success_settings_saved_successfully'
                      .tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('admin_admin_settings_error_failed_to_save'.tr())),
        );
      }
    }
  }

  void _updateSetting<T>(T value, T Function(AdminSettingsModel) getter,
      AdminSettingsModel Function(AdminSettingsModel, T) setter) {
    if (_settings != null && getter(_settings!) != value) {
      setState(() {
        _settings = setter(_settings!, value);
        _hasUnsavedChanges = true;
      });
    }
  }

  void _handleSearch(String query) {
    // Navigate to main search screen
    Navigator.pushNamed(context, '/search');
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1, // Admin screens don't use bottom navigation
      scaffoldKey: _scaffoldKey,
      appBar: EnhancedUniversalHeader(
        title: 'Admin Settings',
        showBackButton: true,
        showSearch: true,
        showDeveloperTools: true,
        onSearchPressed: _handleSearch,
        actions: [
          if (_hasUnsavedChanges)
            TextButton(
              onPressed: _saveSettings,
              child: const Text(
                'Save',
                style: TextStyle(color: Color(0xFF00BF63)),
              ),
            ),
        ],
      ),
      drawer: const AdminDrawer(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorWidget()
                  : _buildSettingsContent(),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading settings',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSettings,
            child: Text('admin_admin_settings_text_retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    if (_settings == null) {
      return Center(
          child: Text('admin_admin_settings_text_no_settings_available'.tr()));
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGeneralSettings(),
          const SizedBox(height: 32),
          _buildUserSettings(),
          const SizedBox(height: 32),
          _buildContentSettings(),
          const SizedBox(height: 32),
          _buildSecuritySettings(),
          const SizedBox(height: 32),
          _buildSystemSettings(),
          const SizedBox(height: 32),
          _buildNotificationSettings(),
          const SizedBox(height: 32),
          _buildMaintenanceSettings(),
          const SizedBox(height: 32),
          _buildDangerZone(),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return _buildSettingsSection(
      title: 'General Settings',
      children: [
        _buildTextSetting(
          'App Name',
          _settings!.appName,
          (value) => _updateSetting(
              value, (s) => s.appName, (s, v) => s.copyWith(appName: v)),
        ),
        _buildTextSetting(
          'App Description',
          _settings!.appDescription,
          (value) => _updateSetting(value, (s) => s.appDescription,
              (s, v) => s.copyWith(appDescription: v)),
        ),
        _buildSwitchSetting(
          'Maintenance Mode',
          _settings!.maintenanceMode,
          (value) => _updateSetting(value, (s) => s.maintenanceMode,
              (s, v) => s.copyWith(maintenanceMode: v)),
        ),
        _buildSwitchSetting(
          'Enable Registration',
          _settings!.registrationEnabled,
          (value) => _updateSetting(value, (s) => s.registrationEnabled,
              (s, v) => s.copyWith(registrationEnabled: v)),
        ),
      ],
    );
  }

  Widget _buildUserSettings() {
    return _buildSettingsSection(
      title: 'User Settings',
      children: [
        _buildNumberSetting(
          'Max Upload Size (MB)',
          _settings!.maxUploadSizeMB.toDouble(),
          (value) => _updateSetting(value.toInt(), (s) => s.maxUploadSizeMB,
              (s, v) => s.copyWith(maxUploadSizeMB: v)),
        ),
        _buildNumberSetting(
          'Max Artworks per User',
          _settings!.maxArtworksPerUser.toDouble(),
          (value) => _updateSetting(value.toInt(), (s) => s.maxArtworksPerUser,
              (s, v) => s.copyWith(maxArtworksPerUser: v)),
        ),
        _buildSwitchSetting(
          'Require Email Verification',
          _settings!.requireEmailVerification,
          (value) => _updateSetting(value, (s) => s.requireEmailVerification,
              (s, v) => s.copyWith(requireEmailVerification: v)),
        ),
        _buildSwitchSetting(
          'Auto-approve Content',
          _settings!.autoApproveContent,
          (value) => _updateSetting(value, (s) => s.autoApproveContent,
              (s, v) => s.copyWith(autoApproveContent: v)),
        ),
      ],
    );
  }

  Widget _buildContentSettings() {
    return _buildSettingsSection(
      title: 'Content Settings',
      children: [
        _buildSwitchSetting(
          'Enable Comments',
          _settings!.commentsEnabled,
          (value) => _updateSetting(value, (s) => s.commentsEnabled,
              (s, v) => s.copyWith(commentsEnabled: v)),
        ),
        _buildSwitchSetting(
          'Enable Artwork Ratings',
          _settings!.ratingsEnabled,
          (value) => _updateSetting(value, (s) => s.ratingsEnabled,
              (s, v) => s.copyWith(ratingsEnabled: v)),
        ),
        _buildSwitchSetting(
          'Enable Content Reporting',
          _settings!.reportingEnabled,
          (value) => _updateSetting(value, (s) => s.reportingEnabled,
              (s, v) => s.copyWith(reportingEnabled: v)),
        ),
        _buildTextSetting(
          'Banned Words (comma-separated)',
          _settings!.bannedWords.join(', '),
          (value) => _updateSetting(
            value
                .split(',')
                .map((w) => w.trim())
                .where((w) => w.isNotEmpty)
                .toList(),
            (s) => s.bannedWords,
            (s, v) => s.copyWith(bannedWords: v),
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySettings() {
    return _buildSettingsSection(
      title: 'Security Settings',
      children: [
        _buildNumberSetting(
          'Max Login Attempts',
          _settings!.maxLoginAttempts.toDouble(),
          (value) => _updateSetting(value.toInt(), (s) => s.maxLoginAttempts,
              (s, v) => s.copyWith(maxLoginAttempts: v)),
        ),
        _buildNumberSetting(
          'Login Attempt Window (minutes)',
          _settings!.loginAttemptWindow.toDouble(),
          (value) => _updateSetting(value.toInt(), (s) => s.loginAttemptWindow,
              (s, v) => s.copyWith(loginAttemptWindow: v)),
        ),
        _buildSwitchSetting(
          'Enable Two-Factor Authentication',
          _settings!.twoFactorEnabled,
          (value) => _updateSetting(value, (s) => s.twoFactorEnabled,
              (s, v) => s.copyWith(twoFactorEnabled: v)),
        ),
        _buildSwitchSetting(
          'Enable IP Blocking',
          _settings!.ipBlockingEnabled,
          (value) => _updateSetting(value, (s) => s.ipBlockingEnabled,
              (s, v) => s.copyWith(ipBlockingEnabled: v)),
        ),
      ],
    );
  }

  Widget _buildSystemSettings() {
    return _buildSettingsSection(
      title: 'System Settings',
      children: [
        _buildSwitchSetting(
          'Enable Analytics',
          _settings!.analyticsEnabled,
          (value) => _updateSetting(value, (s) => s.analyticsEnabled,
              (s, v) => s.copyWith(analyticsEnabled: v)),
        ),
        _buildSwitchSetting(
          'Enable Error Logging',
          _settings!.errorLoggingEnabled,
          (value) => _updateSetting(value, (s) => s.errorLoggingEnabled,
              (s, v) => s.copyWith(errorLoggingEnabled: v)),
        ),
        _buildSwitchSetting(
          'Enable Performance Monitoring',
          _settings!.performanceMonitoringEnabled,
          (value) => _updateSetting(
              value,
              (s) => s.performanceMonitoringEnabled,
              (s, v) => s.copyWith(performanceMonitoringEnabled: v)),
        ),
        _buildNumberSetting(
          'Cache Duration (hours)',
          _settings!.cacheDurationHours.toDouble(),
          (value) => _updateSetting(value.toInt(), (s) => s.cacheDurationHours,
              (s, v) => s.copyWith(cacheDurationHours: v)),
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSettingsSection(
      title: 'Notification Settings',
      children: [
        _buildSwitchSetting(
          'Enable Push Notifications',
          _settings!.pushNotificationsEnabled,
          (value) => _updateSetting(value, (s) => s.pushNotificationsEnabled,
              (s, v) => s.copyWith(pushNotificationsEnabled: v)),
        ),
        _buildSwitchSetting(
          'Enable Email Notifications',
          _settings!.emailNotificationsEnabled,
          (value) => _updateSetting(value, (s) => s.emailNotificationsEnabled,
              (s, v) => s.copyWith(emailNotificationsEnabled: v)),
        ),
        _buildSwitchSetting(
          'Enable Admin Alerts',
          _settings!.adminAlertsEnabled,
          (value) => _updateSetting(value, (s) => s.adminAlertsEnabled,
              (s, v) => s.copyWith(adminAlertsEnabled: v)),
        ),
      ],
    );
  }

  Widget _buildMaintenanceSettings() {
    return _buildSettingsSection(
      title: 'Maintenance Settings',
      children: [
        _buildTextSetting(
          'Maintenance Message',
          _settings!.maintenanceMessage,
          (value) => _updateSetting(value, (s) => s.maintenanceMessage,
              (s, v) => s.copyWith(maintenanceMessage: v)),
        ),
        ListTile(
          title: Text('admin_admin_settings_text_backup_database'.tr()),
          subtitle: Text('admin_admin_settings_text_create_a_backup'.tr()),
          trailing: ElevatedButton(
            onPressed: () => _showBackupDialog(),
            child: Text('admin_admin_settings_text_backup'.tr()),
          ),
        ),
        ListTile(
          title: Text('admin_admin_settings_text_clear_cache'.tr()),
          subtitle: Text('admin_admin_settings_text_clear_all_cached'.tr()),
          trailing: ElevatedButton(
            onPressed: () => _showClearCacheDialog(),
            child: Text('admin_admin_settings_text_clear'.tr()),
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return _buildSettingsSection(
      title: 'Danger Zone',
      color: Colors.red.shade50,
      children: [
        ListTile(
          title: Text('admin_admin_settings_text_reset_all_settings'.tr()),
          subtitle:
              Text('admin_admin_settings_text_reset_all_settings_29'.tr()),
          trailing: ElevatedButton(
            onPressed: () => _showResetDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('admin_admin_settings_text_reset'.tr()),
          ),
        ),
        ListTile(
          title: Text('admin_admin_settings_text_factory_reset'.tr()),
          subtitle: Text('admin_admin_settings_text_warning_this_will'.tr()),
          trailing: ElevatedButton(
            onPressed: () => _showFactoryResetDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text('admin_admin_settings_text_factory_reset'.tr()),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
    Color? color,
  }) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextSetting(
    String title,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: TextField(
        controller: TextEditingController(text: value),
        onChanged: onChanged,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildNumberSetting(
    String title,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: TextField(
        controller: TextEditingController(text: value.toString()),
        keyboardType: TextInputType.number,
        onChanged: (text) {
          final number = double.tryParse(text);
          if (number != null) {
            onChanged(number);
          }
        },
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
    );
  }

  void _showBackupDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin_admin_settings_text_backup_database'.tr()),
        content: const Text(
            'Are you sure you want to create a backup of the database?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('admin_admin_payment_text_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Implement backup logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'admin_admin_settings_success_backup_created_successfully'
                            .tr())),
              );
            },
            child: Text('admin_admin_settings_text_backup'.tr()),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin_admin_settings_text_clear_cache'.tr()),
        content: Text('admin_admin_settings_text_are_you_sure'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('admin_admin_payment_text_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Implement cache clearing logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'admin_admin_settings_success_cache_cleared_successfully'
                            .tr())),
              );
            },
            child: Text('admin_admin_settings_text_clear'.tr()),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin_admin_settings_text_reset_settings'.tr()),
        content: const Text(
            'Are you sure you want to reset all settings to default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('admin_admin_payment_text_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Implement reset logic
              await _settingsService.resetSettings();
              await _loadSettings();
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'admin_admin_settings_success_settings_reset_successfully'
                            .tr())),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('admin_admin_settings_text_reset'.tr()),
          ),
        ],
      ),
    );
  }

  void _showFactoryResetDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin_admin_settings_text_factory_reset'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('admin_admin_settings_text_warning_this_will_64'.tr()),
            const SizedBox(height: 16),
            Text('admin_admin_settings_text_are_you_absolutely'.tr()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('admin_admin_payment_text_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Implement factory reset logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'admin_admin_settings_text_factory_reset_completed'
                            .tr())),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text('admin_admin_settings_text_factory_reset'.tr()),
          ),
        ],
      ),
    );
  }
}
