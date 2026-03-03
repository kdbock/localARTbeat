import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_settings/src/models/security_settings_model.dart';

void main() {
  group('SecuritySettingsModel', () {
    test('defaultSettings produces valid model with nested defaults', () {
      final settings = SecuritySettingsModel.defaultSettings('user-1');

      expect(settings.userId, 'user-1');
      expect(settings.twoFactor.enabled, isFalse);
      expect(settings.login.sessionTimeout, 30);
      expect(settings.isValid(), isTrue);
    });

    test('PasswordSettings validatePassword enforces configured policy', () {
      const password = PasswordSettings(
        minPasswordLength: 10,
        requireUppercase: true,
        requireLowercase: true,
        requireNumbers: true,
        requireSpecialChars: true,
      );

      expect(password.validatePassword('short1A!'), isFalse);
      expect(password.validatePassword('NoSpecial123'), isFalse);
      expect(password.validatePassword('StrongPass123!'), isTrue);
    });

    test('isPasswordChangeRequired follows lastChanged + interval', () {
      final requiresChange = PasswordSettings(
        requirePasswordChange: true,
        passwordChangeInterval: 30,
        lastChanged: DateTime.now().subtract(const Duration(days: 45)),
      );
      final noChangeNeeded = PasswordSettings(
        requirePasswordChange: true,
        passwordChangeInterval: 30,
        lastChanged: DateTime.now().subtract(const Duration(days: 5)),
      );

      expect(requiresChange.isPasswordChangeRequired, isTrue);
      expect(noChangeNeeded.isPasswordChangeRequired, isFalse);
    });
  });
}
