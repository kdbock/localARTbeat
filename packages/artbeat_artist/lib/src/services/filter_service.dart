import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/artist_logger.dart';

/// Service for handling search and filtering operations in the artist module
class FilterService {
  static final FilterService _instance = FilterService._internal();
  factory FilterService() => _instance;
  FilterService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Filter artists by various criteria
  Future<List<Map<String, dynamic>>> filterArtists({
    String? location,
    List<String>? specialties,
    String? searchTerm,
    bool? isVerified,
    bool? isFeatured,
    String? subscriptionTier,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore.collection('artistProfiles');

      // Apply location filter
      if (location != null && location.isNotEmpty) {
        query = query.where('location', isEqualTo: location);
      }

      // Apply verification filter
      if (isVerified != null) {
        query = query.where('isVerified', isEqualTo: isVerified);
      }

      // Apply featured filter
      if (isFeatured != null) {
        query = query.where('isFeatured', isEqualTo: isFeatured);
      }

      // Apply subscription tier filter
      if (subscriptionTier != null && subscriptionTier.isNotEmpty) {
        query = query.where('subscriptionTier', isEqualTo: subscriptionTier);
      }

      // Apply specialty filter (if single specialty)
      if (specialties != null &&
          specialties.isNotEmpty &&
          specialties.length == 1) {
        query = query.where('specialties', arrayContains: specialties.first);
      }

      // Apply pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      List<Map<String, dynamic>> results = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>..['id'] = doc.id)
          .toList();

      // Apply search term filter (client-side for more flexible search)
      if (searchTerm != null && searchTerm.isNotEmpty) {
        results = results.where((artist) {
          final name = (artist['displayName'] ?? '').toString().toLowerCase();
          final bio = (artist['bio'] ?? '').toString().toLowerCase();
          final location = (artist['location'] ?? '').toString().toLowerCase();
          final searchLower = searchTerm.toLowerCase();

          return name.contains(searchLower) ||
              bio.contains(searchLower) ||
              location.contains(searchLower);
        }).toList();
      }

      // Apply multiple specialties filter (client-side)
      if (specialties != null && specialties.length > 1) {
        results = results.where((artist) {
          final artistSpecialtiesRaw = artist['specialties'];
          if (artistSpecialtiesRaw == null) return false;
          final artistSpecialties = (artistSpecialtiesRaw as List<dynamic>)
              .map((e) => e.toString())
              .toList();
          return specialties.any(
            (specialty) => artistSpecialties.contains(specialty),
          );
        }).toList();
      }

      return results;
    } catch (e) {
      ArtistLogger.error('Error filtering artists: $e');
      return [];
    }
  }

  /// Filter artworks by various criteria
  Future<List<Map<String, dynamic>>> filterArtworks({
    String? artistId,
    String? medium,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? location,
    bool? isForSale,
    String? searchTerm,
    String? sortBy, // 'price', 'date', 'popularity'
    bool ascending = true,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore.collection('artworks');

      // Apply artist filter
      if (artistId != null && artistId.isNotEmpty) {
        query = query.where('artistId', isEqualTo: artistId);
      }

      // Apply medium filter
      if (medium != null && medium.isNotEmpty) {
        query = query.where('medium', isEqualTo: medium);
      }

      // Apply category filter
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      // Apply location filter
      if (location != null && location.isNotEmpty) {
        query = query.where('location', isEqualTo: location);
      }

      // Apply for sale filter
      if (isForSale != null) {
        query = query.where('isForSale', isEqualTo: isForSale);
      }

      // Apply sorting
      if (sortBy != null) {
        switch (sortBy) {
          case 'price':
            query = query.orderBy('price', descending: !ascending);
            break;
          case 'date':
            query = query.orderBy('createdAt', descending: !ascending);
            break;
          case 'popularity':
            query = query.orderBy('likeCount', descending: !ascending);
            break;
          default:
            query = query.orderBy('createdAt', descending: true);
        }
      } else {
        query = query.orderBy('createdAt', descending: true);
      }

      // Apply pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      List<Map<String, dynamic>> results = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>..['id'] = doc.id)
          .toList();

      // Apply price range filter (client-side for flexibility)
      if (minPrice != null || maxPrice != null) {
        results = results.where((artwork) {
          final price = (artwork['price'] as num?)?.toDouble() ?? 0.0;
          final meetsMin = minPrice == null || price >= minPrice;
          final meetsMax = maxPrice == null || price <= maxPrice;
          return meetsMin && meetsMax;
        }).toList();
      }

      // Apply search term filter (client-side)
      if (searchTerm != null && searchTerm.isNotEmpty) {
        results = results.where((artwork) {
          final title = (artwork['title'] ?? '').toString().toLowerCase();
          final description = (artwork['description'] ?? '')
              .toString()
              .toLowerCase();
          final tagsRaw = artwork['tags'];
          final tags = tagsRaw != null
              ? (tagsRaw as List<dynamic>)
                    .map((tag) => tag.toString().toLowerCase())
                    .toList()
              : <String>[];
          final searchLower = searchTerm.toLowerCase();

          return title.contains(searchLower) ||
              description.contains(searchLower) ||
              tags.any((tag) => tag.contains(searchLower));
        }).toList();
      }

      return results;
    } catch (e) {
      ArtistLogger.error('Error filtering artworks: $e');
      return [];
    }
  }

  /// Filter events by various criteria
  Future<List<Map<String, dynamic>>> filterEvents({
    String? organizerId,
    String? eventType,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    bool? isPublic,
    String? searchTerm,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('events');

      // Apply organizer filter
      if (organizerId != null && organizerId.isNotEmpty) {
        query = query.where('organizerId', isEqualTo: organizerId);
      }

      // Apply event type filter
      if (eventType != null && eventType.isNotEmpty) {
        query = query.where('eventType', isEqualTo: eventType);
      }

      // Apply location filter
      if (location != null && location.isNotEmpty) {
        query = query.where('location', isEqualTo: location);
      }

      // Apply public filter
      if (isPublic != null) {
        query = query.where('isPublic', isEqualTo: isPublic);
      }

      // Apply date range filter
      if (startDate != null) {
        query = query.where('startDate', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('startDate', isLessThanOrEqualTo: endDate);
      }

      query = query.orderBy('startDate').limit(limit);

      final snapshot = await query.get();
      List<Map<String, dynamic>> results = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>..['id'] = doc.id)
          .toList();

      // Apply search term filter (client-side)
      if (searchTerm != null && searchTerm.isNotEmpty) {
        results = results.where((event) {
          final title = (event['title'] ?? '').toString().toLowerCase();
          final description = (event['description'] ?? '')
              .toString()
              .toLowerCase();
          final venue = (event['venue'] ?? '').toString().toLowerCase();
          final searchLower = searchTerm.toLowerCase();

          return title.contains(searchLower) ||
              description.contains(searchLower) ||
              venue.contains(searchLower);
        }).toList();
      }

      return results;
    } catch (e) {
      ArtistLogger.error('Error filtering events: $e');
      return [];
    }
  }

  /// Get available filter options for artists
  Future<Map<String, List<String>>> getArtistFilterOptions() async {
    try {
      final snapshot = await _firestore.collection('artistProfiles').get();

      final locations = <String>{};
      final specialties = <String>{};
      final subscriptionTiers = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (data['location'] != null) {
          locations.add(data['location'].toString());
        }

        if (data['specialties'] != null) {
          final specialtiesRaw = data['specialties'];
          final artistSpecialties = (specialtiesRaw as List<dynamic>)
              .map((e) => e.toString())
              .toList();
          specialties.addAll(artistSpecialties);
        }

        if (data['subscriptionTier'] != null) {
          subscriptionTiers.add(data['subscriptionTier'].toString());
        }
      }

      return {
        'locations': locations.toList()..sort(),
        'specialties': specialties.toList()..sort(),
        'subscriptionTiers': subscriptionTiers.toList()..sort(),
      };
    } catch (e) {
      ArtistLogger.error('Error getting artist filter options: $e');
      return {'locations': [], 'specialties': [], 'subscriptionTiers': []};
    }
  }

  /// Get available filter options for artworks
  Future<Map<String, List<String>>> getArtworkFilterOptions() async {
    try {
      final snapshot = await _firestore.collection('artworks').get();

      final mediums = <String>{};
      final categories = <String>{};
      final locations = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (data['medium'] != null) {
          mediums.add(data['medium'].toString());
        }

        if (data['category'] != null) {
          categories.add(data['category'].toString());
        }

        if (data['location'] != null) {
          locations.add(data['location'].toString());
        }
      }

      return {
        'mediums': mediums.toList()..sort(),
        'categories': categories.toList()..sort(),
        'locations': locations.toList()..sort(),
      };
    } catch (e) {
      ArtistLogger.error('Error getting artwork filter options: $e');
      return {'mediums': [], 'categories': [], 'locations': []};
    }
  }

  /// Build search query with advanced parameters
  Map<String, dynamic> buildSearchQuery({
    String? searchTerm,
    Map<String, dynamic>? filters,
    String? sortBy,
    bool ascending = true,
    int limit = 20,
    int offset = 0,
  }) {
    final query = <String, dynamic>{'limit': limit, 'offset': offset};

    if (searchTerm != null && searchTerm.isNotEmpty) {
      query['searchTerm'] = searchTerm;
    }

    if (filters != null && filters.isNotEmpty) {
      query['filters'] = filters;
    }

    if (sortBy != null) {
      query['sortBy'] = sortBy;
      query['ascending'] = ascending;
    }

    return query;
  }
}
