import 'package:cloud_firestore/cloud_firestore.dart';

/// Content Model for Admin Dashboard
///
/// Represents any type of content in the system (artwork, posts, events, etc.)
/// Used for unified content management in the admin dashboard
class ContentModel {
  final String id;
  final String title;
  final String description;
  final String type; // 'artwork', 'post', 'event', 'ad', etc.
  final String authorId;
  final String authorName;
  final String status; // 'active', 'pending', 'rejected', 'archived'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isFlagged;
  final bool isPublic;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final String? imageUrl;
  final String? thumbnailUrl;
  final int viewCount;
  final int likeCount;
  final int reportCount;

  const ContentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.authorId,
    required this.authorName,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.isFlagged = false,
    this.isPublic = true,
    this.tags = const [],
    this.metadata = const {},
    this.imageUrl,
    this.thumbnailUrl,
    this.viewCount = 0,
    this.likeCount = 0,
    this.reportCount = 0,
  });

  /// Create ContentModel from Firestore document
  factory ContentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ContentModel(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled',
      description: data['description'] as String? ?? '',
      type: data['type'] as String? ?? 'unknown',
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Unknown Author',
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isFlagged: data['isFlagged'] as bool? ?? false,
      isPublic: data['isPublic'] as bool? ?? true,
      tags: List<String>.from(data['tags'] as List? ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
      imageUrl: data['imageUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      viewCount: data['viewCount'] as int? ?? 0,
      likeCount: data['likeCount'] as int? ?? 0,
      reportCount: data['reportCount'] as int? ?? 0,
    );
  }

  /// Create ContentModel from different collection types
  factory ContentModel.fromArtwork(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ContentModel(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled Artwork',
      description: data['description'] as String? ?? '',
      type: 'artwork',
      authorId: data['artistId'] as String? ?? '',
      authorName: data['artistName'] as String? ?? 'Unknown Artist',
      status: () {
        final status = data['status'] as String?;
        if (status != null && status != 'active') return status;
        final moderationStatus = data['moderationStatus'] as String?;
        if (moderationStatus == 'approved') return 'approved';
        if (moderationStatus == 'pending') return 'pending';
        if (moderationStatus == 'rejected') return 'rejected';
        if (moderationStatus == 'flagged') return 'flagged';
        return 'approved'; // default to approved for artworks
      }(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isFlagged: data['flagged'] as bool? ?? false,
      isPublic: data['isPublic'] as bool? ?? true,
      tags: List<String>.from(data['tags'] as List? ?? []),
      metadata: {
        'medium': data['medium'] as String? ?? '',
        'dimensions': data['dimensions'] as String? ?? '',
        'price': data['price'] as double? ?? 0.0,
        'category': data['category'] as String? ?? '',
      },
      imageUrl: data['imageUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      viewCount: data['viewCount'] as int? ?? 0,
      likeCount: data['likeCount'] as int? ?? 0,
      reportCount: data['reportCount'] as int? ?? 0,
    );
  }

  factory ContentModel.fromPost(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ContentModel(
      id: doc.id,
      title: () {
        final title = data['title'] as String?;
        if (title != null && title.isNotEmpty) return title;
        final isArtistPost = data['isArtistPost'] as bool? ?? false;
        final location = data['location'] as String?;
        if (location != null && location.isNotEmpty) {
          final feedType = isArtistPost ? 'Artist Feed' : 'Main Feed';
          return '$feedType - Post from $location';
        }
        final feedType = isArtistPost ? 'Artist Feed Post' : 'Main Feed Post';
        return feedType;
      }(),
      description: data['content'] as String? ?? '',
      type: 'post',
      authorId: data['userId'] as String? ?? '',
      authorName: data['userName'] as String? ?? 'Unknown User',
      status: () {
        final status = data['status'] as String?;
        if (status != null && status != 'active') return status;
        final moderationStatus = data['moderationStatus'] as String?;
        return moderationStatus == 'flagged' ? 'flagged' : 'active';
      }(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isFlagged: data['flagged'] as bool? ?? false,
      isPublic: data['isPublic'] as bool? ?? true,
      tags: List<String>.from(data['tags'] as List? ?? []),
      metadata: {
        'postType': data['postType'] as String? ?? 'text',
        'communityId': data['communityId'] as String? ?? '',
        'imageUrls': data['imageUrls'] as List<dynamic>? ?? [],
        'videoUrl': data['videoUrl'] as String?,
        'isArtistPost': data['isArtistPost'] as bool? ?? false,
      },
      imageUrl: data['imageUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      viewCount: data['viewCount'] as int? ?? 0,
      likeCount: data['likesCount'] as int? ?? 0,
      reportCount: data['reportCount'] as int? ?? 0,
    );
  }

  factory ContentModel.fromEvent(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ContentModel(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled Event',
      description: data['description'] as String? ?? '',
      type: 'event',
      authorId: data['organizerId'] as String? ?? '',
      authorName: data['organizerName'] as String? ?? 'Unknown Organizer',
      status: () {
        final status = data['status'] as String?;
        if (status != null && status != 'active') return status;
        final moderationStatus = data['moderationStatus'] as String?;
        if (moderationStatus == 'approved') return 'approved';
        if (moderationStatus == 'pending') return 'pending';
        if (moderationStatus == 'rejected') return 'rejected';
        if (moderationStatus == 'flagged') return 'flagged';
        return 'pending'; // default to pending for events
      }(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isFlagged: data['isFlagged'] as bool? ?? false,
      isPublic: data['isPublic'] as bool? ?? true,
      tags: List<String>.from(data['tags'] as List? ?? []),
      metadata: {
        'eventDate':
            (data['eventDate'] as Timestamp?)?.toDate().toIso8601String(),
        'location': data['location'] as String? ?? '',
        'ticketPrice': data['ticketPrice'] as double? ?? 0.0,
        'maxAttendees': data['maxAttendees'] as int? ?? 0,
      },
      imageUrl: data['imageUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      viewCount: data['viewCount'] as int? ?? 0,
      likeCount: data['likeCount'] as int? ?? 0,
      reportCount: data['reportCount'] as int? ?? 0,
    );
  }

  factory ContentModel.fromCapture(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ContentModel(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled Capture',
      description: data['description'] as String? ?? '',
      type: 'capture',
      authorId: data['userId'] as String? ?? '',
      authorName: data['userName'] as String? ?? 'Unknown User',
      status: () {
        final status = data['status'] as String?;
        if (status == 'approved') return 'active';
        if (status == 'pending') return 'pending';
        if (status == 'rejected') return 'rejected';
        final moderationStatus = data['moderationStatus'] as String?;
        if (moderationStatus == 'approved') return 'approved';
        if (moderationStatus == 'pending') return 'pending';
        if (moderationStatus == 'rejected') return 'rejected';
        if (moderationStatus == 'flagged') return 'flagged';
        return 'active'; // default to active for legacy captures
      }(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isFlagged: data['isFlagged'] as bool? ?? false,
      isPublic: data['isPublic'] as bool? ?? false,
      tags: List<String>.from(data['tags'] as List? ?? []),
      metadata: {
        'artType': data['artType'] as String?,
        'artMedium': data['artMedium'] as String?,
        'locationName': data['locationName'] as String?,
        'artistId': data['artistId'] as String?,
        'artistName': data['artistName'] as String?,
        'textAnnotations': data['textAnnotations'] as List<dynamic>?,
      },
      imageUrl: data['imageUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      viewCount: data['viewCount'] as int? ?? 0,
      likeCount: data['likeCount'] as int? ?? 0,
      reportCount: data['reportCount'] as int? ?? 0,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'authorId': authorId,
      'authorName': authorName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isFlagged': isFlagged,
      'isPublic': isPublic,
      'tags': tags,
      'metadata': metadata,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'reportCount': reportCount,
    };
  }

  /// Create a copy with updated fields
  ContentModel copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? authorId,
    String? authorName,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFlagged,
    bool? isPublic,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    String? imageUrl,
    String? thumbnailUrl,
    int? viewCount,
    int? likeCount,
    int? reportCount,
  }) {
    return ContentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFlagged: isFlagged ?? this.isFlagged,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      reportCount: reportCount ?? this.reportCount,
    );
  }

  /// Get display-friendly type name
  String get displayType {
    switch (type.toLowerCase()) {
      case 'artwork':
        return 'Artwork';
      case 'post':
        return 'Post';
      case 'event':
        return 'Event';
      case 'capture':
        return 'Capture';
      case 'ad':
        return 'Advertisement';
      case 'commission':
        return 'Commission';
      default:
        return type.toUpperCase();
    }
  }

  /// Get status color for UI
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
        return 'green';
      case 'pending':
        return 'orange';
      case 'rejected':
      case 'banned':
        return 'red';
      case 'archived':
        return 'grey';
      default:
        return 'blue';
    }
  }

  /// Check if content needs attention
  bool get needsAttention {
    return isFlagged ||
        status == 'pending' ||
        reportCount > 0 ||
        (status == 'rejected' &&
            updatedAt != null &&
            DateTime.now().difference(updatedAt!).inDays < 7);
  }

  /// Get priority level for admin review
  String get priorityLevel {
    if (isFlagged || reportCount > 5) return 'high';
    if (reportCount > 0 || status == 'pending') return 'medium';
    return 'low';
  }

  /// Get AdminContentType from type string
  AdminContentType get contentType {
    switch (type) {
      case 'artwork':
        return AdminContentType.artwork;
      case 'post':
        return AdminContentType.post;
      case 'event':
        return AdminContentType.event;
      case 'capture':
        return AdminContentType.capture;
      case 'ad':
        return AdminContentType.ad;
      case 'commission':
        return AdminContentType.commission;
      default:
        return AdminContentType.all;
    }
  }

  /// Get engagement score
  double get engagementScore {
    if (viewCount == 0) return 0.0;
    return (likeCount / viewCount) * 100;
  }

  @override
  String toString() {
    return 'ContentModel(id: $id, title: $title, type: $type, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Content type enumeration for filtering - Admin Dashboard
enum AdminContentType {
  all,
  artwork,
  post,
  event,
  capture,
  ad,
  commission;

  String get displayName {
    switch (this) {
      case AdminContentType.all:
        return 'All Content';
      case AdminContentType.artwork:
        return 'Artwork';
      case AdminContentType.post:
        return 'Posts';
      case AdminContentType.event:
        return 'Events';
      case AdminContentType.capture:
        return 'Captures';
      case AdminContentType.ad:
        return 'Advertisements';
      case AdminContentType.commission:
        return 'Commissions';
    }
  }

  String get value {
    switch (this) {
      case AdminContentType.all:
        return 'all';
      case AdminContentType.artwork:
        return 'artwork';
      case AdminContentType.post:
        return 'post';
      case AdminContentType.event:
        return 'event';
      case AdminContentType.capture:
        return 'capture';
      case AdminContentType.ad:
        return 'ad';
      case AdminContentType.commission:
        return 'commission';
    }
  }
}

/// Content status enumeration - Admin Dashboard
enum AdminContentStatus {
  all,
  active,
  pending,
  rejected,
  archived,
  flagged;

  String get displayName {
    switch (this) {
      case AdminContentStatus.all:
        return 'All Status';
      case AdminContentStatus.active:
        return 'Active';
      case AdminContentStatus.pending:
        return 'Pending Review';
      case AdminContentStatus.rejected:
        return 'Rejected';
      case AdminContentStatus.archived:
        return 'Archived';
      case AdminContentStatus.flagged:
        return 'Flagged';
    }
  }

  String get value {
    switch (this) {
      case AdminContentStatus.all:
        return 'all';
      case AdminContentStatus.active:
        return 'active';
      case AdminContentStatus.pending:
        return 'pending';
      case AdminContentStatus.rejected:
        return 'rejected';
      case AdminContentStatus.archived:
        return 'archived';
      case AdminContentStatus.flagged:
        return 'flagged';
    }
  }
}
