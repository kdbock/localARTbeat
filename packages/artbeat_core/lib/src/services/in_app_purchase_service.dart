import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/in_app_purchase_models.dart';
import '../models/subscription_tier.dart';
import '../utils/logger.dart';
import 'purchase_verification_service.dart';

/// Service for handling in-app purchases across iOS and Android
class InAppPurchaseService {
  static final InAppPurchaseService _instance =
      InAppPurchaseService._internal();
  factory InAppPurchaseService() => _instance;
  InAppPurchaseService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];

  // Store pending purchase metadata (cleared after purchase completes)
  final Map<String, Map<String, dynamic>> _pendingPurchaseMetadata = {};

  // Product IDs for different purchase types
  static const Map<String, List<String>> _productIds = {
    'subscriptions': [
      'artbeat_starter_monthly',
      'artbeat_creator_monthly',
      'artbeat_business_monthly',
      'artbeat_enterprise_monthly',
      'artbeat_starter_yearly',
      'artbeat_creator_yearly',
      'artbeat_business_yearly',
      'artbeat_enterprise_yearly',
    ],
    'gifts': [
      'artbeat_gift_small', // Small Gift (50 Credits)
      'artbeat_gift_medium', // Medium Gift (100 Credits)
      'artbeat_gift_large', // Large Gift (250 Credits)
      'artbeat_gift_premium', // Premium Gift (500 Credits)
    ],
    'ads': [
      'ad_small_1w', // Small ad package - 1 week
      'ad_small_1m', // Small ad package - 1 month
      'ad_small_3m', // Small ad package - 3 months
      'ad_big_1w', // Big ad package - 1 week
      'ad_big_1m', // Big ad package - 1 month
      'ad_big_3m', // Big ad package - 3 months
    ],
  };

  // Callbacks for purchase events
  void Function(CompletedPurchase)? onPurchaseCompleted;
  void Function(String)? onPurchaseError;
  void Function(String)? onPurchaseCancelled;

  /// Initialize the in-app purchase service
  /// This method performs all necessary setup to prevent null PendingIntent crashes
  Future<bool> initialize() async {
    try {
      AppLogger.info('🔄 Initializing in-app purchase service...');

      // Check if in-app purchases are available on this device
      _isAvailable = await _inAppPurchase.isAvailable();

      if (!_isAvailable) {
        AppLogger.warning('⚠️ In-app purchases not available on this device');
        return false;
      }

      AppLogger.info('✅ In-app purchases are available on this device');

      // Set up purchase listener before any purchase operations
      try {
        final Stream<List<PurchaseDetails>> purchaseUpdated =
            _inAppPurchase.purchaseStream;
        _subscription = purchaseUpdated.listen(
          _onPurchaseUpdate,
          onDone: () => _subscription?.cancel(),
          onError: (Object error) {
            AppLogger.error('❌ Purchase stream error: $error');
            // Don't crash on stream errors - these can be recovered
          },
        );
        AppLogger.info('✅ Purchase stream listener registered');
      } catch (e) {
        AppLogger.error('⚠️ Failed to register purchase listener: $e');
        // Continue even if listener fails - purchases might still work
      }

      // Load products from store
      try {
        await _loadProducts();
        AppLogger.info('✅ Products loaded from store');
      } catch (e) {
        AppLogger.error('⚠️ Failed to load products: $e');
        // Continue - user can still attempt purchases if products exist
      }

      // Restore any previously purchased items
      try {
        await _restorePurchases();
        AppLogger.info('✅ Previous purchases restored');
      } catch (e) {
        AppLogger.error('⚠️ Failed to restore purchases: $e');
        // This is non-critical
      }

      AppLogger.info('✅ In-app purchase service initialized successfully');
      return true;
    } catch (e) {
      AppLogger.error(
        '❌ Failed to initialize in-app purchase service: $e',
        error: e,
      );
      // Return false but don't crash - the app can continue without IAP
      return false;
    }
  }

  /// Load available products from the stores
  Future<void> _loadProducts() async {
    try {
      final Set<String> allProductIds = {};
      _productIds.values.forEach((ids) => allProductIds.addAll(ids));

      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(allProductIds);

      if (response.error != null) {
        AppLogger.error('Error loading products: ${response.error}');
        return;
      }

      _products = response.productDetails;
      AppLogger.info('✅ Loaded ${_products.length} products');

      for (final product in _products) {
        AppLogger.info(
          'Product: ${product.id} - ${product.title} - ${product.price}',
        );
      }
    } catch (e) {
      AppLogger.error('Error loading products: $e');
    }
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    if (kDebugMode) {
      print(
      '🔔 _onPurchaseUpdate called with ${purchaseDetailsList.length} purchases',
    );
    }
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (kDebugMode) {
        print(
        '   - Product: ${purchaseDetails.productID}, Status: ${purchaseDetails.status}',
      );
      }
      _handlePurchaseUpdate(purchaseDetails);
    }
  }

  /// Handle individual purchase update
  Future<void> _handlePurchaseUpdate(PurchaseDetails purchaseDetails) async {
    try {
      if (kDebugMode) {
        print('📦 Handling purchase update for ${purchaseDetails.productID}');
      }
      if (kDebugMode) {
        print('   Status: ${purchaseDetails.status}');
      }

      AppLogger.info(
        'Purchase update: ${purchaseDetails.productID} - ${purchaseDetails.status}',
      );

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          if (kDebugMode) {
            print('⏳ Purchase PENDING: ${purchaseDetails.productID}');
          }
          AppLogger.info('Purchase pending: ${purchaseDetails.productID}');
          break;

        case PurchaseStatus.purchased:
          if (kDebugMode) {
            print('✅ Purchase PURCHASED: ${purchaseDetails.productID}');
          }
          await _handleSuccessfulPurchase(purchaseDetails);
          break;

        case PurchaseStatus.error:
          if (kDebugMode) {
            print('❌ Purchase ERROR: ${purchaseDetails.error}');
          }
          AppLogger.error('Purchase error: ${purchaseDetails.error}');
          onPurchaseError?.call(
            purchaseDetails.error?.message ?? 'Unknown error',
          );
          // Clear pending metadata on error
          _pendingPurchaseMetadata.remove(purchaseDetails.productID);
          break;

        case PurchaseStatus.canceled:
          if (kDebugMode) {
            print('🚫 Purchase CANCELED: ${purchaseDetails.productID}');
          }
          AppLogger.info('Purchase cancelled: ${purchaseDetails.productID}');
          onPurchaseCancelled?.call(purchaseDetails.productID);
          // Clear pending metadata on cancellation
          _pendingPurchaseMetadata.remove(purchaseDetails.productID);
          break;

        case PurchaseStatus.restored:
          if (kDebugMode) {
            print('🔄 Purchase RESTORED: ${purchaseDetails.productID}');
          }
          await _handleRestoredPurchase(purchaseDetails);
          break;
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        if (kDebugMode) {
          print('✔️ Completing purchase for ${purchaseDetails.productID}');
        }
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error handling purchase update: ${e.toString()}');
      }
      AppLogger.error('Error handling purchase update: ${e.toString()}');
    }
  }

  /// Handle successful purchase
  Future<void> _handleSuccessfulPurchase(
    PurchaseDetails purchaseDetails,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.error('User not authenticated for purchase');
        return;
      }

      // Verify purchase with server (important for security)
      final isValid = await _verifyPurchase(purchaseDetails);
      if (!isValid) {
        AppLogger.error('Purchase verification failed');
        return;
      }

      // Determine purchase type and category
      final purchaseType = _getPurchaseType(purchaseDetails.productID);
      final purchaseCategory = _getPurchaseCategory(purchaseDetails.productID);
      final product = _getProductDetails(purchaseDetails.productID);

      if (product == null) {
        AppLogger.error('Product not found: ${purchaseDetails.productID}');
        return;
      }

      // Retrieve pending purchase metadata
      final pendingMetadata =
          _pendingPurchaseMetadata[purchaseDetails.productID] ?? {};

      // Create completed purchase record
      final completedPurchase = CompletedPurchase(
        purchaseId:
            purchaseDetails.purchaseID ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        productId: purchaseDetails.productID,
        userId: user.uid,
        purchaseDate: DateTime.now(),
        status: 'completed',
        type: purchaseType,
        category: purchaseCategory,
        amount: _getProductPrice(product),
        currency: _getProductCurrency(product),
        transactionId: purchaseDetails.purchaseID,
        metadata: {
          'platform': Platform.isIOS ? 'ios' : 'android',
          'verificationData':
              purchaseDetails.verificationData.localVerificationData,
          ...pendingMetadata, // Include stored metadata
        },
      );

      // Save to Firestore
      await _savePurchaseToFirestore(completedPurchase);

      // Handle specific purchase types
      await _processPurchaseByType(completedPurchase, purchaseDetails);

      // Notify listeners
      onPurchaseCompleted?.call(completedPurchase);

      // Clear pending metadata after successful purchase
      _pendingPurchaseMetadata.remove(purchaseDetails.productID);

      AppLogger.info(
        '✅ Purchase completed successfully: ${purchaseDetails.productID}',
      );
    } catch (e) {
      AppLogger.error('Error handling successful purchase: $e');
    }
  }

  /// Handle restored purchase
  Future<void> _handleRestoredPurchase(PurchaseDetails purchaseDetails) async {
    try {
      if (kDebugMode) {
        print('🔄 Processing restored purchase: ${purchaseDetails.productID}');
      }

      final purchaseType = _getPurchaseType(purchaseDetails.productID);

      if (purchaseType == PurchaseType.consumable) {
        if (kDebugMode) {
          print(
          '🎁 Consumable restored - this should not happen for consumables',
        );
        }
        if (kDebugMode) {
          print(
          '   Consumables are one-time purchases and should not be restored',
        );
        }

        // In debug mode, treat restored consumables as successful for testing
        // This handles the case where IAP dialogs don't work on simulators
        if (_isDebugMode() && _isGiftProduct(purchaseDetails.productID)) {
          if (kDebugMode) {
            print(
            '🐛 DEBUG MODE: Treating restored consumable as successful purchase',
          );
          }
          await _handleSuccessfulPurchase(purchaseDetails);
          return;
        }

        if (kDebugMode) {
          print('   Ignoring this restored consumable purchase');
        }
        // Do not process consumables as successful on restore
        return;
      }

      if (kDebugMode) {
        print('📦 Non-consumable restored purchase - restoring benefits');
      }
      // For non-consumable and subscription purchases, restore the benefits
      await _handleSuccessfulPurchase(purchaseDetails);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling restored purchase: $e');
      }
      AppLogger.error('Error handling restored purchase: $e');
    }
  }

  /// Verify purchase with server (implement server-side verification)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      // Determine platform and verify accordingly
      if (Platform.isAndroid) {
        // Android: Use Google Play Developer API
        // Extract purchase token from verification data
        final verificationData = purchaseDetails.verificationData;
        final purchaseToken = _extractPurchaseTokenFromVerificationData(
          verificationData.localVerificationData,
        );

        return await PurchaseVerificationService.verifyGooglePlayPurchase(
          packageName: 'com.wordnerd.artbeat', // Your app package name
          productId: purchaseDetails.productID,
          purchaseToken: purchaseToken,
        );
      } else if (Platform.isIOS) {
        // iOS: Use App Store verification
        final user = _auth.currentUser;
        if (user == null) {
          AppLogger.error(
            'User not authenticated for iOS purchase verification',
          );
          return false;
        }

        return await PurchaseVerificationService.verifyAppStorePurchase(
          receiptData: purchaseDetails.verificationData.localVerificationData,
          productId: purchaseDetails.productID,
          userId: user.uid,
        );
      } else {
        AppLogger.warning(
          '⚠️ Purchase verification not supported on this platform',
        );
        return false;
      }
    } catch (e) {
      AppLogger.error('Error verifying purchase: $e');
      return false;
    }
  }

  /// Save purchase to Firestore
  Future<void> _savePurchaseToFirestore(CompletedPurchase purchase) async {
    try {
      await _firestore
          .collection('purchases')
          .doc(purchase.purchaseId)
          .set(purchase.toFirestore());

      AppLogger.info('✅ Purchase saved to Firestore: ${purchase.purchaseId}');
    } catch (e) {
      AppLogger.error('Error saving purchase to Firestore: $e');
    }
  }

  /// Process purchase based on type
  Future<void> _processPurchaseByType(
    CompletedPurchase purchase,
    PurchaseDetails details,
  ) async {
    switch (purchase.category) {
      case PurchaseCategory.subscription:
        await _processSubscriptionPurchase(purchase, details);
        break;
      case PurchaseCategory.gifts:
        await _processGiftPurchase(purchase, details);
        break;
      case PurchaseCategory.ads:
        await _processAdPurchase(purchase, details);
        break;
      case PurchaseCategory.premium:
        await _processPremiumPurchase(purchase, details);
        break;
    }
  }

  /// Process subscription purchase
  Future<void> _processSubscriptionPurchase(
    CompletedPurchase purchase,
    PurchaseDetails details,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Determine subscription tier from product ID
      final tier = _getSubscriptionTierFromProductId(purchase.productId);
      final isYearly = purchase.productId.contains('yearly');

      // Calculate expiry date
      final expiryDate = DateTime.now().add(
        isYearly ? const Duration(days: 365) : const Duration(days: 30),
      );

      // Create subscription details
      final subscription = SubscriptionDetails(
        subscriptionId: purchase.purchaseId,
        productId: purchase.productId,
        userId: user.uid,
        startDate: purchase.purchaseDate,
        endDate: expiryDate,
        status: 'active',
        autoRenewing: true,
        price: purchase.amount,
        currency: purchase.currency,
        nextBillingDate: expiryDate,
      );

      // Save subscription
      await _firestore
          .collection('subscriptions')
          .doc(subscription.subscriptionId)
          .set(subscription.toFirestore());

      // Update user's subscription tier
      await _firestore.collection('users').doc(user.uid).update({
        'subscriptionTier': tier.apiName,
        'subscriptionStatus': 'active',
        'subscriptionExpiryDate': Timestamp.fromDate(expiryDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Subscription processed: ${tier.displayName}');
    } catch (e) {
      AppLogger.error('Error processing subscription purchase: $e');
    }
  }

  /// Process gift purchase
  Future<void> _processGiftPurchase(
    CompletedPurchase purchase,
    PurchaseDetails details,
  ) async {
    try {
      // Gift processing will be handled by the gift service
      // This is just to record the purchase
      AppLogger.info('✅ Gift purchase processed: ${purchase.productId}');
    } catch (e) {
      AppLogger.error('Error processing gift purchase: $e');
    }
  }

  /// Process ad purchase
  Future<void> _processAdPurchase(
    CompletedPurchase purchase,
    PurchaseDetails details,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Determine ad credits based on product
      final adCredits = _getAdCreditsFromProductId(purchase.productId);

      // Add ad credits to user account
      await _firestore.collection('users').doc(user.uid).update({
        'adCredits': FieldValue.increment(adCredits),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Ad purchase processed: $adCredits credits added');
    } catch (e) {
      AppLogger.error('Error processing ad purchase: $e');
    }
  }

  /// Process premium purchase
  Future<void> _processPremiumPurchase(
    CompletedPurchase purchase,
    PurchaseDetails details,
  ) async {
    try {
      // Handle premium feature unlocks
      AppLogger.info('✅ Premium purchase processed: ${purchase.productId}');
    } catch (e) {
      AppLogger.error('Error processing premium purchase: $e');
    }
  }

  /// Purchase a product
  Future<bool> purchaseProduct(
    String productId, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.info('🛍️ Starting purchase flow for product: $productId');

      // Validate in-app purchase is available
      if (!_isAvailable) {
        AppLogger.error('❌ In-app purchases not available on this device');
        AppLogger.info('Available products: ${_products.length}');
        throw Exception('In-app purchases are not available on this device');
      }

      // Validate product exists and is loaded
      final product = _getProductDetails(productId);
      if (product == null) {
        AppLogger.error('❌ Product not found: $productId');
        AppLogger.info(
          'Available products: ${_products.map((p) => p.id).join(", ")}',
        );
        throw Exception(
          'Product "$productId" not found. Please ensure it\'s configured in the store.',
        );
      }

      AppLogger.info('✅ Product found: ${product.title} - ${product.price}');

      // Validate user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.error('❌ User not authenticated for purchase');
        throw Exception('User must be authenticated to make purchases');
      }

      AppLogger.info('🔐 User authenticated: ${user.uid}');

      // Validate purchase parameters before initiating
      if (user.uid.isEmpty) {
        AppLogger.error('❌ Invalid user ID');
        throw Exception('Invalid user ID for purchase');
      }

      // Create purchase param with validation
      final purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: user.uid,
      );

      AppLogger.info(
        '📱 Purchase parameters validated, initiating purchase...',
      );

      // Store metadata for later retrieval when purchase completes
      if (metadata != null && metadata.isNotEmpty) {
        _pendingPurchaseMetadata[productId] = metadata;
        AppLogger.info('📝 Stored purchase metadata for $productId');
      }

      // Initiate purchase with comprehensive error handling
      final purchaseType = _getPurchaseType(productId);
      bool result;

      try {
        if (purchaseType == PurchaseType.consumable) {
          AppLogger.info('💳 Initiating consumable purchase: $productId');
          if (kDebugMode) {
            print('💳 Calling buyConsumable for $productId');
          }
          if (kDebugMode) {
            print('   - User: ${user.uid}');
          }
          if (kDebugMode) {
            print('   - Product: ${product.title} (${product.price})');
          }

          result = await _inAppPurchase.buyConsumable(
            purchaseParam: purchaseParam,
          );

          if (kDebugMode) {
            print('💳 buyConsumable returned: $result');
          }
        } else {
          AppLogger.info(
            '💳 Initiating non-consumable/subscription purchase: $productId',
          );
          if (kDebugMode) {
            print('💳 Calling buyNonConsumable for $productId');
          }

          result = await _inAppPurchase.buyNonConsumable(
            purchaseParam: purchaseParam,
          );

          if (kDebugMode) {
            print('💳 buyNonConsumable returned: $result');
          }
        }

        if (kDebugMode) {
          print('✅ Purchase call completed. Result: $result');
        }
        if (kDebugMode) {
          print('⏳ Now waiting for purchase update callback...');
        }

        AppLogger.info(
          '✅ Purchase initiated successfully: $productId - Result: $result',
        );
        return result;
      } catch (e) {
        // Check if this is a PendingIntent-related crash
        if (e.toString().contains('PendingIntent') ||
            e.toString().contains('Null') ||
            e.toString().contains('null')) {
          AppLogger.error(
            'NATIVE CRASH DETECTED: ProxyBillingActivity PendingIntent error: $e',
          );
          throw Exception(
            'Payment service encountered an error. Please ensure Google Play is up to date.',
          );
        }

        AppLogger.error('Error during purchase initiation: $e', error: e);
        rethrow;
      }
    } catch (e) {
      AppLogger.error('❌ Error purchasing product "$productId": $e', error: e);
      onPurchaseError?.call(e.toString());
      return false;
    }
  }

  /// Restore purchases
  Future<void> _restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      AppLogger.info('✅ Purchases restored');
    } catch (e) {
      AppLogger.error('Error restoring purchases: $e');
    }
  }

  /// Get available products by category
  List<ProductDetails> getProductsByCategory(PurchaseCategory category) {
    final categoryProductIds = _productIds[category.name] ?? [];
    return _products
        .where((product) => categoryProductIds.contains(product.id))
        .toList();
  }

  /// Get subscription products
  List<ProductDetails> getSubscriptionProducts() {
    return getProductsByCategory(PurchaseCategory.subscription);
  }

  /// Get gift products
  List<ProductDetails> getGiftProducts() {
    return getProductsByCategory(PurchaseCategory.gifts);
  }

  /// Check if a specific product is loaded
  bool isProductLoaded(String productId) {
    return _getProductDetails(productId) != null;
  }

  /// Get total number of loaded products
  int get loadedProductCount => _products.length;

  /// Get ad products
  List<ProductDetails> getAdProducts() {
    return getProductsByCategory(PurchaseCategory.ads);
  }

  /// Helper methods
  PurchaseType _getPurchaseType(String productId) {
    if (_productIds['subscriptions']!.contains(productId)) {
      return PurchaseType.subscription;
    } else if (_productIds['gifts']!.contains(productId) ||
        _productIds['ads']!.contains(productId)) {
      return PurchaseType.consumable;
    }
    return PurchaseType.nonConsumable;
  }

  PurchaseCategory _getPurchaseCategory(String productId) {
    if (_productIds['subscriptions']!.contains(productId)) {
      return PurchaseCategory.subscription;
    } else if (_productIds['gifts']!.contains(productId)) {
      return PurchaseCategory.gifts;
    } else if (_productIds['ads']!.contains(productId)) {
      return PurchaseCategory.ads;
    }
    return PurchaseCategory.premium;
  }

  ProductDetails? _getProductDetails(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  double _getProductPrice(ProductDetails product) {
    return product.rawPrice;
  }

  String _getProductCurrency(ProductDetails product) {
    return product.currencyCode;
  }

  SubscriptionTier _getSubscriptionTierFromProductId(String productId) {
    if (productId.contains('starter')) return SubscriptionTier.starter;
    if (productId.contains('creator')) return SubscriptionTier.creator;
    if (productId.contains('business')) return SubscriptionTier.business;
    if (productId.contains('enterprise')) return SubscriptionTier.enterprise;
    return SubscriptionTier.free;
  }

  int _getAdCreditsFromProductId(String productId) {
    switch (productId) {
      // Small ad packages
      case 'ad_small_1w':
        return 50; // Small package, 1 week
      case 'ad_small_1m':
        return 200; // Small package, 1 month
      case 'ad_small_3m':
        return 600; // Small package, 3 months
      // Big ad packages
      case 'ad_big_1w':
        return 150; // Big package, 1 week
      case 'ad_big_1m':
        return 600; // Big package, 1 month
      case 'ad_big_3m':
        return 1800; // Big package, 3 months
      default:
        return 0;
    }
  }

  /// Get user's active subscriptions
  Future<List<SubscriptionDetails>> getUserActiveSubscriptions(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      return snapshot.docs
          .map((doc) => SubscriptionDetails.fromFirestore(doc))
          .where((sub) => sub.isActive)
          .toList();
    } catch (e) {
      AppLogger.error('Error getting user subscriptions: $e');
      return [];
    }
  }

  /// Get user's purchase history
  Future<List<CompletedPurchase>> getUserPurchaseHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('purchases')
          .where('userId', isEqualTo: userId)
          .orderBy('purchaseDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CompletedPurchase.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting purchase history: $e');
      return [];
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription(String userId) async {
    final subscriptions = await getUserActiveSubscriptions(userId);
    return subscriptions.isNotEmpty;
  }

  /// Get user's current subscription tier
  Future<SubscriptionTier> getUserSubscriptionTier(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final tierName = data['subscriptionTier'] as String?;
        if (tierName != null) {
          return SubscriptionTier.fromLegacyName(tierName);
        }
      }
      return SubscriptionTier.free;
    } catch (e) {
      AppLogger.error('Error getting user subscription tier: $e');
      return SubscriptionTier.free;
    }
  }

  /// Extract purchase token from Android verification data
  String _extractPurchaseTokenFromVerificationData(String verificationData) {
    try {
      // For Android, the verification data contains JSON with purchase token
      final data =
          verificationData; // This is typically the purchase token directly
      return data;
    } catch (e) {
      AppLogger.error('Error extracting purchase token: $e');
      return '';
    }
  }

  /// Check if service is available
  bool get isAvailable => _isAvailable;

  /// Get all available products
  List<ProductDetails> get products => _products;

  /// Check if running in debug mode
  bool _isDebugMode() {
    bool debug = false;
    assert(debug = true);
    return debug;
  }

  /// Check if product ID is a gift product
  bool _isGiftProduct(String productId) {
    return _productIds['gifts']?.contains(productId) ?? false;
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
