import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/hud_top_bar.dart';
import '../widgets/settings_section_card.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supportedLocales = context.supportedLocales;
    final currentLocale = context.locale;

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
                  title: 'settings_language_title'.tr(),
                  subtitle: 'settings_language_subtitle'.tr(),
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: supportedLocales.length,
                    itemBuilder: (context, index) {
                      final locale = supportedLocales[index];
                      final isSelected = locale == currentLocale;
                      final languageName = _getLanguageName(locale.languageCode);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SettingsSectionCard(
                          child: ListTile(
                            title: Text(
                              languageName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Color(0xFF22D3EE))
                                : null,
                            onTap: () async {
                              await context.setLocale(locale);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'es': return 'Español';
      case 'fr': return 'Français';
      case 'de': return 'Deutsch';
      case 'pt': return 'Português';
      case 'zh': return '中文';
      case 'ar': return 'العربية';
      default: return code.toUpperCase();
    }
  }
}
