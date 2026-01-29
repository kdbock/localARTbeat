import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils, EngagementStats, ArtworkContentType;

/// Moderation status for artwork
enum ArtworkModerationStatus {
  pending,
  approved,
  rejected,
  flagged,
  underReview;

  String get displayName {
    switch (this) {
      case ArtworkModerationStatus.pending:
        return 'Pending Review';
      case ArtworkModerationStatus.approved:
        return 'Approved';
      case ArtworkModerationStatus.rejected:
        return 'Rejected';
      case ArtworkModerationStatus.flagged:
        return 'Flagged';
      case ArtworkModerationStatus.underReview:
        return 'Under Review';
    }
  }

  String get value {
    switch (this) {
      case ArtworkModerationStatus.pending:
        return 'pending';
      case ArtworkModerationStatus.approved:
        return 'approved';
      case ArtworkModerationStatus.rejected:
        return 'rejected';
      case ArtworkModerationStatus.flagged:
        return 'flagged';
      case ArtworkModerationStatus.underReview:
        return 'underReview';
    }
  }

  static ArtworkModerationStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return ArtworkModerationStatus.approved;
      case 'rejected':
        return ArtworkModerationStatus.rejected;
      case 'flagged':
        return ArtworkModerationStatus.flagged;
      case 'underreview':
        return ArtworkModerationStatus.underReview;
      case 'pending':
      default:
        return ArtworkModerationStatus.pending;
    }
  }
}

/// Model representing an artwork item in the ARTbeat platform
class ArtworkModel {
  /// Unique identifier for the artwork
  final String id;

  /// ID of the user who created the artwork
  final String userId;

  /// ID of the artist profile associated with this artwork
  final String artistProfileId;

  /// Title of the artwork
  final String title;

  /// Detailed description of the artwork
  final String description;

  /// URL to the artwork's main image in Firebase Storage
  final String imageUrl;

  /// List of additional image URLs for multiple photos
  final List<String> additionalImageUrls;

  /// List of video URLs for the artwork
  final List<String> videoUrls;

  /// List of audio file URLs for the artwork
  final List<String> audioUrls;

  /// Primary art medium used (e.g., "Oil Paint", "Digital", etc.)
  final String medium;

  /// Artwork styles (e.g., "Abstract", "Modern", "Minimalist")
  final List<String> styles;

  /// Physical dimensions of the artwork (e.g., "24x36 inches")
  final String? dimensions;

  /// Materials used in the artwork
  final String? materials;

  /// Location where the artwork is displayed/stored
  final String? location;

  /// Custom tags for searching and categorization
  final List<String>? tags;

  /// Hashtags for social media integration
  final List<String>? hashtags;

  /// Keywords for enhanced search functionality
  final List<String>? keywords;

  /// Price of the artwork in the default currency (USD)
  final double? price;

  /// Whether the artwork is currently for sale
  final bool isForSale;

  /// Whether the artwork has been sold
  final bool isSold;

  /// The year the artwork was created
  final int? yearCreated;

  /// Commission rate for galleries (as a percentage)
  final double? commissionRate;

  /// Whether the artwork is featured in the app
  final bool isFeatured;

  /// Whether the artwork is publicly visible
  final bool isPublic;

  /// External link (e.g., to artist's website or shop)
  final String? externalLink;

  /// Number of times the artwork has been viewed
  final int viewCount;

  /// Universal engagement statistics
  final EngagementStats engagementStats;

  /// Display name of the artist
  final String artistName;

  /// Timestamp when the artwork was created
  final DateTime createdAt;

  /// Timestamp of the last update
  final DateTime updatedAt;

  /// Moderation status of the artwork
  final ArtworkModerationStatus moderationStatus;

  /// Whether the artwork has been flagged for review
  final bool flagged;

  /// Timestamp when the artwork was flagged
  final DateTime? flaggedAt;

  /// Notes from moderators
  final String? moderationNotes;

  /// Content type: visual, written, audio, or comic
  final ArtworkContentType contentType;

  /// Whether this artwork is serialized (has chapters)
  final bool isSerializing;

  /// Total number of chapters/episodes (for serialized works)
  final int? totalChapters;

  /// Number of released chapters/episodes
  final int? releasedChapters;

  /// Reading metadata for written/audio content
  final Map<String, dynamic>? readingMetadata;

  /// Serialization configuration
  final Map<String, dynamic>? serializationConfig;

  /// Whether this artwork is in auction
  final bool auctionEnabled;

  /// End date/time of the auction
  final DateTime? auctionEnd;

  /// Starting price for the auction
  final double? startingPrice;

  /// Reserve price for the auction (hidden from bidders)
  final double? reservePrice;

  /// Current status of the auction
  final String? auctionStatus;

  /// Current highest bid amount
  final double? currentHighestBid;

  /// User ID of the current highest bidder
  final String? currentHighestBidder;

  ArtworkModel({
    required this.id,
    required this.userId,
    required this.artistProfileId,
    required this.title,
    required this.description,
    required this.imageUrl,
    List<String> additionalImageUrls = const [],
    List<String> videoUrls = const [],
    List<String> audioUrls = const [],
    required this.medium,
    required List<String> styles,
    this.dimensions,
    this.materials,
    this.location,
    List<String>? tags,
    List<String>? hashtags,
    List<String>? keywords,
    this.price,
    required this.isForSale,
    this.isSold = false,
    this.yearCreated,
    this.commissionRate,
    this.isFeatured = false,
    this.isPublic = true,
    this.externalLink,
    this.viewCount = 0,
    this.artistName = 'Unknown Artist',
    EngagementStats? engagementStats,
    required this.createdAt,
    required this.updatedAt,
    this.moderationStatus = ArtworkModerationStatus.approved,
    this.flagged = false,
    this.flaggedAt,
    this.moderationNotes,
    this.contentType = ArtworkContentType.visual,
    this.isSerializing = false,
    this.totalChapters,
    this.releasedChapters,
    this.readingMetadata,
    this.serializationConfig,
    this.auctionEnabled = false,
    this.auctionEnd,
    this.startingPrice,
    this.reservePrice,
    this.auctionStatus,
    this.currentHighestBid,
    this.currentHighestBidder,
  }) : // Create defensive copies of all lists to prevent external modification
       additionalImageUrls = List.unmodifiable(additionalImageUrls),
       videoUrls = List.unmodifiable(videoUrls),
       audioUrls = List.unmodifiable(audioUrls),
       styles = List.unmodifiable(styles),
       tags = tags != null ? List.unmodifiable(tags) : null,
       hashtags = hashtags != null ? List.unmodifiable(hashtags) : null,
       keywords = keywords != null ? List.unmodifiable(keywords) : null,
       engagementStats =
           engagementStats ?? EngagementStats(lastUpdated: DateTime.now());

  /// Create ArtworkModel from Firestore document
  factory ArtworkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ArtworkModel(
      id: doc.id,
      // Handle legacy documents that have artistId instead of userId/artistProfileId
      userId: FirestoreUtils.safeStringDefault(data['userId'] ?? data['artistId']),
      artistProfileId:
          FirestoreUtils.safeStringDefault(data['artistProfileId'] ?? data['artistId']),
      title: FirestoreUtils.safeStringDefault(data['title']),
      description: FirestoreUtils.safeStringDefault(data['description']),
      imageUrl: FirestoreUtils.safeStringDefault(data['imageUrl']),
      additionalImageUrls: (data['additionalImageUrls'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      videoUrls: (data['videoUrls'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      audioUrls: (data['audioUrls'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      medium: FirestoreUtils.safeStringDefault(data['medium']),
      styles: (data['styles'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      dimensions: FirestoreUtils.safeString(data['dimensions']),
      materials: FirestoreUtils.safeString(data['materials']),
      location: FirestoreUtils.safeString(data['location']),
      tags: data['tags'] != null
          ? (data['tags'] as List<dynamic>).map((e) => e.toString()).toList()
          : null,
      hashtags: data['hashtags'] != null
          ? (data['hashtags'] as List<dynamic>).map((e) => e.toString()).toList()
          : null,
      keywords: data['keywords'] != null
          ? (data['keywords'] as List<dynamic>).map((e) => e.toString()).toList()
          : null,
      price: FirestoreUtils.safeDouble(data['price']),
      isForSale: FirestoreUtils.safeBool(data['isForSale'], false),
      isSold: FirestoreUtils.safeBool(data['isSold'], false),
      yearCreated: FirestoreUtils.safeInt(data['yearCreated']),
      commissionRate: FirestoreUtils.safeDouble(data['commissionRate']),
      isFeatured: FirestoreUtils.safeBool(data['isFeatured'], false),
      isPublic: FirestoreUtils.safeBool(data['isPublic'], true),
      externalLink: FirestoreUtils.safeString(data['externalLink']),
      viewCount: FirestoreUtils.safeInt(data['viewCount']),
      artistName: FirestoreUtils.safeStringDefault(
        data['artistName'],
        'Unknown Artist',
      ),
      engagementStats: EngagementStats.fromFirestore(
        data['engagementStats'] as Map<String, dynamic>? ?? data,
      ),
      createdAt: FirestoreUtils.safeDateTime(data['createdAt']),
      updatedAt: FirestoreUtils.safeDateTime(data['updatedAt']),
      moderationStatus: ArtworkModerationStatus.fromString(
        FirestoreUtils.safeStringDefault(data['moderationStatus'], 'approved'),
      ),
      flagged: FirestoreUtils.safeBool(data['flagged'], false),
      flaggedAt: data['flaggedAt'] != null
          ? FirestoreUtils.safeDateTime(data['flaggedAt'])
          : null,
      moderationNotes: FirestoreUtils.safeString(data['moderationNotes']),
      contentType: ArtworkContentType.fromString(
        FirestoreUtils.safeStringDefault(data['contentType'], 'visual'),
      ),
      isSerializing: FirestoreUtils.safeBool(data['isSerializing'], false),
      totalChapters: FirestoreUtils.safeInt(data['totalChapters']),
      releasedChapters: FirestoreUtils.safeInt(data['releasedChapters']),
      readingMetadata: data['readingMetadata'] as Map<String, dynamic>?,
      serializationConfig: data['serializationConfig'] as Map<String, dynamic>?,
      auctionEnabled:
          FirestoreUtils.safeBool(data['auctionEnabled'] ?? data['isAuction'], false),
      auctionEnd: data['auctionEnd'] != null
          ? FirestoreUtils.safeDateTime(data['auctionEnd'])
          : null,
      startingPrice: FirestoreUtils.safeDouble(data['startingPrice']),
      reservePrice: FirestoreUtils.safeDouble(data['reservePrice']),
      auctionStatus: FirestoreUtils.safeString(data['auctionStatus']),
      currentHighestBid: FirestoreUtils.safeDouble(data['currentHighestBid']),
      currentHighestBidder: FirestoreUtils.safeString(data['currentHighestBidder']),
    );
  }

  /// Convert ArtworkModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'artistProfileId': artistProfileId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'additionalImageUrls': additionalImageUrls,
      'videoUrls': videoUrls,
      'audioUrls': audioUrls,
      'medium': medium,
      'styles': styles,
      if (dimensions != null) 'dimensions': dimensions,
      if (materials != null) 'materials': materials,
      if (location != null) 'location': location,
      if (tags != null) 'tags': tags,
      if (hashtags != null) 'hashtags': hashtags,
      if (keywords != null) 'keywords': keywords,
      if (price != null) 'price': price,
      'isForSale': isForSale,
      'isSold': isSold,
      if (yearCreated != null) 'yearCreated': yearCreated,
      if (commissionRate != null) 'commissionRate': commissionRate,
      'isFeatured': isFeatured,
      'isPublic': isPublic,
      if (externalLink != null) 'externalLink': externalLink,
      'viewCount': viewCount,
      'artistName': artistName,
      'engagementStats': engagementStats.toFirestore(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'moderationStatus': moderationStatus.value,
      'flagged': flagged,
      if (flaggedAt != null) 'flaggedAt': Timestamp.fromDate(flaggedAt!),
      if (moderationNotes != null) 'moderationNotes': moderationNotes,
      'contentType': contentType.value,
      'isSerializing': isSerializing,
      if (totalChapters != null) 'totalChapters': totalChapters,
      if (releasedChapters != null) 'releasedChapters': releasedChapters,
      if (readingMetadata != null) 'readingMetadata': readingMetadata,
      if (serializationConfig != null)
        'serializationConfig': serializationConfig,
      'auctionEnabled': auctionEnabled,
      if (auctionEnd != null) 'auctionEnd': Timestamp.fromDate(auctionEnd!),
      if (startingPrice != null) 'startingPrice': startingPrice,
      if (reservePrice != null) 'reservePrice': reservePrice,
      if (auctionStatus != null) 'auctionStatus': auctionStatus,
      if (currentHighestBid != null) 'currentHighestBid': currentHighestBid,
      if (currentHighestBidder != null)
        'currentHighestBidder': currentHighestBidder,
    };
  }

  /// Getters for compatibility and convenience
  int get likeCount => engagementStats.likeCount;
  int get commentCount => engagementStats.commentCount;
  int get likesCount => engagementStats.likeCount;

  /// Create a copy of this ArtworkModel with updated fields
  ArtworkModel copyWith({
    String? title,
    String? description,
    String? imageUrl,
    List<String>? additionalImageUrls,
    List<String>? videoUrls,
    List<String>? audioUrls,
    String? medium,
    List<String>? styles,
    String? dimensions,
    String? materials,
    String? location,
    List<String>? tags,
    List<String>? hashtags,
    List<String>? keywords,
    double? price,
    bool? isForSale,
    bool? isSold,
    int? yearCreated,
    double? commissionRate,
    bool? isFeatured,
    bool? isPublic,
    String? externalLink,
    int? viewCount,
    String? artistName,
    EngagementStats? engagementStats,
    DateTime? updatedAt,
    ArtworkModerationStatus? moderationStatus,
    bool? flagged,
    DateTime? flaggedAt,
    String? moderationNotes,
    ArtworkContentType? contentType,
    bool? isSerializing,
    int? totalChapters,
    int? releasedChapters,
    Map<String, dynamic>? readingMetadata,
    Map<String, dynamic>? serializationConfig,
    bool? auctionEnabled,
    DateTime? auctionEnd,
    double? startingPrice,
    double? reservePrice,
    String? auctionStatus,
    double? currentHighestBid,
    String? currentHighestBidder,
  }) {
    return ArtworkModel(
      id: id,
      userId: userId,
      artistProfileId: artistProfileId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      additionalImageUrls: additionalImageUrls ?? this.additionalImageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      audioUrls: audioUrls ?? this.audioUrls,
      medium: medium ?? this.medium,
      styles: styles ?? this.styles,
      dimensions: dimensions ?? this.dimensions,
      materials: materials ?? this.materials,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      hashtags: hashtags ?? this.hashtags,
      keywords: keywords ?? this.keywords,
      price: price ?? this.price,
      isForSale: isForSale ?? this.isForSale,
      isSold: isSold ?? this.isSold,
      yearCreated: yearCreated ?? this.yearCreated,
      commissionRate: commissionRate ?? this.commissionRate,
      isFeatured: isFeatured ?? this.isFeatured,
      isPublic: isPublic ?? this.isPublic,
      externalLink: externalLink ?? this.externalLink,
      viewCount: viewCount ?? this.viewCount,
      artistName: artistName ?? this.artistName,
      engagementStats: engagementStats ?? this.engagementStats,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      flagged: flagged ?? this.flagged,
      flaggedAt: flaggedAt ?? this.flaggedAt,
      moderationNotes: moderationNotes ?? this.moderationNotes,
      contentType: contentType ?? this.contentType,
      isSerializing: isSerializing ?? this.isSerializing,
      totalChapters: totalChapters ?? this.totalChapters,
      releasedChapters: releasedChapters ?? this.releasedChapters,
      readingMetadata: readingMetadata ?? this.readingMetadata,
      serializationConfig: serializationConfig ?? this.serializationConfig,
      auctionEnabled: auctionEnabled ?? this.auctionEnabled,
      auctionEnd: auctionEnd ?? this.auctionEnd,
      startingPrice: startingPrice ?? this.startingPrice,
      reservePrice: reservePrice ?? this.reservePrice,
      auctionStatus: auctionStatus ?? this.auctionStatus,
      currentHighestBid: currentHighestBid ?? this.currentHighestBid,
      currentHighestBidder: currentHighestBidder ?? this.currentHighestBidder,
    );
  }
}
