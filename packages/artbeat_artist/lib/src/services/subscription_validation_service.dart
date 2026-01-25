import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/artist_logger.dart';

/// Service for validating subscription-related operations and business rules
class SubscriptionValidationService {
  static final SubscriptionValidationService _instance =
      SubscriptionValidationService._internal();
  factory SubscriptionValidationService() => _instance;
  SubscriptionValidationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Validate if user can upgrade to a specific subscription tier
  Future<ValidationResult> canUpgradeToTier({
    required String userId,
    required String currentTier,
    required String targetTier,
  }) async {
    try {
      // Define tier hierarchy
      final tierHierarchy = {
        'free': 0,
        'artist_basic': 1,
        'artist_pro': 2,
        'gallery': 3,
      };

      final currentTierLevel = tierHierarchy[currentTier] ?? 0;
      final targetTierLevel = tierHierarchy[targetTier] ?? 0;

      // Check if target tier is higher than current
      if (targetTierLevel <= currentTierLevel) {
        return ValidationResult(
          isValid: false,
          message:
              'Cannot downgrade or stay on same tier. Use change plan instead.',
        );
      }

      // Check if user meets requirements for target tier
      final requirements = await _getTierRequirements(targetTier);
      final userProfile = await _getUserProfile(userId);

      if (userProfile == null) {
        return ValidationResult(
          isValid: false,
          message: 'User profile not found',
        );
      }

      if (requirements == null) {
        return ValidationResult(
          isValid: false,
          message: 'Invalid subscription tier',
        );
      }

      // Validate requirements
      final validationErrors = <String>[];

      // Check profile completeness
      if (requirements['profileCompleteness'] == true) {
        if (!_isProfileComplete(userProfile)) {
          validationErrors.add('Profile must be complete');
        }
      }

      // Check artwork count for artist tiers
      if (targetTier.contains('artist')) {
        final artworkCount = await _getArtworkCount(userId);
        final minArtworks = requirements['minArtworks'] as int? ?? 0;

        if (artworkCount < minArtworks) {
          validationErrors.add('Minimum $minArtworks artworks required');
        }
      }

      // Check payment method for paid tiers
      if (targetTier != 'free') {
        final hasPaymentMethod = await _hasValidPaymentMethod(userId);
        if (!hasPaymentMethod) {
          validationErrors.add('Valid payment method required');
        }
      }

      // Check gallery-specific requirements
      if (targetTier == 'gallery') {
        final hasBusinessInfo = await _hasBusinessInformation(userId);
        if (!hasBusinessInfo) {
          validationErrors.add(
            'Business information required for gallery tier',
          );
        }
      }

      return ValidationResult(
        isValid: validationErrors.isEmpty,
        message: validationErrors.isEmpty
            ? 'Upgrade validation successful'
            : validationErrors.join(', '),
        validationErrors: validationErrors,
      );
    } catch (e) {
      ArtistLogger.error('Error validating tier upgrade: $e');
      return ValidationResult(
        isValid: false,
        message: 'Validation failed due to technical error',
      );
    }
  }

  /// Validate if user can cancel their subscription
  Future<ValidationResult> canCancelSubscription({
    required String userId,
    required String subscriptionId,
  }) async {
    try {
      final subscription = await _getSubscription(subscriptionId);

      if (subscription == null) {
        return ValidationResult(
          isValid: false,
          message: 'Subscription not found',
        );
      }

      // Check if subscription belongs to user
      if (subscription['userId'] != userId) {
        return ValidationResult(
          isValid: false,
          message: 'Subscription does not belong to user',
        );
      }

      // Check subscription status
      final status = subscription['status'] as String;
      if (status == 'cancelled' || status == 'inactive') {
        return ValidationResult(
          isValid: false,
          message: 'Subscription is already cancelled or inactive',
        );
      }

      // Check if there are pending commitments
      final hasPendingCommitments = await _hasPendingCommitments(userId);
      if (hasPendingCommitments) {
        return ValidationResult(
          isValid: false,
          message: 'Cannot cancel subscription with pending commitments',
        );
      }

      // Check if user has active gallery events
      if (subscription['tier'] == 'gallery') {
        final hasActiveEvents = await _hasActiveEvents(userId);
        if (hasActiveEvents) {
          return ValidationResult(
            isValid: false,
            message: 'Cannot cancel gallery subscription with active events',
            validationErrors: [
              'Active events must be completed or cancelled first',
            ],
          );
        }
      }

      return ValidationResult(
        isValid: true,
        message: 'Subscription can be cancelled',
      );
    } catch (e) {
      ArtistLogger.error('Error validating subscription cancellation: $e');
      return ValidationResult(
        isValid: false,
        message: 'Cancellation validation failed due to technical error',
      );
    }
  }

  /// Validate subscription payment information
  Future<ValidationResult> validatePaymentInformation({
    required String userId,
    required Map<String, dynamic> paymentData,
  }) async {
    try {
      final validationErrors = <String>[];

      // Validate required fields
      if (paymentData['paymentMethodId'] == null ||
          paymentData['paymentMethodId'].toString().isEmpty) {
        validationErrors.add('Payment method is required');
      }

      if (paymentData['amount'] == null ||
          (paymentData['amount'] as num) <= 0) {
        validationErrors.add('Valid amount is required');
      }

      if (paymentData['currency'] == null ||
          paymentData['currency'].toString().isEmpty) {
        validationErrors.add('Currency is required');
      }

      // Validate payment method exists and is valid
      final paymentMethodId = paymentData['paymentMethodId'] as String;
      final isValidPaymentMethod = await _validatePaymentMethod(
        paymentMethodId,
        userId,
      );
      if (!isValidPaymentMethod) {
        validationErrors.add('Invalid or expired payment method');
      }

      // Validate amount matches subscription tier
      final tier = paymentData['tier'] as String?;
      if (tier != null) {
        final expectedAmount = await _getTierPrice(tier);
        final providedAmount = (paymentData['amount'] as num).toDouble();

        if ((expectedAmount - providedAmount).abs() > 0.01) {
          validationErrors.add('Amount does not match subscription tier price');
        }
      }

      return ValidationResult(
        isValid: validationErrors.isEmpty,
        message: validationErrors.isEmpty
            ? 'Payment information is valid'
            : validationErrors.join(', '),
        validationErrors: validationErrors,
      );
    } catch (e) {
      ArtistLogger.error('Error validating payment information: $e');
      return ValidationResult(
        isValid: false,
        message: 'Payment validation failed due to technical error',
      );
    }
  }

  /// Validate business information for gallery subscriptions
  Future<ValidationResult> validateBusinessInformation(
    Map<String, dynamic> businessInfo,
  ) async {
    final validationErrors = <String>[];

    // Required fields for gallery subscription
    final requiredFields = [
      'businessName',
      'businessAddress',
      'businessPhone',
      'businessEmail',
      'businessType',
      'taxId',
    ];

    for (final field in requiredFields) {
      if (businessInfo[field] == null ||
          businessInfo[field].toString().trim().isEmpty) {
        validationErrors.add(
          '${field.replaceAll(RegExp(r'([A-Z])'), ' \$1').toLowerCase()} is required',
        );
      }
    }

    // Validate email format
    if (businessInfo['businessEmail'] != null) {
      final email = businessInfo['businessEmail'].toString();
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        validationErrors.add('Invalid business email format');
      }
    }

    // Validate phone format
    if (businessInfo['businessPhone'] != null) {
      final phone = businessInfo['businessPhone'].toString();
      if (!RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phone)) {
        validationErrors.add('Invalid business phone format');
      }
    }

    return ValidationResult(
      isValid: validationErrors.isEmpty,
      message: validationErrors.isEmpty
          ? 'Business information is valid'
          : validationErrors.join(', '),
      validationErrors: validationErrors,
    );
  }

  // Private helper methods

  Future<Map<String, dynamic>?> _getTierRequirements(String tier) async {
    final requirements = {
      'free': {'profileCompleteness': false, 'minArtworks': 0},
      'artist_basic': {'profileCompleteness': true, 'minArtworks': 1},
      'artist_pro': {'profileCompleteness': true, 'minArtworks': 5},
      'gallery': {
        'profileCompleteness': true,
        'minArtworks': 0,
        'businessInfo': true,
      },
    };

    return requirements[tier] as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      ArtistLogger.error('Error getting user profile: $e');
      return null;
    }
  }

  bool _isProfileComplete(Map<String, dynamic> profile) {
    final requiredFields = ['displayName', 'bio', 'profilePictureUrl'];
    return requiredFields.every(
      (field) =>
          profile[field] != null && profile[field].toString().trim().isNotEmpty,
    );
  }

  Future<int> _getArtworkCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('artworks')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      ArtistLogger.error('Error getting artwork count: $e');
      return 0;
    }
  }

  Future<bool> _hasValidPaymentMethod(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('paymentMethods')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      ArtistLogger.error('Error checking payment methods: $e');
      return false;
    }
  }

  Future<bool> _hasBusinessInformation(String userId) async {
    try {
      final doc = await _firestore.collection('businessInfo').doc(userId).get();
      return doc.exists && doc.data() != null;
    } catch (e) {
      ArtistLogger.error('Error checking business information: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _getSubscription(String subscriptionId) async {
    try {
      final doc = await _firestore
          .collection('subscriptions')
          .doc(subscriptionId)
          .get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      ArtistLogger.error('Error getting subscription: $e');
      return null;
    }
  }

  Future<bool> _hasPendingCommitments(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('commitments')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      ArtistLogger.error('Error checking pending commitments: $e');
      return false;
    }
  }

  Future<bool> _hasActiveEvents(String userId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('events')
          .where('organizerId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .where('endDate', isGreaterThan: now)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      ArtistLogger.error('Error checking active events: $e');
      return false;
    }
  }

  Future<bool> _validatePaymentMethod(
    String paymentMethodId,
    String userId,
  ) async {
    try {
      final doc = await _firestore
          .collection('paymentMethods')
          .doc(paymentMethodId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      return data['userId'] == userId && data['isActive'] == true;
    } catch (e) {
      ArtistLogger.error('Error validating payment method: $e');
      return false;
    }
  }

  Future<double> _getTierPrice(String tier) async {
    final prices = {
      'free': 0.0,
      'artist_basic': 0.0,
      'artist_pro': 9.99,
      'gallery': 49.99,
    };

    return prices[tier] ?? 0.0;
  }
}

/// Result of validation operations
class ValidationResult {
  final bool isValid;
  final String message;
  final List<String> validationErrors;

  ValidationResult({
    required this.isValid,
    required this.message,
    this.validationErrors = const [],
  });
}
