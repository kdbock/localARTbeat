import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:artbeat_core/src/config/legal_config.dart';
import 'package:artbeat_core/src/services/legal_consent_service.dart';

class _FakeFirebaseAuth extends Mock implements FirebaseAuth {
  _FakeFirebaseAuth(this._currentUser);
  final User? _currentUser;

  @override
  User? get currentUser => _currentUser;
}

class _FakeUser extends Mock implements User {
  _FakeUser(this._uid);
  final String _uid;

  @override
  String get uid => _uid;
}

void main() {
  group('LegalConsentService', () {
    late FakeFirebaseFirestore firestore;
    late _FakeUser user;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      user = _FakeUser('user-1');
    });

    test(
      'records registration consent for authenticated matching user',
      () async {
        final auth = _FakeFirebaseAuth(user);
        final service = LegalConsentService(auth: auth, firestore: firestore);

        await service.recordRegistrationConsent(userId: 'user-1', locale: 'en');

        final userDoc = await firestore.collection('users').doc('user-1').get();
        expect(userDoc.exists, isTrue);

        final data = userDoc.data()!;
        final legalConsents = data['legalConsents'] as Map<String, dynamic>;
        final tos = legalConsents['termsOfService'] as Map<String, dynamic>;
        final privacy = legalConsents['privacyPolicy'] as Map<String, dynamic>;

        expect(tos['accepted'], isTrue);
        expect(tos['version'], LegalConfig.tosVersion);
        expect(tos['surface'], 'registration');
        expect(tos['locale'], 'en');

        expect(privacy['accepted'], isTrue);
        expect(privacy['version'], LegalConfig.privacyVersion);
        expect(privacy['surface'], 'registration');
        expect(privacy['locale'], 'en');

        expect(data.containsKey('updatedAt'), isTrue);
      },
    );

    test('throws when no authenticated user exists', () async {
      final auth = _FakeFirebaseAuth(null);
      final service = LegalConsentService(auth: auth, firestore: firestore);

      expect(
        () => service.recordRegistrationConsent(userId: 'user-1', locale: 'en'),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'throws when authenticated user does not match requested user',
      () async {
        final auth = _FakeFirebaseAuth(_FakeUser('other-user'));
        final service = LegalConsentService(auth: auth, firestore: firestore);

        expect(
          () =>
              service.recordRegistrationConsent(userId: 'user-1', locale: 'en'),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}
