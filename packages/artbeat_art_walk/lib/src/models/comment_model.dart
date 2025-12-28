import 'package:cloud_firestore/cloud_firestore.dart';

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
    final Timestamp? timestamp = json['createdAt'] as Timestamp?;
    final List<dynamic>? repliesJson = json['replies'] as List<dynamic>?;
    return CommentModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      content: json['content'] as String,
      parentCommentId: json['parentCommentId'] as String?,
      createdAt: (timestamp ?? Timestamp.now()).toDate(),
      likeCount: json['likeCount'] as int? ?? 0,
      userLikes: List<String>.from(json['userLikes'] as List<dynamic>? ?? []),
      userName: json['userName'] as String? ?? 'Anonymous',
      userPhotoUrl: json['userPhotoUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      replies: repliesJson
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
