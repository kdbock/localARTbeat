import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

class CommentModel {
  final String id;
  final String userId;
  final String content;
  final String? parentCommentId;
  final DateTime createdAt;
  final int likeCount;
  final List<String> userLikes;
  final String userName;
  final String? userPhotoUrl;
  final double? rating;
  final List<CommentModel>? replies;

  CommentModel({
    required this.id,
    required this.userId,
    required this.content,
    this.parentCommentId,
    required this.createdAt,
    required this.likeCount,
    required this.userLikes,
    required this.userName,
    this.userPhotoUrl,
    this.rating,
    this.replies,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: FirestoreUtils.safeStringDefault(json['id']),
      userId: FirestoreUtils.safeStringDefault(json['userId']),
      content: FirestoreUtils.safeStringDefault(json['content']),
      parentCommentId: FirestoreUtils.safeString(json['parentCommentId']),
      createdAt: FirestoreUtils.safeDateTime(json['createdAt']),
      likeCount: FirestoreUtils.safeInt(json['likeCount']),
      userLikes: (json['userLikes'] as List<dynamic>?)
              ?.map((e) => FirestoreUtils.safeStringDefault(e))
              .toList() ??
          [],
      userName: FirestoreUtils.safeStringDefault(json['userName'], 'Anonymous'),
      userPhotoUrl: FirestoreUtils.safeString(json['userPhotoUrl']),
      rating: json['rating'] != null
          ? FirestoreUtils.safeDouble(json['rating'])
          : null,
      replies: (json['replies'] as List<dynamic>?)
          ?.map((r) => CommentModel.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'content': content,
    'parentCommentId': parentCommentId,
    'createdAt': Timestamp.fromDate(createdAt),
    'likeCount': likeCount,
    'userLikes': userLikes,
    'userName': userName,
    'userPhotoUrl': userPhotoUrl,
    'rating': rating,
    'replies': replies?.map((r) => r.toJson()).toList(),
  };
}
