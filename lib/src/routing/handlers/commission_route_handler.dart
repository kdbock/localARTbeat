import 'package:artbeat_community/artbeat_community.dart' as community;
import 'package:flutter/material.dart';

import '../route_utils.dart';

class CommissionRouteHandler {
  const CommissionRouteHandler();

  Route<dynamic>? handleRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/commission/request':
        final args = settings.arguments as Map<String, dynamic>?;
        final artistId = args?['artistId'] as String?;
        final artistName = args?['artistName'] as String?;

        if (artistId == null || artistName == null) {
          return RouteUtils.createSimpleRoute(
            child: const community.DirectCommissionsScreen(),
          );
        }

        return RouteUtils.createSimpleRoute(
          child: community.CommissionRequestScreen(
            artistId: artistId,
            artistName: artistName,
          ),
        );

      case '/commission/hub':
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Commission Hub'),
          child: const community.CommissionHubScreen(),
        );

      default:
        return RouteUtils.createNotFoundRoute('Commission feature');
    }
  }
}
