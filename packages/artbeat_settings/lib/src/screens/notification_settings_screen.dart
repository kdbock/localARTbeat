import 'package:flutter/material.dart';

import '../widgets/hud_top_bar.dart';
import '../widgets/settings_category_header.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_toggle_row.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool captureAlerts = true;
  bool comments = true;
  bool tipsAndUpdates = false;
  bool challenges = true;

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
