import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/legal_config.dart';
import '../utils/logger.dart';

/// Stores durable, versioned legal consent records for users.
class LegalConsentService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  LegalConsentService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> recordRegistrationConsent({
    required String userId,
    required String locale,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != userId) {
      throw StateError('Cannot record consent for unauthenticated user.');
    }

    final now = FieldValue.serverTimestamp();
    await _firestore.collection('users').doc(userId).set({
      'legalConsents': {
        'termsOfService': {
          'accepted': true,
          'version': LegalConfig.tosVersion,
          'acceptedAt': now,
          'surface': 'registration',
          'locale': locale,
        },
        'privacyPolicy': {
          'accepted': true,
          'version': LegalConfig.privacyVersion,
          'acceptedAt': now,
          'surface': 'registration',
          'locale': locale,
        },
      },
      'updatedAt': now,
    }, SetOptions(merge: true));

    AppLogger.info('Recorded legal consents for user $userId');
  }
}
