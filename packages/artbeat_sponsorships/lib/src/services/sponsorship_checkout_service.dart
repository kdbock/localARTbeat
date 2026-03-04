import 'dart:convert';

import 'package:artbeat_core/artbeat_core.dart';

import '../models/sponsorship_tier.dart';

class SponsorshipStripePlan {
  const SponsorshipStripePlan({required this.productId, required this.priceId});

  final String productId;
  final String priceId;
}

class SponsorshipCheckoutResult {
  const SponsorshipCheckoutResult({
    required this.customerId,
    required this.subscriptionId,
    required this.priceId,
    required this.productId,
    this.status,
    this.rawResponse,
  });

  final String customerId;
  final String subscriptionId;
  final String priceId;
  final String productId;
  final String? status;
  final Map<String, dynamic>? rawResponse;
}

class SponsorshipCheckoutService {
  SponsorshipCheckoutService({UnifiedPaymentService? paymentService})
    : _paymentService = paymentService ?? UnifiedPaymentService();

  final UnifiedPaymentService _paymentService;

  static const Map<SponsorshipTier, SponsorshipStripePlan> _fallbackPlans = {
    SponsorshipTier.artWalk: SponsorshipStripePlan(
      productId: 'prod_sponsorship_art_walk_2026',
      priceId: 'price_sponsorship_art_walk_monthly_2026',
    ),
    SponsorshipTier.capture: SponsorshipStripePlan(
      productId: 'prod_sponsorship_capture_2026',
      priceId: 'price_sponsorship_capture_monthly_2026',
    ),
    SponsorshipTier.discover: SponsorshipStripePlan(
      productId: 'prod_sponsorship_discovery_2026',
      priceId: 'price_sponsorship_discovery_monthly_2026',
    ),
  };

  Future<SponsorshipCheckoutResult> startRecurringCheckout({
    required SponsorshipTier tier,
    required String businessName,
    required String contactEmail,
  }) async {
    final plan = _resolvePlan(tier);
    final customerId = await _paymentService.getOrCreateCustomerId();
    final setupIntentSecret = await _paymentService.createSetupIntent(
      customerId,
    );

    await _paymentService.setupPaymentSheet(
      customerId: customerId,
      setupIntentClientSecret: setupIntentSecret,
    );
    await _paymentService.safelyPresentPaymentSheet(
      operationName: 'sponsorship_${tier.value}_setup',
    );

    var paymentMethodId = await _paymentService.getDefaultPaymentMethodId();
    if (paymentMethodId == null) {
      final methods = await _paymentService.getPaymentMethods(customerId);
      if (methods.isNotEmpty) {
        paymentMethodId = methods.first.id;
      }
    }
    if (paymentMethodId == null) {
      throw Exception('No payment method found after setup');
    }

    final response = await _paymentService.makeAuthenticatedRequest(
      functionKey: 'createSubscription',
      body: {
        'customerId': customerId,
        'priceId': plan.priceId,
        'productId': plan.productId,
        'paymentMethodId': paymentMethodId,
        'sponsorshipType': tier.value,
        'metadata': {
          'module': 'sponsorships',
          'businessName': businessName,
          'contactEmail': contactEmail,
        },
      },
    );

    if (response.statusCode != 200) {
      String message = 'Failed to create sponsorship subscription';
      try {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        message = (decoded['error'] as String?) ?? message;
      } on Exception {
        // Keep fallback message if response is not JSON.
      }
      throw Exception(message);
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final subscriptionId =
        (data['subscriptionId'] as String?) ??
        (data['id'] as String?) ??
        (data['stripeSubscriptionId'] as String?) ??
        '';
    if (subscriptionId.isEmpty) {
      throw Exception('Subscription created but no subscription ID returned');
    }

    return SponsorshipCheckoutResult(
      customerId: customerId,
      subscriptionId: subscriptionId,
      priceId: plan.priceId,
      productId: plan.productId,
      status: data['status'] as String?,
      rawResponse: data,
    );
  }

  SponsorshipStripePlan _resolvePlan(SponsorshipTier tier) {
    final env = EnvLoader();
    final product = env.get(_productEnvKey(tier));
    final price = env.get(_priceEnvKey(tier));
    if (product.isNotEmpty && price.isNotEmpty) {
      return SponsorshipStripePlan(productId: product, priceId: price);
    }

    final fallback = _fallbackPlans[tier];
    if (fallback == null) {
      throw Exception('No Stripe plan configured for tier: ${tier.value}');
    }
    return fallback;
  }

  String _productEnvKey(SponsorshipTier tier) {
    switch (tier) {
      case SponsorshipTier.artWalk:
        return 'STRIPE_PRODUCT_SPONSORSHIP_ART_WALK';
      case SponsorshipTier.capture:
        return 'STRIPE_PRODUCT_SPONSORSHIP_CAPTURE';
      case SponsorshipTier.discover:
        return 'STRIPE_PRODUCT_SPONSORSHIP_DISCOVERY';
    }
  }

  String _priceEnvKey(SponsorshipTier tier) {
    switch (tier) {
      case SponsorshipTier.artWalk:
        return 'STRIPE_PRICE_SPONSORSHIP_ART_WALK_MONTHLY';
      case SponsorshipTier.capture:
        return 'STRIPE_PRICE_SPONSORSHIP_CAPTURE_MONTHLY';
      case SponsorshipTier.discover:
        return 'STRIPE_PRICE_SPONSORSHIP_DISCOVERY_MONTHLY';
    }
  }
}
