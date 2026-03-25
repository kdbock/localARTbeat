import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_auth/artbeat_auth.dart' as auth;
import 'package:artbeat_community/artbeat_community.dart' as community;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_events/artbeat_events.dart' as events;
import 'package:artbeat_profile/artbeat_profile.dart' as profile;
import 'package:artbeat_sponsorships/artbeat_sponsorships.dart' as sponsorships;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../screens/in_app_purchase_demo_screen.dart';
import '../../../test_payment_debug.dart';
import '../../screens/ads_route_screen.dart';
import '../route_utils.dart';

class RootRouteHandler {
  const RootRouteHandler();

  bool isProtectedRoute(String routeName) =>
      routeName != core.AppRoutes.splash &&
      routeName != core.AppRoutes.dashboard &&
      routeName != core.AppRoutes.login &&
      routeName != core.AppRoutes.register &&
      routeName != core.AppRoutes.forgotPassword &&
      routeName != core.AppRoutes.artistSearch &&
      routeName != core.AppRoutes.artistSearchShort &&
      routeName != core.AppRoutes.artistBrowse &&
      routeName != core.AppRoutes.artistFeatured &&
      routeName != core.AppRoutes.trending &&
      routeName != core.AppRoutes.local &&
      routeName != core.AppRoutes.artworkBrowse &&
      routeName != core.AppRoutes.artworkFeatured &&
      routeName != core.AppRoutes.artworkRecent &&
      routeName != core.AppRoutes.artworkTrending &&
      routeName != core.AppRoutes.artworkSearch &&
      routeName != core.AppRoutes.allEvents &&
      routeName != core.AppRoutes.chapterLanding &&
      routeName != core.AppRoutes.search &&
      routeName != '/art-walk/map' &&
      routeName != '/art-walk/dashboard' &&
      routeName != '/capture/camera' &&
      routeName != '/community/hub' &&
      routeName != '/events/discover' &&
      !routeName.startsWith('/public/') &&
      !routeName.startsWith('/art-walk/') &&
      !routeName.startsWith('/community/');

  Route<dynamic>? handleDirectRoute(
    RouteSettings settings, {
    required Widget Function(String routeName) buildOnboardingScreen,
  }) {
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
      case core.AppRoutes.login:
        return RouteUtils.createSimpleRoute(child: const auth.LoginScreen());
      case core.AppRoutes.register:
        return RouteUtils.createSimpleRoute(child: const auth.RegisterScreen());
      case core.AppRoutes.forgotPassword:
        return RouteUtils.createSimpleRoute(
          child: const auth.ForgotPasswordScreen(),
        );
      case core.AppRoutes.profileEdit:
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        return RouteUtils.createMainNavRoute(
          child: profile.EditProfileScreen(userId: currentUserId),
        );
      case core.AppRoutes.artistDashboard:
        return RouteUtils.createMainNavRoute(
          child: const core.AuthRequiredScreen(),
        );
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
      case core.AppRoutes.artistOnboardingWelcome:
      case core.AppRoutes.artistOnboardingIntroduction:
      case core.AppRoutes.artistOnboardingStory:
      case core.AppRoutes.artistOnboardingArtwork:
      case core.AppRoutes.artistOnboardingFeatured:
      case core.AppRoutes.artistOnboardingBenefits:
      case core.AppRoutes.artistOnboardingSelection:
        return RouteUtils.createSimpleRoute(
          child: buildOnboardingScreen(settings.name!),
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
