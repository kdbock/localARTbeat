import 'package:artbeat_sponsorships/src/services/sponsor_service.dart';
import 'package:artbeat_sponsorships/src/utils/sponsorship_placements.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('SponsorService.getSponsorForPlacement', () {
    test('returns null for invalid placement key', () async {
      final firestore = FakeFirebaseFirestore();
      final service = SponsorService(firestore: firestore);

      final result = await service.getSponsorForPlacement(
        placementKey: 'invalid_placement',
        userLocation: const LatLng(35.7796, -78.6382),
      );

      expect(result, isNull);
    });

    test('enforces radius filtering for capture sponsors', () async {
      final firestore = FakeFirebaseFirestore();
      final service = SponsorService(firestore: firestore);
      final now = DateTime.now().toUtc();

      await firestore.collection('sponsorships').doc('sponsor_1').set({
        'businessId': 'biz_1',
        'businessName': 'Neighborhood Gallery',
        'tier': 'capture',
        'status': 'active',
        'startDate': now.subtract(const Duration(days: 1)),
        'endDate': now.add(const Duration(days: 30)),
        'placementKeys': [SponsorshipPlacements.captureDetailBanner],
        'logoUrl': 'https://example.com/logo.png',
        'linkUrl': 'https://example.com',
        'createdAt': now,
        'radiusMiles': 1.0,
        'latitude': 35.7796,
        'longitude': -78.6382,
      });

      final inRange = await service.getSponsorForPlacement(
        placementKey: SponsorshipPlacements.captureDetailBanner,
        userLocation: const LatLng(35.7800, -78.6380),
      );
      expect(inRange, isNotNull);
      expect(inRange!.id, 'sponsor_1');

      final outOfRange = await service.getSponsorForPlacement(
        placementKey: SponsorshipPlacements.captureDetailBanner,
        userLocation: const LatLng(36.0726, -79.7920),
      );
      expect(outOfRange, isNull);
    });
  });
}
