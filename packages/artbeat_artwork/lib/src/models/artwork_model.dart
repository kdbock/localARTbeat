import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

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

/// Status for Art Battle participation
enum ArtBattleStatus {
  eligible,
  active,
  coolingDown,
  optedOut,
  removed,
  frozen;

  String get value {
    switch (this) {
      case ArtBattleStatus.eligible:
        return 'eligible';
      case ArtBattleStatus.active:
        return 'active';
      case ArtBattleStatus.coolingDown:
        return 'cooling_down';
      case ArtBattleStatus.optedOut:
        return 'opted_out';
      case ArtBattleStatus.removed:
        return 'removed';
      case ArtBattleStatus.frozen:
        return 'frozen';
    }
  }

  static ArtBattleStatus fromString(String status) {
    switch (status) {
      case 'eligible':
        return ArtBattleStatus.eligible;
      case 'active':
        return ArtBattleStatus.active;
      case 'cooling_down':
        return ArtBattleStatus.coolingDown;
      case 'opted_out':
        return ArtBattleStatus.optedOut;
      case 'removed':
        return ArtBattleStatus.removed;
      case 'frozen':
        return ArtBattleStatus.frozen;
      default:
        return ArtBattleStatus.eligible;
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

  /// Whether this artwork is enabled for Art Battles
  final bool artBattleEnabled;

  /// Current status in Art Battle system
  final ArtBattleStatus artBattleStatus;

  /// Score in Art Battle system (wins - losses)
  final int artBattleScore;

  /// Number of appearances in Art Battles
  final int artBattleAppearances;

  /// Number of wins in Art Battles
  final int artBattleWins;

  /// Last time this artwork was shown in a battle
  final DateTime? artBattleLastShownAt;

  /// Last time this artwork won a battle
  final DateTime? artBattleLastWinAt;

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
    this.artBattleEnabled = false,
    this.artBattleStatus = ArtBattleStatus.eligible,
    this.artBattleScore = 0,
    this.artBattleAppearances = 0,
    this.artBattleWins = 0,
    this.artBattleLastShownAt,
    this.artBattleLastWinAt,
  })  :
        // Create defensive copies of all lists to prevent external modification
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
      userId: data['userId'] as String? ?? data['artistId'] as String? ?? '',
      artistProfileId: data['artistProfileId'] as String? ??
          data['artistId'] as String? ??
          '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      additionalImageUrls:
          (data['additionalImageUrls'] as List<dynamic>? ?? []).cast<String>(),
      videoUrls: (data['videoUrls'] as List<dynamic>? ?? []).cast<String>(),
      audioUrls: (data['audioUrls'] as List<dynamic>? ?? []).cast<String>(),
      medium: data['medium'] as String? ?? '',
      styles: (data['styles'] as List<dynamic>? ?? []).cast<String>(),
      dimensions: data['dimensions'] as String?,
      materials: data['materials'] as String?,
      location: data['location'] as String?,
      tags: data['tags'] != null
          ? (data['tags'] as List<dynamic>).cast<String>()
          : null,
      hashtags: data['hashtags'] != null
          ? (data['hashtags'] as List<dynamic>).cast<String>()
          : null,
      keywords: data['keywords'] != null
          ? (data['keywords'] as List<dynamic>).cast<String>()
          : null,
      price: data['price'] != null ? (data['price'] as num).toDouble() : null,
      isForSale: data['isForSale'] as bool? ?? false,
      isSold: data['isSold'] as bool? ?? false,
      yearCreated: data['yearCreated'] as int?,
      commissionRate: data['commissionRate'] != null
          ? (data['commissionRate'] as num).toDouble()
          : null,
      isFeatured: data['isFeatured'] as bool? ?? false,
      isPublic: data['isPublic'] as bool? ?? true,
      externalLink: data['externalLink'] as String?,
      viewCount: data['viewCount'] as int? ?? 0,
      engagementStats: EngagementStats.fromFirestore(
        data['engagementStats'] as Map<String, dynamic>? ?? data,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      moderationStatus: ArtworkModerationStatus.fromString(
        data['moderationStatus'] as String? ?? 'approved',
      ),
      flagged: (data['flagged'] as bool?) ?? false,
      flaggedAt: (data['flaggedAt'] as Timestamp?)?.toDate(),
      moderationNotes: data['moderationNotes'] as String?,
      contentType: ArtworkContentType.fromString(
          data['contentType'] as String? ?? 'visual'),
      isSerializing: data['isSerializing'] as bool? ?? false,
      totalChapters: data['totalChapters'] as int?,
      releasedChapters: data['releasedChapters'] as int?,
      readingMetadata: data['readingMetadata'] as Map<String, dynamic>?,
      serializationConfig: data['serializationConfig'] as Map<String, dynamic>?,
      auctionEnabled: data['auctionEnabled'] as bool? ?? data['isAuction'] as bool? ?? false,
      auctionEnd: (data['auctionEnd'] as Timestamp?)?.toDate(),
      startingPrice: data['startingPrice'] != null
          ? (data['startingPrice'] as num).toDouble()
          : null,
      reservePrice: data['reservePrice'] != null
          ? (data['reservePrice'] as num).toDouble()
          : null,
      auctionStatus: data['auctionStatus'] as String?,
      currentHighestBid: data['currentHighestBid'] != null
          ? (data['currentHighestBid'] as num).toDouble()
          : null,
      currentHighestBidder: data['currentHighestBidder'] as String?,
      artBattleEnabled: data['artBattleEnabled'] as bool? ?? false,
      artBattleStatus: ArtBattleStatus.fromString(
        data['artBattleStatus'] as String? ?? 'eligible',
      ),
      artBattleScore: data['artBattleScore'] as int? ?? 0,
      artBattleAppearances: data['artBattleAppearances'] as int? ?? 0,
      artBattleWins: data['artBattleWins'] as int? ?? 0,
      artBattleLastShownAt:
          (data['artBattleLastShownAt'] as Timestamp?)?.toDate(),
      artBattleLastWinAt: (data['artBattleLastWinAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert ArtworkModel to Firestore data
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
      'dimensions': dimensions,
      'materials': materials,
      'location': location,
      'tags': tags,
      'hashtags': hashtags,
      'keywords': keywords,
      'price': price,
      'isForSale': isForSale,
      'isSold': isSold,
      'yearCreated': yearCreated,
      'commissionRate': commissionRate,
      'isFeatured': isFeatured,
      'isPublic': isPublic,
      'externalLink': externalLink,
      'viewCount': viewCount,
      'engagementStats': engagementStats.toFirestore(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'moderationStatus': moderationStatus.value,
      'flagged': flagged,
      'flaggedAt': flaggedAt != null ? Timestamp.fromDate(flaggedAt!) : null,
      'moderationNotes': moderationNotes,
      'contentType': contentType.value,
      'isSerializing': isSerializing,
      if (totalChapters != null) 'totalChapters': totalChapters,
      if (releasedChapters != null) 'releasedChapters': releasedChapters,
      if (readingMetadata != null) 'readingMetadata': readingMetadata,
      if (serializationConfig != null)
        'serializationConfig': serializationConfig,
      'auctionEnabled': auctionEnabled,
      'isAuction': auctionEnabled,
      if (auctionEnd != null) 'auctionEnd': Timestamp.fromDate(auctionEnd!),
      if (startingPrice != null) 'startingPrice': startingPrice,
      if (reservePrice != null) 'reservePrice': reservePrice,
      if (auctionStatus != null) 'auctionStatus': auctionStatus,
      if (currentHighestBid != null) 'currentHighestBid': currentHighestBid,
      if (currentHighestBidder != null)
        'currentHighestBidder': currentHighestBidder,
      'artBattleEnabled': artBattleEnabled,
      'artBattleStatus': artBattleStatus.value,
      'artBattleScore': artBattleScore,
      'artBattleAppearances': artBattleAppearances,
      'artBattleWins': artBattleWins,
      if (artBattleLastShownAt != null)
        'artBattleLastShownAt': Timestamp.fromDate(artBattleLastShownAt!),
      if (artBattleLastWinAt != null)
        'artBattleLastWinAt': Timestamp.fromDate(artBattleLastWinAt!),
    };
  }

  /// Create a copy of the artwork model with updated fields
  ArtworkModel copyWith({
    String? id,
    String? userId,
    String? artistProfileId,
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
    EngagementStats? engagementStats,
    DateTime? createdAt,
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
      id: id ?? this.id,
      userId: userId ?? this.userId,
      artistProfileId: artistProfileId ?? this.artistProfileId,
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
      engagementStats: engagementStats ?? this.engagementStats,
      createdAt: createdAt ?? this.createdAt,
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

  // Backward compatibility getters for migration period
  int get likeCount => engagementStats.likeCount;
  int get commentCount => engagementStats.commentCount;
  int get applauseCount => engagementStats.likeCount;

  // Dashboard compatibility getters
  int get likesCount => engagementStats.likeCount;
  int get viewsCount => viewCount;

  // Artist name getter - this would need to be populated from artist profile data
  // For now, return a placeholder that can be overridden when artist data is available
  String get artistName => 'Unknown Artist';
}
