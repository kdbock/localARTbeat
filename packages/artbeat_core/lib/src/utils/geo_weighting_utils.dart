import 'dart:developer' as developer;

import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_core/src/utils/coordinate_validator.dart';

class GeoWeightingUtils {
  static final Map<String, SimpleLatLng?> _locationCache = {};

  static Future<SimpleLatLng?> resolveViewerLocation(UserModel? user) async {
    if (user == null) {
      return _getCurrentDeviceCoordinates();
    }

    final zip = user.zipCode?.trim();
    if (zip != null && zip.isNotEmpty) {
      return _resolveLocation(zip);
    }

    final location = user.location.trim();
    if (location.isNotEmpty) {
      return _resolveLocation(location);
    }

    return _getCurrentDeviceCoordinates();
  }

  static Future<List<ArtistProfileModel>> sortArtistProfilesByDistance(
    List<ArtistProfileModel> artists, {
    UserModel? viewer,
  }) async {
    final viewerLocation = await resolveViewerLocation(viewer);
    if (viewerLocation == null) return artists;

    return sortByDistance<ArtistProfileModel>(
      items: artists,
      idOf: (artist) => artist.userId,
      locationOf: (artist) => artist.location,
      coordsOf: (artist) {
        final lat = artist.locationLat;
        final lng = artist.locationLng;
        if (lat == null || lng == null) return null;
        return SimpleLatLng(lat, lng);
      },
      viewerLocation: viewerLocation,
      tieBreaker: (a, b) {
        final boostCompare = b.boostScore.compareTo(a.boostScore);
        if (boostCompare != 0) return boostCompare;
        final aBoost = a.lastBoostAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bBoost = b.lastBoostAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final boostTimeCompare = bBoost.compareTo(aBoost);
        if (boostTimeCompare != 0) return boostTimeCompare;
        return a.displayName.compareTo(b.displayName);
      },
    );
  }

  static Future<List<T>> sortByDistance<T>({
    required List<T> items,
    required String Function(T) idOf,
    required String? Function(T) locationOf,
    required SimpleLatLng? viewerLocation,
    required int Function(T, T) tieBreaker,
    SimpleLatLng? Function(T)? coordsOf,
  }) async {
    if (viewerLocation == null) return items;

    final task = developer.TimelineTask();
    task.start(
      'GeoWeighting.sortByDistance',
      arguments: {'count': items.length},
    );
    try {
      final distances = <String, double>{};
      final missingLocations = <String, String>{};

      developer.Timeline.timeSync(
        'GeoWeighting.sortByDistance.distanceMap',
        () {
          for (final item in items) {
            final coords = coordsOf?.call(item);
            if (coords != null && LocationUtils.isValidLatLng(coords)) {
              distances[idOf(item)] = LocationUtils.calculateDistance(
                viewerLocation.latitude,
                viewerLocation.longitude,
                coords.latitude,
                coords.longitude,
              );
            } else {
              missingLocations[idOf(item)] = locationOf(item) ?? '';
            }
          }
        },
      );

      if (missingLocations.isNotEmpty) {
        final resolveTask = developer.TimelineTask();
        resolveTask.start(
          'GeoWeighting.sortByDistance.resolveMissing',
          arguments: {'count': missingLocations.length},
        );
        final resolved = await _distanceMapForLocations(
          viewerLocation,
          missingLocations,
        );
        resolveTask.finish();
        distances.addAll(resolved);
      }

      final sorted = List<T>.from(items);
      developer.Timeline.timeSync(
        'GeoWeighting.sortByDistance.sort',
        () {
          sorted.sort((a, b) {
            final distanceA = distances[idOf(a)] ?? double.infinity;
            final distanceB = distances[idOf(b)] ?? double.infinity;
            if (distanceA != distanceB) return distanceA.compareTo(distanceB);
            return tieBreaker(a, b);
          });
        },
      );

      return sorted;
    } finally {
      task.finish();
    }
  }

  static Future<SimpleLatLng?> _getCurrentDeviceCoordinates() async {
    try {
      final position = await LocationUtils.getCurrentPosition(
        timeoutDuration: const Duration(seconds: 6),
      );
      return SimpleLatLng(position.latitude, position.longitude);
    } catch (e) {
      AppLogger.warning('GeoWeighting: failed to read device location: $e');
      return null;
    }
  }

  static Future<Map<String, double>> _distanceMapForLocations(
    SimpleLatLng viewer,
    Map<String, String> locations,
  ) async {
    final entries = await Future.wait(
      locations.entries.map((entry) async {
        final coords = await _resolveLocation(entry.value);
        if (coords == null) {
          return MapEntry(entry.key, double.infinity);
        }
        final distance = LocationUtils.calculateDistance(
          viewer.latitude,
          viewer.longitude,
          coords.latitude,
          coords.longitude,
        );
        return MapEntry(entry.key, distance);
      }),
    );

    return Map<String, double>.fromEntries(entries);
  }

  static Future<SimpleLatLng?> _resolveLocation(String? location) async {
    final raw = location?.trim();
    if (raw == null || raw.isEmpty) return null;

    final key = raw.toLowerCase();
    if (_locationCache.containsKey(key)) {
      return _locationCache[key];
    }

    SimpleLatLng? coords;
    final parsedCoords = _parseCoordinates(raw);
    if (parsedCoords != null) {
      coords = parsedCoords;
    } else {
      final zip = _extractZip(raw);
      if (zip != null) {
        coords = await LocationUtils.getCoordinatesFromZipCode(zip);
      } else {
        coords = await LocationUtils.getLocationFromAddress(raw);
      }
    }

    if (coords != null && !LocationUtils.isValidLatLng(coords)) {
      LocationUtils.logInvalidCoordinates(
        'artist_location',
        coords.latitude,
        coords.longitude,
      );
      coords = null;
    }

    _locationCache[key] = coords;
    return coords;
  }

  static String? _extractZip(String input) {
    final match = RegExp(r'(\d{5})(?:-\d{4})?').firstMatch(input);
    return match?.group(1);
  }

  static SimpleLatLng? _parseCoordinates(String input) {
    final commaMatch = RegExp(
      r'(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)',
    ).firstMatch(input);
    final match =
        commaMatch ??
        RegExp(r'(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)').firstMatch(input);
    if (match == null) return null;
    final lat = double.tryParse(match.group(1) ?? '');
    final lng = double.tryParse(match.group(2) ?? '');
    if (lat == null || lng == null) return null;
    final coords = SimpleLatLng(lat, lng);
    return CoordinateValidator.isValidLatLng(coords) ? coords : null;
  }
}
