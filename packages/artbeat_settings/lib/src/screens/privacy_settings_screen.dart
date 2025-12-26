import 'package:flutter/material.dart';

import '../widgets/hud_top_bar.dart';
import '../widgets/settings_category_header.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_toggle_row.dart';
import '../widgets/settings_list_item.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool isProfilePrivate = false;
  bool allowDataUsage = true;
  bool personalizedContent = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      body: Stack(
        children: [
          // Gradient background
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
                  title: 'privacy_settings_title',
                  subtitle: 'privacy_settings_subtitle',
                  onBack: () => Navigator.of(context).maybePop(),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 8, bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SettingsCategoryHeader(title: 'Privacy'),

                        SettingsSectionCard(
                          child: Column(
                            children: [
                              SettingsToggleRow(
                                title: 'Private Profile',
                                subtitle: 'Hide your profile from public feeds',
                                value: isProfilePrivate,
                                onChanged: (v) =>
                                    setState(() => isProfilePrivate = v),
                              ),
                              SettingsToggleRow(
                                title: 'Allow Data Usage',
                                subtitle:
                                    'Help us improve by sharing usage data',
                                value: allowDataUsage,
                                onChanged: (v) =>
                                    setState(() => allowDataUsage = v),
                              ),
                              SettingsToggleRow(
                                title: 'Personalized Content',
                                subtitle:
                                    'Improve recommendations based on activity',
                                value: personalizedContent,
                                onChanged: (v) =>
                                    setState(() => personalizedContent = v),
                              ),
                            ],
                          ),
                        ),

                        const SettingsCategoryHeader(title: 'Account'),

                        SettingsSectionCard(
                          child: SettingsListItem(
                            icon: Icons.delete_forever_rounded,
                            title: 'Delete Account',
                            destructive: true,
                            onTap: () {
                              // TODO: Confirm deletion flow
                            },
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
