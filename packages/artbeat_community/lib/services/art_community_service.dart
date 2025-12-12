import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/art_models.dart';
import '../models/post_model.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Unified service for art community operations
/// Simplified and focused on core art-sharing functionality
class ArtCommunityService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // RSS feed URLs
  static const List<String> _rssFeedUrls = [
    'https://www.neusenews.com/index?format=rss',
    'https://www.neusenewssports.com/news-1?format=rss',
    'https://www.ncpoliticalnews.com/news?format=rss',
  ];

  // Stream controllers for real-time updates
  final StreamController<List<ArtPost>> _feedController =
      StreamController.broadcast();
  final StreamController<List<ArtistProfile>> _artistsController =
      StreamController.broadcast();

  Stream<List<ArtPost>> get feedStream => _feedController.stream;
  Stream<List<ArtistProfile>> get artistsStream => _artistsController.stream;

  /// Get current cached artists (synchronous)
  List<ArtistProfile> getArtists({int limit = 20}) {
    return _artistsCache.take(limit).toList();
  }

  /// Get artists from Firestore (async)
  Future<List<ArtistProfile>> fetchArtists({int limit = 20}) async {
    try {
      AppLogger.info('🎨 Fetching artists from Firestore...');

      final snapshot = await _firestore.collection('users').limit(100).get();

      AppLogger.info('🎨 Query returned ${snapshot.docs.length} documents');

      final artists = <ArtistProfile>[];
      final currentUser = FirebaseAuth.instance.currentUser;

      for (final doc in snapshot.docs) {
        final userData = doc.data();
        final userType = userData['userType'] as String?;
        AppLogger.info(
          '🎨 Processing user doc: ${doc.id}, userType=${userType}, fullName=${userData['fullName']}',
        );

        // Check if user has an artist profile
        DocumentSnapshot? artistProfileDoc;
        try {
          final profileQuery = await _firestore
              .collection('artistProfiles')
              .where('userId', isEqualTo: doc.id)
              .limit(1)
              .get();

          if (profileQuery.docs.isNotEmpty) {
            artistProfileDoc = profileQuery.docs.first;
            AppLogger.info('🎨 User ${doc.id} has detailed artist profile');
          }
        } catch (e) {
          AppLogger.warning(
            '🎨 Could not check artist profile for ${doc.id}: $e',
          );
        }

        // Only process users who are artists (have userType 'artist' or have artistProfile)
        final bool isArtist = userType == 'artist' || artistProfileDoc != null;
        if (!isArtist) {
          AppLogger.info('🎨 Skipping user ${doc.id} - not an artist');
          continue;
        }

        try {
          // Use artist profile document if available, otherwise use user document
          final sourceDoc = artistProfileDoc ?? doc;
          final artist = ArtistProfile.fromFirestore(sourceDoc);

          // Check if portfolio images are empty, try to fetch from artworks
          List<String> portfolioImages = artist.portfolioImages;
          if (portfolioImages.isEmpty) {
            try {
              final artworksSnapshot = await _firestore
                  .collection('artworks')
                  .where('artistId', isEqualTo: artist.userId)
                  .orderBy('createdAt', descending: true)
                  .limit(3)
                  .get();

              portfolioImages = artworksSnapshot.docs
                  .map((artworkDoc) {
                    final data = artworkDoc.data();
                    final imageUrl = data['imageUrl'] as String?;
                    if (imageUrl != null && imageUrl.isNotEmpty) {
                      return imageUrl;
                    }
                    // Also check for images array
                    final images = data['images'] as List?;
                    if (images != null && images.isNotEmpty) {
                      final firstImage = images.first as String?;
                      if (firstImage != null && firstImage.isNotEmpty) {
                        return firstImage;
                      }
                    }
                    return null;
                  })
                  .whereType<String>()
                  .toList();
            } catch (e) {
              AppLogger.warning(
                '🎨 Could not fetch artworks for ${artist.displayName}: $e',
              );
            }
          }

          // Check if current user is following this artist and get updated follower count
          bool isFollowing = false;
          int updatedFollowersCount = artist.followersCount;

          if (currentUser != null && currentUser.uid != artist.userId) {
            try {
              final followDoc = await _firestore
                  .collection('follows')
                  .doc('${currentUser.uid}_${artist.userId}')
                  .get();
              isFollowing = followDoc.exists;
            } catch (e) {
              AppLogger.warning(
                '🎨 Could not check follow status for ${artist.displayName}: $e',
              );
            }
          }

          // Get updated follower count from users collection
          try {
            final userDoc = await _firestore
                .collection('users')
                .doc(artist.userId)
                .get();
            if (userDoc.exists) {
              final userData = userDoc.data() ?? {};
              updatedFollowersCount =
                  userData['followersCount'] as int? ?? artist.followersCount;
            }
          } catch (e) {
            AppLogger.warning(
              '🎨 Could not get updated follower count for ${artist.displayName}: $e',
            );
          }

          // Create artist with portfolio images, follow status, and updated follower count
          final artistWithData = artist.copyWith(
            portfolioImages: portfolioImages,
            isFollowedByCurrentUser: isFollowing,
            followersCount: updatedFollowersCount,
          );

          AppLogger.info(
            '🎨 Loaded artist: ${artistWithData.displayName}, avatar: ${artistWithData.avatarUrl}, portfolio: ${artistWithData.portfolioImages.length} images, following: $isFollowing, followers: $updatedFollowersCount',
          );

          artists.add(artistWithData);
        } catch (e) {
          AppLogger.error('🎨 Error parsing artist doc ${doc.id}: $e');
        }
      }

      AppLogger.info('🎨 Successfully loaded ${artists.length} artists');
      _artistsCache = artists;
      return artists;
    } catch (e) {
      AppLogger.error('🎨 Error fetching artists: $e');
      return [];
    }
  }

  // Cache for performance
  List<ArtPost> _feedCache = [];
  List<ArtistProfile> _artistsCache = [];

  ArtCommunityService() {
    _initializeStreams();
  }

  void _initializeStreams() {
    // Set up real-time listeners for feed
    _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
          _feedCache = snapshot.docs
              .map((doc) => ArtPost.fromFirestore(doc))
              .toList();
          _feedController.add(_feedCache);
        });

    // Set up real-time listeners for artists
    _firestore
        .collection('users')
        .where('userType', isEqualTo: 'artist')
        .snapshots()
        .listen((snapshot) {
          _artistsCache = snapshot.docs
              .map((doc) => ArtistProfile.fromFirestore(doc))
              .toList();
          _artistsController.add(_artistsCache);
        });
  }

  /// Get paginated feed posts
  Future<List<PostModel>> getFeed({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      // Load posts and add like status for current user
      final posts = <PostModel>[];
      for (final doc in snapshot.docs) {
        final post = PostModel.fromFirestore(doc);
        final isLiked = await hasUserLikedPost(post.id);
        final postWithLikeStatus = post.copyWith(isLikedByCurrentUser: isLiked);
        posts.add(postWithLikeStatus);
      }

      // Fetch RSS posts and add them to the feed
      final rssPosts = await _fetchRssPosts();
      posts.addAll(rssPosts);

      // Sort combined posts by createdAt (newest first)
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Limit to requested number
      if (posts.length > limit) {
        posts.removeRange(limit, posts.length);
      }

      // Debug: Log the retrieved posts
      if (kDebugMode) {
        print(
          '📱 DEBUG: Retrieved ${posts.length} posts from Firestore and RSS',
        );
        for (int i = 0; i < posts.length; i++) {
          final post = posts[i];
          print(
            '📱 Post $i: "${post.content}" with ${post.imageUrls.length} images',
          );
          if (post.imageUrls.isNotEmpty) {
            print('📱   First image URL: ${post.imageUrls.first}');
          }
        }
      }

      return posts;
    } catch (e) {
      AppLogger.error('Error getting feed: $e');
      return [];
    }
  }

  /// Fetch RSS posts from configured feeds
  Future<List<PostModel>> _fetchRssPosts() async {
    final rssPosts = <PostModel>[];

    for (final url in _rssFeedUrls) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final document = xml.XmlDocument.parse(response.body);
          final items = document.findAllElements('item');

          for (final item in items.take(5)) {
            // Limit to 5 items per feed
            final title =
                item.findElements('title').firstOrNull?.innerText ?? '';
            final description =
                item.findElements('description').firstOrNull?.innerText ?? '';
            final contentEncoded =
                item.findElements('content:encoded').firstOrNull?.innerText ??
                '';
            final pubDate =
                item.findElements('pubDate').firstOrNull?.innerText ?? '';

            // Parse publication date
            DateTime createdAt;
            try {
              createdAt = DateTime.parse(pubDate);
            } catch (e) {
              createdAt = DateTime.now().subtract(
                const Duration(hours: 1),
              ); // Fallback
            }

            // Extract image URLs from description, content:encoded, and media:content
            final imageUrls = <String>[];

            // From description
            final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
            final descMatch = imgRegex.firstMatch(description);
            if (descMatch != null) {
              final url = descMatch.group(1)!;
              if (url.isNotEmpty) {
                imageUrls.add(url);
              }
            }

            // From content:encoded
            final contentMatch = imgRegex.firstMatch(contentEncoded);
            if (contentMatch != null) {
              final url = contentMatch.group(1)!;
              if (url.isNotEmpty && !imageUrls.contains(url)) {
                imageUrls.add(url);
              }
            }

            // From media:content
            final mediaContents = item.findAllElements('media:content');
            for (final media in mediaContents) {
              final mediaUrl = media.getAttribute('url');
              if (mediaUrl != null &&
                  mediaUrl.isNotEmpty &&
                  !imageUrls.contains(mediaUrl)) {
                imageUrls.add(mediaUrl);
              }
            }

            // Use description for excerpt content
            final rawContent = description;

            // Clean HTML from content, preserving paragraph breaks
            String cleanContent = rawContent;
            // Replace paragraph and line break tags with spaces (to avoid unwanted line breaks)
            cleanContent = cleanContent.replaceAll('</p>', ' ');
            cleanContent = cleanContent.replaceAll('</div>', ' ');
            cleanContent = cleanContent.replaceAll('<br>', ' ');
            cleanContent = cleanContent.replaceAll('<br/>', ' ');
            cleanContent = cleanContent.replaceAll('<br />', ' ');
            // Remove all remaining HTML tags
            cleanContent = cleanContent.replaceAll(RegExp(r'<[^>]*>'), '');
            // Replace any remaining newlines with spaces and clean up multiple spaces
            cleanContent = cleanContent
                .replaceAll('\n', ' ')
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();

            // Truncate to approximately 4 lines (300 chars), ending at sentence if possible
            String truncatedContent = cleanContent;
            const int maxLength = 300;
            if (cleanContent.length > maxLength) {
              final String candidate = cleanContent.substring(0, maxLength);
              final int lastPeriod = candidate.lastIndexOf('.');
              if (lastPeriod > maxLength * 0.5) {
                truncatedContent = cleanContent.substring(0, lastPeriod + 1);
              } else {
                final int lastSpace = candidate.lastIndexOf(' ');
                if (lastSpace > 0) {
                  truncatedContent =
                      '${cleanContent.substring(0, lastSpace)}...';
                } else {
                  truncatedContent = '$candidate...';
                }
              }
            }

            final rssPost = PostModel(
              id: 'rss_${url.hashCode}_${title.hashCode}',
              userId: 'rss_feed',
              userName: _getFeedName(url),
              userPhotoUrl: '', // Could add a default RSS icon
              content: title.isNotEmpty
                  ? '$title\n\n$truncatedContent'
                  : truncatedContent,
              imageUrls: imageUrls,
              tags: ['news', 'rss'],
              location: '',
              createdAt: createdAt,
              isPublic: true,
              isUserVerified: true,
              moderationStatus: PostModerationStatus.approved,
              flagged: false,
              isLikedByCurrentUser: false,
            );

            rssPosts.add(rssPost);
          }
        }
      } catch (e) {
        AppLogger.error('Error fetching RSS from $url: $e');
      }
    }

    return rssPosts;
  }

  /// Get display name for RSS feed
  String _getFeedName(String url) {
    if (url.contains('neusenews.com')) {
      return 'Neuse News';
    } else if (url.contains('neusenewssports.com')) {
      return 'Neuse News Sports';
    } else if (url.contains('ncpoliticalnews.com')) {
      return 'NC Political News';
    }
    return 'News Feed';
  }

  /// Get posts by specific artist
  Future<List<ArtPost>> getArtistPosts(
    String artistId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: artistId)
          .where('isArtistPost', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('Error getting artist posts: $e');
      return [];
    }
  }

  /// Get posts by topic/tag
  Future<List<ArtPost>> getPostsByTopic(String topic, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('tags', arrayContains: topic)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('Error getting posts by topic: $e');
      return [];
    }
  }

  /// Create a new art post
  Future<String?> createPost({
    required String content,
    required List<String> imageUrls,
    List<String> tags = const [],
    bool isArtistPost = false,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Get user profile data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final post = ArtPost(
        id: '', // Will be set by Firestore
        userId: user.uid,
        userName:
            userData['displayName'] as String? ??
            userData['name'] as String? ??
            'Anonymous',
        userAvatarUrl: userData['profileImageUrl'] as String? ?? '',
        content: content,
        imageUrls: imageUrls,
        tags: tags,
        createdAt: DateTime.now(),
        isArtistPost: isArtistPost,
        isUserVerified: userData['isVerified'] as bool? ?? false,
      );

      // Debug: Log the post data being saved
      if (kDebugMode) {
        print('🔥 DEBUG: Saving post to Firestore:');
        print('🔥 Content: $content');
        print('🔥 Image URLs (${imageUrls.length}): $imageUrls');
        print('🔥 Tags: $tags');
        final firestoreData = post.toFirestore();
        print('🔥 Firestore data: $firestoreData');
      }

      final docRef = await _firestore
          .collection('posts')
          .add(post.toFirestore());
      AppLogger.info('Created post: ${docRef.id}');

      // Debug: Verify the post was saved correctly
      if (kDebugMode) {
        final savedDoc = await docRef.get();
        final savedData = savedDoc.data();
        print('🔥 DEBUG: Verified saved post data: $savedData');
      }

      return docRef.id;
    } catch (e) {
      AppLogger.error('Error creating post: $e');
      return null;
    }
  }

  /// Create an enhanced post with multimedia support
  Future<String?> createEnhancedPost({
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
    String? audioUrl,
    List<String> tags = const [],
    bool isArtistPost = false,
    PostModerationStatus moderationStatus = PostModerationStatus.approved,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Get user profile data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final post = PostModel(
        id: '', // Will be set by Firestore
        userId: user.uid,
        userName:
            userData['displayName'] as String? ??
            userData['name'] as String? ??
            userData['fullName'] as String? ??
            user.displayName ??
            'Anonymous',
        userPhotoUrl: userData['profileImageUrl'] as String? ?? '',
        content: content,
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        audioUrl: audioUrl,
        tags: tags,
        location: userData['location'] as String? ?? '',
        createdAt: DateTime.now(),
        engagementStats: EngagementStats(lastUpdated: DateTime.now()),
        isPublic: true,
        isUserVerified: userData['isVerified'] as bool? ?? false,
        moderationStatus: moderationStatus,
        flagged: moderationStatus != PostModerationStatus.approved,
      );

      // Debug: Log the enhanced post data being saved
      if (kDebugMode) {
        print('🔥 DEBUG: Saving enhanced post to Firestore:');
        print('🔥 Content: $content');
        print('🔥 Image URLs (${imageUrls.length}): $imageUrls');
        print('🔥 Video URL: $videoUrl');
        print('🔥 Audio URL: $audioUrl');
        print('🔥 Tags: $tags');
        print('🔥 Moderation Status: ${moderationStatus.value}');
      }

      // Save to posts collection
      final docRef = await _firestore
          .collection('posts')
          .add(post.toFirestore());

      // Also save to user_posts collection for easy user post retrieval
      await _firestore
          .collection('user_posts')
          .doc(user.uid)
          .collection('posts')
          .doc(docRef.id)
          .set({
            'postId': docRef.id,
            'createdAt': Timestamp.fromDate(DateTime.now()),
            'moderationStatus': moderationStatus.value,
            'isArtistPost': isArtistPost,
            'hasImages': imageUrls.isNotEmpty,
            'hasVideo': videoUrl != null,
            'hasAudio': audioUrl != null,
            'tagCount': tags.length,
          });

      AppLogger.info('Created enhanced post: ${docRef.id}');

      return docRef.id;
    } catch (e) {
      AppLogger.error('Error creating enhanced post: $e');
      return null;
    }
  }

  /// Like/unlike a post
  Future<bool> toggleLike(String postId) async {
    try {
      AppLogger.info(
        '🤍 ArtCommunityService.toggleLike called for postId: $postId',
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.error('🤍 No authenticated user found');
        return false;
      }

      AppLogger.info('🤍 Authenticated user: ${user.uid}');

      final likeRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(user.uid);

      AppLogger.info('🤍 Checking if like document exists...');
      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // Unlike
        AppLogger.info('🤍 User has already liked this post, unliking...');
        await likeRef.delete();
        await _updateLikeCount(postId, -1);
        AppLogger.info('🤍 Unlike completed successfully');
        return true; // Changed from false to true - operation succeeded
      } else {
        // Like
        AppLogger.info('🤍 User hasn\'t liked this post, liking...');
        await likeRef.set({'userId': user.uid, 'createdAt': Timestamp.now()});
        await _updateLikeCount(postId, 1);
        AppLogger.info('🤍 Like completed successfully');
        return true;
      }
    } catch (e) {
      AppLogger.error('Error toggling like: $e');
      return false;
    }
  }

  Future<void> _updateLikeCount(String postId, int change) async {
    try {
      AppLogger.info('🤍 Updating like count for post $postId by $change');

      final postRef = _firestore.collection('posts').doc(postId);
      await postRef.update({
        'engagementStats.likeCount': FieldValue.increment(change),
        'engagementStats.lastUpdated': FieldValue.serverTimestamp(),
      });

      AppLogger.info('🤍 Like count update completed successfully');
    } catch (e) {
      AppLogger.error('🤍 Error updating like count: $e');
    }
  }

  /// Check if current user has liked a post
  Future<bool> hasUserLikedPost(String postId) async {
    try {
      AppLogger.info('🤍 Checking if user has liked post: $postId');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.info('🤍 No authenticated user, returning false');
        return false;
      }

      final likeDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(user.uid)
          .get();

      final hasLiked = likeDoc.exists;
      AppLogger.info(
        '🤍 User ${user.uid} has ${hasLiked ? 'liked' : 'not liked'} post $postId',
      );
      return hasLiked;
    } catch (e) {
      AppLogger.error('Error checking if user liked post $postId: $e');
      return false;
    }
  }

  /// Get comments for a post
  Future<List<ArtComment>> getComments(String postId, {int limit = 10}) async {
    try {
      AppLogger.info('💬 Getting comments for post: $postId');

      // First, let's try a simple query without orderBy to see if that's the issue
      AppLogger.info('💬 Trying simple query without orderBy...');
      final simpleSnapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .get();

      AppLogger.info(
        '💬 Simple query returned ${simpleSnapshot.docs.length} documents',
      );

      // Debug: Log simple query results
      if (simpleSnapshot.docs.isNotEmpty) {
        for (int i = 0; i < simpleSnapshot.docs.length && i < 3; i++) {
          final doc = simpleSnapshot.docs[i];
          final data = doc.data();
          AppLogger.info(
            '💬 Simple query result ${i}: postId="${data['postId']}", content="${data['content']}"',
          );
        }
      }

      // Try top-level comments collection first
      final snapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      AppLogger.info(
        '💬 Top-level comments query returned ${snapshot.docs.length} documents',
      );

      // Debug: Log the query details
      AppLogger.info('💬 Query details: postId="$postId", limit=$limit');

      final List<ArtComment> comments = [];

      // Debug: If no comments found, let's see what post IDs exist in the comments collection
      if (snapshot.docs.isEmpty) {
        AppLogger.info(
          '💬 No comments found for postId: "$postId", checking what post IDs exist...',
        );
        final allCommentsSnapshot = await _firestore
            .collection('comments')
            .limit(10)
            .get();
        AppLogger.info(
          '💬 Found ${allCommentsSnapshot.docs.length} total comments in collection',
        );
        for (final doc in allCommentsSnapshot.docs) {
          final data = doc.data();
          AppLogger.info(
            '💬 Comment ${doc.id} has postId: "${data['postId']}"',
          );
        }
      }

      if (snapshot.docs.isNotEmpty) {
        // Debug: Log the first few documents
        for (int i = 0; i < snapshot.docs.length && i < 3; i++) {
          final doc = snapshot.docs[i];
          AppLogger.info('💬 Comment doc ${i}: ${doc.id} - ${doc.data()}');
        }

        // Parse comments with error handling
        for (final doc in snapshot.docs) {
          try {
            final data = doc.data();
            AppLogger.info('💬 Raw comment data: $data');
            final comment = ArtComment.fromFirestore(doc);
            AppLogger.info('💬 Parsed comment userName: "${comment.userName}"');
            comments.add(comment);
            AppLogger.info(
              '💬 Successfully parsed comment: ${comment.id} - "${comment.content}" by ${comment.userName}',
            );
          } catch (e) {
            AppLogger.error('💬 Failed to parse comment ${doc.id}: $e');
          }
        }
      } else {
        // Try subcollection structure as fallback
        AppLogger.info(
          '💬 No comments in top-level collection, trying subcollection...',
        );
        final subcollectionSnapshot = await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();

        AppLogger.info(
          '💬 Subcollection query returned ${subcollectionSnapshot.docs.length} documents',
        );

        if (subcollectionSnapshot.docs.isNotEmpty) {
          // Debug: Log the first few documents
          for (int i = 0; i < subcollectionSnapshot.docs.length && i < 3; i++) {
            final doc = subcollectionSnapshot.docs[i];
            AppLogger.info(
              '💬 Subcollection comment doc ${i}: ${doc.id} - ${doc.data()}',
            );
          }

          // Parse subcollection comments with error handling
          for (final doc in subcollectionSnapshot.docs) {
            try {
              final comment = ArtComment.fromFirestore(doc);
              comments.add(comment);
              AppLogger.info(
                '💬 Successfully parsed subcollection comment: ${comment.id} - "${comment.content}"',
              );
            } catch (e) {
              AppLogger.error(
                '💬 Failed to parse subcollection comment ${doc.id}: $e',
              );
            }
          }
        }
      }

      AppLogger.info(
        '💬 Retrieved ${comments.length} comments for post $postId',
      );

      return comments;
    } catch (e) {
      AppLogger.error('Error getting comments: $e');
      return [];
    }
  }

  /// Add comment to a post
  Future<String?> addComment(String postId, String content) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      AppLogger.info('💬 User data for comment: $userData');
      AppLogger.info(
        '💬 fullName: "${userData['fullName']}", displayName: "${userData['displayName']}", name: "${userData['name']}"',
      );

      final comment = ArtComment(
        id: '',
        postId: postId,
        userId: user.uid,
        userName:
            userData['fullName'] as String? ??
            userData['displayName'] as String? ??
            userData['name'] as String? ??
            'Anonymous',
        userAvatarUrl: userData['profileImageUrl'] as String? ?? '',
        content: content,
        createdAt: DateTime.now(),
      );

      AppLogger.info('💬 Comment userName will be: "${comment.userName}"');

      final docRef = await _firestore
          .collection('comments')
          .add(comment.toFirestore());

      // Update comment count
      await _firestore.collection('posts').doc(postId).update({
        'engagementStats.commentCount': FieldValue.increment(1),
        'engagementStats.lastUpdated': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      AppLogger.error('Error adding comment: $e');
      return null;
    }
  }

  /// Get artist profile
  Future<ArtistProfile?> getArtistProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('artistProfiles')
          .doc(userId)
          .get();
      if (doc.exists) {
        return ArtistProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting artist profile: $e');
      return null;
    }
  }

  /// Create or update artist profile
  Future<bool> updateArtistProfile(ArtistProfile profile) async {
    try {
      await _firestore
          .collection('artistProfiles')
          .doc(profile.userId)
          .set(profile.toFirestore());
      return true;
    } catch (e) {
      AppLogger.error('Error updating artist profile: $e');
      return false;
    }
  }

  /// Get popular topics/tags
  Future<List<String>> getPopularTopics({int limit = 10}) async {
    try {
      // This would typically use aggregation, but for simplicity we'll get recent posts
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      final allTags = <String>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final tags = List<String>.from(data['tags'] as Iterable? ?? []);
        allTags.addAll(tags);
      }

      // Count frequency and return most popular
      final tagCounts = <String, int>{};
      for (final tag in allTags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }

      final sortedTags = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedTags.take(limit).map((e) => e.key).toList();
    } catch (e) {
      AppLogger.error('Error getting popular topics: $e');
      return ['Paintings', 'Digital Art', 'Photography', 'Sculpture'];
    }
  }

  /// Search posts by query
  Future<List<ArtPost>> searchPosts(String query, {int limit = 20}) async {
    try {
      // Simple search implementation - in production you'd want full-text search
      final snapshot = await _firestore
          .collection('posts')
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThanOrEqualTo: '$query\uf8ff')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('Error searching posts: $e');
      return [];
    }
  }

  /// Fix existing posts that show "Anonymous" by updating their userName field
  Future<void> fixAnonymousPosts() async {
    try {
      AppLogger.debug('Starting anonymous posts fix');

      // Query posts where userName is "Anonymous"
      final anonymousPostsQuery = await _firestore
          .collection('posts')
          .where('userName', isEqualTo: 'Anonymous')
          .get();

      AppLogger.debug(
        'Found ${anonymousPostsQuery.docs.length} posts with "Anonymous" userName',
      );

      int updatedCount = 0;
      int errorCount = 0;

      for (final doc in anonymousPostsQuery.docs) {
        try {
          final postData = doc.data();
          final userId = postData['userId'] as String?;

          if (userId == null) {
            AppLogger.warning('Post ${doc.id} has no userId, skipping');
            continue;
          }

          // Get user profile data
          final userDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();

          if (!userDoc.exists) {
            AppLogger.warning(
              'User profile not found for userId: $userId, skipping post ${doc.id}',
            );
            continue;
          }

          final userData = userDoc.data() ?? {};

          // Determine the correct user name with multiple fallbacks
          final correctUserName =
              userData['displayName'] as String? ??
              userData['name'] as String? ??
              userData['fullName'] as String? ??
              'Anonymous'; // Keep as Anonymous if still not found

          if (correctUserName == 'Anonymous') {
            AppLogger.info(
              'Could not find display name for user $userId, keeping as Anonymous',
            );
            continue;
          }

          // Update the post with the correct user name
          await doc.reference.update({'userName': correctUserName});

          updatedCount++;
          AppLogger.debug('Updated post ${doc.id}: "$correctUserName"');
        } catch (e) {
          errorCount++;
          AppLogger.error('Error updating post ${doc.id}: $e', error: e);
        }
      }

      AppLogger.info(
        'Anonymous posts fix complete. Updated: $updatedCount, Errors: $errorCount',
      );
    } catch (e) {
      AppLogger.error('Fatal error in fixAnonymousPosts: $e', error: e);
      rethrow;
    }
  }

  /// Increment share count for a post
  Future<void> incrementShareCount(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'engagementStats.shareCount': FieldValue.increment(1),
        'engagementStats.lastUpdated': FieldValue.serverTimestamp(),
      });
      AppLogger.info('Share count incremented for post: $postId');
    } catch (e) {
      AppLogger.error('Error incrementing share count for post $postId: $e');
    }
  }

  /// Report a post for moderation review
  Future<bool> reportPost(
    String postId,
    String reason, {
    String? additionalDetails,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.error('Cannot report post: User not authenticated');
        return false;
      }

      final reportData = {
        'type': 'post',
        'postId': postId,
        'reportedBy': user.uid,
        'reporterEmail': user.email,
        'reason': reason,
        'additionalDetails': additionalDetails,
        'reportedAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, reviewed, resolved
      };

      await _firestore.collection('reports').add(reportData);

      // Also update the post to mark it as flagged and increment report count
      await _firestore.collection('posts').doc(postId).update({
        'flagged': true,
        'flaggedAt': FieldValue.serverTimestamp(),
        'status': 'flagged',
        'moderationStatus': 'flagged',
        'reportCount': FieldValue.increment(1),
      });

      AppLogger.info('Post $postId reported successfully with reason: $reason');
      return true;
    } catch (e) {
      AppLogger.error('Error reporting post $postId: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _feedController.close();
    _artistsController.close();
    super.dispose();
  }
}
