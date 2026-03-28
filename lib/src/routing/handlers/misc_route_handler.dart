import 'package:artbeat_admin/artbeat_admin.dart' as admin;
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_core/auth_service.dart' as core_auth;
import 'package:artbeat_events/artbeat_events.dart' as events;
import 'package:artbeat_profile/artbeat_profile.dart' as profile;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../screens/notifications_screen.dart';
import '../../guards/auth_guard.dart';
import '../../screens/about_screen.dart';
import '../../screens/privacy_policy_screen.dart';
import '../../screens/rewards_screen.dart';
import '../../screens/terms_of_service_screen.dart';
import '../route_utils.dart';

class MiscRouteHandler {
  const MiscRouteHandler({required core_auth.AuthService authService})
    : _authService = authService;

  final core_auth.AuthService _authService;

  Route<dynamic>? handleRoute(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.achievements:
        return RouteUtils.createMainLayoutRoute(
          child: const profile.AchievementsScreen(),
        );

      case core.AppRoutes.achievementsInfo:
        return RouteUtils.createMainLayoutRoute(
          child: const profile.AchievementInfoScreen(),
        );

      case core.AppRoutes.leaderboard:
        return RouteUtils.createMainLayoutRoute(
          child: const core.LeaderboardScreen(),
        );

      case core.AppRoutes.notifications:
        return RouteUtils.createMainLayoutRoute(
          child: const NotificationsScreen(useScaffold: false),
          drawer: const events.EventsDrawer(),
          currentIndex: 4,
        );

      case core.AppRoutes.search:
        return RouteUtils.createMainLayoutRoute(
          child: const core.SearchResultsPage(),
        );

      case core.AppRoutes.searchResults:
        final searchArgs = settings.arguments as Map<String, dynamic>?;
        final searchQuery = searchArgs?['query'] as String?;
        return RouteUtils.createMainLayoutRoute(
          child: core.SearchResultsPage(initialQuery: searchQuery),
        );

      case core.AppRoutes.feedback:
        return RouteUtils.createMainLayoutRoute(
          child: const core.FeedbackForm(),
        );

      case core.AppRoutes.developerFeedbackAdmin:
        return RouteUtils.createMainLayoutRoute(
          child: const admin.ModernUnifiedAdminDashboard(),
        );

      case core.AppRoutes.systemInfo:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('System Info - Coming Soon')),
        );

      case core.AppRoutes.support:
      case '/help':
        return RouteUtils.createMainLayoutRoute(
          child: const core.HelpSupportScreen(),
        );

      case '/favorites':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = _authService.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Center(child: Text('Favorites not available')),
              );
            }
            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar('Favorites'),
              child: profile.FavoritesScreen(userId: currentUser.uid),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/rewards':
        return RouteUtils.createMainLayoutRoute(child: const RewardsScreen());

      case '/billing':
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Billing & Payments'),
          child: const artist.PaymentMethodsScreen(),
        );

      case '/about':
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('About ARTbeat'),
          child: const AboutScreen(),
        );

      case '/privacy-policy':
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('common_privacy_policy'.tr()),
          child: const PrivacyPolicyScreen(),
        );

      case '/terms-of-service':
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('common_terms_of_service'.tr()),
          child: const TermsOfServiceScreen(),
        );

      default:
        return RouteUtils.createMainLayoutRoute(
          child: const core.SplashScreen(),
        );
    }
  }
}
