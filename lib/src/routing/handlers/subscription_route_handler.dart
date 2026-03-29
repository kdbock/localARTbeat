import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:flutter/material.dart';

import '../route_utils.dart';

class SubscriptionRouteHandler {
  const SubscriptionRouteHandler();

  Route<dynamic>? handleRoute(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.subscriptionComparison:
        return RouteUtils.createMainLayoutRoute(
          child: const core.SubscriptionPurchaseScreen(
            tier: core.SubscriptionTier.starter,
          ),
        );

      case core.AppRoutes.subscriptionPlans:
        return RouteUtils.createMainLayoutRoute(
          child: const core.SubscriptionPlansScreen(),
        );

      case core.AppRoutes.paymentMethods:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Payment Methods'),
          child: const artist.PaymentMethodsScreen(),
        );

      case core.AppRoutes.paymentScreen:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Payment Screen'),
          child: const artist.PaymentMethodsScreen(),
        );

      case core.AppRoutes.paymentRefund:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Refunds'),
          child: const Center(child: Text('Refund management coming soon')),
        );

      default:
        return RouteUtils.createNotFoundRoute('Subscription feature');
    }
  }
}
