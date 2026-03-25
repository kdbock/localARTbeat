import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/index.dart';

class LocalAdPurchaseResult {
  final String productId;
  final String purchaseId;
  final String? transactionId;
  final double price;
  final String currencyCode;
  final String verificationData;
  final String sourcePlatform;

  const LocalAdPurchaseResult({
    required this.productId,
    required this.purchaseId,
    required this.transactionId,
    required this.price,
    required this.currencyCode,
    required this.verificationData,
    required this.sourcePlatform,
  });
}

class LocalAdIapService {
  LocalAdIapService._internal();

  static final LocalAdIapService _instance = LocalAdIapService._internal();
  factory LocalAdIapService() => _instance;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Completer<LocalAdPurchaseResult>? _pendingPurchaseCompleter;
  ProductDetails? _pendingProduct;
  String? _pendingProductId;
  bool _isInitialized = false;

  Future<void> initIap() async {
    if (_isInitialized) {
      return;
    }

    final isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      throw Exception('In-app purchases are not available on this device');
    }

    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _completePendingPurchaseWithError(
          'Purchase stream error: $error',
        );
      },
    );

    _isInitialized = true;
  }

  Future<List<ProductDetails>> fetchProducts() async {
    await initIap();

    final response = await _inAppPurchase.queryProductDetails(
      AdPricingMatrix.getAllSkus().toSet(),
    );

    if (response.error != null) {
      throw Exception('Failed to fetch products: ${response.error}');
    }

    return response.productDetails;
  }

  Future<LocalAdPurchaseResult> purchaseAdSubscription({
    required LocalAdSize size,
  }) async {
    await initIap();

    if (_pendingPurchaseCompleter != null &&
        !(_pendingPurchaseCompleter?.isCompleted ?? true)) {
      throw Exception('Another ad purchase is already in progress');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final sku = AdPricingMatrix.getSku(size, LocalAdDuration.oneMonth);
    if (sku == null) {
      throw Exception('Missing product configuration for this ad type');
    }

    final response = await _inAppPurchase.queryProductDetails({sku});
    if (response.error != null) {
      throw Exception('Failed to load Apple subscription product: ${response.error}');
    }

    if (response.productDetails.isEmpty) {
      final notFound = response.notFoundIDs.join(', ');
      throw Exception(
        notFound.isEmpty
            ? 'Apple subscription product is not available for $sku'
            : 'Apple subscription product is missing: $notFound',
      );
    }

    final product = response.productDetails.first;
    _pendingProduct = product;
    _pendingProductId = product.id;
    _pendingPurchaseCompleter = Completer<LocalAdPurchaseResult>();

    final purchaseStarted = await _inAppPurchase.buyNonConsumable(
      purchaseParam: PurchaseParam(
        productDetails: product,
        applicationUserName: user.uid,
      ),
    );

    if (!purchaseStarted) {
      _clearPendingPurchase();
      throw Exception('Failed to start Apple subscription purchase');
    }

    return _pendingPurchaseCompleter!.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        _clearPendingPurchase();
        throw TimeoutException('Timed out waiting for Apple subscription confirmation');
      },
    );
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (_pendingProductId != null &&
          purchaseDetails.productID == _pendingProductId) {
        _handlePendingPurchaseUpdate(purchaseDetails);
      }
    }
  }

  Future<void> _handlePendingPurchaseUpdate(PurchaseDetails details) async {
    switch (details.status) {
      case PurchaseStatus.pending:
        return;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        final product = _pendingProduct;
        if (product == null) {
          _completePendingPurchaseWithError(
            'Apple purchase completed, but product metadata was missing.',
          );
          break;
        }

        if (details.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(details);
        }

        _pendingPurchaseCompleter?.complete(
          LocalAdPurchaseResult(
            productId: details.productID,
            purchaseId:
                details.purchaseID ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            transactionId: details.purchaseID,
            price: product.rawPrice,
            currencyCode: product.currencyCode,
            verificationData: details.verificationData.localVerificationData,
            sourcePlatform: Platform.isIOS ? 'ios' : 'android',
          ),
        );
        _clearPendingPurchase();
        break;
      case PurchaseStatus.canceled:
        _completePendingPurchaseWithError('Apple subscription purchase was cancelled.');
        break;
      case PurchaseStatus.error:
        _completePendingPurchaseWithError(
          details.error?.message ?? 'Apple subscription purchase failed.',
        );
        break;
    }
  }

  void _completePendingPurchaseWithError(String message) {
    if (!(_pendingPurchaseCompleter?.isCompleted ?? true)) {
      _pendingPurchaseCompleter?.completeError(Exception(message));
    }
    _clearPendingPurchase();
  }

  void _clearPendingPurchase() {
    _pendingProduct = null;
    _pendingProductId = null;
    _pendingPurchaseCompleter = null;
  }

  void dispose() {
    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
    _clearPendingPurchase();
    _isInitialized = false;
  }
}
