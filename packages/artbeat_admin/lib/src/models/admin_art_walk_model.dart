import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

class AdminArtWalkModel {
  final String id;
  final String title;
  final String description;
  final String userId;
  final List<String> artworkIds;
  final DateTime createdAt;
  final bool isPublic;
  final int viewCount;
  final String? coverImageUrl;
  final int reportCount;

  const AdminArtWalkModel({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.artworkIds,
    required this.createdAt,
    required this.isPublic,
    required this.viewCount,
    this.coverImageUrl,
    required this.reportCount,
  });

  factory AdminArtWalkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AdminArtWalkModel(
      id: doc.id,
      title: FirestoreUtils.safeStringDefault(data['title']),
      description: FirestoreUtils.safeStringDefault(data['description']),
      userId: FirestoreUtils.safeStringDefault(data['userId']),
      artworkIds: (data['artworkIds'] as List<dynamic>?)
              ?.map((e) => FirestoreUtils.safeStringDefault(e))
              .toList() ??
          const [],
      createdAt: FirestoreUtils.safeDateTime(data['createdAt']),
      isPublic: FirestoreUtils.safeBool(data['isPublic'], false),
      viewCount: FirestoreUtils.safeInt(data['viewCount']),
      coverImageUrl: FirestoreUtils.safeString(data['coverImageUrl']),
      reportCount: FirestoreUtils.safeInt(data['reportCount']),
    );
  }
}
