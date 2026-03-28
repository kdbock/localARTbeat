import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/logger.dart';

class MessagingStatusService {
  MessagingStatusService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<int> getTotalUnreadCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          int totalUnread = 0;
          final archivedChatIds = <String>{};

          try {
            final archivedSnapshot = await _firestore
                .collection('users')
                .doc(userId)
                .collection('archivedChats')
                .get();

            for (final doc in archivedSnapshot.docs) {
              final chatId = doc.data()['chatId'] as String?;
              if (chatId != null && chatId.isNotEmpty) {
                archivedChatIds.add(chatId);
              }
            }
          } catch (error) {
            AppLogger.error(
              'Error getting archived chat IDs for unread count: $error',
            );
          }

          for (final doc in snapshot.docs) {
            try {
              if (archivedChatIds.contains(doc.id)) {
                continue;
              }

              final data = doc.data();
              final unreadCounts =
                  data['unreadCounts'] as Map<dynamic, dynamic>?;

              if (unreadCounts != null) {
                totalUnread += unreadCounts[userId] as int? ?? 0;
              }
            } catch (error) {
              AppLogger.error(
                'Error parsing unread count for chat ${doc.id}: $error',
              );
            }
          }

          return totalUnread;
        });
  }
}
