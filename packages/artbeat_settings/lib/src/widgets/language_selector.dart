import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'common_language'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: languages.map((lang) {
                final isSelected = _selectedLanguage == lang['code'];
                return GestureDetector(
                  onTap: () => _changeLanguage(lang['code']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF8B5CF6)
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      color: isSelected
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          lang['nameKey']!.tr(),
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF8B5CF6)
                                : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
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
