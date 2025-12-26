import 'package:artbeat_auth/artbeat_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_profile/artbeat_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:artbeat_core/src/routing/app_routes.dart';
import '../route_utils.dart';

/// Handles core application routes (auth, dashboard, profile)
class CoreRouteHandler implements RouteHandler {
  @override
  bool canHandle(String routeName) => _coreRoutes.contains(routeName);

  static final List<String> _coreRoutes = [
    AppRoutes.splash,
    AppRoutes.dashboard,
    AppRoutes.auth,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
    AppRoutes.profile,
    AppRoutes.profileEdit,
    AppRoutes.profileCreate,
    AppRoutes.profileDeep,
    AppRoutes.profilePictureViewer,
    AppRoutes.favorites,
    AppRoutes.favoriteDeep,
  ];

  @override
  Route<dynamic>? handleRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return RouteUtils.createSimpleRoute(child: const core.SplashScreen());

      case AppRoutes.dashboard:
        return RouteUtils.createSafeRoute(AppRoutes.dashboard, () {
          core.AppLogger.info('🏠 Building dashboard screen...');
          return const core.ArtbeatDashboardScreen();
        });

      case AppRoutes.auth:
      case AppRoutes.login:
        return RouteUtils.createMainLayoutRoute(child: const LoginScreen());

      case AppRoutes.register:
        return RouteUtils.createMainLayoutRoute(child: const RegisterScreen());

      case AppRoutes.forgotPassword:
        return RouteUtils.createMainLayoutRoute(
          child: const ForgotPasswordScreen(),
        );

      case AppRoutes.profile:
        return _createProfileRoute();

      case AppRoutes.profileEdit:
        return _createProfileEditRoute();

      case AppRoutes.profileCreate:
        return _createProfileCreateRoute();

      case AppRoutes.profileDeep:
        return _createProfileDeepRoute(settings);

      case AppRoutes.profilePictureViewer:
        return _createProfilePictureViewerRoute(settings);

      case AppRoutes.favorites:
        return _createFavoritesRoute();

      case AppRoutes.favoriteDeep:
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
