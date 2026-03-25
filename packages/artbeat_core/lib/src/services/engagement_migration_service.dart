import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/engagement_model.dart';
import '../utils/logger.dart';

/// Service to migrate from old engagement system to new universal system
/// Handles migration of likes, applause, follows, etc. to the new system
class EngagementMigrationService {
  FirebaseFirestore? _firestoreInstance;

  void initialize() {
    _firestoreInstance ??= FirebaseFirestore.instance;
  }

  FirebaseFirestore get _firestore {
    initialize();
    return _firestoreInstance!;
  }

  /// Migrate all engagement data from old system to new universal system
  Future<void> migrateAllEngagements() async {
    AppLogger.info('🔄 Starting engagement migration...');

    try {
      // Migrate in parallel for better performance
      await Future.wait([
        _migratePosts(),
        _migrateArtworks(),
        _migrateArtWalks(),
        _migrateEvents(),
        _migrateUserConnections(),
      ]);

      AppLogger.info('✅ Engagement migration completed successfully');
    } catch (e) {
      AppLogger.error('❌ Error during engagement migration: $e');
      rethrow;
    }
  }

  /// Migrate post engagements (applause, comments, shares)
  Future<void> _migratePosts() async {
    AppLogger.info('🔄 Migrating post engagements...');

    final postsQuery = _firestore.collection('posts');
    final postsSnapshot = await postsQuery.get();

    for (final postDoc in postsSnapshot.docs) {
      final postData = postDoc.data();
      final postId = postDoc.id;

      // Initialize engagement stats
      final stats = EngagementStats(
        likeCount:
            (postData['applauseCount'] as int? ?? 0) +
            (postData['likeCount'] as int? ?? 0),
        commentCount: postData['commentCount'] as int? ?? 0,
        shareCount: postData['shareCount'] as int? ?? 0,
        lastUpdated: DateTime.now(),
      );

      // Update post with new engagement stats
      await postDoc.reference.update(stats.toFirestore());

      // Migrate individual applause records
      await _migratePostApplause(postId);

      AppLogger.info('✅ Migrated post: $postId');
    }
  }

  /// Migrate artwork engagements (likes, applause, comments)
  Future<void> _migrateArtworks() async {
    AppLogger.info('🔄 Migrating artwork engagements...');

    final artworksQuery = _firestore.collection('artwork');
    final artworksSnapshot = await artworksQuery.get();

    for (final artworkDoc in artworksSnapshot.docs) {
      final artworkData = artworkDoc.data();
      final artworkId = artworkDoc.id;

      // Initialize engagement stats
      final stats = EngagementStats(
        likeCount:
            (artworkData['likeCount'] as int? ?? 0) +
            (artworkData['applauseCount'] as int? ?? 0),
        commentCount: artworkData['commentCount'] as int? ?? 0,
        lastUpdated: DateTime.now(),
      );

      // Update artwork with new engagement stats
      await artworkDoc.reference.update(stats.toFirestore());

      AppLogger.info('✅ Migrated artwork: $artworkId');
    }
  }

  /// Migrate art walk engagements
  Future<void> _migrateArtWalks() async {
    AppLogger.info('🔄 Migrating art walk engagements...');

    final artWalksQuery = _firestore.collection('artWalks');
    final artWalksSnapshot = await artWalksQuery.get();

    for (final artWalkDoc in artWalksSnapshot.docs) {
      final artWalkId = artWalkDoc.id;

      // Initialize engagement stats (art walks mainly have views)
      final stats = EngagementStats(
        likeCount: 0, // Start fresh for art walks
        commentCount: 0,
        shareCount: 0,
        seenCount: 0, // Art walks will track views as 'seen'
        lastUpdated: DateTime.now(),
      );

      // Update art walk with new engagement stats
      await artWalkDoc.reference.update(stats.toFirestore());

      AppLogger.info('✅ Migrated art walk: $artWalkId');
    }
  }

  /// Migrate event engagements
  Future<void> _migrateEvents() async {
    AppLogger.info('🔄 Migrating event engagements...');

    final eventsQuery = _firestore.collection('events');
    final eventsSnapshot = await eventsQuery.get();

    for (final eventDoc in eventsSnapshot.docs) {
      final eventId = eventDoc.id;

      // Initialize engagement stats
      final stats = EngagementStats(
        likeCount: 0, // Start fresh for events
        commentCount: 0,
        shareCount: 0,
        seenCount: 0, // Events will track views as 'seen'
        rateCount: 0, // Events can be rated
        reviewCount: 0, // Events can be reviewed
        lastUpdated: DateTime.now(),
      );

      // Update event with new engagement stats
      await eventDoc.reference.update(stats.toFirestore());

      AppLogger.info('✅ Migrated event: $eventId');
    }
  }

  /// Migrate user connections (followers/following to connections)
  Future<void> _migrateUserConnections() async {
    AppLogger.info('🔄 Migrating user connections...');

    final usersQuery = _firestore.collection('users');
    final usersSnapshot = await usersQuery.get();

    for (final userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();
      final userId = userDoc.id;

      // Get followers and following lists
      final followers = List<String>.from(userData['followers'] as List? ?? []);
      final following = List<String>.from(userData['following'] as List? ?? []);

      // Create connection engagements for following relationships
      for (final followedUserId in following) {
        await _createConnectionEngagement(userId, followedUserId);
      }

      // Initialize engagement stats for user profile
      final stats = EngagementStats(
        followCount: followers.length,
        lastUpdated: DateTime.now(),
      );

      // Update user with new engagement stats
      await userDoc.reference.update(stats.toFirestore());

      AppLogger.info('✅ Migrated user connections: $userId');
    }
  }

  /// Migrate individual post applause records
  Future<void> _migratePostApplause(String postId) async {
    try {
      final applauseQuery = _firestore
          .collection('posts')
          .doc(postId)
          .collection('applause');

      final applauseSnapshot = await applauseQuery.get();

      for (final applauseDoc in applauseSnapshot.docs) {
        final applauseData = applauseDoc.data();
        final userId = applauseDoc.id;
        final count = applauseData['count'] as int? ?? 1;

        // Create individual engagement records for each applause
        for (int i = 0; i < count; i++) {
          await _createAppreciationEngagement(userId, postId, 'post');
        }
      }
    } catch (e) {
      AppLogger.error('Error migrating post applause for $postId: $e');
    }
  }

  /// Create a connection engagement record
  Future<void> _createConnectionEngagement(
    String fromUserId,
    String toUserId,
  ) async {
    try {
      final engagementId = '${toUserId}_${fromUserId}_follow';

      final engagement = EngagementModel(
        id: engagementId,
        contentId: toUserId,
        contentType: 'profile',
        userId: fromUserId,
        type: EngagementType.follow,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('engagements')
          .doc(engagementId)
          .set(engagement.toFirestore());
    } catch (e) {
      AppLogger.error('Error creating connection engagement: $e');
    }
  }

  /// Create an appreciation engagement record
  Future<void> _createAppreciationEngagement(
    String userId,
    String contentId,
    String contentType,
  ) async {
    try {
      final engagementId =
          '${contentId}_${userId}_like_${DateTime.now().millisecondsSinceEpoch}';

      final engagement = EngagementModel(
        id: engagementId,
        contentId: contentId,
        contentType: contentType,
        userId: userId,
        type: EngagementType.like,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('engagements')
          .doc(engagementId)
          .set(engagement.toFirestore());
    } catch (e) {
      AppLogger.error('Error creating appreciation engagement: $e');
    }
  }

  /// Clean up old engagement fields after migration
  Future<void> cleanupOldEngagementFields() async {
    AppLogger.info('🧹 Cleaning up old engagement fields...');

    try {
      // Clean up posts
      await _cleanupPostFields();

      // Clean up artworks
      await _cleanupArtworkFields();

      // Clean up users
      await _cleanupUserFields();

      AppLogger.info('✅ Cleanup completed successfully');
    } catch (e) {
      AppLogger.error('❌ Error during cleanup: $e');
      rethrow;
    }
  }

  Future<void> _cleanupPostFields() async {
    final postsQuery = _firestore.collection('posts');
    final postsSnapshot = await postsQuery.get();

    for (final postDoc in postsSnapshot.docs) {
      await postDoc.reference.update({
        'applauseCount': FieldValue.delete(),
        'commentCount': FieldValue.delete(),
        'shareCount': FieldValue.delete(),
      });
    }
  }

  Future<void> _cleanupArtworkFields() async {
    final artworksQuery = _firestore.collection('artwork');
    final artworksSnapshot = await artworksQuery.get();

    for (final artworkDoc in artworksSnapshot.docs) {
      await artworkDoc.reference.update({
        'likeCount': FieldValue.delete(),
        'applauseCount': FieldValue.delete(),
        'commentCount': FieldValue.delete(),
      });
    }
  }

  Future<void> _cleanupUserFields() async {
    final usersQuery = _firestore.collection('users');
    final usersSnapshot = await usersQuery.get();

    for (final userDoc in usersSnapshot.docs) {
      await userDoc.reference.update({
        'followers': FieldValue.delete(),
        'following': FieldValue.delete(),
        'followersCount': FieldValue.delete(),
        'followingCount': FieldValue.delete(),
      });
    }
  }

  /// Verify migration integrity
  Future<bool> verifyMigration() async {
    AppLogger.debug('🔍 Verifying migration integrity...');

    try {
      // Check if engagement collection exists and has data
      final engagementsQuery = _firestore.collection('engagements').limit(1);
      final engagementsSnapshot = await engagementsQuery.get();

      if (engagementsSnapshot.docs.isEmpty) {
        AppLogger.error('❌ No engagements found in new collection');
        return false;
      }

      // Check if posts have new engagement stats
      final postsQuery = _firestore.collection('posts').limit(1);
      final postsSnapshot = await postsQuery.get();

      if (postsSnapshot.docs.isNotEmpty) {
        final postData = postsSnapshot.docs.first.data();
        if (!postData.containsKey('likeCount')) {
          AppLogger.error('❌ Posts missing new engagement stats');
          return false;
        }
      }

      AppLogger.info('✅ Migration verification passed');
      return true;
    } catch (e) {
      AppLogger.error('❌ Error during migration verification: $e');
      return false;
    }
  }
}
