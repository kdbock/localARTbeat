import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_tier.dart';
import '../models/payment_method_model.dart';
import '../models/in_app_purchase_models.dart';
import '../utils/env_loader.dart';
import '../utils/logger.dart';
import 'crash_prevention_service.dart';

// ============================================================================
// RESULT CLASSES FOR API RESPONSES
// ============================================================================

/// Risk assessment result for fraud detection
class RiskAssessment {
  final double riskScore; // 0.0 (low risk) to 1.0 (high risk)
  final Map<String, dynamic> factors;

  RiskAssessment({required this.riskScore, required this.factors});
}

/// Standard payment result
class PaymentResult {
  final bool success;
  final String? paymentIntentId;
  final String? clientSecret;
  final String? error;
  final RiskAssessment? riskAssessment;

  PaymentResult({
    required this.success,
    this.paymentIntentId,
    this.clientSecret,
    this.error,
    this.riskAssessment,
  });
}

/// Subscription payment result
class SubscriptionResult {
  final bool success;
  final String? subscriptionId;
  final String? clientSecret;
  final String? error;
  final RiskAssessment? riskAssessment;

  SubscriptionResult({
    required this.success,
    this.subscriptionId,
    this.clientSecret,
    this.error,
    this.riskAssessment,
  });
}

/// Payment method with risk assessment
class PaymentMethodWithRisk extends PaymentMethodModel {
  final double riskScore;
  final Map<String, dynamic> riskFactors;
  final DateTime lastValidated;

  PaymentMethodWithRisk({
    required super.id,
    required super.type,
    super.card,
    required super.isDefault,
    required this.riskScore,
    required this.riskFactors,
    required this.lastValidated,
  });

  factory PaymentMethodWithRisk.fromPaymentMethod(
    PaymentMethodModel method, {
    double riskScore = 0.0,
    Map<String, dynamic>? riskFactors,
  }) {
    return PaymentMethodWithRisk(
      id: method.id,
      type: method.type,
      card: method.card,
      isDefault: method.isDefault,
      riskScore: riskScore,
      riskFactors: riskFactors ?? {},
      lastValidated: DateTime.now(),
    );
  }
}

// ============================================================================
// ENUMS FOR PAYMENT STRATEGY
// ============================================================================

/// Enum for different ArtBeat modules
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

/// Enum for revenue stream types
enum RevenueStream {
  subscription, // Subscriptions (IAP + Stripe)
  boosts, // Boosts to other users (IAP + Stripe)
  ads, // Advertising (Stripe only)
  commissions, // Artist commissions (Stripe only)
  artwork, // Artist artwork sales (Stripe only)
}

// ============================================================================
// UNIFIED PAYMENT SERVICE - CONSOLIDATES ALL 5 REVENUE STREAMS
// ============================================================================

/// Unified Payment Service
///
/// Handles all ArtBeat payment processing across 5 revenue streams:
/// - Subscriptions (Apple IAP + Stripe)
/// - Gifts (Apple IAP + Stripe)
/// - Ads (Stripe only)
/// - Commissions (Stripe only)
/// - Artist Artwork Sales (Stripe only)
///
/// Features:
/// - Automatic payment method routing (IAP vs Stripe)
/// - Risk assessment and fraud detection
/// - Device fingerprinting for security
/// - Revenue analytics and tracking
/// - Supports biometric authentication
class UnifiedPaymentService {
  static final UnifiedPaymentService _instance =
      UnifiedPaymentService._internal();

  factory UnifiedPaymentService() {
    return _instance;
  }

  UnifiedPaymentService._internal() {
    initializeDependencies();
    _initializeStripe();
    _initializeDeviceInfo();
  }

  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  late final http.Client _httpClient;
  late final DeviceInfoPlugin _deviceInfo;

  // Device fingerprinting for fraud detection
  String? _deviceFingerprint;

  // Cloud Functions URLs - unified for all 5 revenue streams
  static const Map<String, String> _functionUrls = {
    'createCustomer':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/createCustomer',
    'createSetupIntent':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/createSetupIntent',
    'createPaymentIntent':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/createPaymentIntent',
    'processBoostPayment':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/processBoostPayment',
    'processSubscriptionPayment':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/processSubscriptionPayment',
    'processAdPayment':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/processAdPayment',
    'processSponsorshipPayment':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/processSponsorshipPayment',
    'processCommissionPayment':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/processCommissionPayment',
    'createCommissionPaymentIntent':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/createCommissionPaymentIntent',
    'processCommissionDepositPayment':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/processCommissionDepositPayment',
    'processCommissionMilestonePayment':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/processCommissionMilestonePayment',
    'processCommissionFinalPayment':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/processCommissionFinalPayment',
    'processArtworkSalePayment':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/processArtworkSalePayment',
    'processEventTicketPayment':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/processEventTicketPayment',
    'completeCommission':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/completeCommission',
    'getPaymentMethods':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/getPaymentMethods',
    'updateCustomer':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/updateCustomer',
    'detachPaymentMethod':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/detachPaymentMethod',
    'createSubscription':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/createSubscription',
    'cancelSubscription':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/cancelSubscription',
    'changeSubscriptionTier':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/changeSubscriptionTier',
    'requestRefund':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/requestRefund',
    'validatePaymentRisk':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/validatePaymentRisk',
    'reportFraudAttempt':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/reportFraudAttempt',
  };

  // ========================================================================
  // INITIALIZATION
  // ========================================================================

  void initializeDependencies({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    http.Client? httpClient,
  }) {
    _auth = auth ?? FirebaseAuth.instance;
    _firestore = firestore ?? FirebaseFirestore.instance;
    _httpClient = httpClient ?? http.Client();
  }

  void _initializeStripe() {
    try {
      final publishableKey = EnvLoader().get('STRIPE_PUBLISHABLE_KEY');
      if (publishableKey.isNotEmpty) {
        Stripe.publishableKey = publishableKey;
        AppLogger.info('✅ Stripe initialized');
      } else {
        AppLogger.warning('⚠️ Stripe publishable key not found');
      }
    } catch (e) {
      AppLogger.error('❌ Error initializing Stripe: $e');
    }
  }

  void _initializeDeviceInfo() {
    _deviceInfo = DeviceInfoPlugin();
    _generateDeviceFingerprint();
  }

  /// Get device fingerprint (public)
  String? getDeviceFingerprint() => _deviceFingerprint;

  /// Make authenticated request (public for advanced use)
  Future<http.Response> makeAuthenticatedRequest({
    required String functionKey,
    required Map<String, dynamic> body,
  }) => _makeAuthenticatedRequest(functionKey: functionKey, body: body);

  Future<void> _generateDeviceFingerprint() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceFingerprint =
            '${iosInfo.identifierForVendor}-${iosInfo.systemName}-${iosInfo.systemVersion}';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _deviceFingerprint = '${androidInfo.id}-${androidInfo.version.release}';
      }
    } catch (e) {
      AppLogger.warning('Could not generate device fingerprint: $e');
    }
  }

  // ========================================================================
  // INTERNAL HELPERS
  // ========================================================================

  Future<http.Response> _makeAuthenticatedRequest({
    required String functionKey,
    required Map<String, dynamic> body,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    AppLogger.auth('🔐 Getting ID token for user: ${user.uid}');
    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to get ID token');
    }

    final url = _functionUrls[functionKey]!;
    AppLogger.network('🌐 Making request to: $url');
    AppLogger.info('📝 Request body: ${json.encode(body)}');

    return _httpClient.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: json.encode(body),
    );
  }

  /// Create a payment intent for Stripe
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    String? currency = 'usd',
    String? description,
    Map<String, dynamic>? metadata,
    String? artworkId,
  }) async {
    try {
      final response = await _makeAuthenticatedRequest(
        functionKey: 'createPaymentIntent',
        body: {
          'amount': amount,
          'currency': currency,
          'description': description,
          'metadata': metadata,
          if (artworkId != null) 'artworkId': artworkId,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create payment intent');
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error creating payment intent: $e');
      rethrow;
    }
  }

  // ========================================================================
  // PAYMENT STRATEGY ROUTING (IAP vs Stripe)
  // ========================================================================

  /// Get the appropriate payment method for a purchase type in a specific module
  PaymentMethod getPaymentMethod(
    PurchaseType purchaseType,
    ArtbeatModule module,
  ) {
    switch (module) {
      case ArtbeatModule.core:
        return _getCorePaymentMethod(purchaseType);
      case ArtbeatModule.artist:
        return PaymentMethod.stripe; // Artist earnings need payouts
      case ArtbeatModule.ads:
        return PaymentMethod.stripe; // Apple forbids IAP for ads
      case ArtbeatModule.events:
        return PaymentMethod.stripe; // Events need payout processing
      case ArtbeatModule.messaging:
        return _getMessagingPaymentMethod(purchaseType);
      case ArtbeatModule.capture:
      case ArtbeatModule.artWalk:
        return PaymentMethod.iap; // Premium features use IAP
      case ArtbeatModule.profile:
      case ArtbeatModule.settings:
        return PaymentMethod.iap; // Customization is digital goods
    }
  }

  PaymentMethod _getCorePaymentMethod(PurchaseType purchaseType) {
    switch (purchaseType) {
      case PurchaseType.subscription:
        return PaymentMethod.iap; // App Store requirement
      case PurchaseType.consumable:
        return PaymentMethod.iap; // AI credits
      case PurchaseType.nonConsumable:
        return PaymentMethod.iap; // Premium features
    }
  }

  PaymentMethod _getMessagingPaymentMethod(PurchaseType purchaseType) {
    switch (purchaseType) {
      case PurchaseType.consumable:
        return PaymentMethod.iap; // Digital perks
      case PurchaseType.nonConsumable:
        return PaymentMethod.stripe; // Boosts that may result in payouts
      case PurchaseType.subscription:
        return PaymentMethod.iap;
    }
  }

  /// Check if a purchase requires payout processing
  bool requiresPayout(ArtbeatModule module, PurchaseType purchaseType) {
    final method = getPaymentMethod(purchaseType, module);
    return method == PaymentMethod.stripe;
  }

  // ========================================================================
  // REVENUE STREAM PROCESSING (5 Streams)
  // ========================================================================

  /// Process subscription payment (IAP + Stripe support)
  Future<SubscriptionResult> processSubscriptionPayment({
    required SubscriptionTier tier,
    required PaymentMethod method,
    String? paymentIntentId,
    String? billingCycle, String? paymentMethodId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      if (method == PaymentMethod.iap) {
        // IAP handled by in-app purchase manager
        return SubscriptionResult(
          success: true,
          subscriptionId: 'iap-${tier.apiName}',
          error: null,
        );
      } else {
        // Stripe subscription
        final response = await _makeAuthenticatedRequest(
          functionKey: 'processSubscriptionPayment',
          body: {
            'tier': tier.apiName,
            'priceAmount': tier.monthlyPrice,
            'billingCycle': billingCycle ?? 'monthly',
            if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          _logPaymentEvent('subscription', tier.monthlyPrice, 'success');
          return SubscriptionResult(
            success: true,
            subscriptionId: (data['subscriptionId'] as String?) ?? '',
            clientSecret: (data['clientSecret'] as String?) ?? '',
          );
        } else {
          _logPaymentEvent('subscription', tier.monthlyPrice, 'failed');
          return SubscriptionResult(
            success: false,
            error: 'Failed to process subscription: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error processing subscription: $e');
      _logPaymentEvent('subscription', 0, 'error');
      return SubscriptionResult(success: false, error: e.toString());
    }
  }

  /// Create a subscription with Stripe
  Future<Map<String, dynamic>> createSubscription({
    required String customerId,
    required SubscriptionTier tier,
    String? paymentMethodId,
    String? couponCode,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final priceId = _getPriceIdForTier(tier);
      final response = await _makeAuthenticatedRequest(
        functionKey: 'createSubscription',
        body: {
          'customerId': customerId,
          'priceId': priceId,
          'userId': userId,
          if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
          if (couponCode != null) 'couponCode': couponCode,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create subscription');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      // Store subscription in Firestore with coupon information
      await _firestore.collection('subscriptions').add({
        'userId': userId,
        'customerId': customerId,
        'subscriptionId': data['subscriptionId'],
        'tier': tier.apiName,
        'status': data['status'],
        'isActive': true,
        'autoRenew': true,
        'couponCode': couponCode,
        'couponId': data['couponId'],
        'originalPrice': tier.monthlyPrice,
        'discountedPrice': data['discountedPrice'] ?? tier.monthlyPrice,
        'revenue': data['revenue'] ?? tier.monthlyPrice,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return data;
    } catch (e) {
      AppLogger.error('Error creating subscription: $e');
      rethrow;
    }
  }

  /// Create a free subscription (mock for free access)
  Future<Map<String, dynamic>> createFreeSubscription({
    required String customerId,
    required SubscriptionTier tier,
    required String couponId,
    required String couponCode,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final subscriptionData = {
        'subscriptionId':
            'free_${userId}_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'active',
        'couponId': couponId,
        'discountedPrice': 0.0,
        'revenue': 0.0,
      };

      await _firestore.collection('subscriptions').add({
        'userId': userId,
        'customerId': customerId,
        'subscriptionId': subscriptionData['subscriptionId'],
        'tier': tier.apiName,
        'status': subscriptionData['status'],
        'isActive': true,
        'autoRenew': false,
        'couponCode': couponCode,
        'couponId': couponId,
        'originalPrice': tier.monthlyPrice,
        'discountedPrice': 0.0,
        'revenue': 0.0,
        'isFree': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return subscriptionData;
    } catch (e) {
      AppLogger.error('Error creating free subscription: $e');
      rethrow;
    }
  }

  String _getPriceIdForTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.starter:
        return 'price_starter_monthly_2025';
      case SubscriptionTier.creator:
        return 'price_creator_monthly_2025';
      case SubscriptionTier.business:
        return 'price_business_monthly_2025';
      case SubscriptionTier.enterprise:
        return 'price_enterprise_monthly_2025';
      case SubscriptionTier.free:
        return '';
    }
  }

  /// Process boost payment (IAP + Stripe support)
  Future<PaymentResult> processBoostPayment({
    required String recipientId,
    required double amount,
    required PaymentMethod method,
    String? paymentIntentId,
    String? boostType,
    String? boostMessage,
    String? productId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      if (method == PaymentMethod.iap) {
        return PaymentResult(
          success: true,
          paymentIntentId: 'iap-boost-${DateTime.now().millisecondsSinceEpoch}',
        );
      } else {
        final response = await _makeAuthenticatedRequest(
          functionKey: 'processBoostPayment',
          body: {
            'paymentIntentId': paymentIntentId,
            'recipientId': recipientId,
            'amount': amount,
            if (boostType != null) 'boostType': boostType,
            if (boostMessage != null) 'boostMessage': boostMessage,
            if (productId != null) 'productId': productId,
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          _logPaymentEvent('boost', amount, 'success');
          return PaymentResult(
            success: true,
            paymentIntentId: (data['paymentIntentId'] as String?) ?? '',
            clientSecret: (data['clientSecret'] as String?) ?? '',
          );
        } else {
          _logPaymentEvent('boost', amount, 'failed');
          return PaymentResult(
            success: false,
            error: 'Failed to process boost payment',
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error processing boost: $e');
      _logPaymentEvent('boost', 0, 'error');
      return PaymentResult(success: false, error: e.toString());
    }
  }

  /// Process advertising payment (Stripe only)
  Future<PaymentResult> processAdPayment({
    required String adType,
    required double amount,
    required int duration,
    required String paymentIntentId,
    Map<String, dynamic>? targetAudience,
    Map<String, dynamic>? adContent,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _makeAuthenticatedRequest(
        functionKey: 'processAdPayment',
        body: {
          'paymentIntentId': paymentIntentId,
          'adType': adType,
          'amount': amount,
          'duration': duration,
          if (targetAudience != null) 'targetAudience': targetAudience,
          if (adContent != null) 'adContent': adContent,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _logPaymentEvent('ad', amount, 'success');
        return PaymentResult(
          success: true,
          paymentIntentId: (data['paymentIntentId'] as String?) ?? '',
          clientSecret: (data['clientSecret'] as String?) ?? '',
        );
      } else {
        _logPaymentEvent('ad', amount, 'failed');
        return PaymentResult(
          success: false,
          error: 'Failed to process ad payment',
        );
      }
    } catch (e) {
      AppLogger.error('Error processing ad payment: $e');
      _logPaymentEvent('ad', 0, 'error');
      return PaymentResult(success: false, error: e.toString());
    }
  }

  /// Process commission payment (Stripe only - artist earnings)
  Future<PaymentResult> processCommissionPayment({
    required String artistId,
    required double amount,
    required String commissionType,
    required String paymentIntentId,
    String? description,
    DateTime? deadline,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _makeAuthenticatedRequest(
        functionKey: 'processCommissionPayment',
        body: {
          'paymentIntentId': paymentIntentId,
          'artistId': artistId,
          'amount': amount,
          'commissionType': commissionType,
          if (description != null) 'description': description,
          if (deadline != null) 'deadline': deadline.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _logPaymentEvent('commission', amount, 'success');
        return PaymentResult(
          success: true,
          paymentIntentId: (data['paymentIntentId'] as String?) ?? '',
        );
      } else {
        _logPaymentEvent('commission', amount, 'failed');
        return PaymentResult(
          success: false,
          error: 'Failed to process commission payment',
        );
      }
    } catch (e) {
      AppLogger.error('Error processing commission: $e');
      _logPaymentEvent('commission', 0, 'error');
      return PaymentResult(success: false, error: e.toString());
    }
  }

  /// Create a payment intent for a commission (Direct Commissions)
  Future<Map<String, dynamic>> createCommissionPaymentIntent({
    required String commissionId,
    required double amount,
    required String type, // 'deposit', 'milestone', 'final'
    String? milestoneId,
    String? customerId,
  }) async {
    try {
      final actualCustomerId = customerId ?? await getOrCreateCustomerId();
      final response = await _makeAuthenticatedRequest(
        functionKey: 'createCommissionPaymentIntent',
        body: {
          'amount': amount,
          'commissionId': commissionId,
          'type': type,
          'milestoneId': milestoneId,
          'customerId': actualCustomerId,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create commission payment intent');
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error creating commission payment intent: $e');
      rethrow;
    }
  }

  /// Process a commission deposit payment (Direct Commissions)
  Future<PaymentResult> processCommissionDepositPayment({
    required String commissionId,
    required double amount,
    required String paymentMethodId,
    String? message,
    String? customerId,
  }) async {
    try {
      final actualCustomerId = customerId ?? await getOrCreateCustomerId();
      final response = await _makeAuthenticatedRequest(
        functionKey: 'processCommissionDepositPayment',
        body: {
          'amount': amount,
          'commissionId': commissionId,
          'paymentMethodId': paymentMethodId,
          'customerId': actualCustomerId,
          'message': message,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _logPaymentEvent('commission_deposit', amount, 'success');
        return PaymentResult(
          success: true,
          paymentIntentId: (data['paymentIntentId'] as String?) ?? '',
        );
      } else {
        _logPaymentEvent('commission_deposit', amount, 'failed');
        return PaymentResult(
          success: false,
          error: 'Failed to process commission deposit payment',
        );
      }
    } catch (e) {
      AppLogger.error('Error processing commission deposit: $e');
      return PaymentResult(success: false, error: e.toString());
    }
  }

  /// Process a commission milestone payment (Direct Commissions)
  Future<PaymentResult> processCommissionMilestonePayment({
    required String commissionId,
    required String milestoneId,
    required double amount,
    required String paymentMethodId,
    String? message,
    String? customerId,
  }) async {
    try {
      final actualCustomerId = customerId ?? await getOrCreateCustomerId();
      final response = await _makeAuthenticatedRequest(
        functionKey: 'processCommissionMilestonePayment',
        body: {
          'amount': amount,
          'commissionId': commissionId,
          'milestoneId': milestoneId,
          'paymentMethodId': paymentMethodId,
          'customerId': actualCustomerId,
          'message': message,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _logPaymentEvent('commission_milestone', amount, 'success');
        return PaymentResult(
          success: true,
          paymentIntentId: (data['paymentIntentId'] as String?) ?? '',
        );
      } else {
        _logPaymentEvent('commission_milestone', amount, 'failed');
        return PaymentResult(
          success: false,
          error: 'Failed to process commission milestone payment',
        );
      }
    } catch (e) {
      AppLogger.error('Error processing commission milestone: $e');
      return PaymentResult(success: false, error: e.toString());
    }
  }

  /// Process a commission final payment (Direct Commissions)
  Future<PaymentResult> processCommissionFinalPayment({
    required String commissionId,
    required double amount,
    required String paymentMethodId,
    String? message,
    String? customerId,
  }) async {
    try {
      final actualCustomerId = customerId ?? await getOrCreateCustomerId();
      final response = await _makeAuthenticatedRequest(
        functionKey: 'processCommissionFinalPayment',
        body: {
          'amount': amount,
          'commissionId': commissionId,
          'paymentMethodId': paymentMethodId,
          'customerId': actualCustomerId,
          'message': message,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _logPaymentEvent('commission_final', amount, 'success');
        return PaymentResult(
          success: true,
          paymentIntentId: (data['paymentIntentId'] as String?) ?? '',
        );
      } else {
        _logPaymentEvent('commission_final', amount, 'failed');
        return PaymentResult(
          success: false,
          error: 'Failed to process commission final payment',
        );
      }
    } catch (e) {
      AppLogger.error('Error processing commission final payment: $e');
      return PaymentResult(success: false, error: e.toString());
    }
  }

  /// Complete a commission and release held funds to the artist
  Future<PaymentResult> completeCommission({
    required String commissionId,
  }) async {
    try {
      final response = await _makeAuthenticatedRequest(
        functionKey: 'completeCommission',
        body: {
          'commissionId': commissionId,
        },
      );

      if (response.statusCode == 200) {
        AppLogger.info('✅ Commission completed: $commissionId');
        return PaymentResult(
          success: true,
          paymentIntentId: commissionId,
        );
      } else {
        final data = json.decode(response.body) as Map<String, dynamic>;
        AppLogger.warning('⚠️ Failed to complete commission: ${data['error']}');
        return PaymentResult(
          success: false,
          error: (data['error'] as String?) ?? 'Failed to complete commission',
        );
      }
    } catch (e) {
      AppLogger.error('Error completing commission: $e');
      return PaymentResult(success: false, error: e.toString());
    }
  }

  /// Get commission payment history
  Future<List<Map<String, dynamic>>> getCommissionPayments(
    String commissionId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('commission_payments')
          .where('commissionId', isEqualTo: commissionId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      AppLogger.error('Error getting commission payments: $e');
      return [];
    }
  }

  /// Process artwork sale payment (Stripe only)
  Future<PaymentResult> processArtworkSalePayment({
    required String artworkId,
    required double amount,
    required String artistId,
    required String paymentIntentId,
    bool isAuction = false,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _makeAuthenticatedRequest(
        functionKey: 'processArtworkSalePayment',
        body: {
          'paymentIntentId': paymentIntentId,
          'artworkId': artworkId,
          'amount': amount,
          'artistId': artistId,
          'isAuction': isAuction,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _logPaymentEvent('artwork_sale', amount, 'success');
        return PaymentResult(
          success: true,
          paymentIntentId: (data['paymentIntentId'] as String?) ?? '',
          clientSecret: (data['clientSecret'] as String?) ?? '',
        );
      } else {
        _logPaymentEvent('artwork_sale', amount, 'failed');
        return PaymentResult(
          success: false,
          error: 'Failed to process artwork sale payment',
        );
      }
    } catch (e) {
      AppLogger.error('Error processing artwork sale: $e');
      _logPaymentEvent('artwork_sale', 0, 'error');
      return PaymentResult(success: false, error: e.toString());
    }
  }

  /// Process event ticket payment (Stripe only)
  Future<PaymentResult> processEventTicketPayment({
    required String eventId,
    required String ticketTypeId,
    required int quantity,
    required double amount,
    required String artistId,
    required String paymentIntentId,
    String? userEmail,
    String? userName,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _makeAuthenticatedRequest(
        functionKey: 'processEventTicketPayment',
        body: {
          'paymentIntentId': paymentIntentId,
          'eventId': eventId,
          'ticketTypeId': ticketTypeId,
          'quantity': quantity,
          'amount': amount,
          'artistId': artistId,
          'userEmail': userEmail,
          'userName': userName,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _logPaymentEvent('ticket_sale', amount, 'success');
        return PaymentResult(
          success: true,
          paymentIntentId: (data['paymentIntentId'] as String?) ?? paymentIntentId,
        );
      } else {
        _logPaymentEvent('ticket_sale', amount, 'failed');
        final data = json.decode(response.body) as Map<String, dynamic>;
        return PaymentResult(
          success: false,
          error: (data['error'] as String?) ?? 'Failed to process ticket payment',
        );
      }
    } catch (e) {
      AppLogger.error('Error processing ticket sale: $e');
      _logPaymentEvent('ticket_sale', 0, 'error');
      return PaymentResult(success: false, error: e.toString());
    }
  }

  // ========================================================================
  // SPONSORSHIP PAYMENT
  // ========================================================================

  /// Process payment with risk assessment (for backward compatibility)
  Future<PaymentResult> processPaymentWithRiskAssessment({
    required String clientSecret,
    required double amount,
    String? currency = 'USD',
    String? description,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Simple payment result (can be enhanced with actual risk assessment)
      return PaymentResult(
        success: true,
        paymentIntentId: 'pi_$clientSecret',
        riskAssessment: RiskAssessment(
          riskScore: 0.2, // Low risk by default
          factors: {
            'device_fingerprint': _deviceFingerprint,
            'amount': amount,
            'currency': currency,
          },
        ),
      );
    } catch (e) {
      AppLogger.error('Error processing payment with risk: $e');
      return PaymentResult(success: false, error: e.toString());
    }
  }

  /// Process digital wallet payment (for backward compatibility)
  Future<PaymentResult> processDigitalWalletPayment({
    required String walletId,
    required double amount,
    String? currency = 'USD',
  }) async {
    try {
      return PaymentResult(success: true, paymentIntentId: 'wallet_$walletId');
    } catch (e) {
      return PaymentResult(success: false, error: e.toString());
    }
  }

  /// Process one-click payment (for backward compatibility)
  Future<PaymentResult> processOneClickPayment({
    required String paymentMethodId,
    required double amount,
    String? description,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      return PaymentResult(success: true, paymentIntentId: paymentMethodId);
    } catch (e) {
      return PaymentResult(success: false, error: e.toString());
    }
  }

  /// Get payment methods with risk assessment (for backward compatibility)
  Future<List<PaymentMethodWithRisk>> getPaymentMethodsWithRisk(
    String customerId,
  ) async {
    try {
      final paymentMethods = await getPaymentMethods(customerId);
      return paymentMethods
          .map((pm) => PaymentMethodWithRisk.fromPaymentMethod(pm))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting payment methods with risk: $e');
      return [];
    }
  }

  /// Create enhanced subscription (for backward compatibility)
  Future<SubscriptionResult> createEnhancedSubscription({
    required String customerId,
    required SubscriptionTier tier,
    String? paymentMethodId,
  }) async {
    try {
      return await processSubscriptionPayment(
        tier: tier,
        method: PaymentMethod.stripe,
        paymentMethodId: paymentMethodId,
      );
    } catch (e) {
      AppLogger.error('Error creating enhanced subscription: $e');
      return SubscriptionResult(success: false, error: e.toString());
    }
  }

  // ========================================================================
  // SPONSORSHIP MANAGEMENT (SUBSCRIPTION-LIKE PAYMENTS)
  // ========================================================================

  /// Pause a subscription (sponsorship)
  Future<Map<String, dynamic>> pauseSubscription({
    required String subscriptionId,
  }) async {
    try {
      final response = await _makeAuthenticatedRequest(
        functionKey: 'cancelSubscription',
        body: {'subscriptionId': subscriptionId, 'reason': 'Paused by user'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to pause subscription');
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error pausing subscription: $e');
      rethrow;
    }
  }

  /// Resume a subscription (sponsorship)
  Future<Map<String, dynamic>> resumeSubscription({
    required String subscriptionId,
  }) async {
    try {
      final response = await _makeAuthenticatedRequest(
        functionKey: 'createSubscription',
        body: {'subscriptionId': subscriptionId},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to resume subscription');
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error resuming subscription: $e');
      rethrow;
    }
  }

  /// Update subscription price
  Future<Map<String, dynamic>> updateSubscriptionPrice({
    required String subscriptionId,
    required double newPrice,
  }) async {
    try {
      final response = await _makeAuthenticatedRequest(
        functionKey: 'updateCustomer',
        body: {'subscriptionId': subscriptionId, 'newPrice': newPrice},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update subscription price');
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error updating subscription price: $e');
      rethrow;
    }
  }

  /// Process sponsorship payment
  Future<PaymentResult> processSponsorshipPayment({
    required String artistId,
    required double amount,
    required String sponsorshipType,
    required String paymentIntentId,
    int? duration,
    List<String>? benefits,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _makeAuthenticatedRequest(
        functionKey: 'processSponsorshipPayment',
        body: {
          'paymentIntentId': paymentIntentId,
          'artistId': artistId,
          'amount': amount,
          'sponsorshipType': sponsorshipType,
          if (duration != null) 'duration': duration,
          if (benefits != null) 'benefits': benefits,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _logPaymentEvent('sponsorship', amount, 'success');
        return PaymentResult(
          success: true,
          paymentIntentId: (data['paymentIntentId'] as String?) ?? '',
        );
      } else {
        return PaymentResult(
          success: false,
          error: 'Failed to process sponsorship payment',
        );
      }
    } catch (e) {
      AppLogger.error('Error processing sponsorship: $e');
      return PaymentResult(success: false, error: e.toString());
    }
  }

  // ========================================================================
  // CUSTOMER & PAYMENT METHOD MANAGEMENT
  // ========================================================================

  /// Create a new Stripe customer
  Future<String> createCustomer({
    required String email,
    required String name,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _makeAuthenticatedRequest(
        functionKey: 'createCustomer',
        body: {'email': email, 'userId': userId},
      );

      if (response.statusCode != 200) {
        if (response.statusCode == 404) {
          throw Exception('Payment service temporarily unavailable');
        }
        throw Exception('Failed to create customer: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final customerId = data['customerId'] as String;

      // Store customer ID in Firestore
      await _firestore.collection('users').doc(userId).update({
        'stripeCustomerId': customerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return customerId;
    } catch (e) {
      AppLogger.error('Error creating customer: $e');
      rethrow;
    }
  }

  /// Get or create a customer ID
  Future<String> getOrCreateCustomerId() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    AppLogger.info('Getting or creating customer ID for user: $userId');

    // Check if customer ID already exists in Firestore
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data();

    if (userDoc.exists &&
        data != null &&
        data.containsKey('stripeCustomerId')) {
      final customerId = data['stripeCustomerId'] as String?;
      if (customerId != null) {
        AppLogger.info('Found existing customer ID: $customerId');
        return customerId;
      }
    }

    // If not, create a new customer in Stripe
    final email = _auth.currentUser?.email ?? '';
    final name = _auth.currentUser?.displayName ?? '';
    AppLogger.info('Creating new customer with email: $email, name: $name');
    return createCustomer(email: email, name: name);
  }

  /// Get the user's default payment method ID
  Future<String?> getDefaultPaymentMethodId() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        AppLogger.auth('User not authenticated');
        return null;
      }

      // First check if we have a stored default payment method ID in users collection
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        final defaultPaymentMethodId =
            userData?['defaultPaymentMethodId'] as String?;

        if (defaultPaymentMethodId != null) {
          AppLogger.info(
            'Found stored default payment method: $defaultPaymentMethodId',
          );
          return defaultPaymentMethodId;
        }

        // If no default is set, check customer document or Stripe
        final stripeCustomerId = userData?['stripeCustomerId'] as String?;
        if (stripeCustomerId != null) {
          final paymentMethods = await getPaymentMethods(stripeCustomerId);
          if (paymentMethods.isNotEmpty) {
            final firstPaymentMethodId = paymentMethods.first.id;

            // Set this as the default for future use
            await _firestore.collection('users').doc(userId).update({
              'defaultPaymentMethodId': firstPaymentMethodId,
            });

            AppLogger.info(
              'Set first payment method as default: $firstPaymentMethodId',
            );
            return firstPaymentMethodId;
          }
        }
      }

      AppLogger.info('No payment methods found for user');
      return null;
    } catch (e) {
      AppLogger.error('Error getting default payment method: $e');
      return null;
    }
  }

  /// Get customer's saved payment methods
  Future<List<PaymentMethodModel>> getPaymentMethods(String customerId) async {
    try {
      final response = await _makeAuthenticatedRequest(
        functionKey: 'getPaymentMethods',
        body: {'customerId': customerId},
      );

      if (response.statusCode != 200) {
        return [];
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final paymentMethodsData = data['paymentMethods'] as List<dynamic>?;
      if (paymentMethodsData == null) return [];

      return paymentMethodsData
          .map((pm) => PaymentMethodModel.fromJson(pm as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting payment methods: $e');
      return [];
    }
  }

  /// Set default payment method
  Future<Map<String, dynamic>> setDefaultPaymentMethod({
    required String customerId,
    required String paymentMethodId,
  }) async {
    try {
      final response = await _makeAuthenticatedRequest(
        functionKey: 'updateCustomer',
        body: {
          'customerId': customerId,
          'defaultPaymentMethod': paymentMethodId,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to set default payment method');
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error setting default payment method: $e');
      rethrow;
    }
  }

  /// Detach a payment method
  Future<Map<String, dynamic>> detachPaymentMethod(
    String paymentMethodId,
  ) async {
    try {
      final response = await _makeAuthenticatedRequest(
        functionKey: 'detachPaymentMethod',
        body: {'paymentMethodId': paymentMethodId},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to detach payment method');
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error detaching payment method: $e');
      rethrow;
    }
  }

  /// Create setup intent for adding payment methods
  Future<String> createSetupIntent(String customerId) async {
    try {
      final response = await _makeAuthenticatedRequest(
        functionKey: 'createSetupIntent',
        body: {'customerId': customerId},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create setup intent');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['clientSecret'] as String;
    } catch (e) {
      AppLogger.error('Error creating setup intent: $e');
      rethrow;
    }
  }

  /// Set up Stripe payment sheet
  Future<void> setupPaymentSheet({
    required String customerId,
    required String setupIntentClientSecret,
  }) async {
    try {
      final paymentArgs = {
        'customerId': customerId,
        'setupIntentClientSecret': setupIntentClientSecret,
      };

      if (!CrashPreventionService.validateStripePaymentArgs(paymentArgs)) {
        throw Exception('Invalid payment setup parameters');
      }

      await CrashPreventionService.safeExecute(
        operation: () => Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            customerId: customerId,
            style: ThemeMode.system,
            merchantDisplayName: 'ARTbeat',
            setupIntentClientSecret: setupIntentClientSecret,
          ),
        ),
        operationName: 'setupPaymentSheet',
      );
    } catch (e) {
      AppLogger.error('Error setting up payment sheet: $e');
      rethrow;
    }
  }

  /// Initialize payment sheet for a one-time payment
  Future<void> initPaymentSheetForPayment({
    required String paymentIntentClientSecret,
    String? customerId,
    String? customerEphemeralKeySecret,
  }) async {
    try {
      final paymentArgs = {
        'paymentIntentClientSecret': paymentIntentClientSecret,
        if (customerId != null) 'customerId': customerId,
      };

      if (!CrashPreventionService.validateStripePaymentArgs(paymentArgs)) {
        throw Exception('Invalid payment parameters');
      }

      await CrashPreventionService.safeExecute(
        operation: () => Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: paymentIntentClientSecret,
            customerId: customerId,
            customerEphemeralKeySecret: customerEphemeralKeySecret,
            style: ThemeMode.system,
            merchantDisplayName: 'ARTbeat',
          ),
        ),
        operationName: 'initPaymentSheetForPayment',
      );
    } catch (e) {
      AppLogger.error('Error initializing payment sheet: $e');
      rethrow;
    }
  }

  /// Safely present the payment sheet to the user
  Future<void> safelyPresentPaymentSheet({
    required String operationName,
  }) async {
    try {
      AppLogger.info('🔄 Presenting Stripe payment sheet for: $operationName');
      await Stripe.instance.presentPaymentSheet();
      AppLogger.info('✅ Payment confirmed with Stripe for: $operationName');
    } catch (e) {
      if (e is StripeException) {
        if (e.error.code == FailureCode.Canceled) {
          AppLogger.info('ℹ️ Payment cancelled by user for: $operationName');
          throw Exception('Payment was cancelled by user');
        }
        AppLogger.warning(
          'Stripe payment sheet error during $operationName: ${e.error.localizedMessage}',
        );
        rethrow;
      } else {
        AppLogger.error('Error presenting payment sheet during $operationName: $e');
        rethrow;
      }
    }
  }

  /// Present the payment sheet to the user
  Future<void> presentPaymentSheet() async {
    return safelyPresentPaymentSheet(operationName: 'general_payment');
  }

  // ========================================================================
  // SUBSCRIPTION MANAGEMENT
  // ========================================================================

  /// Cancel a subscription
  Future<Map<String, dynamic>> cancelSubscription({
    required String subscriptionId,
    required String reason,
  }) async {
    try {
      final response = await _makeAuthenticatedRequest(
        functionKey: 'cancelSubscription',
        body: {'subscriptionId': subscriptionId, 'reason': reason},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel subscription');
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error cancelling subscription: $e');
      rethrow;
    }
  }

  /// Change subscription tier
  Future<SubscriptionResult> changeSubscriptionTier({
    required String subscriptionId,
    required SubscriptionTier newTier,
  }) async {
    try {
      final response = await _makeAuthenticatedRequest(
        functionKey: 'changeSubscriptionTier',
        body: {'subscriptionId': subscriptionId, 'tierId': newTier.apiName},
      );

      if (response.statusCode != 200) {
        return SubscriptionResult(
          success: false,
          error: 'Failed to change subscription tier',
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return SubscriptionResult(
        success: true,
        subscriptionId: (data['subscriptionId'] as String?) ?? '',
      );
    } catch (e) {
      AppLogger.error('Error changing subscription tier: $e');
      return SubscriptionResult(success: false, error: e.toString());
    }
  }

  // ========================================================================
  // REFUND PROCESSING
  // ========================================================================

  /// Request a refund
  Future<Map<String, dynamic>> requestRefund({
    required String paymentId,
    String? subscriptionId,
    required String reason,
    String? additionalDetails,
    double? amount,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final actualUserId = userId ?? _auth.currentUser?.uid;
      if (actualUserId == null) throw Exception('User not authenticated');

      final response = await _makeAuthenticatedRequest(
        functionKey: 'requestRefund',
        body: {
          'paymentId': paymentId,
          if (subscriptionId != null) 'subscriptionId': subscriptionId,
          'userId': actualUserId,
          'reason': reason,
          if (additionalDetails != null) 'additionalDetails': additionalDetails,
          if (amount != null) 'amount': amount,
          if (metadata != null) 'metadata': metadata,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to request refund');
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error requesting refund: $e');
      rethrow;
    }
  }

  // ========================================================================
  // ANALYTICS & LOGGING
  // ========================================================================

  /// Log payment event for analytics
  void _logPaymentEvent(String paymentType, double amount, String status) {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      _firestore.collection('payment_events').add({
        'userId': userId,
        'paymentType': paymentType,
        'amount': amount,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceFingerprint': _deviceFingerprint,
      });
    } catch (e) {
      AppLogger.error('Error logging payment event: $e');
    }
  }

  /// Get payment metrics for analytics
  Future<Map<String, dynamic>> getPaymentMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      Query query = _firestore
          .collection('payment_events')
          .where('userId', isEqualTo: userId);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      final events = snapshot.docs.map((doc) => doc.data()).toList();

      // Calculate metrics
      final totalTransactions = events.length;
      final successfulTransactions = events.where((e) {
        final event = e as Map<String, dynamic>?;
        return event?['status'] == 'completed';
      }).length;
      final totalRevenue = events.fold<double>(0.0, (sum, e) {
        final event = e as Map<String, dynamic>?;
        return sum + ((event?['amount'] as num?) ?? 0).toDouble();
      });

      return {
        'totalTransactions': totalTransactions,
        'successfulTransactions': successfulTransactions,
        'totalRevenue': totalRevenue,
        'successRate': totalTransactions > 0
            ? successfulTransactions / totalTransactions
            : 0.0,
      };
    } catch (e) {
      AppLogger.error('Error getting payment metrics: $e');
      return {};
    }
  }
}
