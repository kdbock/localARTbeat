import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Model representing a single navigation step in turn-by-turn directions
class NavigationStepModel {
  final String instruction; // HTML formatted instruction from Google Maps
  final String maneuver; // turn-left, turn-right, straight, etc.
  final int distanceMeters; // Distance of this step in meters
  final int durationSeconds; // Duration of this step in seconds
  final LatLng startLocation; // Start coordinate of this step
  final LatLng endLocation; // End coordinate of this step
  final List<LatLng> polylinePoints; // Detailed path for this step
  final String? travelMode; // walking, driving, etc.

  NavigationStepModel({
    required this.instruction,
    required this.maneuver,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.startLocation,
    required this.endLocation,
    required this.polylinePoints,
    this.travelMode,
  });

  /// Create NavigationStepModel from Google Maps Directions API response
  factory NavigationStepModel.fromGoogleMapsStep(Map<String, dynamic> step) {
    final startLocation = step['start_location'] as Map<String, dynamic>;
    final endLocation = step['end_location'] as Map<String, dynamic>;
    final polyline = step['polyline'] as Map<String, dynamic>;
    final distance = step['distance'] as Map<String, dynamic>;
    final duration = step['duration'] as Map<String, dynamic>;

    return NavigationStepModel(
      instruction: step['html_instructions'] as String? ?? '',
      maneuver: step['maneuver'] as String? ?? 'straight',
      distanceMeters: distance['value'] as int? ?? 0,
      durationSeconds: duration['value'] as int? ?? 0,
      startLocation: LatLng(
        (startLocation['lat'] as num?)?.toDouble() ?? 0.0,
        (startLocation['lng'] as num?)?.toDouble() ?? 0.0,
      ),
      endLocation: LatLng(
        (endLocation['lat'] as num?)?.toDouble() ?? 0.0,
        (endLocation['lng'] as num?)?.toDouble() ?? 0.0,
      ),
      polylinePoints: decodePolyline(polyline['points'] as String? ?? ''),
      travelMode: step['travel_mode'] as String?,
    );
  }

  /// Get human-readable instruction without HTML tags
  String get cleanInstruction {
    return instruction
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  /// Get formatted distance string
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters}m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Get formatted duration string
  String get formattedDuration {
    if (durationSeconds < 60) {
      return '${durationSeconds}s';
    } else {
      final minutes = (durationSeconds / 60).round();
      return '${minutes}min';
    }
  }

  /// Get icon for the maneuver type
  String get maneuverIcon {
    switch (maneuver.toLowerCase()) {
      case 'turn-left':
        return '↰';
      case 'turn-right':
        return '↱';
      case 'turn-sharp-left':
        return '⬅️';
      case 'turn-sharp-right':
        return '➡️';
      case 'turn-slight-left':
        return '↖️';
      case 'turn-slight-right':
        return '↗️';
      case 'straight':
        return '⬆️';
      case 'u-turn-left':
      case 'u-turn-right':
        return '↩️';
      default:
        return '⬆️';
    }
  }

  /// Decode Google Maps polyline string to list of LatLng points
  static List<LatLng> decodePolyline(String polyline) {
    final List<LatLng> coordinates = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < polyline.length) {
      int shift = 0;
      int result = 0;
      int byte;

      do {
        byte = polyline.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final int deltaLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += deltaLat;

      shift = 0;
      result = 0;

      do {
        byte = polyline.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final int deltaLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += deltaLng;

      coordinates.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return coordinates;
  }
}
