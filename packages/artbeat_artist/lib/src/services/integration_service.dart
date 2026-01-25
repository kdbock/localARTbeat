import '../utils/artist_logger.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show
        UserService,
        SubscriptionService,
        ArtistProfileModel,
        UserModel,
        UserType;
import 'package:artbeat_core/src/models/subscription_model.dart'
    as core_subscription;
import '../models/subscription_model.dart' as artist_subscription;
import 'subscription_service.dart' as artist_service;

/// Service to handle cross-package integration and resolve conflicts
/// between artbeat_core and artbeat_artist functionality.
///
/// This service provides a unified interface for operations that span
/// multiple packages while maintaining clear separation of concerns.
class IntegrationService {
  static IntegrationService? _instance;
  static IntegrationService get instance =>
      _instance ??= IntegrationService._();

  IntegrationService._();

  final UserService _userService = UserService();
  final SubscriptionService _coreSubscriptionService = SubscriptionService();
  final artist_service.SubscriptionService _artistSubscriptionService =
      artist_service.SubscriptionService();

  /// Get unified artist data combining core and artist package functionality
  Future<UnifiedArtistData?> getUnifiedArtistData(String userId) async {
    try {
      ArtistLogger.error(
        '🔗 IntegrationService: Getting unified artist data for $userId',
      );

      // Get core user data
      final userModel = await _userService.getUserById(userId);
      if (userModel == null) {
        ArtistLogger.error('❌ IntegrationService: User not found');
        return null;
      }

      // Get artist profile if exists
      final artistProfile = await _artistSubscriptionService
          .getArtistProfileByUserId(userId);

      // Get subscription information from both sources
      final coreSubscription = await _coreSubscriptionService
          .getUserSubscription();
      final artistSubscription = await _artistSubscriptionService
          .getCurrentSubscription(userId);

      return UnifiedArtistData(
        userModel: userModel,
        artistProfile: artistProfile,
        coreSubscription: coreSubscription,
        artistSubscription: artistSubscription,
      );
    } catch (e) {
      ArtistLogger.error(
        '❌ IntegrationService: Error getting unified data: $e',
      );
      return null;
    }
  }

  /// Resolve subscription responsibilities:
  /// - Core handles basic subscription management
  /// - Artist handles artist-specific subscription features
  Future<SubscriptionCapabilities> getSubscriptionCapabilities(
    String userId,
  ) async {
    try {
      final unifiedData = await getUnifiedArtistData(userId);
      if (unifiedData == null) {
        return SubscriptionCapabilities.none();
      }

      // Determine capabilities based on subscriptions
      final hasCore =
          unifiedData.coreSubscription != null &&
          unifiedData.coreSubscription!.isActive;
      final hasArtist =
          unifiedData.artistSubscription != null &&
          unifiedData.artistSubscription!.isActive;
      final isArtist = unifiedData.artistProfile != null;

      return SubscriptionCapabilities(
        canAccessBasicFeatures: true,
        canAccessProFeatures: hasCore || hasArtist,
        canCreateArtwork: isArtist,
        canCreateEvents: isArtist && (hasArtist || hasCore),
        canAccessAnalytics: isArtist && (hasArtist || hasCore),
        canManageGallery: isArtist && hasArtist,
        maxArtworkUploads: _calculateMaxArtwork(unifiedData),
        preferredSubscriptionSource: hasArtist ? 'artist' : 'core',
      );
    } catch (e) {
      ArtistLogger.error(
        '❌ IntegrationService: Error determining capabilities: $e',
      );
      return SubscriptionCapabilities.none();
    }
  }

  int _calculateMaxArtwork(UnifiedArtistData data) {
    // Artist subscription takes precedence
    if (data.artistSubscription?.isActive == true) {
      switch (data.artistSubscription!.tier.name) {
        case 'creator':
        case 'business':
        case 'enterprise':
          return -1; // Unlimited
        default:
          return 5; // Basic limit
      }
    }

    // Fall back to core subscription
    if (data.coreSubscription?.isActive == true) {
      return 10; // Core subscription limit
    }

    return 5; // Default limit
  }

  /// Migrate user from core-only to artist-enabled account
  Future<bool> enableArtistFeatures(String userId) async {
    try {
      ArtistLogger.error(
        '🎨 IntegrationService: Enabling artist features for $userId',
      );

      // Check if user already has artist profile
      final existingProfile = await _artistSubscriptionService
          .getArtistProfileByUserId(userId);
      if (existingProfile != null) {
        ArtistLogger.error(
          'ℹ️ IntegrationService: Artist profile already exists',
        );
        return true;
      }

      // Get user details for profile creation
      final userModel = await _userService.getUserById(userId);
      if (userModel == null) {
        ArtistLogger.error(
          '❌ IntegrationService: Cannot create artist profile - user not found',
        );
        return false;
      }

      // Create artist profile with basic information
      final profileId = await _artistSubscriptionService.createArtistProfile(
        userId: userId,
        displayName: userModel.fullName.isNotEmpty
            ? userModel.fullName
            : 'New Artist',
        bio: 'Welcome to my artist profile!',
        userType: UserType.artist,
        location: userModel.location.isNotEmpty
            ? userModel.location
            : 'Location',
        mediums: ['Digital Art'], // Default medium
        styles: ['Contemporary'], // Default style
        socialLinks: {},
      );

      final success = profileId.isNotEmpty;
      if (success) {
        ArtistLogger.error(
          '✅ IntegrationService: Artist features enabled successfully',
        );
      } else {
        ArtistLogger.error(
          '❌ IntegrationService: Failed to enable artist features',
        );
      }

      return success;
    } catch (e) {
      ArtistLogger.error(
        '❌ IntegrationService: Error enabling artist features: $e',
      );
      return false;
    }
  }

  /// Get recommended subscription upgrade path
  Future<SubscriptionRecommendation> getSubscriptionRecommendation(
    String userId,
  ) async {
    try {
      final capabilities = await getSubscriptionCapabilities(userId);
      final unifiedData = await getUnifiedArtistData(userId);

      if (unifiedData?.artistProfile == null) {
        return SubscriptionRecommendation(
          type: 'enable-artist',
          title: 'Become an Artist',
          description: 'Unlock artist features to showcase your work',
          action: () => enableArtistFeatures(userId),
        );
      }

      if (!capabilities.canAccessProFeatures) {
        return SubscriptionRecommendation(
          type: 'upgrade-pro',
          title: 'Upgrade to Pro',
          description: 'Get unlimited uploads and advanced analytics',
          action: null, // Will be handled by subscription screens
        );
      }

      return SubscriptionRecommendation(
        type: 'none',
        title: 'You\'re all set!',
        description: 'You have access to all available features',
        action: null,
      );
    } catch (e) {
      ArtistLogger.error(
        '❌ IntegrationService: Error getting recommendation: $e',
      );
      return SubscriptionRecommendation(
        type: 'error',
        title: 'Unable to load recommendations',
        description: 'Please try again later',
        action: null,
      );
    }
  }
}

/// Unified data structure combining core and artist package information
class UnifiedArtistData {
  final UserModel userModel;
  final ArtistProfileModel? artistProfile;
  final core_subscription.SubscriptionModel?
  coreSubscription; // artbeat_core subscription
  final artist_subscription.SubscriptionModel?
  artistSubscription; // artbeat_artist subscription

  UnifiedArtistData({
    required this.userModel,
    this.artistProfile,
    this.coreSubscription,
    this.artistSubscription,
  });
}

/// Capabilities available to user based on their subscription status
class SubscriptionCapabilities {
  final bool canAccessBasicFeatures;
  final bool canAccessProFeatures;
  final bool canCreateArtwork;
  final bool canCreateEvents;
  final bool canAccessAnalytics;
  final bool canManageGallery;
  final int maxArtworkUploads; // -1 for unlimited
  final String preferredSubscriptionSource; // 'core' or 'artist'

  SubscriptionCapabilities({
    required this.canAccessBasicFeatures,
    required this.canAccessProFeatures,
    required this.canCreateArtwork,
    required this.canCreateEvents,
    required this.canAccessAnalytics,
    required this.canManageGallery,
    required this.maxArtworkUploads,
    required this.preferredSubscriptionSource,
  });

  factory SubscriptionCapabilities.none() {
    return SubscriptionCapabilities(
      canAccessBasicFeatures: true,
      canAccessProFeatures: false,
      canCreateArtwork: false,
      canCreateEvents: false,
      canAccessAnalytics: false,
      canManageGallery: false,
      maxArtworkUploads: 0,
      preferredSubscriptionSource: 'core',
    );
  }
}

/// Recommendation for subscription upgrade or feature activation
class SubscriptionRecommendation {
  final String type; // 'none', 'enable-artist', 'upgrade-pro', 'error'
  final String title;
  final String description;
  final Future<bool> Function()? action;

  SubscriptionRecommendation({
    required this.type,
    required this.title,
    required this.description,
    this.action,
  });
}
