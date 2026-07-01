import 'dart:async';

import 'package:artbeat_core/artbeat_core.dart';

import '../models/sponsorship_tier.dart';

class SponsorshipIapPlan {
  const SponsorshipIapPlan({required this.productId});

  final String productId;
}

class SponsorshipCheckoutResult {
  const SponsorshipCheckoutResult({
    required this.productId,
    required this.status,
    this.purchaseId,
    this.transactionId,
    this.amount,
    this.currency,
    this.rawPurchase,
  });

  final String productId;
  final String status;
  final String? purchaseId;
  final String? transactionId;
  final double? amount;
  final String? currency;
  final CompletedPurchase? rawPurchase;
}

class SponsorshipCheckoutService {
  SponsorshipCheckoutService({InAppPurchaseManager? purchaseManager})
    : _purchaseManager = purchaseManager ?? InAppPurchaseManager();

  static const Duration _purchaseTimeout = Duration(minutes: 3);

  static const Map<SponsorshipTier, String> _productIds = {
    SponsorshipTier.discover: 'artbeat_sponsorship_discovery_monthly',
    SponsorshipTier.capture: 'artbeat_sponsorship_capture_monthly',
    SponsorshipTier.artWalk: 'artbeat_sponsorship_art_walk_monthly',
  };

  final InAppPurchaseManager _purchaseManager;

  Future<SponsorshipCheckoutResult> startRecurringCheckout({
    required SponsorshipTier tier,
    required String businessName,
    required String contactEmail,
  }) async {
    final plan = _resolvePlan(tier);
    final checkoutId = 'sponsor_${DateTime.now().millisecondsSinceEpoch}';

    if (!_purchaseManager.isInitialized) {
      final initialized = await _purchaseManager.initialize();
      if (!initialized) {
        throw Exception('In-app purchases are not available right now.');
      }
    }

    final completion = _waitForPurchase(
      productId: plan.productId,
      checkoutId: checkoutId,
    );

    final started = await _purchaseManager.purchaseProduct(
      plan.productId,
      metadata: <String, dynamic>{
        'checkoutId': checkoutId,
        'module': 'sponsorships',
        'productFamily': 'sponsorship',
        'sponsorshipTier': tier.value,
        'businessName': businessName.trim(),
        'contactEmail': contactEmail.trim(),
      },
    );

    if (!started) {
      throw Exception('The store did not start the sponsorship purchase.');
    }

    final purchase = await completion;
    return SponsorshipCheckoutResult(
      productId: plan.productId,
      status: purchase.status,
      purchaseId: purchase.purchaseId,
      transactionId: purchase.transactionId,
      amount: purchase.amount,
      currency: purchase.currency,
      rawPurchase: purchase,
    );
  }

  Future<CompletedPurchase> _waitForPurchase({
    required String productId,
    required String checkoutId,
  }) {
    late final StreamSubscription<PurchaseEvent> subscription;
    final completer = Completer<CompletedPurchase>();

    subscription = _purchaseManager.purchaseEventStream.listen((event) {
      if (event.type == PurchaseEventType.error && !completer.isCompleted) {
        completer.completeError(
          Exception(event.error ?? 'Sponsorship purchase failed.'),
        );
        return;
      }

      if (event.type == PurchaseEventType.cancelled &&
          event.productId == productId &&
          !completer.isCompleted) {
        completer.completeError(Exception('Sponsorship purchase cancelled.'));
        return;
      }

      final purchase = event.purchase;
      if (event.type == PurchaseEventType.completed &&
          purchase != null &&
          purchase.productId == productId &&
          purchase.metadata['checkoutId'] == checkoutId &&
          !completer.isCompleted) {
        completer.complete(purchase);
      }
    });

    return completer.future
        .timeout(
          _purchaseTimeout,
          onTimeout: () => throw TimeoutException(
            'Timed out waiting for sponsorship purchase confirmation.',
            _purchaseTimeout,
          ),
        )
        .whenComplete(subscription.cancel);
  }

  SponsorshipIapPlan _resolvePlan(SponsorshipTier tier) {
    final productId = _productIds[tier];
    if (productId == null || productId.isEmpty) {
      throw Exception('Sponsorship product is not configured for ${tier.value}.');
    }
    return SponsorshipIapPlan(productId: productId);
  }
}
