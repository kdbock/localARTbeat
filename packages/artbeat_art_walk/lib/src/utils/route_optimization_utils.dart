import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_art_walk/src/models/public_art_model.dart';

/// Utility class for optimizing art walk routes using various algorithms
class RouteOptimizationUtils {
  /// Optimize route using nearest neighbor algorithm starting from a given location
  /// This is a simple but effective approach for small to medium sized routes
  static List<PublicArtModel> optimizeRouteFromLocation(
    List<PublicArtModel> artPieces,
    LatLng startLocation,
  ) {
    if (artPieces.isEmpty) return artPieces;
    if (artPieces.length == 1) return artPieces;

    // Simple nearest neighbor approach starting from current location
    final List<PublicArtModel> optimized = [];
    final List<PublicArtModel> remaining = List.from(artPieces);

    // Find the nearest art piece to start location
    PublicArtModel nearest = remaining.first;
    double minDistance = double.infinity;

    for (final art in remaining) {
      final distance = Geolocator.distanceBetween(
        startLocation.latitude,
        startLocation.longitude,
        art.location.latitude,
        art.location.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = art;
      }
    }

    optimized.add(nearest);
    remaining.remove(nearest);

    // Continue with nearest neighbor from each subsequent point
    while (remaining.isNotEmpty) {
      final current = optimized.last;
      nearest = remaining.first;
      minDistance = double.infinity;

      for (final art in remaining) {
        final distance = Geolocator.distanceBetween(
          current.location.latitude,
          current.location.longitude,
          art.location.latitude,
          art.location.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearest = art;
        }
      }

      optimized.add(nearest);
      remaining.remove(nearest);
    }

    return optimized;
  }

  /// Calculate total distance for a route including start and end points
  static double calculateTotalDistance(List<LatLng> routePoints) {
    if (routePoints.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < routePoints.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        routePoints[i].latitude,
        routePoints[i].longitude,
        routePoints[i + 1].latitude,
        routePoints[i + 1].longitude,
      );
    }

    return totalDistance;
  }

  /// Create route points from optimized art pieces including start location
  static List<LatLng> createRoutePoints(
    List<PublicArtModel> optimizedArtPieces,
    LatLng startLocation, {
    bool returnToStart = false,
  }) {
    final routePoints = <LatLng>[
      startLocation, // Start at current location
      ...optimizedArtPieces.map(
        (art) => LatLng(art.location.latitude, art.location.longitude),
      ),
    ];

    if (returnToStart) {
      routePoints.add(startLocation); // Return to start
    }

    return routePoints;
  }

  /// Advanced optimization using 2-opt algorithm for better results
  /// This is more computationally expensive but provides better optimization
  static List<PublicArtModel> optimize2Opt(
    List<PublicArtModel> artPieces,
    LatLng startLocation,
  ) {
    if (artPieces.length <= 3) {
      // For small routes, use simple nearest neighbor
      return optimizeRouteFromLocation(artPieces, startLocation);
    }

    // Start with nearest neighbor solution
    final List<PublicArtModel> route = optimizeRouteFromLocation(
      artPieces,
      startLocation,
    );
    bool improved = true;

    while (improved) {
      improved = false;

      for (int i = 1; i < route.length - 2; i++) {
        for (int j = i + 1; j < route.length; j++) {
          if (j - i == 1) continue; // Skip adjacent edges

          // Calculate current distance
          final double currentDistance =
              _getSegmentDistance(route, i - 1, i, startLocation) +
              _getSegmentDistance(
                route,
                j,
                j + 1 < route.length ? j + 1 : 0,
                startLocation,
              );

          // Calculate distance after 2-opt swap
          final double newDistance =
              _getSegmentDistance(route, i - 1, j, startLocation) +
              _getSegmentDistance(
                route,
                i,
                j + 1 < route.length ? j + 1 : 0,
                startLocation,
              );

          if (newDistance < currentDistance) {
            // Perform 2-opt swap
            _reverse2OptSegment(route, i, j);
            improved = true;
          }
        }
      }
    }

    return route;
  }

  /// Helper method to get distance between two points in the route
  static double _getSegmentDistance(
    List<PublicArtModel> route,
    int fromIndex,
    int toIndex,
    LatLng startLocation,
  ) {
    LatLng fromPoint;
    LatLng toPoint;

    if (fromIndex == -1) {
      fromPoint = startLocation;
    } else {
      fromPoint = LatLng(
        route[fromIndex].location.latitude,
        route[fromIndex].location.longitude,
      );
    }

    if (toIndex >= route.length) {
      toPoint = startLocation;
    } else {
      toPoint = LatLng(
        route[toIndex].location.latitude,
        route[toIndex].location.longitude,
      );
    }

    return Geolocator.distanceBetween(
      fromPoint.latitude,
      fromPoint.longitude,
      toPoint.latitude,
      toPoint.longitude,
    );
  }

  /// Helper method to reverse a segment of the route for 2-opt
  static void _reverse2OptSegment(
    List<PublicArtModel> route,
    int start,
    int end,
  ) {
    while (start < end) {
      final temp = route[start];
      route[start] = route[end];
      route[end] = temp;
      start++;
      end--;
    }
  }
}
