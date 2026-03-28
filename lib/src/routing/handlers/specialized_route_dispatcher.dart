import 'package:flutter/material.dart';

typedef RouteHandlerDelegate = Route<dynamic>? Function(RouteSettings settings);

class SpecializedRouteDispatcher {
  SpecializedRouteDispatcher({
    required RouteHandlerDelegate handleArtistRoute,
    required RouteHandlerDelegate handleArtworkRoute,
    required RouteHandlerDelegate handleGalleryRoute,
    required RouteHandlerDelegate handleCommissionRoute,
    required RouteHandlerDelegate handleCommunityRoute,
    required RouteHandlerDelegate handleArtWalkRoute,
    required RouteHandlerDelegate handleMessagingRoute,
    required RouteHandlerDelegate handleEventsRoute,
    required RouteHandlerDelegate handleAdsRoute,
    required RouteHandlerDelegate handleAdminRoute,
    required RouteHandlerDelegate handleProfileRoute,
    required RouteHandlerDelegate handleSettingsRoute,
    required RouteHandlerDelegate handleCaptureRoute,
    required RouteHandlerDelegate handleSubscriptionRoute,
    required RouteHandlerDelegate handleIapRoute,
    required RouteHandlerDelegate handleMiscRoute,
  }) : _routeMatchers = [
         _RouteMatcher.single('/artist', handleArtistRoute),
         _RouteMatcher.single('/artwork', handleArtworkRoute),
         _RouteMatcher.single('/gallery', handleGalleryRoute),
         _RouteMatcher.single('/commission', handleCommissionRoute),
         _RouteMatcher.single('/community', handleCommunityRoute),
         _RouteMatcher.multi(const [
           '/art-walk',
           '/enhanced',
           '/artwalk',
           '/instant',
         ], handleArtWalkRoute),
         _RouteMatcher.single('/messaging', handleMessagingRoute),
         _RouteMatcher.single('/events', handleEventsRoute),
         _RouteMatcher.single('/ads', handleAdsRoute),
         _RouteMatcher.single('/admin', handleAdminRoute),
         _RouteMatcher.single('/profile', handleProfileRoute),
         _RouteMatcher.single('/settings', handleSettingsRoute),
         _RouteMatcher.single('/capture', handleCaptureRoute),
         _RouteMatcher.single('/subscription', handleSubscriptionRoute),
         _RouteMatcher.single('/iap', handleIapRoute),
       ],
       _handleMiscRoute = handleMiscRoute;

  final List<_RouteMatcher> _routeMatchers;
  final RouteHandlerDelegate _handleMiscRoute;

  Route<dynamic>? handleRoute(RouteSettings settings) {
    final routeName = settings.name;
    if (routeName == null) {
      return null;
    }

    for (final routeMatcher in _routeMatchers) {
      if (routeMatcher.matches(routeName)) {
        return routeMatcher.handle(settings);
      }
    }

    return _handleMiscRoute(settings);
  }
}

class _RouteMatcher {
  const _RouteMatcher(this._prefixes, this.handle);

  _RouteMatcher.single(String prefix, RouteHandlerDelegate handle)
    : this([prefix], handle);

  _RouteMatcher.multi(List<String> prefixes, RouteHandlerDelegate handle)
    : this(prefixes, handle);

  final List<String> _prefixes;
  final RouteHandlerDelegate handle;

  bool matches(String routeName) {
    for (final prefix in _prefixes) {
      if (routeName.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }
}
