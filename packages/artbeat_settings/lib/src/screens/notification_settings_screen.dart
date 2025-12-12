import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/models.dart';
import '../services/settings_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _settingsService = SettingsService();
  NotificationSettingsModel? _notificationSettings;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() => _isLoading = true);

    try {
      final settings = await _settingsService.getNotificationSettings();
      if (mounted) {
        setState(() => _notificationSettings = settings);
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('settings_load_failed'.tr());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _updateSettings(NotificationSettingsModel settings) async {
    try {
      await _settingsService.saveNotificationSettings(settings);
      if (mounted) {
        setState(() => _notificationSettings = settings);
        _showSuccessMessage('settings_updated'.tr());
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('settings_update_failed'.tr());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _buildNotificationSettings();
  }

  Widget _buildNotificationSettings() {
    if (_notificationSettings == null)
      return Center(child: Text('settings_no_settings'.tr()));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEmailSettings(),
        const SizedBox(height: 24),
        _buildPushSettings(),
        const SizedBox(height: 24),
        _buildInAppSettings(),
        const SizedBox(height: 24),
        _buildQuietHoursSettings(),
      ],
    );
  }

  Widget _buildEmailSettings() {
    final email = _notificationSettings!.email;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.email),
                const SizedBox(width: 8),
                Text(
                  'settings_email_notifications'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('settings_enable_email_notifications'.tr()),
              subtitle: Text('settings_receive_notifications_email'.tr()),
              value: email.enabled,
              onChanged: (value) {
                final updated = _notificationSettings!.copyWith(
                  email: email.copyWith(enabled: value),
                );
                _updateSettings(updated);
              },
            ),
            if (email.enabled) ...[
              const Divider(),
              ListTile(
                title: Text('settings_frequency'.tr()),
                subtitle: Text(
                  'settings_currently'.tr(
                    namedArgs: {'value': email.frequency},
                  ),
                ),
                trailing: DropdownButton<String>(
                  value: email.frequency,
                  items: [
                    DropdownMenuItem(
                      value: 'immediate',
                      child: Text('settings_frequency_immediate'.tr()),
                    ),
                    DropdownMenuItem(
                      value: 'daily',
                      child: Text('settings_frequency_daily'.tr()),
                    ),
                    DropdownMenuItem(
                      value: 'weekly',
                      child: Text('settings_frequency_weekly'.tr()),
                    ),
                    DropdownMenuItem(
                      value: 'never',
                      child: Text('settings_never'.tr()),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      final updated = _notificationSettings!.copyWith(
                        email: email.copyWith(frequency: value),
                      );
                      _updateSettings(updated);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPushSettings() {
    final push = _notificationSettings!.push;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications),
                const SizedBox(width: 8),
                Text(
                  'settings_push_notifications'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('settings_enable_push_notifications'.tr()),
              subtitle: Text('settings_receive_notifications_device'.tr()),
              value: push.enabled,
              onChanged: (value) {
                final updated = _notificationSettings!.copyWith(
                  push: push.copyWith(enabled: value),
                );
                _updateSettings(updated);
              },
            ),
            if (push.enabled) ...[
              const Divider(),
              SwitchListTile(
                title: Text('settings_sound'.tr()),
                subtitle: Text('settings_play_sound_notifications'.tr()),
                value: push.allowSounds,
                onChanged: (value) {
                  final updated = _notificationSettings!.copyWith(
                    push: push.copyWith(allowSounds: value),
                  );
                  _updateSettings(updated);
                },
              ),
              SwitchListTile(
                title: Text('settings_vibration'.tr()),
                subtitle: Text('settings_vibrate_notifications'.tr()),
                value: push.allowVibration,
                onChanged: (value) {
                  final updated = _notificationSettings!.copyWith(
                    push: push.copyWith(allowVibration: value),
                  );
                  _updateSettings(updated);
                },
              ),
              SwitchListTile(
                title: Text('settings_badges'.tr()),
                subtitle: Text('settings_show_notification_count'.tr()),
                value: push.allowBadges,
                onChanged: (value) {
                  final updated = _notificationSettings!.copyWith(
                    push: push.copyWith(allowBadges: value),
                  );
                  _updateSettings(updated);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInAppSettings() {
    final inApp = _notificationSettings!.inApp;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active),
                const SizedBox(width: 8),
                Text(
                  'settings_in_app_notifications'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('settings_enable_in_app_notifications'.tr()),
              subtitle: Text('settings_show_notifications_using_app'.tr()),
              value: inApp.enabled,
              onChanged: (value) {
                final updated = _notificationSettings!.copyWith(
                  inApp: inApp.copyWith(enabled: value),
                );
                _updateSettings(updated);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursSettings() {
    final quietHours = _notificationSettings!.quietHours;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.nightlight_round),
                const SizedBox(width: 8),
                Text(
                  'settings_quiet_hours'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('settings_enable_quiet_hours'.tr()),
              subtitle: Text('settings_reduce_notifications_hours'.tr()),
              value: quietHours.enabled,
              onChanged: (value) {
                final updated = _notificationSettings!.copyWith(
                  quietHours: quietHours.copyWith(enabled: value),
                );
                _updateSettings(updated);
              },
            ),
            if (quietHours.enabled) ...[
              const Divider(),
              ListTile(
                title: Text('settings_start_time'.tr()),
                subtitle: Text(quietHours.startTime),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context, quietHours.startTime, true),
              ),
              ListTile(
                title: Text('settings_end_time'.tr()),
                subtitle: Text(quietHours.endTime),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context, quietHours.endTime, false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    String currentTime,
    bool isStartTime,
  ) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      final timeString =
          '${selectedTime.hour.toString().padLeft(2, '0')}:'
          '${selectedTime.minute.toString().padLeft(2, '0')}';

      final quietHours = _notificationSettings!.quietHours;
      final updated = _notificationSettings!.copyWith(
        quietHours: isStartTime
            ? quietHours.copyWith(startTime: timeString)
            : quietHours.copyWith(endTime: timeString),
      );
      _updateSettings(updated);
    }
  }
}
