import 'dart:async';
import '../models/in_app_purchase_models.dart';
import '../models/subscription_tier.dart';
import '../utils/logger.dart';
import 'in_app_purchase_service.dart';
import 'in_app_ad_service.dart';
import 'payment_strategy_service.dart';

/// Main manager for coordinating all in-app purchase services
class InAppPurchaseManager {
  static final InAppPurchaseManager _instance =
      InAppPurchaseManager._internal();
  factory InAppPurchaseManager() => _instance;
  InAppPurchaseManager._internal();

  final InAppPurchaseService _purchaseService = InAppPurchaseService();
  final InAppAdService _adService = InAppAdService();
  final PaymentStrategyService _paymentStrategy = PaymentStrategyService();

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
      AppLogger.info('🎉 InAppPurchaseManager._handlePurchaseCompleted called');
      AppLogger.info('🎉 Purchase completed: ${purchase.productId}');
      AppLogger.info('🎉 Purchase category: ${purchase.category}');
      AppLogger.info('🎉 Purchase metadata: ${purchase.metadata}');

      // Process purchase based on category
      switch (purchase.category) {
        case PurchaseCategory.subscription:
          _handleSubscriptionPurchase(purchase);
          break;
        case PurchaseCategory.boosts:
          AppLogger.warning(
            'Retired boost purchase ignored: ${purchase.productId}',
          );
          break;
        case PurchaseCategory.ads:
          _handleAdPurchase(purchase);
          break;
        case PurchaseCategory.sponsorships:
          _handleSponsorshipPurchase(purchase);
          break;
        case PurchaseCategory.eventSubmissions:
          _handleEventSubmissionPurchase(purchase);
          break;
        case PurchaseCategory.premium:
          _handlePremiumPurchase(purchase);
          break;
      }

      // Emit purchase event
      AppLogger.info('📡 Emitting purchase event to stream...');
      _purchaseEventController?.add(
        PurchaseEvent(type: PurchaseEventType.completed, purchase: purchase),
      );
      AppLogger.info('✅ Purchase event emitted');
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
    AppLogger.info(
      '✅ IAP subscription completion event received; backend activation owns entitlement for ${purchase.productId}',
    );
  }

  /// Handle ad purchase
  void _handleAdPurchase(CompletedPurchase purchase) {
    _adService.logLegacyAdPurchaseAttempt(purchase.productId);
  }

  void _handleSponsorshipPurchase(CompletedPurchase purchase) {
    AppLogger.info(
      '✅ Sponsorship purchase completed for review workflow: ${purchase.productId}',
    );
  }

  void _handleEventSubmissionPurchase(CompletedPurchase purchase) {
    AppLogger.info(
      '✅ Event submission purchase completed for review workflow: ${purchase.productId}',
    );
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
    AppLogger.warning('App subscriptions are retired in the lean app.');
    return Future.value(false);
  }

  Future<bool> cancelSubscription(String subscriptionId) {
    AppLogger.warning('App subscriptions are retired in the lean app.');
    return Future.value(false);
  }

  Future<Map<String, dynamic>> getUserSubscriptionStatus(String userId) {
    return Future.value(<String, dynamic>{'active': false});
  }

  Future<bool> canAccessFeature(String userId, String feature) {
    return Future.value(true);
  }

  List<Map<String, dynamic>> getAllSubscriptionPricing() {
    return const <Map<String, dynamic>>[];
  }

  Future<bool> purchaseBoost({
    required String recipientId,
    required String boostProductId,
    required String message,
    Map<String, dynamic>? metadata,
  }) {
    AppLogger.warning('Boost purchases are retired in the lean app.');
    return Future.value(false);
  }

  List<Map<String, dynamic>> getAvailableBoosts() {
    return const <Map<String, dynamic>>[];
  }

  Future<List<ArtistBoostPurchase>> getSentBoosts(String userId) {
    return Future.value(const <ArtistBoostPurchase>[]);
  }

  Future<List<ArtistBoostPurchase>> getReceivedBoosts(String userId) {
    return Future.value(const <ArtistBoostPurchase>[]);
  }

  Future<int> getBoostCreditsBalance(String userId) {
    return Future.value(0);
  }

  Future<bool> useBoostCredits(String userId, int amount) {
    return Future.value(false);
  }

  Future<Map<String, dynamic>> getBoostStatistics(String userId) {
    return Future.value(const <String, dynamic>{});
  }

  // Ad methods
  List<Map<String, dynamic>> getAvailableAdPackages() {
    return _adService.getAvailableAdPackages();
  }

  Future<bool> purchaseProduct(
    String productId, {
    Map<String, dynamic>? metadata,
  }) {
    return _purchaseService.purchaseProduct(productId, metadata: metadata);
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
