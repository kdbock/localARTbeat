import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:artbeat_core/artbeat_core.dart';

class AdminBroadcastService extends ChangeNotifier {
  AdminBroadcastService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<List<Map<String, dynamic>>> getRecentBroadcasts({int limit = 10}) {
    return _firestore
        .collection('broadcasts')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(growable: false),
        );
  }

  Future<void> sendBroadcastMessage(String message) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Admin not authenticated');
      }

      final usersSnapshot = await _firestore
          .collection('users')
          .where('isOnline', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      final timestamp = DateTime.now();

      final broadcastRef = _firestore.collection('broadcasts').doc();
      batch.set(broadcastRef, {
        'message': message,
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Admin',
        'timestamp': Timestamp.fromDate(timestamp),
        'recipientCount': usersSnapshot.docs.length,
      });

      final activityRef = _firestore.collection('admin_activity').doc();
      batch.set(activityRef, {
        'type': 'broadcast',
        'user': currentUser.displayName ?? 'Admin',
        'action':
            'Sent broadcast message to ${usersSnapshot.docs.length} users',
        'timestamp': Timestamp.fromDate(timestamp),
        'severity': 'low',
      });

      await batch.commit();
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error sending admin broadcast message: $e');
      rethrow;
    }
  }
}
