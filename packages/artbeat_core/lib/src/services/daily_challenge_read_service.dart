import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/daily_challenge_model.dart';
import '../utils/logger.dart';

class DailyChallengeReadService {
  FirebaseFirestore? _firestoreInstance;
  FirebaseAuth? _authInstance;

  void initialize() {
    _firestoreInstance ??= FirebaseFirestore.instance;
    _authInstance ??= FirebaseAuth.instance;
  }

  FirebaseFirestore get _firestore {
    initialize();
    return _firestoreInstance!;
  }

  FirebaseAuth get _auth {
    initialize();
    return _authInstance!;
  }

  Future<DailyChallengeModel?> getTodaysChallenge() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final today = DateTime.now();
      final todayKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final challengeDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dailyChallenges')
          .doc(todayKey)
          .get();

      if (!challengeDoc.exists) {
        return null;
      }

      return DailyChallengeModel.fromMap(challengeDoc.data()!);
    } catch (e) {
      AppLogger.error('Error getting today\'s challenge: $e');
      return null;
    }
  }
}
