import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'coordinate_validator.dart' show SimpleLatLng;
import 'dart:math';
import 'logger.dart';

class LocationUtils {
  static const String _zipCodeKey = 'user_zip_code';

  static Future<Position> getCurrentPosition({
    Duration? timeoutDuration,
  }) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: timeoutDuration,
    );

    return Geolocator.getCurrentPosition(locationSettings: locationSettings);
  }

  static Future<Position?> getLastKnownPositionSafe() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  static Future<String> getZipCodeFromGeoPoint(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final postalCode = placemarks.first.postalCode ?? '';
        if (postalCode.isNotEmpty) {
          return postalCode;
        }
      }
      return '';
    } catch (e) {
      AppLogger.error('Error getting zip code from coordinates: $e');
      return '';
    }
  }

  static Future<String> getZipCodeFromCurrentPosition() async {
    try {
      final position = await getCurrentPosition();
      return getZipCodeFromGeoPoint(position.latitude, position.longitude);
    } catch (e) {
      AppLogger.error('Error getting current zip code: $e');
      return '';
    }
  }

  /// Check if coordinates are valid
  static bool isValidLatitude(double? latitude) {
    return latitude != null && latitude >= -90 && latitude <= 90;
  }

  static bool isValidLongitude(double? longitude) {
    return longitude != null && longitude >= -180 && longitude <= 180;
  }

  static bool isValidLatLng(SimpleLatLng coordinates) {
    return isValidLatitude(coordinates.latitude) &&
        isValidLongitude(coordinates.longitude);
  }

  /// Log invalid coordinates for debugging
  static void logInvalidCoordinates(String source, double? lat, double? lng) {
    AppLogger.error('❌ Invalid coordinates from $source: lat=$lat, lng=$lng');
  }

  static Future<String?> getStoredZipCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_zipCodeKey);
  }

  static Future<void> storeZipCode(String zipCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_zipCodeKey, zipCode);
  }

  static Future<SimpleLatLng?> getCoordinatesFromZipCode(String zipCode) async {
    try {
      final locations = await locationFromAddress('$zipCode USA');
      if (locations.isNotEmpty) {
        return SimpleLatLng(
          locations.first.latitude,
          locations.first.longitude,
        );
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting coordinates from ZIP code: $e');
      return null;
    }
  }

  // Use alias for backward compatibility
  static Future<String> getZipCodeFromCoordinates(
    double lat,
    double lng,
  ) async {
    return getZipCodeFromGeoPoint(lat, lng);
  }

  /// Get location coordinates from address string
  static Future<SimpleLatLng?> getLocationFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return SimpleLatLng(
          locations.first.latitude,
          locations.first.longitude,
        );
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting location from address: $e');
      return null;
    }
  }

  /// Calculate distance between two points using Haversine formula
  /// Returns distance in miles
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 3959; // miles (use 6371 for kilometers)

    // Convert to radians
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;

    final a =
        sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
}
