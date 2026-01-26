import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Model for tracking where a user has been mentioned
class ProfileMentionModel {
  final String id;
  final String userId; // User who was mentioned
  final String mentionedByUserId;
  final String mentionedByUserName;
  final String? mentionedByUserAvatar;
  final String mentionType; // 'post', 'comment', 'caption', 'bio'
  final String contextId; // ID of the post, comment, etc.
  final String? contextTitle;
  final String? contextPreview;
  final String? contextImageUrl;
  final DateTime createdAt;
  final bool isRead;
  final bool isDeleted;

  ProfileMentionModel({
    required this.id,
    required this.userId,
    required this.mentionedByUserId,
    required this.mentionedByUserName,
    this.mentionedByUserAvatar,
    required this.mentionType,
    required this.contextId,
    this.contextTitle,
    this.contextPreview,
    this.contextImageUrl,
    required this.createdAt,
    this.isRead = false,
    this.isDeleted = false,
  });

  factory ProfileMentionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProfileMentionModel(
      id: doc.id,
      userId: FirestoreUtils.getString(data, 'userId'),
      mentionedByUserId: FirestoreUtils.getString(data, 'mentionedByUserId'),
      mentionedByUserName: FirestoreUtils.getString(data, 'mentionedByUserName'),
      mentionedByUserAvatar: FirestoreUtils.getOptionalString(data, 'mentionedByUserAvatar'),
      mentionType: FirestoreUtils.getString(data, 'mentionType'),
      contextId: FirestoreUtils.getString(data, 'contextId'),
      contextTitle: FirestoreUtils.getOptionalString(data, 'contextTitle'),
      contextPreview: FirestoreUtils.getOptionalString(data, 'contextPreview'),
      contextImageUrl: FirestoreUtils.getOptionalString(data, 'contextImageUrl'),
      createdAt: FirestoreUtils.getDateTime(data, 'createdAt'),
      isRead: FirestoreUtils.getBool(data, 'isRead'),
      isDeleted: FirestoreUtils.getBool(data, 'isDeleted'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'mentionedByUserId': mentionedByUserId,
      'mentionedByUserName': mentionedByUserName,
      'mentionedByUserAvatar': mentionedByUserAvatar,
      'mentionType': mentionType,
      'contextId': contextId,
      'contextTitle': contextTitle,
      'contextPreview': contextPreview,
      'contextImageUrl': contextImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'isDeleted': isDeleted,
    };
  }

  ProfileMentionModel copyWith({
    String? mentionedByUserName,
    String? mentionedByUserAvatar,
    String? contextTitle,
    String? contextPreview,
    String? contextImageUrl,
    bool? isRead,
    bool? isDeleted,
  }) {
    return ProfileMentionModel(
      id: id,
      userId: userId,
      mentionedByUserId: mentionedByUserId,
      mentionedByUserName: mentionedByUserName ?? this.mentionedByUserName,
      mentionedByUserAvatar:
          mentionedByUserAvatar ?? this.mentionedByUserAvatar,
      mentionType: mentionType,
      contextId: contextId,
      contextTitle: contextTitle ?? this.contextTitle,
      contextPreview: contextPreview ?? this.contextPreview,
      contextImageUrl: contextImageUrl ?? this.contextImageUrl,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  String get displayText {
    switch (mentionType) {
      case 'post':
        return '$mentionedByUserName mentioned you in a post';
      case 'comment':
        return '$mentionedByUserName mentioned you in a comment';
      case 'caption':
        return '$mentionedByUserName mentioned you in a caption';
      case 'bio':
        return '$mentionedByUserName mentioned you in their bio';
      default:
        return '$mentionedByUserName mentioned you';
    }
  }
}
