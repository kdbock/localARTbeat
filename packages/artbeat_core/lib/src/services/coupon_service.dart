import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/coupon_model.dart';
import '../models/subscription_tier.dart';

/// Service for managing promotional coupons and discount codes
class CouponService extends ChangeNotifier {
  static final CouponService _instance = CouponService._internal();
  factory CouponService() => _instance;
  CouponService._internal();

  FirebaseAuth? _authInstance;
  FirebaseFirestore? _firestoreInstance;

  void initialize() {
    _authInstance ??= FirebaseAuth.instance;
    _firestoreInstance ??= FirebaseFirestore.instance;
  }

  FirebaseAuth get _auth {
    initialize();
    return _authInstance!;
  }

  FirebaseFirestore get _firestore {
    initialize();
    return _firestoreInstance!;
  }

  /// Create a new coupon
  Future<String> createCoupon({
    required String code,
    required String title,
    required String description,
    required CouponType type,
    double? discountAmount,
    int? discountPercentage,
    int? maxUses,
    DateTime? expiresAt,
    List<String>? allowedSubscriptionTiers,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Validate coupon parameters based on type
    _validateCouponParameters(type, discountAmount, discountPercentage);

    // Check if code already exists
    final existingCoupon = await _getCouponByCode(code);
    if (existingCoupon != null) {
      throw Exception('Coupon code already exists');
    }

    final coupon = CouponModel(
      id: '', // Will be set by Firestore
      code: code.toUpperCase(),
      title: title,
      description: description,
      type: type,
      status: CouponStatus.active,
      discountAmount: discountAmount,
      discountPercentage: discountPercentage,
      maxUses: maxUses,
      currentUses: 0,
      expiresAt: expiresAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: user.uid,
      allowedSubscriptionTiers: allowedSubscriptionTiers,
      metadata: metadata,
    );

    final docRef = await _firestore
        .collection('coupons')
        .add(coupon.toFirestore());

    return docRef.id;
  }

  /// Validate a coupon code and return coupon details
  Future<CouponModel?> validateCoupon(String code) async {
    final coupon = await _getCouponByCode(code.toUpperCase());
    if (coupon == null) return null;

    if (!coupon.isValid) return null;

    return coupon;
  }

  /// Apply a coupon to a subscription purchase
  Future<Map<String, dynamic>> applyCoupon({
    required String couponCode,
    required SubscriptionTier tier,
    required double originalPrice,
  }) async {
    final coupon = await validateCoupon(couponCode);
    if (coupon == null) {
      throw Exception('Invalid or expired coupon code');
    }

    // Check if coupon can be applied to this tier
    if (!coupon.canApplyToTier(tier.apiName)) {
      throw Exception(
        'This coupon cannot be applied to the selected subscription tier',
      );
    }

    final discountedPrice = coupon.calculateDiscountedPrice(originalPrice);
    final discountAmount = originalPrice - discountedPrice;

    return {
      'coupon': coupon,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'discountAmount': discountAmount,
      'isFree': discountedPrice == 0.0,
    };
  }

  /// Redeem a coupon (increment usage count)
  Future<void> redeemCoupon(String couponId) async {
    await _firestore.runTransaction((transaction) async {
      final couponRef = _firestore.collection('coupons').doc(couponId);
      final couponDoc = await transaction.get(couponRef);

      if (!couponDoc.exists) {
        throw Exception('Coupon not found');
      }

      final coupon = CouponModel.fromFirestore(couponDoc);
      final newUsageCount = coupon.currentUses + 1;

      // Check if usage limit would be exceeded
      if (coupon.maxUses != null && newUsageCount > coupon.maxUses!) {
        throw Exception('Coupon usage limit exceeded');
      }

      transaction.update(couponRef, {
        'currentUses': newUsageCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Get coupon by ID
  Future<CouponModel?> getCoupon(String couponId) async {
    final doc = await _firestore.collection('coupons').doc(couponId).get();
    if (!doc.exists) return null;
    return CouponModel.fromFirestore(doc);
  }

  /// Get coupon by code
  Future<CouponModel?> _getCouponByCode(String code) async {
    final snapshot = await _firestore
        .collection('coupons')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return CouponModel.fromFirestore(snapshot.docs.first);
  }

  /// Get all coupons created by current user (admin function)
  Stream<List<CouponModel>> getMyCoupons() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('coupons')
        .where('createdBy', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CouponModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get active coupons (for admin dashboard)
  Stream<List<CouponModel>> getActiveCoupons() {
    return _firestore
        .collection('coupons')
        .where('status', isEqualTo: CouponStatus.active.value)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CouponModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Update coupon status
  Future<void> updateCouponStatus(String couponId, CouponStatus status) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('coupons').doc(couponId).update({
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update a coupon's details
  Future<void> updateCoupon(CouponModel coupon) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Verify ownership
    final couponDoc = await _firestore
        .collection('coupons')
        .doc(coupon.id)
        .get();
    if (!couponDoc.exists) throw Exception('Coupon not found');

    final existingCoupon = CouponModel.fromFirestore(couponDoc);
    if (existingCoupon.createdBy != user.uid) {
      throw Exception('You can only update coupons you created');
    }

    // Validate coupon parameters based on type
    _validateCouponParameters(
      coupon.type,
      coupon.discountAmount,
      coupon.discountPercentage,
    );

    // Check if code already exists (if changed)
    if (coupon.code != existingCoupon.code) {
      final codeExists = await _getCouponByCode(coupon.code);
      if (codeExists != null) {
        throw Exception('Coupon code already exists');
      }
    }

    await _firestore.collection('coupons').doc(coupon.id).update({
      ...coupon.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a coupon
  Future<void> deleteCoupon(String couponId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Verify ownership
    final couponDoc = await _firestore
        .collection('coupons')
        .doc(couponId)
        .get();
    if (!couponDoc.exists) throw Exception('Coupon not found');

    final coupon = CouponModel.fromFirestore(couponDoc);
    if (coupon.createdBy != user.uid) {
      throw Exception('Not authorized to delete this coupon');
    }

    await _firestore.collection('coupons').doc(couponId).delete();
  }

  /// Generate a unique coupon code
  Future<String> generateUniqueCode({int length = 8}) async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code;

    do {
      code = String.fromCharCodes(
        List.generate(
          length,
          (index) => chars.codeUnitAt(
            DateTime.now().millisecondsSinceEpoch % chars.length,
          ),
        ),
      );
    } while (await _getCouponByCode(code) != null);

    return code;
  }

  /// Create a full access coupon for beta testing or promotions
  Future<String> createFullAccessCoupon({
    required String title,
    required String description,
    int? maxUses,
    DateTime? expiresAt,
    List<String>? allowedSubscriptionTiers,
  }) async {
    final code = await generateUniqueCode();

    return createCoupon(
      code: code,
      title: title,
      description: description,
      type: CouponType.fullAccess,
      maxUses: maxUses,
      expiresAt: expiresAt,
      allowedSubscriptionTiers: allowedSubscriptionTiers,
    );
  }

  /// Create a percentage discount coupon
  Future<String> createPercentageDiscountCoupon({
    required String title,
    required String description,
    required int discountPercentage,
    int? maxUses,
    DateTime? expiresAt,
    List<String>? allowedSubscriptionTiers,
  }) async {
    final code = await generateUniqueCode();

    return createCoupon(
      code: code,
      title: title,
      description: description,
      type: CouponType.percentageDiscount,
      discountPercentage: discountPercentage,
      maxUses: maxUses,
      expiresAt: expiresAt,
      allowedSubscriptionTiers: allowedSubscriptionTiers,
    );
  }

  /// Create a fixed discount coupon
  Future<String> createFixedDiscountCoupon({
    required String title,
    required String description,
    required double discountAmount,
    int? maxUses,
    DateTime? expiresAt,
    List<String>? allowedSubscriptionTiers,
  }) async {
    final code = await generateUniqueCode();

    return createCoupon(
      code: code,
      title: title,
      description: description,
      type: CouponType.fixedDiscount,
      discountAmount: discountAmount,
      maxUses: maxUses,
      expiresAt: expiresAt,
      allowedSubscriptionTiers: allowedSubscriptionTiers,
    );
  }

  /// Get coupon usage statistics
  Future<Map<String, dynamic>> getCouponStats(String couponId) async {
    final coupon = await getCoupon(couponId);
    if (coupon == null) throw Exception('Coupon not found');

    // Get all subscription records that used this coupon
    final subscriptionsSnapshot = await _firestore
        .collection('subscriptions')
        .where('couponId', isEqualTo: couponId)
        .get();

    final totalRevenue = subscriptionsSnapshot.docs.fold<double>(0.0, (
      sum,
      doc,
    ) {
      final data = doc.data();
      return sum + (data['revenue'] as double? ?? 0.0);
    });

    return {
      'coupon': coupon,
      'totalUses': coupon.currentUses,
      'remainingUses': coupon.maxUses != null
          ? coupon.maxUses! - coupon.currentUses
          : null,
      'totalRevenue': totalRevenue,
      'subscriptionCount': subscriptionsSnapshot.docs.length,
    };
  }

  /// Validate coupon parameters based on type
  void _validateCouponParameters(
    CouponType type,
    double? discountAmount,
    int? discountPercentage,
  ) {
    switch (type) {
      case CouponType.fullAccess:
        // No additional validation needed
        break;
      case CouponType.percentageDiscount:
        if (discountPercentage == null ||
            discountPercentage <= 0 ||
            discountPercentage > 100) {
          throw Exception('Percentage discount must be between 1 and 100');
        }
        break;
      case CouponType.fixedDiscount:
        if (discountAmount == null || discountAmount <= 0) {
          throw Exception('Fixed discount amount must be greater than 0');
        }
        break;
      case CouponType.freeTrial:
        // Free trial validation would be handled in subscription logic
        break;
    }
  }
}
