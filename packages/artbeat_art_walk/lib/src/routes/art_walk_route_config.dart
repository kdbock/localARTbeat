import 'package:flutter/material.dart';
import '../constants/routes.dart';
import '../screens/screens.dart';
import '../models/models.dart';

/// Art walk module route configuration
class ArtWalkRouteConfig {
  static Map<String, Widget Function(BuildContext)> routes = {
    ArtWalkRoutes.map: (_) => const ArtWalkMapScreen(),
    ArtWalkRoutes.list: (_) => const ArtWalkListScreen(),
    ArtWalkRoutes.dashboard: (_) => const DiscoverDashboardScreen(),
  };

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
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

      // Note: ArtWalkRoutes.enhancedExperience is deprecated and now points to
      // the same path as ArtWalkRoutes.experience, so no separate case needed

      default:
        return null;
    }
  }
}
