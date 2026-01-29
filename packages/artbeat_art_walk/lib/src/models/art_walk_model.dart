import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

/// Model representing an Art Walk
class ArtWalkModel {
  final String id;
  final String title;
  final String description;
  final String userId;
  final List<String> artworkIds;
  final DateTime createdAt;
  final bool isPublic;
  final int viewCount;
  final List<String> imageUrls; // Added for map preview and list view
  final String? zipCode; // Added for NC Region filtering
  final double? estimatedDuration; // Duration in minutes
  final double? estimatedDistance; // Distance in miles
  final String? coverImageUrl; // Cover image URL
  final String? routeData; // Encoded route data for map display
  final List<String>? tags; // Tags for categorization
  final String? difficulty; // Difficulty level (Easy, Medium, Hard)
  final bool? isAccessible; // Accessibility information
  final GeoPoint? startLocation; // Starting location for the art walk
  final int?
  completionCount; // Number of times this art walk has been completed
  final int reportCount; // Number of reports/flags on this art walk
  final bool isFlagged; // Whether this art walk has been flagged for review

  ArtWalkModel({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.artworkIds,
    required this.createdAt,
    this.isPublic = false,
    this.viewCount = 0,
    this.imageUrls = const [],
    this.zipCode, // Added
    this.estimatedDuration,
    this.estimatedDistance,
    this.coverImageUrl,
    this.routeData,
    this.tags,
    this.difficulty,
    this.isAccessible,
    this.startLocation,
    this.completionCount,
    this.reportCount = 0,
    this.isFlagged = false,
  });

  factory ArtWalkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ArtWalkModel(
      id: doc.id,
      title: FirestoreUtils.safeStringDefault(data['title']),
      description: FirestoreUtils.safeStringDefault(data['description']),
      userId: FirestoreUtils.safeStringDefault(data['userId']),
      artworkIds:
          (data['artworkIds'] as List<dynamic>?)
              ?.map((e) => FirestoreUtils.safeStringDefault(e))
              .toList() ??
          [],
      createdAt: FirestoreUtils.safeDateTime(data['createdAt']),
      isPublic: FirestoreUtils.safeBool(data['isPublic'], false),
      viewCount: FirestoreUtils.safeInt(data['viewCount']),
      imageUrls:
          (data['imageUrls'] as List<dynamic>?)
              ?.map((e) => FirestoreUtils.safeStringDefault(e))
              .toList() ??
          [],
      zipCode: FirestoreUtils.safeString(data['zipCode']),
      estimatedDuration: data['estimatedDuration'] != null
          ? FirestoreUtils.safeDouble(data['estimatedDuration'])
          : null,
      estimatedDistance: data['estimatedDistance'] != null
          ? FirestoreUtils.safeDouble(data['estimatedDistance'])
          : null,
      coverImageUrl: FirestoreUtils.safeString(data['coverImageUrl']),
      routeData: FirestoreUtils.safeString(data['routeData']),
      tags: (data['tags'] as List<dynamic>?)
          ?.map((e) => FirestoreUtils.safeStringDefault(e))
          .toList(),
      difficulty: FirestoreUtils.safeString(data['difficulty']),
      isAccessible: data['isAccessible'] != null
          ? FirestoreUtils.safeBool(data['isAccessible'])
          : null,
      startLocation: data['startLocation'] as GeoPoint?,
      completionCount: data['completionCount'] != null
          ? FirestoreUtils.safeInt(data['completionCount'])
          : null,
      reportCount: FirestoreUtils.safeInt(data['reportCount']),
      isFlagged: FirestoreUtils.safeBool(data['isFlagged'], false),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'userId': userId,
      'artworkIds': artworkIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPublic': isPublic,
      'viewCount': viewCount,
      'imageUrls': imageUrls,
      'zipCode': zipCode,
      'estimatedDuration': estimatedDuration,
      'estimatedDistance': estimatedDistance,
      'coverImageUrl': coverImageUrl,
      'routeData': routeData,
      'tags': tags,
      'difficulty': difficulty,
      'isAccessible': isAccessible,
      'startLocation': startLocation,
      'completionCount': completionCount,
      'reportCount': reportCount,
      'isFlagged': isFlagged,
    };
  }

  ArtWalkModel copyWith({
    String? id,
    String? title,
    String? description,
    String? userId,
    List<String>? artworkIds,
    DateTime? createdAt,
    bool? isPublic,
    int? viewCount,
    List<String>? imageUrls,
    String? zipCode,
    double? estimatedDuration,
    double? estimatedDistance,
    String? coverImageUrl,
    String? routeData,
    List<String>? tags,
    String? difficulty,
    bool? isAccessible,
    GeoPoint? startLocation,
    int? completionCount,
    int? reportCount,
    bool? isFlagged,
  }) {
    return ArtWalkModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      artworkIds: artworkIds ?? this.artworkIds,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      viewCount: viewCount ?? this.viewCount,
      imageUrls: imageUrls ?? this.imageUrls,
      zipCode: zipCode ?? this.zipCode,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      routeData: routeData ?? this.routeData,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      isAccessible: isAccessible ?? this.isAccessible,
      startLocation: startLocation ?? this.startLocation,
      completionCount: completionCount ?? this.completionCount,
      reportCount: reportCount ?? this.reportCount,
      isFlagged: isFlagged ?? this.isFlagged,
    );
  }

  List<String> get artPieces => artworkIds;
}
