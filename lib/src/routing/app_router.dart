import 'package:artbeat_auth/artbeat_auth.dart' as auth;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_core/auth_service.dart' as core_auth;
import 'package:flutter/material.dart';

import '../guards/auth_guard.dart';
import 'handlers/art_walk_route_handler.dart';
import 'handlers/auth_profile_route_handler.dart';
import 'handlers/capture_route_handler.dart';
import 'handlers/community_route_handler.dart';
import 'handlers/direct_route_handler.dart';
import 'handlers/events_route_handler.dart';
import 'handlers/iap_route_handler.dart';
import 'handlers/misc_route_handler.dart';
import 'handlers/profile_route_handler.dart';
import 'handlers/settings_route_handler.dart';
import 'handlers/specialized_route_dispatcher.dart';
import 'revamp_route_surface_policy.dart';
import 'route_access_policy.dart';
import 'route_utils.dart';

/// Main application router that handles all route generation
class AppRouter {
  final _authGuard = AuthGuard();
  final _authService = core_auth.AuthService();
  final _routeAccessPolicy = const RouteAccessPolicy();
  final _revampRouteSurfacePolicy = const RevampRouteSurfacePolicy();
  late final _authProfileRouteHandler = AuthProfileRouteHandler(
    authService: _authService,
  );
  final _artWalkRouteHandler = const ArtWalkRouteHandler();
  final _communityRouteHandler = const CommunityRouteHandler();
  final _directRouteHandler = const DirectRouteHandler();
  final _iapRouteHandler = const IapRouteHandler();
  final _captureRouteHandler = const CaptureRouteHandler();
  final _profileRouteHandler = const ProfileRouteHandler();
  late final _eventsRouteHandler = EventsRouteHandler(
    authService: _authService,
  );
  late final _settingsRouteHandler = SettingsRouteHandler(
    authService: _authService,
  );
  late final _miscRouteHandler = MiscRouteHandler(authService: _authService);
  late final _specializedRouteDispatcher = SpecializedRouteDispatcher(
    handleCommunityRoute: _communityRouteHandler.handleRoute,
    handleArtWalkRoute: _artWalkRouteHandler.handleRoute,
    handleEventsRoute: _eventsRouteHandler.handleRoute,
    handleProfileRoute: _profileRouteHandler.handleRoute,
    handleSettingsRoute: _settingsRouteHandler.handleRoute,
    handleCaptureRoute: _captureRouteHandler.handleRoute,
    handleIapRoute: _iapRouteHandler.handleRoute,
    handleMiscRoute: _miscRouteHandler.handleRoute,
  );
  /// Main route generation method
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeStart = DateTime.now();
    final routeName = settings.name;
    if (routeName == null) {
      return RouteUtils.createNotFoundRoute();
    }

    core.AppLogger.info('🛣️ Navigating to: $routeName');

    if (_revampRouteSurfacePolicy.isHidden(routeName)) {
      _trackRouteRendered(routeName, routeStart, source: 'revamp_paused');
      return RouteUtils.createRevampPausedRoute(routeName);
    }

    // Check if user is authenticated for protected routes
    if (!_authGuard.isAuthenticated &&
        _routeAccessPolicy.requiresAuthentication(routeName)) {
      core.UxSessionAnalyticsService().trackAuthInterrupt(
        routeName: routeName,
        source: 'router_guard',
      );
      core.UxSessionAnalyticsService().trackRouteRendered(
        routeName: auth.AuthRoutes.login,
        source: 'auth_guard_redirect',
        durationMs: DateTime.now().difference(routeStart).inMilliseconds,
        success: true,
      );
      return RouteUtils.createSimpleRoute(child: const auth.LoginScreen());
    }

    final authProfileRoute = _authProfileRouteHandler.handleRoute(settings);
    if (authProfileRoute != null) {
      _trackRouteRendered(routeName, routeStart, source: 'auth_profile_handler');
      return authProfileRoute;
    }

    final directRoute = _directRouteHandler.handleRoute(settings);
    if (directRoute != null) {
      _trackRouteRendered(routeName, routeStart, source: 'direct_handler');
      return directRoute;
    }

    final specializedRoute = _specializedRouteDispatcher.handleRoute(settings);
    if (specializedRoute != null) {
      _trackRouteRendered(routeName, routeStart, source: 'specialized_handler');
      return specializedRoute;
    }

    // Route not found
    _trackRouteRendered(routeName, routeStart, source: 'not_found');
    return RouteUtils.createNotFoundRoute();
  }

  void _trackRouteRendered(
    String routeName,
    DateTime routeStart, {
    required String source,
  }) {
    core.UxSessionAnalyticsService().trackRouteRendered(
      routeName: routeName,
      source: source,
      durationMs: DateTime.now().difference(routeStart).inMilliseconds,
      success: true,
    );
  }

}
