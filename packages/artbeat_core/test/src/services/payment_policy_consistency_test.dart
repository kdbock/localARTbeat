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

    test('keeps payout modules on Stripe for all purchase types', () {
      const payoutModules = <ArtbeatModule>[
        ArtbeatModule.artist,
        ArtbeatModule.events,
      ];

      for (final module in payoutModules) {
        for (final purchaseType in PurchaseType.values) {
          expect(
            strategy.getPaymentMethod(purchaseType, module),
            PaymentMethod.stripe,
            reason: 'Expected $module/$purchaseType to remain Stripe-routed',
          );
          expect(
            strategy.requiresPayout(module, purchaseType),
            isTrue,
            reason: 'Expected $module/$purchaseType to require payout flow',
          );
        }
      }
    });

    test('keeps app-store-governed modules on IAP for all purchase types', () {
      const iapModules = <ArtbeatModule>[
        ArtbeatModule.core,
        ArtbeatModule.ads,
        ArtbeatModule.messaging,
        ArtbeatModule.capture,
        ArtbeatModule.artWalk,
        ArtbeatModule.profile,
        ArtbeatModule.settings,
      ];

      for (final module in iapModules) {
        for (final purchaseType in PurchaseType.values) {
          expect(
            strategy.getPaymentMethod(purchaseType, module),
            PaymentMethod.iap,
            reason: 'Expected $module/$purchaseType to remain IAP-routed',
          );
          expect(
            strategy.requiresPayout(module, purchaseType),
            isFalse,
            reason: 'Expected $module/$purchaseType to avoid payout flow',
          );
        }
      }
    });
  });
}
