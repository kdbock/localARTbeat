import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/index.dart';

class LocalAdIapService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _purchasesCollection = 'adPurchases';

  LocalAdIapService() {
    _productIds = AdPricingMatrix.getAllSkus();
  }

  late final List<String> _productIds;

  Future<void> initIap() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      throw Exception('Failed to initialize IAP: $e');
    }
  }

  Future<List<ProductDetails>> fetchProducts() async {
    try {
      final response = await _inAppPurchase.queryProductDetails(
        _productIds.toSet(),
      );
      return response.productDetails;
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<void> purchaseAd({
    required LocalAdSize size,
    required LocalAdDuration duration,
  }) async {
    try {
      final sku = AdPricingMatrix.getSku(size, duration);
      if (sku == null) {
        throw Exception('Invalid ad configuration');
      }

      final response = await _inAppPurchase.queryProductDetails({sku}.toSet());

      if (response.productDetails.isEmpty) {
        final errorMsg = response.notFoundIDs.isNotEmpty
            ? 'Product "$sku" not found in App Store Connect. Missing products: ${response.notFoundIDs.join(", ")}'
            : 'Product "$sku" not available';
        throw Exception(errorMsg);
      }

      final product = response.productDetails.first;
      await _inAppPurchase.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      throw Exception('Failed to purchase: $e');
    }
  }

  Future<bool> verifyReceipt(String receipt) async {
    try {
      return true;
    } catch (e) {
      throw Exception('Failed to verify receipt: $e');
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      throw Exception('Failed to restore purchases: $e');
    }
  }

  Future<void> recordPurchase(LocalAdPurchase purchase) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection(_purchasesCollection)
          .doc(purchase.id)
          .set(purchase.toMap());
    } catch (e) {
      throw Exception('Failed to record purchase: $e');
    }
  }

  Future<List<LocalAdPurchase>> getUserPurchases(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(_purchasesCollection)
          .orderBy('purchasedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LocalAdPurchase.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch purchases: $e');
    }
  }
}
