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

  /// International Standard Book Number
  final String? isbn;

  /// Series name if this is part of a series
  final String? seriesName;

  /// Volume number in the series
  final int? volumeNumber;

  /// Publisher of the work
  final String? publisher;

  /// Edition of the work (e.g., First Edition, Revised)
  final String? edition;

  /// Short hook or teaser for the work
  final String? shortHook;

  /// Story status (e.g., Ongoing, Completed)
  final String? storyStatus;

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
    this.isbn,
    this.seriesName,
    this.volumeNumber,
    this.publisher,
    this.edition,
    this.shortHook,
    this.storyStatus,
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
      isbn: FirestoreUtils.safeString(json['isbn']),
      seriesName: FirestoreUtils.safeString(json['seriesName']),
      volumeNumber: FirestoreUtils.safeInt(json['volumeNumber']),
      publisher: FirestoreUtils.safeString(json['publisher']),
      edition: FirestoreUtils.safeString(json['edition']),
      shortHook: FirestoreUtils.safeString(json['shortHook']),
      storyStatus: FirestoreUtils.safeString(json['storyStatus']),
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
    if (isbn != null) 'isbn': isbn,
    if (seriesName != null) 'seriesName': seriesName,
    if (volumeNumber != null) 'volumeNumber': volumeNumber,
    if (publisher != null) 'publisher': publisher,
    if (edition != null) 'edition': edition,
    if (shortHook != null) 'shortHook': shortHook,
    if (storyStatus != null) 'storyStatus': storyStatus,
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
    String? isbn,
    String? seriesName,
    int? volumeNumber,
    String? publisher,
    String? edition,
    String? shortHook,
    String? storyStatus,
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
      isbn: isbn ?? this.isbn,
      seriesName: seriesName ?? this.seriesName,
      volumeNumber: volumeNumber ?? this.volumeNumber,
      publisher: publisher ?? this.publisher,
      edition: edition ?? this.edition,
      shortHook: shortHook ?? this.shortHook,
      storyStatus: storyStatus ?? this.storyStatus,
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
