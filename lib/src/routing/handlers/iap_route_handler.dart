import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_sponsorships/artbeat_sponsorships.dart' as sponsorships;
import 'package:flutter/material.dart';

import '../route_utils.dart';

class IapRouteHandler {
  const IapRouteHandler();

  Route<dynamic>? handleRoute(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.subscriptions:
      case core.AppRoutes.ads:
        return RouteUtils.createMainLayoutRoute(
          child: const sponsorships.LocalBusinessScreen(),
        );

      default:
        return RouteUtils.createNotFoundRoute('In-App Purchase feature');
    }
  }
}
