import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final String parentCommentId;
  final String type;
  final Timestamp createdAt;
  final String userName;
  final String userAvatarUrl;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.parentCommentId,
    required this.type,
    required this.createdAt,
    required this.userName,
    required this.userAvatarUrl,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CommentModel(
      id: doc.id,
      postId: FirestoreUtils.safeStringDefault(data['postId']),
      userId: FirestoreUtils.safeStringDefault(data['userId']),
      content: FirestoreUtils.safeStringDefault(data['content']),
      parentCommentId: FirestoreUtils.safeStringDefault(
        data['parentCommentId'],
      ),
      type: FirestoreUtils.safeStringDefault(data['type'], 'Appreciation'),
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : Timestamp.fromDate(FirestoreUtils.safeDateTime(data['createdAt'])),
      userName: FirestoreUtils.safeStringDefault(data['userName']),
      userAvatarUrl: FirestoreUtils.safeStringDefault(data['userAvatarUrl']),
    );
  }
}
