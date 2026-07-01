import 'package:artbeat_art_walk/artbeat_art_walk.dart' as art_walk;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_events/artbeat_events.dart' as events;
import 'package:artbeat_sponsorships/artbeat_sponsorships.dart' as sponsorships;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../test_payment_debug.dart';
import '../../screens/onboarding_funnel_report_screen.dart';
import '../../screens/user_onboarding_flow_screen.dart';
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
        return RouteUtils.createMainLayoutRoute(
          child: const sponsorships.LocalBusinessScreen(),
        );
      case core.AppRoutes.sponsorshipCreate:
        return RouteUtils.createMainLayoutRoute(
          child: const sponsorships.CreateSponsorshipScreen(),
        );
      case '/store':
        return RouteUtils.createRevampPausedRoute(settings.name);
      case core.AppRoutes.splash:
        return RouteUtils.createSimpleRoute(child: const core.SplashScreen());
      case core.AppRoutes.chapterLanding:
        return _chapterLandingRoute(settings);
      case core.AppRoutes.dashboard:
        return _dashboardRoute();
      case core.AppRoutes.artDiscovery:
      case '/community/discovery':
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const art_walk.InstantDiscoveryRadarScreen(),
        );
      case '/old-dashboard':
        if (!kDebugMode) {
          return RouteUtils.createNotFoundRoute('debug');
        }
        return RouteUtils.createMainNavRoute(
          currentIndex: 0,
          child: const core.ArtbeatDashboardScreen(),
        );
      case '/2025_modern_onboarding':
      case core.AppRoutes.userOnboarding:
        return RouteUtils.createSimpleRoute(
          child: const UserOnboardingFlowScreen(),
        );
      case '/debug/payment':
        if (!kDebugMode) {
          return RouteUtils.createNotFoundRoute('debug');
        }
        return RouteUtils.createSimpleRoute(child: const PaymentDebugScreen());
      case core.AppRoutes.onboardingFunnelAnalytics:
        return RouteUtils.createMainLayoutRoute(
          child: const OnboardingFunnelReportScreen(),
        );
      case core.AppRoutes.artworkBrowse:
        return RouteUtils.createRevampPausedRoute(settings.name);
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
        return RouteUtils.createRevampPausedRoute(settings.name);
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
        return RouteUtils.createRevampPausedRoute(settings.name);
      case core.AppRoutes.localBusiness:
        return RouteUtils.createMainLayoutRoute(
          child: const sponsorships.LocalBusinessScreen(),
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
