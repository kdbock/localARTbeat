import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/known_entity_model.dart';
import '../models/capture_model.dart';
import '../services/capture_service_interface.dart';

/// Repository for searching across all entity types in the app
class KnownEntityRepository {
  final FirebaseFirestore _firestore;
  final CaptureServiceInterface _captureService;

  KnownEntityRepository({
    FirebaseFirestore? firestore,
    CaptureServiceInterface? captureService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _captureService = captureService ?? DefaultCaptureService();

  /// Search across all entity types
  /// Returns a unified list of KnownEntity objects
  Future<List<KnownEntity>> search(String query) async {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    final results = <KnownEntity>[];

    // Execute searches in parallel for better performance
    final futures = <Future<List<KnownEntity>>>[
      _searchArtists(lowerQuery),
      _searchArtwork(lowerQuery),
      _searchArtWalks(lowerQuery),
      _searchEvents(lowerQuery),
      _searchCommunity(lowerQuery),
      _searchLocations(lowerQuery),
    ];

    try {
      final searchResults = await Future.wait(futures);

      // Flatten and combine all results
      for (final entityList in searchResults) {
        results.addAll(entityList);
      }

      // Sort by relevance (exact matches first, then partial matches)
      results.sort(
        (a, b) => _calculateRelevanceScore(
          b,
          lowerQuery,
        ).compareTo(_calculateRelevanceScore(a, lowerQuery)),
      );

      // Limit total results to prevent overwhelming UI
      return results.take(50).toList();
    } catch (error) {
      debugPrint('❌ KnownEntityRepository: Search error: $error');
      rethrow;
    }
  }

  /// Search for artists/users
  Future<List<KnownEntity>> _searchArtists(String lowerQuery) async {
    final results = <KnownEntity>[];

    try {
      // Search users collection - increased limit to search more users
      // TODO: Implement searchTokens field for better performance
      final usersQuery = await _firestore.collection('users').limit(200).get();

      for (final doc in usersQuery.docs) {
        final data = doc.data();
        if (_matchesArtistData(data, lowerQuery)) {
          results.add(KnownEntity.fromArtist(id: doc.id, data: data));
        }
      }

      // Search artist profiles collection
      final artistProfilesQuery = await _firestore
          .collection('artist_profiles')
          .limit(200)
          .get();

      for (final doc in artistProfilesQuery.docs) {
        final data = doc.data();
        if (_matchesArtistProfileData(data, lowerQuery)) {
          results.add(KnownEntity.fromArtist(id: doc.id, data: data));
        }
      }
    } catch (error) {
      debugPrint('Error searching artists: $error');
    }

    return results;
  }

  /// Search for artwork/captures
  Future<List<KnownEntity>> _searchArtwork(String lowerQuery) async {
    final results = <KnownEntity>[];

    try {
      // Search captures using CaptureService with increased limit
      final captures = await _captureService.getAllCaptures(limit: 100);

      for (final capture in captures) {
        // Filter by query - improved capture filtering
        // Get photographer user info for enhanced matching
        String? photographerName;
        String? photographerUsername;

        try {
          // Try to get user info from the captures collection if it has photographer details
          // or fetch from users collection
          final userDoc = await _firestore
              .collection('users')
              .doc(capture.userId)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            photographerName = userData['fullName'] as String?;
            photographerUsername = userData['username'] as String?;
          }
        } catch (e) {
          debugPrint(
            'Error fetching photographer info for capture ${capture.id}: $e',
          );
        }

        if (_matchesCaptureData(
          capture,
          lowerQuery,
          photographerName: photographerName,
          photographerUsername: photographerUsername,
        )) {
          final data = {
            'title': capture.title ?? '',
            'artistName': capture.artistName ?? '',
            'description': capture.description ?? '',
            'imageUrl': capture.imageUrl,
            'tags': capture.tags ?? [],
            'userId': capture.userId,
            'photographerName': photographerName ?? '',
            'photographerUsername': photographerUsername ?? '',
            'createdAt': capture.createdAt.toIso8601String(),
          };

          results.add(KnownEntity.fromArtwork(id: capture.id, data: data));
        }
      }

      // Search artwork collection if it exists
      try {
        final artworkQuery = await _firestore
            .collection('artwork')
            .limit(100)
            .get();

        for (final doc in artworkQuery.docs) {
          final data = doc.data();
          if (_matchesArtworkData(data, lowerQuery)) {
            results.add(KnownEntity.fromArtwork(id: doc.id, data: data));
          }
        }
      } catch (_) {
        // Artwork collection might not exist
      }
    } catch (error) {
      debugPrint('Error searching artwork: $error');
    }

    return results;
  }

  /// Search for art walks
  Future<List<KnownEntity>> _searchArtWalks(String lowerQuery) async {
    final results = <KnownEntity>[];

    try {
      final artWalksQuery = await _firestore
          .collection('art_walks')
          .limit(100)
          .get();

      for (final doc in artWalksQuery.docs) {
        final data = doc.data();
        if (_matchesArtWalkData(data, lowerQuery)) {
          results.add(KnownEntity.fromArtWalk(id: doc.id, data: data));
        }
      }
    } catch (error) {
      debugPrint('Error searching art walks: $error');
    }

    return results;
  }

  /// Search for events
  Future<List<KnownEntity>> _searchEvents(String lowerQuery) async {
    final results = <KnownEntity>[];

    try {
      final eventsQuery = await _firestore
          .collection('events')
          .limit(100)
          .get();

      for (final doc in eventsQuery.docs) {
        final data = doc.data();
        if (_matchesEventData(data, lowerQuery)) {
          results.add(KnownEntity.fromEvent(id: doc.id, data: data));
        }
      }
    } catch (error) {
      debugPrint('Error searching events: $error');
    }

    return results;
  }

  /// Search for community posts
  Future<List<KnownEntity>> _searchCommunity(String lowerQuery) async {
    final results = <KnownEntity>[];

    try {
      // Search community posts
      try {
        final postsQuery = await _firestore
            .collection('community_posts')
            .limit(100)
            .get();

        for (final doc in postsQuery.docs) {
          final data = doc.data();
          if (_matchesCommunityData(data, lowerQuery)) {
            results.add(KnownEntity.fromCommunity(id: doc.id, data: data));
          }
        }
      } catch (e) {
        debugPrint('Error searching community posts: $e');
      }

      // Search artist directory
      try {
        final artistDirQuery = await _firestore
            .collection('artist_directory')
            .limit(100)
            .get();

        for (final doc in artistDirQuery.docs) {
          final data = doc.data();
          if (_matchesArtistDirectoryData(data, lowerQuery)) {
            results.add(KnownEntity.fromCommunity(id: doc.id, data: data));
          }
        }
      } catch (e) {
        debugPrint('Error searching artist directory: $e');
      }
    } catch (error) {
      debugPrint('Error searching community: $error');
    }

    return results;
  }

  /// Search for locations (galleries, venues, studios)
  Future<List<KnownEntity>> _searchLocations(String lowerQuery) async {
    final results = <KnownEntity>[];

    try {
      // Search galleries collection
      try {
        final galleriesQuery = await _firestore
            .collection('galleries')
            .limit(100)
            .get();

        for (final doc in galleriesQuery.docs) {
          final data = doc.data();
          if (_matchesLocationData(data, lowerQuery)) {
            results.add(KnownEntity.fromLocation(id: doc.id, data: data));
          }
        }
      } catch (e) {
        debugPrint('Error searching galleries: $e');
      }

      // Search venues collection
      try {
        final venuesQuery = await _firestore
            .collection('venues')
            .limit(100)
            .get();

        for (final doc in venuesQuery.docs) {
          final data = doc.data();
          if (_matchesLocationData(data, lowerQuery)) {
            results.add(KnownEntity.fromLocation(id: doc.id, data: data));
          }
        }
      } catch (e) {
        debugPrint('Error searching venues: $e');
      }
    } catch (error) {
      debugPrint('Error searching locations: $error');
    }

    return results;
  }

  /// Check if artist/user data matches query
  bool _matchesArtistData(Map<String, dynamic> data, String lowerQuery) {
    final fullName = (data['fullName'] as String? ?? '').toLowerCase();
    final username = (data['username'] as String? ?? '').toLowerCase();

    return fullName.contains(lowerQuery) ||
        username.contains(lowerQuery) ||
        _matchesWords(fullName, lowerQuery) ||
        _matchesWords(username, lowerQuery);
  }

  /// Check if artist profile data matches query
  bool _matchesArtistProfileData(Map<String, dynamic> data, String lowerQuery) {
    final artistName = (data['artistName'] as String? ?? '').toLowerCase();
    final bio = (data['bio'] as String? ?? '').toLowerCase();
    final tags = (data['tags'] as List<dynamic>? ?? [])
        .map((tag) => tag.toString().toLowerCase())
        .toList();

    return artistName.contains(lowerQuery) ||
        bio.contains(lowerQuery) ||
        tags.any((tag) => tag.contains(lowerQuery)) ||
        _matchesWords(artistName, lowerQuery) ||
        _matchesWords(bio, lowerQuery);
  }

  /// Check if capture data matches query
  bool _matchesCaptureData(
    CaptureModel capture,
    String lowerQuery, {
    String? photographerName,
    String? photographerUsername,
  }) {
    final title = (capture.title ?? '').toLowerCase();
    final artistName = (capture.artistName ?? '').toLowerCase();
    final description = (capture.description ?? '').toLowerCase();
    final tags = (capture.tags ?? []).map((tag) => tag.toLowerCase()).toList();
    final tagsString = tags.join(' ');

    // Photographer info for search matching
    final photographerFullName = (photographerName ?? '').toLowerCase();
    final photographer = (photographerUsername ?? '').toLowerCase();

    // Direct contains check for any field (including photographer info)
    if (title.contains(lowerQuery) ||
        artistName.contains(lowerQuery) ||
        description.contains(lowerQuery) ||
        tagsString.contains(lowerQuery) ||
        photographerFullName.contains(lowerQuery) ||
        photographer.contains(lowerQuery)) {
      return true;
    }

    // Word-by-word matching for better results
    final queryWords = lowerQuery.split(' ');
    for (final queryWord in queryWords) {
      if (queryWord.isNotEmpty && queryWord.length > 2) {
        // Skip very short words
        if (title.contains(queryWord) ||
            artistName.contains(queryWord) ||
            description.contains(queryWord) ||
            tagsString.contains(queryWord) ||
            photographerFullName.contains(queryWord) ||
            photographer.contains(queryWord)) {
          return true;
        }
      }
    }

    // Legacy word boundary matches
    return _matchesWords(title, lowerQuery) ||
        _matchesWords(artistName, lowerQuery) ||
        _matchesWords(description, lowerQuery) ||
        _matchesWords(photographerFullName, lowerQuery) ||
        _matchesWords(photographer, lowerQuery);
  }

  /// Check if artwork data matches query
  bool _matchesArtworkData(Map<String, dynamic> data, String lowerQuery) {
    final title = (data['title'] as String? ?? '').toLowerCase();
    final artistName = (data['artistName'] as String? ?? '').toLowerCase();
    final description = (data['description'] as String? ?? '').toLowerCase();
    final tags = (data['tags'] as List<dynamic>? ?? [])
        .map((tag) => tag.toString().toLowerCase())
        .toList();

    return title.contains(lowerQuery) ||
        artistName.contains(lowerQuery) ||
        description.contains(lowerQuery) ||
        tags.any((tag) => tag.contains(lowerQuery)) ||
        _matchesWords(title, lowerQuery) ||
        _matchesWords(artistName, lowerQuery) ||
        _matchesWords(description, lowerQuery);
  }

  /// Check if art walk data matches query
  bool _matchesArtWalkData(Map<String, dynamic> data, String lowerQuery) {
    final title = (data['title'] as String? ?? '').toLowerCase();
    final description = (data['description'] as String? ?? '').toLowerCase();
    final zipCode = (data['zipCode'] as String? ?? '').toLowerCase();
    final tags = (data['tags'] as List<dynamic>? ?? [])
        .map((tag) => tag.toString().toLowerCase())
        .toList();

    return title.contains(lowerQuery) ||
        description.contains(lowerQuery) ||
        zipCode.contains(lowerQuery) ||
        tags.any((tag) => tag.contains(lowerQuery)) ||
        _matchesWords(title, lowerQuery) ||
        _matchesWords(description, lowerQuery);
  }

  /// Check if event data matches query
  bool _matchesEventData(Map<String, dynamic> data, String lowerQuery) {
    final title = (data['title'] as String? ?? '').toLowerCase();
    final description = (data['description'] as String? ?? '').toLowerCase();
    final location = (data['location'] as String? ?? '').toLowerCase();
    final tags = (data['tags'] as List<dynamic>? ?? [])
        .map((tag) => tag.toString().toLowerCase())
        .toList();

    return title.contains(lowerQuery) ||
        description.contains(lowerQuery) ||
        location.contains(lowerQuery) ||
        tags.any((tag) => tag.contains(lowerQuery)) ||
        _matchesWords(title, lowerQuery) ||
        _matchesWords(description, lowerQuery) ||
        _matchesWords(location, lowerQuery);
  }

  /// Check if community data (posts, artists) matches query
  bool _matchesCommunityData(Map<String, dynamic> data, String lowerQuery) {
    final title = (data['title'] as String? ?? '').toLowerCase();
    final content = (data['content'] as String? ?? '').toLowerCase();
    final description = (data['description'] as String? ?? '').toLowerCase();
    final authorName = (data['authorName'] as String? ?? '').toLowerCase();
    final tags = (data['tags'] as List<dynamic>? ?? [])
        .map((tag) => tag.toString().toLowerCase())
        .toList();

    return title.contains(lowerQuery) ||
        content.contains(lowerQuery) ||
        description.contains(lowerQuery) ||
        authorName.contains(lowerQuery) ||
        tags.any((tag) => tag.contains(lowerQuery)) ||
        _matchesWords(title, lowerQuery) ||
        _matchesWords(content, lowerQuery) ||
        _matchesWords(description, lowerQuery) ||
        _matchesWords(authorName, lowerQuery);
  }

  /// Check if artist directory data matches query
  bool _matchesArtistDirectoryData(
    Map<String, dynamic> data,
    String lowerQuery,
  ) {
    final artistName = (data['artistName'] as String? ?? '').toLowerCase();
    final bio = (data['bio'] as String? ?? '').toLowerCase();
    final style = (data['style'] as String? ?? '').toLowerCase();
    final tags = (data['tags'] as List<dynamic>? ?? [])
        .map((tag) => tag.toString().toLowerCase())
        .toList();

    return artistName.contains(lowerQuery) ||
        bio.contains(lowerQuery) ||
        style.contains(lowerQuery) ||
        tags.any((tag) => tag.contains(lowerQuery)) ||
        _matchesWords(artistName, lowerQuery) ||
        _matchesWords(bio, lowerQuery) ||
        _matchesWords(style, lowerQuery);
  }

  /// Check if location (gallery, venue) data matches query
  bool _matchesLocationData(Map<String, dynamic> data, String lowerQuery) {
    final name = (data['name'] as String? ?? '').toLowerCase();
    final description = (data['description'] as String? ?? '').toLowerCase();
    final address = (data['address'] as String? ?? '').toLowerCase();
    final city = (data['city'] as String? ?? '').toLowerCase();
    final tags = (data['tags'] as List<dynamic>? ?? [])
        .map((tag) => tag.toString().toLowerCase())
        .toList();

    return name.contains(lowerQuery) ||
        description.contains(lowerQuery) ||
        address.contains(lowerQuery) ||
        city.contains(lowerQuery) ||
        tags.any((tag) => tag.contains(lowerQuery)) ||
        _matchesWords(name, lowerQuery) ||
        _matchesWords(description, lowerQuery) ||
        _matchesWords(address, lowerQuery) ||
        _matchesWords(city, lowerQuery);
  }

  /// Check for word boundary matches (e.g., "Kelly" matches "Kristy Kelly")
  bool _matchesWords(String text, String query) {
    if (text.isEmpty || query.isEmpty) return false;

    final queryWords = query.split(' ');
    final textWords = text.split(' ');

    for (final queryWord in queryWords) {
      if (queryWord.isNotEmpty) {
        for (final textWord in textWords) {
          if (textWord.startsWith(queryWord)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Calculate relevance score for sorting results
  /// Higher score = more relevant
  int _calculateRelevanceScore(KnownEntity entity, String lowerQuery) {
    final title = entity.title.toLowerCase();
    final subtitle = entity.subtitle.toLowerCase();
    int score = 0;

    // Exact title match gets highest score
    if (title == lowerQuery) {
      score += 100;
    }
    // Title starts with query
    else if (title.startsWith(lowerQuery)) {
      score += 80;
    }
    // Title contains query
    else if (title.contains(lowerQuery)) {
      score += 60;
    }

    // Subtitle matches (lower priority)
    if (subtitle.contains(lowerQuery)) {
      score += 20;
    }

    // Word boundary matches
    if (_matchesWords(title, lowerQuery)) {
      score += 40;
    }

    // Boost recent items slightly
    if (entity.createdAt != null) {
      final daysSinceCreation = DateTime.now()
          .difference(entity.createdAt!)
          .inDays;
      if (daysSinceCreation < 30) {
        score += 5;
      }
    }

    return score;
  }
}
