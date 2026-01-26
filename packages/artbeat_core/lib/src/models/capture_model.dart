import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_utils.dart';
import 'engagement_model.dart';

enum CaptureStatus { pending, approved, rejected }

extension CaptureStatusExtension on CaptureStatus {
  String get displayName {
    switch (this) {
      case CaptureStatus.pending:
        return 'Pending Review';
      case CaptureStatus.approved:
        return 'Approved';
      case CaptureStatus.rejected:
        return 'Rejected';
    }
  }

  String get value {
    switch (this) {
      case CaptureStatus.pending:
        return 'pending';
      case CaptureStatus.approved:
        return 'approved';
      case CaptureStatus.rejected:
        return 'rejected';
    }
  }

  static CaptureStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return CaptureStatus.approved;
      case 'rejected':
        return CaptureStatus.rejected;
      case 'pending':
      default:
        return CaptureStatus.pending;
    }
  }
}

class CaptureModel {
  final String id;
  final String userId;
  final String? title;
  final List<String>? textAnnotations;
  final String imageUrl;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final GeoPoint? location;
  final String? locationName;
  final String? description;
  final bool isProcessed;
  final List<String>? tags;
  final String? artistId;
  final String? artistName;
  final bool isPublic;
  final String? artType;
  final String? artMedium;
  final CaptureStatus status;
  final String? moderationNotes;
  final EngagementStats engagementStats;
  final int reportCount;
  final bool isFlagged;

  CaptureModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.createdAt,
    this.title,
    this.textAnnotations,
    this.thumbnailUrl,
    this.updatedAt,
    this.location,
    this.locationName,
    this.description,
    this.isProcessed = false,
    this.tags,
    this.artistId,
    this.artistName,
    this.isPublic = false,
    this.artType,
    this.artMedium,
    this.status = CaptureStatus.approved,
    this.moderationNotes,
    EngagementStats? engagementStats,
    this.reportCount = 0,
    this.isFlagged = false,
  }) : engagementStats =
           engagementStats ?? EngagementStats(lastUpdated: DateTime.now());

  factory CaptureModel.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    final id = FirestoreUtils.safeString(json['id']);
    final userId = FirestoreUtils.safeString(json['userId']);
    final imageUrl = FirestoreUtils.safeString(json['imageUrl']);

    if (id == null || id.isEmpty) {
      throw Exception('Capture ID is required but was null or empty');
    }
    if (userId == null || userId.isEmpty) {
      throw Exception('User ID is required but was null or empty');
    }
    if (imageUrl == null) {
      throw Exception('Image URL is required but was null');
    }

    return CaptureModel(
      id: id,
      userId: userId,
      imageUrl: imageUrl,
      createdAt: FirestoreUtils.safeDateTime(json['createdAt']),
      title: FirestoreUtils.safeString(json['title']),
      textAnnotations: (json['textAnnotations'] as List<dynamic>?)
          ?.map((e) => FirestoreUtils.safeStringDefault(e))
          .toList(),
      thumbnailUrl: FirestoreUtils.safeString(json['thumbnailUrl']),
      updatedAt: json['updatedAt'] != null
          ? FirestoreUtils.safeDateTime(json['updatedAt'])
          : null,
      location: json['location'] as GeoPoint?,
      locationName: FirestoreUtils.safeString(json['locationName']),
      description: FirestoreUtils.safeString(json['description']),
      isProcessed: FirestoreUtils.safeBool(json['isProcessed'], false),
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => FirestoreUtils.safeStringDefault(e))
          .toList(),
      artistId: FirestoreUtils.safeString(json['artistId']),
      artistName: FirestoreUtils.safeString(json['artistName']),
      isPublic: FirestoreUtils.safeBool(json['isPublic'], false),
      artType: FirestoreUtils.safeString(json['artType']),
      artMedium: FirestoreUtils.safeString(json['artMedium']),
      status: CaptureStatusExtension.fromString(
        FirestoreUtils.safeStringDefault(json['status'], 'approved'),
      ),
      moderationNotes: FirestoreUtils.safeString(json['moderationNotes']),
      engagementStats: EngagementStats.fromFirestore(
        json['engagementStats'] as Map<String, dynamic>? ?? json,
      ),
      reportCount: FirestoreUtils.safeInt(json['reportCount']),
      isFlagged: FirestoreUtils.safeBool(json['isFlagged'], false),
    );
  }

  factory CaptureModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('Document data is null for capture ${snapshot.id}');
    }
    return CaptureModel.fromJson({...data, 'id': snapshot.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'textAnnotations': textAnnotations,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'location': location,
      'locationName': locationName,
      'description': description,
      'isProcessed': isProcessed,
      'tags': tags,
      'artistId': artistId,
      'artistName': artistName,
      'isPublic': isPublic,
      'artType': artType,
      'artMedium': artMedium,
      'status': status.value,
      'moderationNotes': moderationNotes,
      'engagementStats': engagementStats.toFirestore(),
      'reportCount': reportCount,
      'isFlagged': isFlagged,
    };
  }

  Map<String, dynamic> toFirestore() => toJson();

  CaptureModel copyWith({
    String? id,
    String? userId,
    String? title,
    List<String>? textAnnotations,
    String? imageUrl,
    String? thumbnailUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    GeoPoint? location,
    String? locationName,
    String? description,
    bool? isProcessed,
    List<String>? tags,
    String? artistId,
    String? artistName,
    bool? isPublic,
    String? artType,
    String? artMedium,
    CaptureStatus? status,
    String? moderationNotes,
    EngagementStats? engagementStats,
    int? reportCount,
    bool? isFlagged,
  }) {
    return CaptureModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      textAnnotations: textAnnotations ?? this.textAnnotations,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      location: location ?? this.location,
      locationName: locationName ?? this.locationName,
      description: description ?? this.description,
      isProcessed: isProcessed ?? this.isProcessed,
      tags: tags ?? this.tags,
      artistId: artistId ?? this.artistId,
      artistName: artistName ?? this.artistName,
      isPublic: isPublic ?? this.isPublic,
      artType: artType ?? this.artType,
      artMedium: artMedium ?? this.artMedium,
      status: status ?? this.status,
      moderationNotes: moderationNotes ?? this.moderationNotes,
      engagementStats: engagementStats ?? this.engagementStats,
      reportCount: reportCount ?? this.reportCount,
      isFlagged: isFlagged ?? this.isFlagged,
    );
  }

  @override
  String toString() {
    return 'CaptureModel(id: $id, userId: $userId, title: $title, imageUrl: $imageUrl)';
  }
}
