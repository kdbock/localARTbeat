import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_community/artbeat_community.dart' as community;
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:easy_localization/easy_localization.dart';

/// Screen for discovering users and artists on the platform
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  final artist.SubscriptionService _artistSubscriptionService =
      artist.SubscriptionService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  late TabController _tabController;

  // Search and loading state
  final List<UserModel> _searchResults = <UserModel>[];
  List<ArtistProfileModel> _featuredArtists = <ArtistProfileModel>[];
  bool _isLoading = false;

  // Nearby content state
  final List<community.PostModel> _feedItems = <community.PostModel>[];
  final List<UserModel> _nearbyUsers = <UserModel>[];
  final List<ArtistProfileModel> _nearbyArtists = <ArtistProfileModel>[];
  final List<artwork.ArtworkModel> _nearbyArtworks = <artwork.ArtworkModel>[];
  final List<EventModel> _nearbyEvents = <EventModel>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialContent();
  }

  Future<void> _loadInitialContent() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadSuggestedUsers(),
        _loadFeaturedArtists(),
        _loadNearbyContent(),
      ]);
    } catch (e) {
      // debugPrint('Error loading initial content: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNearbyContent() async {
    try {
      // Save current location for caching
      final position = await Geolocator.getCurrentPosition();
      final point = GeoPoint(position.latitude, position.longitude);

      // Load nearby content in parallel
      await Future.wait([
        _loadNearbyUsers(point),
        _loadNearbyArtists(point),
        _loadNearbyArtworks(point),
        _loadNearbyEvents(point),
        _loadNearbyPosts(point),
      ]);
    } catch (e) {
      // debugPrint('Error loading nearby content: $e');
    }
  }

  Future<List<UserModel>> _loadNearbyUsers(GeoPoint location) async {
    try {
      final usersRef = FirebaseFirestore.instance.collection('users');
      final snapshot = await usersRef.orderBy('location').limit(50).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel(
          id: doc.id,
          email: data['email'] as String? ?? '',
          username: data['username'] as String? ?? '',
          fullName: data['fullName'] as String? ?? '',
          bio: data['bio'] as String? ?? '',
          profileImageUrl: data['profileImageUrl'] as String? ?? '',
          location: data['location'] as String? ?? '',
          posts: List<String>.from(
            (data['posts'] ?? <dynamic>[]) as List<dynamic>,
          ),
          engagementStats: data['engagementStats'] != null
              ? EngagementStats.fromFirestore(
                  data['engagementStats'] as Map<String, dynamic>,
                )
              : null,
          captures: (data['captures'] as List<dynamic>? ?? [])
              .map(
                (capture) =>
                    CaptureModel.fromJson(capture as Map<String, dynamic>),
              )
              .toList(),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          lastActive: data['lastActive'] != null
              ? (data['lastActive'] as Timestamp).toDate()
              : null,
          userType: data['userType'] as String?,
          preferences: data['preferences'] as Map<String, dynamic>?,
          experiencePoints: data['experiencePoints'] as int? ?? 0,
          level: data['level'] as int? ?? 1,
          zipCode: data['zipCode'] as String?,
        );
      }).toList();
    } catch (e) {
      // debugPrint('Error loading nearby users: $e');
      return [];
    }
  }

  Future<List<ArtistProfileModel>> _loadNearbyArtists(GeoPoint location) async {
    try {
      // First, get featured artist IDs
      final artistFeatureService = ArtistFeatureService();
      final featuredArtistIds = await artistFeatureService
          .getFeaturedArtistIds();

      final artistsRef = FirebaseFirestore.instance.collection(
        'artistProfiles',
      );

      // Get featured artists first (prioritize these)
      final featuredArtists = <ArtistProfileModel>[];
      if (featuredArtistIds.isNotEmpty) {
        final featuredSnapshot = await artistsRef
            .where(
              FieldPath.documentId,
              whereIn: featuredArtistIds.take(10).toList(),
            )
            .get();

        featuredArtists.addAll(
          featuredSnapshot.docs.map(
            (doc) => ArtistProfileModel.fromFirestore(doc),
          ),
        );
      }

      // Then get other nearby artists, excluding already included featured ones
      final otherSnapshot = await artistsRef
          .orderBy('location')
          .limit(featuredArtists.isEmpty ? 20 : 10)
          .get();

      final otherArtists = otherSnapshot.docs
          .where((doc) => !featuredArtistIds.contains(doc.id))
          .map((doc) => ArtistProfileModel.fromFirestore(doc))
          .toList();

      // Combine: featured artists first, then other nearby artists
      return [...featuredArtists, ...otherArtists];
    } catch (e) {
      // debugPrint('Error loading nearby artists: $e');
      return [];
    }
  }

  Future<List<artwork.ArtworkModel>> _loadNearbyArtworks(
    GeoPoint location,
  ) async {
    try {
      final artworksRef = FirebaseFirestore.instance.collection('artwork');
      final snapshot = await artworksRef
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final locationData = data['location'] as GeoPoint?;
        return artwork.ArtworkModel(
          id: doc.id,
          userId: data['userId'] as String,
          artistProfileId: data['artistProfileId'] as String,
          title: data['title'] as String,
          description: data['description'] as String,
          imageUrl: data['imageUrl'] as String,
          medium: data['medium'] as String,
          styles: List<String>.from(
            (data['styles'] ?? <dynamic>[]) as List<dynamic>,
          ),
          location: locationData != null
              ? '${locationData.latitude}, ${locationData.longitude}'
              : null,
          isForSale: data['isForSale'] as bool? ?? false,
          isSold: data['isSold'] as bool? ?? false,
          price: (data['price'] as num?)?.toDouble(),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      // debugPrint('Error loading nearby artworks: $e');
      return [];
    }
  }

  Future<List<EventModel>> _loadNearbyEvents(GeoPoint point) async {
    try {
      final eventsRef = FirebaseFirestore.instance.collection('events');
      final snapshot = await eventsRef
          .where('location', isNull: false)
          .where('endDate', isGreaterThan: DateTime.now())
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return EventModel(
          id: doc.id,
          title: data['title'] as String,
          description: data['description'] as String,
          startDate: (data['startDate'] as Timestamp).toDate(),
          endDate: data['endDate'] != null
              ? (data['endDate'] as Timestamp).toDate()
              : null,
          location: data['location'] as String,
          imageUrl: data['imageUrl'] as String?,
          artistId: data['artistId'] as String,
          isPublic: data['isPublic'] as bool? ?? true,
          attendeeIds: List<String>.from(
            (data['attendeeIds'] ?? <dynamic>[]) as List<dynamic>,
          ),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      // debugPrint('Error loading nearby events: $e');
      return [];
    }
  }

  Future<List<community.PostModel>> _loadNearbyPosts(GeoPoint location) async {
    try {
      final postsRef = FirebaseFirestore.instance.collection('posts');
      final snapshot = await postsRef
          .where('location', isNull: false)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final posts = snapshot.docs.map((doc) {
        final data = doc.data();
        return community.PostModel(
          id: doc.id,
          userId: data['userId'] as String,
          userName: data['userName'] as String,
          userPhotoUrl: data['userPhotoUrl'] as String? ?? '',
          content: data['content'] as String,
          imageUrls: List<String>.from(
            (data['imageUrls'] ?? <dynamic>[]) as List<dynamic>,
          ),
          tags: List<String>.from(
            (data['tags'] ?? <dynamic>[]) as List<dynamic>,
          ),
          location: data['location'] as String,
          geoPoint: data['geoPoint'] as GeoPoint?,
          zipCode: data['zipCode'] as String?,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          engagementStats: data['engagementStats'] != null
              ? EngagementStats.fromMap(
                  data['engagementStats'] as Map<String, dynamic>,
                )
              : null,
          isPublic: data['isPublic'] as bool? ?? true,
          mentionedUsers: data['mentionedUsers'] != null
              ? List<String>.from(
                  (data['mentionedUsers'] ?? <dynamic>[]) as List<dynamic>,
                )
              : null,
          metadata: data['metadata'] as Map<String, dynamic>?,
          isUserVerified: data['isUserVerified'] as bool? ?? false,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _feedItems.clear();
          _feedItems.addAll(posts);
        });
      }

      return posts;
    } catch (e) {
      // debugPrint('Error loading nearby posts: $e');
      return [];
    }
  }

  Future<void> _loadSuggestedUsers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _userService.getSuggestedUsers();
      if (!mounted) return;

      setState(() {
        _searchResults.clear();
        _searchResults.addAll(users);
      });
    } catch (e) {
      if (!mounted) return;

      // debugPrint('Error loading suggested users: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile_discover_offline_users'.tr()),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFeaturedArtists() async {
    try {
      final coreArtists = await _subscriptionService.getFeaturedArtists();
      if (!mounted) return;

      final artists = await Future.wait(
        coreArtists.map((a) async {
          final artistProfile = await _artistSubscriptionService
              .getArtistProfileById(a.id);
          if (artistProfile == null) {
            // Create a minimal artist profile from core model
            return ArtistProfileModel(
              id: a.id,
              userId: a.userId,
              displayName: a.displayName,
              bio: a.bio ?? '',
              userType: UserType.artist,
              mediums: const <String>[],
              styles: const <String>[],
              subscriptionTier: a.subscriptionTier,
              createdAt: a.createdAt,
              updatedAt: DateTime.now(),
            );
          }
          return artistProfile;
        }),
      );

      setState(() {
        _featuredArtists = artists.cast<ArtistProfileModel>();
      });
    } catch (e) {
      if (!mounted) return;

      // debugPrint('Error loading featured artists: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile_discover_offline_artists'.tr()),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isLoading = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final users = await _userService.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults.clear();
          _searchResults.addAll(users);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching users: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar at the top
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),

          // Tab bar for Users and Artists
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'People'),
              Tab(text: 'Artists'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
          ),

          // Art Walk Banner
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/art-walk/map'),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade300,
                    Colors.deepPurple.shade700,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((255 * 0.2).round()),
                    offset: const Offset(0, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Art Walk',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Discover public art in your area or create your own custom art walks',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.map_outlined, color: Colors.white, size: 40),
                ],
              ),
            ),
          ),

          // Content area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // People tab
                _buildPeopleTab(),

                // Artists tab
                _buildArtistsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Display horizontal sliders for various nearby content
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Community feed slider placeholder
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Community Feed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: _feedItems.isEmpty
                ? Center(child: Text('profile_discover_no_feed'.tr()))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _feedItems.length,
                    itemBuilder: (context, index) {
                      final item = _feedItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: 200,
                          child: Center(child: Text(item.content)),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),
          // Users nearby slider placeholder
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Users Nearby',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: _nearbyUsers.isEmpty
                ? Center(child: Text('profile_discover_no_users'.tr()))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _nearbyUsers.length,
                    itemBuilder: (context, index) {
                      final user = _nearbyUsers[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            const CircleAvatar(radius: 30),
                            const SizedBox(height: 8),
                            Text(user.fullName),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),
          // Artists nearby slider placeholder
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Artists Nearby',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: _nearbyArtists.isEmpty
                ? Center(child: Text('profile_discover_no_artists'.tr()))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _nearbyArtists.length,
                    itemBuilder: (context, index) {
                      final artistProfile = _nearbyArtists[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage:
                                      ImageUrlValidator.safeNetworkImage(
                                        artistProfile.profileImageUrl,
                                      ),
                                  child:
                                      !ImageUrlValidator.isValidImageUrl(
                                        artistProfile.profileImageUrl,
                                      )
                                      ? Text(
                                          artistProfile.displayName.isNotEmpty
                                              ? artistProfile.displayName[0]
                                                    .toUpperCase()
                                              : '?',
                                          style: const TextStyle(fontSize: 20),
                                        )
                                      : null,
                                ),
                                // Featured indicator
                                FutureBuilder<bool>(
                                  future: ArtistFeatureService()
                                      .hasActiveFeature(
                                        artistProfile.id,
                                        FeatureType.artistFeatured,
                                      ),
                                  builder: (context, snapshot) {
                                    if (snapshot.data == true) {
                                      return Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.star,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 70,
                              child: Text(
                                artistProfile.displayName,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),
          // Artwork nearby slider placeholder
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Artwork Nearby',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: _nearbyArtworks.isEmpty
                ? Center(child: Text('profile_discover_no_artwork'.tr()))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _nearbyArtworks.length,
                    itemBuilder: (context, index) {
                      final art = _nearbyArtworks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: 140,
                          child: Center(child: Text(art.title)),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),
          // Events nearby slider placeholder
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Events Nearby',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: _nearbyEvents.isEmpty
                ? Center(child: Text('profile_discover_no_events'.tr()))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _nearbyEvents.length,
                    itemBuilder: (context, index) {
                      final event = _nearbyEvents[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: 180,
                          child: Center(child: Text(event.title)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Browse artists button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/artist/browse');
            },
            icon: const Icon(Icons.search),
            label: const Text('Browse All Artists'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),

        // Artist subscription card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Card(
            elevation: 2,
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/artist/subscription');
              },
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Are you an artist?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Icon(
                          Icons.palette,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create your artist profile and showcase your work to art enthusiasts worldwide.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/artist/subscription');
                      },
                      child: const Text('Learn More'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Featured artists section
        const Padding(
          padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: Text(
            'Featured Artists',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // Featured artists list
        Expanded(
          child: _featuredArtists.isEmpty
              ? const Center(child: Text('No featured artists available'))
              : ListView.builder(
                  itemCount: _featuredArtists.length,
                  itemBuilder: (context, index) {
                    final artist = _featuredArtists[index];
                    return ListTile(
                      leading: Stack(
                        children: [
                          UserAvatar(
                            imageUrl: artist.profileImageUrl,
                            displayName: artist.displayName,
                            radius: 20,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Text(artist.displayName),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Featured',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        artist.styles.isNotEmpty
                            ? artist.styles.first
                            : artist.mediums.isNotEmpty
                            ? artist.mediums.first
                            : 'Artist',
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/artist/public-profile',
                          arguments: {'artistId': artist.userId},
                        );
                      },
                      trailing: _FollowButton(
                        artistProfile: artist,
                        subscriptionService: _artistSubscriptionService,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FollowButton extends StatefulWidget {
  final ArtistProfileModel artistProfile;
  final artist.SubscriptionService subscriptionService;

  const _FollowButton({
    required this.artistProfile,
    required this.subscriptionService,
  });

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _isFollowing = false;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    try {
      final isFollowing = await widget.subscriptionService.isFollowingArtist(
        artistProfileId: widget.artistProfile.id,
      );
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final newFollowState = await widget.subscriptionService
          .toggleFollowArtist(artistProfileId: widget.artistProfile.id);

      if (mounted) {
        setState(() {
          _isFollowing = newFollowState;
          _isUpdating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newFollowState
                  ? 'You are now following ${widget.artistProfile.displayName}'
                  : 'You have unfollowed ${widget.artistProfile.displayName}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 80,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: _isUpdating ? null : _toggleFollow,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isFollowing
            ? Colors.grey[300]
            : Theme.of(context).primaryColor,
        foregroundColor: _isFollowing ? Colors.black87 : Colors.white,
        minimumSize: const Size(80, 36),
      ),
      child: _isUpdating
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(_isFollowing ? 'Following' : 'Follow'),
    );
  }
}
