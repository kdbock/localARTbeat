import 'package:cloud_firestore/cloud_firestore.dart';

/// Moderation status for comments
enum CommentModerationStatus {
  pending,
  approved,
  rejected,
  flagged,
  underReview;

  String get displayName {
    switch (this) {
      case CommentModerationStatus.pending:
        return 'Pending Review';
      case CommentModerationStatus.approved:
        return 'Approved';
      case CommentModerationStatus.rejected:
        return 'Rejected';
      case CommentModerationStatus.flagged:
        return 'Flagged';
      case CommentModerationStatus.underReview:
        return 'Under Review';
    }
  }

  String get value {
    switch (this) {
      case CommentModerationStatus.pending:
        return 'pending';
      case CommentModerationStatus.approved:
        return 'approved';
      case CommentModerationStatus.rejected:
        return 'rejected';
      case CommentModerationStatus.flagged:
        return 'flagged';
      case CommentModerationStatus.underReview:
        return 'underReview';
    }
  }

  static CommentModerationStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return CommentModerationStatus.approved;
      case 'rejected':
        return CommentModerationStatus.rejected;
      case 'flagged':
        return CommentModerationStatus.flagged;
      case 'underreview':
        return CommentModerationStatus.underReview;
      case 'pending':
      default:
        return CommentModerationStatus.pending;
    }
  }
}

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final String parentCommentId;
  final String type; // Critique, Appreciation, Question, Tip
  final Timestamp createdAt;
  final String userName;
  final String userAvatarUrl;
  final CommentModerationStatus moderationStatus;
  final bool flagged;
  final DateTime? flaggedAt;
  final String? moderationNotes;

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
    this.moderationStatus = CommentModerationStatus.approved,
    this.flagged = false,
    this.flaggedAt,
    this.moderationNotes,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      postId: (data['postId'] as String?) ?? '',
      userId: (data['userId'] as String?) ?? '',
      content: (data['content'] as String?) ?? '',
      parentCommentId: (data['parentCommentId'] as String?) ?? '',
      type: (data['type'] as String?) ?? 'Appreciation',
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
      userName: (data['userName'] as String?) ?? '',
      userAvatarUrl: (data['userAvatarUrl'] as String?) ?? '',
      moderationStatus: CommentModerationStatus.fromString(
        data['moderationStatus'] as String? ?? 'approved',
      ),
      flagged: (data['flagged'] as bool?) ?? false,
      flaggedAt: (data['flaggedAt'] as Timestamp?)?.toDate(),
      moderationNotes: data['moderationNotes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = {
      'postId': postId,
      'userId': userId,
      'content': content,
      'parentCommentId': parentCommentId,
      'type': type,
      'createdAt': createdAt,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'moderationStatus': moderationStatus.value,
      'flagged': flagged,
      'flaggedAt': flaggedAt != null ? Timestamp.fromDate(flaggedAt!) : null,
      'moderationNotes': moderationNotes,
    };
    // Remove null values to prevent iOS crash in cloud_firestore plugin
    map.removeWhere((key, value) => value == null);
    return map;
  }
}
