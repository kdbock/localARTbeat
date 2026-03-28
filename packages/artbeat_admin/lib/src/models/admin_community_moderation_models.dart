import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

class AdminModeratedPost {
  final String id;
  final String content;
  final String authorName;
  final DateTime createdAt;
  final DateTime? flaggedAt;

  const AdminModeratedPost({
    required this.id,
    required this.content,
    required this.authorName,
    required this.createdAt,
    this.flaggedAt,
  });

  factory AdminModeratedPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AdminModeratedPost(
      id: doc.id,
      content: FirestoreUtils.safeStringDefault(data['content']),
      authorName: FirestoreUtils.safeString(data['authorName']) ??
          FirestoreUtils.safeString(data['userName']) ??
          'Unknown user',
      createdAt: FirestoreUtils.safeDateTime(data['createdAt']),
      flaggedAt: data['flaggedAt'] != null
          ? FirestoreUtils.safeDateTime(data['flaggedAt'])
          : null,
    );
  }
}

class AdminModeratedComment {
  final String id;
  final String content;
  final String userName;
  final DateTime createdAt;
  final DateTime? flaggedAt;

  const AdminModeratedComment({
    required this.id,
    required this.content,
    required this.userName,
    required this.createdAt,
    this.flaggedAt,
  });

  factory AdminModeratedComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AdminModeratedComment(
      id: doc.id,
      content: FirestoreUtils.safeStringDefault(data['content']),
      userName: FirestoreUtils.safeStringDefault(data['userName']),
      createdAt: FirestoreUtils.safeDateTime(data['createdAt']),
      flaggedAt: data['flaggedAt'] != null
          ? FirestoreUtils.safeDateTime(data['flaggedAt'])
          : null,
    );
  }
}
