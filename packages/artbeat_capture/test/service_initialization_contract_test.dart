import 'package:artbeat_capture/src/services/ai_ml_integration_service.dart';
import 'package:artbeat_capture/src/services/capture_analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Capture service initialization contracts', () {
    test(
      'CaptureAnalyticsService can be constructed without eager Firebase access',
      () {
        expect(CaptureAnalyticsService.new, returnsNormally);
      },
    );

    test(
      'AIMLIntegrationService can be constructed without eager Firebase access',
      () {
        expect(AIMLIntegrationService.new, returnsNormally);
      },
    );
  });
}
