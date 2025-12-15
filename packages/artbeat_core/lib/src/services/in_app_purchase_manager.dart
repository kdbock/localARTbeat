import 'dart:async';
import '../models/in_app_purchase_models.dart';
import '../models/subscription_tier.dart';
import '../utils/logger.dart';
import 'in_app_purchase_service.dart';
import 'in_app_subscription_service.dart';
import 'in_app_gift_service.dart';
import 'in_app_ad_service.dart';
import 'payment_strategy_service.dart';
import 'subscription_service.dart';

/// Main manager for coordinating all in-app purchase services
class InAppPurchaseManager {
  static final InAppPurchaseManager _instance =
      InAppPurchaseManager._internal();
  factory InAppPurchaseManager() => _instance;
  InAppPurchaseManager._internal();

  final InAppPurchaseService _purchaseService = InAppPurchaseService();
  final InAppSubscriptionService _subscriptionService =
      InAppSubscriptionService();
  final InAppGiftService _giftService = InAppGiftService();
  final InAppAdService _adService = InAppAdService();
  final PaymentStrategyService _paymentStrategy = PaymentStrategyService();
  final SubscriptionService _coreSubscriptionService = SubscriptionService();

  bool _isInitialized = false;
  StreamController<PurchaseEvent>? _purchaseEventController;

  /// Initialize all in-app purchase services
  Future<bool> initialize() async {
    try {
      if (_isInitialized) {
        AppLogger.info('In-app purchase manager already initialized');
        return true;
      }

      AppLogger.info('🚀 Initializing in-app purchase manager...');

      // Initialize the main purchase service
      final success = await _purchaseService.initialize();
      if (!success) {
        AppLogger.error('❌ Failed to initialize in-app purchase service');
        return false;
      }

      // Set up purchase event stream
      _purchaseEventController = StreamController<PurchaseEvent>.broadcast();

      // Set up purchase callbacks
      _purchaseService.onPurchaseCompleted = _handlePurchaseCompleted;
      _purchaseService.onPurchaseError = _handlePurchaseError;
      _purchaseService.onPurchaseCancelled = _handlePurchaseCancelled;

      _isInitialized = true;
      AppLogger.info('✅ In-app purchase manager initialized successfully');
      return true;
    } catch (e) {
      AppLogger.error('❌ Failed to initialize in-app purchase manager: $e');
      return false;
    }
  }

  /// Handle completed purchase
  void _handlePurchaseCompleted(CompletedPurchase purchase) {
    try {
      AppLogger.info('🎉 Purchase completed: ${purchase.productId}');

      // Process purchase based on category
      switch (purchase.category) {
        case PurchaseCategory.subscription:
          _handleSubscriptionPurchase(purchase);
          break;
        case PurchaseCategory.gifts:
          _handleGiftPurchase(purchase);
          break;
        case PurchaseCategory.ads:
          _handleAdPurchase(purchase);
          break;
        case PurchaseCategory.premium:
          _handlePremiumPurchase(purchase);
          break;
      }

      // Emit purchase event
      _purchaseEventController?.add(
        PurchaseEvent(type: PurchaseEventType.completed, purchase: purchase),
      );
    } catch (e) {
      AppLogger.error('Error handling completed purchase: $e');
    }
  }

  /// Handle purchase error
  void _handlePurchaseError(String error) {
    AppLogger.error('❌ Purchase error: $error');
    _purchaseEventController?.add(
      PurchaseEvent(type: PurchaseEventType.error, error: error),
    );
  }

  /// Handle purchase cancellation
  void _handlePurchaseCancelled(String productId) {
    AppLogger.info('❌ Purchase cancelled: $productId');
    _purchaseEventController?.add(
      PurchaseEvent(type: PurchaseEventType.cancelled, productId: productId),
    );
  }

  /// Handle subscription purchase
  void _handleSubscriptionPurchase(CompletedPurchase purchase) {
    // Map product ID to subscription tier
    final tier = _getTierFromProductId(purchase.productId);
    if (tier != null) {
      // Update user's subscription tier in their artist profile
      _coreSubscriptionService.updateUserSubscriptionTier(tier);
      AppLogger.info(
        '✅ Subscription purchase processed: ${purchase.productId} -> ${tier.displayName}',
      );
    } else {
      AppLogger.error(
        '❌ Unknown subscription product ID: ${purchase.productId}',
      );
    }
  }

  /// Map product ID to subscription tier
  SubscriptionTier? _getTierFromProductId(String productId) {
    switch (productId) {
      case 'artbeat_starter_monthly':
      case 'artbeat_starter_yearly':
        return SubscriptionTier.starter;
      case 'artbeat_creator_monthly':
      case 'artbeat_creator_yearly':
        return SubscriptionTier.creator;
      case 'artbeat_business_monthly':
      case 'artbeat_business_yearly':
        return SubscriptionTier.business;
      case 'artbeat_enterprise_monthly':
      case 'artbeat_enterprise_yearly':
        return SubscriptionTier.enterprise;
      default:
        return null;
    }
  }

  /// Handle gift purchase
  void _handleGiftPurchase(CompletedPurchase purchase) {
    // Extract gift metadata
    final metadata = purchase.metadata;
    final recipientId = metadata['recipientId'] as String?;
    final message = metadata['message'] as String?;

    if (recipientId == null || recipientId.isEmpty) {
      AppLogger.error(
        '❌ Gift purchase missing recipientId: ${purchase.productId}',
      );
      AppLogger.error('Metadata: $metadata');
      return;
    }

    if (message == null || message.isEmpty) {
      AppLogger.warning(
        '⚠️ Gift purchase missing message, using default: ${purchase.productId}',
      );
    }

    try {
      _giftService.completeGiftPurchase(
        senderId: purchase.userId,
        recipientId: recipientId,
        productId: purchase.productId,
        transactionId: purchase.transactionId ?? purchase.purchaseId,
        message: message ?? 'A gift from an ArtBeat supporter!',
      );
      AppLogger.info('✅ Gift purchase completed successfully');
    } catch (e) {
      AppLogger.error('❌ Error completing gift purchase: $e');
    }
  }

  /// Handle ad purchase
  void _handleAdPurchase(CompletedPurchase purchase) {
    // Extract ad metadata
    final metadata = purchase.metadata;
    final artworkId = metadata['artworkId'] as String?;
    final targetingOptions =
        metadata['targetingOptions'] as Map<String, dynamic>?;

    if (artworkId != null && targetingOptions != null) {
      _adService.completeAdPurchase(
        userId: purchase.userId,
        productId: purchase.productId,
        transactionId: purchase.transactionId ?? purchase.purchaseId,
        artworkId: artworkId,
        targetingOptions: targetingOptions,
      );
    }
  }

  /// Handle premium purchase
  void _handlePremiumPurchase(CompletedPurchase purchase) {
    // Handle premium feature unlocks
    AppLogger.info('✅ Premium purchase processed: ${purchase.productId}');
  }

  // Subscription methods
  Future<bool> subscribeToTier(SubscriptionTier tier, {bool isYearly = false}) {
    // Check if IAP should be used for subscriptions
    final paymentMethod = _paymentStrategy.getSubscriptionPaymentMethod(tier);
    if (paymentMethod != PaymentMethod.iap) {
      AppLogger.warning(
        'Subscription tier $tier should use IAP but payment strategy returned $paymentMethod',
      );
      // For now, proceed with IAP as it's required by App Store
    }
    return _subscriptionService.subscribeToTier(tier, isYearly: isYearly);
  }

  Future<bool> cancelSubscription(String subscriptionId) {
    return _subscriptionService.cancelSubscription(subscriptionId);
  }

  Future<Map<String, dynamic>> getUserSubscriptionStatus(String userId) {
    return _subscriptionService.getUserSubscriptionStatus(userId);
  }

  Future<bool> canAccessFeature(String userId, String feature) {
    return _subscriptionService.canAccessFeature(userId, feature);
  }

  List<Map<String, dynamic>> getAllSubscriptionPricing() {
    return _subscriptionService.getAllSubscriptionPricing();
  }

  // Gift methods
  Future<bool> purchaseGift({
    required String recipientId,
    required String giftProductId,
    required String message,
    Map<String, dynamic>? metadata,
  }) {
    // Check if IAP should be used for gifts in messaging module
    final paymentMethod = _paymentStrategy.getPaymentMethod(
      PurchaseType.nonConsumable, // Gifts are typically non-consumable
      ArtbeatModule.messaging,
    );

    if (paymentMethod != PaymentMethod.iap) {
      AppLogger.warning(
        'Gift purchase should use $paymentMethod but IAP manager was called',
      );
      // For now, proceed with IAP for digital-only gifts
      // Stripe would be used for gifts that result in payouts
    }

    return _giftService.purchaseGift(
      recipientId: recipientId,
      giftProductId: giftProductId,
      message: message,
      metadata: metadata,
    );
  }

  List<Map<String, dynamic>> getAvailableGifts() {
    return _giftService.getAvailableGifts();
  }

  Future<List<InAppGiftPurchase>> getSentGifts(String userId) {
    return _giftService.getSentGifts(userId);
  }

  Future<List<InAppGiftPurchase>> getReceivedGifts(String userId) {
    return _giftService.getReceivedGifts(userId);
  }

  Future<int> getGiftCreditsBalance(String userId) {
    return _giftService.getGiftCreditsBalance(userId);
  }

  Future<bool> useGiftCredits(String userId, int amount) {
    return _giftService.useGiftCredits(userId, amount);
  }

  Future<Map<String, dynamic>> getGiftStatistics(String userId) {
    return _giftService.getGiftStatistics(userId);
  }

  // Ad methods
  Future<bool> purchaseAdPackage({
    required String adProductId,
    required String artworkId,
    required Map<String, dynamic> targetingOptions,
    Map<String, dynamic>? metadata,
  }) {
    // Check if IAP should be used for ads
    final paymentMethod = _paymentStrategy.getPaymentMethod(
      PurchaseType.nonConsumable, // Ad packages are typically non-consumable
      ArtbeatModule.ads,
    );

    if (paymentMethod != PaymentMethod.iap) {
      AppLogger.warning(
        'Ad purchase should use $paymentMethod but IAP manager was called',
      );
      // Ads must use Stripe per Apple policy - this IAP method should not be used for ads
      return Future.value(false);
    }

    return _adService.purchaseAdPackage(
      adProductId: adProductId,
      artworkId: artworkId,
      targetingOptions: targetingOptions,
      metadata: metadata,
    );
  }

  List<Map<String, dynamic>> getAvailableAdPackages() {
    return _adService.getAvailableAdPackages();
  }

  Future<List<InAppAdPurchase>> getUserAdPurchases(String userId) {
    return _adService.getUserAdPurchases(userId);
  }

  Future<List<Map<String, dynamic>>> getUserActiveCampaigns(String userId) {
    return _adService.getUserActiveCampaigns(userId);
  }

  Future<int> getAdCreditsBalance(String userId) {
    return _adService.getAdCreditsBalance(userId);
  }

  Future<bool> useAdCredits(String userId, int impressions) {
    return _adService.useAdCredits(userId, impressions);
  }

  Future<Map<String, dynamic>> getAdStatistics(String userId) {
    return _adService.getAdStatistics(userId);
  }

  Future<Map<String, dynamic>> getCampaignAnalytics(String campaignId) {
    return _adService.getCampaignAnalytics(campaignId);
  }

  // General methods
  Future<List<CompletedPurchase>> getUserPurchaseHistory(String userId) {
    return _purchaseService.getUserPurchaseHistory(userId);
  }

  Future<bool> hasActiveSubscription(String userId) {
    return _purchaseService.hasActiveSubscription(userId);
  }

  Future<SubscriptionTier> getUserSubscriptionTier(String userId) {
    return _purchaseService.getUserSubscriptionTier(userId);
  }

  /// Get purchase event stream
  Stream<PurchaseEvent> get purchaseEventStream {
    return _purchaseEventController?.stream ?? const Stream.empty();
  }

  /// Check if manager is initialized
  bool get isInitialized => _isInitialized;

  /// Check if in-app purchases are available
  bool get isAvailable => _purchaseService.isAvailable;

  /// Get the appropriate payment method for a purchase type in a specific module
  PaymentMethod getPaymentMethod(
    PurchaseType purchaseType,
    ArtbeatModule module,
  ) {
    return _paymentStrategy.getPaymentMethod(purchaseType, module);
  }

  /// Check if a purchase requires payout processing (should use Stripe)
  bool requiresPayout(ArtbeatModule module, PurchaseType purchaseType) {
    return _paymentStrategy.requiresPayout(module, purchaseType);
  }

  /// Dispose resources
  void dispose() {
    _purchaseService.dispose();
    _purchaseEventController?.close();
    _purchaseEventController = null;
    _isInitialized = false;
  }
}

/// Purchase event types
enum PurchaseEventType { completed, error, cancelled }

/// Purchase event model
class PurchaseEvent {
  final PurchaseEventType type;
  final CompletedPurchase? purchase;
  final String? error;
  final String? productId;

  PurchaseEvent({
    required this.type,
    this.purchase,
    this.error,
    this.productId,
  });
}
