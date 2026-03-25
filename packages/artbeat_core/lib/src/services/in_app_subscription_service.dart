import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/in_app_purchase_models.dart';
import '../models/subscription_tier.dart';
import '../utils/logger.dart';
import 'in_app_purchase_service.dart';

/// Service for handling subscription-specific in-app purchases
class InAppSubscriptionService {
  static final InAppSubscriptionService _instance =
      InAppSubscriptionService._internal();
  factory InAppSubscriptionService() => _instance;
  InAppSubscriptionService._internal();

  final InAppPurchaseService _purchaseService = InAppPurchaseService();
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

  /// Subscribe to a specific tier
  Future<bool> subscribeToTier(
    SubscriptionTier tier, {
    bool isYearly = false,
  }) async {
    try {
      AppLogger.info(
        '🎯 Starting subscription purchase for ${tier.displayName} (yearly: $isYearly)',
      );

      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.error('User not authenticated for subscription');
        return false;
      }

      // Check if user already has an active subscription
      final hasActive = await _purchaseService.hasActiveSubscription(user.uid);
      AppLogger.info('User has active subscription: $hasActive');
      if (hasActive) {
        AppLogger.warning('User already has an active subscription');
        // You might want to handle subscription changes here
        return await _changeSubscriptionTier(tier, isYearly);
      }

      // Get product ID for the tier
      final productId = _getProductIdForTier(tier, isYearly);
      AppLogger.info('Product ID for ${tier.displayName}: $productId');
      if (productId == null) {
        AppLogger.error('No product ID found for tier: ${tier.displayName}');
        return false;
      }

      // Purchase the subscription
      final success = await _purchaseService.purchaseProduct(
        productId,
        metadata: {
          'tier': tier.apiName,
          'isYearly': isYearly,
          'userId': user.uid,
        },
      );

      if (success) {
        AppLogger.info(
          '✅ Subscription purchase initiated: ${tier.displayName}',
        );
      } else {
        AppLogger.error('❌ Failed to initiate subscription purchase');
      }

      return success;
    } catch (e) {
      AppLogger.error('Error subscribing to tier: $e');
      return false;
    }
  }

  /// Change subscription tier
  Future<bool> _changeSubscriptionTier(
    SubscriptionTier newTier,
    bool isYearly,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get current active subscriptions
      final activeSubscriptions = await _purchaseService
          .getUserActiveSubscriptions(user.uid);
      if (activeSubscriptions.isEmpty) {
        // No active subscription, proceed with new subscription
        return await subscribeToTier(newTier, isYearly: isYearly);
      }

      // Cancel current subscription and start new one
      for (final subscription in activeSubscriptions) {
        await _cancelSubscription(subscription.subscriptionId);
      }

      // Start new subscription
      return await subscribeToTier(newTier, isYearly: isYearly);
    } catch (e) {
      AppLogger.error('Error changing subscription tier: $e');
      return false;
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      return await _cancelSubscription(subscriptionId);
    } catch (e) {
      AppLogger.error('Error cancelling subscription: $e');
      return false;
    }
  }

  /// Internal method to cancel subscription
  Future<bool> _cancelSubscription(String subscriptionId) async {
    try {
      // Update subscription status in Firestore
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'status': 'cancelled',
        'cancellationReason': 'user_requested',
        'autoRenewing': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user's subscription status
      final subscription = await _firestore
          .collection('subscriptions')
          .doc(subscriptionId)
          .get();

      if (subscription.exists) {
        final data = subscription.data()!;
        final userId = data['userId'] as String;

        await _firestore.collection('users').doc(userId).update({
          'subscriptionStatus': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      AppLogger.info('✅ Subscription cancelled: $subscriptionId');
      return true;
    } catch (e) {
      AppLogger.error('Error cancelling subscription: $e');
      return false;
    }
  }

  /// Get subscription pricing for display
  Map<String, dynamic> getSubscriptionPricing(SubscriptionTier tier) {
    final monthlyPrice = tier.monthlyPrice;
    final yearlyPrice = tier.yearlyPrice;
    final yearlySavings = (monthlyPrice * 12) - yearlyPrice;

    return {
      'tier': tier,
      'monthlyPrice': monthlyPrice,
      'yearlyPrice': yearlyPrice,
      'yearlyMonthlyEquivalent': yearlyPrice / 12,
      'yearlySavings': yearlySavings,
      'features': tier.features,
    };
  }

  /// Get all subscription tiers with pricing
  List<Map<String, dynamic>> getAllSubscriptionPricing() {
    return SubscriptionTier.values
        .where((tier) => tier != SubscriptionTier.free)
        .map((tier) => getSubscriptionPricing(tier))
        .toList();
  }

  /// Check if user can access feature based on subscription
  Future<bool> canAccessFeature(String userId, String feature) async {
    try {
      final tier = await _purchaseService.getUserSubscriptionTier(userId);
      return _checkFeatureAccess(tier, feature);
    } catch (e) {
      AppLogger.error('Error checking feature access: $e');
      return false;
    }
  }

  /// Check feature access based on tier
  bool _checkFeatureAccess(SubscriptionTier tier, String feature) {
    switch (feature) {
      case 'unlimited_artworks':
        return tier == SubscriptionTier.business ||
            tier == SubscriptionTier.enterprise;
      case 'advanced_analytics':
        return tier == SubscriptionTier.creator ||
            tier == SubscriptionTier.business ||
            tier == SubscriptionTier.enterprise;
      case 'team_collaboration':
        return tier == SubscriptionTier.business ||
            tier == SubscriptionTier.enterprise;
      case 'api_access':
        return tier == SubscriptionTier.business ||
            tier == SubscriptionTier.enterprise;
      case 'white_label':
        return tier == SubscriptionTier.enterprise;
      case 'priority_support':
        return tier == SubscriptionTier.creator ||
            tier == SubscriptionTier.business ||
            tier == SubscriptionTier.enterprise;
      default:
        return true; // Basic features available to all
    }
  }

  /// Get usage limits based on subscription tier
  Map<String, int> getUsageLimits(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return {
          'artworks': 3,
          'storage_gb': 1, // 0.5GB converted to MB for easier calculation
          'ai_credits': 5,
          'team_members': 1,
        };
      case SubscriptionTier.starter:
        return {
          'artworks': 25,
          'storage_gb': 5,
          'ai_credits': 50,
          'team_members': 1,
        };
      case SubscriptionTier.creator:
        return {
          'artworks': 100,
          'storage_gb': 25,
          'ai_credits': 200,
          'team_members': 1,
        };
      case SubscriptionTier.business:
        return {
          'artworks': -1, // Unlimited
          'storage_gb': 100,
          'ai_credits': 500,
          'team_members': 5,
        };
      case SubscriptionTier.enterprise:
        return {
          'artworks': -1, // Unlimited
          'storage_gb': -1, // Unlimited
          'ai_credits': -1, // Unlimited
          'team_members': -1, // Unlimited
        };
    }
  }

  /// Check if user has reached usage limit
  Future<bool> hasReachedLimit(String userId, String limitType) async {
    try {
      final tier = await _purchaseService.getUserSubscriptionTier(userId);
      final limits = getUsageLimits(tier);
      final limit = limits[limitType] ?? 0;

      if (limit == -1) return false; // Unlimited

      // Get current usage from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data()!;
      final currentUsage = data['${limitType}_count'] as int? ?? 0;

      return currentUsage >= limit;
    } catch (e) {
      AppLogger.error('Error checking usage limit: $e');
      return false;
    }
  }

  /// Get product ID for subscription tier
  String? _getProductIdForTier(SubscriptionTier tier, bool isYearly) {
    final suffix = isYearly ? 'yearly' : 'monthly';

    switch (tier) {
      case SubscriptionTier.starter:
        return 'artbeat_starter_$suffix';
      case SubscriptionTier.creator:
        return 'artbeat_creator_$suffix';
      case SubscriptionTier.business:
        return 'artbeat_business_$suffix';
      case SubscriptionTier.enterprise:
        return 'artbeat_enterprise_$suffix';
      case SubscriptionTier.free:
        return null;
    }
  }

  /// Get user's subscription status
  Future<Map<String, dynamic>> getUserSubscriptionStatus(String userId) async {
    try {
      final tier = await _purchaseService.getUserSubscriptionTier(userId);
      final activeSubscriptions = await _purchaseService
          .getUserActiveSubscriptions(userId);
      final limits = getUsageLimits(tier);

      // Get current usage
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.exists ? userDoc.data()! : <String, dynamic>{};

      return {
        'tier': tier,
        'isActive': activeSubscriptions.isNotEmpty,
        'subscriptions': activeSubscriptions,
        'limits': limits,
        'usage': {
          'artworks': userData['artworks_count'] ?? 0,
          'storage_gb': userData['storage_used_gb'] ?? 0,
          'ai_credits': userData['ai_credits_used'] ?? 0,
          'team_members': userData['team_members_count'] ?? 1,
        },
        'features': tier.features,
      };
    } catch (e) {
      AppLogger.error('Error getting subscription status: $e');
      return {
        'tier': SubscriptionTier.free,
        'isActive': false,
        'subscriptions': <SubscriptionDetails>[],
        'limits': getUsageLimits(SubscriptionTier.free),
        'usage': <String, int>{},
        'features': SubscriptionTier.free.features,
      };
    }
  }

  /// Restore subscription purchases
  Future<void> restoreSubscriptions() async {
    try {
      // This will be handled by the main InAppPurchaseService
      AppLogger.info('Restoring subscription purchases...');
    } catch (e) {
      AppLogger.error('Error restoring subscriptions: $e');
    }
  }
}
