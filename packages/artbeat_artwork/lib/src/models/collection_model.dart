import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

/// Model representing an artwork collection/portfolio
/// Allows artists to group related artworks and create curated galleries
class CollectionModel {
  final String id;
  final String userId; // Creator of the collection
  final String artistProfileId; // Associated artist profile
  final String title;
  final String description;
  final String? coverImageUrl; // Featured image for the collection
  final List<String> artworkIds; // IDs of artworks in this collection
  final List<String> tags; // Searchable tags
  final CollectionType type; // Type of collection
  final CollectionVisibility visibility; // Privacy setting
  final DateTime createdAt;
  final DateTime updatedAt;
  final int viewCount;
  final bool isFeatured; // Admin featured collection
  final bool isPortfolio; // Is this the artist's main portfolio
  final int sortOrder; // Order for display
  final Map<String, dynamic> metadata; // Additional data

  const CollectionModel({
    required this.id,
    required this.userId,
    required this.artistProfileId,
    required this.title,
    required this.description,
    this.coverImageUrl,
    required this.artworkIds,
    required this.tags,
    required this.type,
    required this.visibility,
    required this.createdAt,
    required this.updatedAt,
    this.viewCount = 0,
    this.isFeatured = false,
    this.isPortfolio = false,
    this.sortOrder = 0,
    this.metadata = const {},
  });

  /// Create from Firestore document
  factory CollectionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return CollectionModel(
      id: doc.id,
      userId: FirestoreUtils.safeStringDefault(data['userId']),
      artistProfileId: FirestoreUtils.safeStringDefault(data['artistProfileId']),
      title: FirestoreUtils.safeStringDefault(data['title']),
      description: FirestoreUtils.safeStringDefault(data['description']),
      coverImageUrl: FirestoreUtils.safeString(data['coverImageUrl']),
      artworkIds: (data['artworkIds'] as List<dynamic>? ?? [])
          .map((e) => FirestoreUtils.safeStringDefault(e))
          .toList(),
      tags: (data['tags'] as List<dynamic>? ?? [])
          .map((e) => FirestoreUtils.safeStringDefault(e))
          .toList(),
      type: CollectionType.values.firstWhere(
        (e) => e.name == FirestoreUtils.safeString(data['type']),
        orElse: () => CollectionType.personal,
      ),
      visibility: CollectionVisibility.values.firstWhere(
        (e) => e.name == FirestoreUtils.safeString(data['visibility']),
        orElse: () => CollectionVisibility.public,
      ),
      createdAt: FirestoreUtils.safeDateTime(data['createdAt']),
      updatedAt: FirestoreUtils.safeDateTime(data['updatedAt']),
      viewCount: FirestoreUtils.safeInt(data['viewCount']),
      isFeatured: FirestoreUtils.safeBool(data['isFeatured'], false),
      isPortfolio: FirestoreUtils.safeBool(data['isPortfolio'], false),
      sortOrder: FirestoreUtils.safeInt(data['sortOrder']),
      metadata: (data['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'artistProfileId': artistProfileId,
      'title': title,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'artworkIds': artworkIds,
      'tags': tags,
      'type': type.name,
      'visibility': visibility.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'viewCount': viewCount,
      'isFeatured': isFeatured,
      'isPortfolio': isPortfolio,
      'sortOrder': sortOrder,
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  CollectionModel copyWith({
    String? id,
    String? userId,
    String? artistProfileId,
    String? title,
    String? description,
    String? coverImageUrl,
    List<String>? artworkIds,
    List<String>? tags,
    CollectionType? type,
    CollectionVisibility? visibility,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewCount,
    bool? isFeatured,
    bool? isPortfolio,
    int? sortOrder,
    Map<String, dynamic>? metadata,
  }) {
    return CollectionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      artistProfileId: artistProfileId ?? this.artistProfileId,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      artworkIds: artworkIds ?? this.artworkIds,
      tags: tags ?? this.tags,
      type: type ?? this.type,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount: viewCount ?? this.viewCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isPortfolio: isPortfolio ?? this.isPortfolio,
      sortOrder: sortOrder ?? this.sortOrder,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CollectionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CollectionModel(id: $id, title: $title, type: $type, artworkCount: ${artworkIds.length})';
  }
}

/// Types of artwork collections
enum CollectionType {
  personal, // Personal artist collection
  portfolio, // Artist's main portfolio
  curated, // Admin/curator curated gallery
  exhibition, // Virtual exhibition
  series, // Artwork series (related theme/style)
  collaborative, // Multiple artists
}

/// Collection visibility settings
enum CollectionVisibility {
  public, // Visible to everyone
  private, // Only visible to creator
  unlisted, // Accessible via direct link only
  subscribers, // Only for artist subscribers
}

/// Extension methods for CollectionType
extension CollectionTypeExtension on CollectionType {
  String get displayName {
    switch (this) {
      case CollectionType.personal:
        return 'Personal Collection';
      case CollectionType.portfolio:
        return 'Portfolio';
      case CollectionType.curated:
        return 'Curated Gallery';
      case CollectionType.exhibition:
        return 'Virtual Exhibition';
      case CollectionType.series:
        return 'Artwork Series';
      case CollectionType.collaborative:
        return 'Collaborative Collection';
    }
  }

  String get description {
    switch (this) {
      case CollectionType.personal:
        return 'Your personal artwork collection';
      case CollectionType.portfolio:
        return 'Showcase your best work';
      case CollectionType.curated:
        return 'Curated by gallery or admin';
      case CollectionType.exhibition:
        return 'Virtual gallery exhibition';
      case CollectionType.series:
        return 'Related artworks in a series';
      case CollectionType.collaborative:
        return 'Multiple artists collaboration';
    }
  }
}

/// Extension methods for CollectionVisibility
extension CollectionVisibilityExtension on CollectionVisibility {
  String get displayName {
    switch (this) {
      case CollectionVisibility.public:
        return 'Public';
      case CollectionVisibility.private:
        return 'Private';
      case CollectionVisibility.unlisted:
        return 'Unlisted';
      case CollectionVisibility.subscribers:
        return 'Subscribers Only';
    }
  }

  String get description {
    switch (this) {
      case CollectionVisibility.public:
        return 'Visible to everyone';
      case CollectionVisibility.private:
        return 'Only visible to you';
      case CollectionVisibility.unlisted:
        return 'Accessible via direct link';
      case CollectionVisibility.subscribers:
        return 'Only for your subscribers';
    }
  }
}
