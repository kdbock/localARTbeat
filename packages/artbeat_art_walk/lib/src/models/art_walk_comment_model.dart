import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Model class for comments on art walks
class ArtWalkCommentModel {
  final String id;
  final String artWalkId;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String content;
  final DateTime createdAt;
  final EngagementStats engagementStats;
  final String? parentCommentId; // For threaded comments
  final bool isEdited;
  final double? rating; // Optional rating (1-5 stars)
  final List<String>? mentionedUsers;

  /// Constructor
  ArtWalkCommentModel({
    required this.id,
    required this.artWalkId,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.content,
    required this.createdAt,
    required this.engagementStats,
    this.parentCommentId,
    this.isEdited = false,
    this.rating,
    this.mentionedUsers,
  });

  /// Create an ArtWalkCommentModel from Firestore document
  factory ArtWalkCommentModel.fromFirestore(
    DocumentSnapshot doc, {
    String? artWalkId,
  }) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ArtWalkCommentModel(
      id: doc.id,
      artWalkId: artWalkId ?? FirestoreUtils.safeStringDefault(data['artWalkId']),
      userId: FirestoreUtils.safeStringDefault(data['userId']),
      userName: FirestoreUtils.safeStringDefault(data['userName']),
      userPhotoUrl: FirestoreUtils.safeStringDefault(data['userPhotoUrl']),
      content: FirestoreUtils.safeStringDefault(data['content']),
      createdAt: FirestoreUtils.safeDateTime(data['createdAt']),
      engagementStats: EngagementStats.fromMap(
        data['engagementStats'] as Map<String, dynamic>? ?? {},
      ),
      parentCommentId: FirestoreUtils.safeString(data['parentCommentId']),
      isEdited: FirestoreUtils.safeBool(data['isEdited'], false),
      rating: data['rating'] != null
          ? FirestoreUtils.safeDouble(data['rating'])
          : null,
      mentionedUsers: (data['mentionedUsers'] as List<dynamic>?)
          ?.map((e) => FirestoreUtils.safeStringDefault(e))
          .toList(),
    );
  }

  /// Convert to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'artWalkId': artWalkId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'engagementStats': engagementStats.toMap(),
      'parentCommentId': parentCommentId,
      'isEdited': isEdited,
      'rating': rating,
      'mentionedUsers': mentionedUsers,
    };
  }

  /// Create a copy of this comment with modified fields
  ArtWalkCommentModel copyWith({
    String? id,
    String? artWalkId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? content,
    DateTime? createdAt,
    EngagementStats? engagementStats,
    String? parentCommentId,
    bool? isEdited,
    double? rating,
    List<String>? mentionedUsers,
    bool clearMentionedUsers = false,
  }) {
    return ArtWalkCommentModel(
      id: id ?? this.id,
      artWalkId: artWalkId ?? this.artWalkId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      engagementStats: engagementStats ?? this.engagementStats,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      isEdited: isEdited ?? this.isEdited,
      rating: rating ?? this.rating,
      mentionedUsers: clearMentionedUsers
          ? null
          : (mentionedUsers ?? this.mentionedUsers),
    );
  }
}
