import 'package:artbeat_sponsorships/src/services/sponsor_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sponsorship service initialization contracts', () {
    test('SponsorService can be constructed without eager Firebase access', () {
      expect(SponsorService.new, returnsNormally);
    });
  });
}
