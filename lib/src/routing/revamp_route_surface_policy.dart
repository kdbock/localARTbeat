import 'package:artbeat_core/artbeat_core.dart' as core;

class RevampRouteSurfacePolicy {
  const RevampRouteSurfacePolicy();

  static const Set<String> hiddenRoutes = {
    '/billing',
    '/quest-history',
    '/settings/become-artist',
    '/store',
    '/weekly-goals',
    core.AppRoutes.adminDashboard,
    core.AppRoutes.adminModeration,
    core.AppRoutes.adminSettings,
    core.AppRoutes.artWalkAdminModeration,
    core.AppRoutes.artWalkAchievements,
    core.AppRoutes.artWalkSettings,
    core.AppRoutes.artworkModeration,
    core.AppRoutes.captureAdminModeration,
    core.AppRoutes.communityCreate,
    core.AppRoutes.communityMessaging,
    core.AppRoutes.communityModeration,
    core.AppRoutes.communityPortfolios,
    core.AppRoutes.developerFeedbackAdmin,
    core.AppRoutes.eventsArtistDashboard,
    core.AppRoutes.eventsCalendar,
    core.AppRoutes.eventsMyEvents,
    core.AppRoutes.eventsMyTickets,
    core.AppRoutes.eventsTickets,
    core.AppRoutes.galleryAnalytics,
    core.AppRoutes.galleryArtistsManagement,
    core.AppRoutes.subscriptionComparison,
    core.AppRoutes.subscriptionPlans,
    core.AppRoutes.subscriptions,
  };

  static const List<String> hiddenPrefixes = [
    '/admin',
    '/artist',
    '/artwork',
    '/commission',
    '/gallery',
    '/messaging',
    '/subscription',
  ];

  bool isHidden(String routeName) {
    if (hiddenRoutes.contains(routeName)) {
      return true;
    }

    for (final prefix in hiddenPrefixes) {
      if (routeName.startsWith(prefix)) {
        return true;
      }
    }

    return false;
  }
}
