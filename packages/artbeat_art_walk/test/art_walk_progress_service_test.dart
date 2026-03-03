import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

import 'art_walk_service_test.mocks.dart';

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockRewardsService mockRewards;
  late MockCollectionReference<Map<String, dynamic>> mockCollection;
  late MockDocumentReference<Map<String, dynamic>> mockDocRef;
  late ArtWalkProgressService progressService;

  Position createPosition(double lat, double lon) {
    return Position(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 1.0,
      heading: 1.0,
      speed: 1.0,
      speedAccuracy: 1.0,
      altitudeAccuracy: 1.0,
      headingAccuracy: 1.0,
    );
  }

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockRewards = MockRewardsService();
    mockCollection = MockCollectionReference<Map<String, dynamic>>();
    mockDocRef = MockDocumentReference<Map<String, dynamic>>();

    progressService = ArtWalkProgressService();
    progressService.setDependencies(
      firestore: mockFirestore,
      auth: mockAuth,
      rewards: mockRewards,
    );

    when(
      mockFirestore.collection('artWalkProgress'),
    ).thenReturn(mockCollection);
    when(mockCollection.doc(any)).thenReturn(mockDocRef);
  });

  group('ArtWalkProgressService Tests', () {
    test('startWalk creates new progress if none exists', () async {
      const uid = 'test_user';
      const artWalkId = 'test_walk';

      when(mockDocRef.get()).thenAnswer((_) async {
        final doc = MockDocumentSnapshot<Map<String, dynamic>>();
        when(doc.exists).thenReturn(false);
        return doc;
      });

      when(mockDocRef.set(any)).thenAnswer((_) async => {});

      final progress = await progressService.startWalk(
        artWalkId: artWalkId,
        totalArtCount: 5,
        userId: uid,
      );

      expect(progress.userId, uid);
      expect(progress.artWalkId, artWalkId);
      expect(progress.totalArtCount, 5);
      verify(mockDocRef.set(any)).called(1);
    });

    test('recordArtVisit updates progress and awards XP', () async {
      const uid = 'test_user';
      const artWalkId = 'test_walk';
      const artId = 'art1';
      final userPos = createPosition(10.0001, 20.0001);
      final artPos = createPosition(10.0, 20.0);

      // Start a walk first
      when(mockDocRef.get()).thenAnswer((_) async {
        final doc = MockDocumentSnapshot<Map<String, dynamic>>();
        when(doc.exists).thenReturn(false);
        return doc;
      });
      when(mockDocRef.set(any)).thenAnswer((_) async => {});

      await progressService.startWalk(
        artWalkId: artWalkId,
        totalArtCount: 5,
        userId: uid,
      );

      // Now record a visit
      when(
        mockRewards.awardXP(any, customAmount: anyNamed('customAmount')),
      ).thenAnswer((_) async => {});

      final progress = await progressService.recordArtVisit(
        artId: artId,
        userLocation: userPos,
        artLocation: artPos,
      );

      expect(progress.visitedArt.length, 1);
      expect(progress.visitedArt.first.artId, artId);
      expect(progress.visitedArt.first.wasNearArt, isTrue);
      verify(
        mockRewards.awardXP(any, customAmount: anyNamed('customAmount')),
      ).called(1);
      verify(mockDocRef.set(any)).called(2);
    });

    test('completeWalk marks progress as completed and awards bonus', () async {
      const uid = 'test_user';
      const artWalkId = 'test_walk';

      // Start a walk first
      when(mockDocRef.get()).thenAnswer((_) async {
        final doc = MockDocumentSnapshot<Map<String, dynamic>>();
        when(doc.exists).thenReturn(false);
        return doc;
      });
      when(mockDocRef.set(any)).thenAnswer((_) async => {});

      await progressService.startWalk(
        artWalkId: artWalkId,
        totalArtCount: 5,
        userId: uid,
      );

      // Complete the walk
      when(
        mockRewards.awardXP(any, customAmount: anyNamed('customAmount')),
      ).thenAnswer((_) async => {});

      final progress = await progressService.completeWalk();

      expect(progress.status, WalkStatus.completed);
      expect(progress.completedAt, isNotNull);
      verify(
        mockRewards.awardXP(
          'art_walk_completion',
          customAmount: anyNamed('customAmount'),
        ),
      ).called(1);
      verify(mockDocRef.set(any)).called(2);
    });

    test('recordArtVisit does not duplicate previously visited art', () async {
      const uid = 'test_user';
      const artWalkId = 'test_walk';
      const artId = 'art1';
      final userPos = createPosition(10.0001, 20.0001);
      final artPos = createPosition(10.0, 20.0);

      when(mockDocRef.get()).thenAnswer((_) async {
        final doc = MockDocumentSnapshot<Map<String, dynamic>>();
        when(doc.exists).thenReturn(false);
        return doc;
      });
      when(mockDocRef.set(any)).thenAnswer((_) async => {});
      when(
        mockRewards.awardXP(any, customAmount: anyNamed('customAmount')),
      ).thenAnswer((_) async => {});

      await progressService.startWalk(
        artWalkId: artWalkId,
        totalArtCount: 5,
        userId: uid,
      );

      final firstVisit = await progressService.recordArtVisit(
        artId: artId,
        userLocation: userPos,
        artLocation: artPos,
      );
      final secondVisit = await progressService.recordArtVisit(
        artId: artId,
        userLocation: userPos,
        artLocation: artPos,
      );

      expect(firstVisit.visitedArt.length, 1);
      expect(secondVisit.visitedArt.length, 1);
      verify(
        mockRewards.awardXP(any, customAmount: anyNamed('customAmount')),
      ).called(1);
    });

    test(
      'pauseWalk and abandonWalk update status and clear progress',
      () async {
        const uid = 'test_user';
        const artWalkId = 'test_walk';

        when(mockDocRef.get()).thenAnswer((_) async {
          final doc = MockDocumentSnapshot<Map<String, dynamic>>();
          when(doc.exists).thenReturn(false);
          return doc;
        });
        when(mockDocRef.set(any)).thenAnswer((_) async => {});

        await progressService.startWalk(
          artWalkId: artWalkId,
          totalArtCount: 5,
          userId: uid,
        );

        final paused = await progressService.pauseWalk();
        expect(paused.status, WalkStatus.paused);
        expect(progressService.currentProgress?.status, WalkStatus.paused);

        await progressService.abandonWalk();
        expect(progressService.currentProgress, isNull);
      },
    );
  });
}
