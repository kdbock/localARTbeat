import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryInvitationModel {
  final String id;
  final String galleryId;
  final String artistId;
  final String galleryName;
  final String artistName;
  final String message;
  final String status;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final String? galleryImageUrl;
  final String? artistImageUrl;
  final Map<String, dynamic>? terms;

  GalleryInvitationModel({
    required this.id,
    required this.galleryId,
    required this.artistId,
    required this.galleryName,
    required this.artistName,
    required this.message,
    required this.status,
    this.createdAt,
    this.expiresAt,
    this.galleryImageUrl,
    this.artistImageUrl,
    this.terms,
  });

  factory GalleryInvitationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GalleryInvitationModel(
      id: doc.id,
      galleryId: data['galleryId'] != null ? data['galleryId'].toString() : '',
      artistId: data['artistId'] != null ? data['artistId'].toString() : '',
      galleryName: data['galleryName'] != null
          ? data['galleryName'].toString()
          : '',
      artistName: data['artistName'] != null
          ? data['artistName'].toString()
          : '',
      message: data['message'] != null ? data['message'].toString() : '',
      status: data['status'] != null ? data['status'].toString() : '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      expiresAt: data['expiresAt'] is Timestamp
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      galleryImageUrl: data['galleryImageUrl'] != null
          ? data['galleryImageUrl'].toString()
          : null,
      artistImageUrl: data['artistImageUrl'] != null
          ? data['artistImageUrl'].toString()
          : null,
      terms: data['terms'] is Map
          ? Map<String, dynamic>.from(data['terms'] as Map)
          : null,
    );
  }
}
