import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../utils/artist_logger.dart';
import 'error_monitoring_service.dart';
import '../utils/input_validator.dart';

/// Service for handling artist community features and social interactions
class CommunityService {
  static final CommunityService _instance = CommunityService._internal();
  factory CommunityService() => _instance;
  CommunityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Follow another artist
  Future<bool> followArtist(String artistId) async {
    return ErrorMonitoringService.safeExecute(
      'followArtist',
      () async {
        // Validate input
        InputValidator.validateUserId(artistId).throwIfInvalid();

        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          ArtistLogger.warning('Follow artist failed: User not authenticated');
          return false;
        }

        await _firestore
            .collection('follows')
            .doc('${currentUser.uid}_$artistId')
            .set({
              'followerId': currentUser.uid,
              'followedId': artistId,
              'createdAt': FieldValue.serverTimestamp(),
              'type': 'artist',
            });

        // Update follower counts
        await _updateFollowerCounts(currentUser.uid, artistId, isFollow: true);

        ArtistLogger.communityService(
          'Follow artist successful',
          details: 'Artist: $artistId',
        );
        return true;
      },
      fallbackValue: false,
      context: {'artistId': artistId, 'operation': 'follow'},
    );
  }

  /// Unfollow an artist
  Future<bool> unfollowArtist(String artistId) async {
    return ErrorMonitoringService.safeExecute(
      'unfollowArtist',
      () async {
        // Validate input
        InputValidator.validateUserId(artistId).throwIfInvalid();

        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          ArtistLogger.warning(
            'Unfollow artist failed: User not authenticated',
          );
          return false;
        }

        await _firestore
            .collection('follows')
            .doc('${currentUser.uid}_$artistId')
            .delete();

        // Update follower counts
        await _updateFollowerCounts(currentUser.uid, artistId, isFollow: false);

        ArtistLogger.communityService(
          'Unfollow artist successful',
          details: 'Artist: $artistId',
        );
        return true;
      },
      fallbackValue: false,
      context: {'artistId': artistId, 'operation': 'unfollow'},
    );
  }

  /// Check if current user follows an artist
  Future<bool> isFollowingArtist(String artistId) async {
    return ErrorMonitoringService.safeExecute(
      'isFollowingArtist',
      () async {
        // Validate input
        InputValidator.validateUserId(artistId).throwIfInvalid();

        final currentUser = _auth.currentUser;
        if (currentUser == null) return false;

        final doc = await _firestore
            .collection('follows')
            .doc('${currentUser.uid}_$artistId')
            .get();

        return doc.exists;
      },
      fallbackValue: false,
      context: {'artistId': artistId, 'operation': 'checkFollowStatus'},
    );
  }

  /// Get artist followers
  Future<List<core.UserModel>> getArtistFollowers(
    String artistId, {
    int limit = 20,
  }) async {
    return ErrorMonitoringService.safeExecute(
      'getArtistFollowers',
      () async {
        // Validate input
        InputValidator.validateUserId(artistId).throwIfInvalid();

        final snapshot = await _firestore
            .collection('follows')
            .where('followedId', isEqualTo: artistId)
            .limit(limit)
            .get();

        final followerIds = snapshot.docs
            .map((doc) => doc.data()['followerId'] as String)
            .toList();

        if (followerIds.isEmpty) {
          ArtistLogger.communityService(
            'No followers found for artist',
            details: 'Artist: $artistId',
          );
          return <core.UserModel>[];
        }

        final userDocs = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: followerIds)
            .get();

        final followers = userDocs.docs
            .map((doc) => core.UserModel.fromJson(doc.data()..['id'] = doc.id))
            .toList();

        ArtistLogger.communityService(
          'Retrieved artist followers',
          details: 'Artist: $artistId, Count: ${followers.length}',
        );
        return followers;
      },
      fallbackValue: <core.UserModel>[],
      context: {
        'artistId': artistId,
        'operation': 'getFollowers',
        'limit': limit,
      },
    );
  }

  /// Get artists followed by user
  Future<List<core.UserModel>> getFollowedArtists(
    String userId, {
    int limit = 20,
  }) async {
    return ErrorMonitoringService.safeExecute(
      'getFollowedArtists',
      () async {
        // Validate input
        InputValidator.validateUserId(userId).throwIfInvalid();

        final snapshot = await _firestore
            .collection('follows')
            .where('followerId', isEqualTo: userId)
            .where('type', isEqualTo: 'artist')
            .limit(limit)
            .get();

        final artistIds = snapshot.docs
            .map((doc) => doc.data()['followedId'] as String)
            .toList();

        if (artistIds.isEmpty) {
          ArtistLogger.communityService(
            'No followed artists found for user',
            details: 'User: $userId',
          );
          return <core.UserModel>[];
        }

        final artistDocs = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: artistIds)
            .get();

        final followedArtists = artistDocs.docs
            .map((doc) => core.UserModel.fromJson(doc.data()..['id'] = doc.id))
            .toList();

        ArtistLogger.communityService(
          'Retrieved followed artists',
          details: 'User: $userId, Count: ${followedArtists.length}',
        );
        return followedArtists;
      },
      fallbackValue: <core.UserModel>[],
      context: {
        'userId': userId,
        'operation': 'getFollowedArtists',
        'limit': limit,
      },
    );
  }

  /// Get artist collaboration requests
  Future<List<Map<String, dynamic>>> getCollaborationRequests(
    String artistId,
  ) async {
    return ErrorMonitoringService.safeExecute(
      'getCollaborationRequests',
      () async {
        // Validate input
        InputValidator.validateUserId(artistId).throwIfInvalid();

        final snapshot = await _firestore
            .collection('collaborationRequests')
            .where('recipientId', isEqualTo: artistId)
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .get();

        final requests = snapshot.docs
            .map((doc) => doc.data()..['id'] = doc.id)
            .toList();

        ArtistLogger.communityService(
          'Retrieved collaboration requests',
          details: 'Artist: $artistId, Count: ${requests.length}',
        );
        return requests;
      },
      fallbackValue: <Map<String, dynamic>>[],
      context: {'artistId': artistId, 'operation': 'getCollaborationRequests'},
    );
  }

  /// Send collaboration request
  Future<bool> sendCollaborationRequest(
    String recipientId,
    String message,
    String projectType,
  ) async {
    return ErrorMonitoringService.safeExecute(
      'sendCollaborationRequest',
      () async {
        // Validate inputs
        InputValidator.validateUserId(recipientId).throwIfInvalid();
        final validatedMessage = InputValidator.validateText(
          message,
          fieldName: 'message',
        ).getOrThrow();
        final validatedProjectType = InputValidator.validateText(
          projectType,
          fieldName: 'projectType',
        ).getOrThrow();

        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          ArtistLogger.warning(
            'Send collaboration request failed: User not authenticated',
          );
          return false;
        }

        await _firestore.collection('collaborationRequests').add({
          'senderId': currentUser.uid,
          'recipientId': recipientId,
          'message': validatedMessage,
          'projectType': validatedProjectType,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        ArtistLogger.communityService(
          'Collaboration request sent successfully',
          details: 'Recipient: $recipientId, Project: $validatedProjectType',
        );
        return true;
      },
      fallbackValue: false,
      context: {
        'recipientId': recipientId,
        'projectType': projectType,
        'operation': 'sendCollaborationRequest',
      },
    );
  }

  /// Update collaboration request status
  Future<bool> updateCollaborationRequestStatus(
    String requestId,
    String status,
  ) async {
    return ErrorMonitoringService.safeExecute(
      'updateCollaborationRequestStatus',
      () async {
        // Validate inputs
        final validatedRequestId = InputValidator.validateText(
          requestId,
          fieldName: 'requestId',
        ).getOrThrow();
        final validatedStatus = InputValidator.validateText(
          status,
          fieldName: 'status',
        ).getOrThrow();

        await _firestore
            .collection('collaborationRequests')
            .doc(validatedRequestId)
            .update({
              'status': validatedStatus,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        ArtistLogger.communityService(
          'Collaboration request status updated',
          details: 'Request: $validatedRequestId, Status: $validatedStatus',
        );
        return true;
      },
      fallbackValue: false,
      context: {
        'requestId': requestId,
        'status': status,
        'operation': 'updateCollaborationRequestStatus',
      },
    );
  }

  /// Get artist community feed (posts from followed artists)
  Stream<List<Map<String, dynamic>>> getArtistCommunityFeed(
    String userId, {
    int limit = 20,
  }) {
    return _firestore
        .collection('follows')
        .where('followerId', isEqualTo: userId)
        .snapshots()
        .asyncMap((followSnapshot) async {
          if (followSnapshot.docs.isEmpty) return <Map<String, dynamic>>[];

          final followedIds = followSnapshot.docs
              .map((doc) => doc.data()['followedId'] as String)
              .toList();

          final feedSnapshot = await _firestore
              .collection('posts')
              .where('userId', whereIn: followedIds)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

          return feedSnapshot.docs
              .map((doc) => doc.data()..['id'] = doc.id)
              .toList();
        });
  }

  /// Update follower counts helper method
  Future<void> _updateFollowerCounts(
    String followerId,
    String followedId, {
    required bool isFollow,
  }) async {
    final batch = _firestore.batch();

    // Update follower's following count
    final followerRef = _firestore.collection('users').doc(followerId);
    batch.update(followerRef, {
      'followingCount': FieldValue.increment(isFollow ? 1 : -1),
    });

    // Update followed user's follower count
    final followedRef = _firestore.collection('users').doc(followedId);
    batch.update(followedRef, {
      'followersCount': FieldValue.increment(isFollow ? 1 : -1),
    });

    await batch.commit();
  }

  /// Get mutual connections between two artists
  Future<List<core.UserModel>> getMutualConnections(
    String artistId1,
    String artistId2,
  ) async {
    return ErrorMonitoringService.safeExecute(
      'getMutualConnections',
      () async {
        // Validate inputs
        InputValidator.validateUserId(artistId1).throwIfInvalid();
        InputValidator.validateUserId(artistId2).throwIfInvalid();

        final artist1Follows = await _firestore
            .collection('follows')
            .where('followerId', isEqualTo: artistId1)
            .get();

        final artist2Follows = await _firestore
            .collection('follows')
            .where('followerId', isEqualTo: artistId2)
            .get();

        final artist1FollowedIds = artist1Follows.docs
            .map((doc) => doc.data()['followedId'] as String)
            .toSet();

        final artist2FollowedIds = artist2Follows.docs
            .map((doc) => doc.data()['followedId'] as String)
            .toSet();

        final mutualIds = artist1FollowedIds
            .intersection(artist2FollowedIds)
            .toList();

        if (mutualIds.isEmpty) {
          ArtistLogger.communityService(
            'No mutual connections found',
            details: 'Artists: $artistId1, $artistId2',
          );
          return <core.UserModel>[];
        }

        final mutualDocs = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: mutualIds)
            .get();

        final mutualConnections = mutualDocs.docs
            .map((doc) => core.UserModel.fromJson(doc.data()..['id'] = doc.id))
            .toList();

        ArtistLogger.communityService(
          'Retrieved mutual connections',
          details:
              'Artists: $artistId1, $artistId2, Count: ${mutualConnections.length}',
        );
        return mutualConnections;
      },
      fallbackValue: <core.UserModel>[],
      context: {
        'artistId1': artistId1,
        'artistId2': artistId2,
        'operation': 'getMutualConnections',
      },
    );
  }
}
