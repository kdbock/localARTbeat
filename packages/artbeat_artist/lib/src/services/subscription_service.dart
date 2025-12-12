import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription_model.dart';
import '../models/top_follower_model.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'error_monitoring_service.dart';
import '../utils/artist_logger.dart';
import '../utils/input_validator.dart';

/// Service for managing artist subscriptions
class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? getCurrentUserId() => _auth.currentUser?.uid;

  /// Get the current user's subscription
  Future<SubscriptionModel?> getUserSubscription() async {
    return ErrorMonitoringService.safeExecute(
      'getUserSubscription',
      () async {
        final userId = _auth.currentUser?.uid;
        if (userId == null) {
          ArtistLogger.warning('getUserSubscription: No authenticated user');
          return null;
        }

        ArtistLogger.info('getUserSubscription: Querying for userId: $userId');

        final snapshot = await _firestore
            .collection('subscriptions')
            .where('userId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        ArtistLogger.info(
            'getUserSubscription: Found ${snapshot.docs.length} subscriptions');

        if (snapshot.docs.isEmpty) {
          ArtistLogger.info(
              'getUserSubscription: No active subscription found for user $userId');
          return null;
        }

        final subscription =
            SubscriptionModel.fromFirestore(snapshot.docs.first);
        ArtistLogger.info(
            'getUserSubscription: Found subscription: ${subscription.tier}');
        return subscription;
      },
      fallbackValue: null,
    );
  }

  /// Get current subscription for a specific user
  Future<SubscriptionModel?> getCurrentSubscription(String userId) async {
    return ErrorMonitoringService.safeExecute(
      'getCurrentSubscription',
      () async {
        final validationResult =
            InputValidator.validateText(userId, fieldName: 'userId');
        final validUserId = validationResult.getOrThrow();

        final snapshot = await _firestore
            .collection('subscriptions')
            .where('userId', isEqualTo: validUserId)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) return null;

        return SubscriptionModel.fromFirestore(snapshot.docs.first);
      },
      fallbackValue: null,
    );
  }

  /// Get current subscription tier
  Future<SubscriptionTier> getCurrentTier() async {
    return ErrorMonitoringService.safeExecute(
      'getCurrentTier',
      () async {
        final sub = await getUserSubscription();
        return sub?.tier ?? SubscriptionTier.free;
      },
      fallbackValue: SubscriptionTier.free,
    );
  }

  /// Create new artist profile
  Future<String> createArtistProfile({
    required String userId,
    required String displayName,
    required String bio,
    required UserType userType,
    required String location,
    required List<String> mediums,
    required List<String> styles,
    required Map<String, String> socialLinks,
    String? profileImageUrl,
    String? coverImageUrl,
  }) async {
    return ErrorMonitoringService.safeExecute(
      'createArtistProfile',
      () async {
        // Validate required inputs
        final userIdResult =
            InputValidator.validateText(userId, fieldName: 'userId');
        final displayNameResult =
            InputValidator.validateText(displayName, fieldName: 'displayName');
        final bioResult = InputValidator.validateText(bio, fieldName: 'bio');
        final locationResult =
            InputValidator.validateText(location, fieldName: 'location');

        final validUserId = userIdResult.getOrThrow();
        final validDisplayName = displayNameResult.getOrThrow();
        final validBio = bioResult.getOrThrow();
        final validLocation = locationResult.getOrThrow();

        DocumentReference docRef;

        // Check if profile already exists
        final existingProfile = await _firestore
            .collection('artistProfiles')
            .where('userId', isEqualTo: validUserId)
            .limit(1)
            .get();

        if (existingProfile.docs.isNotEmpty) {
          // Update existing profile
          docRef = _firestore
              .collection('artistProfiles')
              .doc(existingProfile.docs.first.id);

          await docRef.update({
            'displayName': validDisplayName,
            'bio': validBio,
            'userType': userType.value,
            'location': validLocation,
            'mediums': mediums,
            'styles': styles,
            'socialLinks': socialLinks,
            if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
            if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Create new profile
          docRef = _firestore.collection('artistProfiles').doc();

          await docRef.set({
            'userId': validUserId,
            'displayName': validDisplayName,
            'bio': validBio,
            'userType': userType.value,
            'location': validLocation,
            'mediums': mediums,
            'styles': styles,
            'socialLinks': socialLinks,
            'profileImageUrl': profileImageUrl,
            'coverImageUrl': coverImageUrl,
            'isVerified': false,
            'isFeatured': false,
            'followerCount': 0,
            'subscriptionTier': SubscriptionTier.free.apiName,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        return docRef.id;
      },
    );
  }

  /// Save or update artist profile
  Future<void> saveArtistProfile({
    String? profileId,
    required String displayName,
    required String bio,
    required List<String> mediums,
    required List<String> styles,
    String? location,
    String? websiteUrl,
    String? instagram,
    String? facebook,
    String? twitter,
    String? etsy,
    required UserType userType,
    String? profileImageUrl,
    String? coverImageUrl,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final Map<String, String> socialLinks = {
        if (websiteUrl != null) 'website': websiteUrl,
        if (instagram != null) 'instagram': instagram,
        if (facebook != null) 'facebook': facebook,
        if (twitter != null) 'twitter': twitter,
        if (etsy != null) 'etsy': etsy,
      };

      // Get current tier (default to basic)
      SubscriptionTier tier = SubscriptionTier.free;
      try {
        final subscription = await getUserSubscription();
        if (subscription != null) {
          tier = subscription.tier;
        }
      } catch (e) {
        ArtistLogger.warning(
            'Error getting subscription, defaulting to basic: $e');
      }

      // Prepare profile data
      final Map<String, dynamic> data = {
        'userId': userId,
        'displayName': displayName,
        'bio': bio,
        'userType': userType.value,
        'mediums': mediums,
        'styles': styles,
        'socialLinks': socialLinks,
        'subscriptionTier': tier.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (location != null) data['location'] = location;
      if (profileImageUrl != null) data['profileImageUrl'] = profileImageUrl;
      if (coverImageUrl != null) data['coverImageUrl'] = coverImageUrl;

      // Create or update profile
      if (profileId != null) {
        await _firestore
            .collection('artistProfiles')
            .doc(profileId)
            .update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['isVerified'] = false;
        data['isFeatured'] = false;
        await _firestore.collection('artistProfiles').add(data);
      }
    } catch (e) {
      ArtistLogger.error('Error saving artist profile: $e');
      throw Exception('Failed to save artist profile: $e');
    }
  }

  /// Check if user has access to a specific tier's features
  Future<bool> hasTierAccess(SubscriptionTier minimumTier) async {
    try {
      final currentTier = await getCurrentTier();
      return currentTier.index >= minimumTier.index;
    } catch (e) {
      ArtistLogger.error('Error checking tier access: $e');
      return false;
    }
  }

  /// Helper method to get tier details
  Map<String, dynamic> getTierDetails(SubscriptionTier tier) {
    return {
      'name': tier.displayName,
      'price': tier.monthlyPrice,
      'features': tier.features,
    };
  }

  /// Get artist profile by user ID
  Future<ArtistProfileModel?> getArtistProfileByUserId(String userId) async {
    try {
      // Use info level for normal operations instead of error
      ArtistLogger.info(
          '🔍 getArtistProfileByUserId: Querying for userId: $userId');

      final query = await _firestore
          .collection('artistProfiles')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      ArtistLogger.info(
          '📊 getArtistProfileByUserId: Found ${query.docs.length} documents');

      if (query.docs.isEmpty) {
        ArtistLogger.warning(
            '❌ getArtistProfileByUserId: No artist profile found for user $userId');
        return null;
      }

      final profile = ArtistProfileModel.fromFirestore(query.docs.first);
      ArtistLogger.info(
          '✅ getArtistProfileByUserId: Successfully loaded profile for ${profile.displayName}');
      return profile;
    } catch (e) {
      ArtistLogger.error('❌ Error getting artist profile: $e');
      return null;
    }
  }

  /// Get the current user's artist profile
  Future<ArtistProfileModel?> getCurrentArtistProfile() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return null;

      return await getArtistProfileByUserId(userId);
    } catch (e) {
      ArtistLogger.error('Error getting current artist profile: $e');
      return null;
    }
  }

  /// Get featured artists
  Future<List<ArtistProfileModel>> getFeaturedArtists() async {
    try {
      final snapshot = await _firestore
          .collection('artistProfiles')
          .where('isFeatured', isEqualTo: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => ArtistProfileModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      ArtistLogger.error('Error getting featured artists: $e');
      return [];
    }
  }

  /// Get verified artists
  Future<List<ArtistProfileModel>> getVerifiedArtists() async {
    try {
      final snapshot = await _firestore
          .collection('artistProfiles')
          .where('isVerified', isEqualTo: true)
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => ArtistProfileModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      ArtistLogger.error('Error getting verified artists: $e');
      return [];
    }
  }

  /// Get artist profile by ID
  Future<ArtistProfileModel?> getArtistProfileById(String id) async {
    try {
      final docSnapshot =
          await _firestore.collection('artistProfiles').doc(id).get();

      if (!docSnapshot.exists) return null;
      return ArtistProfileModel.fromFirestore(docSnapshot);
    } catch (e) {
      ArtistLogger.error('Error getting artist profile by id: $e');
      return null;
    }
  }

  /// Check if user is following an artist
  Future<bool> isFollowingArtist({required String artistProfileId}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _firestore
          .collection('artistFollows')
          .doc('${userId}_$artistProfileId')
          .get();

      return doc.exists;
    } catch (e) {
      ArtistLogger.error('Error checking if following artist: $e');
      return false;
    }
  }

  /// Follow an artist
  Future<void> followArtist({required String artistProfileId}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User must be logged in');

      ArtistLogger.error(
          'Following artist: userId=$userId, artistProfileId=$artistProfileId');

      // First, create the follow relationship
      ArtistLogger.error('Creating artistFollows document...');
      await _firestore
          .collection('artistFollows')
          .doc('${userId}_$artistProfileId')
          .set({
        'userId': userId,
        'artistProfileId': artistProfileId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      ArtistLogger.error('artistFollows document created successfully');

      // Update follower count
      ArtistLogger.error('Updating follower count...');
      await _firestore
          .collection('artistProfiles')
          .doc(artistProfileId)
          .update({
        'followerCount': FieldValue.increment(1),
      });
      ArtistLogger.error('Follower count updated successfully');
    } catch (e) {
      ArtistLogger.error('Error following artist: $e');
      rethrow;
    }
  }

  /// Unfollow an artist
  Future<void> unfollowArtist({required String artistProfileId}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User must be logged in');

      ArtistLogger.error(
          'Unfollowing artist: userId=$userId, artistProfileId=$artistProfileId');

      // First, delete the follow relationship
      ArtistLogger.error('Deleting artistFollows document...');
      await _firestore
          .collection('artistFollows')
          .doc('${userId}_$artistProfileId')
          .delete();
      ArtistLogger.error('artistFollows document deleted successfully');

      // Update follower count
      ArtistLogger.error('Updating follower count...');
      await _firestore
          .collection('artistProfiles')
          .doc(artistProfileId)
          .update({
        'followerCount': FieldValue.increment(-1),
      });
      ArtistLogger.error('Follower count updated successfully');
    } catch (e) {
      ArtistLogger.error('Error unfollowing artist: $e');
      rethrow;
    }
  }

  /// Toggle following status for an artist
  Future<bool> toggleFollowArtist({required String artistProfileId}) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) throw Exception('User must be logged in');

      final isCurrentlyFollowing =
          await isFollowingArtist(artistProfileId: artistProfileId);

      if (isCurrentlyFollowing) {
        await unfollowArtist(artistProfileId: artistProfileId);
        return false;
      } else {
        await followArtist(artistProfileId: artistProfileId);
        return true;
      }
    } catch (e) {
      ArtistLogger.error('Error toggling artist follow status: $e');
      rethrow;
    }
  }

  /// Get all artists with optional filters
  Future<List<ArtistProfileModel>> getAllArtists({
    String? searchQuery,
    String? medium,
    String? style,
  }) async {
    try {
      Query query = _firestore.collection('artistProfiles');

      // Filter by medium if specified
      if (medium != null && medium != 'All') {
        query = query.where('mediums', arrayContains: medium);
      }

      // Get all artists
      final snapshot = await query.get();
      List<ArtistProfileModel> artists = snapshot.docs
          .map((doc) => ArtistProfileModel.fromFirestore(doc))
          .toList();

      // Apply style filter in memory (since Firestore doesn't support multiple array-contains queries)
      if (style != null && style != 'All') {
        artists =
            artists.where((artist) => artist.styles.contains(style)).toList();
      }

      // Apply search filter in memory
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        artists = artists.where((artist) {
          return artist.displayName.toLowerCase().contains(searchLower) ||
              (artist.bio?.toLowerCase().contains(searchLower) ?? false);
        }).toList();
      }

      // Sort by subscription tier, featured status, and name
      artists.sort((a, b) {
        // First sort by subscription tier (premium > standard > basic)
        final tierCompare =
            b.subscriptionTier.index.compareTo(a.subscriptionTier.index);
        if (tierCompare != 0) return tierCompare;

        // Then by featured status
        if (a.isFeatured != b.isFeatured) {
          return a.isFeatured ? -1 : 1;
        }

        // Finally by name
        return a.displayName.compareTo(b.displayName);
      });

      return artists;
    } catch (e) {
      ArtistLogger.error('Error getting all artists: $e');
      return [];
    }
  }

  /// Get all followers for an artist
  Future<List<String>> getFollowersForArtist({
    required String artistProfileId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('artistFollows')
          .where('artistProfileId', isEqualTo: artistProfileId)
          .get();

      return snapshot.docs.map((doc) => doc['userId'] as String).toList();
    } catch (e) {
      ArtistLogger.error('Error getting followers for artist: $e');
      return [];
    }
  }

  /// Get engagement score for a follower
  /// Calculates based on gifts (10 pts), likes (1 pt), messages (5 pts), views (0.5 pts)
  Future<int> calculateEngagementScore({
    required String followerId,
    required String artistProfileId,
  }) async {
    try {
      int score = 0;

      final giftsSnapshot = await _firestore
          .collection('gifts')
          .where('senderId', isEqualTo: followerId)
          .where('recipientId', isEqualTo: artistProfileId)
          .get();
      score += giftsSnapshot.docs.length * 10;

      final likesSnapshot = await _firestore
          .collection('likes')
          .where('userId', isEqualTo: followerId)
          .where('artistId', isEqualTo: artistProfileId)
          .get();
      score += likesSnapshot.docs.length;

      final messagesSnapshot = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: followerId)
          .where('recipientId', isEqualTo: artistProfileId)
          .get();
      score += messagesSnapshot.docs.length * 5;

      final viewsSnapshot = await _firestore
          .collection('profileViews')
          .where('viewerId', isEqualTo: followerId)
          .where('artistProfileId', isEqualTo: artistProfileId)
          .get();
      score += (viewsSnapshot.docs.length * 0.5).toInt();

      return score;
    } catch (e) {
      ArtistLogger.error('Error calculating engagement score: $e');
      return 0;
    }
  }

  /// Get top engaged followers for an artist (MySpace-style top 8)
  Future<List<TopFollowerModel>> getTopFollowers({
    required String artistProfileId,
    int limit = 8,
  }) async {
    try {
      ArtistLogger.info(
          '🔝 Fetching top $limit followers for artist: $artistProfileId');

      final followerIds =
          await getFollowersForArtist(artistProfileId: artistProfileId);

      if (followerIds.isEmpty) {
        ArtistLogger.info('No followers found for artist');
        return [];
      }

      final topFollowers = <TopFollowerModel>[];

      for (final followerId in followerIds) {
        try {
          final engagementScore = await calculateEngagementScore(
            followerId: followerId,
            artistProfileId: artistProfileId,
          );

          if (engagementScore > 0) {
            final userDoc =
                await _firestore.collection('users').doc(followerId).get();

            final followerName = userDoc['displayName'] as String? ?? 'User';
            final followerAvatarUrl = userDoc['profileImageUrl'] as String?;
            final isVerified = userDoc['isVerified'] as bool? ?? false;

            final topFollower = TopFollowerModel(
              followerId: followerId,
              followerName: followerName,
              followerAvatarUrl: followerAvatarUrl,
              engagementScore: engagementScore,
              isVerified: isVerified,
              lastEngagementAt: DateTime.now(),
            );

            topFollowers.add(topFollower);
          }
        } catch (e) {
          ArtistLogger.warning('Error processing follower $followerId: $e');
          continue;
        }
      }

      topFollowers
          .sort((a, b) => b.engagementScore.compareTo(a.engagementScore));

      final result = topFollowers.take(limit).toList();
      ArtistLogger.info('🔝 Found ${result.length} top followers');

      return result;
    } catch (e) {
      ArtistLogger.error('Error getting top followers: $e');
      return [];
    }
  }

  /// Get follower stats for an artist
  Future<Map<String, dynamic>> getFollowerStats({
    required String artistProfileId,
  }) async {
    try {
      final followerIds =
          await getFollowersForArtist(artistProfileId: artistProfileId);
      final totalFollowers = followerIds.length;

      int totalEngagement = 0;
      for (final followerId in followerIds) {
        final score = await calculateEngagementScore(
          followerId: followerId,
          artistProfileId: artistProfileId,
        );
        totalEngagement += score;
      }

      final avgEngagement =
          totalFollowers > 0 ? totalEngagement ~/ totalFollowers : 0;

      return {
        'totalFollowers': totalFollowers,
        'totalEngagement': totalEngagement,
        'averageEngagement': avgEngagement,
      };
    } catch (e) {
      ArtistLogger.error('Error getting follower stats: $e');
      return {
        'totalFollowers': 0,
        'totalEngagement': 0,
        'averageEngagement': 0,
      };
    }
  }
}
