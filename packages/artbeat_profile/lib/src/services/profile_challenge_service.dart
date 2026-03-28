import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppLogger;
import '../models/profile_challenge_model.dart';

class ProfileChallengeService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProfileChallengeService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  Future<ProfileChallengeModel?> getTodaysChallenge({String? userId}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return null;

    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final challengeDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('dailyChallenges')
          .doc(todayKey)
          .get();

      if (!challengeDoc.exists) return null;

      return ProfileChallengeModel.fromMap(challengeDoc.data()!);
    } catch (e) {
      AppLogger.error('Error getting today challenge: $e');
      return null;
    }
  }
}
