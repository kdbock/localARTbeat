import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_events/artbeat_events.dart';

class LanguageSelector extends StatefulWidget {
  final void Function(String)? onLanguageChanged;

  const LanguageSelector({super.key, this.onLanguageChanged});

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  final List<Map<String, String>> languages = [
    {'code': 'en', 'nameKey': 'artbeat_settings_language_english'},
    {'code': 'es', 'nameKey': 'artbeat_settings_language_spanish'},
    {'code': 'fr', 'nameKey': 'artbeat_settings_language_french'},
    {'code': 'de', 'nameKey': 'artbeat_settings_language_german'},
    {'code': 'pt', 'nameKey': 'artbeat_settings_language_portuguese'},
    {'code': 'zh', 'nameKey': 'artbeat_settings_language_chinese'},
    {'code': 'ar', 'nameKey': 'artbeat_settings_language_arabic'},
  ];

  late String _selectedLanguage;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final easyLoc = EasyLocalization.of(context);
      if (easyLoc != null) {
        _selectedLanguage = easyLoc.locale.languageCode;
        _initialized = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'common_language'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: languages.map((lang) {
              final isSelected = _selectedLanguage == lang['code'];
              return GestureDetector(
                onTap: () => _changeLanguage(lang['code']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF22D3EE)
                          : Colors.white24,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    color: isSelected
                        ? const Color(0xFF22D3EE).withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lang['nameKey']!.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF22D3EE)
                              : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _changeLanguage(String languageCode) async {
    final easyLoc = EasyLocalization.of(context);
    if (easyLoc == null) return;

    setState(() {
      _selectedLanguage = languageCode;
    });

    await easyLoc.setLocale(Locale(languageCode));
    widget.onLanguageChanged?.call(languageCode);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'artbeat_settings_language_changed'.tr().replaceAll(
              '{language}',
              languages
                  .firstWhere((l) => l['code'] == languageCode)['nameKey']!
                  .tr(),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF8B5CF6),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
