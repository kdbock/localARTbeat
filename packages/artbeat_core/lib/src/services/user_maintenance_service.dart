import 'package:cloud_firestore/cloud_firestore.dart';

class UserXpRepairResult {
  const UserXpRepairResult({
    required this.userId,
    required this.displayName,
    required this.actualApprovedCaptures,
    required this.storedCapturesCount,
    required this.previousXp,
    required this.updatedXp,
    required this.previousLevel,
    required this.updatedLevel,
    required this.wasUpdated,
  });

  final String userId;
  final String displayName;
  final int actualApprovedCaptures;
  final int storedCapturesCount;
  final int previousXp;
  final int updatedXp;
  final int previousLevel;
  final int updatedLevel;
  final bool wasUpdated;
}

class UserMaintenanceService {
  UserMaintenanceService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<bool> recalculateUserCaptureCount(String userId) async {
    final capturesSnapshot = await _firestore
        .collection('captures')
        .where('userId', isEqualTo: userId)
        .get();

    await _firestore.collection('users').doc(userId).update({
      'capturesCount': capturesSnapshot.size,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return true;
  }

  Future<UserXpRepairResult?> repairUserXpFromApprovedCaptures(
    String userId, {
    int xpPerApprovedCapture = 50,
    int xpPerLevel = 1000,
  }) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return null;
    }

    final userData = userDoc.data() ?? <String, dynamic>{};
    final currentXp = userData['experiencePoints'] as int? ?? 0;
    final currentLevel = userData['level'] as int? ?? 1;
    final storedCapturesCount = userData['capturesCount'] as int? ?? 0;

    final capturesQuery = await _firestore
        .collection('captures')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'approved')
        .get();

    final actualApprovedCaptures = capturesQuery.docs.length;
    final expectedXp = actualApprovedCaptures * xpPerApprovedCapture;
    final expectedLevel = (expectedXp ~/ xpPerLevel) + 1;
    final wasUpdated =
        expectedXp > currentXp ||
        actualApprovedCaptures != storedCapturesCount ||
        expectedLevel != currentLevel;

    if (wasUpdated) {
      await _firestore.collection('users').doc(userId).update({
        'experiencePoints': expectedXp,
        'level': expectedLevel,
        'capturesCount': actualApprovedCaptures,
        'lastXPGain': FieldValue.serverTimestamp(),
      });
    }

    return UserXpRepairResult(
      userId: userId,
      displayName: userData['fullName'] as String? ?? 'Unknown User',
      actualApprovedCaptures: actualApprovedCaptures,
      storedCapturesCount: storedCapturesCount,
      previousXp: currentXp,
      updatedXp: expectedXp,
      previousLevel: currentLevel,
      updatedLevel: expectedLevel,
      wasUpdated: wasUpdated,
    );
  }
}
