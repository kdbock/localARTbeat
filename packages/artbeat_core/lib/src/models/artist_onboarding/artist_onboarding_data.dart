/// Model representing the artist's onboarding profile data
/// Supports draft saving, auto-save, and resume capability
class ArtistOnboardingData {
  // Screen 1: Artist Identification (captured, but minimal data)
  final bool isArtist;

  // Screen 2: Artist Introduction
  final String? artistIntroduction;
  final String? artistType;

  // Screen 3: Artist Story
  final String? storyOrigin;
  final String? storyInspiration;
  final String? storyMessage;
  final String? profilePhotoUrl;
  final String? profilePhotoLocalPath;

  // Screen 4: Artwork Showcase
  final List<ArtworkDraft> artworks;

  // Screen 5: Featured Artwork Selection
  final List<String> featuredArtworkIds; // Ordered list of artwork IDs

  // Screen 6: Benefits Discovery (analytics/tracking data)
  final List<String> viewedTiers;
  final DateTime? benefitsViewedAt;

  // Screen 7: Package Selection
  final String? selectedTier; // FREE, STARTER, CREATOR, BUSINESS, ENTERPRISE
  final DateTime? tierSelectedAt;

  // Progress tracking
  final int currentStep; // 0-6 (0 = welcome, 6 = complete)
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isComplete;

  const ArtistOnboardingData({
    this.isArtist = true,
    this.artistIntroduction,
    this.artistType,
    this.storyOrigin,
    this.storyInspiration,
    this.storyMessage,
    this.profilePhotoUrl,
    this.profilePhotoLocalPath,
    this.artworks = const [],
    this.featuredArtworkIds = const [],
    this.viewedTiers = const [],
    this.benefitsViewedAt,
    this.selectedTier,
    this.tierSelectedAt,
    this.currentStep = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isComplete = false,
  });

  /// Create empty draft
  factory ArtistOnboardingData.initial() {
    final now = DateTime.now();
    return ArtistOnboardingData(createdAt: now, updatedAt: now);
  }

  /// Copy with method for immutable updates
  ArtistOnboardingData copyWith({
    bool? isArtist,
    String? artistIntroduction,
    String? artistType,
    String? storyOrigin,
    String? storyInspiration,
    String? storyMessage,
    String? profilePhotoUrl,
    String? profilePhotoLocalPath,
    List<ArtworkDraft>? artworks,
    List<String>? featuredArtworkIds,
    List<String>? viewedTiers,
    DateTime? benefitsViewedAt,
    String? selectedTier,
    DateTime? tierSelectedAt,
    int? currentStep,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isComplete,
  }) {
    return ArtistOnboardingData(
      isArtist: isArtist ?? this.isArtist,
      artistIntroduction: artistIntroduction ?? this.artistIntroduction,
      artistType: artistType ?? this.artistType,
      storyOrigin: storyOrigin ?? this.storyOrigin,
      storyInspiration: storyInspiration ?? this.storyInspiration,
      storyMessage: storyMessage ?? this.storyMessage,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      profilePhotoLocalPath:
          profilePhotoLocalPath ?? this.profilePhotoLocalPath,
      artworks: artworks ?? this.artworks,
      featuredArtworkIds: featuredArtworkIds ?? this.featuredArtworkIds,
      viewedTiers: viewedTiers ?? this.viewedTiers,
      benefitsViewedAt: benefitsViewedAt ?? this.benefitsViewedAt,
      selectedTier: selectedTier ?? this.selectedTier,
      tierSelectedAt: tierSelectedAt ?? this.tierSelectedAt,
      currentStep: currentStep ?? this.currentStep,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isComplete: isComplete ?? this.isComplete,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'isArtist': isArtist,
      'artistIntroduction': artistIntroduction,
      'artistType': artistType,
      'storyOrigin': storyOrigin,
      'storyInspiration': storyInspiration,
      'storyMessage': storyMessage,
      'profilePhotoUrl': profilePhotoUrl,
      'profilePhotoLocalPath': profilePhotoLocalPath,
      'artworks': artworks.map((a) => a.toJson()).toList(),
      'featuredArtworkIds': featuredArtworkIds,
      'viewedTiers': viewedTiers,
      'benefitsViewedAt': benefitsViewedAt?.toIso8601String(),
      'selectedTier': selectedTier,
      'tierSelectedAt': tierSelectedAt?.toIso8601String(),
      'currentStep': currentStep,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isComplete': isComplete,
    };
  }

  /// Create from JSON
  factory ArtistOnboardingData.fromJson(Map<String, dynamic> json) {
    return ArtistOnboardingData(
      isArtist: json['isArtist'] as bool? ?? true,
      artistIntroduction: json['artistIntroduction'] as String?,
      artistType: json['artistType'] as String?,
      storyOrigin: json['storyOrigin'] as String?,
      storyInspiration: json['storyInspiration'] as String?,
      storyMessage: json['storyMessage'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      profilePhotoLocalPath: json['profilePhotoLocalPath'] as String?,
      artworks:
          (json['artworks'] as List<dynamic>?)
              ?.map((a) => ArtworkDraft.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      featuredArtworkIds:
          (json['featuredArtworkIds'] as List<dynamic>?)?.cast<String>() ?? [],
      viewedTiers:
          (json['viewedTiers'] as List<dynamic>?)?.cast<String>() ?? [],
      benefitsViewedAt: json['benefitsViewedAt'] != null
          ? DateTime.parse(json['benefitsViewedAt'] as String)
          : null,
      selectedTier: json['selectedTier'] as String?,
      tierSelectedAt: json['tierSelectedAt'] != null
          ? DateTime.parse(json['tierSelectedAt'] as String)
          : null,
      currentStep: json['currentStep'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isComplete: json['isComplete'] as bool? ?? false,
    );
  }

  /// Get completion percentage
  double get completionPercentage {
    int completed = 0;
    const int totalSteps = 7;

    if (isArtist) completed++;
    if (artistIntroduction?.isNotEmpty ?? false) completed++;
    if ((storyOrigin?.isNotEmpty ?? false) ||
        (storyInspiration?.isNotEmpty ?? false) ||
        (storyMessage?.isNotEmpty ?? false)) {
      completed++;
    }
    if (artworks.isNotEmpty) completed++;
    if (featuredArtworkIds.isNotEmpty) completed++;
    if (viewedTiers.isNotEmpty) completed++;
    if (selectedTier != null) completed++;

    return completed / totalSteps;
  }

  /// Check if ready for specific screen
  bool canAccessScreen(int screenIndex) {
    // Welcome screen (0) is always accessible
    if (screenIndex == 0) return true;

    // Each subsequent screen requires the previous to be at least started
    return currentStep >= screenIndex - 1;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtistOnboardingData &&
          runtimeType == other.runtimeType &&
          isArtist == other.isArtist &&
          artistIntroduction == other.artistIntroduction &&
          artistType == other.artistType &&
          currentStep == other.currentStep &&
          isComplete == other.isComplete;

  @override
  int get hashCode =>
      isArtist.hashCode ^
      artistIntroduction.hashCode ^
      artistType.hashCode ^
      currentStep.hashCode ^
      isComplete.hashCode;

  @override
  String toString() {
    return 'ArtistOnboardingData(step: $currentStep, completion: ${(completionPercentage * 100).toStringAsFixed(0)}%, complete: $isComplete)';
  }
}

/// Model for artwork uploaded during onboarding
class ArtworkDraft {
  final String id; // UUID for local tracking
  final String? title;
  final int? yearCreated;
  final String? medium;
  final bool isForSale;
  final double? price;
  final String? currency;
  final String? dimensions; // "HxWxD" format
  final String? availability; // "original", "sold", "prints"
  final String? shipping; // "ship", "pickup", "both"
  final String? imageUrl; // Uploaded image URL
  final String? localImagePath; // Local file path before upload
  final DateTime createdAt;
  final DateTime updatedAt;

  const ArtworkDraft({
    required this.id,
    this.title,
    this.yearCreated,
    this.medium,
    this.isForSale = false,
    this.price,
    this.currency = 'USD',
    this.dimensions,
    this.availability,
    this.shipping,
    this.imageUrl,
    this.localImagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create initial draft with just an image
  factory ArtworkDraft.initial({required String id, String? localImagePath}) {
    final now = DateTime.now();
    return ArtworkDraft(
      id: id,
      localImagePath: localImagePath,
      createdAt: now,
      updatedAt: now,
    );
  }

  ArtworkDraft copyWith({
    String? id,
    String? title,
    int? yearCreated,
    String? medium,
    bool? isForSale,
    double? price,
    String? currency,
    String? dimensions,
    String? availability,
    String? shipping,
    String? imageUrl,
    String? localImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ArtworkDraft(
      id: id ?? this.id,
      title: title ?? this.title,
      yearCreated: yearCreated ?? this.yearCreated,
      medium: medium ?? this.medium,
      isForSale: isForSale ?? this.isForSale,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      dimensions: dimensions ?? this.dimensions,
      availability: availability ?? this.availability,
      shipping: shipping ?? this.shipping,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'yearCreated': yearCreated,
      'medium': medium,
      'isForSale': isForSale,
      'price': price,
      'currency': currency,
      'dimensions': dimensions,
      'availability': availability,
      'shipping': shipping,
      'imageUrl': imageUrl,
      'localImagePath': localImagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ArtworkDraft.fromJson(Map<String, dynamic> json) {
    return ArtworkDraft(
      id: json['id'] as String,
      title: json['title'] as String?,
      yearCreated: json['yearCreated'] as int?,
      medium: json['medium'] as String?,
      isForSale: json['isForSale'] as bool? ?? false,
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      dimensions: json['dimensions'] as String?,
      availability: json['availability'] as String?,
      shipping: json['shipping'] as String?,
      imageUrl: json['imageUrl'] as String?,
      localImagePath: json['localImagePath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Check if artwork has minimum required data
  bool get hasMinimumData {
    return (imageUrl != null || localImagePath != null) &&
        title != null &&
        title!.isNotEmpty;
  }

  @override
  String toString() {
    return 'ArtworkDraft(id: $id, title: $title, forSale: $isForSale)';
  }
}
