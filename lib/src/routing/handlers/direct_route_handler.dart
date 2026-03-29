import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_community/artbeat_community.dart' as community;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_events/artbeat_events.dart' as events;
import 'package:artbeat_sponsorships/artbeat_sponsorships.dart' as sponsorships;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../screens/in_app_purchase_demo_screen.dart';
import '../../../test_payment_debug.dart';
import '../../screens/ads_route_screen.dart';
import '../route_utils.dart';

class DirectRouteHandler {
  const DirectRouteHandler();

  Route<dynamic>? handleRoute(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.sponsorshipArtWalk:
        return RouteUtils.createMainLayoutRoute(
          child: const sponsorships.ArtWalkSponsorshipScreen(),
        );
      case core.AppRoutes.sponsorshipCapture:
      case core.AppRoutes.sponsorshipDiscover:
        return RouteUtils.createMainLayoutRoute(child: const AdsRouteScreen());
      case core.AppRoutes.sponsorshipCreate:
        return RouteUtils.createMainLayoutRoute(
          child: const sponsorships.CreateSponsorshipScreen(),
        );
      case '/store':
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Artbeat Store'),
          child: const core.ArtbeatStoreScreen(),
        );
      case core.AppRoutes.splash:
        return RouteUtils.createSimpleRoute(child: const core.SplashScreen());
      case core.AppRoutes.chapterLanding:
        return _chapterLandingRoute(settings);
      case core.AppRoutes.dashboard:
        return _dashboardRoute();
      case core.AppRoutes.artDiscovery:
      case '/community/discovery':
        return RouteUtils.createMainLayoutRoute(
          child: const artwork.ArtworkDiscoveryScreen(),
        );
      case '/old-dashboard':
        return RouteUtils.createMainNavRoute(
          currentIndex: 0,
          child: const core.ArtbeatDashboardScreen(),
        );
      case '/2025_modern_onboarding':
        return RouteUtils.createSimpleRoute(
          child: const core.AuthRequiredScreen(),
        );
      case '/debug/payment':
        if (!kDebugMode) {
          return RouteUtils.createNotFoundRoute('debug');
        }
        return RouteUtils.createSimpleRoute(child: const PaymentDebugScreen());
      case core.AppRoutes.artworkBrowse:
        return RouteUtils.createSimpleRoute(
          child: const artwork.ArtworkBrowseScreen(),
        );
      case core.AppRoutes.search:
        return _searchRoute(settings);
      case core.AppRoutes.searchResults:
        final query = RouteUtils.getArgument<String>(settings, 'query');
        return RouteUtils.createMainNavRoute(
          child: core.SearchResultsPage(initialQuery: query),
        );
      case core.AppRoutes.browse:
        return RouteUtils.createMainNavRoute(
          child: const core.FullBrowseScreen(),
        );
      case '/community/create-post':
        return RouteUtils.createMainNavRoute(
          child: const community.CreateGroupPostScreen(
            groupType: community.GroupType.artist,
            postType: 'artwork',
          ),
        );
      case '/events/create':
        return RouteUtils.createMainNavRoute(
          child: const events.CreateEventScreen(),
        );
      case core.AppRoutes.artistSearch:
      case core.AppRoutes.artistSearchShort:
      case core.AppRoutes.trending:
        return RouteUtils.createMainNavRoute(
          child: const core.AuthRequiredScreen(),
        );
      case core.AppRoutes.local:
        return RouteUtils.createMainNavRoute(
          child: const events.EventsDashboardScreen(),
        );
      case core.AppRoutes.inAppPurchaseDemo:
        if (!kDebugMode) {
          return RouteUtils.createNotFoundRoute('debug');
        }
        return RouteUtils.createMainNavRoute(
          child: const InAppPurchaseDemoScreen(),
        );
      case core.AppRoutes.localBusiness:
        return RouteUtils.createMainLayoutRoute(
          child: const sponsorships.LocalBusinessScreen(),
        );
      case '/auction/hub':
        return RouteUtils.createMainLayoutRoute(
          child: const core.AuthRequiredScreen(),
        );
      default:
        return null;
    }
  }

  Route<dynamic> _chapterLandingRoute(RouteSettings settings) {
    final chapterId = RouteUtils.getArgument<String>(settings, 'chapterId');
    if (chapterId == null) {
      return RouteUtils.createNotFoundRoute('Chapter ID required');
    }

    return RouteUtils.createMainNavRoute(
      currentIndex: 0,
      child: core.ChapterLandingScreen(chapterId: chapterId),
    );
  }

  Route<dynamic> _dashboardRoute() {
    final bottomNavKey = GlobalKey();
    final bottomNavItemKeys = List.generate(5, (_) => GlobalKey());
    return RouteUtils.createMainNavRoute(
      currentIndex: 0,
      bottomNavKey: bottomNavKey,
      bottomNavItemKeys: bottomNavItemKeys,
      child: core.AnimatedDashboardScreen(
        bottomNavKey: bottomNavKey,
        bottomNavItemKeys: bottomNavItemKeys,
      ),
    );
  }

  Route<dynamic> _searchRoute(RouteSettings settings) {
    final query = RouteUtils.getArgument<String>(settings, 'query');
    var initialQuery = query;
    final routeName = settings.name;
    if (initialQuery == null && routeName != null && routeName.contains('?')) {
      initialQuery = Uri.parse(routeName).queryParameters['q'];
    }

    return RouteUtils.createMainNavRoute(
      child: core.SearchResultsPage(initialQuery: initialQuery),
    );
  }
}
