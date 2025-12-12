import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/artist_profile_model.dart';
import '../models/subscription_tier.dart';
import '../models/subscription_model.dart';
import '../models/user_type.dart';
import '../models/coupon_model.dart';
import '../models/feature_limits.dart';
import 'subscription_plan_validator.dart';
import 'subscription_validation_service.dart';
import 'coupon_service.dart';
import 'payment_service.dart';
import 'artist_feature_service.dart';
import '../utils/logger.dart';

/// Service for managing subscriptions
class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SubscriptionPlanValidator _planValidator = SubscriptionPlanValidator();
  final SubscriptionValidationService _validationService =
      SubscriptionValidationService();

  /// Get the current user's subscription
  Future<SubscriptionModel?> getUserSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return SubscriptionModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      AppLogger.error('Error getting user subscription: $e');
      return null;
    }
  }

  /// Get the current user's subscription tier
  Future<SubscriptionTier> getCurrentSubscriptionTier() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return SubscriptionTier.free;

      // Check if user has an artist profile
      final artistDoc = await _firestore
          .collection('artistProfiles')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (artistDoc.docs.isEmpty) return SubscriptionTier.free;

      // Get subscription tier from artist profile
      final artistProfile = ArtistProfileModel.fromFirestore(
        artistDoc.docs.first,
      );
      final tier = artistProfile.subscriptionTier;
      return tier;
    } catch (e) {
      AppLogger.error('Error getting current subscription tier: $e');
      return SubscriptionTier.free;
    }
  }

  /// Check if the current user is a subscriber (any paid tier)
  Future<bool> isSubscriber() async {
    try {
      final tier = await getCurrentSubscriptionTier();
      return tier == SubscriptionTier.starter ||
          tier == SubscriptionTier.creator ||
          tier == SubscriptionTier.business ||
          tier == SubscriptionTier.enterprise;
    } catch (e) {
      AppLogger.error('Error checking if user is subscriber: $e');
      return false;
    }
  }

  /// Get featured artists based on active features
  Future<List<ArtistProfileModel>> getFeaturedArtists() async {
    try {
      // Get artist IDs with active featured features
      final artistFeatureService = ArtistFeatureService();
      final featuredArtistIds = await artistFeatureService
          .getFeaturedArtistIds();

      if (featuredArtistIds.isEmpty) {
        return [];
      }

      // Get artist profiles for these IDs
      final artists = <ArtistProfileModel>[];
      for (final artistId in featuredArtistIds) {
        final artistDoc = await _firestore
            .collection('artistProfiles')
            .doc(artistId)
            .get();

        if (artistDoc.exists) {
          artists.add(ArtistProfileModel.fromFirestore(artistDoc));
        }
      }

      return artists;
    } catch (e) {
      AppLogger.error('Error getting featured artists: $e');
      return [];
    }
  }

  /// Get local artists based on location
  Future<List<ArtistProfileModel>> getLocalArtists(String location) async {
    try {
      final snapshot = await _firestore
          .collection('artistProfiles')
          .where('location', isEqualTo: location)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => ArtistProfileModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting local artists: $e');
      return [];
    }
  }

  /// Get all galleries
  Future<List<ArtistProfileModel>> getGalleries() async {
    try {
      final snapshot = await _firestore
          .collection('artistProfiles')
          .where('userType', isEqualTo: UserType.gallery.name)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => ArtistProfileModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting galleries: $e');
      return [];
    }
  }

  /// Get subscription details by tier
  Map<String, dynamic> getSubscriptionDetails(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.creator:
        return {
          'name': 'Creator',
          'price': 12.99,
          'priceId': 'price_creator_monthly_2025',
          'features': [
            'Unlimited artwork listings',
            'Featured in discover section',
            'Advanced analytics',
            'Priority support',
            'Event creation and promotion',
            'AI features: 50 credits/month',
          ],
        };
      case SubscriptionTier.business:
        return {
          'name': 'Business',
          'price': 29.99,
          'priceId': 'price_business_monthly_2025',
          'features': [
            'Multiple artist management',
            'Business profile for galleries',
            'Advanced analytics dashboard',
            'Dedicated support',
            'All Creator features',
            'AI features: 200 credits/month',
          ],
        };
      case SubscriptionTier.starter:
        return {
          'name': 'Starter',
          'price': 4.99,
          'priceId': 'price_starter_monthly_2025',
          'features': [
            'Artist profile page',
            'Up to 5 artwork listings',
            'Basic analytics',
            'Community features',
            'AI features: 10 credits/month',
          ],
        };
      case SubscriptionTier.free:
        return {
          'name': 'Free',
          'price': 0.00,
          'priceId': '',
          'features': [
            'Artist profile page',
            'Community features',
            'Basic support',
          ],
        };
      case SubscriptionTier.enterprise:
        return {
          'name': 'Enterprise',
          'price': 79.99,
          'priceId': 'price_enterprise_monthly_2025',
          'features': [
            'All Business features',
            'White-label branding',
            'Dedicated account manager',
            'SLA guarantee',
            'Custom integrations',
            'AI features: 1000 credits/month',
          ],
        };
    }
  }

  /// Validate and process subscription tier change
  Future<bool> changeTier(SubscriptionTier newTier) async {
    try {
      final currentTier = await getCurrentSubscriptionTier();

      // Check if transition is valid
      if (!await _planValidator.canTransitionTo(currentTier, newTier)) {
        AppLogger.info('Invalid tier transition from $currentTier to $newTier');
        return false;
      }

      // Start a transaction to update subscription data
      await _firestore.runTransaction((transaction) async {
        final userId = _auth.currentUser?.uid;
        if (userId == null) throw Exception('User not authenticated');

        // Get artist profile reference
        final artistQuery = await _firestore
            .collection('artistProfiles')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        DocumentReference artistRef;

        if (artistQuery.docs.isEmpty) {
          // Create a minimal artist profile for the user so subscription changes succeed.
          final displayName = _auth.currentUser?.displayName ?? '';
          artistRef = _firestore.collection('artistProfiles').doc();
          transaction.set(artistRef, {
            'userId': userId,
            'displayName': displayName,
            'userType': UserType.artist.name,
            'subscriptionTier': newTier.apiName,
            'isVerified': false,
            'isFeatured': false,
            'isPortfolioPublic': true,
            'mediums': <String>[],
            'styles': <String>[],
            'socialLinks': <String, String>{},
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'likesCount': 0,
            'viewsCount': 0,
            'artworksCount': 0,
          });
        } else {
          artistRef = artistQuery.docs.first.reference;

          // Update subscription tier in artist profile
          transaction.update(artistRef, {
            'subscriptionTier': newTier.apiName,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Update subscriptions collection
        final subscriptionQuery = await _firestore
            .collection('subscriptions')
            .where('userId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (subscriptionQuery.docs.isNotEmpty) {
          transaction.update(subscriptionQuery.docs.first.reference, {
            'tier': newTier.apiName,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          final newSubscriptionRef = _firestore
              .collection('subscriptions')
              .doc();
          transaction.set(newSubscriptionRef, {
            'userId': userId,
            'tier': newTier.apiName,
            'startDate': FieldValue.serverTimestamp(),
            'isActive': true,
            'autoRenew': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      return true;
    } catch (e) {
      AppLogger.error('Error changing subscription tier: $e');
      return false;
    }
  }

  /// Change subscription tier with validation
  Future<Map<String, dynamic>> changeTierWithValidation(
    SubscriptionTier newTier, {
    bool validateOnly = false,
  }) async {
    try {
      final validation = await _validationService.prepareTierChange(newTier);
      if ((validation['isValid'] as bool? ?? false) == false) {
        return validation;
      }

      if (validateOnly) {
        return validation;
      }

      // Start a transaction to update subscription data
      await _firestore.runTransaction((transaction) async {
        final userId = _auth.currentUser?.uid;
        if (userId == null) throw Exception('User not authenticated');

        // Get artist profile reference
        final artistQuery = await _firestore
            .collection('artistProfiles')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        DocumentReference artistRef;

        if (artistQuery.docs.isEmpty) {
          final displayName = _auth.currentUser?.displayName ?? '';
          artistRef = _firestore.collection('artistProfiles').doc();
          transaction.set(artistRef, {
            'userId': userId,
            'displayName': displayName,
            'userType': UserType.artist.name,
            'subscriptionTier': newTier.apiName,
            'isVerified': false,
            'isFeatured': false,
            'isPortfolioPublic': true,
            'mediums': <String>[],
            'styles': <String>[],
            'socialLinks': <String, String>{},
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'likesCount': 0,
            'viewsCount': 0,
            'artworksCount': 0,
          });
        } else {
          artistRef = artistQuery.docs.first.reference;

          // Update subscription tier in artist profile
          transaction.update(artistRef, {
            'subscriptionTier': newTier.apiName,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Update subscriptions collection
        final subscriptionQuery = await _firestore
            .collection('subscriptions')
            .where('userId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (subscriptionQuery.docs.isNotEmpty) {
          transaction.update(subscriptionQuery.docs.first.reference, {
            'tier': newTier.apiName,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          final newSubscriptionRef = _firestore
              .collection('subscriptions')
              .doc();
          transaction.set(newSubscriptionRef, {
            'userId': userId,
            'tier': newTier.apiName,
            'startDate': FieldValue.serverTimestamp(),
            'isActive': true,
            'autoRenew': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      return {
        'isValid': true,
        'message': 'Successfully changed subscription tier',
        'newTier': newTier,
      };
    } catch (e) {
      return {
        'isValid': false,
        'message': 'Error changing subscription tier: $e',
      };
    }
  }

  /// Get capabilities for current subscription tier
  Future<Map<String, dynamic>> getCurrentTierCapabilities() async {
    final tier = await getCurrentSubscriptionTier();
    return _planValidator.getTierCapabilities(tier);
  }

  /// Check if current tier allows a specific capability
  Future<bool> hasCapability(String capability) async {
    try {
      final capabilities = await getCurrentTierCapabilities();
      final dynamic value = capabilities[capability];
      return (value as bool?) ?? false;
    } catch (e) {
      AppLogger.error('Error checking capability $capability: $e');
      return false;
    }
  }

  // ===== COUPON METHODS =====

  /// Create a subscription with coupon support
  Future<Map<String, dynamic>> createSubscriptionWithCoupon({
    required SubscriptionTier tier,
    String? couponCode,
    String? paymentMethodId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final couponService = CouponService();
      final paymentService = PaymentService();

      // Get or create customer
      final customerId = await _getOrCreateCustomerId();
      if (customerId == null) {
        return {
          'success': false,
          'message': 'Failed to create payment customer',
        };
      }

      Map<String, dynamic>? couponResult;

      // Validate coupon if provided
      if (couponCode != null && couponCode.isNotEmpty) {
        try {
          couponResult = await couponService.applyCoupon(
            couponCode: couponCode,
            tier: tier,
            originalPrice: tier.monthlyPrice,
          );
        } catch (e) {
          return {'success': false, 'message': e.toString()};
        }
      }

      final coupon = couponResult?['coupon'] as CouponModel?;
      final isFree = couponResult?['isFree'] as bool? ?? false;

      Map<String, dynamic> subscriptionResult;

      if (isFree && coupon != null) {
        // Create free subscription
        subscriptionResult = await paymentService.createFreeSubscription(
          customerId: customerId,
          tier: tier,
          couponId: coupon.id,
          couponCode: coupon.code,
        );

        // Redeem the coupon
        await couponService.redeemCoupon(coupon.id);
      } else {
        // Create paid subscription (with or without discount)
        subscriptionResult = await paymentService.createSubscription(
          customerId: customerId,
          tier: tier,
          paymentMethodId: paymentMethodId,
          couponCode: couponCode,
        );

        // Redeem coupon if used
        if (coupon != null) {
          await couponService.redeemCoupon(coupon.id);
        }
      }

      // Update user profile with new subscription tier
      await updateUserSubscriptionTier(tier);

      return {
        'success': true,
        'message': isFree
            ? 'Free subscription activated successfully!'
            : 'Subscription created successfully!',
        'subscription': subscriptionResult,
        'couponApplied': coupon != null,
        'isFree': isFree,
      };
    } catch (e) {
      AppLogger.error('Error creating subscription with coupon: $e');
      return {'success': false, 'message': 'Failed to create subscription: $e'};
    }
  }

  /// Validate a coupon for a specific subscription tier
  Future<Map<String, dynamic>> validateCouponForSubscription({
    required String couponCode,
    required SubscriptionTier tier,
  }) async {
    try {
      final couponService = CouponService();

      final couponResult = await couponService.applyCoupon(
        couponCode: couponCode,
        tier: tier,
        originalPrice: tier.monthlyPrice,
      );

      final coupon = couponResult['coupon'] as CouponModel;
      final discountedPrice = couponResult['discountedPrice'] as double;
      final discountAmount = couponResult['discountAmount'] as double;
      final isFree = couponResult['isFree'] as bool;

      return {
        'valid': true,
        'coupon': coupon,
        'originalPrice': tier.monthlyPrice,
        'discountedPrice': discountedPrice,
        'discountAmount': discountAmount,
        'isFree': isFree,
        'message': isFree
            ? '🎉 Full access granted! No payment required.'
            : '✅ Coupon applied! ${discountAmount.toStringAsFixed(2)} discount.',
      };
    } catch (e) {
      return {'valid': false, 'message': e.toString()};
    }
  }

  /// Get user's coupon usage history
  Future<List<Map<String, dynamic>>> getUserCouponHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Get user's subscriptions with coupons
      final subscriptionsSnapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: user.uid)
          .where('couponId', isNull: false)
          .orderBy('createdAt', descending: true)
          .get();

      final couponService = CouponService();
      final history = <Map<String, dynamic>>[];

      for (final doc in subscriptionsSnapshot.docs) {
        final data = doc.data();
        final couponId = data['couponId'] as String?;
        final couponCode = data['couponCode'] as String?;

        if (couponId != null) {
          final coupon = await couponService.getCoupon(couponId);
          if (coupon != null) {
            history.add({
              'subscriptionId': doc.id,
              'coupon': coupon,
              'couponCode': couponCode,
              'tier': data['tier'],
              'originalPrice': data['originalPrice'] ?? 0.0,
              'discountedPrice': data['discountedPrice'] ?? 0.0,
              'revenue': data['revenue'] ?? 0.0,
              'isFree': data['isFree'] ?? false,
              'createdAt': data['createdAt'],
            });
          }
        }
      }

      return history;
    } catch (e) {
      AppLogger.error('Error getting coupon history: $e');
      return [];
    }
  }

  /// Helper method to get or create customer ID
  Future<String?> _getOrCreateCustomerId() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Check if user already has a customer ID
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final customerId = data?['stripeCustomerId'] as String?;
        if (customerId != null) return customerId;
      }

      // Create new customer
      final paymentService = PaymentService();
      final customerId = await paymentService.createCustomer(
        email: user.email ?? '',
        name: user.displayName ?? 'ARTbeat User',
      );

      return customerId;
    } catch (e) {
      AppLogger.error('Error getting/creating customer ID: $e');
      return null;
    }
  }

  /// Helper method to update user's subscription tier
  Future<void> updateUserSubscriptionTier(SubscriptionTier tier) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Update artist profile if it exists
      final artistQuery = await _firestore
          .collection('artistProfiles')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (artistQuery.docs.isNotEmpty) {
        // Update existing profile
        await _firestore
            .collection('artistProfiles')
            .doc(artistQuery.docs.first.id)
            .update({
              'subscriptionTier': tier.apiName,
              'updatedAt': FieldValue.serverTimestamp(),
            });
        AppLogger.info(
          'Updated existing artist profile subscription tier to ${tier.apiName}',
        );
      } else {
        // Create minimal artist profile if none exists
        // This handles cases where subscription purchase happens without prior onboarding
        AppLogger.warning(
          'No artist profile found for user ${user.uid} during subscription update. Creating minimal profile.',
        );

        final docRef = _firestore.collection('artistProfiles').doc();
        await docRef.set({
          'userId': user.uid,
          'displayName': user.displayName ?? 'Artist',
          'bio': 'Artist profile created via subscription purchase',
          'userType': 'artist',
          'location': '',
          'mediums': <String>[],
          'styles': <String>[],
          'socialLinks': <String, String>{},
          'profileImageUrl': null,
          'coverImageUrl': null,
          'isVerified': false,
          'isFeatured': false,
          'followerCount': 0,
          'subscriptionTier': tier.apiName,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        AppLogger.info(
          'Created new artist profile for user ${user.uid} with subscription tier ${tier.apiName}',
        );
      }
    } catch (e) {
      AppLogger.error('Error updating user subscription tier: $e');
    }
  }

  /// Upgrade user's subscription to a higher tier
  Future<void> upgradeSubscription(SubscriptionTier tier) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final currentTier = await getCurrentSubscriptionTier();

      // Validate that this is actually an upgrade
      final tierOrder = [
        SubscriptionTier.free,
        SubscriptionTier.starter,
        SubscriptionTier.creator,
        SubscriptionTier.business,
        SubscriptionTier.enterprise,
      ];

      final currentIndex = tierOrder.indexOf(currentTier);
      final newIndex = tierOrder.indexOf(tier);

      if (newIndex <= currentIndex) {
        throw Exception('Can only upgrade to a higher tier');
      }

      // Process payment for the upgrade
      final paymentService = PaymentService();

      // Get or create Stripe customer ID
      final customerId = await paymentService.getOrCreateCustomerId();

      // Create or update subscription
      await paymentService.createSubscription(
        customerId: customerId,
        tier: tier,
      );

      // Update the user's tier in Firestore
      await updateUserSubscriptionTier(tier);

      AppLogger.info(
        'Successfully upgraded subscription to ${tier.displayName}',
      );
    } catch (e) {
      AppLogger.error('Error upgrading subscription: $e');
      rethrow;
    }
  }

  /// Get feature limits for the current user's subscription tier
  Future<FeatureLimits> getFeatureLimits() async {
    try {
      final currentTier = await getCurrentSubscriptionTier();
      return FeatureLimits.forTier(currentTier);
    } catch (e) {
      AppLogger.error('Error getting feature limits: $e');
      // Return free tier limits as fallback
      return FeatureLimits.forTier(SubscriptionTier.free);
    }
  }

  /// Check if the current user has access to a specific feature
  Future<bool> checkFeatureAccess(String feature) async {
    try {
      final limits = await getFeatureLimits();

      switch (feature.toLowerCase()) {
        case 'advanced_analytics':
          return limits.hasAdvancedAnalytics;
        case 'featured_placement':
          return limits.hasFeaturedPlacement;
        case 'custom_branding':
          return limits.hasCustomBranding;
        case 'api_access':
          return limits.hasAPIAccess;
        case 'unlimited_support':
          return limits.hasUnlimitedSupport;
        case 'team_members':
          return limits.teamMembers > 1;
        case 'ai_credits':
          return limits.aiCredits > 0;
        default:
          AppLogger.info('Unknown feature: $feature');
          return false;
      }
    } catch (e) {
      AppLogger.error('Error checking feature access for $feature: $e');
      return false;
    }
  }
}
