import 'package:cloud_firestore/cloud_firestore.dart';

enum ChapterModerationStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  underReview('underReview');

  const ChapterModerationStatus(this.value);
  final String value;

  static ChapterModerationStatus fromString(String value) {
    return ChapterModerationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ChapterModerationStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case ChapterModerationStatus.pending:
        return 'Pending Review';
      case ChapterModerationStatus.approved:
        return 'Approved';
      case ChapterModerationStatus.rejected:
        return 'Rejected';
      case ChapterModerationStatus.underReview:
        return 'Under Review';
    }
  }
}

class ChapterModel {
  final String id;
  final String artworkId;
  final int chapterNumber;
  final int? episodeNumber;
  final String title;
  final String description;
  final String content;
  final int estimatedReadingTime;
  final int wordCount;
  final DateTime releaseDate;
  final bool isReleased;
  final bool isPaid;
  final double? price;
  final List<String> panelImages;
  final List<int> panelOrder;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ChapterModerationStatus moderationStatus;
  final List<String>? contentWarnings;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;

  ChapterModel({
    required this.id,
    required this.artworkId,
    required this.chapterNumber,
    this.episodeNumber,
    required this.title,
    required this.description,
    required this.content,
    required this.estimatedReadingTime,
    required this.wordCount,
    required this.releaseDate,
    this.isReleased = false,
    this.isPaid = false,
    this.price,
    List<String> panelImages = const [],
    List<int> panelOrder = const [],
    this.thumbnailUrl,
    required this.createdAt,
    required this.updatedAt,
    this.moderationStatus = ChapterModerationStatus.pending,
    List<String>? contentWarnings,
    List<String>? tags,
    this.metadata,
  }) : panelImages = List.unmodifiable(panelImages),
       panelOrder = List.unmodifiable(panelOrder),
       contentWarnings = contentWarnings != null
           ? List.unmodifiable(contentWarnings)
           : null,
       tags = tags != null ? List.unmodifiable(tags) : null;

  factory ChapterModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChapterModel(
      id: doc.id,
      artworkId: data['artworkId'] as String? ?? '',
      chapterNumber: data['chapterNumber'] as int? ?? 0,
      episodeNumber: data['episodeNumber'] as int?,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      content: data['content'] as String? ?? '',
      estimatedReadingTime: data['estimatedReadingTime'] as int? ?? 0,
      wordCount: data['wordCount'] as int? ?? 0,
      releaseDate:
          (data['releaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isReleased: data['isReleased'] as bool? ?? false,
      isPaid: data['isPaid'] as bool? ?? false,
      price: data['price'] != null ? (data['price'] as num).toDouble() : null,
      panelImages: (data['panelImages'] as List<dynamic>? ?? []).cast<String>(),
      panelOrder: (data['panelOrder'] as List<dynamic>? ?? []).cast<int>(),
      thumbnailUrl: data['thumbnailUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      moderationStatus: ChapterModerationStatus.fromString(
        data['moderationStatus'] as String? ?? 'pending',
      ),
      contentWarnings: data['contentWarnings'] != null
          ? (data['contentWarnings'] as List<dynamic>).cast<String>()
          : null,
      tags: data['tags'] != null
          ? (data['tags'] as List<dynamic>).cast<String>()
          : null,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'artworkId': artworkId,
      'chapterNumber': chapterNumber,
      if (episodeNumber != null) 'episodeNumber': episodeNumber,
      'title': title,
      'description': description,
      'content': content,
      'estimatedReadingTime': estimatedReadingTime,
      'wordCount': wordCount,
      'releaseDate': Timestamp.fromDate(releaseDate),
      'isReleased': isReleased,
      'isPaid': isPaid,
      if (price != null) 'price': price,
      'panelImages': panelImages,
      'panelOrder': panelOrder,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'moderationStatus': moderationStatus.value,
      if (contentWarnings != null) 'contentWarnings': contentWarnings,
      if (tags != null) 'tags': tags,
      if (metadata != null) 'metadata': metadata,
    };
  }

  ChapterModel copyWith({
    String? id,
    String? artworkId,
    int? chapterNumber,
    int? episodeNumber,
    String? title,
    String? description,
    String? content,
    int? estimatedReadingTime,
    int? wordCount,
    DateTime? releaseDate,
    bool? isReleased,
    bool? isPaid,
    double? price,
    List<String>? panelImages,
    List<int>? panelOrder,
    String? thumbnailUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    ChapterModerationStatus? moderationStatus,
    List<String>? contentWarnings,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return ChapterModel(
      id: id ?? this.id,
      artworkId: artworkId ?? this.artworkId,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      estimatedReadingTime: estimatedReadingTime ?? this.estimatedReadingTime,
      wordCount: wordCount ?? this.wordCount,
      releaseDate: releaseDate ?? this.releaseDate,
      isReleased: isReleased ?? this.isReleased,
      isPaid: isPaid ?? this.isPaid,
      price: price ?? this.price,
      panelImages: panelImages ?? this.panelImages,
      panelOrder: panelOrder ?? this.panelOrder,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      contentWarnings: contentWarnings ?? this.contentWarnings,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }
}
