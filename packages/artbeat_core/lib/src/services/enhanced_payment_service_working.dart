import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import '../models/subscription_tier.dart';
import '../models/payment_method_model.dart';
import '../utils/env_loader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import 'biometric_auth_service.dart';
import 'crash_prevention_service.dart';

/// Risk assessment result
class RiskAssessment {
  final double riskScore; // 0.0 (low risk) to 1.0 (high risk)
  final Map<String, dynamic> factors;

  RiskAssessment({required this.riskScore, required this.factors});
}

/// Enhanced payment result
class PaymentResult {
  final bool success;
  final String? paymentIntentId;
  final String? error;
  final RiskAssessment? riskAssessment;

  PaymentResult({
    required this.success,
    this.paymentIntentId,
    this.error,
    this.riskAssessment,
  });
}

/// Enhanced subscription result
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

/// Enhanced payment method model with fraud detection
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

/// Enhanced Payment Service with 2025 features
/// Includes digital wallets, device fingerprinting, and fraud detection
class EnhancedPaymentService {
  static final EnhancedPaymentService _instance =
      EnhancedPaymentService._internal();

  factory EnhancedPaymentService() {
    return _instance;
  }

  EnhancedPaymentService._internal() {
    initializeDependencies();
    _initializeStripe();
    _initializeDeviceInfo();
  }

  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  late final http.Client _httpClient;
  late final DeviceInfoPlugin _deviceInfo;
  late final BiometricAuthService _biometricService;

  // Device fingerprinting for fraud detection
  String? _deviceFingerprint;
  Map<String, dynamic>? _deviceInfoData;

  // Enhanced Cloud Functions URLs with fraud detection
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
    // Enhanced fraud detection endpoints
    'validatePaymentRisk':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/validatePaymentRisk',
    'reportFraudAttempt':
        'https://us-central1-wordnerd-artbeat.cloudfunctions.net/reportFraudAttempt',
  };

  void initializeDependencies({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    http.Client? httpClient,
    DeviceInfoPlugin? deviceInfo,
    BiometricAuthService? biometricService,
  }) {
    _auth = auth ?? FirebaseAuth.instance;
    _firestore = firestore ?? FirebaseFirestore.instance;
    _httpClient = httpClient ?? http.Client();
    _deviceInfo = deviceInfo ?? DeviceInfoPlugin();
    _biometricService = biometricService ?? BiometricAuthService();
  }

  /// Initialize device fingerprinting for fraud detection
  Future<void> _initializeDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _deviceInfoData = {
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdk': androidInfo.version.sdkInt,
          'brand': androidInfo.brand,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceInfoData = {
          'model': iosInfo.model,
          'systemVersion': iosInfo.systemVersion,
          'name': iosInfo.name,
        };
      }

      // Create device fingerprint
      _deviceFingerprint = _generateDeviceFingerprint();
      AppLogger.info('✅ Device fingerprint generated: $_deviceFingerprint');
    } catch (e) {
      AppLogger.error('❌ Error initializing device info: $e');
    }
  }

  /// Generate device fingerprint for fraud detection
  String _generateDeviceFingerprint() {
    if (_deviceInfoData == null) return 'unknown';

    final components = [
      _deviceInfoData!['model'] ?? 'unknown',
      _deviceInfoData!['manufacturer'] ?? _deviceInfoData!['name'] ?? 'unknown',
      Platform.operatingSystem,
      Platform.operatingSystemVersion,
    ];

    return components.join('|').hashCode.toString();
  }

  /// Get device fingerprint for fraud detection
  Future<String> getDeviceFingerprint() async {
    if (_deviceFingerprint == null) {
      await _initializeDeviceInfo();
    }
    return _deviceFingerprint ?? 'unknown';
  }

  /// Enhanced payment processing with fraud detection
  Future<PaymentResult> processPaymentWithRiskAssessment({
    required String paymentIntentClientSecret,
    required double amount,
    required String currency,
    Map<String, dynamic>? metadata,
    bool skipBiometricAuth = false,
  }) async {
    try {
      // Perform risk assessment before processing
      final riskAssessment = await _assessPaymentRisk(amount, currency);

      // Check if biometric authentication is required
      if (!skipBiometricAuth &&
          _biometricService.shouldRequireBiometric(amount)) {
        final biometricResult = await _biometricService.authenticateForPayment(
          amount: amount,
          currency: currency,
          description:
              'Confirm payment of ${amount.toStringAsFixed(2)} $currency',
        );

        if (!biometricResult.success) {
          return PaymentResult(
            success: false,
            error: biometricResult.error ?? 'Biometric authentication failed',
            riskAssessment: riskAssessment,
          );
        }
      }

      // Initialize payment sheet with crash prevention
      await CrashPreventionService.safeExecute(
        operation: () => Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            merchantDisplayName: 'ARTbeat',
            style: ThemeMode.system,
            paymentIntentClientSecret: paymentIntentClientSecret,
            customerId: _auth.currentUser?.uid,
            allowsDelayedPaymentMethods: true,
          ),
        ),
        operationName: 'initPaymentSheet_enhanced',
      );

      // Present payment sheet to user with crash prevention
      await CrashPreventionService.safeExecute(
        operation: () => Stripe.instance.presentPaymentSheet(),
        operationName: 'presentPaymentSheet_enhanced',
      );

      // Log successful payment with risk data
      await _logPaymentEvent('success', amount, currency, riskAssessment);

      return PaymentResult(success: true, riskAssessment: riskAssessment);
    } catch (e) {
      // Log failed payment attempt
      await _logPaymentEvent(
        'failed',
        amount,
        currency,
        null,
        error: e.toString(),
      );

      // Report potential fraud attempt if risk score is high
      final riskAssessment = await _assessPaymentRisk(amount, currency);
      if (riskAssessment.riskScore > 0.7) {
        await _reportFraudAttempt(amount, currency, e.toString());
      }

      return PaymentResult(success: false, error: e.toString());
    }
  }

  /// Assess payment risk using multiple factors
  Future<RiskAssessment> _assessPaymentRisk(
    double amount,
    String currency,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return RiskAssessment(
          riskScore: 0.5,
          factors: {'error': 'user_not_authenticated'},
        );
      }

      // Get user's payment history for risk assessment
      final paymentHistory = await _getUserPaymentHistory(userId);
      final deviceHistory = await _getDevicePaymentHistory();

      // Calculate risk factors
      final riskFactors = <String, dynamic>{};
      double riskScore = 0.0;

      // Amount-based risk
      if (amount > 500) {
        riskScore += 0.3;
        riskFactors['high_amount'] = true;
      }

      // Frequency-based risk
      if (paymentHistory.length > 10) {
        riskScore += 0.1;
        riskFactors['frequent_payments'] = true;
      }

      // Device-based risk
      if (deviceHistory.isEmpty) {
        riskScore += 0.2;
        riskFactors['new_device'] = true;
      }

      // Time-based risk (unusual hours)
      final hour = DateTime.now().hour;
      if (hour < 6 || hour > 22) {
        riskScore += 0.1;
        riskFactors['unusual_time'] = true;
      }

      return RiskAssessment(
        riskScore: riskScore.clamp(0.0, 1.0),
        factors: riskFactors,
      );
    } catch (e) {
      AppLogger.error('❌ Error assessing payment risk: $e');
      return RiskAssessment(riskScore: 0.5, factors: {'error': e.toString()});
    }
  }

  /// Get user's payment history for risk assessment
  Future<List<Map<String, dynamic>>> _getUserPaymentHistory(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .where(
            'timestamp',
            isGreaterThan: DateTime.now().subtract(const Duration(days: 30)),
          )
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      AppLogger.error('❌ Error getting payment history: $e');
      return [];
    }
  }

  /// Get device payment history for fraud detection
  Future<List<Map<String, dynamic>>> _getDevicePaymentHistory() async {
    if (_deviceFingerprint == null) return [];

    try {
      final snapshot = await _firestore
          .collection('device_payments')
          .where('deviceFingerprint', isEqualTo: _deviceFingerprint)
          .where(
            'timestamp',
            isGreaterThan: DateTime.now().subtract(const Duration(days: 7)),
          )
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      AppLogger.error('❌ Error getting device payment history: $e');
      return [];
    }
  }

  /// Log payment events for monitoring and analytics
  Future<void> _logPaymentEvent(
    String event,
    double amount,
    String currency,
    RiskAssessment? riskAssessment, {
    String? error,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('payment_events').add({
        'userId': userId,
        'event': event,
        'amount': amount,
        'currency': currency,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceFingerprint': _deviceFingerprint,
        'deviceInfo': _deviceInfoData,
        if (riskAssessment != null) 'riskScore': riskAssessment.riskScore,
        if (riskAssessment != null) 'riskFactors': riskAssessment.factors,
        if (error != null) 'error': error,
      });
    } catch (e) {
      AppLogger.error('❌ Error logging payment event: $e');
    }
  }

  /// Report potential fraud attempts
  Future<void> _reportFraudAttempt(
    double amount,
    String currency,
    String reason,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('fraud_attempts').add({
        'userId': userId,
        'amount': amount,
        'currency': currency,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceFingerprint': _deviceFingerprint,
        'deviceInfo': _deviceInfoData,
      });

      AppLogger.warning('🚨 Fraud attempt reported: $reason');
    } catch (e) {
      AppLogger.error('❌ Error reporting fraud attempt: $e');
    }
  }

  /// Enhanced digital wallet payment processing
  Future<PaymentResult> processDigitalWalletPayment({
    required String walletType, // 'apple_pay', 'google_pay', 'paypal'
    required double amount,
    required String currency,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.info('💳 Processing $walletType payment: $amount $currency');

      // Create payment intent with wallet-specific configuration
      final paymentIntentData = await _createWalletPaymentIntent(
        walletType: walletType,
        amount: amount,
        currency: currency,
        metadata: metadata,
      );

      final clientSecret = paymentIntentData['clientSecret'] as String;

      // Initialize payment sheet for wallet payment with crash prevention
      await CrashPreventionService.safeExecute(
        operation: () => Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            merchantDisplayName: 'ARTbeat',
            style: ThemeMode.system,
            paymentIntentClientSecret: clientSecret,
            customerId: _auth.currentUser?.uid,
            allowsDelayedPaymentMethods: true,
          ),
        ),
        operationName: 'initPaymentSheet_wallet',
      );

      // Present payment sheet with crash prevention
      await CrashPreventionService.safeExecute(
        operation: () => Stripe.instance.presentPaymentSheet(),
        operationName: 'presentPaymentSheet_wallet',
      );

      return PaymentResult(
        success: true,
        paymentIntentId: paymentIntentData['id'] as String?,
      );
    } catch (e) {
      AppLogger.error('❌ Digital wallet payment error: $e');
      return PaymentResult(success: false, error: e.toString());
    }
  }

  /// Create payment intent for digital wallet
  Future<Map<String, dynamic>> _createWalletPaymentIntent({
    required String walletType,
    required double amount,
    required String currency,
    Map<String, dynamic>? metadata,
  }) async {
    final body = {
      'amount': (amount * 100).toInt(), // Convert to cents
      'currency': currency,
      'walletType': walletType,
      'deviceFingerprint': _deviceFingerprint,
      if (metadata != null) 'metadata': metadata,
    };

    final response = await makeAuthenticatedRequest(
      functionKey: 'createPaymentIntent',
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to create wallet payment intent: ${response.body}',
      );
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Enhanced one-click payment with device verification
  Future<PaymentResult> processOneClickPayment({
    required String paymentMethodId,
    required double amount,
    required String currency,
    Map<String, dynamic>? metadata,
    bool skipBiometricAuth = false,
  }) async {
    try {
      // Check if biometric authentication is required for one-click payments
      if (!skipBiometricAuth &&
          _biometricService.shouldRequireBiometric(amount)) {
        final biometricResult = await _biometricService.authenticateForPayment(
          amount: amount,
          currency: currency,
          description:
              'Confirm one-click payment of ${amount.toStringAsFixed(2)} $currency',
        );

        if (!biometricResult.success) {
          return PaymentResult(
            success: false,
            error: biometricResult.error ?? 'Biometric authentication failed',
          );
        }
      }

      // Create and confirm payment intent
      final paymentIntentData = await _createOneClickPaymentIntent(
        paymentMethodId: paymentMethodId,
        amount: amount,
        currency: currency,
        metadata: metadata,
      );

      final clientSecret = paymentIntentData['clientSecret'] as String;

      // Initialize payment sheet with crash prevention
      await CrashPreventionService.safeExecute(
        operation: () => Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            merchantDisplayName: 'ARTbeat',
            style: ThemeMode.system,
            paymentIntentClientSecret: clientSecret,
            customerId: _auth.currentUser?.uid,
            allowsDelayedPaymentMethods: true,
          ),
        ),
        operationName: 'initPaymentSheet_oneclick',
      );

      // Present payment sheet with crash prevention
      await CrashPreventionService.safeExecute(
        operation: () => Stripe.instance.presentPaymentSheet(),
        operationName: 'presentPaymentSheet_oneclick',
      );

      return PaymentResult(
        success: true,
        paymentIntentId: paymentIntentData['id'] as String?,
      );
    } catch (e) {
      AppLogger.error('❌ One-click payment error: $e');
      return PaymentResult(success: false, error: e.toString());
    }
  }

  /// Create payment intent for one-click payment
  Future<Map<String, dynamic>> _createOneClickPaymentIntent({
    required String paymentMethodId,
    required double amount,
    required String currency,
    Map<String, dynamic>? metadata,
  }) async {
    final body = {
      'amount': (amount * 100).toInt(),
      'currency': currency,
      'paymentMethodId': paymentMethodId,
      'deviceFingerprint': _deviceFingerprint,
      'oneClick': true,
      if (metadata != null) 'metadata': metadata,
    };

    final response = await makeAuthenticatedRequest(
      functionKey: 'createPaymentIntent',
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to create one-click payment intent: ${response.body}',
      );
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Get enhanced payment methods with risk assessment
  Future<List<PaymentMethodWithRisk>> getPaymentMethodsWithRisk() async {
    try {
      final response = await makeAuthenticatedRequest(
        functionKey: 'getPaymentMethods',
        body: {},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get payment methods: ${response.body}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final paymentMethodsData = data['paymentMethods'] as List<dynamic>? ?? [];

      final methods = paymentMethodsData
          .map(
            (method) =>
                PaymentMethodModel.fromJson(method as Map<String, dynamic>),
          )
          .toList();

      // Assess risk for each payment method
      final methodsWithRisk = <PaymentMethodWithRisk>[];
      for (final method in methods) {
        final riskAssessment = await _assessPaymentMethodRisk(method);
        methodsWithRisk.add(
          PaymentMethodWithRisk.fromPaymentMethod(
            method,
            riskScore: riskAssessment.riskScore,
            riskFactors: riskAssessment.factors,
          ),
        );
      }

      return methodsWithRisk;
    } catch (e) {
      AppLogger.error('❌ Error getting payment methods with risk: $e');
      return [];
    }
  }

  /// Assess risk for individual payment method
  Future<RiskAssessment> _assessPaymentMethodRisk(
    PaymentMethodModel method,
  ) async {
    // Simple risk assessment based on payment method usage patterns
    final riskFactors = <String, dynamic>{};
    double riskScore = 0.0;

    // Check if payment method has been used recently (lower risk)
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        final recentPayments = await _firestore
            .collection('payments')
            .where('userId', isEqualTo: userId)
            .where('paymentMethodId', isEqualTo: method.id)
            .where(
              'timestamp',
              isGreaterThan: DateTime.now().subtract(const Duration(days: 30)),
            )
            .get();

        if (recentPayments.docs.isEmpty) {
          riskScore += 0.2;
          riskFactors['unused_payment_method'] = true;
        }
      } catch (e) {
        riskScore += 0.1;
        riskFactors['error_checking_usage'] = true;
      }
    }

    return RiskAssessment(
      riskScore: riskScore.clamp(0.0, 1.0),
      factors: riskFactors,
    );
  }

  /// Enhanced subscription management with risk monitoring
  Future<SubscriptionResult> createEnhancedSubscription({
    required SubscriptionTier tier,
    required String paymentMethodId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Risk assessment for subscription
      final riskAssessment = await _assessSubscriptionRisk(tier);

      final body = {
        'tierApiName': tier.apiName,
        'paymentMethodId': paymentMethodId,
        'deviceFingerprint': _deviceFingerprint,
        'riskScore': riskAssessment.riskScore,
        if (metadata != null) 'metadata': metadata,
      };

      final response = await makeAuthenticatedRequest(
        functionKey: 'createSubscription',
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create subscription: ${response.body}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      return SubscriptionResult(
        success: true,
        subscriptionId: data['subscriptionId'] as String?,
        clientSecret: data['clientSecret'] as String?,
        riskAssessment: riskAssessment,
      );
    } catch (e) {
      AppLogger.error('❌ Enhanced subscription creation error: $e');
      return SubscriptionResult(success: false, error: e.toString());
    }
  }

  /// Assess subscription risk
  Future<RiskAssessment> _assessSubscriptionRisk(SubscriptionTier tier) async {
    final riskFactors = <String, dynamic>{};
    double riskScore = 0.0;

    // High-value subscriptions have higher risk
    if (tier.monthlyPrice > 50) {
      riskScore += 0.2;
      riskFactors['high_value_subscription'] = true;
    }

    // Check user's subscription history
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      final existingSubscriptions = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      if (existingSubscriptions.docs.isNotEmpty) {
        riskScore += 0.1;
        riskFactors['existing_subscriptions'] =
            existingSubscriptions.docs.length;
      }
    }

    return RiskAssessment(
      riskScore: riskScore.clamp(0.0, 1.0),
      factors: riskFactors,
    );
  }

  /// Make authenticated request to Cloud Functions
  Future<http.Response> makeAuthenticatedRequest({
    required String functionKey,
    required Map<String, dynamic> body,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to get ID token');
    }

    final url = _functionUrls[functionKey]!;
    AppLogger.network('🌐 Making request to: $url');

    return _httpClient.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: json.encode(body),
    );
  }

  /// Pause a subscription
  Future<bool> pauseSubscription(String subscriptionId) async {
    try {
      final body = {
        'subscriptionId': subscriptionId,
        'deviceFingerprint': await getDeviceFingerprint(),
      };

      final response = await makeAuthenticatedRequest(
        functionKey: 'pauseSubscription',
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('❌ Error pausing subscription: $e');
      return false;
    }
  }

  /// Resume a subscription
  Future<bool> resumeSubscription(String subscriptionId) async {
    try {
      final body = {
        'subscriptionId': subscriptionId,
        'deviceFingerprint': await getDeviceFingerprint(),
      };

      final response = await makeAuthenticatedRequest(
        functionKey: 'resumeSubscription',
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('❌ Error resuming subscription: $e');
      return false;
    }
  }

  /// Update subscription price
  Future<bool> updateSubscriptionPrice(
    String subscriptionId,
    String newPriceId,
  ) async {
    try {
      final body = {
        'subscriptionId': subscriptionId,
        'newPriceId': newPriceId,
        'deviceFingerprint': await getDeviceFingerprint(),
      };

      final response = await makeAuthenticatedRequest(
        functionKey: 'updateSubscriptionPrice',
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('❌ Error updating subscription price: $e');
      return false;
    }
  }

  /// Initialize Stripe with publishable key
  void _initializeStripe() {
    try {
      final publishableKey = EnvLoader().get('STRIPE_PUBLISHABLE_KEY');
      if (publishableKey.isNotEmpty) {
        Stripe.publishableKey = publishableKey;
        AppLogger.info('✅ Stripe initialized with publishable key');
      } else {
        AppLogger.warning('⚠️ Stripe publishable key not found in environment');
      }
    } catch (e) {
      AppLogger.error('❌ Error initializing Stripe: $e');
    }
  }
}
