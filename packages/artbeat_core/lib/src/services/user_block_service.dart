import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/logger.dart';

class UserBlockService {
  UserBlockService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> blockUser(String userId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(userId)
          .set({'blockedAt': FieldValue.serverTimestamp()});
    } catch (error) {
      AppLogger.error('Error blocking user: $error');
      throw Exception('Failed to block user');
    }
  }

  Future<void> unblockUser(String userId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(userId)
          .delete();
    } catch (error) {
      AppLogger.error('Error unblocking user: $error');
      throw Exception('Failed to unblock user');
    }
  }
}
