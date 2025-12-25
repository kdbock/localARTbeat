import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:cloud_firestore/cloud_firestore.dart';

class ArtistProfileService {
  static final ArtistProfileService _instance =
      ArtistProfileService._internal();
  factory ArtistProfileService() => _instance;
  ArtistProfileService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _artistProfilesCollection =>
      _firestore.collection('artistProfiles');
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Create a new artist profile
  Future<core.ArtistProfileModel> createArtistProfile({
    required String userId,
    required String displayName,
    required String username,
    required String bio,
    String? website,
    List<String>? mediums,
    List<String>? styles,
    String? location,
    required core.UserType userType,
    required core.SubscriptionTier subscriptionTier,
  }) async {
    try {
      final now = DateTime.now();
      final data = {
        'userId': userId,
        'displayName': displayName,
        'username': username,
        'bio': bio,
        'website': website,
        'mediums': mediums ?? [],
        'styles': styles ?? [],
        'location': location,
        'userType': userType.name,
        'subscriptionTier': subscriptionTier.name,
        'isVerified': false,
        'isFeatured': false,
        'isPortfolioPublic': true, // Default to public for featured artists
        'socialLinks': <String, String>{},
        'createdAt': now,
        'updatedAt': now,
      };

      final docRef = await _artistProfilesCollection.add(data);
      data['id'] = docRef.id;

      return core.ArtistProfileModel(
        id: docRef.id,
        userId: userId,
        displayName: displayName,
        username: username,
        bio: bio,
        userType: userType,
        location: location,
        mediums: mediums ?? [],
        styles: styles ?? [],
        profileImageUrl: null,
        coverImageUrl: null,
        socialLinks: const {},
        isVerified: false,
        isFeatured: false,
        isPortfolioPublic: true,
        subscriptionTier: subscriptionTier,
        createdAt: now,
        updatedAt: now,
        followersCount: 0,
      );
    } catch (e) {
      throw Exception('Error creating artist profile: $e');
    }
  }

  /// Get artist profile by user ID
  Future<core.ArtistProfileModel?> getArtistProfileByUserId(
      String userId) async {
    try {
      final querySnapshot = await _artistProfilesCollection
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;

      return core.ArtistProfileModel(
        id: doc.id,
        userId: data['userId'] as String,
        displayName: data['displayName'] as String,
        username: data['username'] as String? ?? '',
        bio: data['bio'] as String?,
        userType: core.UserType.fromString(
            (data['userType'] as String?) ?? core.UserType.artist.name),
        location: data['location'] as String?,
        mediums: List<String>.from(data['mediums'] as Iterable? ?? []),
        styles: List<String>.from(data['styles'] as Iterable? ?? []),
        profileImageUrl: data['profileImageUrl'] as String?,
        coverImageUrl: data['coverImageUrl'] as String?,
        socialLinks:
            Map<String, String>.from(data['socialLinks'] as Map? ?? {}),
        isVerified: (data['isVerified'] as bool?) ?? false,
        isFeatured: (data['isFeatured'] as bool?) ?? false,
        isPortfolioPublic: (data['isPortfolioPublic'] as bool?) ?? true,
        subscriptionTier: core.SubscriptionTier.values.firstWhere(
          (tier) => tier.name == data['subscriptionTier'],
          orElse: () => core.SubscriptionTier.free,
        ),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        followersCount: (data['followersCount'] as int?) ??
            (data['followerCount'] as int?) ??
            0,
      );
    } catch (e) {
      throw Exception('Error getting artist profile: $e');
    }
  }

  /// Get artist profile by ID
  Future<core.ArtistProfileModel?> getArtistProfileById(
      String profileId) async {
    try {
      final doc = await _artistProfilesCollection.doc(profileId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;

      return core.ArtistProfileModel(
        id: doc.id,
        userId: data['userId'] as String,
        displayName: data['displayName'] as String,
        username: data['username'] as String? ?? '',
        bio: (data['bio'] as String?) ?? '',
        userType: core.UserType.fromString(
            (data['userType'] as String?) ?? core.UserType.artist.name),
        location: data['location'] as String?,
        mediums: List<String>.from(data['mediums'] as Iterable? ?? []),
        styles: List<String>.from(data['styles'] as Iterable? ?? []),
        profileImageUrl: data['profileImageUrl'] as String?,
        coverImageUrl: data['coverImageUrl'] as String?,
        socialLinks:
            Map<String, String>.from(data['socialLinks'] as Map? ?? {}),
        isVerified: (data['isVerified'] as bool?) ?? false,
        isFeatured: (data['isFeatured'] as bool?) ?? false,
        isPortfolioPublic: (data['isPortfolioPublic'] as bool?) ?? true,
        subscriptionTier: core.SubscriptionTier.values.firstWhere(
          (tier) => tier.apiName == data['subscriptionTier'],
          orElse: () => core.SubscriptionTier.free,
        ),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        followersCount: (data['followersCount'] as int?) ??
            (data['followerCount'] as int?) ??
            0,
      );
    } catch (e) {
      throw Exception('Error getting artist profile by ID: $e');
    }
  }

  /// Update artist profile
  Future<void> updateArtistProfile(
    String profileId, {
    String? displayName,
    String? bio,
    String? website,
    List<String>? mediums,
    List<String>? styles,
    String? location,
    String? profileImageUrl,
    String? coverImageUrl,
    Map<String, String>? socialLinks,
    bool? isVerified,
    bool? isFeatured,
    bool? isPortfolioPublic,
    core.SubscriptionTier? subscriptionTier,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now(),
      };

      if (displayName != null) updates['displayName'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (website != null) updates['website'] = website;
      if (mediums != null) updates['mediums'] = mediums;
      if (styles != null) updates['styles'] = styles;
      if (location != null) updates['location'] = location;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
      if (coverImageUrl != null) updates['coverImageUrl'] = coverImageUrl;
      if (socialLinks != null) updates['socialLinks'] = socialLinks;
      if (isVerified != null) updates['isVerified'] = isVerified;
      if (isFeatured != null) updates['isFeatured'] = isFeatured;
      if (isPortfolioPublic != null)
        updates['isPortfolioPublic'] = isPortfolioPublic;
      if (subscriptionTier != null) {
        updates['subscriptionTier'] = subscriptionTier.name;
      }

      await _artistProfilesCollection.doc(profileId).update(updates);
    } catch (e) {
      throw Exception('Error updating artist profile: $e');
    }
  }

  /// Get featured artists
  Future<List<core.ArtistProfileModel>> getFeaturedArtists(
      {int limit = 10}) async {
    try {
      // Query users where userType = 'artist' and isFeatured = true
      final usersQuery = await _usersCollection
          .where('userType', isEqualTo: 'artist')
          .where('isFeatured', isEqualTo: true)
          .limit(limit)
          .get();

      final artists = <core.ArtistProfileModel>[];

      for (final doc in usersQuery.docs) {
        // Check if user has an artist profile
        DocumentSnapshot? artistProfileDoc;
        try {
          final profileQuery = await _artistProfilesCollection
              .where('userId', isEqualTo: doc.id)
              .limit(1)
              .get();

          if (profileQuery.docs.isNotEmpty) {
            artistProfileDoc = profileQuery.docs.first;
          }
        } catch (e) {
          // Ignore errors, use user doc
        }

        // Use artist profile document if available, otherwise use user document
        final sourceDoc = artistProfileDoc ?? doc;
        final artist = core.ArtistProfileModel.fromFirestore(sourceDoc);

        artists.add(artist);
      }

      return artists;
    } catch (e) {
      throw Exception('Error getting featured artists: $e');
    }
  }

  /// Get artists by location
  Future<List<core.ArtistProfileModel>> getArtistsByLocation(
    String location, {
    int limit = 10,
  }) async {
    try {
      // First, query users where userType = 'artist' and location matches
      final usersQuery = await _usersCollection
          .where('userType', isEqualTo: 'artist')
          .where('location', isEqualTo: location)
          .orderBy('createdAt', descending: true)
          .limit(limit * 2) // Get more to account for users without profiles
          .get();

      final List<core.ArtistProfileModel> artists = [];

      for (final userDoc in usersQuery.docs) {
        if (artists.length >= limit) break;

        final userData = userDoc.data() as Map<String, dynamic>;
        final userId = userDoc.id;

        // Try to get the artist profile
        final profileDoc = await _artistProfilesCollection
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        if (profileDoc.docs.isNotEmpty) {
          // User has a profile
          artists.add(
              core.ArtistProfileModel.fromFirestore(profileDoc.docs.first));
        } else {
          // User doesn't have a profile yet, create basic one from user data
          artists.add(core.ArtistProfileModel(
            id: userId,
            userId: userId,
            displayName: (userData['fullName'] as String?) ??
                (userData['displayName'] as String?) ??
                'Unknown Artist',
            username: userData['username'] as String? ?? '',
            bio: userData['bio'] as String? ?? '',
            userType: core.UserType.artist,
            location: userData['location'] as String?,
            mediums: [],
            styles: [],
            profileImageUrl: userData['profileImageUrl'] as String?,
            coverImageUrl: null,
            socialLinks: {},
            isVerified: false,
            isFeatured: false,
            isPortfolioPublic: true,
            subscriptionTier: core.SubscriptionTier.free,
            createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            updatedAt: (userData['updatedAt'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            followersCount: 0,
          ));
        }
      }

      return artists;
    } catch (e) {
      throw Exception('Error getting artists by location: $e');
    }
  }

  /// Get all artists (for discovery)
  Future<List<core.ArtistProfileModel>> getAllArtists({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      // Query users where userType = 'artist'
      Query usersQuery = _usersCollection
          .where('userType', isEqualTo: 'artist')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        // For pagination, we'd need to track the last user document
        // This is simplified - in production, you'd need proper pagination
        usersQuery = usersQuery.startAfterDocument(lastDocument);
      }

      final usersSnapshot = await usersQuery.get();
      final List<core.ArtistProfileModel> artists = [];

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final userId = userDoc.id;

        // Try to get the artist profile
        final profileDoc = await _artistProfilesCollection
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        if (profileDoc.docs.isNotEmpty) {
          // User has a profile
          artists.add(
              core.ArtistProfileModel.fromFirestore(profileDoc.docs.first));
        } else {
          // User doesn't have a profile yet, create basic one from user data
          final now = DateTime.now();
          artists.add(core.ArtistProfileModel(
            id: userId, // Use userId as id since no profile document exists
            userId: userId,
            displayName: (userData['fullName'] as String?) ??
                (userData['displayName'] as String?) ??
                'Unknown Artist',
            username: userData['username'] as String? ?? '',
            bio: userData['bio'] as String? ?? '',
            userType: core.UserType.artist,
            location: userData['location'] as String?,
            mediums: [],
            styles: [],
            profileImageUrl: userData['profileImageUrl'] as String?,
            coverImageUrl: null,
            socialLinks: {},
            isVerified: false,
            isFeatured: false,
            isPortfolioPublic: true,
            subscriptionTier: core.SubscriptionTier.free,
            createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? now,
            updatedAt: (userData['updatedAt'] as Timestamp?)?.toDate() ?? now,
            followersCount: 0,
          ));
        }
      }

      return artists;
    } catch (e) {
      throw Exception('Error getting all artists: $e');
    }
  }

  /// Search artists by name and location
  Future<List<core.ArtistProfileModel>> searchArtists(
    String query, {
    int limit = 20,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final String queryLower = query.toLowerCase().trim();

      // First, get all users with userType = 'artist'
      final usersQuery =
          await _usersCollection.where('userType', isEqualTo: 'artist').get();

      final List<core.UserModel> artistUsers = usersQuery.docs
          .map((doc) => core.UserModel.fromFirestore(doc))
          .toList();

      // Filter users client-side by display name and location
      final filteredUsers = artistUsers.where((user) {
        final displayNameMatch =
            user.fullName.toLowerCase().contains(queryLower) ||
                user.username.toLowerCase().contains(queryLower);
        final locationMatch = user.location.toLowerCase().contains(queryLower);
        final bioMatch = user.bio.toLowerCase().contains(queryLower);

        return displayNameMatch || locationMatch || bioMatch;
      }).toList();

      // Sort by relevance (exact matches first, then partial matches)
      filteredUsers.sort((a, b) {
        final aName = a.fullName.toLowerCase();
        final bName = b.fullName.toLowerCase();

        // Exact display name matches first
        if (aName == queryLower && bName != queryLower) return -1;
        if (bName == queryLower && aName != queryLower) return 1;

        // Display name starts with query
        if (aName.startsWith(queryLower) && !bName.startsWith(queryLower))
          return -1;
        if (bName.startsWith(queryLower) && !aName.startsWith(queryLower))
          return 1;

        // Otherwise, alphabetical order
        return aName.compareTo(bName);
      });

      // Get artist profiles for the top matching users
      final List<core.ArtistProfileModel> artists = [];
      final topUsers = filteredUsers
          .take(limit * 2)
          .toList(); // Get more to account for users without profiles

      for (final user in topUsers) {
        if (artists.length >= limit) break;

        // Try to get the artist profile
        final profileDoc = await _artistProfilesCollection
            .where('userId', isEqualTo: user.id)
            .limit(1)
            .get();

        if (profileDoc.docs.isNotEmpty) {
          // User has a profile
          artists.add(
              core.ArtistProfileModel.fromFirestore(profileDoc.docs.first));
        } else {
          // User doesn't have a profile yet, create basic one from user data
          artists.add(core.ArtistProfileModel(
            id: user.id,
            userId: user.id,
            displayName: user.fullName,
            username: user.username,
            bio: user.bio,
            userType: core.UserType.artist,
            location: user.location,
            mediums: [],
            styles: [],
            profileImageUrl: user.profileImageUrl,
            coverImageUrl: null,
            socialLinks: {},
            isVerified: false,
            isFeatured: false,
            isPortfolioPublic: true,
            subscriptionTier: core.SubscriptionTier.free,
            createdAt: user.createdAt,
            updatedAt: user.createdAt,
            followersCount: 0,
          ));
        }
      }

      return artists.take(limit).toList();
    } catch (e) {
      throw Exception('Error searching artists: $e');
    }
  }
}
