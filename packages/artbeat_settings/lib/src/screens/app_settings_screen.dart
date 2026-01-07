import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' hide HudTopBar;
import 'package:firebase_auth/firebase_auth.dart';
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
                                subtitle: Localizations.localeOf(
                                  context,
                                ).languageCode.toUpperCase(),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.settingsLanguage,
                                  );
                                },
                              ),
                              SettingsListItem(
                                icon: Icons.palette_rounded,
                                title: 'Appearance',
                                subtitle: 'System Default',
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.settingsTheme,
                                  );
                                },
                              ),
                              SettingsListItem(
                                icon: Icons.storage_rounded,
                                title: 'Storage Usage',
                                subtitle: '1.2 MB',
                                onTap: () {
                                  // Storage usage screen could be implemented similarly
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Storage details coming soon',
                                      ),
                                    ),
                                  );
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
                                    AppRoutes.settingsPrivacy,
                                  );
                                },
                              ),
                              SettingsListItem(
                                icon: Icons.logout_rounded,
                                title: 'Sign Out',
                                destructive: true,
                                onTap: () => _handleSignOut(context),
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

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
        }
      }
    }
  }
}
