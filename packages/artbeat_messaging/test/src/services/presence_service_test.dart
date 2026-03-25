import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_messaging/src/services/presence_service.dart';

class _TestFirebaseAuth implements FirebaseAuth {
  int authStateChangesCallCount = 0;

  @override
  Stream<User?> authStateChanges() {
    authStateChangesCallCount++;
    return const Stream<User?>.empty();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PresenceService', () {
    late _TestFirebaseAuth auth;
    late FakeFirebaseFirestore firestore;

    setUp(() {
      auth = _TestFirebaseAuth();
      firestore = FakeFirebaseFirestore();
    });

    test('does not subscribe to auth changes before initialize', () {
      PresenceService(auth: auth, firestore: firestore);

      expect(auth.authStateChangesCallCount, 0);
    });

    test('subscribes to auth changes once when initialized', () {
      final service = PresenceService(auth: auth, firestore: firestore);

      service.initialize();
      service.initialize();

      expect(auth.authStateChangesCallCount, 1);
    });
  });
}
