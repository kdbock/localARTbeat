import 'package:flutter/material.dart';
import 'package:artbeat_art_walk/src/constants/routes.dart';
import 'package:artbeat_art_walk/src/screens/screens.dart';
import 'package:artbeat_art_walk/src/models/models.dart';
import 'package:geolocator/geolocator.dart';

/// Art walk module route configuration
class ArtWalkRouteConfig {
  static Map<String, Widget Function(BuildContext)> routes = {
    ArtWalkRoutes.map: (_) => const ArtWalkMapScreen(),
    ArtWalkRoutes.list: (_) => const ArtWalkListScreen(),
    ArtWalkRoutes.dashboard: (_) => const DiscoverDashboardScreen(),
    ArtWalkRoutes.questHistory: (_) => const QuestHistoryScreen(),
    ArtWalkRoutes.weeklyGoals: (_) => const WeeklyGoalsScreen(),
    ArtWalkRoutes.instantDiscovery: (_) => const InstantDiscoveryRadarScreen(),
    ArtWalkRoutes.goNowNavigation: (_) => const Scaffold(
      body: Center(child: Text('Go Now route requires arguments')),
    ),
  };

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/art-walk/explore':
        return MaterialPageRoute(
          builder: (_) => const DiscoverDashboardScreen(),
        );

      case '/art-walk/start':
        return MaterialPageRoute(builder: (_) => const ArtWalkListScreen());

      case '/art-walk/nearby':
        return MaterialPageRoute(builder: (_) => const ArtWalkMapScreen());

      case ArtWalkRoutes.detail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ArtWalkDetailScreen(walkId: args['walkId'] as String),
        );

      case ArtWalkRoutes.review:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ArtWalkReviewScreen(
            artWalkId: args['artWalkId'] as String,
            artWalk: args['artWalk'] as ArtWalkModel,
          ),
        );

      case ArtWalkRoutes.experience:
        final args = settings.arguments as Map<String, dynamic>;
        // Redirect to enhanced experience for better UX
        return MaterialPageRoute(
          builder: (_) => EnhancedArtWalkExperienceScreen(
            artWalkId: args['artWalkId'] as String,
            artWalk: args['artWalk'] as ArtWalkModel,
          ),
        );

      case ArtWalkRoutes.create:
        final args = settings.arguments as Map<String, dynamic>?;
        // Redirect to enhanced create screen for better UX
        return MaterialPageRoute(
          builder: (_) => EnhancedArtWalkCreateScreen(
            artWalkId: args?['artWalkId'] as String?,
            artWalkToEdit: args?['artWalk'] as ArtWalkModel?,
          ),
        );

      case ArtWalkRoutes.edit:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ArtWalkEditScreen(
            artWalkId: args['walkId'] as String,
            artWalk: args['artWalk'] as ArtWalkModel?,
          ),
        );

      case ArtWalkRoutes.enhancedCreate:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => EnhancedArtWalkCreateScreen(
            artWalkId: args?['artWalkId'] as String?,
            artWalkToEdit: args?['artWalk'] as ArtWalkModel?,
          ),
        );

      case ArtWalkRoutes.celebration:
        final args = settings.arguments as Map<String, dynamic>?;
        final celebrationData = args?['celebrationData'] as CelebrationData?;
        if (celebrationData == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Art walk celebration data missing')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) =>
              ArtWalkCelebrationScreen(celebrationData: celebrationData),
        );

      // Note: ArtWalkRoutes.enhancedExperience is deprecated and now points to
      // the same path as ArtWalkRoutes.experience, so no separate case needed

      case ArtWalkRoutes.instantDiscovery:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => InstantDiscoveryRadarScreen(
            userPosition: args?['userPosition'] as Position?,
            initialNearbyArt: (args?['initialNearbyArt'] as List?)
                ?.cast<PublicArtModel>(),
          ),
        );
      case ArtWalkRoutes.goNowNavigation:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => GoNowNavigationScreen(
            pieceId: args['pieceId'] as String,
            title: args['title'] as String,
            latitude: args['latitude'] as double,
            longitude: args['longitude'] as double,
            source: (args['source'] as String?) ?? 'unknown',
            showAddToWalkAction:
                (args['showAddToWalkAction'] as bool?) ?? false,
          ),
        );
      default:
        return null;
    }
  }
}
