import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:flutter/material.dart';

import '../../screens/ads_route_screen.dart';
import '../route_utils.dart';

class IapRouteHandler {
  const IapRouteHandler();

  Route<dynamic>? handleRoute(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.subscriptions:
        return RouteUtils.createMainLayoutRoute(
          child: const core.SubscriptionPlansScreen(),
        );

      case core.AppRoutes.boosts:
        return RouteUtils.createMainLayoutRoute(
          child: const core.ArtistBoostsScreen(),
        );

      case core.AppRoutes.ads:
        return RouteUtils.createMainLayoutRoute(child: const AdsRouteScreen());

      default:
        return RouteUtils.createNotFoundRoute('In-App Purchase feature');
    }
  }
}
