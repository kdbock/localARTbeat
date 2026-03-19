import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

enum AdminArtworkModerationStatus {
  pending,
  approved,
  rejected,
  flagged,
  underReview;

  String get displayName {
    switch (this) {
      case AdminArtworkModerationStatus.pending:
        return 'Pending Review';
      case AdminArtworkModerationStatus.approved:
        return 'Approved';
      case AdminArtworkModerationStatus.rejected:
        return 'Rejected';
      case AdminArtworkModerationStatus.flagged:
        return 'Flagged';
      case AdminArtworkModerationStatus.underReview:
        return 'Under Review';
    }
  }

  String get value {
    switch (this) {
      case AdminArtworkModerationStatus.pending:
        return 'pending';
      case AdminArtworkModerationStatus.approved:
        return 'approved';
      case AdminArtworkModerationStatus.rejected:
        return 'rejected';
      case AdminArtworkModerationStatus.flagged:
        return 'flagged';
      case AdminArtworkModerationStatus.underReview:
        return 'underReview';
    }
  }

  static AdminArtworkModerationStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AdminArtworkModerationStatus.approved;
      case 'rejected':
        return AdminArtworkModerationStatus.rejected;
      case 'flagged':
        return AdminArtworkModerationStatus.flagged;
      case 'underreview':
        return AdminArtworkModerationStatus.underReview;
      case 'pending':
      default:
        return AdminArtworkModerationStatus.pending;
    }
  }
}

class AdminArtworkModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String artistName;
  final DateTime createdAt;
  final AdminArtworkModerationStatus moderationStatus;
  final bool flagged;
  final bool isFeatured;
  final bool isPublic;

  const AdminArtworkModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.artistName,
    required this.createdAt,
    required this.moderationStatus,
    required this.flagged,
    required this.isFeatured,
    required this.isPublic,
  });

  factory AdminArtworkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AdminArtworkModel(
      id: doc.id,
      title: FirestoreUtils.safeStringDefault(data['title']),
      description: FirestoreUtils.safeStringDefault(data['description']),
      imageUrl: FirestoreUtils.safeStringDefault(
        data['imageUrl'] ?? data['coverImage'],
      ),
      artistName: FirestoreUtils.safeStringDefault(
        data['artistName'],
        'Unknown Artist',
      ),
      createdAt: FirestoreUtils.safeDateTime(data['createdAt']),
      moderationStatus: AdminArtworkModerationStatus.fromString(
        FirestoreUtils.safeStringDefault(data['moderationStatus'], 'approved'),
      ),
      flagged: FirestoreUtils.safeBool(data['flagged'], false),
      isFeatured: FirestoreUtils.safeBool(data['isFeatured'], false),
      isPublic: FirestoreUtils.safeBool(data['isPublic'], true),
    );
  }
}
