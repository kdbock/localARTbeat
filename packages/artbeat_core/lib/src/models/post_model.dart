import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_utils.dart';

class PostModel {
  final String id;
  final String userId;
  final String content;
  final List<String> imageUrls;
  final DateTime createdAt;
  final List<String> tags;
  final int likes;
  final int comments;
  final String? artworkId;
  final String? eventId;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.imageUrls,
    required this.createdAt,
    required this.tags,
    required this.likes,
    required this.comments,
    this.artworkId,
    this.eventId,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PostModel(
      id: doc.id,
      userId: FirestoreUtils.safeStringDefault(data['userId']),
      content: FirestoreUtils.safeStringDefault(data['content']),
      imageUrls: (data['imageUrls'] as List<dynamic>? ?? [])
          .map((e) => FirestoreUtils.safeStringDefault(e))
          .toList(),
      createdAt: FirestoreUtils.safeDateTime(data['createdAt']),
      tags: (data['tags'] as List<dynamic>? ?? [])
          .map((e) => FirestoreUtils.safeStringDefault(e))
          .toList(),
      likes: FirestoreUtils.safeInt(data['likes']),
      comments: FirestoreUtils.safeInt(data['comments']),
      artworkId: FirestoreUtils.safeString(data['artworkId']),
      eventId: FirestoreUtils.safeString(data['eventId']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'content': content,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'tags': tags,
      'likes': likes,
      'comments': comments,
      if (artworkId != null) 'artworkId': artworkId,
      if (eventId != null) 'eventId': eventId,
    };
  }
}
