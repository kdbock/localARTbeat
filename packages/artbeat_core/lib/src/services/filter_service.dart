import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

import '../models/filter_types.dart';

/// Service for handling all filtering operations
class FilterService {
  FirebaseFirestore? _firestoreInstance;

  FirebaseFirestore get _firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;

  /// Filter artists based on parameters
  Future<List<ArtistProfileModel>> filterArtists(
    FilterParameters params,
  ) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection(
        'artistProfiles',
      );

      // Apply base filters
      if (params.artistTypes?.isNotEmpty ?? false) {
        query = query.where(
          'artistType',
          whereIn: params.artistTypes!.map((t) => t.name).toList(),
        );
      }

      if (params.artMediums?.isNotEmpty ?? false) {
        query = query.where(
          'mediums',
          arrayContainsAny: params.artMediums!.map((m) => m.name).toList(),
        );
      }

      if (params.locations?.isNotEmpty ?? false) {
        query = query.where('location', whereIn: params.locations);
      }

      // Apply sorting
      switch (params.sortBy) {
        case SortOption.relevance:
          query = query.orderBy('isFeatured', descending: true);
          break;
        case SortOption.newestFirst:
          query = query.orderBy('createdAt', descending: true);
          break;
        case SortOption.oldestFirst:
          query = query.orderBy('createdAt', descending: false);
          break;
        case SortOption.mostPopular:
          query = query.orderBy('followerCount', descending: true);
          break;
        case SortOption.leastPopular:
          query = query.orderBy('followerCount', descending: false);
          break;
      }

      final snapshot = await query.get();
      List<ArtistProfileModel> artists = snapshot.docs.map((doc) {
        return ArtistProfileModel.fromFirestore(doc);
      }).toList();

      // Apply text search filter in memory
      if (params.searchQuery?.isNotEmpty ?? false) {
        final searchLower = params.searchQuery!.toLowerCase();
        artists = artists.where((artist) {
          return artist.displayName.toLowerCase().contains(searchLower) ||
              (artist.bio?.toLowerCase() ?? '').contains(searchLower) ||
              artist.mediums.any(
                (medium) => medium.toLowerCase().contains(searchLower),
              ) ||
              artist.styles.any(
                (style) => style.toLowerCase().contains(searchLower),
              );
        }).toList();
      }

      return artists;
    } catch (e, stackTrace) {
      AppLogger.error('Error filtering artists: $e\n$stackTrace');
      return [];
    }
  }

  /// Filter artworks based on parameters
  Future<List<ArtworkModel>> filterArtwork(
    FilterParameters params,
  ) async {
    try {
      Query query = _firestore.collection('artwork');

      // Apply base filters
      if (params.artMediums?.isNotEmpty ?? false) {
        query = query.where(
          'medium',
          whereIn: params.artMediums!.map((m) => m.name).toList(),
        );
      }

      if (params.locations?.isNotEmpty ?? false) {
        query = query.where('location', whereIn: params.locations);
      }

      // Apply date range filters if specified
      if (params.startDate != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(params.startDate!),
        );
      }
      if (params.endDate != null) {
        query = query.where(
          'createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(params.endDate!),
        );
      }

      // Apply sorting
      switch (params.sortBy) {
        case SortOption.relevance:
          query = query.orderBy('viewCount', descending: true);
          break;
        case SortOption.newestFirst:
          query = query.orderBy('createdAt', descending: true);
          break;
        case SortOption.oldestFirst:
          query = query.orderBy('createdAt', descending: false);
          break;
        case SortOption.mostPopular:
          query = query.orderBy('likeCount', descending: true);
          break;
        case SortOption.leastPopular:
          query = query.orderBy('likeCount', descending: false);
          break;
      }

      final snapshot = await query.get();
      var artworks = snapshot.docs.map(ArtworkModel.fromFirestore).toList();

      // Apply text search filter in memory
      if (params.searchQuery?.isNotEmpty ?? false) {
        final searchLower = params.searchQuery!.toLowerCase();
        artworks = artworks.where((artwork) {
          final title = artwork.title.toLowerCase();
          final description = artwork.description.toLowerCase();
          final medium = artwork.medium.toLowerCase();
          final tags = artwork.tags.map((tag) => tag.toLowerCase()).toList();

          return title.contains(searchLower) ||
              description.contains(searchLower) ||
              medium.contains(searchLower) ||
              tags.any((tag) => tag.contains(searchLower));
        }).toList();
      }

      // Apply tag filters in memory
      if (params.tags?.isNotEmpty ?? false) {
        artworks = artworks.where((artwork) {
          final artworkTags = artwork.tags;
          return artworkTags.any((tag) => params.tags!.contains(tag));
        }).toList();
      }

      return artworks;
    } catch (e, stackTrace) {
      AppLogger.error('Error filtering artwork: $e\n$stackTrace');
      return [];
    }
  }

  /// Filter events based on parameters
  Future<List<EventModel>> filterEvents(FilterParameters params) async {
    try {
      Query query = _firestore.collection('events');

      // Apply location filter
      if (params.locations?.isNotEmpty ?? false) {
        query = query.where('location', whereIn: params.locations);
      }

      // Apply date range filters
      if (params.startDate != null) {
        query = query.where(
          'startDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(params.startDate!),
        );
      }
      if (params.endDate != null) {
        query = query.where(
          'endDate',
          isLessThanOrEqualTo: Timestamp.fromDate(params.endDate!),
        );
      }

      // Apply sorting
      switch (params.sortBy) {
        case SortOption.relevance:
        case SortOption.newestFirst:
          query = query.orderBy('startDate', descending: false);
          break;
        case SortOption.oldestFirst:
          query = query.orderBy('startDate', descending: true);
          break;
        case SortOption.mostPopular:
          query = query.orderBy('interestedCount', descending: true);
          break;
        case SortOption.leastPopular:
          query = query.orderBy('interestedCount', descending: false);
          break;
      }

      final snapshot = await query.get();
      List<EventModel> events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();

      // Apply text search filter in memory
      if (params.searchQuery?.isNotEmpty ?? false) {
        final searchLower = params.searchQuery!.toLowerCase();
        events = events.where((event) {
          return event.title.toLowerCase().contains(searchLower) ||
              event.description.toLowerCase().contains(searchLower) ||
              event.location.toLowerCase().contains(searchLower);
        }).toList();
      }

      return events;
    } catch (e, stackTrace) {
      AppLogger.error('Error filtering events: $e\n$stackTrace');
      return [];
    }
  }
}
