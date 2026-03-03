import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_core/src/utils/coordinate_validator.dart';

void main() {
  group('CoordinateValidator', () {
    test('validates latitude bounds and finite values', () {
      expect(CoordinateValidator.isValidLatitude(0), isTrue);
      expect(CoordinateValidator.isValidLatitude(90), isTrue);
      expect(CoordinateValidator.isValidLatitude(-90), isTrue);
      expect(CoordinateValidator.isValidLatitude(90.1), isFalse);
      expect(CoordinateValidator.isValidLatitude(-90.1), isFalse);
      expect(CoordinateValidator.isValidLatitude(double.nan), isFalse);
      expect(CoordinateValidator.isValidLatitude(double.infinity), isFalse);
      expect(CoordinateValidator.isValidLatitude(null), isFalse);
    });

    test('validates longitude bounds and finite values', () {
      expect(CoordinateValidator.isValidLongitude(0), isTrue);
      expect(CoordinateValidator.isValidLongitude(180), isTrue);
      expect(CoordinateValidator.isValidLongitude(-180), isTrue);
      expect(CoordinateValidator.isValidLongitude(180.1), isFalse);
      expect(CoordinateValidator.isValidLongitude(-180.1), isFalse);
      expect(CoordinateValidator.isValidLongitude(double.nan), isFalse);
      expect(CoordinateValidator.isValidLongitude(double.infinity), isFalse);
      expect(CoordinateValidator.isValidLongitude(null), isFalse);
    });

    test('validates geopoint and safely converts valid values', () {
      const validPoint = GeoPoint(37.7749, -122.4194);

      expect(CoordinateValidator.isValidGeoPoint(validPoint), isTrue);
      expect(CoordinateValidator.isValidGeoPoint(null), isFalse);

      final converted = CoordinateValidator.safeLatLngFromGeoPoint(validPoint);
      expect(converted, isNotNull);
      expect(converted!.latitude, closeTo(37.7749, 0.0001));
      expect(converted.longitude, closeTo(-122.4194, 0.0001));

      expect(
        CoordinateValidator.safeLatLngFromGeoPoint(null, itemId: 'art-1'),
        isNull,
      );
    });

    test('returns expected default location', () {
      final location = CoordinateValidator.getDefaultLocation();
      expect(location.latitude, closeTo(37.7749, 0.0001));
      expect(location.longitude, closeTo(-122.4194, 0.0001));
    });
  });
}
