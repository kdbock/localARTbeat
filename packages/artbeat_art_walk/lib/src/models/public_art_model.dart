import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

/// Model representing public art (street art, murals, sculptures, etc.)
class PublicArtModel {
  final String id;
  final String userId; // ID of the user who added this art
  final String title;
  final String description;
  final String imageUrl;
  final String? artistName; // Name of the artist if known
  final GeoPoint location; // Lat/lng of the artwork
  final String? address; // Human-readable address if available
  final List<String> tags;
  final String? artType; // Mural, Sculpture, Installation, etc.
  final bool isVerified; // If the art has been verified by moderators
  final int viewCount;
  final int likeCount;
  final List<String> usersFavorited; // UIDs of users who favorited this art
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PublicArtModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.artistName,
    required this.location,
    this.address,
    this.tags = const <String>[],
    this.artType,
    this.isVerified = false,
    this.viewCount = 0,
    this.likeCount = 0,
    this.usersFavorited = const <String>[],
    required this.createdAt,
    this.updatedAt,
  });

  /// Create PublicArtModel from Firestore document
  factory PublicArtModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PublicArtModel(
      id: doc.id,
      userId: FirestoreUtils.safeStringDefault(data['userId']),
      title: FirestoreUtils.safeStringDefault(data['title']),
      description: FirestoreUtils.safeStringDefault(data['description']),
      imageUrl: FirestoreUtils.safeStringDefault(data['imageUrl']),
      artistName: FirestoreUtils.safeString(data['artistName']),
      location: data['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      address: FirestoreUtils.safeString(data['address']),
      tags:
          (data['tags'] as List<dynamic>?)
              ?.map((e) => FirestoreUtils.safeStringDefault(e))
              .toList() ??
          [],
      artType: FirestoreUtils.safeString(data['artType']),
      isVerified: FirestoreUtils.safeBool(data['isVerified'], false),
      viewCount: FirestoreUtils.safeInt(data['viewCount']),
      likeCount: FirestoreUtils.safeInt(data['likeCount']),
      usersFavorited:
          (data['usersFavorited'] as List<dynamic>?)
              ?.map((e) => FirestoreUtils.safeStringDefault(e))
              .toList() ??
          [],
      createdAt: FirestoreUtils.safeDateTime(data['createdAt']),
      updatedAt: data['updatedAt'] != null
          ? FirestoreUtils.safeDateTime(data['updatedAt'])
          : null,
    );
  }

  /// Create PublicArtModel from json data
  factory PublicArtModel.fromJson(Map<String, dynamic> json) {
    return PublicArtModel(
      id: FirestoreUtils.safeStringDefault(json['id']),
      userId: FirestoreUtils.safeStringDefault(json['userId']),
      title: FirestoreUtils.safeStringDefault(json['title']),
      description: FirestoreUtils.safeStringDefault(json['description']),
      imageUrl: FirestoreUtils.safeStringDefault(json['imageUrl']),
      artistName: FirestoreUtils.safeString(json['artistName']),
      location: json['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      address: FirestoreUtils.safeString(json['address']),
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((e) => FirestoreUtils.safeStringDefault(e))
              .toList() ??
          [],
      artType: FirestoreUtils.safeString(json['artType']),
      isVerified: FirestoreUtils.safeBool(json['isVerified'], false),
      viewCount: FirestoreUtils.safeInt(json['viewCount']),
      likeCount: FirestoreUtils.safeInt(json['likeCount']),
      usersFavorited:
          (json['usersFavorited'] as List<dynamic>?)
              ?.map((e) => FirestoreUtils.safeStringDefault(e))
              .toList() ??
          [],
      createdAt: FirestoreUtils.safeDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? FirestoreUtils.safeDateTime(json['updatedAt'])
          : null,
    );
  }

  /// Create PublicArtModel from CaptureModel
  /// Useful for converting user captures to public art pieces
  factory PublicArtModel.fromCapture(dynamic capture) {
    // Handle both CaptureModel and dynamic types
    return PublicArtModel(
      id: FirestoreUtils.safeStringDefault(capture.id),
      userId: FirestoreUtils.safeStringDefault(capture.userId),
      title: FirestoreUtils.safeStringDefault(
        capture.title,
        'Untitled Artwork',
      ),
      description: FirestoreUtils.safeStringDefault(capture.description),
      imageUrl: FirestoreUtils.safeStringDefault(capture.imageUrl),
      artistName: FirestoreUtils.safeString(capture.artistName),
      location: capture.location as GeoPoint? ?? const GeoPoint(0, 0),
      address: FirestoreUtils.safeString(capture.locationName),
      tags:
          (capture.tags as List<dynamic>?)
              ?.map((e) => FirestoreUtils.safeStringDefault(e))
              .toList() ??
          [],
      artType: FirestoreUtils.safeString(capture.artType),
      isVerified: false, // Captures are not verified by default
      viewCount: 0,
      likeCount: 0,
      usersFavorited: [],
      createdAt: capture.createdAt as DateTime? ?? DateTime.now(),
      updatedAt: capture.updatedAt as DateTime?,
    );
  }

  /// Convert PublicArtModel to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'artistName': artistName,
      'location': location,
      'address': address,
      'tags': tags,
      'artType': artType,
      'isVerified': isVerified,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'usersFavorited': usersFavorited,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy of this PublicArtModel with the given fields replaced
  PublicArtModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? imageUrl,
    String? artistName,
    GeoPoint? location,
    String? address,
    List<String>? tags,
    String? artType,
    bool? isVerified,
    int? viewCount,
    int? likeCount,
    List<String>? usersFavorited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PublicArtModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      artistName: artistName ?? this.artistName,
      location: location ?? this.location,
      address: address ?? this.address,
      tags: tags ?? this.tags,
      artType: artType ?? this.artType,
      isVerified: isVerified ?? this.isVerified,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      usersFavorited: usersFavorited ?? this.usersFavorited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'artistName': artistName,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'address': address,
      'tags': tags,
      'artType': artType,
      'isVerified': isVerified,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'usersFavorited': usersFavorited,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
