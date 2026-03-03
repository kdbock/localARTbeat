import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_settings/src/models/user_settings_model.dart';

void main() {
  group('UserSettingsModel', () {
    test('defaultSettings creates valid US-oriented defaults', () {
      final settings = UserSettingsModel.defaultSettings('user-1');

      expect(settings.userId, 'user-1');
      expect(settings.darkMode, isFalse);
      expect(settings.notificationsEnabled, isTrue);
      expect(settings.distanceUnit, 'miles');
      expect(settings.isValid(), isTrue);
    });

    test('toMap/fromMap roundtrip preserves key values', () {
      final model = UserSettingsModel.defaultSettings('user-2').copyWith(
        language: 'es',
        timezone: 'America/New_York',
        distanceUnit: 'kilometers',
        blockedUsers: const ['uA', 'uB'],
      );

      final roundTrip = UserSettingsModel.fromMap(model.toMap());

      expect(roundTrip.userId, 'user-2');
      expect(roundTrip.language, 'es');
      expect(roundTrip.timezone, 'America/New_York');
      expect(roundTrip.distanceUnit, 'kilometers');
      expect(roundTrip.blockedUsers, ['uA', 'uB']);
    });

    test('isValid fails for unsupported distance unit', () {
      final invalid = UserSettingsModel.defaultSettings('user-3').copyWith(
        distanceUnit: 'meters',
      );

      expect(invalid.isValid(), isFalse);
    });
  });
}
