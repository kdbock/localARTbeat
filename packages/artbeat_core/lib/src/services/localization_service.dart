import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  static const String _languageKey = 'app_language';

  final List<Locale> supportedLocales = const [
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('pt'),
    Locale('zh'),
    Locale('ar'),
  ];

  late SharedPreferences _prefs;
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final savedLanguage = _prefs.getString(_languageKey);

    if (savedLanguage != null) {
      await setLanguage(savedLanguage);
    } else {
      _currentLocale = const Locale('en');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    final locale = Locale(languageCode);
    if (supportedLocales.contains(locale)) {
      _currentLocale = locale;
      await EasyLocalization.of(_getContext())?.setLocale(locale);
      await _prefs.setString(_languageKey, languageCode);
    }
  }

  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      case 'pt':
        return 'Português';
      case 'zh':
        return '中文';
      case 'ar':
        return 'العربية';
      default:
        return 'English';
    }
  }

  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  BuildContext _getContext() {
    if (_context == null) {
      throw Exception(
        'LocalizationService context not set. Call setContext() first.',
      );
    }
    return _context!;
  }
}
