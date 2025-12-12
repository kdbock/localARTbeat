import 'package:cloud_firestore/cloud_firestore.dart';
import 'artwork_content_type.dart';

class ArtworkModel {
  final String id;
  final String title;
  final String description;
  final String artistId;
  final String imageUrl;
  final double price;
  final String medium;
  final List<String> tags;
  final DateTime createdAt;
  final bool isSold;
  final String? galleryId;
  final int applauseCount;
  final int viewsCount;
  final String artistName;
  final ArtworkContentType contentType;
  final bool isSerializing;
  final int? totalChapters;
  final int? releasedChapters;
  final Map<String, dynamic>? readingMetadata;
  final Map<String, dynamic>? serializationConfig;

  ArtworkModel({
    required this.id,
    required this.title,
    required this.description,
    required this.artistId,
    required this.imageUrl,
    required this.price,
    required this.medium,
    required this.tags,
    required this.createdAt,
    required this.isSold,
    this.galleryId,
    required this.applauseCount,
    this.viewsCount = 0,
    this.artistName = 'Unknown Artist',
    this.contentType = ArtworkContentType.visual,
    this.isSerializing = false,
    this.totalChapters,
    this.releasedChapters,
    this.readingMetadata,
    this.serializationConfig,
  });

  factory ArtworkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ArtworkModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      artistId: data['artistId'] as String? ?? data['userId'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      medium: data['medium'] as String? ?? '',
      tags: List<String>.from(data['tags'] as List<dynamic>? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSold: data['isSold'] as bool? ?? false,
      galleryId: data['galleryId'] as String?,
      applauseCount: data['applauseCount'] as int? ?? 0,
      viewsCount: data['viewsCount'] as int? ?? data['viewCount'] as int? ?? 0,
      artistName: data['artistName'] as String? ?? 'Unknown Artist',
      contentType: ArtworkContentType.fromString(
        data['contentType'] as String? ?? 'visual',
      ),
      isSerializing: data['isSerializing'] as bool? ?? false,
      totalChapters: data['totalChapters'] as int?,
      releasedChapters: data['releasedChapters'] as int?,
      readingMetadata: data['readingMetadata'] as Map<String, dynamic>?,
      serializationConfig: data['serializationConfig'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'artistId': artistId,
      'imageUrl': imageUrl,
      'price': price,
      'medium': medium,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'isSold': isSold,
      if (galleryId != null) 'galleryId': galleryId,
      'applauseCount': applauseCount,
      'viewsCount': viewsCount,
      'artistName': artistName,
      'contentType': contentType.value,
      'isSerializing': isSerializing,
      if (totalChapters != null) 'totalChapters': totalChapters,
      if (releasedChapters != null) 'releasedChapters': releasedChapters,
      if (readingMetadata != null) 'readingMetadata': readingMetadata,
      if (serializationConfig != null)
        'serializationConfig': serializationConfig,
    };
  }

  // Compatibility getter for dashboard
  int get likesCount => applauseCount;
}
