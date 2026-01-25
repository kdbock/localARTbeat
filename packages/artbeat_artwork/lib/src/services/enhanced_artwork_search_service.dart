import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/artwork_model.dart';

/// Enhanced search service for comprehensive artwork discovery
///
/// Provides advanced search capabilities including full-text search,
/// semantic search, saved searches, and intelligent recommendations.
class EnhancedArtworkSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  /// Advanced search with multiple filters and sorting
  Future<Map<String, dynamic>> advancedSearch({
    String? query,
    List<String>? mediums,
    List<String>? styles,
    double? minPrice,
    double? maxPrice,
    String? location,
    String? artistId,
    bool? isForSale,
    bool? isFeatured,
    String?
    sortBy, // 'relevance', 'price_asc', 'price_desc', 'newest', 'oldest', 'popular'
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      // Track search event for analytics
      await _trackSearchEvent(query ?? '', {
        'mediums': mediums,
        'styles': styles,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'location': location,
        'artistId': artistId,
        'isForSale': isForSale,
        'isFeatured': isFeatured,
        'sortBy': sortBy,
      });

      // Build base query
      Query artworkQuery = _firestore
          .collection('artwork')
          .where('isPublic', isEqualTo: true);

      // Apply filters
      if (mediums != null && mediums.isNotEmpty) {
        artworkQuery = artworkQuery.where('medium', whereIn: mediums);
      }

      if (isForSale != null) {
        artworkQuery = artworkQuery.where('isForSale', isEqualTo: isForSale);
      }

      if (isFeatured != null) {
        artworkQuery = artworkQuery.where('isFeatured', isEqualTo: isFeatured);
      }

      if (location != null) {
        artworkQuery = artworkQuery.where('location', isEqualTo: location);
      }

      if (artistId != null) {
        artworkQuery = artworkQuery.where('userId', isEqualTo: artistId);
      }

      // Apply sorting
      switch (sortBy) {
        case 'price_asc':
          artworkQuery = artworkQuery.orderBy('price', descending: false);
          break;
        case 'price_desc':
          artworkQuery = artworkQuery.orderBy('price', descending: true);
          break;
        case 'newest':
          artworkQuery = artworkQuery.orderBy('createdAt', descending: true);
          break;
        case 'oldest':
          artworkQuery = artworkQuery.orderBy('createdAt', descending: false);
          break;
        case 'popular':
          artworkQuery = artworkQuery.orderBy('viewCount', descending: true);
          break;
        default:
          artworkQuery = artworkQuery.orderBy('createdAt', descending: true);
      }

      // Apply pagination
      if (startAfter != null) {
        artworkQuery = artworkQuery.startAfterDocument(startAfter);
      }

      artworkQuery = artworkQuery.limit(limit);

      // Execute query
      final snapshot = await artworkQuery.get();
      List<ArtworkModel> results = snapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();

      // Apply text search and price filters on client side (due to Firestore limitations)
      if (query != null && query.isNotEmpty) {
        results = _filterByTextSearch(results, query);
      }

      if (minPrice != null || maxPrice != null) {
        results = _filterByPriceRange(results, minPrice, maxPrice);
      }

      if (styles != null && styles.isNotEmpty) {
        results = _filterByStyles(results, styles);
      }

      // Calculate search metadata
      final searchMetadata = {
        'totalResults': results.length,
        'query': query,
        'filters': {
          'mediums': mediums,
          'styles': styles,
          'minPrice': minPrice,
          'maxPrice': maxPrice,
          'location': location,
          'artistId': artistId,
          'isForSale': isForSale,
          'isFeatured': isFeatured,
        },
        'sortBy': sortBy,
        'searchId': _generateSearchId(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      return {
        'results': results,
        'metadata': searchMetadata,
        'hasMore': results.length == limit,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      };
    } catch (e) {
      _logger.e('Error in advanced search: $e', error: e);
      return {
        'results': <ArtworkModel>[],
        'metadata': <String, dynamic>{},
        'hasMore': false,
        'lastDocument': null,
      };
    }
  }

  /// Semantic search using artwork descriptions and tags
  Future<List<ArtworkModel>> semanticSearch(
    String query, {
    int limit = 10,
    double similarityThreshold = 0.3,
  }) async {
    try {
      // Get all artworks for semantic analysis
      final snapshot = await _firestore
          .collection('artwork')
          .where('isPublic', isEqualTo: true)
          .limit(200) // Limit to avoid performance issues
          .get();

      final artworks = snapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();

      // Calculate semantic similarity scores
      final scoredResults = <_ScoredArtwork>[];
      final queryTerms = query.toLowerCase().split(' ');

      for (final artwork in artworks) {
        final score = _calculateSemanticSimilarity(artwork, queryTerms);
        if (score >= similarityThreshold) {
          scoredResults.add(_ScoredArtwork(artwork, score));
        }
      }

      // Sort by relevance score and return top results
      scoredResults.sort((a, b) => b.score.compareTo(a.score));
      return scoredResults.take(limit).map((s) => s.artwork).toList();
    } catch (e) {
      _logger.e('Error in semantic search: $e', error: e);
      return [];
    }
  }

  /// Save a search for quick access
  Future<String?> saveSearch({
    required String name,
    String? query,
    Map<String, dynamic>? filters,
    bool setAsDefault = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final searchData = {
        'name': name,
        'query': query ?? '',
        'filters': filters ?? {},
        'userId': user.uid,
        'isDefault': setAsDefault,
        'createdAt': Timestamp.now(),
        'lastUsed': Timestamp.now(),
        'useCount': 1,
      };

      // If setting as default, unset other defaults first
      if (setAsDefault) {
        await _firestore
            .collection('saved_searches')
            .where('userId', isEqualTo: user.uid)
            .where('isDefault', isEqualTo: true)
            .get()
            .then((snapshot) {
              for (final doc in snapshot.docs) {
                doc.reference.update({'isDefault': false});
              }
            });
      }

      final docRef = await _firestore
          .collection('saved_searches')
          .add(searchData);
      return docRef.id;
    } catch (e) {
      _logger.e('Error saving search: $e', error: e);
      return null;
    }
  }

  /// Get user's saved searches
  Future<List<Map<String, dynamic>>> getSavedSearches() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('saved_searches')
          .where('userId', isEqualTo: user.uid)
          .orderBy('lastUsed', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'],
          'query': data['query'],
          'filters': data['filters'],
          'isDefault': data['isDefault'] ?? false,
          'createdAt': data['createdAt'],
          'lastUsed': data['lastUsed'],
          'useCount': data['useCount'] ?? 0,
        };
      }).toList();
    } catch (e) {
      _logger.e('Error getting saved searches: $e', error: e);
      return [];
    }
  }

  /// Execute a saved search
  Future<Map<String, dynamic>> executeSavedSearch(String searchId) async {
    try {
      final searchDoc = await _firestore
          .collection('saved_searches')
          .doc(searchId)
          .get();
      if (!searchDoc.exists) {
        throw Exception('Saved search not found');
      }

      final searchData = searchDoc.data()!;

      // Update usage statistics
      await searchDoc.reference.update({
        'lastUsed': Timestamp.now(),
        'useCount': FieldValue.increment(1),
      });

      // Execute the search
      final filters = searchData['filters'] as Map<String, dynamic>;
      return await advancedSearch(
        query: searchData['query'] as String?,
        mediums: filters['mediums'] as List<String>?,
        styles: filters['styles'] as List<String>?,
        minPrice: filters['minPrice'] as double?,
        maxPrice: filters['maxPrice'] as double?,
        location: filters['location'] as String?,
        artistId: filters['artistId'] as String?,
        isForSale: filters['isForSale'] as bool?,
        isFeatured: filters['isFeatured'] as bool?,
        sortBy: filters['sortBy'] as String?,
      );
    } catch (e) {
      _logger.e('Error executing saved search: $e', error: e);
      return {
        'results': <ArtworkModel>[],
        'metadata': <String, dynamic>{},
        'hasMore': false,
        'lastDocument': null,
      };
    }
  }

  /// Delete a saved search
  Future<bool> deleteSavedSearch(String searchId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Verify ownership
      final searchDoc = await _firestore
          .collection('saved_searches')
          .doc(searchId)
          .get();
      if (!searchDoc.exists) return false;

      final data = searchDoc.data()!;
      if (data['userId'] != user.uid) return false;

      await searchDoc.reference.delete();
      return true;
    } catch (e) {
      _logger.e('Error deleting saved search: $e', error: e);
      return false;
    }
  }

  /// Get search suggestions based on popular queries
  Future<List<String>> getSearchSuggestions(String partialQuery) async {
    try {
      if (partialQuery.length < 2) return [];

      // Get popular search terms from analytics
      final snapshot = await _firestore
          .collection('analytics')
          .doc('search_terms')
          .collection('popular')
          .orderBy('count', descending: true)
          .limit(50)
          .get();

      final suggestions = <String>[];
      final lowerPartial = partialQuery.toLowerCase();

      for (final doc in snapshot.docs) {
        final term = doc.data()['term'] as String;
        if (term.toLowerCase().contains(lowerPartial)) {
          suggestions.add(term);
        }
      }

      // Also get suggestions from artwork titles and tags
      final artworkSuggestions = await _getArtworkBasedSuggestions(
        partialQuery,
      );
      suggestions.addAll(artworkSuggestions);

      // Remove duplicates and return top suggestions
      return suggestions.toSet().take(10).toList();
    } catch (e) {
      _logger.e('Error getting search suggestions: $e', error: e);
      return [];
    }
  }

  /// Get trending search terms
  Future<List<Map<String, dynamic>>> getTrendingSearches({
    int limit = 10,
  }) async {
    try {
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('analytics')
          .doc('search_events')
          .collection('queries')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(lastWeek))
          .get();

      // Count search term frequencies
      final termCounts = <String, int>{};
      for (final doc in snapshot.docs) {
        final query = doc.data()['query'] as String? ?? '';
        if (query.isNotEmpty) {
          termCounts[query] = (termCounts[query] ?? 0) + 1;
        }
      }

      // Sort and return top trending terms
      final sortedTerms = termCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedTerms
          .take(limit)
          .map(
            (entry) => {
              'term': entry.key,
              'count': entry.value,
              'trend': 'up', // Could be enhanced with trend calculation
            },
          )
          .toList();
    } catch (e) {
      _logger.e('Error getting trending searches: $e', error: e);
      return [];
    }
  }

  /// Get search analytics for admins
  Future<Map<String, dynamic>> getSearchAnalytics({int days = 30}) async {
    try {
      final cutoffDate = Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: days)),
      );

      final snapshot = await _firestore
          .collection('analytics')
          .doc('search_events')
          .collection('queries')
          .where('timestamp', isGreaterThan: cutoffDate)
          .get();

      final queries = snapshot.docs;
      final totalSearches = queries.length;
      final uniqueQueries = queries
          .map((doc) => doc.data()['query'])
          .toSet()
          .length;

      // Calculate zero-result searches
      int zeroResultSearches = 0;
      for (final doc in queries) {
        final data = doc.data();
        final resultCount = data['resultCount'] as int? ?? 0;
        if (resultCount == 0) zeroResultSearches++;
      }

      return {
        'totalSearches': totalSearches,
        'uniqueQueries': uniqueQueries,
        'zeroResultSearches': zeroResultSearches,
        'zeroResultRate': totalSearches > 0
            ? (zeroResultSearches / totalSearches) * 100
            : 0.0,
        'averageResultsPerSearch': totalSearches > 0
            ? queries.fold(
                    0,
                    (sum, doc) =>
                        sum + ((doc.data()['resultCount'] as int?) ?? 0),
                  ) /
                  totalSearches
            : 0.0,
        'timeframeDays': days,
      };
    } catch (e) {
      _logger.e('Error getting search analytics: $e', error: e);
      return {};
    }
  }

  /// Private helper methods

  Future<void> _trackSearchEvent(
    String query,
    Map<String, dynamic> filters,
  ) async {
    try {
      final user = _auth.currentUser;

      await _firestore
          .collection('analytics')
          .doc('search_events')
          .collection('queries')
          .add({
            'query': query,
            'filters': filters,
            'userId': user?.uid,
            'timestamp': Timestamp.now(),
            'resultCount': 0, // Will be updated after search completes
          });

      // Update popular search terms counter
      if (query.isNotEmpty) {
        await _firestore
            .collection('analytics')
            .doc('search_terms')
            .collection('popular')
            .doc(query.toLowerCase())
            .set({
              'term': query,
              'count': FieldValue.increment(1),
              'lastSearched': Timestamp.now(),
            }, SetOptions(merge: true));
      }
    } catch (e) {
      _logger.e('Error tracking search event: $e', error: e);
    }
  }

  List<ArtworkModel> _filterByTextSearch(
    List<ArtworkModel> artworks,
    String query,
  ) {
    final queryTerms = query.toLowerCase().split(' ');

    return artworks.where((artwork) {
      final searchText =
          '${artwork.title} ${artwork.description} ${artwork.tags?.join(' ') ?? ''}'
              .toLowerCase();
      return queryTerms.any((term) => searchText.contains(term));
    }).toList();
  }

  List<ArtworkModel> _filterByPriceRange(
    List<ArtworkModel> artworks,
    double? minPrice,
    double? maxPrice,
  ) {
    return artworks.where((artwork) {
      if (artwork.price == null) return false;

      if (minPrice != null && artwork.price! < minPrice) return false;
      if (maxPrice != null && artwork.price! > maxPrice) return false;

      return true;
    }).toList();
  }

  List<ArtworkModel> _filterByStyles(
    List<ArtworkModel> artworks,
    List<String> styles,
  ) {
    return artworks.where((artwork) {
      if (artwork.styles.isEmpty) return false;
      return artwork.styles.any((style) => styles.contains(style));
    }).toList();
  }

  double _calculateSemanticSimilarity(
    ArtworkModel artwork,
    List<String> queryTerms,
  ) {
    final artworkText =
        '${artwork.title} ${artwork.description} ${artwork.tags?.join(' ') ?? ''} ${artwork.styles.join(' ')}'
            .toLowerCase();
    final artworkWords = artworkText
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();

    double score = 0.0;

    for (final queryTerm in queryTerms) {
      // Exact matches get highest score
      if (artworkText.contains(queryTerm)) {
        score += 1.0;
      }

      // Partial matches get lower score
      for (final word in artworkWords) {
        if (word.contains(queryTerm) || queryTerm.contains(word)) {
          score += 0.5;
        }
      }
    }

    // Normalize by query length
    return score / queryTerms.length;
  }

  Future<List<String>> _getArtworkBasedSuggestions(String partialQuery) async {
    try {
      final snapshot = await _firestore
          .collection('artwork')
          .where('isPublic', isEqualTo: true)
          .limit(100)
          .get();

      final suggestions = <String>{};
      final lowerPartial = partialQuery.toLowerCase();

      for (final doc in snapshot.docs) {
        final artwork = ArtworkModel.fromFirestore(doc);

        // Check title
        if (artwork.title.toLowerCase().contains(lowerPartial)) {
          suggestions.add(artwork.title);
        }

        // Check tags
        if (artwork.tags != null) {
          for (final tag in artwork.tags!) {
            if (tag.toLowerCase().contains(lowerPartial)) {
              suggestions.add(tag);
            }
          }
        }

        // Check styles
        for (final style in artwork.styles) {
          if (style.toLowerCase().contains(lowerPartial)) {
            suggestions.add(style);
          }
        }
      }

      return suggestions.toList();
    } catch (e) {
      _logger.e('Error getting artwork-based suggestions: $e', error: e);
      return [];
    }
  }

  String _generateSearchId() {
    return 'search_${DateTime.now().millisecondsSinceEpoch}_${_auth.currentUser?.uid ?? "anonymous"}';
  }
}

/// Helper class for scored artwork results
class _ScoredArtwork {
  final ArtworkModel artwork;
  final double score;

  _ScoredArtwork(this.artwork, this.score);
}
