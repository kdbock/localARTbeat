import 'package:artbeat_auth/artbeat_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_profile/artbeat_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../route_utils.dart';

/// Handles core application routes (auth, dashboard, profile)
class CoreRouteHandler implements RouteHandler {
  @override
  bool canHandle(String routeName) => _coreRoutes.contains(routeName);

  static final List<String> _coreRoutes = [
    core.AppRoutes.splash,
    core.AppRoutes.dashboard,
    core.AppRoutes.auth,
    core.AppRoutes.login,
    core.AppRoutes.register,
    core.AppRoutes.forgotPassword,
    core.AppRoutes.profile,
    core.AppRoutes.profileEdit,
    core.AppRoutes.profileCreate,
    core.AppRoutes.profileDeep,
    core.AppRoutes.profilePictureViewer,
    core.AppRoutes.favorites,
    core.AppRoutes.favoriteDeep,
  ];

  @override
  Route<dynamic>? handleRoute(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.splash:
        return RouteUtils.createSimpleRoute(child: const core.SplashScreen());

      case core.AppRoutes.dashboard:
        return RouteUtils.createSafeRoute(core.AppRoutes.dashboard, () {
          core.AppLogger.info('🏠 Building dashboard screen...');
          return const core.ArtbeatDashboardScreen();
        });

      case core.AppRoutes.auth:
      case core.AppRoutes.login:
        return RouteUtils.createMainLayoutRoute(child: const LoginScreen());

      case core.AppRoutes.register:
        return RouteUtils.createMainLayoutRoute(child: const RegisterScreen());

      case core.AppRoutes.forgotPassword:
        return RouteUtils.createMainLayoutRoute(
          child: const ForgotPasswordScreen(),
        );

      case core.AppRoutes.profile:
        return _createProfileRoute();

      case core.AppRoutes.profileEdit:
        return _createProfileEditRoute();

      case core.AppRoutes.profileCreate:
        return _createProfileCreateRoute();

      case core.AppRoutes.profileDeep:
        return _createProfileDeepRoute(settings);

      case core.AppRoutes.profilePictureViewer:
        return _createProfilePictureViewerRoute(settings);

      case core.AppRoutes.favorites:
        return _createFavoritesRoute();

      case core.AppRoutes.favoriteDeep:
        return _createFavoriteDeepRoute(settings);

      default:
        return null;
    }
  }

  MaterialPageRoute<dynamic> _createProfileRoute() =>
      RouteUtils.createAuthRequiredRoute(
        authenticatedBuilder: () {
          final currentUserId = FirebaseAuth.instance.currentUser!.uid;
          return core.MainLayout(
            currentIndex: -1,
            drawer: const core.ArtbeatDrawer(),
            child: ProfileViewScreen(
              userId: currentUserId,
              isCurrentUser: true,
            ),
          );
        },
        unauthenticatedBuilder: () => const core.MainLayout(
          currentIndex: -1,
          child: Scaffold(
            body: Center(child: Text('Please log in to view your profile')),
          ),
        ),
      );

  MaterialPageRoute<dynamic> _createProfileEditRoute() =>
      RouteUtils.createAuthRequiredRoute(
        authenticatedBuilder: () {
          final currentUserId = FirebaseAuth.instance.currentUser!.uid;
          return EditProfileScreen(userId: currentUserId);
        },
        unauthenticatedBuilder: () => const core.MainLayout(
          currentIndex: -1,
          child: Scaffold(
            body: Center(child: Text('Please log in to edit your profile')),
          ),
        ),
      );

  MaterialPageRoute<dynamic> _createProfileCreateRoute() =>
      RouteUtils.createAuthRequiredRoute(
        authenticatedBuilder: () {
          final currentUserId = FirebaseAuth.instance.currentUser!.uid;
          return core.MainLayout(
            currentIndex: -1,
            child: CreateProfileScreen(userId: currentUserId),
          );
        },
        unauthenticatedBuilder: () =>
            const core.MainLayout(currentIndex: -1, child: LoginScreen()),
      );

  MaterialPageRoute<dynamic> _createProfileDeepRoute(RouteSettings settings) {
    final userId = RouteUtils.getArgument<String>(settings, 'userId');
    if (userId == null) {
      return RouteUtils.createErrorRoute('No user ID provided');
    }
    return RouteUtils.createMainLayoutRoute(
      child: ProfileViewScreen(userId: userId),
    );
  }

  MaterialPageRoute<dynamic> _createProfilePictureViewerRoute(
    RouteSettings settings,
  ) {
    final imageUrl = RouteUtils.getArgument<String>(settings, 'imageUrl');
    if (imageUrl == null) {
      return RouteUtils.createErrorRoute('No image URL provided');
    }
    final userId =
        RouteUtils.getArgument<String>(settings, 'userId') ??
        FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return RouteUtils.createErrorRoute('No user ID provided');
    }
    return RouteUtils.createMainLayoutRoute(
      child: ProfilePictureViewerScreen(imageUrl: imageUrl, userId: userId),
    );
  }

  MaterialPageRoute<dynamic> _createFavoritesRoute() =>
      RouteUtils.createMainLayoutRoute(
        appBar: RouteUtils.createAppBar('Following'),
        child: const Center(child: Text('Following coming soon')),
      );

  MaterialPageRoute<dynamic> _createFavoriteDeepRoute(RouteSettings settings) {
    final favoriteId = RouteUtils.getArgument<String>(settings, 'favoriteId');
    final userId = RouteUtils.getArgument<String>(settings, 'userId');

    if (favoriteId == null || userId == null) {
      return RouteUtils.createErrorRoute('No favorite ID or user ID provided');
    }

    return RouteUtils.createMainLayoutRoute(
      child: FavoriteDetailScreen(favoriteId: favoriteId, userId: userId),
    );
  }
}
