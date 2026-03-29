import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/art_models.dart';
import '../models/comment_model.dart';
import '../models/group_models.dart';
import '../models/post_model.dart';
import '../models/artwork_model.dart' as community_artwork;
import 'community_social_activity_service.dart';

enum PostAppreciationResult {
  added,
  alreadyAppreciated,
  unauthenticated,
  postNotFound,
  error,
}

class PaginatedPostsResult<T> {
  const PaginatedPostsResult({required this.posts, required this.lastDocument});

  final List<T> posts;
  final DocumentSnapshot? lastDocument;
}

class CommunityService extends ChangeNotifier {
  CommunityService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    UserService? userService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _userService = userService ?? UserService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserService _userService;

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => currentUser?.uid;

  // Method to pick images for a post
  Future<List<File>> pickPostImages() async {
    // This is a placeholder.
    // Actual implementation would use image_picker or a similar package
    // to allow the user to select images from their gallery or camera.
    AppLogger.info('pickPostImages called - placeholder implementation');
    return []; // Return an empty list for now
  }

  // Get all posts
  Future<List<PostModel>> getPosts({int limit = 10, String? lastPostId}) async {
    try {
      Query query = _firestore
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastPostId != null) {
        // Get the last document for pagination
        final lastDocSnapshot = await _firestore
            .collection('posts')
            .doc(lastPostId)
            .get();
        query = query.startAfterDocument(lastDocSnapshot);
      }

      final querySnapshot = await query.get();

      // Load posts and add like status for current user (batched)
      final postIds = querySnapshot.docs.map((doc) => doc.id).toList();
      final likedPostIds = await _getLikedPostIds(postIds);
      return querySnapshot.docs.map((doc) {
        final post = PostModel.fromFirestore(doc);
        final isLiked = likedPostIds.contains(post.id);
        return post.copyWith(isLikedByCurrentUser: isLiked);
      }).toList();
    } catch (e) {
      AppLogger.error('Error getting posts: $e');
      return [];
    }
  }

  Future<PaginatedPostsResult<PostModel>> getPublicPostsPaginated({
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final posts = <PostModel>[];

      for (final doc in snapshot.docs) {
        var post = PostModel.fromFirestore(doc);
        if (post.userPhotoUrl.isEmpty && post.userId.isNotEmpty) {
          final user = await _userService.getUserById(post.userId);
          if (user != null) {
            post = post.copyWith(
              userPhotoUrl: user.profileImageUrl,
              isUserVerified: user.isVerified,
            );
          }
        }
        posts.add(post);
      }

      return PaginatedPostsResult(
        posts: posts,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      AppLogger.error('Error loading paginated public posts: $e');
      return const PaginatedPostsResult(posts: [], lastDocument: null);
    }
  }

  Future<PaginatedPostsResult<PostModel>> getTrendingPosts({
    required String timeFrame,
    required String category,
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      final now = DateTime.now();
      final cutoffDate = switch (timeFrame) {
        'Day' => now.subtract(const Duration(days: 1)),
        'Week' => now.subtract(const Duration(days: 7)),
        'Month' => DateTime(now.year, now.month - 1, now.day),
        _ => DateTime(2000),
      };

      Query<Map<String, dynamic>> query = _firestore
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate),
          )
          .orderBy('createdAt', descending: true);

      if (category != 'All') {
        query = query.where('tags', arrayContains: category.toLowerCase());
      }

      query = query.orderBy('applauseCount', descending: true).limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return PaginatedPostsResult(
        posts: snapshot.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList(growable: false),
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      AppLogger.error('Error loading trending posts: $e');
      return const PaginatedPostsResult(posts: [], lastDocument: null);
    }
  }

  Future<List<community_artwork.ArtworkModel>> getRecentArtworks({
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('artwork')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => community_artwork.ArtworkModel.fromFirestore(doc, null))
          .toList(growable: false);
    } catch (e) {
      AppLogger.error('Error loading recent artworks: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getOnlineArtists({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('artistProfiles')
          .where('isOnline', isEqualTo: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => _mapArtistProfileDoc(doc))
          .toList(growable: false);
    } catch (e) {
      AppLogger.error('Error loading online artists: $e');
      return [];
    }
  }

  Future<List<PostModel>> getRecentPublicPosts({int limit = 5}) {
    return getPosts(limit: limit);
  }

  Future<List<Map<String, dynamic>>> getFeaturedArtists({
    required SubscriptionService subscriptionService,
  }) async {
    try {
      final featuredArtists = await subscriptionService.getFeaturedArtists();
      final artists = <Map<String, dynamic>>[];

      for (final artist in featuredArtists) {
        artists.add({
          'id': artist.id,
          'userId': artist.userId,
          'name': artist.displayName,
          'specialty': _resolveArtistSpecialty(
            mediums: artist.mediums,
            styles: artist.styles,
            location: artist.location,
          ),
          'avatar': artist.profileImageUrl ?? '',
          'followers': await _getArtistFollowerCount(artist.id),
        });
      }

      return artists;
    } catch (e) {
      AppLogger.error('Error loading featured artists: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getVerifiedArtists({
    int limit = 10,
  }) async {
    return _getArtistProfilesByFlags(isVerified: true, limit: limit);
  }

  Future<List<Map<String, dynamic>>> getStandardArtists({
    int limit = 10,
  }) async {
    return _getArtistProfilesByFlags(
      isVerified: false,
      isFeatured: false,
      limit: limit,
    );
  }

  Stream<List<community_artwork.ArtworkModel>> watchMarketplaceArtworks({
    required String type,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('artwork')
        .where('isPublic', isEqualTo: true);

    if (type == 'sale') {
      query = query.where('isForSale', isEqualTo: true);
    } else if (type == 'auction') {
      query = query.where('auctionEnabled', isEqualTo: true);
    } else if (type == 'featured') {
      query = query.where('isFeatured', isEqualTo: true);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    community_artwork.ArtworkModel.fromFirestore(doc, null),
              )
              .toList(growable: false),
        );
  }

  Future<List<Map<String, dynamic>>> getTopGroups({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('groups')
          .orderBy('memberCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList(growable: false);
    } catch (e) {
      AppLogger.error('Error loading groups: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getArtistProfilesByFlags({
    required bool isVerified,
    bool? isFeatured,
    int limit = 10,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('artistProfiles')
          .where('isVerified', isEqualTo: isVerified);

      if (isFeatured != null) {
        query = query.where('isFeatured', isEqualTo: isFeatured);
      }

      final snapshot = await query.limit(limit).get();
      final artists = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final artist = _mapArtistProfileDoc(doc);
        artist['followers'] = await _getArtistFollowerCount(doc.id);
        artists.add(artist);
      }

      return artists;
    } catch (e) {
      AppLogger.error('Error loading artist profiles: $e');
      return [];
    }
  }

  Map<String, dynamic> _mapArtistProfileDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final mediums = (data['mediums'] as List<dynamic>? ?? [])
        .map((value) => value.toString())
        .toList(growable: false);
    final styles = (data['styles'] as List<dynamic>? ?? [])
        .map((value) => value.toString())
        .toList(growable: false);

    return {
      'id': doc.id,
      'userId': data['userId'] ?? '',
      'name': data['displayName'] ?? 'Unknown Artist',
      'specialty': _resolveArtistSpecialty(
        mediums: mediums,
        styles: styles,
        location: data['location'] as String?,
      ),
      'avatar': data['profileImageUrl'] ?? '',
      'isOnline': data['isOnline'] ?? false,
      'followers': 0,
    };
  }

  String _resolveArtistSpecialty({
    required List<String> mediums,
    required List<String> styles,
    String? location,
  }) {
    if (mediums.isNotEmpty) {
      return mediums.first;
    }
    if (styles.isNotEmpty) {
      return styles.first;
    }
    if (location != null && location.isNotEmpty) {
      return location;
    }
    return '';
  }

  Future<int> _getArtistFollowerCount(String artistProfileId) async {
    try {
      final followersSnapshot = await _firestore
          .collection('artistFollows')
          .where('artistProfileId', isEqualTo: artistProfileId)
          .get();
      return followersSnapshot.docs.length;
    } catch (e) {
      AppLogger.warning(
        'Error getting follower count for artist $artistProfileId: $e',
      );
      return 0;
    }
  }

  Future<String> createGroupForCurrentUser({
    required String name,
    required String description,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final groupRef = await _firestore.collection('groups').add({
      'name': name,
      'description': description,
      'createdBy': userId,
      'memberCount': 1,
      'postCount': 0,
      'color': '#8B5CF6',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('groupMembers').add({
      'groupId': groupRef.id,
      'userId': userId,
      'role': 'admin',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    return groupRef.id;
  }

  Future<List<CommunitySocialActivity>> getPersonalizedActivities({
    required String userId,
    CommunitySocialActivityService? socialActivityService,
    int directLimit = 10,
    int nearbyLimit = 10,
    double nearbyRadiusKm = 80.0,
  }) async {
    final activityService =
        socialActivityService ?? CommunitySocialActivityService();

    final activities = await activityService.getUserActivities(
      userId: userId,
      limit: directLimit,
    );

    if (activities.length >= 5) {
      return _filterNonFeedActivities(activities);
    }

    try {
      final userPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      final nearbyActivities = await activityService.getNearbyActivities(
        userPosition: userPosition,
        radiusKm: nearbyRadiusKm,
        limit: nearbyLimit,
      );

      final existingIds = activities.map((activity) => activity.id).toSet();
      for (final activity in nearbyActivities) {
        if (!existingIds.contains(activity.id)) {
          activities.add(activity);
        }
      }
    } catch (e) {
      AppLogger.warning('Error loading nearby activities: $e');
    }

    return _filterNonFeedActivities(activities);
  }

  List<CommunitySocialActivity> _filterNonFeedActivities(
    List<CommunitySocialActivity> activities,
  ) {
    return activities
        .where((activity) {
          final activityType = activity.type.toString().toLowerCase();
          final isRssFeed =
              activityType.contains('rss') ||
              activityType.contains('feed') ||
              activityType.contains('news');

          final message = activity.message.toLowerCase();
          final hasRssIndicators =
              message.contains('rss') ||
              message.contains('news feed') ||
              message.contains('political news') ||
              message.contains('news sports');

          return !isRssFeed && !hasRssIndicators;
        })
        .toList(growable: false);
  }

  // Get posts by user ID
  Future<List<PostModel>> getPostsByUserId(
    String userId, {
    int limit = 10,
    String? lastPostId,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastPostId != null) {
        final lastDocSnapshot = await _firestore
            .collection('posts')
            .doc(lastPostId)
            .get();
        query = query.startAfterDocument(lastDocSnapshot);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting posts by user ID: $e');
      return [];
    }
  }

  // Create a new post
  Future<String?> createPost({
    required String userId,
    required String userName,
    required String userPhotoUrl,
    required String content,
    required List<String> imageUrls,
    required List<String> tags,
    required String location,
    GeoPoint? geoPoint,
    String? zipCode,
    bool isPublic = true,
    List<String>? mentionedUsers,
    Map<String, dynamic>? metadata,
    String? groupType, // Add groupType parameter
  }) async {
    try {
      AppLogger.info('🔄 Creating post for user: $userId');
      AppLogger.info('📝 Post content: $content');
      AppLogger.info('🖼️ Image URLs: $imageUrls');
      AppLogger.info('🏷️ Tags: $tags');
      AppLogger.info('📍 Location: $location');
      AppLogger.info('👥 Group Type: $groupType');

      final docRef = await _firestore.collection('posts').add({
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'content': content,
        'imageUrls': imageUrls,
        'tags': tags,
        'location': location,
        'geoPoint': geoPoint,
        'zipCode': zipCode,
        'createdAt': FieldValue.serverTimestamp(),
        'applauseCount': 0,
        'commentCount': 0,
        'shareCount': 0,
        'isPublic': isPublic,
        'mentionedUsers': mentionedUsers,
        'metadata': metadata,
        'groupType':
            groupType ?? 'general', // Default to 'general' if not specified
      });

      AppLogger.info('✅ Post created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      AppLogger.error('❌ Error creating post: $e');
      AppLogger.info('📍 Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  Future<bool> isCurrentUserArtist() async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      final profile = await getArtistProfile(userId);
      return profile != null;
    } catch (e) {
      AppLogger.error('Error checking current user artist status: $e');
      return false;
    }
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;
    return _userService.getUserById(userId);
  }

  Future<String?> createEnhancedPostForCurrentUser({
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
    String? audioUrl,
    List<String> tags = const [],
    bool isArtistPost = false,
    String location = '',
    String? groupType,
    String? groupId,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final userModel = await _userService.getUserById(user.uid);
    if (userModel == null) {
      throw Exception('User profile not found');
    }

    final docRef = await _firestore.collection('posts').add({
      'userId': user.uid,
      'userName': userModel.fullName,
      'userPhotoUrl': userModel.profileImageUrl,
      'content': content,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'tags': tags,
      'location': location.isNotEmpty ? location : userModel.location,
      'createdAt': FieldValue.serverTimestamp(),
      'applauseCount': 0,
      'commentCount': 0,
      'shareCount': 0,
      'isPublic': true,
      'isUserVerified': userModel.isVerified,
      'groupType': groupType,
      if (groupId != null) 'groupId': groupId,
      'engagementStats': {
        'likeCount': 0,
        'commentCount': 0,
        'shareCount': 0,
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      'moderationStatus': 'approved',
      'flagged': false,
      'metadata': {'isArtistPost': isArtistPost},
    });

    return docRef.id;
  }

  // Delete a post
  Future<bool> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      return true;
    } catch (e) {
      AppLogger.error('Error deleting post: $e');
      return false;
    }
  }

  // Add a comment to a post
  Future<String?> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String userPhotoUrl,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      // Add the comment to Firestore
      final commentRef = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
            'userId': userId,
            'userName': userName,
            'userAvatarUrl': userPhotoUrl, // Changed to match the model
            'content': content,
            'createdAt': FieldValue.serverTimestamp(),
            'parentCommentId': parentCommentId ?? '',
            'type': 'Appreciation', // Add default type
          });

      // Update the comment count on the post
      await _firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      return commentRef.id;
    } catch (e) {
      AppLogger.error('Error adding comment: $e');
      AppLogger.error('Error type: ${e.runtimeType}');
      if (e.toString().contains('permission')) {
        AppLogger.error('Permission error details: $e');
        AppLogger.info('User ID: $userId');
        AppLogger.info('Post ID: $postId');
      }
      return null;
    }
  }

  Future<CommentModel?> addCommentForCurrentUser({
    required String postId,
    required String content,
    required String type,
    String parentCommentId = '',
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final userModel = await _userService.getUserById(user.uid);
    if (userModel == null) {
      throw Exception('User profile not found');
    }

    final commentRef = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
          'postId': postId,
          'userId': user.uid,
          'userName': userModel.fullName,
          'userAvatarUrl': userModel.profileImageUrl,
          'content': content,
          'type': type,
          'parentCommentId': parentCommentId,
          'createdAt': FieldValue.serverTimestamp(),
        });

    await _firestore.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(1),
      'engagementStats.commentCount': FieldValue.increment(1),
      'engagementStats.lastUpdated': FieldValue.serverTimestamp(),
    });

    return CommentModel(
      id: commentRef.id,
      postId: postId,
      userId: user.uid,
      userName: userModel.fullName,
      userAvatarUrl: userModel.profileImageUrl,
      content: content,
      type: type,
      parentCommentId: parentCommentId,
      createdAt: Timestamp.now(),
    );
  }

  // Get comments for a post
  Future<List<CommentModel>> getComments(
    String postId, {
    int limit = 50,
    String? lastCommentId,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt', descending: false) // Oldest first
          .limit(limit);

      if (lastCommentId != null) {
        final lastDocSnapshot = await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(lastCommentId)
            .get();
        query = query.startAfterDocument(lastDocSnapshot);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .where(
            (comment) => comment.parentCommentId.isEmpty,
          ) // Filter top-level comments
          .toList();
    } catch (e) {
      AppLogger.error('Error getting comments: $e');
      return [];
    }
  }

  // Get replies to a comment
  Future<List<CommentModel>> getReplies(
    String postId,
    String commentId, {
    int limit = 50,
    String? lastReplyId,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .where('parentCommentId', isEqualTo: commentId)
          .orderBy('createdAt', descending: false) // Oldest first
          .limit(limit);

      if (lastReplyId != null) {
        final lastDocSnapshot = await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(lastReplyId)
            .get();
        query = query.startAfterDocument(lastDocSnapshot);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting replies: $e');
      return [];
    }
  }

  Future<List<CommentModel>> getPostComments(String postId) {
    return getComments(postId);
  }

  Future<GroupType?> getGroupType(String groupId) async {
    try {
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) return null;
      final data = groupDoc.data();
      final groupTypeString = data?['groupType'] as String?;
      if (groupTypeString == null) return null;
      return GroupType.values.firstWhere(
        (value) => value.value == groupTypeString,
        orElse: () => GroupType.artist,
      );
    } catch (e) {
      AppLogger.error('Error loading group type: $e');
      return null;
    }
  }

  Future<List<PostModel>> getGroupPosts(
    String groupId, {
    int limit = 50,
  }) async {
    try {
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('groupId', isEqualTo: groupId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return postsSnapshot.docs
          .map(PostModel.fromDocument)
          .toList(growable: false);
    } catch (e) {
      AppLogger.error('Error loading group posts: $e');
      return [];
    }
  }

  Future<PaginatedPostsResult<BaseGroupPost>> getGroupTypePosts(
    GroupType groupType, {
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('posts')
          .where('groupType', isEqualTo: groupType.value)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final posts = snapshot.docs
          .map((doc) => _createGroupPostFromDocument(groupType, doc))
          .whereType<BaseGroupPost>()
          .toList(growable: false);

      return PaginatedPostsResult(
        posts: posts,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      AppLogger.error('Error loading ${groupType.value} posts: $e');
      return const PaginatedPostsResult(posts: [], lastDocument: null);
    }
  }

  Future<PaginatedPostsResult<ArtistGroupPost>> getArtistFeedPosts(
    String artistId, {
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('posts')
          .where('groupType', isEqualTo: GroupType.artist.value)
          .where('userId', isEqualTo: artistId)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final posts = snapshot.docs
          .map((doc) {
            try {
              return ArtistGroupPost.fromFirestore(doc);
            } catch (e) {
              AppLogger.error('Error parsing artist post ${doc.id}: $e');
              return null;
            }
          })
          .whereType<ArtistGroupPost>()
          .toList(growable: false);

      return PaginatedPostsResult(
        posts: posts,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      AppLogger.error('Error loading artist feed posts for $artistId: $e');
      return const PaginatedPostsResult(posts: [], lastDocument: null);
    }
  }

  Future<bool> isGroupMember(String groupId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      final membershipDoc = await _firestore
          .collection('groupMembers')
          .where('groupId', isEqualTo: groupId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      return membershipDoc.docs.isNotEmpty;
    } catch (e) {
      AppLogger.error('Error checking group membership: $e');
      return false;
    }
  }

  Future<void> joinGroup(String groupId) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _firestore.collection('groupMembers').add({
      'groupId': groupId,
      'userId': userId,
      'role': 'member',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('groups').doc(groupId).update({
      'memberCount': FieldValue.increment(1),
    });
  }

  Future<void> leaveGroup(String groupId) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final membershipDocs = await _firestore
        .collection('groupMembers')
        .where('groupId', isEqualTo: groupId)
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in membershipDocs.docs) {
      await doc.reference.delete();
    }

    await _firestore.collection('groups').doc(groupId).update({
      'memberCount': FieldValue.increment(-1),
    });
  }

  Future<ArtistProfile?> getArtistProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('artistProfiles')
          .doc(userId)
          .get();
      if (!doc.exists) return null;
      return ArtistProfile.fromFirestore(doc);
    } catch (e) {
      AppLogger.error('Error getting artist profile: $e');
      return null;
    }
  }

  Future<PostAppreciationResult> appreciatePost(String postId) async {
    final userId = currentUserId;
    if (userId == null) {
      return PostAppreciationResult.unauthenticated;
    }

    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final appreciationRef = postRef.collection('appreciations').doc(userId);

      return await _firestore.runTransaction<PostAppreciationResult>((
        transaction,
      ) async {
        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) {
          return PostAppreciationResult.postNotFound;
        }

        final appreciationSnapshot = await transaction.get(appreciationRef);
        if (appreciationSnapshot.exists) {
          return PostAppreciationResult.alreadyAppreciated;
        }

        final currentCount =
            (postSnapshot.data()?['applauseCount'] as int?) ?? 0;
        transaction.update(postRef, {
          'applauseCount': currentCount + 1,
          'engagementStats.likeCount': FieldValue.increment(1),
          'engagementStats.lastUpdated': FieldValue.serverTimestamp(),
        });
        transaction.set(appreciationRef, {
          'userId': userId,
          'postId': postId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return PostAppreciationResult.added;
      });
    } catch (e) {
      AppLogger.error('Error appreciating post $postId: $e');
      return PostAppreciationResult.error;
    }
  }

  Future<bool> featurePost(String postId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final postDoc = await postRef.get();
      if (!postDoc.exists) {
        return false;
      }

      await postRef.update({'isFeatured': true});
      return true;
    } catch (e) {
      AppLogger.error('Error featuring post $postId: $e');
      return false;
    }
  }

  Future<void> incrementPostShareCount(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'shareCount': FieldValue.increment(1),
        'engagementStats.shareCount': FieldValue.increment(1),
        'engagementStats.lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Error incrementing share count for post $postId: $e');
    }
  }

  Future<List<CommentModel>> getAllCommentsForPost(String postId) async {
    try {
      final commentsSnapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .get();

      return commentsSnapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList(growable: false);
    } catch (e) {
      AppLogger.error('Error loading all comments for post $postId: $e');
      return [];
    }
  }

  Future<CommentModel?> addDetailedCommentForCurrentUser({
    required String postId,
    required String content,
    String parentCommentId = '',
  }) {
    return addCommentForCurrentUser(
      postId: postId,
      content: content,
      type: 'Appreciation',
      parentCommentId: parentCommentId,
    );
  }

  Future<bool> reportComment({
    required String postId,
    required String commentId,
  }) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .update({'isReported': true});
      return true;
    } catch (e) {
      AppLogger.error(
        'Error reporting comment $commentId for post $postId: $e',
      );
      return false;
    }
  }

  BaseGroupPost? _createGroupPostFromDocument(
    GroupType groupType,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    try {
      switch (groupType) {
        case GroupType.artist:
          return ArtistGroupPost.fromFirestore(doc);
        case GroupType.event:
          return EventGroupPost.fromFirestore(doc);
        case GroupType.artWalk:
          return ArtWalkAdventurePost.fromFirestore(doc);
        case GroupType.artistWanted:
          return ArtistWantedPost.fromFirestore(doc);
      }
    } catch (e) {
      AppLogger.error('Error creating ${groupType.value} post ${doc.id}: $e');
      return null;
    }
  }

  // Get unread posts count for the current user
  Stream<int> getUnreadPostsCount(String userId) {
    try {
      return _firestore
          .collection('user_activity')
          .doc(userId)
          .snapshots()
          .asyncMap((doc) async {
            if (!doc.exists) {
              // If no user activity doc exists, count all posts as unread
              final postsSnapshot = await _firestore
                  .collection('posts')
                  .where('isPublic', isEqualTo: true)
                  .get();
              return postsSnapshot.docs.length;
            }

            final data = doc.data()!;
            final lastSeenTimestamp = data['lastCommunityVisit'] as Timestamp?;

            if (lastSeenTimestamp == null) {
              // If never visited, count all posts as unread
              final postsSnapshot = await _firestore
                  .collection('posts')
                  .where('isPublic', isEqualTo: true)
                  .get();
              return postsSnapshot.docs.length;
            }

            // Count posts created after last visit
            final unreadPostsSnapshot = await _firestore
                .collection('posts')
                .where('isPublic', isEqualTo: true)
                .where('createdAt', isGreaterThan: lastSeenTimestamp)
                .get();

            return unreadPostsSnapshot.docs.length;
          });
    } catch (e) {
      AppLogger.error('Error getting unread posts count: $e');
      return Stream.value(0);
    }
  }

  // Mark community as visited (reset unread count)
  Future<void> markCommunityAsVisited(String userId) async {
    try {
      await _firestore.collection('user_activity').doc(userId).set({
        'lastCommunityVisit': FieldValue.serverTimestamp(),
        'userId': userId,
      }, SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('Error marking community as visited: $e');
    }
  }

  // Toggle like for a post
  Future<bool> toggleLike(String postId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        AppLogger.error('User not authenticated for like action');
        return false;
      }

      // Reference to the post document
      final postRef = _firestore.collection('posts').doc(postId);

      // Reference to the user's like document
      final likeRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId);

      // Use a transaction to ensure consistency
      return await _firestore.runTransaction<bool>((transaction) async {
        // Check if user has already liked this post
        final likeDoc = await transaction.get(likeRef);
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final postData = postDoc.data() as Map<String, dynamic>;
        final currentLikeCount =
            (postData['engagementStats']?['likeCount'] ?? 0) as int;

        if (likeDoc.exists) {
          // User has liked - remove like
          transaction.delete(likeRef);
          transaction.update(postRef, {
            'engagementStats.likeCount': currentLikeCount > 0
                ? currentLikeCount - 1
                : 0,
            'engagementStats.lastUpdated': FieldValue.serverTimestamp(),
          });
          AppLogger.info('Removed like for post $postId by user $userId');
          return true; // Changed from false to true - operation succeeded
        } else {
          // User hasn't liked - add like
          transaction.set(likeRef, {
            'userId': userId,
            'likedAt': FieldValue.serverTimestamp(),
          });
          transaction.update(postRef, {
            'engagementStats.likeCount': currentLikeCount + 1,
            'engagementStats.lastUpdated': FieldValue.serverTimestamp(),
          });
          AppLogger.info('Added like for post $postId by user $userId');
          return true; // true = liked
        }
      });
    } catch (e) {
      AppLogger.error('Error toggling like for post $postId: $e');
      return false;
    }
  }

  // Check if current user has liked a post
  Future<bool> hasUserLikedPost(String postId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;

      final likeDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .get();

      return likeDoc.exists;
    } catch (e) {
      AppLogger.error('Error checking if user liked post $postId: $e');
      return false;
    }
  }

  Future<Set<String>> _getLikedPostIds(List<String> postIds) async {
    if (postIds.isEmpty) return {};
    final userId = currentUserId;
    if (userId == null) return {};

    try {
      final snapshot = await _firestore
          .collectionGroup('likes')
          .where('userId', isEqualTo: userId)
          .get();

      final likedPostIds = <String>{};
      for (final doc in snapshot.docs) {
        final postId = doc.reference.parent.parent?.id;
        if (postId != null && postIds.contains(postId)) {
          likedPostIds.add(postId);
        }
      }
      return likedPostIds;
    } catch (e) {
      AppLogger.error('Error loading liked posts for user: $e');
      return {};
    }
  }

  // Get users who liked a post
  Future<List<String>> getPostLikes(String postId) async {
    try {
      final likesSnapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .get();

      return likesSnapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();
    } catch (e) {
      AppLogger.error('Error getting likes for post $postId: $e');
      return [];
    }
  }
}
