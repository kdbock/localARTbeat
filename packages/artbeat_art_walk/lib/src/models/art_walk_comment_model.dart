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
    final data = doc.data() as Map<String, dynamic>;

    // Handle server timestamps that might be null for new comments
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return ArtWalkCommentModel(
      id: doc.id,
      artWalkId: artWalkId ?? data['artWalkId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userPhotoUrl: data['userPhotoUrl'] as String? ?? '',
      content: data['content'] as String? ?? '',
      createdAt: createdAt,
      engagementStats: EngagementStats.fromMap(
        data['engagementStats'] as Map<String, dynamic>? ?? {},
      ),
      parentCommentId: data['parentCommentId'] as String?,
      isEdited: data['isEdited'] as bool? ?? false,
      rating: (data['rating'] as num?)?.toDouble(),
      mentionedUsers: data['mentionedUsers'] != null
          ? List<String>.from(data['mentionedUsers'] as List<dynamic>)
          : null,
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
