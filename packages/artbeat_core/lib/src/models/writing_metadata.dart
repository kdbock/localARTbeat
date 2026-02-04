import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_utils.dart';

/// Metadata for written works (books, stories, poetry, essays, etc.)
class WritingMetadata {
  /// Genre of the work (Fiction, Poetry, Essay, etc.)
  final String? genre;

  /// Total word count of the written work
  final int? wordCount;

  /// Estimated reading time in minutes
  final int? estimatedReadMinutes;

  /// Language of the written work
  final String? language;

  /// Thematic tags for the work
  final List<String> themes;

  /// Whether this is a serialized work (released in chapters)
  final bool isSerializing;

  /// Preview text (first 500 words or excerpt)
  final String? excerpt;

  /// When the work was first published
  final DateTime? firstPublishedDate;

  /// Whether the work has multiple chapters
  final bool hasMultipleChapters;

  const WritingMetadata({
    this.genre,
    this.wordCount,
    this.estimatedReadMinutes,
    this.language = 'English',
    this.themes = const [],
    this.isSerializing = false,
    this.excerpt,
    this.firstPublishedDate,
    this.hasMultipleChapters = false,
  });

  /// Create WritingMetadata from JSON
  factory WritingMetadata.fromJson(Map<String, dynamic> json) {
    return WritingMetadata(
      genre: FirestoreUtils.safeString(json['genre']),
      wordCount: FirestoreUtils.safeInt(json['wordCount']),
      estimatedReadMinutes: FirestoreUtils.safeInt(
        json['estimatedReadMinutes'],
      ),
      language: FirestoreUtils.safeStringDefault(json['language'], 'English'),
      themes:
          (json['themes'] as List<dynamic>?)
              ?.map((e) => FirestoreUtils.safeStringDefault(e))
              .toList() ??
          [],
      isSerializing: FirestoreUtils.safeBool(json['isSerializing'], false),
      excerpt: FirestoreUtils.safeString(json['excerpt']),
      firstPublishedDate: json['firstPublishedDate'] != null
          ? FirestoreUtils.safeDateTime(json['firstPublishedDate'])
          : null,
      hasMultipleChapters: FirestoreUtils.safeBool(
        json['hasMultipleChapters'],
        false,
      ),
    );
  }

  /// Convert WritingMetadata to JSON for Firestore
  Map<String, dynamic> toJson() => {
    if (genre != null) 'genre': genre,
    if (wordCount != null) 'wordCount': wordCount,
    if (estimatedReadMinutes != null)
      'estimatedReadMinutes': estimatedReadMinutes,
    if (language != null) 'language': language,
    'themes': themes,
    'isSerializing': isSerializing,
    if (excerpt != null) 'excerpt': excerpt,
    if (firstPublishedDate != null)
      'firstPublishedDate': Timestamp.fromDate(firstPublishedDate!),
    'hasMultipleChapters': hasMultipleChapters,
  };

  /// Create a copy with updated fields
  WritingMetadata copyWith({
    String? genre,
    int? wordCount,
    int? estimatedReadMinutes,
    String? language,
    List<String>? themes,
    bool? isSerializing,
    String? excerpt,
    DateTime? firstPublishedDate,
    bool? hasMultipleChapters,
  }) {
    return WritingMetadata(
      genre: genre ?? this.genre,
      wordCount: wordCount ?? this.wordCount,
      estimatedReadMinutes: estimatedReadMinutes ?? this.estimatedReadMinutes,
      language: language ?? this.language,
      themes: themes ?? this.themes,
      isSerializing: isSerializing ?? this.isSerializing,
      excerpt: excerpt ?? this.excerpt,
      firstPublishedDate: firstPublishedDate ?? this.firstPublishedDate,
      hasMultipleChapters: hasMultipleChapters ?? this.hasMultipleChapters,
    );
  }

  @override
  String toString() {
    return 'WritingMetadata(genre: $genre, wordCount: $wordCount, language: $language, isSerializing: $isSerializing)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WritingMetadata &&
        other.genre == genre &&
        other.wordCount == wordCount &&
        other.estimatedReadMinutes == estimatedReadMinutes &&
        other.language == language &&
        other.isSerializing == isSerializing;
  }

  @override
  int get hashCode {
    return Object.hash(
      genre,
      wordCount,
      estimatedReadMinutes,
      language,
      isSerializing,
    );
  }
}
