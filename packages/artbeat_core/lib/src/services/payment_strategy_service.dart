import 'package:artbeat_core/src/models/in_app_purchase_models.dart';
import 'package:artbeat_core/src/models/subscription_tier.dart';

/// Enum for different ARTbeat modules
enum ArtbeatModule {
  core, // artbeat_core - subscriptions, AI credits
  artist, // artbeat_artist - payouts, commissions
  ads, // artbeat_ads - advertising
  events, // artbeat_events - ticketing
  messaging, // artbeat_messaging - gifts, chat perks
  capture, // artbeat_capture - premium features
  artWalk, // artbeat_art_walk - premium features
  profile, // artbeat_profile - customization
  settings, // artbeat_settings - premium settings
}

/// Enum for payment methods
enum PaymentMethod {
  iap, // In-App Purchase (Apple/Google)
  stripe, // Stripe payment processing
}

/// Payment strategy service that routes payments to appropriate providers
/// based on ARTbeat's hybrid payment model
class PaymentStrategyService {
  static final PaymentStrategyService _instance =
      PaymentStrategyService._internal();
  factory PaymentStrategyService() => _instance;
  PaymentStrategyService._internal();

  static const List<PurchaseType> _allPurchaseTypes = PurchaseType.values;

  // Canonical source-of-truth routing table for IAP vs Stripe by module and purchase type.
  static final Map<ArtbeatModule, Map<PurchaseType, PaymentMethod>>
  _policyTable = {
    ArtbeatModule.core: {
      PurchaseType.subscription: PaymentMethod.iap,
      PurchaseType.consumable: PaymentMethod.iap,
      PurchaseType.nonConsumable: PaymentMethod.iap,
    },
    ArtbeatModule.artist: {
      PurchaseType.subscription: PaymentMethod.stripe,
      PurchaseType.consumable: PaymentMethod.stripe,
      PurchaseType.nonConsumable: PaymentMethod.stripe,
    },
    ArtbeatModule.ads: {
      PurchaseType.subscription: PaymentMethod.iap,
      PurchaseType.consumable: PaymentMethod.iap,
      PurchaseType.nonConsumable: PaymentMethod.iap,
    },
    ArtbeatModule.events: {
      PurchaseType.subscription: PaymentMethod.stripe,
      PurchaseType.consumable: PaymentMethod.stripe,
      PurchaseType.nonConsumable: PaymentMethod.stripe,
    },
    ArtbeatModule.messaging: {
      PurchaseType.subscription: PaymentMethod.iap,
      PurchaseType.consumable: PaymentMethod.iap,
      PurchaseType.nonConsumable: PaymentMethod.iap,
    },
    ArtbeatModule.capture: {
      PurchaseType.subscription: PaymentMethod.iap,
      PurchaseType.consumable: PaymentMethod.iap,
      PurchaseType.nonConsumable: PaymentMethod.iap,
    },
    ArtbeatModule.artWalk: {
      PurchaseType.subscription: PaymentMethod.iap,
      PurchaseType.consumable: PaymentMethod.iap,
      PurchaseType.nonConsumable: PaymentMethod.iap,
    },
    ArtbeatModule.profile: {
      PurchaseType.subscription: PaymentMethod.iap,
      PurchaseType.consumable: PaymentMethod.iap,
      PurchaseType.nonConsumable: PaymentMethod.iap,
    },
    ArtbeatModule.settings: {
      PurchaseType.subscription: PaymentMethod.iap,
      PurchaseType.consumable: PaymentMethod.iap,
      PurchaseType.nonConsumable: PaymentMethod.iap,
    },
  };

  /// Get the appropriate payment method for a purchase type in a specific module
  PaymentMethod getPaymentMethod(
    PurchaseType purchaseType,
    ArtbeatModule module,
  ) {
    final modulePolicy = _policyTable[module];
    if (modulePolicy == null) {
      throw StateError('Missing payment policy for module: $module');
    }
    final method = modulePolicy[purchaseType];
    if (method == null) {
      throw StateError(
        'Missing payment policy for module: $module and purchaseType: $purchaseType',
      );
    }
    return method;
  }

  /// Check if a purchase requires payout processing
  bool requiresPayout(ArtbeatModule module, PurchaseType purchaseType) {
    final method = getPaymentMethod(purchaseType, module);
    return method == PaymentMethod.stripe;
  }

  /// Get payment method for subscription tier upgrades
  PaymentMethod getSubscriptionPaymentMethod(SubscriptionTier tier) {
    // All subscriptions must use IAP per App Store rules
    return PaymentMethod.iap;
  }

  /// Validate payment method for a specific use case
  bool isValidPaymentMethod(
    PaymentMethod method,
    PurchaseType purchaseType,
    ArtbeatModule module,
  ) {
    final requiredMethod = getPaymentMethod(purchaseType, module);
    return method == requiredMethod;
  }

  /// Get human-readable explanation for payment method choice
  String getPaymentMethodExplanation(
    PaymentMethod method,
    PurchaseType purchaseType,
    ArtbeatModule module,
  ) {
    if (method == PaymentMethod.iap) {
      switch (purchaseType) {
        case PurchaseType.subscription:
          return 'Subscriptions use In-App Purchases to comply with App Store policies';
        case PurchaseType.consumable:
          return 'Digital items use In-App Purchases for secure processing';
        case PurchaseType.nonConsumable:
          return 'Premium features use In-App Purchases for one-time unlocks';
      }
    } else {
      return 'This purchase requires Stripe for payout processing to artists/organizers';
    }
  }

  /// Exposes the canonical policy table for tests and diagnostics.
  Map<ArtbeatModule, Map<PurchaseType, PaymentMethod>> getPolicyTable() {
    return _policyTable.map(
      (module, policy) => MapEntry(
        module,
        policy.map((type, method) => MapEntry(type, method)),
      ),
    );
  }

  /// Validates every module has a policy for every purchase type.
  bool hasCompletePolicyCoverage() {
    for (final module in ArtbeatModule.values) {
      final policy = _policyTable[module];
      if (policy == null) return false;
      for (final type in _allPurchaseTypes) {
        if (!policy.containsKey(type)) return false;
      }
    }
    return true;
  }
}
