import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/hud_top_bar.dart';
import '../widgets/settings_category_header.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_list_item.dart';

class LegalSettingsScreen extends StatelessWidget {
  const LegalSettingsScreen({super.key});

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                  title: 'legal_settings_title',
                  subtitle: 'legal_settings_subtitle',
                  onBack: () => Navigator.of(context).maybePop(),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 8, bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SettingsCategoryHeader(title: 'Legal'),

                        SettingsSectionCard(
                          child: Column(
                            children: [
                              SettingsListItem(
                                icon: Icons.policy_rounded,
                                title: 'Privacy Policy',
                                onTap: () => _openUrl(
                                  'https://localartbeat.com/privacy',
                                ),
                              ),
                              SettingsListItem(
                                icon: Icons.gavel_rounded,
                                title: 'Terms of Service',
                                onTap: () =>
                                    _openUrl('https://localartbeat.com/terms'),
                              ),
                              SettingsListItem(
                                icon: Icons.groups_2_rounded,
                                title: 'Community Guidelines',
                                onTap: () => _openUrl(
                                  'https://localartbeat.com/guidelines',
                                ),
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
