import 'package:artbeat_admin/artbeat_admin.dart' as admin;
import 'package:artbeat_community/artbeat_community.dart' as community;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_sponsorships/artbeat_sponsorships.dart' as sponsorships;
import 'package:flutter/material.dart';

import '../route_utils.dart';

typedef AdminRouteHandlerDelegate = Route<dynamic>? Function(
  RouteSettings settings,
);

class CommunityRouteHandler {
  const CommunityRouteHandler();

  Route<dynamic>? handleRoute(
    RouteSettings settings, {
    required AdminRouteHandlerDelegate handleAdminRoute,
  }) {
    switch (settings.name) {
      case core.AppRoutes.communityDashboard:
      case core.AppRoutes.communityFeed:
        return RouteUtils.createMainNavRoute(
          currentIndex: 3,
          child: const community.ArtCommunityHub(),
        );

      case core.AppRoutes.communityArtists:
      case core.AppRoutes.communityPortfolios:
        return RouteUtils.createMainLayoutRoute(
          child: const community.PortfoliosScreen(),
        );

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

      case core.AppRoutes.communityStudios:
      case core.AppRoutes.communityMessaging:
        return RouteUtils.createMainLayoutRoute(
          child: const community.StudiosScreen(),
        );

      case core.AppRoutes.communityBoosts:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Boost Artists'),
          child: const community.ViewReceivedBoostsScreen(),
        );

      case core.AppRoutes.communityModeration:
        return handleAdminRoute(
          RouteSettings(
            name: admin.AdminRoutes.communityModeration,
            arguments: settings.arguments,
          ),
        );

      case core.AppRoutes.communitySponsorships:
        return RouteUtils.createMainLayoutRoute(
          child: const sponsorships.LocalBusinessScreen(),
        );

      case core.AppRoutes.communitySettings:
        return RouteUtils.createMainLayoutRoute(
          child: const community.QuietModeScreen(),
        );

      case core.AppRoutes.communityCreate:
        final args = settings.arguments as Map<String, dynamic>?;
        final prefilledImageUrl = args?['prefilledImageUrl'] as String?;
        final prefilledCaption = args?['prefilledCaption'] as String?;
        final isDiscussionPost = args?['isDiscussionPost'] as bool? ?? false;

        return RouteUtils.createMainLayoutRoute(
          child: community.CreatePostScreen(
            prefilledImageUrl: prefilledImageUrl,
            prefilledCaption: prefilledCaption,
            isDiscussionPost: isDiscussionPost,
          ),
        );

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
