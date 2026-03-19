import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_utils.dart';

class PublicArtModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String? artistName;
  final GeoPoint location;

  const PublicArtModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.artistName,
    required this.location,
  });

  factory PublicArtModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PublicArtModel(
      id: doc.id,
      title: FirestoreUtils.safeStringDefault(data['title']),
      description: FirestoreUtils.safeStringDefault(data['description']),
      imageUrl: FirestoreUtils.safeStringDefault(data['imageUrl']),
      artistName: FirestoreUtils.safeString(data['artistName']),
      location: data['location'] as GeoPoint? ?? const GeoPoint(0, 0),
    );
  }
}
