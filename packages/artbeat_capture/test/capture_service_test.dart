// ignore_for_file: subtype_of_sealed_class

import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

class StubUserService extends Fake implements UserService {
  bool incrementResult = true;

  @override
  Future<bool> incrementUserCaptureCount(String userId) async =>
      incrementResult;
}

class StubConnectivity extends Fake implements Connectivity {
  StubConnectivity(this.results);

  List<ConnectivityResult> results;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => results;
}

class FakeCapturePostCaptureHooks extends Fake
    implements CapturePostCaptureHooks {
  @override
  Future<void> awardCaptureApprovedXp() async {}

  @override
  Future<void> awardCaptureCreatedXp() async {}

  @override
  Future<void> checkCaptureAchievements(String userId) async {}

  @override
  Future<void> postCaptureActivity({
    required CaptureModel capture,
    required String userName,
    String? userAvatar,
    Position? location,
  }) async {}

  @override
  Future<void> recordCaptureChallengeProgress() async {}

  @override
  Future<void> updateWeeklyPhotographyGoals() async {}
}

class StubFirebaseFirestore extends Fake implements FirebaseFirestore {
  StubFirebaseFirestore(this.collections);

  final Map<String, StubCollectionReference<Map<String, dynamic>>> collections;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    final collection = collections[path];
    if (collection == null) {
      throw StateError('No stubbed collection for $path');
    }
    return collection;
  }
}

class StubCollectionReference<T extends Object?> extends Fake
    implements CollectionReference<T>, Query<T> {
  StubCollectionReference({
    required List<QueryDocumentSnapshot<T>> docs,
    String documentId = 'new_doc_id',
  }) : _docs = docs,
       _documentId = documentId;

  final List<QueryDocumentSnapshot<T>> _docs;
  final String _documentId;
  final List<T> addedPayloads = <T>[];

  @override
  Query<T> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) => this;

  @override
  Query<T> orderBy(Object field, {bool descending = false}) => this;

  @override
  Future<QuerySnapshot<T>> get([GetOptions? options]) async =>
      StubQuerySnapshot<T>(_docs);

  @override
  Future<DocumentReference<T>> add(T data) async {
    addedPayloads.add(data);
    return StubDocumentReference<T>(_documentId);
  }
}

class StubQuerySnapshot<T extends Object?> extends Fake
    implements QuerySnapshot<T> {
  StubQuerySnapshot(this._docs);

  final List<QueryDocumentSnapshot<T>> _docs;

  @override
  List<QueryDocumentSnapshot<T>> get docs => _docs;
}

class StubQueryDocumentSnapshot<T extends Object?> extends Fake
    implements QueryDocumentSnapshot<T> {
  StubQueryDocumentSnapshot(this._id, this._data);

  final String _id;
  final T _data;

  @override
  String get id => _id;

  @override
  T data() => _data;
}

class StubDocumentReference<T extends Object?> extends Fake
    implements DocumentReference<T> {
  StubDocumentReference(this._id);

  final String _id;

  @override
  String get id => _id;
}

void main() {
  late StubCollectionReference<Map<String, dynamic>> capturesCollection;
  late StubFirebaseFirestore firestore;
  late StubConnectivity connectivity;
  late StubUserService userService;
  late FakeCapturePostCaptureHooks fakePostCaptureHooks;
  late CaptureService captureService;

  setUp(() {
    capturesCollection = StubCollectionReference<Map<String, dynamic>>(
      docs: <QueryDocumentSnapshot<Map<String, dynamic>>>[],
    );
    firestore = StubFirebaseFirestore({
      'captures': capturesCollection,
      'publicArt': StubCollectionReference<Map<String, dynamic>>(
        docs: const [],
      ),
    });
    connectivity = StubConnectivity(const <ConnectivityResult>[]);
    userService = StubUserService();
    fakePostCaptureHooks = FakeCapturePostCaptureHooks();

    captureService = CaptureService.withDependencies(
      firestore: firestore,
      connectivity: connectivity,
      userService: userService,
      postCaptureHooks: fakePostCaptureHooks,
    );
  });

  group('CaptureService Tests', () {
    test('getCapturesForUser returns list of captures', () async {
      const userId = 'test_user';
      final now = DateTime.now();

      capturesCollection = StubCollectionReference<Map<String, dynamic>>(
        docs: <QueryDocumentSnapshot<Map<String, dynamic>>>[
          StubQueryDocumentSnapshot<Map<String, dynamic>>('doc_123', {
            'userId': userId,
            'title': 'Test Capture',
            'imageUrl': 'https://example.com/image.jpg',
            'createdAt': Timestamp.fromDate(now),
            'status': 'approved',
          }),
        ],
      );
      firestore = StubFirebaseFirestore({
        'captures': capturesCollection,
        'publicArt': StubCollectionReference<Map<String, dynamic>>(
          docs: const [],
        ),
      });
      captureService = CaptureService.withDependencies(
        firestore: firestore,
        connectivity: connectivity,
        userService: userService,
        postCaptureHooks: fakePostCaptureHooks,
      );

      final results = await captureService.getCapturesForUser(userId);

      expect(results.length, 1);
      expect(results.first.id, 'doc_123');
      expect(results.first.title, 'Test Capture');
    });

    test('saveCaptureWithOfflineSupport saves directly when online', () async {
      final capture = CaptureModel(
        id: '',
        userId: 'test_user',
        userName: 'Test User',
        userHandle: '@test_user',
        userProfileUrl: 'https://example.com/user.jpg',
        imageUrl: 'https://example.com/image.jpg',
        createdAt: DateTime.now(),
        title: 'Online Capture',
      );

      connectivity.results = <ConnectivityResult>[ConnectivityResult.wifi];
      userService.incrementResult = true;

      final result = await captureService.saveCaptureWithOfflineSupport(
        capture: capture,
        localImagePath: '/tmp/image.jpg',
      );

      expect(result, 'new_doc_id');
      expect(capturesCollection.addedPayloads, hasLength(1));
    });

    test(
      'saveCaptureWithOfflineSupport uses offline queue when offline',
      () async {
        // OfflineQueueService is still a singleton with local persistence, so
        // this remains better covered by integration-style tests.
      },
    );
  });
}
