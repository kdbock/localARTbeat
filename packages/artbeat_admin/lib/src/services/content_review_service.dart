import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart' show ChapterService;
import '../models/content_review_model.dart';
import '../models/content_model.dart';
import 'content_analysis_service.dart';

/// Service for content review operations
class ContentReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ContentAnalysisService _analysisService = ContentAnalysisService();
  final ChapterService _chapterService = ChapterService();

  /// Get pending content reviews with advanced filtering
  Future<List<ContentReviewModel>> getPendingReviews({
    ContentType? contentType,
    int? limit,
    ModerationFilters? filters,
  }) async {
    try {
      List<ContentReviewModel> allReviews = [];

      // Get pending captures if contentType is captures or all
      if (contentType == null ||
          contentType == ContentType.all ||
          contentType == ContentType.captures) {
        final capturesQuery = _firestore
            .collection('captures')
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true);

        final capturesSnapshot = await capturesQuery.get();

        for (final doc in capturesSnapshot.docs) {
          final data = doc.data();

          // Get user info for author name
          String authorName = 'Unknown User';
          try {
            final userDoc = await _firestore
                .collection('users')
                .doc(data['userId'] as String?)
                .get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              authorName = (userData['fullName'] as String?) ??
                  (userData['username'] as String?) ??
                  'Unknown User';
            }
          } catch (e) {
            // Continue with default name if user lookup fails
          }

          allReviews.add(ContentReviewModel(
            id: doc.id,
            contentId: doc.id,
            contentType: ContentType.captures,
            title: (data['title'] as String?) ?? 'Untitled Capture',
            description:
                (data['description'] as String?) ?? 'No description provided',
            authorId: (data['userId'] as String?) ?? '',
            authorName: authorName,
            status: ReviewStatus.pending,
            createdAt: (data['createdAt'] as Timestamp).toDate(),
            metadata: {
              'imageUrl': data['imageUrl'],
              'thumbnailUrl': data['thumbnailUrl'],
              'location': data['location'],
              'locationName': data['locationName'],
              'tags': data['tags'],
              'artistId': data['artistId'],
              'artistName': data['artistName'],
            },
          ));
        }
      }

      // Get pending ads if contentType is ads or all
      if (contentType == null ||
          contentType == ContentType.all ||
          contentType == ContentType.ads) {
        try {
          final adsQuery = _firestore
              .collection('ads')
              .where('status', isEqualTo: 'pending')
              .orderBy('createdAt', descending: true);

          final adsSnapshot = await adsQuery.get();

          for (final doc in adsSnapshot.docs) {
            final data = doc.data();

            // Get user info for author name
            String authorName = 'Unknown User';
            try {
              final userDoc = await _firestore
                  .collection('users')
                  .doc((data['ownerId'] as String?) ??
                      (data['userId'] as String?))
                  .get();
              if (userDoc.exists) {
                final userData = userDoc.data()!;
                authorName = (userData['fullName'] as String?) ??
                    (userData['username'] as String?) ??
                    'Unknown User';
              }
            } catch (e) {
              // Continue with default name if user lookup fails
            }

            allReviews.add(ContentReviewModel(
              id: doc.id,
              contentId: doc.id,
              contentType: ContentType.ads,
              title: (data['title'] as String?) ?? 'Untitled Ad',
              description:
                  (data['description'] as String?) ?? 'No description provided',
              authorId: (data['ownerId'] as String?) ??
                  (data['userId'] as String?) ??
                  '',
              authorName: authorName,
              status: ReviewStatus.pending,
              createdAt: (data['createdAt'] as Timestamp).toDate(),
              metadata: {
                'imageUrl': data['imageUrl'],
                'type': data['type'],
                'location': data['location'],
                'startDate': data['startDate'],
                'endDate': data['endDate'],
              },
            ));
          }
        } catch (e) {
          // Ads collection might not exist or have different structure
          // Note: Could not fetch ads - collection may not exist: $e
        }
      }

      // Get pending posts if contentType is posts or all
      if (contentType == null ||
          contentType == ContentType.all ||
          contentType == ContentType.posts) {
        try {
          final postsQuery = _firestore
              .collection('posts')
              .where('flagged', isEqualTo: true)
              .orderBy('createdAt', descending: true);

          final postsSnapshot = await postsQuery.get();

          for (final doc in postsSnapshot.docs) {
            final data = doc.data();

            // Get user info for author name
            String authorName = 'Unknown User';
            try {
              final userDoc = await _firestore
                  .collection('users')
                  .doc(data['userId'] as String?)
                  .get();
              if (userDoc.exists) {
                final userData = userDoc.data()!;
                authorName = (userData['fullName'] as String?) ??
                    (userData['username'] as String?) ??
                    'Unknown User';
              }
            } catch (e) {
              // Continue with default name if user lookup fails
            }

            allReviews.add(ContentReviewModel(
              id: doc.id,
              contentId: doc.id,
              contentType: ContentType.posts,
              title:
                  'Post by ${(data['userName'] as String?) ?? 'Unknown User'}',
              description:
                  (data['content'] as String?) ?? 'No content provided',
              authorId: (data['userId'] as String?) ?? '',
              authorName: authorName,
              status: ReviewStatus.flagged,
              createdAt: (data['createdAt'] as Timestamp).toDate(),
              metadata: {
                'content': data['content'],
                'imageUrls': data['imageUrls'],
                'tags': data['tags'],
                'location': data['location'],
                'userName': data['userName'],
                'userPhotoUrl': data['userPhotoUrl'],
                'isPublic': data['isPublic'],
                'flaggedAt': data['flaggedAt'],
                'moderationStatus': data['moderationStatus'],
              },
            ));
          }
        } catch (e) {
          // Note: Could not fetch posts - collection may not exist: $e
        }
      }

      // Get pending comments if contentType is comments or all
      if (contentType == null ||
          contentType == ContentType.all ||
          contentType == ContentType.comments) {
        try {
          final commentsQuery = _firestore
              .collection('comments')
              .where('flagged', isEqualTo: true)
              .orderBy('createdAt', descending: true);

          final commentsSnapshot = await commentsQuery.get();

          for (final doc in commentsSnapshot.docs) {
            final data = doc.data();

            // Get user info for author name
            String authorName = 'Unknown User';
            try {
              final userDoc = await _firestore
                  .collection('users')
                  .doc(data['userId'] as String?)
                  .get();
              if (userDoc.exists) {
                final userData = userDoc.data()!;
                authorName = (userData['fullName'] as String?) ??
                    (userData['username'] as String?) ??
                    'Unknown User';
              }
            } catch (e) {
              // Continue with default name if user lookup fails
            }

            allReviews.add(ContentReviewModel(
              id: doc.id,
              contentId: doc.id,
              contentType: ContentType.comments,
              title:
                  'Comment by ${(data['userName'] as String?) ?? 'Unknown User'}',
              description:
                  (data['content'] as String?) ?? 'No content provided',
              authorId: (data['userId'] as String?) ?? '',
              authorName: authorName,
              status: ReviewStatus.flagged,
              createdAt: (data['createdAt'] as Timestamp).toDate(),
              metadata: {
                'content': data['content'],
                'postId': data['postId'],
                'parentCommentId': data['parentCommentId'],
                'type': data['type'],
                'userName': data['userName'],
                'userAvatarUrl': data['userAvatarUrl'],
                'flaggedAt': data['flaggedAt'],
                'moderationStatus': data['moderationStatus'],
              },
            ));
          }
        } catch (e) {
          // Note: Could not fetch comments - collection may not exist: $e
        }
      }

      // Get pending artwork if contentType is artwork or all
      if (contentType == null ||
          contentType == ContentType.all ||
          contentType == ContentType.artwork) {
        try {
          final artworkQuery = _firestore
              .collection('artwork')
              .where('status', isEqualTo: 'pending')
              .orderBy('createdAt', descending: true);

          final artworkSnapshot = await artworkQuery.get();

          for (final doc in artworkSnapshot.docs) {
            final data = doc.data();

            // Get user info for author name
            String authorName = 'Unknown User';
            try {
              final userDoc = await _firestore
                  .collection('users')
                  .doc((data['artistId'] as String?) ??
                      (data['userId'] as String?))
                  .get();
              if (userDoc.exists) {
                final userData = userDoc.data()!;
                authorName = (userData['fullName'] as String?) ??
                    (userData['username'] as String?) ??
                    'Unknown User';
              }
            } catch (e) {
              // Continue with default name if user lookup fails
            }

            allReviews.add(ContentReviewModel(
              id: doc.id,
              contentId: doc.id,
              contentType: ContentType.artwork,
              title: (data['title'] as String?) ?? 'Untitled Artwork',
              description:
                  (data['description'] as String?) ?? 'No description provided',
              authorId: (data['artistId'] as String?) ??
                  (data['userId'] as String?) ??
                  '',
              authorName: authorName,
              status: ReviewStatus.pending,
              createdAt: (data['createdAt'] as Timestamp).toDate(),
              metadata: {
                'imageUrl': data['imageUrl'],
                'price': data['price'],
                'medium': data['medium'],
                'tags': data['tags'],
                'artistName': data['artistName'],
                'isSold': data['isSold'],
                'galleryId': data['galleryId'],
                'applauseCount': data['applauseCount'],
                'viewsCount': data['viewsCount'],
              },
            ));
          }
        } catch (e) {
          // Note: Could not fetch artwork - collection may not exist: $e
        }
      }

      // Get pending chapters if contentType is chapters or all
      if (contentType == null ||
          contentType == ContentType.all ||
          contentType == ContentType.chapters) {
        try {
          final chaptersQuery = _firestore
              .collectionGroup('chapters')
              .where('moderationStatus', isEqualTo: 'pending')
              .orderBy('createdAt', descending: true);

          final chaptersSnapshot = await chaptersQuery.get();

          for (final doc in chaptersSnapshot.docs) {
            final data = doc.data();

            allReviews.add(ContentReviewModel(
              id: doc.id,
              contentId: doc.id,
              contentType: ContentType.chapters,
              title: (data['title'] as String?) ?? 'Untitled Chapter',
              description:
                  (data['description'] as String?) ?? 'No description provided',
              authorId: (data['authorId'] as String?) ?? '',
              authorName: (data['authorName'] as String?) ?? 'Unknown Author',
              status: ReviewStatus.pending,
              createdAt: (data['createdAt'] as Timestamp).toDate(),
              metadata: {
                'thumbnailUrl': data['thumbnailUrl'],
                'artworkId': data['artworkId'],
                'chapterNumber': data['chapterNumber'],
                'wordCount': data['wordCount'],
                'isPaid': data['isPaid'],
              },
            ));
          }
        } catch (e) {
          // Note: Could not fetch chapters - collection may not exist: $e
        }
      }

      // Sort all reviews by creation date
      allReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Apply filters if specified
      if (filters != null) {
        allReviews = _applyFilters(allReviews, filters);
      }

      // Apply limit if specified
      final finalLimit = limit ?? filters?.limit;
      if (finalLimit != null && allReviews.length > finalLimit) {
        allReviews = allReviews.take(finalLimit).toList();
      }

      return allReviews;
    } catch (e) {
      throw Exception('Failed to get pending reviews: $e');
    }
  }

  /// Get all content reviews with optional filtering
  Future<List<ContentReviewModel>> getContentReviews({
    ContentType? contentType,
    ReviewStatus? status,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('content_reviews');

      if (contentType != null && contentType != ContentType.all) {
        query = query.where('contentType', isEqualTo: contentType.name);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate);
      }

      query = query.orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ContentReviewModel.fromDocument(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get content reviews: $e');
    }
  }

  /// Approve content
  Future<void> approveContent(
    String contentId,
    ContentType contentType, {
    String? artworkId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Update the actual content record based on type
      await _updateContentStatus(contentId, contentType, true,
          artworkId: artworkId);

      // Log the approval action
      await _logReviewAction(contentId, contentType, 'approved', user.uid);
    } catch (e) {
      throw Exception('Failed to approve content: $e');
    }
  }

  /// Reject content
  Future<void> rejectContent(
    String contentId,
    ContentType contentType,
    String reason, {
    String? artworkId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Update the actual content record based on type
      await _updateContentStatus(contentId, contentType, false,
          reason: reason, artworkId: artworkId);

      // Log the rejection action
      await _logReviewAction(contentId, contentType, 'rejected', user.uid,
          reason: reason);
    } catch (e) {
      throw Exception('Failed to reject content: $e');
    }
  }

  /// Create a new content review entry
  Future<void> createContentReview({
    required String contentId,
    required ContentType contentType,
    required String title,
    required String description,
    required String authorId,
    required String authorName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final review = ContentReviewModel(
        id: contentId,
        contentId: contentId,
        contentType: contentType,
        title: title,
        description: description,
        authorId: authorId,
        authorName: authorName,
        status: ReviewStatus.pending,
        createdAt: DateTime.now(),
        metadata: metadata ?? {},
      );

      await _firestore
          .collection('content_reviews')
          .doc(contentId)
          .set(review.toDocument());
    } catch (e) {
      throw Exception('Failed to create content review: $e');
    }
  }

  /// Update content status based on content type
  Future<void> _updateContentStatus(
    String contentId,
    ContentType contentType,
    bool isApproved, {
    String? reason,
    String? artworkId,
  }) async {
    String collectionName = '';
    Map<String, dynamic> updateData;

    switch (contentType) {
      case ContentType.ads:
        collectionName = 'ads';
        updateData = {
          'status': isApproved ? 'approved' : 'rejected',
          'reviewedAt': FieldValue.serverTimestamp(),
        };
        break;
      case ContentType.captures:
        collectionName = 'captures';
        updateData = {
          'status': isApproved ? 'approved' : 'rejected',
          'reviewedAt': FieldValue.serverTimestamp(),
        };
        break;
      case ContentType.posts:
        collectionName = 'posts';
        updateData = {
          'flagged': false,
          'moderationStatus': isApproved ? 'approved' : 'removed',
          'moderatedAt': FieldValue.serverTimestamp(),
          'isPublic': isApproved, // Hide post if rejected
        };
        break;
      case ContentType.comments:
        collectionName = 'comments';
        updateData = {
          'flagged': false,
          'moderationStatus': isApproved ? 'approved' : 'removed',
          'moderatedAt': FieldValue.serverTimestamp(),
        };
        // If comment is rejected, we might want to delete it entirely
        if (!isApproved) {
          await _firestore.collection(collectionName).doc(contentId).delete();
          return;
        }
        break;
      case ContentType.artwork:
        collectionName = 'artwork';
        updateData = {
          'status': isApproved ? 'approved' : 'rejected',
          'reviewedAt': FieldValue.serverTimestamp(),
        };
        break;
      case ContentType.chapters:
        if (artworkId == null) {
          throw Exception('Artwork ID is required for chapter moderation');
        }

        await _firestore
            .collection('artwork')
            .doc(artworkId)
            .collection('chapters')
            .doc(contentId)
            .update({
          'moderationStatus': isApproved ? 'approved' : 'rejected',
          'moderatedAt': FieldValue.serverTimestamp(),
          if (!isApproved && reason != null) 'moderationNotes': reason,
        });

        // Always update chapter counts on the parent artwork
        // This ensures the public 'releasedChapters' count is accurate
        await _chapterService.updateArtworkCountsForAdmin(artworkId);
        return;

      case ContentType.all:
        return; // Cannot update all content types
    }

    if (!isApproved && reason != null) {
      updateData['moderationNotes'] = reason;
    }

    if (collectionName.isNotEmpty) {
      await _firestore
          .collection(collectionName)
          .doc(contentId)
          .update(updateData);
    }
  }

  /// Log review action for audit trail
  Future<void> _logReviewAction(
    String contentId,
    ContentType contentType,
    String action,
    String reviewerId, {
    String? reason,
  }) async {
    await _firestore.collection('content_review_logs').add({
      'contentId': contentId,
      'contentType': contentType.name,
      'action': action,
      'reviewerId': reviewerId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Get content review statistics
  Future<Map<String, int>> getReviewStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('content_reviews');

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      final reviews = snapshot.docs
          .map((doc) => ContentReviewModel.fromDocument(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      final stats = <String, int>{
        'total': reviews.length,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
      };

      for (final contentType in ContentType.values) {
        if (contentType != ContentType.all) {
          stats[contentType.name] = 0;
        }
      }

      for (final review in reviews) {
        stats[review.status.name] = (stats[review.status.name] ?? 0) + 1;
        stats[review.contentType.name] =
            (stats[review.contentType.name] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get review stats: $e');
    }
  }

  /// Get content review by ID
  Future<ContentReviewModel?> getContentReviewById(String id) async {
    try {
      final doc = await _firestore.collection('content_reviews').doc(id).get();
      if (doc.exists) {
        return ContentReviewModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get content review: $e');
    }
  }

  /// Delete content review
  Future<void> deleteContentReview(String id) async {
    try {
      await _firestore.collection('content_reviews').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete content review: $e');
    }
  }

  /// Enhanced bulk approve content with proper content type handling
  Future<void> bulkApproveContent(
    List<ContentReviewModel> contentReviews,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Group content by type for efficient batch operations
      final contentByType = <ContentType, List<ContentReviewModel>>{};
      for (final review in contentReviews) {
        contentByType.putIfAbsent(review.contentType, () => []).add(review);
      }

      // Process each content type separately
      for (final entry in contentByType.entries) {
        final contentType = entry.key;
        final reviews = entry.value;

        final batch = _firestore.batch();

        for (final review in reviews) {
          // Update the actual content
          final artworkId = review.metadata?['artworkId'] as String?;
          await approveContent(review.contentId, contentType,
              artworkId: artworkId);

          // Update the review record
          final reviewDocRef =
              _firestore.collection('content_reviews').doc(review.id);
          batch.update(reviewDocRef, {
            'status': ReviewStatus.approved.name,
            'reviewedAt': FieldValue.serverTimestamp(),
            'reviewedBy': user.uid,
          });
        }

        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to bulk approve content: $e');
    }
  }

  /// Enhanced bulk reject content with proper content type handling
  Future<void> bulkRejectContent(
    List<ContentReviewModel> contentReviews,
    String reason,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Group content by type for efficient batch operations
      final contentByType = <ContentType, List<ContentReviewModel>>{};
      for (final review in contentReviews) {
        contentByType.putIfAbsent(review.contentType, () => []).add(review);
      }

      // Process each content type separately
      for (final entry in contentByType.entries) {
        final contentType = entry.key;
        final reviews = entry.value;

        final batch = _firestore.batch();

        for (final review in reviews) {
          // Update the actual content
          final artworkId = review.metadata?['artworkId'] as String?;
          await rejectContent(review.contentId, contentType, reason,
              artworkId: artworkId);

          // Update the review record
          final reviewDocRef =
              _firestore.collection('content_reviews').doc(review.id);
          batch.update(reviewDocRef, {
            'status': ReviewStatus.rejected.name,
            'reviewedAt': FieldValue.serverTimestamp(),
            'reviewedBy': user.uid,
            'rejectionReason': reason,
          });
        }

        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to bulk reject content: $e');
    }
  }

  /// Bulk delete content (admin only)
  Future<void> bulkDeleteContent(
    List<ContentReviewModel> contentReviews,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Group content by type for efficient batch operations
      final contentByType = <ContentType, List<ContentReviewModel>>{};
      for (final review in contentReviews) {
        contentByType.putIfAbsent(review.contentType, () => []).add(review);
      }

      // Process each content type separately
      for (final entry in contentByType.entries) {
        final contentType = entry.key;
        final reviews = entry.value;

        final batch = _firestore.batch();

        for (final review in reviews) {
          // Delete the actual content
          String collectionName;
          switch (contentType) {
            case ContentType.ads:
              collectionName = 'ads';
              break;
            case ContentType.captures:
              collectionName = 'captures';
              break;
            case ContentType.posts:
              collectionName = 'posts';
              break;
            case ContentType.comments:
              collectionName = 'comments';
              break;
            case ContentType.artwork:
              collectionName = 'artwork';
              break;
            case ContentType.chapters:
              // For chapters, we need special handling as they are subcollections
              // Using collectionGroup to find the specific document
              // Use 'id' field to avoid IllegalArgumentException with collectionGroup
              final chaptersQuery = await _firestore
                  .collectionGroup('chapters')
                  .where('id', isEqualTo: review.contentId)
                  .get();
              if (chaptersQuery.docs.isNotEmpty) {
                batch.delete(chaptersQuery.docs.first.reference);
              }
              collectionName = ''; // Handled separately
              break;
            case ContentType.all:
              continue; // Skip 'all' type
          }

          if (collectionName.isNotEmpty) {
            final contentDocRef =
                _firestore.collection(collectionName).doc(review.contentId);
            batch.delete(contentDocRef);
          }

          // Delete the review record
          final reviewDocRef =
              _firestore.collection('content_reviews').doc(review.id);
          batch.delete(reviewDocRef);

          // Log the deletion action
          await _logReviewAction(
              review.contentId, contentType, 'deleted', user.uid);
        }

        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to bulk delete content: $e');
    }
  }

  /// Get all content for admin management
  Future<List<ContentModel>> getAllContent({
    String? contentType,
    String? status,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection('content')
          .orderBy('createdAt', descending: true);

      if (contentType != null && contentType != 'all') {
        query = query.where('type', isEqualTo: contentType);
      }

      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ContentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get content: $e');
    }
  }

  /// Get content analytics
  Future<Map<String, dynamic>> getContentAnalytics({
    String? contentType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // This is a simplified version - in production you'd calculate real analytics
      final content = await getAllContent(contentType: contentType);

      return {
        'totalContent': content.length,
        'pendingReviews': content.where((c) => c.status == 'pending').length,
        'approvedContent': content.where((c) => c.status == 'approved').length,
        'rejectedContent': content.where((c) => c.status == 'rejected').length,
        'averageEngagement': content.isNotEmpty
            ? content.map((c) => c.engagementScore).reduce((a, b) => a + b) /
                content.length
            : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get content analytics: $e');
    }
  }

  /// Apply filters to a list of content reviews
  List<ContentReviewModel> _applyFilters(
    List<ContentReviewModel> reviews,
    ModerationFilters filters,
  ) {
    var filteredReviews = reviews;

    // Filter by status
    if (filters.status != null) {
      filteredReviews = filteredReviews
          .where((review) => review.status == filters.status)
          .toList();
    }

    // Filter by date range
    if (filters.dateFrom != null) {
      filteredReviews = filteredReviews
          .where((review) => review.createdAt.isAfter(filters.dateFrom!))
          .toList();
    }

    if (filters.dateTo != null) {
      filteredReviews = filteredReviews
          .where((review) => review.createdAt.isBefore(filters.dateTo!))
          .toList();
    }

    // Filter by search query (title, description, author name)
    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
      final query = filters.searchQuery!.toLowerCase();
      filteredReviews = filteredReviews.where((review) {
        return review.title.toLowerCase().contains(query) ||
            review.description.toLowerCase().contains(query) ||
            review.authorName.toLowerCase().contains(query);
      }).toList();
    }

    // Filter by user ID
    if (filters.userId != null && filters.userId!.isNotEmpty) {
      filteredReviews = filteredReviews
          .where((review) => review.authorId == filters.userId)
          .toList();
    }

    // Filter by author name
    if (filters.authorName != null && filters.authorName!.isNotEmpty) {
      final authorQuery = filters.authorName!.toLowerCase();
      filteredReviews = filteredReviews
          .where(
              (review) => review.authorName.toLowerCase().contains(authorQuery))
          .toList();
    }

    // Filter by flag reason (if available in metadata)
    if (filters.flagReason != null && filters.flagReason!.isNotEmpty) {
      filteredReviews = filteredReviews.where((review) {
        final flagReason = review.metadata?['flagReason'] as String?;
        return flagReason != null &&
            flagReason
                .toLowerCase()
                .contains(filters.flagReason!.toLowerCase());
      }).toList();
    }

    return filteredReviews;
  }

  /// Get content reviews with advanced filtering
  Future<List<ContentReviewModel>> getFilteredContentReviews(
    ModerationFilters filters,
  ) async {
    try {
      // Use the existing getPendingReviews method with filters
      return await getPendingReviews(
        contentType: filters.contentType,
        limit: filters.limit,
        filters: filters,
      );
    } catch (e) {
      throw Exception('Failed to get filtered content reviews: $e');
    }
  }

  /// Search content reviews by query
  Future<List<ContentReviewModel>> searchContentReviews(
    String query, {
    ContentType? contentType,
    int? limit,
  }) async {
    try {
      final filters = ModerationFilters(
        searchQuery: query,
        contentType: contentType,
        limit: limit,
      );

      return await getFilteredContentReviews(filters);
    } catch (e) {
      throw Exception('Failed to search content reviews: $e');
    }
  }

  /// Get content reviews by author
  Future<List<ContentReviewModel>> getContentReviewsByAuthor(
    String authorId, {
    ContentType? contentType,
    int? limit,
  }) async {
    try {
      final filters = ModerationFilters(
        userId: authorId,
        contentType: contentType,
        limit: limit,
      );

      return await getFilteredContentReviews(filters);
    } catch (e) {
      throw Exception('Failed to get content reviews by author: $e');
    }
  }

  /// Get content reviews by date range
  Future<List<ContentReviewModel>> getContentReviewsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    ContentType? contentType,
    int? limit,
  }) async {
    try {
      final filters = ModerationFilters(
        dateFrom: startDate,
        dateTo: endDate,
        contentType: contentType,
        limit: limit,
      );

      return await getFilteredContentReviews(filters);
    } catch (e) {
      throw Exception('Failed to get content reviews by date range: $e');
    }
  }

  /// Analyze content using AI for moderation assistance
  Future<ContentAnalysisResult> analyzeContentForModeration({
    required String contentId,
    required ContentType contentType,
    required String content,
    String? imageUrl,
    String? title,
    String? description,
  }) async {
    try {
      return await _analysisService.analyzeContent(
        contentId: contentId,
        contentType: contentType,
        content: content,
        imageUrl: imageUrl,
        title: title,
        description: description,
      );
    } catch (e) {
      throw Exception('Failed to analyze content: $e');
    }
  }

  /// Get AI analysis results for content review
  Future<ContentAnalysisResult?> getContentAnalysis(String contentId) async {
    try {
      final history = await _analysisService.getAnalysisHistory(contentId);
      return history.isNotEmpty ? history.first : null;
    } catch (e) {
      // Return null if analysis not found
      return null;
    }
  }

  /// Get pending reviews with AI analysis included
  Future<List<ContentReviewModel>> getPendingReviewsWithAIAnalysis({
    ContentType? contentType,
    int? limit,
    ModerationFilters? filters,
  }) async {
    final reviews = await getPendingReviews(
      contentType: contentType,
      limit: limit,
      filters: filters,
    );

    // Analyze each review with AI (in parallel for performance)
    final analysisFutures = reviews.map((review) async {
      try {
        final analysis = await analyzeContentForModeration(
          contentId: review.contentId,
          contentType: review.contentType,
          content: review.description,
          imageUrl: review.metadata?['imageUrl'] as String?,
          title: review.title,
          description: review.description,
        );

        // Add AI analysis to review metadata
        review.metadata?.addAll({
          'aiAnalysis': analysis.toJson(),
          'aiRecommendation': analysis.aiRecommendation.displayName,
          'riskScore': analysis.overallRiskScore,
          'qualityScore': analysis.qualityScore,
          'flags': analysis.flags.map((f) => f.toJson()).toList(),
        });

        return review;
      } catch (e) {
        // If AI analysis fails, return review without analysis
        review.metadata?.addAll({
          'aiAnalysis': null,
          'aiError': e.toString(),
        });
        return review;
      }
    });

    return Future.wait(analysisFutures);
  }

  /// Get AI analysis statistics for reporting
  Future<Map<String, dynamic>> getAIAnalysisStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _analysisService.getAnalysisStatistics(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Failed to get AI analysis statistics: $e');
    }
  }

  /// Bulk analyze multiple content items
  Future<List<ContentAnalysisResult>> bulkAnalyzeContent(
    List<Map<String, dynamic>> contentItems,
  ) async {
    final analysisFutures = contentItems.map((item) async {
      return analyzeContentForModeration(
        contentId: item['contentId'] as String,
        contentType: item['contentType'] as ContentType,
        content: item['content'] as String,
        imageUrl: item['imageUrl'] as String?,
        title: item['title'] as String?,
        description: item['description'] as String?,
      );
    });

    return Future.wait(analysisFutures);
  }
}
