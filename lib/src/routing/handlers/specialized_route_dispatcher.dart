import 'package:flutter/material.dart';

typedef RouteHandlerDelegate = Route<dynamic>? Function(RouteSettings settings);

class SpecializedRouteDispatcher {
  SpecializedRouteDispatcher({
    required RouteHandlerDelegate handleCommunityRoute,
    required RouteHandlerDelegate handleArtWalkRoute,
    required RouteHandlerDelegate handleEventsRoute,
    required RouteHandlerDelegate handleProfileRoute,
    required RouteHandlerDelegate handleSettingsRoute,
    required RouteHandlerDelegate handleCaptureRoute,
    required RouteHandlerDelegate handleIapRoute,
    required RouteHandlerDelegate handleMiscRoute,
  }) : _routeMatchers = [
         _RouteMatcher.single('/community', handleCommunityRoute),
         _RouteMatcher.multi(const [
           '/art-walk',
           '/enhanced',
           '/artwalk',
           '/instant',
         ], handleArtWalkRoute),
         _RouteMatcher.single('/events', handleEventsRoute),
         _RouteMatcher.single('/profile', handleProfileRoute),
         _RouteMatcher.single('/settings', handleSettingsRoute),
         _RouteMatcher.single('/capture', handleCaptureRoute),
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
