import 'package:artbeat_ads/artbeat_ads.dart' as ads;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:flutter/material.dart';

import '../route_utils.dart';

class AdsRouteHandler {
  const AdsRouteHandler();

  Route<dynamic>? handleRoute(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.adsCreate:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Create Local Ad'),
          child: const ads.CreateLocalAdScreen(),
        );

      case core.AppRoutes.adsManagement:
      case '/ads/my-ads':
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('My Ads'),
          child: const ads.MyAdsScreen(),
        );

      case core.AppRoutes.adsStatistics:
      case '/ads/my-statistics':
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Browse Local Ads'),
          child: const ads.LocalAdsListScreen(),
        );

      case core.AppRoutes.adPayment:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Submit Local Ad'),
          child: const ads.CreateLocalAdScreen(),
        );

      default:
        return RouteUtils.createComingSoonRoute('Ads feature');
    }
  }
}
