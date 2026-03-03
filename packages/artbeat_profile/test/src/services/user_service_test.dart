import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:artbeat_profile/src/services/user_service.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _FakeUser extends Fake implements User {
  _FakeUser(this._uid);

  final String _uid;

  @override
  String get uid => _uid;
}

void main() {
  group('UserService', () {
    late FakeFirebaseFirestore firestore;
    late _MockFirebaseAuth auth;
    late UserService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = _MockFirebaseAuth();
      service = UserService(auth: auth, firestore: firestore);
    });

    test('currentUser proxies auth currentUser', () {
      when(auth.currentUser).thenReturn(_FakeUser('u1'));
      expect(service.currentUser?.uid, 'u1');
    });

    test(
      'getCaptureUserSettings returns defaults when field is missing',
      () async {
        await firestore.collection('users').doc('u1').set({
          'displayName': 'User',
        });

        final settings = await service.getCaptureUserSettings('u1');

        expect(settings, isNotNull);
        expect(settings!['autoSave'], isTrue);
        expect(settings['quality'], 'high');
        expect(settings['enableOCR'], isTrue);
      },
    );

    test('updateUserProfile merges updates and sets updatedAt', () async {
      await firestore.collection('users').doc('u2').set({
        'fullName': 'Old Name',
      });

      await service.updateUserProfile('u2', {'fullName': 'New Name'});

      final doc = await firestore.collection('users').doc('u2').get();
      expect(doc.data()!['fullName'], 'New Name');
      expect(doc.data()!.containsKey('updatedAt'), isTrue);
    });

    test('updateCaptureUserSettings writes captureSettings map', () async {
      await firestore.collection('users').doc('u3').set({});

      await service.updateCaptureUserSettings('u3', {
        'autoSave': false,
        'quality': 'medium',
      });

      final doc = await firestore.collection('users').doc('u3').get();
      final capture = doc.data()!['captureSettings'] as Map<String, dynamic>;
      expect(capture['autoSave'], isFalse);
      expect(capture['quality'], 'medium');
    });
  });
}
