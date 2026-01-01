import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'message_model.dart';

class ChatModel {
  final String id;
  final List<String> participantIds;
  final MessageModel? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isGroup;
  final String? groupName;
  final String? groupImage;
  final Map<String, int> unreadCounts;
  final String? creatorId;
  final List<Map<String, dynamic>>? participants;

  ChatModel({
    required this.id,
    required this.participantIds,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.isGroup = false,
    this.groupName,
    this.groupImage,
    required this.unreadCounts,
    this.creatorId,
    this.participants,
  });

  int get unreadCount =>
      unreadCounts[FirebaseAuth.instance.currentUser?.uid ?? ''] ?? 0;

  /// Get participant information by user ID
  Map<String, dynamic>? getParticipant(String userId) {
    if (participants == null) return null;

    for (final participant in participants ?? []) {
      if (participant['id'] == userId) {
        // Ensure the participant is a Map<String, dynamic>
        if (participant is Map<String, dynamic>) {
          return participant;
        } else if (participant is Map) {
          return Map<String, dynamic>.from(participant);
        }
      }
    }
    return null;
  }

  /// Get display name for a participant
  String getParticipantDisplayName(String userId) {
    final participant = getParticipant(userId);
    if (participant == null) return 'Unknown User';

    return participant['displayName'] as String? ??
        participant['fullName'] as String? ??
        participant['username'] as String? ??
        'Unknown User';
  }

  /// Get photo URL for a participant
  String? getParticipantPhotoUrl(String userId) {
    final participant = getParticipant(userId);
    if (participant == null) return null;

    return participant['photoUrl'] as String? ??
        participant['profileImageUrl'] as String?;
  }

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatModel(
      id: doc.id,
      participantIds:
          (data['participantIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      lastMessage: data['lastMessage'] != null
          ? MessageModel.fromMap(data['lastMessage'] as Map<String, dynamic>)
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isGroup: data['isGroup'] as bool? ?? false,
      groupName: data['groupName'] as String?,
      groupImage: data['groupImage'] as String?,
      unreadCounts:
          (data['unreadCounts'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), (value as num).toInt()),
          ) ??
          {},
      creatorId: data['creatorId'] as String?,
      participants: (data['participants'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = {
      'participantIds': participantIds,
      'lastMessage': lastMessage?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isGroup': isGroup,
      'groupName': groupName,
      'groupImage': groupImage,
      'unreadCounts': unreadCounts,
      'creatorId': creatorId,
      'participants': participants,
    };
    // Remove null values to prevent iOS crash in cloud_firestore plugin
    map.removeWhere((key, value) => value == null);
    return map;
  }
}
