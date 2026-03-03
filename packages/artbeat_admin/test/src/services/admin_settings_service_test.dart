import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:artbeat_admin/src/services/admin_settings_service.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _FakeUser extends Fake implements User {
  _FakeUser(this._uid);

  final String _uid;

  @override
  String get uid => _uid;
}

void main() {
  group('AdminSettingsService', () {
    late FakeFirebaseFirestore firestore;
    late _MockFirebaseAuth auth;
    late AdminSettingsService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = _MockFirebaseAuth();
      service = AdminSettingsService(firestore: firestore, auth: auth);
    });

    test('getSettings creates defaults when admin_settings is missing',
        () async {
      final settings = await service.getSettings();

      expect(settings.appName, 'ARTbeat');
      final doc = await firestore
          .collection('admin_settings')
          .doc('app_settings')
          .get();
      expect(doc.exists, isTrue);
    });

    test('updateSetting throws when user is not authenticated', () async {
      when(auth.currentUser).thenReturn(null);

      await expectLater(
        () => service.updateSetting('maintenanceMode', true),
        throwsA(isA<Exception>()),
      );
    });

    test('addBannedWord and removeBannedWord persist normalized values',
        () async {
      when(auth.currentUser).thenReturn(_FakeUser('admin-1'));
      await firestore.collection('admin_settings').doc('app_settings').set({
        'bannedWords': ['spam'],
      });

      await service.addBannedWord('Abuse');
      var words = await service.getBannedWords();
      expect(words, containsAll(<String>['spam', 'abuse']));

      await service.removeBannedWord('Abuse');
      words = await service.getBannedWords();
      expect(words, isNot(contains('abuse')));
    });
  });
}
