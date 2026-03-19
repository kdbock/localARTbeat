import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppLogger;
import '../models/profile_achievement_model.dart';

class ProfileAchievementReadService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProfileAchievementReadService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  Future<List<ProfileAchievementModel>> getUserAchievements({
    String? userId,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('achievements')
          .get();

      return snapshot.docs
          .map(
            (doc) => ProfileAchievementModel.fromFirestoreMap(
              doc.data(),
              id: doc.id,
            ),
          )
          .toList()
        ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
    } catch (e) {
      AppLogger.error('Error getting user achievements: $e');
      return [];
    }
  }
}
