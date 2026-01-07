import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/artist_model.dart';
import '../models/artist_profile_model.dart';
import '../utils/logger.dart';

/// Unified ArtistService that handles both basic artist operations
/// and enhanced artist profile functionality
///
/// This service consolidates functionality from both artbeat_core and artbeat_artist
/// to provide a single point of truth for artist-related operations.
class ArtistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get featured artists using ArtistProfileModel for enhanced data
  Future<List<ArtistProfileModel>> getFeaturedArtistProfiles() async {
    try {
      AppLogger.info('🎨 ArtistService: Fetching featured artist profiles...');
      final snapshot = await _firestore
          .collection('artistProfiles')
          .where('isFeatured', isEqualTo: true)
          .where('isPortfolioPublic', isEqualTo: true)
          .orderBy('likesCount', descending: true)
          .limit(20)
          .get()
          .timeout(const Duration(seconds: 10));

      final artists = snapshot.docs
          .map((doc) => ArtistProfileModel.fromFirestore(doc))
          .toList();

      debugPrint(
        '🎨 ArtistService: Loaded ${artists.length} featured artist profiles',
      );
      return artists;
    } catch (e) {
      debugPrint(
        '❌ ArtistService: Error fetching featured artist profiles: $e',
      );
      return [];
    }
  }

  /// Search artists by name with enhanced filtering
  Future<List<ArtistProfileModel>> searchArtistProfiles(
    String query, {
    String? location,
    List<String>? mediums,
    bool onlyFeatured = false,
  }) async {
    try {
      AppLogger.debug(
        '🔍 ArtistService: Searching artists with query: "$query"',
      );

      Query artistsQuery = _firestore.collection('artistProfiles');

      // Apply filters
      if (onlyFeatured) {
        artistsQuery = artistsQuery.where('isFeatured', isEqualTo: true);
      }

      if (location != null && location.isNotEmpty) {
        artistsQuery = artistsQuery.where('location', isEqualTo: location);
      }

      // For mediums, we'll filter in memory since Firestore array-contains-any has limits
      final snapshot = await artistsQuery
          .where('isPortfolioPublic', isEqualTo: true)
          .orderBy('displayName')
          .get()
          .timeout(const Duration(seconds: 10));

      var results = snapshot.docs
          .map((doc) => ArtistProfileModel.fromFirestore(doc))
          .toList();

      // Filter by search query (case-insensitive)
      if (query.isNotEmpty) {
        final queryLower = query.toLowerCase();
        results = results
            .where(
              (artist) =>
                  artist.displayName.toLowerCase().contains(queryLower) ||
                  (artist.bio?.toLowerCase().contains(queryLower) == true),
            )
            .toList();
      }

      // Filter by mediums
      if (mediums != null && mediums.isNotEmpty) {
        results = results
            .where(
              (artist) => artist.mediums.any(
                (String medium) => mediums.contains(medium),
              ),
            )
            .toList();
      }

      AppLogger.debug(
        '🔍 ArtistService: Found ${results.length} matching artists',
      );
      return results;
    } catch (e) {
      AppLogger.error('❌ ArtistService: Error searching artists: $e');
      return [];
    }
  }

  /// Get a single artist profile by ID
  Future<ArtistProfileModel?> getArtistProfileById(String id) async {
    try {
      final doc = await _firestore.collection('artistProfiles').doc(id).get();
      if (doc.exists) {
        return ArtistProfileModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting artist profile $id: $e');
      return null;
    }
  }

  Future<List<ArtistModel>> searchArtists(String query) async {
    Query artistsQuery = _firestore.collection('artists');

    if (query.isNotEmpty) {
      // Case-insensitive search using Firebase's array-contains operator
      artistsQuery = artistsQuery.where(
        'searchTerms',
        arrayContains: query.toLowerCase(),
      );
    }

    final snapshot = await artistsQuery.get();
    return snapshot.docs
        .map(
          (doc) => ArtistModel.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>,
            null,
          ),
        )
        .toList();
  }

  Future<List<ArtistModel>> getFeaturedArtists() async {
    try {
      final snapshot = await _firestore
          .collection('artists')
          .where('isFeatured', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 10));

      return snapshot.docs
          .map(
            (doc) => ArtistModel.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
              null,
            ),
          )
          .toList();
    } catch (e) {
      AppLogger.error('Error getting featured artists: $e');
      return [];
    }
  }

  Future<List<ArtistModel>> getAllArtists() async {
    try {
      final snapshot = await _firestore
          .collection('artists')
          .get()
          .timeout(const Duration(seconds: 10));

      return snapshot.docs
          .map(
            (doc) => ArtistModel.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
              null,
            ),
          )
          .toList();
    } catch (e) {
      AppLogger.error('Error getting all artists: $e');
      return [];
    }
  }

  Future<ArtistModel> createArtist(String name) async {
    final artist = ArtistModel(
      id: '', // Will be set by Firestore
      name: name,
      isVerified: false,
    );

    // Generate search terms for case-insensitive search
    final searchTerms = _generateSearchTerms(name);
    final artistData = {...artist.toFirestore(), 'searchTerms': searchTerms};

    final docRef = await _firestore.collection('artists').add(artistData);

    return ArtistModel(
      id: docRef.id,
      name: name,
      isVerified: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  List<String> _generateSearchTerms(String name) {
    final terms = <String>[];
    final nameLower = name.toLowerCase();

    // Add full name
    terms.add(nameLower);

    // Add each word
    terms.addAll(nameLower.split(' '));

    // Add prefixes of each word for partial matching
    for (final word in nameLower.split(' ')) {
      for (int i = 1; i <= word.length; i++) {
        terms.add(word.substring(0, i));
      }
    }

    return terms.toSet().toList(); // Remove duplicates
  }
}
