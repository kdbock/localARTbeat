import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart' hide HudTopBar;
import '../widgets/hud_top_bar.dart';
import '../widgets/settings_section_card.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ArtbeatThemeProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      body: Stack(
        children: [
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
                  title: 'settings_theme_title'.tr(),
                  subtitle: 'settings_theme_subtitle'.tr(),
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      _buildThemeOption(
                        context: context,
                        title: 'Light Mode',
                        isSelected: !themeProvider.isDarkMode,
                        icon: Icons.light_mode_rounded,
                        onTap: () => themeProvider.setDarkMode(false),
                      ),
                      _buildThemeOption(
                        context: context,
                        title: 'Dark Mode',
                        isSelected: themeProvider.isDarkMode,
                        icon: Icons.dark_mode_rounded,
                        onTap: () => themeProvider.setDarkMode(true),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Additional theme options will be available in future updates.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SettingsSectionCard(
        child: ListTile(
          leading: Icon(icon, color: Colors.white70),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.radio_button_checked, color: Color(0xFF22D3EE))
              : const Icon(Icons.radio_button_off, color: Colors.white24),
          onTap: onTap,
        ),
      ),
    );
  }
}
