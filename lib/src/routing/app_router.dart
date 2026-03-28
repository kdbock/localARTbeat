import 'package:artbeat_auth/artbeat_auth.dart' as auth;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_core/auth_service.dart' as core_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../guards/auth_guard.dart';
import 'handlers/admin_route_handler.dart' as admin_handler;
import 'handlers/ads_route_handler.dart';
import 'handlers/art_walk_route_handler.dart';
import 'handlers/artist_route_handler.dart';
import 'handlers/artwork_route_handler.dart';
import 'handlers/auth_profile_route_handler.dart';
import 'handlers/capture_route_handler.dart';
import 'handlers/commission_route_handler.dart';
import 'handlers/community_route_handler.dart';
import 'handlers/direct_route_handler.dart';
import 'handlers/events_route_handler.dart';
import 'handlers/gallery_route_handler.dart';
import 'handlers/iap_route_handler.dart';
import 'handlers/messaging_route_handler.dart';
import 'handlers/misc_route_handler.dart';
import 'handlers/profile_route_handler.dart';
import 'handlers/settings_route_handler.dart';
import 'handlers/specialized_route_dispatcher.dart';
import 'handlers/subscription_route_handler.dart';
import 'route_access_policy.dart';
import 'route_utils.dart';

/// Main application router that handles all route generation
class AppRouter {
  final _authGuard = AuthGuard();
  final _authService = core_auth.AuthService();
  final _routeAccessPolicy = const RouteAccessPolicy();
  final _adminRouteHandler = const admin_handler.AdminRouteHandler();
  late final _authProfileRouteHandler = AuthProfileRouteHandler(
    authService: _authService,
    buildOnboardingScreen: _buildOnboardingScreen,
  );
  final _artWalkRouteHandler = const ArtWalkRouteHandler();
  final _artworkRouteHandler = const ArtworkRouteHandler();
  final _adsRouteHandler = const AdsRouteHandler();
  final _commissionRouteHandler = const CommissionRouteHandler();
  final _communityRouteHandler = const CommunityRouteHandler();
  final _directRouteHandler = const DirectRouteHandler();
  final _galleryRouteHandler = const GalleryRouteHandler();
  final _iapRouteHandler = const IapRouteHandler();
  final _captureRouteHandler = const CaptureRouteHandler();
  final _messagingRouteHandler = const MessagingRouteHandler();
  final _profileRouteHandler = const ProfileRouteHandler();
  late final _artistRouteHandler = ArtistRouteHandler(
    authService: _authService,
    buildOnboardingScreen: _buildOnboardingScreen,
  );
  late final _eventsRouteHandler = EventsRouteHandler(authService: _authService);
  late final _settingsRouteHandler = SettingsRouteHandler(
    authService: _authService,
  );
  final _subscriptionRouteHandler = const SubscriptionRouteHandler();
  late final _miscRouteHandler = MiscRouteHandler(authService: _authService);
  late final _specializedRouteDispatcher = SpecializedRouteDispatcher(
    handleArtistRoute: _artistRouteHandler.handleRoute,
    handleArtworkRoute: _artworkRouteHandler.handleRoute,
    handleGalleryRoute: _galleryRouteHandler.handleRoute,
    handleCommissionRoute: _commissionRouteHandler.handleRoute,
    handleCommunityRoute: (settings) => _communityRouteHandler.handleRoute(
      settings,
      handleAdminRoute: _adminRouteHandler.handleRoute,
    ),
    handleArtWalkRoute: (settings) => _artWalkRouteHandler.handleRoute(
      settings,
      handleAdminRoute: _adminRouteHandler.handleRoute,
    ),
    handleMessagingRoute: _messagingRouteHandler.handleRoute,
    handleEventsRoute: _eventsRouteHandler.handleRoute,
    handleAdsRoute: _adsRouteHandler.handleRoute,
    handleAdminRoute: _adminRouteHandler.handleRoute,
    handleProfileRoute: _profileRouteHandler.handleRoute,
    handleSettingsRoute: _settingsRouteHandler.handleRoute,
    handleCaptureRoute: (settings) => _captureRouteHandler.handleRoute(
      settings,
      handleAdminRoute: _adminRouteHandler.handleRoute,
    ),
    handleSubscriptionRoute: _subscriptionRouteHandler.handleRoute,
    handleIapRoute: _iapRouteHandler.handleRoute,
    handleMiscRoute: _miscRouteHandler.handleRoute,
  );

  // Shared view model instance for artist onboarding
  // This ensures state persists across all onboarding screens
  static core.ArtistOnboardingViewModel? _onboardingViewModel;

  /// Main route generation method
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;
    if (routeName == null) {
      return RouteUtils.createNotFoundRoute();
    }

    core.AppLogger.info('🛣️ Navigating to: $routeName');

    // Check if user is authenticated for protected routes
    if (!_authGuard.isAuthenticated &&
        _routeAccessPolicy.requiresAuthentication(routeName)) {
      return RouteUtils.createSimpleRoute(child: const auth.LoginScreen());
    }

    final authProfileRoute = _authProfileRouteHandler.handleRoute(settings);
    if (authProfileRoute != null) {
      return authProfileRoute;
    }

    final directRoute = _directRouteHandler.handleRoute(settings);
    if (directRoute != null) {
      return directRoute;
    }

    final specializedRoute = _specializedRouteDispatcher.handleRoute(settings);
    if (specializedRoute != null) {
      return specializedRoute;
    }

    // Route not found
    return RouteUtils.createNotFoundRoute();
  }

  /// Get or create shared onboarding view model instance
  core.ArtistOnboardingViewModel _getOnboardingViewModel() {
    if (_onboardingViewModel == null) {
      _onboardingViewModel = core.ArtistOnboardingViewModel();
      _onboardingViewModel!.initialize();
    }
    return _onboardingViewModel!;
  }

  /// Build onboarding screen with shared view model
  Widget _buildOnboardingScreen(String routeName) {
    final viewModel = _getOnboardingViewModel();

    Widget screen;
    switch (routeName) {
      case core.AppRoutes.artistOnboardingWelcome:
        screen = const core.WelcomeScreen();
        break;
      case core.AppRoutes.artistOnboardingIntroduction:
        screen = const core.ArtistIntroductionScreen();
        break;
      case core.AppRoutes.artistOnboardingStory:
        screen = const core.ArtistStoryScreen();
        break;
      case core.AppRoutes.artistOnboardingArtwork:
        screen = const core.ArtworkUploadScreen();
        break;
      case core.AppRoutes.artistOnboardingFeatured:
        screen = const core.FeaturedArtworkScreen();
        break;
      case core.AppRoutes.artistOnboardingBenefits:
        screen = const core.BenefitsScreen();
        break;
      case core.AppRoutes.artistOnboardingSelection:
        screen = const core.TierSelectionScreen();
        break;
      default:
        screen = const core.WelcomeScreen();
    }

    return ChangeNotifierProvider<core.ArtistOnboardingViewModel>.value(
      value: viewModel,
      child: screen,
    );
  }
}
