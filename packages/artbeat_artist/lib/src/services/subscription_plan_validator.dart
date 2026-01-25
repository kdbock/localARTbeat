import '../utils/artist_logger.dart';

/// Validator for subscription plans and feature access
class SubscriptionPlanValidator {
  static final SubscriptionPlanValidator _instance =
      SubscriptionPlanValidator._internal();
  factory SubscriptionPlanValidator() => _instance;
  SubscriptionPlanValidator._internal();

  /// Validate if user has access to a specific feature based on their subscription
  bool hasFeatureAccess({
    required String subscriptionTier,
    required String feature,
  }) {
    final tierFeatures = _getTierFeatures(subscriptionTier);
    return tierFeatures.contains(feature);
  }

  /// Get all features available for a subscription tier
  List<String> getTierFeatures(String subscriptionTier) {
    return _getTierFeatures(subscriptionTier);
  }

  /// Check if upgrade from current tier to target tier is valid
  bool isValidUpgrade({
    required String currentTier,
    required String targetTier,
  }) {
    final tierHierarchy = _getTierHierarchy();
    final currentLevel = tierHierarchy[currentTier] ?? 0;
    final targetLevel = tierHierarchy[targetTier] ?? 0;

    return targetLevel > currentLevel;
  }

  /// Check if downgrade from current tier to target tier is valid
  bool isValidDowngrade({
    required String currentTier,
    required String targetTier,
  }) {
    final tierHierarchy = _getTierHierarchy();
    final currentLevel = tierHierarchy[currentTier] ?? 0;
    final targetLevel = tierHierarchy[targetTier] ?? 0;

    return targetLevel < currentLevel;
  }

  /// Get the maximum allowed values for a subscription tier
  Map<String, int> getTierLimits(String subscriptionTier) {
    return _getTierLimits(subscriptionTier);
  }

  /// Check if user is within limits for their subscription tier
  bool isWithinLimits({
    required String subscriptionTier,
    required String limitType,
    required int currentValue,
  }) {
    final limits = _getTierLimits(subscriptionTier);
    final limit = limits[limitType];

    if (limit == null) return true; // No limit for this feature
    if (limit == -1) return true; // Unlimited

    return currentValue <= limit;
  }

  /// Get subscription tier pricing
  double getTierPrice(String subscriptionTier) {
    final pricing = {
      'free': 0.0,
      'artist_basic': 0.0,
      'artist_pro': 9.99,
      'gallery': 49.99,
    };

    return pricing[subscriptionTier] ?? 0.0;
  }

  /// Get all available subscription tiers
  List<String> getAllTiers() {
    return ['free', 'artist_basic', 'artist_pro', 'gallery'];
  }

  /// Get subscription tier information
  Map<String, dynamic> getTierInfo(String subscriptionTier) {
    final tierInfo = {
      'free': {
        'name': 'Free',
        'description': 'Basic access to ARTbeat',
        'price': 0.0,
        'billing': 'free',
        'features': _getTierFeatures('free'),
        'limits': _getTierLimits('free'),
      },
      'artist_basic': {
        'name': 'Artist Basic',
        'description': 'Essential tools for emerging artists',
        'price': 0.0,
        'billing': 'free',
        'features': _getTierFeatures('artist_basic'),
        'limits': _getTierLimits('artist_basic'),
      },
      'artist_pro': {
        'name': 'Artist Pro',
        'description': 'Advanced features for professional artists',
        'price': 9.99,
        'billing': 'monthly',
        'features': _getTierFeatures('artist_pro'),
        'limits': _getTierLimits('artist_pro'),
      },
      'gallery': {
        'name': 'Gallery',
        'description': 'Complete gallery management solution',
        'price': 49.99,
        'billing': 'monthly',
        'features': _getTierFeatures('gallery'),
        'limits': _getTierLimits('gallery'),
      },
    };

    return tierInfo[subscriptionTier] ?? {};
  }

  /// Validate subscription data structure
  bool isValidSubscriptionData(Map<String, dynamic> subscriptionData) {
    final requiredFields = ['userId', 'tier', 'status', 'startDate'];

    for (final field in requiredFields) {
      if (!subscriptionData.containsKey(field) ||
          subscriptionData[field] == null) {
        ArtistLogger.error('Missing required field: $field');
        return false;
      }
    }

    // Validate tier exists
    if (!getAllTiers().contains(subscriptionData['tier'])) {
      ArtistLogger.error(
        'Invalid subscription tier: ${subscriptionData['tier']}',
      );
      return false;
    }

    // Validate status
    final validStatuses = ['active', 'inactive', 'cancelled', 'pending'];
    if (!validStatuses.contains(subscriptionData['status'])) {
      ArtistLogger.error(
        'Invalid subscription status: ${subscriptionData['status']}',
      );
      return false;
    }

    return true;
  }

  // Private helper methods

  List<String> _getTierFeatures(String subscriptionTier) {
    final features = {
      'free': [
        'basic_profile',
        'artwork_upload',
        'community_access',
        'basic_analytics',
      ],
      'artist_basic': [
        'basic_profile',
        'artwork_upload',
        'community_access',
        'basic_analytics',
        'profile_customization',
        'social_sharing',
        'follower_insights',
      ],
      'artist_pro': [
        'basic_profile',
        'artwork_upload',
        'community_access',
        'basic_analytics',
        'profile_customization',
        'social_sharing',
        'follower_insights',
        'advanced_analytics',
        'subscription_management',
        'event_creation',
        'commission_tracking',
        'marketing_tools',
        'priority_support',
      ],
      'gallery': [
        'basic_profile',
        'artwork_upload',
        'community_access',
        'basic_analytics',
        'profile_customization',
        'social_sharing',
        'follower_insights',
        'advanced_analytics',
        'subscription_management',
        'event_creation',
        'commission_tracking',
        'marketing_tools',
        'priority_support',
        'gallery_management',
        'artist_management',
        'exhibition_planning',
        'bulk_operations',
        'white_label_options',
      ],
    };

    return features[subscriptionTier] ?? [];
  }

  Map<String, int> _getTierLimits(String subscriptionTier) {
    final limits = {
      'free': {
        'artworks': 10,
        'events': 1,
        'followers': 100,
        'storage_mb': 100,
      },
      'artist_basic': {
        'artworks': 50,
        'events': 3,
        'followers': 1000,
        'storage_mb': 500,
      },
      'artist_pro': {
        'artworks': -1, // Unlimited
        'events': -1,
        'followers': -1,
        'storage_mb': 5000,
      },
      'gallery': {
        'artworks': -1,
        'events': -1,
        'followers': -1,
        'storage_mb': -1,
        'artists': -1,
        'exhibitions': -1,
      },
    };

    return limits[subscriptionTier] ?? {};
  }

  Map<String, int> _getTierHierarchy() {
    return {'free': 0, 'artist_basic': 1, 'artist_pro': 2, 'gallery': 3};
  }
}
