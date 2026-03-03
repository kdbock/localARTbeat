import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_admin/src/models/admin_settings_model.dart';

void main() {
  group('AdminSettingsModel', () {
    test('defaultSettings contains expected baseline values', () {
      final settings = AdminSettingsModel.defaultSettings();

      expect(settings.appName, 'ARTbeat');
      expect(settings.maintenanceMode, isFalse);
      expect(settings.registrationEnabled, isTrue);
      expect(settings.maxUploadSizeMB, 10);
      expect(settings.updatedBy, 'system');
    });

    test('toDocument and fromDocument preserve critical fields', () {
      final now = DateTime.now();
      final original = AdminSettingsModel.defaultSettings().copyWith(
        maintenanceMode: true,
        bannedWords: const ['spam', 'abuse'],
        lastUpdated: now,
        updatedBy: 'admin-1',
      );
      final map = original.toDocument();

      expect(map['lastUpdated'], isA<Timestamp>());
      expect(map['maintenanceMode'], isTrue);
      expect(map['bannedWords'], ['spam', 'abuse']);
      expect(map['updatedBy'], 'admin-1');
    });
  });
}
