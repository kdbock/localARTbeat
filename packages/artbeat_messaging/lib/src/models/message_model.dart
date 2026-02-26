import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, video, file, location }

class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final bool isRead;
  final String? replyToId;
  final Map<String, dynamic>? metadata;
  final bool isStarred;
  final bool isEdited;
  final DateTime? editedAt;
  final String? originalMessage;
  final bool isForwarded;
  final String? forwardedFromId;
  final String? storagePath;
  final String? uploaderId;
  final String? chatId;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.isRead = false,
    this.replyToId,
    this.metadata,
    this.isStarred = false,
    this.isEdited = false,
    this.editedAt,
    this.originalMessage,
    this.isForwarded = false,
    this.forwardedFromId,
    this.storagePath,
    this.uploaderId,
    this.chatId,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: (map['id'] as String?) ?? '',
      senderId: (map['senderId'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == (map['type'] as String?),
        orElse: () => MessageType.text,
      ),
      isRead: (map['isRead'] as bool?) ?? false,
      replyToId: map['replyToId'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
      isStarred: (map['isStarred'] as bool?) ?? false,
      isEdited: (map['isEdited'] as bool?) ?? false,
      editedAt: map['editedAt'] != null
          ? (map['editedAt'] as Timestamp).toDate()
          : null,
      originalMessage: map['originalMessage'] as String?,
      isForwarded: (map['isForwarded'] as bool?) ?? false,
      forwardedFromId: map['forwardedFromId'] as String?,
      storagePath: map['storagePath'] as String?,
      uploaderId: map['uploaderId'] as String?,
      chatId: map['chatId'] as String?,
    );
  }

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: (data['senderId'] as String?) ?? '',
      content: (data['text'] as String?) ?? (data['content'] as String?) ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == (data['type'] as String?),
        orElse: () => MessageType.text,
      ),
      isRead:
          (data['read'] as Map<String, dynamic>?)?.values.contains(true) ??
          false,
      replyToId: data['replyToMessageId'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      isStarred: (data['isStarred'] as bool?) ?? false,
      isEdited: (data['isEdited'] as bool?) ?? false,
      editedAt: data['editedAt'] != null
          ? (data['editedAt'] as Timestamp).toDate()
          : null,
      originalMessage: data['originalMessage'] as String?,
      isForwarded: (data['isForwarded'] as bool?) ?? false,
      forwardedFromId: data['forwardedFromId'] as String?,
      storagePath: data['storagePath'] as String?,
      uploaderId: data['uploaderId'] as String?,
      chatId: data['chatId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'id': id,
      'senderId': senderId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toString(),
      'isRead': isRead,
      'replyToId': replyToId,
      'metadata': metadata,
      'isStarred': isStarred,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'originalMessage': originalMessage,
      'isForwarded': isForwarded,
      'forwardedFromId': forwardedFromId,
    };

    if (storagePath != null) data['storagePath'] = storagePath;
    if (uploaderId != null) data['uploaderId'] = uploaderId;
    if (chatId != null) data['chatId'] = chatId;

    return data;
  }
}
