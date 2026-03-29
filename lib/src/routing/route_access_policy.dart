import 'package:artbeat_core/artbeat_core.dart' as core;

class RouteAccessPolicy {
  const RouteAccessPolicy();

  static const Set<String> _publicRoutes = {
    core.AppRoutes.splash,
    core.AppRoutes.dashboard,
    core.AppRoutes.login,
    core.AppRoutes.register,
    core.AppRoutes.forgotPassword,
    core.AppRoutes.artistSearch,
    core.AppRoutes.artistSearchShort,
    core.AppRoutes.artistBrowse,
    core.AppRoutes.artistFeatured,
    core.AppRoutes.trending,
    core.AppRoutes.local,
    core.AppRoutes.artworkBrowse,
    core.AppRoutes.artworkFeatured,
    core.AppRoutes.artworkRecent,
    core.AppRoutes.artworkTrending,
    core.AppRoutes.artworkSearch,
    core.AppRoutes.allEvents,
    core.AppRoutes.chapterLanding,
    core.AppRoutes.search,
    '/art-walk/map',
    '/art-walk/dashboard',
    '/capture/camera',
    '/community/hub',
  };

  static const List<String> _publicPrefixes = [
    '/public/',
    '/art-walk/',
    '/community/',
  ];

  bool requiresAuthentication(String routeName) {
    if (_publicRoutes.contains(routeName)) {
      return false;
    }
    for (final prefix in _publicPrefixes) {
      if (routeName.startsWith(prefix)) {
        return false;
      }
    }
    return true;
  }
}
