import 'package:artbeat_community/artbeat_community.dart' as community;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_sponsorships/artbeat_sponsorships.dart' as sponsorships;
import 'package:flutter/material.dart';

import '../route_utils.dart';

class CommunityRouteHandler {
  const CommunityRouteHandler();

  Route<dynamic>? handleRoute(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.communityDashboard:
      case core.AppRoutes.communityFeed:
        return RouteUtils.createMainNavRoute(
          currentIndex: 3,
          child: const community.ArtCommunityHub(),
        );

      case core.AppRoutes.communityArtists:
      case core.AppRoutes.communityPortfolios:
        return RouteUtils.createRevampPausedRoute(settings.name);

      case core.AppRoutes.communitySearch:
        return RouteUtils.createMainLayoutRoute(
          child: const core.SearchResultsPage(),
        );

      case core.AppRoutes.communityPosts:
      case core.AppRoutes.communityFeatured:
      case core.AppRoutes.community:
        return RouteUtils.createMainLayoutRoute(
          child: const community.ArtCommunityHub(),
        );

      case core.AppRoutes.communityMessaging:
        return RouteUtils.createRevampPausedRoute(settings.name);

      case core.AppRoutes.communityModeration:
        return RouteUtils.createRevampPausedRoute(settings.name);

      case core.AppRoutes.communitySponsorships:
        return RouteUtils.createMainLayoutRoute(
          child: const sponsorships.LocalBusinessScreen(),
        );

      case core.AppRoutes.communitySettings:
        return RouteUtils.createMainLayoutRoute(
          child: const community.QuietModeScreen(),
        );

      case core.AppRoutes.communityCreate:
        return RouteUtils.createRevampPausedRoute(settings.name);

      case core.AppRoutes.communityTrending:
        return RouteUtils.createMainLayoutRoute(
          child: const community.TrendingContentScreen(),
        );

      case core.AppRoutes.artCommunityHub:
        return RouteUtils.createMainNavRoute(
          currentIndex: 3,
          child: const community.ArtCommunityHub(),
        );

      default:
        return RouteUtils.createNotFoundRoute('Community feature');
    }
  }
}
