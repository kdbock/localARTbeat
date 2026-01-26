import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_utils.dart';
import 'artwork_content_type.dart';

enum ArtBattleStatus { eligible, active, cooling_down, opted_out }

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
  final bool artBattleEnabled;
  final ArtBattleStatus artBattleStatus;
  final int artBattleScore;
  final int artBattleAppearances;
  final int artBattleWins;
  final DateTime? artBattleLastShownAt;
  final DateTime? artBattleLastWinAt;

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
    this.artBattleEnabled = false,
    this.artBattleStatus = ArtBattleStatus.eligible,
    this.artBattleScore = 0,
    this.artBattleAppearances = 0,
    this.artBattleWins = 0,
    this.artBattleLastShownAt,
    this.artBattleLastWinAt,
  });

  factory ArtworkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ArtworkModel(
      id: doc.id,
      title: FirestoreUtils.safeStringDefault(data['title']),
      description: FirestoreUtils.safeStringDefault(data['description']),
      artistId: FirestoreUtils.safeStringDefault(
        data['artistId'] ?? data['userId'],
      ),
      imageUrl: FirestoreUtils.safeStringDefault(data['imageUrl']),
      price: FirestoreUtils.safeDouble(data['price']),
      medium: FirestoreUtils.safeStringDefault(data['medium']),
      tags: (data['tags'] as List<dynamic>? ?? [])
          .map((e) => FirestoreUtils.safeStringDefault(e))
          .toList(),
      createdAt: FirestoreUtils.safeDateTime(data['createdAt']),
      isSold: FirestoreUtils.safeBool(data['isSold'], false),
      galleryId: FirestoreUtils.safeString(data['galleryId']),
      applauseCount: FirestoreUtils.safeInt(data['applauseCount']),
      viewsCount: FirestoreUtils.safeInt(data['viewsCount'] ?? data['viewCount']),
      artistName: FirestoreUtils.safeStringDefault(
        data['artistName'],
        'Unknown Artist',
      ),
      contentType: ArtworkContentType.fromString(
        FirestoreUtils.safeStringDefault(data['contentType'], 'visual'),
      ),
      isSerializing: FirestoreUtils.safeBool(data['isSerializing'], false),
      totalChapters: FirestoreUtils.safeInt(data['totalChapters']),
      releasedChapters: FirestoreUtils.safeInt(data['releasedChapters']),
      readingMetadata: data['readingMetadata'] as Map<String, dynamic>?,
      serializationConfig: data['serializationConfig'] as Map<String, dynamic>?,
      artBattleEnabled: FirestoreUtils.safeBool(data['artBattleEnabled'], false),
      artBattleStatus: ArtBattleStatus.values.firstWhere(
        (e) =>
            e.name ==
            FirestoreUtils.safeStringDefault(data['artBattleStatus'], 'eligible'),
        orElse: () => ArtBattleStatus.eligible,
      ),
      artBattleScore: FirestoreUtils.safeInt(data['artBattleScore']),
      artBattleAppearances: FirestoreUtils.safeInt(data['artBattleAppearances']),
      artBattleWins: FirestoreUtils.safeInt(data['artBattleWins']),
      artBattleLastShownAt: data['artBattleLastShownAt'] != null
          ? FirestoreUtils.safeDateTime(data['artBattleLastShownAt'])
          : null,
      artBattleLastWinAt: data['artBattleLastWinAt'] != null
          ? FirestoreUtils.safeDateTime(data['artBattleLastWinAt'])
          : null,
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
      'artBattleEnabled': artBattleEnabled,
      'artBattleStatus': artBattleStatus.name,
      'artBattleScore': artBattleScore,
      'artBattleAppearances': artBattleAppearances,
      'artBattleWins': artBattleWins,
      if (artBattleLastShownAt != null)
        'artBattleLastShownAt': Timestamp.fromDate(artBattleLastShownAt!),
      if (artBattleLastWinAt != null)
        'artBattleLastWinAt': Timestamp.fromDate(artBattleLastWinAt!),
    };
  }

  // Compatibility getter for dashboard
  int get likesCount => applauseCount;
}
