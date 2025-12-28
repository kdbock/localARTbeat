import 'package:cloud_firestore/cloud_firestore.dart';

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
  final Timestamp createdAt;
  final Timestamp? updatedAt;

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
    final data = doc.data() as Map<String, dynamic>;
    return PublicArtModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      artistName: data['artistName'] as String?,
      location: data['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      address: data['address'] as String?,
      tags: List<String>.from(data['tags'] as List<dynamic>? ?? []),
      artType: data['artType'] as String?,
      isVerified: data['isVerified'] as bool? ?? false,
      viewCount: data['viewCount'] as int? ?? 0,
      likeCount: data['likeCount'] as int? ?? 0,
      usersFavorited: List<String>.from(
        data['usersFavorited'] as List<dynamic>? ?? [],
      ),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  /// Create PublicArtModel from json data
  factory PublicArtModel.fromJson(Map<String, dynamic> json) {
    return PublicArtModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      artistName: json['artistName'] as String?,
      location: json['location'] as GeoPoint,
      address: json['address'] as String?,
      tags: List<String>.from(json['tags'] as List<dynamic>? ?? []),
      artType: json['artType'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      viewCount: json['viewCount'] as int? ?? 0,
      likeCount: json['likeCount'] as int? ?? 0,
      usersFavorited: List<String>.from(
        json['usersFavorited'] as List<dynamic>? ?? [],
      ),
      createdAt: (json['createdAt'] as Timestamp?) ?? Timestamp.now(),
      updatedAt: json['updatedAt'] as Timestamp?,
    );
  }

  /// Create PublicArtModel from CaptureModel
  /// Useful for converting user captures to public art pieces
  factory PublicArtModel.fromCapture(dynamic capture) {
    // Handle both CaptureModel and dynamic types
    return PublicArtModel(
      id: capture.id as String,
      userId: capture.userId as String,
      title: capture.title as String? ?? 'Untitled Artwork',
      description: capture.description as String? ?? '',
      imageUrl: capture.imageUrl as String,
      artistName: capture.artistName as String?,
      location: capture.location as GeoPoint? ?? const GeoPoint(0, 0),
      address: capture.locationName as String?,
      tags: (capture.tags as List<dynamic>?)?.cast<String>() ?? [],
      artType: capture.artType as String?,
      isVerified: false, // Captures are not verified by default
      viewCount: 0,
      likeCount: 0,
      usersFavorited: [],
      createdAt: Timestamp.fromDate(capture.createdAt as DateTime),
      updatedAt: capture.updatedAt != null
          ? Timestamp.fromDate(capture.updatedAt as DateTime)
          : null,
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
      'createdAt': createdAt,
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
    Timestamp? createdAt,
    Timestamp? updatedAt,
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
      'location': location,
      'address': address,
      'tags': tags,
      'artType': artType,
      'isVerified': isVerified,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'usersFavorited': usersFavorited,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
