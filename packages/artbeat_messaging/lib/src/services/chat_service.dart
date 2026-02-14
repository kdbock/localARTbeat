import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/message_thread_model.dart';
import '../models/user_model.dart' as messaging;
import '../models/search_result_model.dart';
import 'notification_service.dart' as messaging_notifications;
import 'package:artbeat_core/artbeat_core.dart' as core;

class ChatService extends ChangeNotifier {
  static final Logger _logger = Logger('ChatService');

  FirebaseFirestore? _firestoreInstance;
  FirebaseAuth? _authInstance;
  FirebaseStorage? _storageInstance;
  messaging_notifications.NotificationService? _notificationServiceInstance;

  // Lazy initialization getters
  FirebaseFirestore get _firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authInstance ??= FirebaseAuth.instance;
  FirebaseStorage get _storage => _storageInstance ??= FirebaseStorage.instance;
  messaging_notifications.NotificationService get _notificationService =>
      _notificationServiceInstance ??=
          messaging_notifications.NotificationService();

  ChatService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    messaging_notifications.NotificationService? notificationService,
  }) : _firestoreInstance = firestore,
       _authInstance = auth,
       _storageInstance = storage,
       _notificationServiceInstance = notificationService;

  String get currentUserId {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    return userId;
  }

  String? get currentUserIdSafe {
    return _auth.currentUser?.uid;
  }

  Stream<List<ChatModel>> getChatStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.error(Exception('User not authenticated'));
    }

    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          try {
            final chats = <ChatModel>[];
            for (final doc in snapshot.docs) {
              try {
                final chat = ChatModel.fromFirestore(doc);
                chats.add(chat);
              } catch (e) {
                core.AppLogger.error(
                  'Error parsing chat document ${doc.id}: $e',
                );
                // Skip malformed documents rather than breaking the entire stream
                continue;
              }
            }
            return chats;
          } catch (e) {
            core.AppLogger.error('Error processing chat stream: $e');
            rethrow;
          }
        })
        .handleError((Object error) {
          core.AppLogger.error('Chat stream error: $error');
          throw Exception('Failed to load chats: $error');
        });
  }

  Future<List<ChatModel>> getChats() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final snapshot = await _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
  }

  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> sendMessage(String chatId, String text) async {
    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUserId,
      content: text,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );
    return _sendMessage(chatId, message);
  }

  Future<void> sendImage(String chatId, String imagePath) async {
    final file = File(imagePath);
    final ref = _storage
        .ref()
        .child('chat_images')
        .child(chatId)
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

    await ref.putFile(file);
    final imageUrl = await ref.getDownloadURL();

    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUserId,
      content: imageUrl,
      timestamp: DateTime.now(),
      type: MessageType.image,
    );
    return _sendMessage(chatId, message);
  }

  Future<void> _sendMessage(String chatId, MessageModel message) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());

    // Get current chat to access participant IDs
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final chatData = chatDoc.data() as Map<String, dynamic>;
    final participantIds =
        (chatData['participantIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    // Get current unread counts
    final currentUnreadCounts =
        (chatData['unreadCounts'] as Map<dynamic, dynamic>?)?.map(
          (key, value) => MapEntry(key.toString(), (value as num).toInt()),
        ) ??
        <String, int>{};

    // Update unread counts for all participants except the sender
    final updatedUnreadCounts = <String, int>{};
    for (String participantId in participantIds) {
      if (participantId != message.senderId) {
        // Increment unread count for other participants
        updatedUnreadCounts[participantId] =
            (currentUnreadCounts[participantId] ?? 0) + 1;
      } else {
        // Keep sender's unread count at 0
        updatedUnreadCounts[participantId] = 0;
      }
    }

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message.toMap(),
      'updatedAt': Timestamp.now(),
      'unreadCounts': updatedUnreadCounts,
    });

    // Send notifications to other participants
    await _sendMessageNotifications(chatId, message, participantIds);
  }

  Stream<List<MessageModel>> getMessageStream(String chatId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  Stream<Map<String, bool>> getTypingStatus(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .doc('status')
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            return <String, bool>{};
          }

          final data = snapshot.data()!;
          return Map<String, bool>.from(data);
        });
  }

  Future<void> updateTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    try {
      final typingRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .doc('status');

      if (isTyping) {
        await typingRef.set({userId: true}, SetOptions(merge: true));
        // Start an auto-reset timer
        Future.delayed(const Duration(seconds: 5), () async {
          try {
            final snapshot = await typingRef.get();
            final data = snapshot.data();
            if (data?[userId] == true) {
              await typingRef.update({userId: false});
            }
          } catch (e) {
            core.AppLogger.error('Error in auto-reset timer: $e');
          }
        });
      } else {
        await typingRef.update({userId: false});
      }
    } catch (e) {
      core.AppLogger.error('Error updating typing status: $e');
    }
  }

  Future<void> clearTypingStatus(String chatId, String userId) async {
    try {
      final typingRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .doc('status');

      await typingRef.set({
        userId: FieldValue.delete(),
      }, SetOptions(merge: true));
    } catch (e) {
      core.AppLogger.error('Error clearing typing status: $e');
    }
  }

  Future<String?> getUserDisplayName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return null;
      }
      final userData = userDoc.data();
      if (userData == null) {
        return null;
      }

      // Use the same fallback logic as UserModel.fromFirestore
      return userData['displayName'] as String? ??
          userData['fullName'] as String? ??
          userData['username'] as String?;
    } catch (e) {
      core.AppLogger.error('Error getting user display name: $e');
      return null;
    }
  }

  Future<String?> getUserPhotoUrl(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return null;
      }
      final userData = userDoc.data();
      if (userData == null) {
        return null;
      }

      // Use the same fallback logic as UserModel.fromFirestore
      return userData['photoUrl'] as String? ??
          userData['profileImageUrl'] as String?;
    } catch (e) {
      core.AppLogger.error('Error getting user photo URL: $e');
      return null;
    }
  }

  Future<List<ChatModel>> searchChats(String query) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    query = query.toLowerCase();
    final chats = await getChats();
    final filteredChats = <ChatModel>[];

    for (final chat in chats) {
      if (chat.isGroup && chat.groupName != null) {
        if (chat.groupName!.toLowerCase().contains(query)) {
          filteredChats.add(chat);
        }
        continue;
      }

      // Search participant names
      for (final participantId in chat.participantIds.where(
        (id) => id != userId,
      )) {
        final name = await getUserDisplayName(participantId);
        if (name?.toLowerCase().contains(query) ?? false) {
          filteredChats.add(chat);
          break;
        }
      }
    }

    return filteredChats;
  }

  Future<List<messaging.UserModel>> searchUsers(String query) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    if (query.isEmpty) return [];

    query = query.toLowerCase().trim();
    try {
      // Since Firestore doesn't support full-text search, we'll use multiple queries
      // and combine the results
      final List<messaging.UserModel> allResults = [];
      final Set<String> seenIds = <String>{};

      // Search by fullName (case-insensitive prefix search)
      try {
        final fullNameQuery = await _firestore
            .collection('users')
            .orderBy('fullName')
            .startAt([query])
            .endAt(['$query\uf8ff'])
            .limit(10)
            .get();

        for (final doc in fullNameQuery.docs) {
          if (!seenIds.contains(doc.id) && doc.id != userId) {
            final user = messaging.UserModel.fromFirestore(doc);
            allResults.add(user);
            seenIds.add(doc.id);
          }
        }
      } catch (e) {
        core.AppLogger.error('Error in fullName search: $e');
      }

      // Search by username (case-insensitive prefix search)
      try {
        final usernameQuery = await _firestore
            .collection('users')
            .orderBy('username')
            .startAt([query])
            .endAt(['$query\uf8ff'])
            .limit(10)
            .get();

        for (final doc in usernameQuery.docs) {
          if (!seenIds.contains(doc.id) && doc.id != userId) {
            final user = messaging.UserModel.fromFirestore(doc);
            allResults.add(user);
            seenIds.add(doc.id);
          }
        }
      } catch (e) {
        core.AppLogger.error('Error in username search: $e');
      }

      // Search by zipCode (exact match)
      try {
        final zipCodeQuery = await _firestore
            .collection('users')
            .where('zipCode', isEqualTo: query)
            .limit(10)
            .get();

        for (final doc in zipCodeQuery.docs) {
          if (!seenIds.contains(doc.id) && doc.id != userId) {
            final user = messaging.UserModel.fromFirestore(doc);
            allResults.add(user);
            seenIds.add(doc.id);
          }
        }
      } catch (e) {
        core.AppLogger.error('Error in zipCode search: $e');
      }

      // If we still don't have many results, do a broader search
      if (allResults.length < 5) {
        try {
          // Get all users and do client-side filtering (not ideal for large datasets)
          final allUsersQuery = await _firestore
              .collection('users')
              .limit(100) // Limit to prevent too much data transfer
              .get();

          for (final doc in allUsersQuery.docs) {
            if (!seenIds.contains(doc.id) && doc.id != userId) {
              final data = doc.data();
              final fullName = (data['fullName'] as String? ?? '')
                  .toLowerCase();
              final username = (data['username'] as String? ?? '')
                  .toLowerCase();
              final location = (data['location'] as String? ?? '')
                  .toLowerCase();

              // Check if query matches any part of the name or location
              if (fullName.contains(query) ||
                  username.contains(query) ||
                  location.contains(query)) {
                final user = messaging.UserModel.fromFirestore(doc);
                allResults.add(user);
                seenIds.add(doc.id);

                if (allResults.length >= 20) break; // Limit results
              }
            }
          }
        } catch (e) {
          core.AppLogger.error('Error in broad search: $e');
        }
      }

      return allResults;
    } catch (e) {
      core.AppLogger.error('Error searching users: $e');
      throw Exception('Failed to search users');
    }
  }

  Future<ChatModel> createOrGetChat(String otherUserId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Check if chat already exists
      final existingChatQuery = await _firestore
          .collection('chats')
          .where('participantIds', arrayContainsAny: [userId])
          .where('isGroup', isEqualTo: false)
          .get();

      for (final doc in existingChatQuery.docs) {
        final participantIds = (doc.data()['participantIds'] as List)
            .cast<String>();
        if (participantIds.contains(otherUserId) &&
            participantIds.length == 2) {
          return ChatModel.fromFirestore(doc);
        }
      }

      // No existing chat found, create new one
      final otherUser = await _firestore
          .collection('users')
          .doc(otherUserId)
          .get();

      if (!otherUser.exists) {
        throw Exception('Other user not found');
      }

      final currentUser = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!currentUser.exists) {
        throw Exception('Current user not found');
      }

      final chatDoc = await _firestore.collection('chats').add({
        'participantIds': [userId, otherUserId],
        'participants': [currentUser.data(), otherUser.data()],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isGroup': false,
        'unreadCounts': {userId: 0, otherUserId: 0},
      });

      final newChat = await chatDoc.get();
      return ChatModel.fromFirestore(newChat);
    } catch (e) {
      core.AppLogger.error('Error creating/getting chat: $e');
      throw Exception('Failed to create or get chat');
    }
  }

  Future<ChatModel> createGroupChat({
    required String groupName,
    required List<String> participantIds,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Add current user to participants if not already included
    if (!participantIds.contains(userId)) {
      participantIds.add(userId);
    }

    try {
      // Get all participant user documents
      final participantDocs = await Future.wait(
        participantIds.map(
          (id) => _firestore.collection('users').doc(id).get(),
        ),
      );

      // Verify all users exist
      if (participantDocs.any((doc) => !doc.exists)) {
        throw Exception('One or more users not found');
      }

      // Initialize unread counts for all participants
      final initialUnreadCounts = <String, int>{};
      for (String participantId in participantIds) {
        initialUnreadCounts[participantId] = 0;
      }

      // Create new group chat
      final chatDoc = await _firestore.collection('chats').add({
        'participantIds': participantIds,
        'participants': participantDocs.map((doc) => doc.data()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isGroup': true,
        'groupName': groupName,
        'unreadCounts': initialUnreadCounts,
      });

      final newChat = await chatDoc.get();
      return ChatModel.fromFirestore(newChat);
    } catch (e) {
      core.AppLogger.error('Error creating group chat: $e');
      throw Exception('Failed to create group chat');
    }
  }

  /// Refreshes the chat list by clearing any cached data and triggering a reload
  Future<void> refresh() async {
    try {
      // Force a refresh by notifying listeners
      notifyListeners();

      // You can also add any cache clearing logic here if needed
      core.AppLogger.info('Chat service refreshed');
    } catch (e) {
      core.AppLogger.error('Error refreshing chat service: $e');
    }
  }

  /// Marks a chat as read for the current user
  Future<void> markChatAsRead(String chatId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Update the chat's unreadCounts field to reset the current user's count
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCounts.$userId': 0,
      });

      // Decrement badge count when user reads messages
      await _notificationService.decrementBadgeCount();
    } catch (e) {
      core.AppLogger.error('Error marking chat as read: $e');
    }
  }

  /// Called when user opens the messaging screen - clears badge and marks notifications as read
  Future<void> onOpenMessaging() async {
    try {
      await _notificationService.onMessagingScreenOpened();
    } catch (e) {
      core.AppLogger.error('Error on open messaging: $e');
    }
  }

  /// Migrates chats that are missing unreadCounts field
  Future<void> _migrateUnreadCounts(
    String chatId,
    List<String> participantIds,
  ) async {
    try {
      final unreadCounts = <String, int>{};
      for (String participantId in participantIds) {
        unreadCounts[participantId] = 0;
      }

      await _firestore.collection('chats').doc(chatId).update({
        'unreadCounts': unreadCounts,
      });

      core.AppLogger.info(
        'ChatService: Migrated unreadCounts for chat $chatId',
      );
    } catch (e) {
      debugPrint(
        'ChatService: Error migrating unreadCounts for chat $chatId: $e',
      );
    }
  }

  /// Gets the total unread messages count across all non-archived chats
  Stream<int> getTotalUnreadCount() {
    final userId = _auth.currentUser?.uid;
    core.AppLogger.info('ChatService.getTotalUnreadCount: userId = $userId');
    if (userId == null) {
      debugPrint(
        'ChatService.getTotalUnreadCount: No user logged in, returning 0',
      );
      return Stream.value(0);
    }

    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          int totalUnread = 0;
          debugPrint(
            'ChatService.getTotalUnreadCount: Processing ${snapshot.docs.length} chats',
          );

          // Get archived chat IDs to exclude them
          final archivedChatIds = <String>{};
          try {
            final archivedSnapshot = await _firestore
                .collection('users')
                .doc(userId)
                .collection('archivedChats')
                .get();

            for (final doc in archivedSnapshot.docs) {
              archivedChatIds.add(doc.data()['chatId'] as String);
            }
          } catch (e) {
            core.AppLogger.error(
              'Error getting archived chat IDs for unread count: $e',
            );
          }

          for (final doc in snapshot.docs) {
            try {
              // Skip archived chats
              if (archivedChatIds.contains(doc.id)) {
                debugPrint(
                  'ChatService.getTotalUnreadCount: Skipping archived chat ${doc.id}',
                );
                continue;
              }

              final data = doc.data();
              final participantIds =
                  (data['participantIds'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [];

              final unreadCounts =
                  data['unreadCounts'] as Map<dynamic, dynamic>?;

              if (unreadCounts != null) {
                final userUnreadCount = unreadCounts[userId] as int? ?? 0;
                debugPrint(
                  'ChatService.getTotalUnreadCount: Chat ${doc.id} has $userUnreadCount unread for user',
                );
                totalUnread += userUnreadCount;
              } else {
                debugPrint(
                  'ChatService.getTotalUnreadCount: Chat ${doc.id} has no unreadCounts field, migrating...',
                );
                // Migrate the chat to have unreadCounts field
                await _migrateUnreadCounts(doc.id, participantIds);
                // After migration, the count is 0 for all participants
                debugPrint(
                  'ChatService.getTotalUnreadCount: Chat ${doc.id} migrated, unread count = 0',
                );
              }
            } catch (e) {
              core.AppLogger.error(
                'Error parsing unread count for chat ${doc.id}: $e',
              );
            }
          }

          debugPrint(
            'ChatService.getTotalUnreadCount: Total unread count = $totalUnread',
          );
          return totalUnread;
        });
  }

  /// Gets a stream of typing status updates for a chat
  Stream<Map<String, bool>> getTypingStatusStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('typingStatus')
        .snapshots()
        .map((snapshot) {
          final data = <String, dynamic>{};
          for (var doc in snapshot.docs) {
            data[doc.id] = doc.data()['isTyping'] ?? false;
          }
          return data.cast<String, bool>();
        });
  }

  /// Gets a user by ID
  Future<messaging.UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return messaging.UserModel.fromFirestore(doc);
    } catch (e) {
      core.AppLogger.error('Error getting user: $e');
      return null;
    }
  }

  /// Gets a chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (!doc.exists) return null;
      return ChatModel.fromFirestore(doc);
    } catch (e) {
      core.AppLogger.error('Error getting chat: $e');
      return null;
    }
  }

  /// Gets blocked users for current user
  Future<List<messaging.UserModel>> getBlockedUsers() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('blockedUsers')
          .get();

      final blockedUsers = <messaging.UserModel>[];
      for (final doc in snapshot.docs) {
        final blockedUserId = doc.id;
        final userData = doc.data();

        // Get full user data from users collection
        final userDoc = await _firestore
            .collection('users')
            .doc(blockedUserId)
            .get();

        if (userDoc.exists) {
          final user = messaging.UserModel.fromFirestore(userDoc);
          // Add blocked date from the blockedUsers collection
          user.blockedAt = (userData['blockedAt'] as Timestamp?)?.toDate();
          blockedUsers.add(user);
        }
      }

      return blockedUsers;
    } catch (e) {
      core.AppLogger.error('Error getting blocked users: $e');
      return [];
    }
  }

  /// Blocks a user
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
    } catch (e) {
      core.AppLogger.error('Error blocking user: $e');
      throw Exception('Failed to block user');
    }
  }

  /// Unblocks a user
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
    } catch (e) {
      core.AppLogger.error('Error unblocking user: $e');
      throw Exception('Failed to unblock user');
    }
  }

  /// Checks if a user is blocked
  Future<bool> isUserBlocked(String userId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      core.AppLogger.error('Error checking if user is blocked: $e');
      return false;
    }
  }

  /// Refresh participant data for a chat
  Future<void> refreshChatParticipants(String chatId) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) return;

      final chatData = chatDoc.data() as Map<String, dynamic>;
      final participantIds =
          (chatData['participantIds'] as List?)?.cast<String>() ?? [];

      if (participantIds.isEmpty) return;

      // Fetch fresh participant data
      final participantDocs = await Future.wait(
        participantIds.map(
          (id) => _firestore.collection('users').doc(id).get(),
        ),
      );

      final participants = participantDocs
          .where((doc) => doc.exists)
          .map((doc) => doc.data())
          .where((data) => data != null)
          .toList();

      // Update the chat document with fresh participant data
      await _firestore.collection('chats').doc(chatId).update({
        'participants': participants,
      });

      core.AppLogger.info('Refreshed participant data for chat $chatId');
    } catch (e) {
      core.AppLogger.error('Error refreshing chat participants: $e');
    }
  }

  /// Clears all messages in a chat
  Future<void> clearChatHistory(String chatId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final batch = _firestore.batch();

      // Get all messages in the chat
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      // Delete all messages
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Update chat's lastMessage and updatedAt
      batch.update(_firestore.collection('chats').doc(chatId), {
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      core.AppLogger.info('Chat history cleared for chat $chatId');
    } catch (e) {
      core.AppLogger.error('Error clearing chat history: $e');
      throw Exception('Failed to clear chat history');
    }
  }

  /// Delete a single message
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      // Check if the message exists and user has permission to delete
      final messageDoc = await messageRef.get();
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data()!;
      if (messageData['senderId'] != currentUserId) {
        throw Exception('You can only delete your own messages');
      }

      // Delete the message
      await messageRef.delete();

      // Update chat's last message if this was the last message
      final lastMessage = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (lastMessage.docs.isNotEmpty) {
        final newLastMessageData = lastMessage.docs.first.data();
        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage':
              newLastMessageData['content'] ?? newLastMessageData['text'],
          'lastMessageTime': newLastMessageData['timestamp'],
          'lastMessageSenderId': newLastMessageData['senderId'],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // No messages left in chat
        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': currentUserId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      notifyListeners();
    } catch (e) {
      core.AppLogger.error('Error deleting message: $e');
      rethrow;
    }
  }

  /// Leaves a group chat
  Future<void> leaveGroup(String chatId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) throw Exception('Chat not found');

      final chatData = chatDoc.data() as Map<String, dynamic>;
      final participantIds =
          (chatData['participantIds'] as List?)?.cast<String>() ?? [];

      if (!participantIds.contains(currentUserId)) {
        throw Exception('User is not a participant in this chat');
      }

      // Remove current user from participants
      participantIds.remove(currentUserId);

      // Update the chat document
      await _firestore.collection('chats').doc(chatId).update({
        'participantIds': participantIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add a system message about leaving
      final leaveMessage = MessageModel(
        id: _firestore.collection('temp').doc().id,
        senderId: 'system',
        content: 'User left the group',
        timestamp: DateTime.now(),
        type: MessageType
            .text, // Use text, or add MessageType.system if you want a new type
      );

      await _sendMessage(chatId, leaveMessage);
      core.AppLogger.info('Left group chat $chatId');
    } catch (e) {
      core.AppLogger.error('Error leaving group: $e');
      throw Exception('Failed to leave group');
    }
  }

  /// Deletes a chat completely
  Future<void> deleteChat(String chatId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final batch = _firestore.batch();

      // Get all messages in the chat
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      // Delete all messages
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the chat document
      batch.delete(_firestore.collection('chats').doc(chatId));

      await batch.commit();
      core.AppLogger.info('Chat deleted: $chatId');
    } catch (e) {
      core.AppLogger.error('Error deleting chat: $e');
      throw Exception('Failed to delete chat');
    }
  }

  /// Reports a user
  Future<void> reportUser(String userId, String reason) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore.collection('reports').add({
        'reporterId': currentUserId,
        'reportedUserId': userId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': 'user_report',
      });
      core.AppLogger.info('User reported: $userId');
    } catch (e) {
      core.AppLogger.error('Error reporting user: $e');
      throw Exception('Failed to report user');
    }
  }

  /// Sends push notifications to other participants when a new message is sent
  Future<void> _sendMessageNotifications(
    String chatId,
    MessageModel message,
    List<String> participantIds,
  ) async {
    try {
      // Get sender's display name
      final senderName =
          await getUserDisplayName(message.senderId) ?? 'Someone';

      // Get chat info to determine notification title
      final chat = await getChatById(chatId);
      String notificationTitle;

      if (chat?.isGroup == true) {
        notificationTitle = chat?.groupName ?? 'Group Chat';
      } else {
        notificationTitle = senderName;
      }

      // Send notifications to all participants except the sender
      for (final participantId in participantIds) {
        if (participantId != message.senderId) {
          await _sendNotificationToUser(
            participantId,
            notificationTitle,
            message.content,
            {
              'chatId': chatId,
              'messageId': message.id,
              'senderId': message.senderId,
              'type': 'new_message',
            },
          );
        }
      }
    } catch (e) {
      core.AppLogger.error('Error sending message notifications: $e');
      // Don't throw error to avoid breaking message sending
    }
  }

  /// Sends a notification to a specific user
  Future<void> _sendNotificationToUser(
    String userId,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      // Use the notification service to send the notification
      await _notificationService.sendNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        data: data,
      );
    } catch (e) {
      core.AppLogger.error('❌ Error sending notification to user $userId: $e');
    }
  }

  /// Archives a chat for the current user
  Future<void> archiveChat(String chatId) async {
    final userId = currentUserId;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('archivedChats')
          .doc(chatId)
          .set({'archivedAt': Timestamp.now(), 'chatId': chatId});

      core.AppLogger.info('Chat $chatId archived for user $userId');
      notifyListeners();
    } catch (e) {
      core.AppLogger.error('Error archiving chat: $e');
      throw Exception('Failed to archive chat');
    }
  }

  /// Unarchives a chat for the current user
  Future<void> unarchiveChat(String chatId) async {
    final userId = currentUserId;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('archivedChats')
          .doc(chatId)
          .delete();

      core.AppLogger.info('Chat $chatId unarchived for user $userId');
      notifyListeners();
    } catch (e) {
      core.AppLogger.error('Error unarchiving chat: $e');
      throw Exception('Failed to unarchive chat');
    }
  }

  /// Checks if a chat is archived for the current user
  Future<bool> isChatArchived(String chatId) async {
    final userId = currentUserIdSafe;
    if (userId == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('archivedChats')
          .doc(chatId)
          .get();

      return doc.exists;
    } catch (e) {
      core.AppLogger.error('Error checking if chat is archived: $e');
      return false;
    }
  }

  /// Gets archived chats for the current user
  Stream<List<ChatModel>> getArchivedChatsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.error(Exception('User not authenticated'));
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('archivedChats')
        .orderBy('archivedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          try {
            final chats = <ChatModel>[];
            for (final doc in snapshot.docs) {
              try {
                final chatId = doc.data()['chatId'] as String;
                final chatDoc = await _firestore
                    .collection('chats')
                    .doc(chatId)
                    .get();
                if (chatDoc.exists) {
                  final chat = ChatModel.fromFirestore(chatDoc);
                  chats.add(chat);
                }
              } catch (e) {
                debugPrint(
                  'Error parsing archived chat document ${doc.id}: $e',
                );
                continue;
              }
            }
            return chats;
          } catch (e) {
            core.AppLogger.error('Error processing archived chat stream: $e');
            rethrow;
          }
        })
        .handleError((Object error) {
          core.AppLogger.error('Archived chat stream error: $error');
          throw Exception('Failed to load archived chats: $error');
        });
  }

  /// Gets non-archived chats (modified version of getChatStream)
  Stream<List<ChatModel>> getNonArchivedChatsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.error(Exception('User not authenticated'));
    }

    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          try {
            final chats = <ChatModel>[];
            final archivedChatIds = <String>{};

            // Get archived chat IDs
            try {
              final archivedSnapshot = await _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('archivedChats')
                  .get();

              for (final doc in archivedSnapshot.docs) {
                archivedChatIds.add(doc.data()['chatId'] as String);
              }
            } catch (e) {
              core.AppLogger.error('Error getting archived chat IDs: $e');
            }

            for (final doc in snapshot.docs) {
              try {
                // Skip archived chats
                if (archivedChatIds.contains(doc.id)) continue;

                final chat = ChatModel.fromFirestore(doc);
                chats.add(chat);
              } catch (e) {
                core.AppLogger.error(
                  'Error parsing chat document ${doc.id}: $e',
                );
                continue;
              }
            }
            return chats;
          } catch (e) {
            core.AppLogger.error(
              'Error processing non-archived chat stream: $e',
            );
            rethrow;
          }
        })
        .handleError((Object error) {
          core.AppLogger.error('Non-archived chat stream error: $error');
          throw Exception('Failed to load chats: $error');
        });
  }

  // Phase 3: Enhanced Message Interaction Features

  /// Edit a message
  Future<void> editMessage(
    String chatId,
    String messageId,
    String newContent,
  ) async {
    try {
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      final messageDoc = await messageRef.get();
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data()!;
      if (messageData['senderId'] != currentUserId) {
        throw Exception('You can only edit your own messages');
      }

      await messageRef.update({
        'content': newContent,
        'text': newContent, // For backward compatibility
        'isEdited': true,
        'editedAt': FieldValue.serverTimestamp(),
        'originalMessage': messageData['content'] ?? messageData['text'],
      });

      notifyListeners();
    } catch (e) {
      core.AppLogger.error('Error editing message: $e');
      rethrow;
    }
  }

  /// Forward a message to another chat
  Future<void> forwardMessage(
    String sourceMessageId,
    String sourceChatId,
    String targetChatId,
  ) async {
    try {
      final sourceMessageRef = _firestore
          .collection('chats')
          .doc(sourceChatId)
          .collection('messages')
          .doc(sourceMessageId);

      final sourceMessageDoc = await sourceMessageRef.get();
      if (!sourceMessageDoc.exists) {
        throw Exception('Source message not found');
      }

      final sourceMessageData = sourceMessageDoc.data()!;
      final targetMessagesRef = _firestore
          .collection('chats')
          .doc(targetChatId)
          .collection('messages');

      final forwardedMessage = {
        'senderId': currentUserId,
        'content': sourceMessageData['content'] ?? sourceMessageData['text'],
        'text': sourceMessageData['content'] ?? sourceMessageData['text'],
        'timestamp': FieldValue.serverTimestamp(),
        'type': sourceMessageData['type'] ?? 'text',
        'isForwarded': true,
        'forwardedFromId': sourceChatId,
        'originalSenderId': sourceMessageData['senderId'],
        'read': {currentUserId: false},
      };

      // Copy media URLs if present
      if (sourceMessageData['imageUrl'] != null) {
        forwardedMessage['imageUrl'] = sourceMessageData['imageUrl'];
      }
      if (sourceMessageData['fileUrl'] != null) {
        forwardedMessage['fileUrl'] = sourceMessageData['fileUrl'];
        forwardedMessage['fileName'] = sourceMessageData['fileName'];
      }

      await targetMessagesRef.add(forwardedMessage);

      // Update target chat's last message
      await _firestore.collection('chats').doc(targetChatId).update({
        'lastMessage':
            sourceMessageData['content'] ?? sourceMessageData['text'],
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUserId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      core.AppLogger.error('Error forwarding message: $e');
      rethrow;
    }
  }

  /// Star/unstar a message
  Future<void> toggleMessageStar(String chatId, String messageId) async {
    try {
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      await _firestore.runTransaction((transaction) async {
        final messageDoc = await transaction.get(messageRef);
        if (!messageDoc.exists) {
          throw Exception('Message not found');
        }

        final messageData = messageDoc.data()!;
        final starredBy = List<String>.from(
          (messageData['starredBy'] as List?) ?? [],
        );

        if (starredBy.contains(currentUserId)) {
          starredBy.remove(currentUserId);
        } else {
          starredBy.add(currentUserId);
        }

        transaction.update(messageRef, {
          'starredBy': starredBy,
          'isStarred': starredBy.isNotEmpty,
        });
      });

      notifyListeners();
    } catch (e) {
      core.AppLogger.error('Error toggling message star: $e');
      rethrow;
    }
  }

  /// Get starred messages for current user
  Stream<List<MessageModel>> getStarredMessagesStream() {
    return _firestore
        .collectionGroup('messages')
        .where('starredBy', arrayContains: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Global search across all chats
  Future<List<SearchResultModel>> globalSearch(
    String query, {
    int limit = 50,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final results = <SearchResultModel>[];

      // Get all chats for current user
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participantIds', arrayContains: currentUserId)
          .get();

      for (final chatDoc in chatsSnapshot.docs) {
        final chat = ChatModel.fromFirestore(chatDoc);

        // Search messages in each chat
        final messagesSnapshot = await _firestore
            .collection('chats')
            .doc(chatDoc.id)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(100) // Limit per chat to avoid overwhelming results
            .get();

        for (final messageDoc in messagesSnapshot.docs) {
          final message = MessageModel.fromFirestore(messageDoc);

          if (message.content.toLowerCase().contains(query.toLowerCase())) {
            final searchResult = SearchResultModel.fromMap(
              <String, dynamic>{},
              message: message,
              chat: chat,
              query: query,
            );
            results.add(searchResult);
          }
        }
      }

      // Sort by timestamp, most recent first
      results.sort(
        (a, b) => b.message.timestamp.compareTo(a.message.timestamp),
      );

      return results.take(limit).toList();
    } catch (e) {
      core.AppLogger.error('Error in global search: $e');
      rethrow;
    }
  }

  /// Search media in messages
  Future<List<MessageModel>> searchMedia(
    MessageType mediaType, {
    String? chatId,
  }) async {
    try {
      Query query;

      if (chatId != null) {
        // Search within specific chat
        query = _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('type', isEqualTo: mediaType.toString());
      } else {
        // Search across all user's chats
        final chatIds = <String>[];
        final chatsSnapshot = await _firestore
            .collection('chats')
            .where('participantIds', arrayContains: currentUserId)
            .get();

        for (final doc in chatsSnapshot.docs) {
          chatIds.add(doc.id);
        }

        if (chatIds.isEmpty) return [];

        // For global media search, we need to query each chat individually
        final allMedia = <MessageModel>[];

        for (final cId in chatIds) {
          final mediaSnapshot = await _firestore
              .collection('chats')
              .doc(cId)
              .collection('messages')
              .where('type', isEqualTo: mediaType.toString())
              .orderBy('timestamp', descending: true)
              .limit(20)
              .get();

          allMedia.addAll(
            mediaSnapshot.docs.map((doc) => MessageModel.fromFirestore(doc)),
          );
        }

        allMedia.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return allMedia;
      }

      final snapshot = await query.orderBy('timestamp', descending: true).get();

      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      core.AppLogger.error('Error searching media: $e');
      rethrow;
    }
  }

  /// Enhanced search with filters
  Future<List<SearchResultModel>> advancedSearch({
    required String query,
    String? chatId,
    DateTime? startDate,
    DateTime? endDate,
    String? senderId,
    MessageType? messageType,
    bool starredOnly = false,
    int limit = 50,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final results = <SearchResultModel>[];

      // Determine which chats to search
      List<String> chatIds;
      if (chatId != null) {
        chatIds = [chatId];
      } else {
        final chatsSnapshot = await _firestore
            .collection('chats')
            .where('participantIds', arrayContains: currentUserId)
            .get();
        chatIds = chatsSnapshot.docs.map((doc) => doc.id).toList();
      }

      for (final cId in chatIds) {
        Query messagesQuery = _firestore
            .collection('chats')
            .doc(cId)
            .collection('messages');

        // Apply filters
        if (startDate != null) {
          messagesQuery = messagesQuery.where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          );
        }
        if (endDate != null) {
          messagesQuery = messagesQuery.where(
            'timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          );
        }
        if (senderId != null) {
          messagesQuery = messagesQuery.where('senderId', isEqualTo: senderId);
        }
        if (messageType != null) {
          messagesQuery = messagesQuery.where(
            'type',
            isEqualTo: messageType.toString(),
          );
        }
        if (starredOnly) {
          messagesQuery = messagesQuery.where(
            'starredBy',
            arrayContains: currentUserId,
          );
        }

        final messagesSnapshot = await messagesQuery
            .orderBy('timestamp', descending: true)
            .limit(100)
            .get();

        // Get chat info for results
        final chatDoc = await _firestore.collection('chats').doc(cId).get();
        final chat = ChatModel.fromFirestore(chatDoc);

        for (final messageDoc in messagesSnapshot.docs) {
          final message = MessageModel.fromFirestore(messageDoc);

          if (message.content.toLowerCase().contains(query.toLowerCase())) {
            final searchResult = SearchResultModel.fromMap(
              <String, dynamic>{},
              message: message,
              chat: chat,
              query: query,
            );
            results.add(searchResult);
          }
        }
      }

      // Sort by timestamp, most recent first
      results.sort(
        (a, b) => b.message.timestamp.compareTo(a.message.timestamp),
      );

      return results.take(limit).toList();
    } catch (e) {
      core.AppLogger.error('Error in advanced search: $e');
      rethrow;
    }
  }

  // ===== THREADING METHODS =====

  /// Send a reply message to a specific message
  Future<void> sendReplyMessage(
    String chatId,
    String replyText,
    String replyToMessageId,
  ) async {
    try {
      final messageId = _firestore.collection('chats').doc().id;
      final messageData = {
        'id': messageId,
        'senderId': currentUserId,
        'content': replyText,
        'timestamp': FieldValue.serverTimestamp(),
        'type': MessageType.text.toString(),
        'isRead': false,
        'replyToId': replyToMessageId,
        'isStarred': false,
        'isEdited': false,
        'isForwarded': false,
      };

      // Add message to chat
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(messageData);

      // Update chat's last message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': {
          'id': messageId,
          'senderId': currentUserId,
          'content': replyText,
          'timestamp': FieldValue.serverTimestamp(),
          'type': MessageType.text.toString(),
        },
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      // Update or create message thread
      await _updateMessageThread(chatId, replyToMessageId, messageId);

      // Send notification
      final chat = await getChatById(chatId);
      if (chat != null) {
        for (final participantId in chat.participantIds) {
          if (participantId != currentUserId) {
            await _notificationService.sendNotificationToUser(
              userId: participantId,
              title: 'New reply',
              body: replyText,
              data: {
                'type': 'message_reply',
                'chatId': chatId,
                'messageId': messageId,
                'replyToId': replyToMessageId,
              },
            );
          }
        }
      }

      core.AppLogger.info('Reply message sent successfully: $messageId');
    } catch (e) {
      core.AppLogger.error('Error sending reply message: $e');
      rethrow;
    }
  }

  /// Get message thread for a specific message
  Future<MessageThreadModel?> getMessageThread(
    String chatId,
    String messageId,
  ) async {
    try {
      final threadDoc = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('threads')
          .doc(messageId)
          .get();

      if (threadDoc.exists) {
        return MessageThreadModel.fromFirestore(threadDoc);
      }

      return null;
    } catch (e) {
      core.AppLogger.error('Error getting message thread: $e');
      rethrow;
    }
  }

  /// Get all messages in a thread
  Future<List<MessageModel>> getThreadMessages(
    String chatId,
    String threadId,
  ) async {
    try {
      final thread = await getMessageThread(chatId, threadId);
      if (thread == null) return [];

      final messages = <MessageModel>[];

      // Add parent message
      final parentMessageDoc = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(thread.parentMessageId)
          .get();

      if (parentMessageDoc.exists) {
        messages.add(MessageModel.fromFirestore(parentMessageDoc));
      }

      // Add reply messages
      for (final replyId in thread.replyMessageIds) {
        final replyDoc = await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(replyId)
            .get();

        if (replyDoc.exists) {
          messages.add(MessageModel.fromFirestore(replyDoc));
        }
      }

      // Sort by timestamp
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return messages;
    } catch (e) {
      core.AppLogger.error('Error getting thread messages: $e');
      rethrow;
    }
  }

  /// Get stream of thread updates
  Stream<MessageThreadModel?> getMessageThreadStream(
    String chatId,
    String messageId,
  ) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('threads')
        .doc(messageId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return MessageThreadModel.fromFirestore(doc);
          }
          return null;
        });
  }

  /// Update or create message thread when a reply is added
  Future<void> _updateMessageThread(
    String chatId,
    String parentMessageId,
    String replyMessageId,
  ) async {
    try {
      final threadRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('threads')
          .doc(parentMessageId);

      final threadDoc = await threadRef.get();

      if (threadDoc.exists) {
        // Update existing thread
        final thread = MessageThreadModel.fromFirestore(threadDoc);
        final updatedThread = thread.addReply(replyMessageId);

        await threadRef.update(updatedThread.toMap());
      } else {
        // Create new thread
        final parentMessageDoc = await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(parentMessageId)
            .get();

        if (parentMessageDoc.exists) {
          final parentMessage = MessageModel.fromFirestore(parentMessageDoc);
          final newThread = MessageThreadModel(
            id: parentMessageId,
            chatId: chatId,
            parentMessageId: parentMessageId,
            replyMessageIds: [replyMessageId],
            threadStarterId: parentMessage.senderId,
            createdAt: parentMessage.timestamp,
            updatedAt: DateTime.now(),
            replyCount: 1,
            lastReplyId: replyMessageId,
            lastReplyAt: DateTime.now(),
            isActive: true,
          );

          await threadRef.set(newThread.toMap());
        }
      }
    } catch (e) {
      core.AppLogger.error('Error updating message thread: $e');
      rethrow;
    }
  }
}
