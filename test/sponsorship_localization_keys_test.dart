import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const localeFiles = <String>[
    'assets/translations/en.json',
    'assets/translations/es.json',
    'assets/translations/fr.json',
    'assets/translations/de.json',
    'assets/translations/pt.json',
    'assets/translations/ar.json',
    'assets/translations/zh.json',
  ];

  Map<String, dynamic> loadJson(String path) {
    final raw = File(path).readAsStringSync();
    return json.decode(raw) as Map<String, dynamic>;
  }

  test(
    'all locales contain the same sponsorship localization keys as English',
    () {
      final en = loadJson(localeFiles.first);
      final sponsorshipKeys = en.keys
          .where((key) => key.startsWith('sponsorship_'))
          .toSet();

      for (final file in localeFiles.skip(1)) {
        final locale = loadJson(file);
        final missing = sponsorshipKeys.where(
          (key) => !locale.containsKey(key),
        );
        expect(
          missing,
          isEmpty,
          reason: 'Missing sponsorship keys in $file: ${missing.join(', ')}',
        );
      }
    },
  );
}
