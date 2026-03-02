import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'art_walk_service_test.mocks.dart';

void main() {
  late MockDirectionsService mockDirectionsService;
  late ArtWalkNavigationService navigationService;

  setUp(() {
    mockDirectionsService = MockDirectionsService();
    navigationService = ArtWalkNavigationService(
      directionsService: mockDirectionsService,
    );
  });

  group('ArtWalkNavigationService Tests', () {
    test('generateRoute returns a route model', () async {
      final artPieces = <PublicArtModel>[
        PublicArtModel(
          id: 'art1',
          userId: 'user1',
          title: 'Art 1',
          description: 'Description 1',
          imageUrl: '',
          location: const GeoPoint(35.0, -82.0),
          createdAt: DateTime.now(),
        ),
      ];

      final startPosition = Position(
        latitude: 34.9,
        longitude: -81.9,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      when(
        mockDirectionsService.getDirections(
          any,
          any,
          waypoints: anyNamed('waypoints'),
        ),
      ).thenAnswer(
        (_) async => {
          'routes': [
            {
              'legs': [
                {
                  'steps': [
                    {
                      'html_instructions': 'Head north',
                      'distance': {'value': 100},
                      'duration': {'value': 60},
                      'start_location': {'lat': 34.9, 'lng': -81.9},
                      'end_location': {'lat': 35.0, 'lng': -82.0},
                      'polyline': {'points': 'abc'},
                    },
                  ],
                  'distance': {'value': 100},
                  'duration': {'value': 60},
                },
              ],
              'overview_polyline': {'points': 'abc'},
            },
          ],
        },
      );

      final route = await navigationService.generateRoute(
        'walk1',
        artPieces,
        startPosition,
      );

      expect(route.artWalkId, 'walk1');
      expect(route.segments.length, 1);
      verify(
        mockDirectionsService.getDirections(
          any,
          any,
          waypoints: anyNamed('waypoints'),
        ),
      ).called(1);
    });
  });
}
