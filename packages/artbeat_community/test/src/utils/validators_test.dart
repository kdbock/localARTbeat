import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_community/utils/validators.dart';

void main() {
  group('Validators', () {
    test('validateEmail accepts valid and rejects invalid formats', () {
      expect(Validators.validateEmail('artist@example.com'), isNull);
      expect(Validators.validateEmail('invalid-email'), isNotNull);
    });

    test('validatePassword enforces minimum complexity', () {
      expect(Validators.validatePassword('Weak123'), isNotNull);
      expect(Validators.validatePassword('StrongPass1'), isNull);
    });

    test('validateUsername enforces allowed charset and length', () {
      expect(Validators.validateUsername('artist_123'), isNull);
      expect(Validators.validateUsername('ab'), isNotNull);
      expect(Validators.validateUsername('invalid-user!'), isNotNull);
    });
  });
}
