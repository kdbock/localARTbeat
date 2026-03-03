import 'package:artbeat_artist/src/utils/input_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InputValidator', () {
    test('validateUserId enforces pattern and length', () {
      expect(InputValidator.validateUserId('ab').isValid, isFalse);
      expect(InputValidator.validateUserId('valid_user-1').isValid, isTrue);
      expect(InputValidator.validateUserId('bad/id').isValid, isFalse);
    });

    test('validatePaymentAmount enforces positivity and decimals', () {
      expect(InputValidator.validatePaymentAmount(0).isValid, isFalse);
      expect(InputValidator.validatePaymentAmount(-5).isValid, isFalse);
      expect(InputValidator.validatePaymentAmount(12.345).isValid, isFalse);
      expect(InputValidator.validatePaymentAmount(12.34).isValid, isTrue);
    });

    test('sanitizeText strips html and dangerous chars', () {
      final sanitized = InputValidator.sanitizeText(
        '  <b>Hello</b> "world" <script>x</script>  ',
      );
      expect(sanitized, 'Hello world x');
    });

    test('validateSubscriptionTier accepts known values', () {
      expect(InputValidator.validateSubscriptionTier('basic').isValid, isTrue);
      expect(InputValidator.validateSubscriptionTier('pro').isValid, isTrue);
      expect(
        InputValidator.validateSubscriptionTier('enterprise').isValid,
        isFalse,
      );
    });
  });
}
