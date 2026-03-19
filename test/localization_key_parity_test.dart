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

  test('all locale files contain exactly the same keys as English', () {
    final english = loadJson(localeFiles.first);
    final englishKeys = english.keys.toSet();

    for (final file in localeFiles.skip(1)) {
      final locale = loadJson(file);
      final localeKeys = locale.keys.toSet();
      final missing = englishKeys.difference(localeKeys).toList()..sort();
      final extra = localeKeys.difference(englishKeys).toList()..sort();

      expect(
        missing,
        isEmpty,
        reason: 'Missing keys in $file: ${missing.join(', ')}',
      );
      expect(
        extra,
        isEmpty,
        reason: 'Extra keys in $file: ${extra.join(', ')}',
      );
    }
  });
}
