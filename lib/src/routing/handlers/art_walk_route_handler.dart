import 'package:artbeat_admin/artbeat_admin.dart' as admin;
import 'package:artbeat_art_walk/artbeat_art_walk.dart' as art_walk;
import 'package:artbeat_capture/artbeat_capture.dart' as capture;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../route_utils.dart';

typedef AdminRouteHandler = Route<dynamic>? Function(RouteSettings settings);

class ArtWalkRouteHandler {
  const ArtWalkRouteHandler();

  Route<dynamic>? handleRoute(
    RouteSettings settings, {
    required AdminRouteHandler handleAdminRoute,
  }) {
    switch (settings.name) {
      case core.AppRoutes.artWalkDashboard:
        return RouteUtils.createSimpleRoute(
          child: const art_walk.DiscoverDashboardScreen(),
        );

      case core.AppRoutes.artWalkMap:
        return RouteUtils.createSimpleRoute(
          child: const art_walk.ArtWalkMapScreen(),
        );

      case core.AppRoutes.artWalkList:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const art_walk.ArtWalkListScreen(),
        );

      case core.AppRoutes.artWalkDetail:
        final walkId = RouteUtils.getArgument<String>(settings, 'walkId');
        if (walkId == null) {
          return RouteUtils.createErrorRoute('Art walk not found');
        }
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: art_walk.ArtWalkDetailScreen(walkId: walkId),
        );

      case core.AppRoutes.artWalkCreate:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const art_walk.EnhancedArtWalkCreateScreen(),
        );

      case core.AppRoutes.artWalkSearch:
        final args = settings.arguments as Map<String, dynamic>?;
        final query = args?['query'] as String?;
        final searchType = args?['searchType'] as String?;
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: art_walk.SearchResultsScreen(
            initialQuery: query,
            searchType: searchType,
          ),
        );

      case core.AppRoutes.artWalkExplore:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const art_walk.DiscoverDashboardScreen(),
        );

      case core.AppRoutes.artWalkStart:
        return _buildExperienceRoute(
          settings,
          missingDataMessage: 'Art walk data is required',
        );

      case core.AppRoutes.artWalkNearby:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const art_walk.ArtWalkMapScreen(),
        );

      case core.AppRoutes.artWalkMyWalks:
      case core.AppRoutes.artWalkCompleted:
      case core.AppRoutes.artWalkSaved:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const art_walk.EnhancedMyArtWalksScreen(),
        );

      case core.AppRoutes.artWalkMyCaptures:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: Builder(
            builder: (context) {
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId == null) {
                return const Center(
                  child: Text('Please log in to view your captures'),
                );
              }
              return FutureBuilder<List<capture.CaptureModel>>(
                future: capture.CaptureService().getCapturesForUser(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading captures'));
                  }
                  final captures = snapshot.data ?? [];
                  return capture.MyCapturesScreen(captures: captures);
                },
              );
            },
          ),
        );

      case core.AppRoutes.artWalkPopular:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const art_walk.ArtWalkListScreen(),
        );

      case core.AppRoutes.artWalkAchievements:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const art_walk.QuestHistoryScreen(),
        );

      case core.AppRoutes.artWalkSettings:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const art_walk.WeeklyGoalsScreen(),
        );

      case core.AppRoutes.artWalkAdminModeration:
        return handleAdminRoute(
          RouteSettings(
            name: admin.AdminRoutes.artWalkModeration,
            arguments: settings.arguments,
          ),
        );

      case '/art-walk/review':
        final args = settings.arguments as Map<String, dynamic>?;
        final artWalkId = args?['artWalkId'] as String?;
        final artWalk = args?['artWalk'] as art_walk.ArtWalkModel?;
        if (artWalkId == null) {
          return RouteUtils.createErrorRoute('Art walk ID is required');
        }
        if (artWalk == null) {
          return RouteUtils.createErrorRoute('Art walk data is required');
        }
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: art_walk.ArtWalkReviewScreen(
            artWalkId: artWalkId,
            artWalk: artWalk,
          ),
        );

      case '/art-walk/experience':
        return _buildExperienceRoute(
          settings,
          missingIdMessage: 'Art walk ID is required',
          missingDataMessage: 'Art walk data is required',
        );

      case '/instant-discovery':
        final args =
            settings.arguments as Map<String, dynamic>? ??
            const <String, dynamic>{};
        final Position? userPosition = args['userPosition'] as Position?;
        final nearbyArt = (args['initialNearbyArt'] as List<dynamic>?)
            ?.cast<art_walk.PublicArtModel>();

        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: art_walk.InstantDiscoveryRadarScreen(
            userPosition: userPosition,
            initialNearbyArt: nearbyArt,
          ),
        );

      case '/quest-history':
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const art_walk.QuestHistoryScreen(),
        );

      case '/weekly-goals':
        return RouteUtils.createSimpleRoute(
          child: const art_walk.WeeklyGoalsScreen(),
        );

      case '/art-walk/location':
        final args = settings.arguments as Map<String, dynamic>?;
        final locationName = args?['locationName'] as String?;
        final captures = args?['captures'] as List<capture.CaptureModel>?;
        if (locationName == null || captures == null) {
          return RouteUtils.createErrorRoute(
            'Location name and captures are required',
          );
        }
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: _LocationCapturesView(
            locationName: locationName,
            captures: captures,
          ),
        );

      default:
        final generatedRoute = art_walk.ArtWalkRouteConfig.generateRoute(
          settings,
        );
        if (generatedRoute != null) {
          return generatedRoute;
        }
        return RouteUtils.createNotFoundRoute('Art Walk feature');
    }
  }

  Route<dynamic> _buildExperienceRoute(
    RouteSettings settings, {
    String missingIdMessage = 'Art walk data is required',
    required String missingDataMessage,
  }) {
    final args = settings.arguments as Map<String, dynamic>?;
    final artWalkId = args?['artWalkId'] as String?;
    final artWalk = args?['artWalk'] as art_walk.ArtWalkModel?;

    if (artWalkId == null) {
      return RouteUtils.createErrorRoute(missingIdMessage);
    }
    if (artWalk == null) {
      return RouteUtils.createErrorRoute(missingDataMessage);
    }

    return RouteUtils.createMainLayoutRoute(
      currentIndex: 1,
      child: art_walk.EnhancedArtWalkExperienceScreen(
        artWalkId: artWalkId,
        artWalk: artWalk,
      ),
    );
  }
}

class _LocationCapturesView extends StatelessWidget {
  const _LocationCapturesView({
    required this.locationName,
    required this.captures,
  });

  final String locationName;
  final List<capture.CaptureModel> captures;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(locationName),
      elevation: 0,
      backgroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.black),
      titleTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    body: captures.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, size: 64),
                SizedBox(height: 16),
              ],
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: captures.length,
            itemBuilder:
                (context, index) => _buildCaptureCard(context, captures[index]),
          ),
  );

  Widget _buildCaptureCard(
    BuildContext context,
    capture.CaptureModel captureModel,
  ) => GestureDetector(
    onTap: () {
      Navigator.pushNamed(
        context,
        '/capture/detail',
        arguments: {'captureId': captureModel.id},
      );
    },
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (captureModel.imageUrl.isNotEmpty)
            Image.network(
              captureModel.imageUrl,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            )
          else
            Container(
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: Text(
                captureModel.title ?? 'Untitled',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
