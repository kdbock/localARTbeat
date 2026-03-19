import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/daily_challenge_model.dart';
import '../utils/logger.dart';

class DailyChallengeProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> recordSocialShare() async {
    await _recordIfMatching((challenge) => challenge.title.contains('Sharer'));
  }

  Future<void> recordComment() async {
    await _recordIfMatching(
      (challenge) =>
          challenge.title.contains('Community') ||
          challenge.title.contains('Connector'),
    );
  }

  Future<void> _recordIfMatching(
    bool Function(DailyChallengeModel challenge) matches,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final today = DateTime.now();
      final todayKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final challengeRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dailyChallenges')
          .doc(todayKey);

      await _firestore.runTransaction((transaction) async {
        final challengeDoc = await transaction.get(challengeRef);
        if (!challengeDoc.exists) return;

        final challenge = DailyChallengeModel.fromMap(challengeDoc.data()!);
        if (challenge.isCompleted || !matches(challenge)) return;

        final newCount = (challenge.currentCount + 1).clamp(
          0,
          challenge.targetCount,
        );

        transaction.update(challengeRef, {
          'currentCount': newCount,
          'isCompleted': newCount >= challenge.targetCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      AppLogger.error('Error updating daily challenge progress: $e');
    }
  }
}
