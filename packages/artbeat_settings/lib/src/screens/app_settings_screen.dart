import 'package:flutter/material.dart';

import '../widgets/hud_top_bar.dart';
import '../widgets/settings_category_header.dart';
import '../widgets/settings_list_item.dart';
import '../widgets/settings_section_card.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      body: Stack(
        children: [
          // Background gradient
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
                  title: 'app_settings_title', // .tr() inside widget
                  subtitle: 'app_settings_subtitle',
                  onBack: () => Navigator.of(context).maybePop(),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 8, bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SettingsCategoryHeader(title: 'General'),

                        SettingsSectionCard(
                          child: Column(
                            children: [
                              SettingsListItem(
                                icon: Icons.language_rounded,
                                title: 'Language',
                                subtitle: 'English',
                                onTap: () {
                                  // TODO: Navigate to language screen
                                },
                              ),
                              SettingsListItem(
                                icon: Icons.palette_rounded,
                                title: 'Appearance',
                                subtitle: 'System Default',
                                onTap: () {
                                  // TODO: Theme switcher
                                },
                              ),
                              SettingsListItem(
                                icon: Icons.storage_rounded,
                                title: 'Storage Usage',
                                subtitle: '1.2 MB',
                                onTap: () {
                                  // TODO: Show storage usage screen
                                },
                              ),
                            ],
                          ),
                        ),

                        const SettingsCategoryHeader(title: 'Account'),

                        SettingsSectionCard(
                          child: Column(
                            children: [
                              SettingsListItem(
                                icon: Icons.lock_rounded,
                                title: 'Privacy Settings',
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/settings/privacy',
                                  );
                                },
                              ),
                              SettingsListItem(
                                icon: Icons.logout_rounded,
                                title: 'Sign Out',
                                destructive: true,
                                onTap: () {
                                  // TODO: Handle sign out
                                },
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
