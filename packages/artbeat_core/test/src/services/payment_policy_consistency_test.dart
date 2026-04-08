import 'package:artbeat_core/src/models/in_app_purchase_models.dart';
import 'package:artbeat_core/src/services/payment_strategy_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Payment policy table', () {
    final strategy = PaymentStrategyService();

    test('has complete module x purchaseType coverage', () {
      expect(strategy.hasCompletePolicyCoverage(), isTrue);
    });

    test('uses expected policy for compliance-sensitive paths', () {
      expect(
        strategy.getPaymentMethod(PurchaseType.nonConsumable, ArtbeatModule.messaging),
        PaymentMethod.iap,
      );
      expect(
        strategy.getPaymentMethod(PurchaseType.consumable, ArtbeatModule.ads),
        PaymentMethod.iap,
      );
      expect(
        strategy.getPaymentMethod(PurchaseType.subscription, ArtbeatModule.core),
        PaymentMethod.iap,
      );
      expect(
        strategy.getPaymentMethod(PurchaseType.nonConsumable, ArtbeatModule.artist),
        PaymentMethod.stripe,
      );
    });
  });

}
