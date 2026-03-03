import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:artbeat_auth/src/services/auth_service.dart';

class _FakeFirebaseAuth extends Mock implements FirebaseAuth {
  User? currentUserValue;

  Future<UserCredential> Function({
    required String email,
    required String password,
  })?
  signInHandler;

  Future<UserCredential> Function({
    required String email,
    required String password,
  })?
  createUserHandler;

  Future<void> Function({required String email})? resetPasswordHandler;

  @override
  User? get currentUser => currentUserValue;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    final handler = signInHandler;
    if (handler == null) {
      throw StateError('signInWithEmailAndPassword handler not configured');
    }
    return handler(email: email, password: password);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    final handler = createUserHandler;
    if (handler == null) {
      throw StateError('createUserWithEmailAndPassword handler not configured');
    }
    return handler(email: email, password: password);
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) {
    final handler = resetPasswordHandler;
    if (handler == null) {
      throw StateError('sendPasswordResetEmail handler not configured');
    }
    return handler(email: email);
  }

  @override
  Future<void> signOut() async {}

  @override
  Stream<User?> authStateChanges() => const Stream.empty();
}

class _FakeUser extends Mock implements User {
  _FakeUser({required this.uidValue, this.emailValue, this.verified = false});

  final String uidValue;
  final String? emailValue;
  bool verified;
  int sentVerificationCount = 0;
  int reloadCount = 0;
  String? updatedDisplayName;

  @override
  String get uid => uidValue;

  @override
  String? get email => emailValue;

  @override
  bool get emailVerified => verified;

  @override
  Future<void> sendEmailVerification([
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    sentVerificationCount++;
  }

  @override
  Future<void> updateDisplayName(String? displayName) async {
    updatedDisplayName = displayName;
  }

  @override
  Future<void> reload() async {
    reloadCount++;
  }
}

class _FakeUserCredential extends Mock implements UserCredential {
  _FakeUserCredential(this.userValue);
  final User? userValue;

  @override
  User? get user => userValue;
}

void main() {
  group('AuthService', () {
    late _FakeFirebaseAuth auth;
    late FakeFirebaseFirestore firestore;
    late AuthService service;

    setUp(() {
      auth = _FakeFirebaseAuth();
      firestore = FakeFirebaseFirestore();
      service = AuthService(auth: auth, firestore: firestore);
    });

    test('delegates email/password sign-in to FirebaseAuth', () async {
      final credential = _FakeUserCredential(null);
      auth.signInHandler = ({required email, required password}) async {
        expect(email, 'user@example.com');
        expect(password, 'secret123');
        return credential;
      };

      final result = await service.signInWithEmailAndPassword(
        'user@example.com',
        'secret123',
      );

      expect(result, same(credential));
    });

    test('register creates user and Firestore user document', () async {
      final user = _FakeUser(
        uidValue: 'uid-123',
        emailValue: 'new@example.com',
      );
      final credential = _FakeUserCredential(user);

      auth.createUserHandler = ({required email, required password}) async {
        expect(email, 'new@example.com');
        expect(password, 'password123');
        return credential;
      };

      final result = await service.registerWithEmailAndPassword(
        'new@example.com',
        'password123',
        'New User',
        zipCode: '10001',
      );

      expect(result, same(credential));
      expect(user.updatedDisplayName, 'New User');

      final doc = await firestore.collection('users').doc('uid-123').get();
      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['id'], 'uid-123');
      expect(data['fullName'], 'New User');
      expect(data['email'], 'new@example.com');
      expect(data['zipCode'], '10001');
      expect(data['userType'], 'regular');
      expect(data['isVerified'], isFalse);
    });

    test('resetPassword delegates to FirebaseAuth', () async {
      String? capturedEmail;
      auth.resetPasswordHandler = ({required email}) async {
        capturedEmail = email;
      };

      await service.resetPassword('reset@example.com');

      expect(capturedEmail, 'reset@example.com');
    });

    test('sendEmailVerification throws when no authenticated user', () async {
      auth.currentUserValue = null;

      expect(service.sendEmailVerification, throwsException);
    });

    test('sendEmailVerification sends when user not verified', () async {
      final user = _FakeUser(
        uidValue: 'uid-1',
        emailValue: 'verify@example.com',
      );
      auth.currentUserValue = user;

      await service.sendEmailVerification();

      expect(user.sentVerificationCount, 1);
    });

    test('sendEmailVerification does nothing when already verified', () async {
      final user = _FakeUser(
        uidValue: 'uid-1',
        emailValue: 'verify@example.com',
        verified: true,
      );
      auth.currentUserValue = user;

      await service.sendEmailVerification();

      expect(user.sentVerificationCount, 0);
    });

    test('isEmailVerified reflects current user state', () {
      final user = _FakeUser(uidValue: 'uid-1', verified: true);
      auth.currentUserValue = user;

      expect(service.isEmailVerified, isTrue);
    });

    test('reloadUser calls currentUser.reload', () async {
      final user = _FakeUser(uidValue: 'uid-1');
      auth.currentUserValue = user;

      await service.reloadUser();

      expect(user.reloadCount, 1);
    });
  });
}
