import 'package:cloud_firestore/cloud_firestore.dart';

class Bookmark {
  final String chapterId;
  final double scrollPosition;
  final DateTime savedAt;
  final String? note;

  Bookmark({
    required this.chapterId,
    required this.scrollPosition,
    required this.savedAt,
    this.note,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      chapterId: json['chapterId'] as String? ?? '',
      scrollPosition: (json['scrollPosition'] as num?)?.toDouble() ?? 0.0,
      savedAt: json['savedAt'] != null
          ? (json['savedAt'] as Timestamp).toDate()
          : DateTime.now(),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapterId': chapterId,
      'scrollPosition': scrollPosition,
      'savedAt': Timestamp.fromDate(savedAt),
      if (note != null) 'note': note,
    };
  }
}

class ReadingAnalyticsModel {
  final String id;
  final String userId;
  final String artworkId;
  final String? chapterId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int timeSpentSeconds;
  final double lastScrollPosition;
  final double completionPercentage;
  final bool isCompleted;
  final List<Bookmark> bookmarks;
  final String device;
  final String? appVersion;
  final Map<String, dynamic>? metadata;

  ReadingAnalyticsModel({
    required this.id,
    required this.userId,
    required this.artworkId,
    this.chapterId,
    required this.startedAt,
    this.completedAt,
    required this.timeSpentSeconds,
    required this.lastScrollPosition,
    required this.completionPercentage,
    this.isCompleted = false,
    List<Bookmark> bookmarks = const [],
    this.device = 'unknown',
    this.appVersion,
    this.metadata,
  }) : bookmarks = List.unmodifiable(bookmarks);

  factory ReadingAnalyticsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final bookmarksList = (data['bookmarks'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map((b) => Bookmark.fromJson(b))
        .toList();

    return ReadingAnalyticsModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      artworkId: data['artworkId'] as String? ?? '',
      chapterId: data['chapterId'] as String?,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      timeSpentSeconds: data['timeSpentSeconds'] as int? ?? 0,
      lastScrollPosition:
          (data['lastScrollPosition'] as num?)?.toDouble() ?? 0.0,
      completionPercentage:
          (data['completionPercentage'] as num?)?.toDouble() ?? 0.0,
      isCompleted: data['isCompleted'] as bool? ?? false,
      bookmarks: bookmarksList,
      device: data['device'] as String? ?? 'unknown',
      appVersion: data['appVersion'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'artworkId': artworkId,
      if (chapterId != null) 'chapterId': chapterId,
      'startedAt': Timestamp.fromDate(startedAt),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      'timeSpentSeconds': timeSpentSeconds,
      'lastScrollPosition': lastScrollPosition,
      'completionPercentage': completionPercentage,
      'isCompleted': isCompleted,
      'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
      'device': device,
      if (appVersion != null) 'appVersion': appVersion,
      if (metadata != null) 'metadata': metadata,
    };
  }

  ReadingAnalyticsModel copyWith({
    String? id,
    String? userId,
    String? artworkId,
    String? chapterId,
    DateTime? startedAt,
    DateTime? completedAt,
    int? timeSpentSeconds,
    double? lastScrollPosition,
    double? completionPercentage,
    bool? isCompleted,
    List<Bookmark>? bookmarks,
    String? device,
    String? appVersion,
    Map<String, dynamic>? metadata,
  }) {
    return ReadingAnalyticsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      artworkId: artworkId ?? this.artworkId,
      chapterId: chapterId ?? this.chapterId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      lastScrollPosition: lastScrollPosition ?? this.lastScrollPosition,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      isCompleted: isCompleted ?? this.isCompleted,
      bookmarks: bookmarks ?? this.bookmarks,
      device: device ?? this.device,
      appVersion: appVersion ?? this.appVersion,
      metadata: metadata ?? this.metadata,
    );
  }
}
