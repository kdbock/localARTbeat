import 'package:cloud_firestore/cloud_firestore.dart';

/// Comprehensive search and filter model for Art Walk discovery
class ArtWalkSearchCriteria {
  final String? searchQuery;
  final List<String>? tags;
  final String? difficulty; // Easy, Medium, Hard
  final bool? isAccessible;
  final double? maxDistance; // Maximum distance in miles
  final double? maxDuration; // Maximum duration in minutes
  final String? zipCode; // Location filter
  final bool? isPublic;
  final String? sortBy; // popular, newest, distance, duration, title
  final bool? sortDescending;
  final int? limit;
  final DocumentSnapshot? lastDocument; // For pagination

  const ArtWalkSearchCriteria({
    this.searchQuery,
    this.tags,
    this.difficulty,
    this.isAccessible,
    this.maxDistance,
    this.maxDuration,
    this.zipCode,
    this.isPublic,
    this.sortBy = 'popular',
    this.sortDescending = true,
    this.limit = 20,
    this.lastDocument,
  });

  /// Create a copy with updated values
  ArtWalkSearchCriteria copyWith({
    String? searchQuery,
    List<String>? tags,
    String? difficulty,
    bool? isAccessible,
    double? maxDistance,
    double? maxDuration,
    String? zipCode,
    bool? isPublic,
    String? sortBy,
    bool? sortDescending,
    int? limit,
    DocumentSnapshot? lastDocument,
  }) {
    return ArtWalkSearchCriteria(
      searchQuery: searchQuery ?? this.searchQuery,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      isAccessible: isAccessible ?? this.isAccessible,
      maxDistance: maxDistance ?? this.maxDistance,
      maxDuration: maxDuration ?? this.maxDuration,
      zipCode: zipCode ?? this.zipCode,
      isPublic: isPublic ?? this.isPublic,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
      limit: limit ?? this.limit,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }

  /// Check if any filters are active
  bool get hasActiveFilters {
    return searchQuery != null && searchQuery!.isNotEmpty ||
        tags != null && tags!.isNotEmpty ||
        difficulty != null ||
        isAccessible != null ||
        maxDistance != null ||
        maxDuration != null ||
        zipCode != null && zipCode!.isNotEmpty ||
        isPublic != null;
  }

  /// Get human-readable summary of active filters
  String get filterSummary {
    final List<String> filters = [];

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      filters.add('"$searchQuery"');
    }
    if (difficulty != null) {
      filters.add('Difficulty: $difficulty');
    }
    if (isAccessible == true) {
      filters.add('Accessible');
    }
    if (maxDistance != null) {
      filters.add('Within ${maxDistance!.toStringAsFixed(1)} miles');
    }
    if (maxDuration != null) {
      filters.add('Under ${maxDuration!.toInt()} minutes');
    }
    if (tags != null && tags!.isNotEmpty) {
      filters.add('Tags: ${tags!.join(', ')}');
    }
    if (zipCode != null && zipCode!.isNotEmpty) {
      filters.add('Location: $zipCode');
    }

    return filters.join(' • ');
  }

  /// Convert to JSON for caching/storage
  Map<String, dynamic> toJson() {
    return {
      'searchQuery': searchQuery,
      'tags': tags,
      'difficulty': difficulty,
      'isAccessible': isAccessible,
      'maxDistance': maxDistance,
      'maxDuration': maxDuration,
      'zipCode': zipCode,
      'isPublic': isPublic,
      'sortBy': sortBy,
      'sortDescending': sortDescending,
      'limit': limit,
    };
  }

  /// Create from JSON
  factory ArtWalkSearchCriteria.fromJson(Map<String, dynamic> json) {
    return ArtWalkSearchCriteria(
      searchQuery: json['searchQuery'] as String?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List<dynamic>)
          : null,
      difficulty: json['difficulty'] as String?,
      isAccessible: json['isAccessible'] as bool?,
      maxDistance: (json['maxDistance'] as num?)?.toDouble(),
      maxDuration: (json['maxDuration'] as num?)?.toDouble(),
      zipCode: json['zipCode'] as String?,
      isPublic: json['isPublic'] as bool?,
      sortBy: json['sortBy'] as String? ?? 'popular',
      sortDescending: json['sortDescending'] as bool? ?? true,
      limit: json['limit'] as int? ?? 20,
    );
  }

  @override
  String toString() {
    return 'ArtWalkSearchCriteria('
        'query: $searchQuery, '
        'tags: $tags, '
        'difficulty: $difficulty, '
        'accessible: $isAccessible, '
        'maxDistance: $maxDistance, '
        'maxDuration: $maxDuration, '
        'zipCode: $zipCode, '
        'sortBy: $sortBy'
        ')';
  }
}

/// Search criteria specifically for public art discovery
class PublicArtSearchCriteria {
  final String? searchQuery;
  final String? artistName;
  final List<String>? artTypes; // Mural, Sculpture, Installation, etc.
  final List<String>? tags;
  final bool? isVerified;
  final double? minRating;
  final double? maxDistanceKm; // Search radius in kilometers
  final String? zipCode;
  final String? sortBy; // popular, newest, rating, distance, title
  final bool? sortDescending;
  final int? limit;
  final DocumentSnapshot? lastDocument;

  const PublicArtSearchCriteria({
    this.searchQuery,
    this.artistName,
    this.artTypes,
    this.tags,
    this.isVerified,
    this.minRating,
    this.maxDistanceKm = 10.0,
    this.zipCode,
    this.sortBy = 'popular',
    this.sortDescending = true,
    this.limit = 20,
    this.lastDocument,
  });

  /// Create a copy with updated values
  PublicArtSearchCriteria copyWith({
    String? searchQuery,
    String? artistName,
    List<String>? artTypes,
    List<String>? tags,
    bool? isVerified,
    double? minRating,
    double? maxDistanceKm,
    String? zipCode,
    String? sortBy,
    bool? sortDescending,
    int? limit,
    DocumentSnapshot? lastDocument,
  }) {
    return PublicArtSearchCriteria(
      searchQuery: searchQuery ?? this.searchQuery,
      artistName: artistName ?? this.artistName,
      artTypes: artTypes ?? this.artTypes,
      tags: tags ?? this.tags,
      isVerified: isVerified ?? this.isVerified,
      minRating: minRating ?? this.minRating,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      zipCode: zipCode ?? this.zipCode,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
      limit: limit ?? this.limit,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }

  /// Check if any filters are active
  bool get hasActiveFilters {
    return searchQuery != null && searchQuery!.isNotEmpty ||
        artistName != null && artistName!.isNotEmpty ||
        artTypes != null && artTypes!.isNotEmpty ||
        tags != null && tags!.isNotEmpty ||
        isVerified != null ||
        minRating != null ||
        zipCode != null && zipCode!.isNotEmpty;
  }

  /// Get human-readable summary of active filters
  String get filterSummary {
    final List<String> filters = [];

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      filters.add('"$searchQuery"');
    }
    if (artistName != null && artistName!.isNotEmpty) {
      filters.add('Artist: $artistName');
    }
    if (artTypes != null && artTypes!.isNotEmpty) {
      filters.add('Types: ${artTypes!.join(', ')}');
    }
    if (isVerified == true) {
      filters.add('Verified Only');
    }
    if (minRating != null) {
      filters.add('Rating: ${minRating!.toStringAsFixed(1)}+');
    }
    if (tags != null && tags!.isNotEmpty) {
      filters.add('Tags: ${tags!.join(', ')}');
    }
    if (zipCode != null && zipCode!.isNotEmpty) {
      filters.add('Location: $zipCode');
    }

    return filters.join(' • ');
  }

  /// Convert to JSON for caching/storage
  Map<String, dynamic> toJson() {
    return {
      'searchQuery': searchQuery,
      'artistName': artistName,
      'artTypes': artTypes,
      'tags': tags,
      'isVerified': isVerified,
      'minRating': minRating,
      'maxDistanceKm': maxDistanceKm,
      'zipCode': zipCode,
      'sortBy': sortBy,
      'sortDescending': sortDescending,
      'limit': limit,
    };
  }

  /// Create from JSON
  factory PublicArtSearchCriteria.fromJson(Map<String, dynamic> json) {
    return PublicArtSearchCriteria(
      searchQuery: json['searchQuery'] as String?,
      artistName: json['artistName'] as String?,
      artTypes: json['artTypes'] != null
          ? List<String>.from(json['artTypes'] as List<dynamic>)
          : null,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List<dynamic>)
          : null,
      isVerified: json['isVerified'] as bool?,
      minRating: (json['minRating'] as num?)?.toDouble(),
      maxDistanceKm: (json['maxDistanceKm'] as num?)?.toDouble() ?? 10.0,
      zipCode: json['zipCode'] as String?,
      sortBy: json['sortBy'] as String? ?? 'popular',
      sortDescending: json['sortDescending'] as bool? ?? true,
      limit: json['limit'] as int? ?? 20,
    );
  }

  @override
  String toString() {
    return 'PublicArtSearchCriteria('
        'query: $searchQuery, '
        'artist: $artistName, '
        'types: $artTypes, '
        'verified: $isVerified, '
        'rating: $minRating+, '
        'radius: ${maxDistanceKm}km, '
        'sortBy: $sortBy'
        ')';
  }
}

/// Search result wrapper with metadata
class SearchResult<T> {
  final List<T> results;
  final int totalCount;
  final bool hasNextPage;
  final DocumentSnapshot? lastDocument;
  final String searchQuery;
  final Duration searchDuration;

  const SearchResult({
    required this.results,
    required this.totalCount,
    required this.hasNextPage,
    this.lastDocument,
    required this.searchQuery,
    required this.searchDuration,
  });

  /// Create empty search result
  factory SearchResult.empty(String query) {
    return SearchResult<T>(
      results: [],
      totalCount: 0,
      hasNextPage: false,
      lastDocument: null,
      searchQuery: query,
      searchDuration: Duration.zero,
    );
  }
}
