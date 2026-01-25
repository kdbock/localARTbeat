import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppLogger;
import '../models/artwork_model.dart';

/// Pagination state tracker
class PaginationState {
  final List<ArtworkModel> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final bool isLoading;
  final String? error;

  PaginationState({
    required this.items,
    this.lastDocument,
    required this.hasMore,
    required this.isLoading,
    this.error,
  });

  PaginationState copyWith({
    List<ArtworkModel>? items,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
    bool? isLoading,
    String? error,
  }) {
    return PaginationState(
      items: items ?? this.items,
      lastDocument: lastDocument ?? this.lastDocument,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Service for handling pagination of artwork lists
class ArtworkPaginationService {
  static final ArtworkPaginationService _instance =
      ArtworkPaginationService._internal();
  factory ArtworkPaginationService() => _instance;
  ArtworkPaginationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int _pageSize = 50;

  /// Load recent artworks with pagination
  Future<PaginationState> loadRecentArtworks({
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('artworks')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize + 1); // Load one extra to check if more exists

      // If paginating, start after last document
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;

      // Check if there are more items
      final bool hasMore = docs.length > _pageSize;
      final itemDocs = hasMore ? docs.sublist(0, _pageSize) : docs;

      final artworks = itemDocs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();

      final lastDoc = itemDocs.isEmpty ? null : itemDocs.last;

      AppLogger.info(
        '✅ Loaded ${artworks.length} recent artworks '
        '(hasMore: $hasMore)',
      );

      return PaginationState(
        items: artworks,
        lastDocument: lastDoc,
        hasMore: hasMore,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error('❌ Error loading recent artworks: $e');
      return PaginationState(
        items: [],
        hasMore: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load trending artworks with pagination
  Future<PaginationState> loadTrendingArtworks({
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('artworks')
          .where('isPublic', isEqualTo: true)
          .orderBy('engagementScore', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize + 1);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;

      final bool hasMore = docs.length > _pageSize;
      final itemDocs = hasMore ? docs.sublist(0, _pageSize) : docs;

      final artworks = itemDocs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();

      final lastDoc = itemDocs.isEmpty ? null : itemDocs.last;

      AppLogger.info(
        '✅ Loaded ${artworks.length} trending artworks '
        '(hasMore: $hasMore)',
      );

      return PaginationState(
        items: artworks,
        lastDocument: lastDoc,
        hasMore: hasMore,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error('❌ Error loading trending artworks: $e');
      return PaginationState(
        items: [],
        hasMore: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load featured artworks with pagination
  Future<PaginationState> loadFeaturedArtworks({
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('artworks')
          .where('isPublic', isEqualTo: true)
          .where('isFeatured', isEqualTo: true)
          .orderBy('featuredDate', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize + 1);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;

      final bool hasMore = docs.length > _pageSize;
      final itemDocs = hasMore ? docs.sublist(0, _pageSize) : docs;

      final artworks = itemDocs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();

      final lastDoc = itemDocs.isEmpty ? null : itemDocs.last;

      AppLogger.info(
        '✅ Loaded ${artworks.length} featured artworks '
        '(hasMore: $hasMore)',
      );

      return PaginationState(
        items: artworks,
        lastDocument: lastDoc,
        hasMore: hasMore,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error('❌ Error loading featured artworks: $e');
      return PaginationState(
        items: [],
        hasMore: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load all artworks with pagination
  Future<PaginationState> loadAllArtworks({
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('artworks')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize + 1);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;

      final bool hasMore = docs.length > _pageSize;
      final itemDocs = hasMore ? docs.sublist(0, _pageSize) : docs;

      final artworks = itemDocs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();

      final lastDoc = itemDocs.isEmpty ? null : itemDocs.last;

      return PaginationState(
        items: artworks,
        lastDocument: lastDoc,
        hasMore: hasMore,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error('❌ Error loading artworks: $e');
      return PaginationState(
        items: [],
        hasMore: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load artworks by artist with pagination
  Future<PaginationState> loadArtistArtworks({
    required String artistId,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('artworks')
          .where('userId', isEqualTo: artistId)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize + 1);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;

      final bool hasMore = docs.length > _pageSize;
      final itemDocs = hasMore ? docs.sublist(0, _pageSize) : docs;

      final artworks = itemDocs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();

      final lastDoc = itemDocs.isEmpty ? null : itemDocs.last;

      return PaginationState(
        items: artworks,
        lastDocument: lastDoc,
        hasMore: hasMore,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error('❌ Error loading artist artworks: $e');
      return PaginationState(
        items: [],
        hasMore: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get page size
  int getPageSize() => _pageSize;
}
