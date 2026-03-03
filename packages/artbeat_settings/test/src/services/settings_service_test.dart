import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:artbeat_settings/src/services/settings_service.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _FakeUser extends Fake implements User {
  _FakeUser(this._uid);

  final String _uid;

  @override
  String get uid => _uid;
}

void main() {
  group('SettingsService', () {
    late FakeFirebaseFirestore firestore;
    late _MockFirebaseAuth auth;
    late SettingsService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = _MockFirebaseAuth();
      service = SettingsService(firestore: firestore, auth: auth);
    });

    test('getUserSettings creates default document when missing', () async {
      when(auth.currentUser).thenReturn(_FakeUser('user-1'));

      final settings = await service.getUserSettings();
      final doc = await firestore.collection('userSettings').doc('user-1').get();

      expect(settings['darkMode'], isFalse);
      expect(settings['notificationsEnabled'], isTrue);
      expect(doc.exists, isTrue);
    });

    test('updateSetting merges value into existing settings', () async {
      when(auth.currentUser).thenReturn(_FakeUser('user-1'));
      await firestore.collection('userSettings').doc('user-1').set({
        'darkMode': false,
      });

      await service.updateSetting('darkMode', true);

      final doc = await firestore.collection('userSettings').doc('user-1').get();
      expect(doc.data()!['darkMode'], isTrue);
    });

    test('blockUser and unblockUser update blocked user list', () async {
      when(auth.currentUser).thenReturn(_FakeUser('user-1'));

      await service.blockUser('blocked-a');
      var blockedUsers = await service.getBlockedUsers();
      expect(blockedUsers, contains('blocked-a'));

      await service.unblockUser('blocked-a');
      blockedUsers = await service.getBlockedUsers();
      expect(blockedUsers, isNot(contains('blocked-a')));
    });

    test('getNotificationSettings returns default model if doc is missing', () async {
      when(auth.currentUser).thenReturn(_FakeUser('user-1'));

      final notificationSettings = await service.getNotificationSettings();

      expect(notificationSettings.userId, 'user-1');
      expect(notificationSettings.email.enabled, isTrue);
      expect(notificationSettings.push.enabled, isTrue);
    });

    test('requestDataDownload creates pending request and rejects duplicate', () async {
      when(auth.currentUser).thenReturn(_FakeUser('user-1'));

      await service.requestDataDownload();

      final firstBatch = await firestore
          .collection('dataRequests')
          .where('userId', isEqualTo: 'user-1')
          .where('requestType', isEqualTo: 'download')
          .get();
      expect(firstBatch.docs.length, 1);

      await expectLater(
        service.requestDataDownload(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
