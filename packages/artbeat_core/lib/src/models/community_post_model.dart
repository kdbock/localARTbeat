import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_utils.dart';

class CommunityPostModel {
  const CommunityPostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.content,
    required this.createdAt,
    required this.likesCount,
    required this.commentCount,
    required this.shareCount,
  });

  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String content;
  final DateTime createdAt;
  final int likesCount;
  final int commentCount;
  final int shareCount;

  factory CommunityPostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final engagementStats =
        data['engagementStats'] as Map<String, dynamic>? ?? data;

    return CommunityPostModel(
      id: doc.id,
      userId: FirestoreUtils.safeStringDefault(data['userId']),
      userName: FirestoreUtils.safeStringDefault(data['userName']),
      userPhotoUrl: FirestoreUtils.safeStringDefault(data['userPhotoUrl']),
      content: FirestoreUtils.safeStringDefault(data['content']),
      createdAt: FirestoreUtils.safeDateTime(data['createdAt']),
      likesCount: FirestoreUtils.safeInt(
        engagementStats['likeCount'] ?? data['likesCount'],
      ),
      commentCount: FirestoreUtils.safeInt(
        engagementStats['commentCount'] ?? data['commentCount'],
      ),
      shareCount: FirestoreUtils.safeInt(
        engagementStats['shareCount'] ?? data['shareCount'],
      ),
    );
  }
}
