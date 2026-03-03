import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/src/services/connectivity_service.dart';

import 'art_walk_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  FirebaseAuth,
  FirebaseStorage,
  ConnectivityService,
  ArtWalkCacheService,
  RewardsService,
  AchievementService,
  ArtLocationClusteringService,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  QueryDocumentSnapshot,
  Query,
  User,
  ArtWalkNavigationService,
  DirectionsService,
])
void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockCollectionReference<Map<String, dynamic>> mockArtWalksCollection;
  late MockCollectionReference<Map<String, dynamic>> mockPublicArtCollection;
  late ArtWalkService artWalkService;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockArtWalksCollection = MockCollectionReference<Map<String, dynamic>>();
    mockPublicArtCollection = MockCollectionReference<Map<String, dynamic>>();

    artWalkService = ArtWalkService(firestore: mockFirestore, auth: mockAuth);

    when(
      mockFirestore.collection('artWalks'),
    ).thenReturn(mockArtWalksCollection);
    when(
      mockFirestore.collection('publicArt'),
    ).thenReturn(mockPublicArtCollection);
    when(
      mockFirestore.collection('captures'),
    ).thenReturn(MockCollectionReference<Map<String, dynamic>>());
  });

  group('ArtWalkService Tests', () {
    test('getCurrentUserId returns uid', () {
      final mockUser = MockUser();
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_uid');

      expect(artWalkService.getCurrentUserId(), 'test_uid');
    });

    test('getArtWalkById returns art walk from Firestore', () async {
      const walkId = 'test_walk';
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockArtWalksCollection.doc(walkId)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDoc);
      when(mockDoc.exists).thenReturn(true);
      when(mockDoc.id).thenReturn(walkId);
      when(mockDoc.data()).thenReturn({
        'title': 'Test Walk',
        'description': 'Description',
        'userId': 'user1',
        'artworkIds': ['art1'],
        'createdAt': Timestamp.now(),
      });

      final result = await artWalkService.getArtWalkById(walkId);

      expect(result, isNotNull);
      expect(result!.id, walkId);
      expect(result.title, 'Test Walk');
    });

    test('getArtInWalk returns list of art pieces from Firestore', () async {
      const walkId = 'test_walk';
      final mockWalkDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      final mockWalkDocRef = MockDocumentReference<Map<String, dynamic>>();

      // Mock ArtWalk fetch
      when(mockArtWalksCollection.doc(walkId)).thenReturn(mockWalkDocRef);
      when(mockWalkDocRef.get()).thenAnswer((_) async => mockWalkDoc);
      when(mockWalkDoc.exists).thenReturn(true);
      when(mockWalkDoc.id).thenReturn(walkId);
      when(mockWalkDoc.data()).thenReturn({
        'title': 'Test Walk',
        'description': 'Description',
        'userId': 'user1',
        'artworkIds': ['art1'],
        'createdAt': Timestamp.now(),
      });

      // Mock PublicArt fetch (batch fetch)
      final mockArtQuery = MockQuery<Map<String, dynamic>>();
      final mockArtSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockArtDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockPublicArtCollection.where(FieldPath.documentId, whereIn: ['art1']),
      ).thenReturn(mockArtQuery);
      when(mockArtQuery.get()).thenAnswer((_) async => mockArtSnapshot);
      when(mockArtSnapshot.docs).thenReturn([mockArtDoc]);
      when(mockArtDoc.id).thenReturn('art1');
      when(mockArtDoc.data()).thenReturn({
        'userId': 'user1',
        'title': 'Test Art',
        'description': 'Art Description',
        'imageUrl': 'http://example.com/image.jpg',
        'location': const GeoPoint(10, 20),
        'createdAt': Timestamp.now(),
      });

      final result = await artWalkService.getArtInWalk(walkId);

      expect(result, isNotEmpty);
      expect(result.first.id, 'art1');
      expect(result.first.title, 'Test Art');
    });

    test('addCommentToArtWalk adds comment and returns id', () async {
      const walkId = 'test_walk';
      const content = 'Nice walk!';
      final mockUser = MockUser();
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockCommentsCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockNewCommentRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('user1');
      when(mockUser.displayName).thenReturn('User One');
      when(mockUser.photoURL).thenReturn('http://example.com/photo.jpg');

      when(mockArtWalksCollection.doc(walkId)).thenReturn(mockDocRef);
      when(
        mockDocRef.collection('comments'),
      ).thenReturn(mockCommentsCollection);
      when(
        mockCommentsCollection.add(any),
      ).thenAnswer((_) async => mockNewCommentRef);
      when(mockNewCommentRef.id).thenReturn('new_comment_id');

      final result = await artWalkService.addCommentToArtWalk(
        artWalkId: walkId,
        content: content,
      );

      expect(result, 'new_comment_id');
      verify(
        mockCommentsCollection.add(argThat(containsPair('content', content))),
      ).called(1);
    });
  });
}
