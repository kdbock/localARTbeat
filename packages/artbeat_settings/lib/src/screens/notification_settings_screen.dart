import 'package:flutter/material.dart';
import '../widgets/settings_category_header.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_toggle_row.dart';
import '../widgets/hud_top_bar.dart';
import '../services/settings_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final SettingsService _settingsService = SettingsService();

  bool captureAlerts = true;
  bool comments = true;
  bool tipsAndUpdates = false;
  bool challenges = true;
  bool autoShareActivities = true;
  bool _isLoadingSettings = true;
  String _distanceUnit = 'miles';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final enabled = await _settingsService.getAutoShareActivitiesEnabled();
      final distanceUnit = await _settingsService.getDistanceUnit();
      if (!mounted) return;
      setState(() {
        autoShareActivities = enabled;
        _distanceUnit = distanceUnit;
      });
    } catch (_) {
      // Keep default value when settings read fails.
    } finally {
      if (mounted) {
        setState(() => _isLoadingSettings = false);
      }
    }
  }

  Future<void> _onAutoShareChanged(bool value) async {
    setState(() => autoShareActivities = value);
    try {
      await _settingsService.setAutoShareActivitiesEnabled(value);
    } catch (_) {
      if (!mounted) return;
      setState(() => autoShareActivities = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save auto-share preference.')),
      );
    }
  }

  Future<void> _onDistanceUnitChanged(bool useKilometers) async {
    final nextUnit = useKilometers ? 'kilometers' : 'miles';
    final previousUnit = _distanceUnit;
    setState(() => _distanceUnit = nextUnit);
    try {
      await _settingsService.setDistanceUnit(nextUnit);
    } catch (_) {
      if (!mounted) return;
      setState(() => _distanceUnit = previousUnit);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save distance unit preference.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF07060F),
                  Color(0xFF0B1222),
                  Color(0xFF0A1B15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                HudTopBar(
                  title: 'notification_settings_title',
                  subtitle: 'notification_settings_subtitle',
                  onBack: () => Navigator.of(context).maybePop(),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 8, bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SettingsCategoryHeader(title: 'Notifications'),

                        SettingsSectionCard(
                          child: Column(
                            children: [
                              SettingsToggleRow(
                                title: 'Distance Units',
                                subtitle:
                                    'Toggle between miles/feet and kilometers/meters',
                                value: _distanceUnit == 'kilometers',
                                onChanged: (v) {
                                  if (_isLoadingSettings) return;
                                  _onDistanceUnitChanged(v);
                                },
                              ),
                              SettingsToggleRow(
                                title: 'Auto-share Activities',
                                subtitle:
                                    'Automatically post captures and completed walks to the community feed',
                                value: autoShareActivities,
                                onChanged: (v) {
                                  if (_isLoadingSettings) return;
                                  _onAutoShareChanged(v);
                                },
                              ),
                              SettingsToggleRow(
                                title: 'New Capture Alerts',
                                subtitle:
                                    'Get notified when new captures are posted',
                                value: captureAlerts,
                                onChanged: (v) =>
                                    setState(() => captureAlerts = v),
                              ),
                              SettingsToggleRow(
                                title: 'Comments & Replies',
                                subtitle: 'Activity on your submissions',
                                value: comments,
                                onChanged: (v) => setState(() => comments = v),
                              ),
                              SettingsToggleRow(
                                title: 'App Tips & Updates',
                                subtitle:
                                    'News, tips, and version announcements',
                                value: tipsAndUpdates,
                                onChanged: (v) =>
                                    setState(() => tipsAndUpdates = v),
                              ),
                              SettingsToggleRow(
                                title: 'Challenges & Events',
                                subtitle: 'Alerts for upcoming challenges',
                                value: challenges,
                                onChanged: (v) =>
                                    setState(() => challenges = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
