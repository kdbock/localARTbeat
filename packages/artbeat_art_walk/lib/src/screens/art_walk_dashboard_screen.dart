import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_ads/artbeat_ads.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

// Dashboard specific colors (using design system colors)
class DashboardColors {
  static const Color primaryTeal = ArtWalkDesignSystem.primaryTeal;
  static const Color primaryTealLight = ArtWalkDesignSystem.primaryTealLight;
  static const Color primaryTealDark = ArtWalkDesignSystem.primaryTealDark;
  static const Color accentOrange = ArtWalkDesignSystem.accentOrange;
  static const Color accentOrangeLight = ArtWalkDesignSystem.accentOrangeLight;
  static const Color backgroundGradientStart =
      ArtWalkDesignSystem.backgroundGradientStart;
  static const Color backgroundGradientEnd =
      ArtWalkDesignSystem.backgroundGradientEnd;
  static const Color cardBackground = ArtWalkDesignSystem.cardBackground;
  static const Color textPrimary = ArtWalkDesignSystem.textPrimary;
  static const Color textSecondary = ArtWalkDesignSystem.textSecondary;
  static const Color headingDarkPurple = Color(
    0xFF2D1B69,
  ); // Dark purple, almost black
}

/// Redesigned Art Walk Dashboard Screen
/// Welcome Traveler, User Name - Where will art take you today?
/// - Map widget that syncs to user location and populates local captures
/// - Captures widget (local, user captures)
/// - Art walks widget (local, user created)
/// - Achievements related to Art Walk
class ArtWalkDashboardScreen extends StatefulWidget {
  const ArtWalkDashboardScreen({super.key});

  @override
  State<ArtWalkDashboardScreen> createState() => _ArtWalkDashboardScreenState();
}

class _ArtWalkDashboardScreenState extends State<ArtWalkDashboardScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Position? _currentPosition;
  List<CaptureModel> _localCaptures = [];
  List<AchievementModel> _artWalkAchievements = [];
  UserModel? _currentUser;
  bool _isDisposed = false;

  // Engagement boost state variables
  int _currentStreak = 0;
  int _activeWalkersNearby = 0;

  final ArtWalkService _artWalkService = ArtWalkService();
  final AchievementService _achievementService = AchievementService();
  final UserService _userService = UserService();
  final CaptureService _captureService = CaptureService();
  final InstantDiscoveryService _discoveryService = InstantDiscoveryService();
  final SocialService _socialService = SocialService();

  // Notification monitoring
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  // Instant Discovery state
  int _nearbyArtCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _startNotificationMonitoring();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _notificationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startNotificationMonitoring() {
    // Start monitoring for nearby art notifications when we have location
    if (_currentPosition != null) {
      _notificationSubscription = _discoveryService
          .monitorNearbyArtNotifications(
            userPosition: _currentPosition!,
            notificationRadiusMeters: 100, // Notify when art is within 100m
            checkInterval: const Duration(
              seconds: 30,
            ), // Check every 30 seconds
          )
          .listen((notification) {
            if (_isDisposed || !mounted) return;

            // Handle notification - could show in-app notification or update UI
            if (notification['type'] == 'nearby_art_discovered') {
              // Update nearby art count if needed
              setState(() {
                // Could update UI to show notification or refresh nearby art count
              });

              // Show a brief snackbar notification
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '🎨 ${notification['art']['title'] ?? 'Art'} is nearby! (${notification['distanceText']})',
                  ),
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'View',
                    onPressed: () {
                      // Navigate to instant discovery radar
                      Navigator.of(context).pushNamed('/instant-discovery');
                    },
                  ),
                ),
              );
            }
          });
    }
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadCurrentUser(),
      _loadUserLocationAndSetMap(),
      _loadLocalCaptures(),
      _loadArtWalkAchievements(),
      _loadEngagementData(),
      _loadNearbyArtCount(),
    ]);
  }

  Future<void> _loadNearbyArtCount() async {
    try {
      if (_currentPosition != null) {
        final nearbyArt = await _discoveryService.getNearbyArt(
          _currentPosition!,
          radiusMeters: 500,
        );
        if (!_isDisposed && mounted) {
          setState(() => _nearbyArtCount = nearbyArt.length);
        }
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userService.getCurrentUserModel();
      if (!_isDisposed && mounted) {
        setState(() => _currentUser = user);
      }
    } catch (e) {
      // debugPrint('Error loading current user: $e');
    }
  }

  Future<void> _loadUserLocationAndSetMap() async {
    try {
      // First try to get location from stored ZIP code
      if (_currentUser?.zipCode != null && _currentUser!.zipCode!.isNotEmpty) {
        final coordinates = await LocationUtils.getCoordinatesFromZipCode(
          _currentUser!.zipCode!,
        );
        if (coordinates != null && mounted) {
          _updateMapPosition(coordinates.latitude, coordinates.longitude);
          return;
        }
      }

      // Then try to get current location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!_isDisposed && mounted) {
        _updateMapPosition(position.latitude, position.longitude);
      }
    } catch (e) {
      // debugPrint('Error getting location: $e');
      // Default to Asheville, NC
      _updateMapPosition(35.5951, -82.5515);
    }
  }

  Future<void> _loadLocalCaptures() async {
    try {
      // Load all public captures for discovery
      final captures = await _captureService.getAllCaptures(limit: 50);
      if (!_isDisposed && mounted) {
        setState(() => _localCaptures = captures);
      }
    } catch (e) {
      // debugPrint('Error loading local captures: $e');
    }
  }

  Future<void> _loadArtWalkAchievements() async {
    try {
      final userId = _artWalkService.getCurrentUserId();
      if (userId != null) {
        final achievements = await _achievementService.getUserAchievements(
          userId: userId,
        );
        if (!_isDisposed && mounted) {
          setState(() => _artWalkAchievements = achievements);
        }
      }
    } catch (e) {
      // debugPrint('Error loading achievements: $e');
    }
  }

  Future<void> _loadEngagementData() async {
    try {
      // Load engagement boost data
      await Future.wait([
        _loadUserStreak(),
        _loadFeaturedWalk(),
        _loadActiveWalkersNearby(),
        _loadFriendsRecentWalks(),
        _loadTrendingCaptures(),
      ]);
    } catch (e) {
      // debugPrint('Error loading engagement data: $e');
    }
  }

  Future<void> _loadUserStreak() async {
    try {
      // Mock data for now - in real implementation, this would come from user service
      if (!_isDisposed && mounted) {
        setState(() => _currentStreak = 5); // Example: 5-day streak
      }
    } catch (e) {
      // debugPrint('Error loading user streak: $e');
    }
  }

  Future<void> _loadFeaturedWalk() async {
    try {
      // Mock data for now - in real implementation, this would come from content service
      // Featured walk data loaded
    } catch (e) {
      // debugPrint('Error loading featured walk: $e');
    }
  }

  Future<void> _loadActiveWalkersNearby() async {
    try {
      if (_currentPosition != null) {
        final count = await _socialService.getActiveWalkersNearby(
          userPosition: _currentPosition!,
        );
        if (!_isDisposed && mounted) {
          setState(() => _activeWalkersNearby = count);
        }
      }
    } catch (e) {
      // print('Error loading active walkers: $e');
    }
  }

  Future<void> _loadFriendsRecentWalks() async {
    try {
      // For now, use empty friend list - in future this would come from user relationships
      final friendIds = <String>[];
      await _socialService.getFriendsRecentWalks(friendIds: friendIds);
      // Friends walks data loaded
    } catch (e) {
      // print('Error loading friends recent walks: $e');
    }
  }

  Future<void> _loadTrendingCaptures() async {
    try {
      // Note: Trending captures functionality ready for future implementation
      // Could be used for a trending section or featured content
      if (!_isDisposed && mounted) {
        // Placeholder for future trending captures feature
      }
    } catch (e) {
      // debugPrint('Error loading trending captures: $e');
    }
  }

  Position _createPosition(double latitude, double longitude) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  void _updateMapPosition(double latitude, double longitude) {
    if (_isDisposed) return;
    setState(() {
      _currentPosition = _createPosition(latitude, longitude);
    });
    _updateMapMarkers();

    // Load nearby art count for instant discovery
    _loadNearbyArtCount();

    // Start notification monitoring for nearby art
    _startNotificationMonitoring();

    // Animate camera to new position
    if (_mapController != null && mounted) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(latitude, longitude), zoom: 13),
        ),
      );
    }
  }

  void _updateMapMarkers() {
    if (!mounted || _currentPosition == null || _isDisposed) return;

    final Set<Marker> markers = {
      // User location marker
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };

    // Add local capture markers
    for (final capture in _localCaptures) {
      if (capture.location != null) {
        markers.add(
          Marker(
            markerId: MarkerId('capture_${capture.id}'),
            position: LatLng(
              capture.location!.latitude,
              capture.location!.longitude,
            ),
            infoWindow: InfoWindow(
              title: capture.title ?? capture.artistName ?? 'Local Art',
              snippet: capture.locationName ?? 'Art Discovery',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            onTap: () => _showCaptureDetails(capture),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  void _showCaptureDetails(CaptureModel capture) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (ImageUrlValidator.isValidImageUrl(capture.imageUrl))
                  Container(
                    height: 200,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: ImageUrlValidator.isValidImageUrl(capture.imageUrl)
                          ? DecorationImage(
                              image: ImageUrlValidator.safeNetworkImage(
                                capture.imageUrl,
                              )!,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),
                Text(
                  capture.title ?? 'Untitled Art Piece',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (capture.artistName?.isNotEmpty == true) ...[
                  Text(
                    'Artist: ${capture.artistName}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: DashboardColors.primaryTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (capture.description?.isNotEmpty == true) ...[
                  Text(
                    capture.description!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                ],
                if (capture.locationName?.isNotEmpty == true)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: DashboardColors.primaryTeal,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          capture.locationName!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context); // Close the bottom sheet
                            // Navigate to create art walk with this capture pre-selected
                            Navigator.pushNamed(
                              context,
                              '/art-walk/create',
                              arguments: {'preSelectedCapture': capture},
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: DashboardColors.accentOrange.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: DashboardColors.accentOrange.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFFF7043), // Orange
                                          Color(0xFFFF9E80), // Light Orange
                                        ],
                                      ).createShader(
                                        Rect.fromLTWH(
                                          0,
                                          0,
                                          bounds.width,
                                          bounds.height,
                                        ),
                                      ),
                                  child: const Icon(
                                    Icons.add_location,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Add to Art Walk',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: DashboardColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close, color: Colors.grey, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Close',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Artist Monetization CTAs
                if (capture.artistName?.isNotEmpty == true) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DashboardColors.primaryTeal.withValues(alpha: 0.1),
                          DashboardColors.accentOrange.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: DashboardColors.primaryTeal.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: DashboardColors.primaryTeal.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: DashboardColors.primaryTeal,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Support ${capture.artistName}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: DashboardColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(
                                      context,
                                      '/artist/profile',
                                      arguments: {
                                        'artistName': capture.artistName,
                                      },
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: DashboardColors.primaryTeal
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: DashboardColors.primaryTeal
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person,
                                          color: DashboardColors.primaryTeal,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'View Profile',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: DashboardColors.primaryTeal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showArtistSupportDialog(
                                      capture.artistName!,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: DashboardColors.accentOrange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.card_giftcard,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Send Tip',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Artist's other works or events
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.event,
                                color: DashboardColors.primaryTeal,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'See more works by ${capture.artistName}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: DashboardColors.textSecondary,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: DashboardColors.primaryTeal,
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Ad Space - Bottom of Capture Detail
                const SizedBox.shrink(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showArtistDiscoveryMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.palette,
                      color: DashboardColors.primaryTeal,
                      size: 24,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Artist Discovery',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: DashboardColors.headingDarkPurple,
                            ),
                          ),
                          Text(
                            'Connect with artists and explore their work',
                            style: TextStyle(
                              fontSize: 14,
                              color: DashboardColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Menu items
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildDiscoveryTile(
                      icon: Icons.person_search,
                      title: 'Find Artists',
                      subtitle: 'Discover local and featured artists',
                      color: DashboardColors.primaryTeal,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/artist-search');
                      },
                    ),
                    _buildDiscoveryTile(
                      icon: Icons.trending_up,
                      title: 'Trending',
                      subtitle: 'Popular artists and trending art',
                      color: DashboardColors.accentOrange,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/trending');
                      },
                    ),
                    _buildDiscoveryTile(
                      icon: Icons.palette,
                      title: 'Browse Artwork',
                      subtitle: 'Explore art collections and galleries',
                      color: DashboardColors.primaryTealLight,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/artwork/browse');
                      },
                    ),
                    _buildDiscoveryTile(
                      icon: Icons.location_on,
                      title: 'Local Scene',
                      subtitle: 'Art events and spaces near you',
                      color: DashboardColors.primaryTealDark,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/local');
                      },
                    ),
                    _buildDiscoveryTile(
                      icon: Icons.account_circle,
                      title: 'My Profile',
                      subtitle: 'View and edit your profile',
                      color: DashboardColors.textSecondary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/profile');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveryTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: DashboardColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: DashboardColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: _buildBackgroundDecoration(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // 1. Instant Discovery Hero Section (ARTbeat's star feature)
                _buildInstantDiscoveryHeroSection(),
                const SizedBox(height: 16),

                // Slot 1: Badge/banner at top
                const AdBadgeWidget(
                  zone: LocalAdZone.featured,
                  width: double.infinity,
                  height: 80,
                ),
                const SizedBox(height: 16),

                // 2. Activity & Progress (combined social proof + gamification)
                _buildActivityAndProgressSection(),
                const SizedBox(height: 16),

                // Slot 2: Native ad card after progress
                const AdNativeCardWidget(
                  zone: LocalAdZone.featured,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                const SizedBox(height: 16),

                // 3. Quick Actions Dashboard
                _buildQuickActionsDashboard(),
                const SizedBox(height: 24),

                // Slot 3: Promotion banner between sections
                const AdSmallBannerWidget(
                  zone: LocalAdZone.featured,
                  height: 100,
                ),
                const SizedBox(height: 24),

                // 4. Discover & Explore
                _buildDiscoverAndExploreSection(),
                const SizedBox(height: 24),

                // Slot 4: CTA card before bottom
                const AdCtaCardWidget(
                  zone: LocalAdZone.featured,
                  ctaText: 'Explore More',
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== INSTANT DISCOVERY DASHBOARD METHODS ====================

  Widget _buildInstantDiscoveryHeroSection() {
    return Container(
      decoration: _buildGlassDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with radar icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(
                        255,
                        255,
                        165,
                        137,
                      ).withValues(alpha: 0.3),
                      const Color.fromARGB(
                        255,
                        73,
                        138,
                        144,
                      ).withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.radar, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Instant Discovery',
                style: TextStyle(
                  color: DashboardColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Dynamic messaging based on nearby art
          _buildDynamicDiscoveryMessage(),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.explore,
                  label: 'Start Discovery',
                  color: DashboardColors.accentOrange,
                  onTap: () => _navigateToInstantDiscovery(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.map,
                  label: 'View Map',
                  color: DashboardColors.primaryTeal,
                  onTap: () => _showNearbyArtMap(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicDiscoveryMessage() {
    final artCount = _nearbyArtCount;
    final activeUsers = _activeWalkersNearby;

    String message;
    String subMessage;

    if (artCount == 0) {
      message = "No art nearby right now";
      subMessage = "Try moving to a different location or check back later";
    } else if (artCount == 1) {
      message = "1 artwork nearby!";
      subMessage = "Perfect for a quick discovery";
    } else if (artCount < 5) {
      message = "$artCount artworks nearby!";
      subMessage = "Great opportunity for discovery";
    } else {
      message = "$artCount artworks nearby!";
      subMessage = "Amazing art scene around you";
    }

    if (activeUsers > 0) {
      subMessage += " • $activeUsers active explorers";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: const TextStyle(
            color: DashboardColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subMessage,
          style: const TextStyle(
            color: DashboardColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityAndProgressSection() {
    return Container(
      decoration: _buildGlassDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with activity indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.green,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Activity & Progress',
                style: TextStyle(
                  color: DashboardColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Live Activity Feed (compact)
          const SocialActivityFeed(maxItems: 1),
          const SizedBox(height: 16),

          // Quick Progress Stats
          Row(
            children: [
              // Current streak
              Expanded(
                child: _buildCompactStatCard(
                  icon: Icons.local_fire_department,
                  iconColor: Colors.orange,
                  value: '$_currentStreak',
                  label: 'Streak',
                ),
              ),
              const SizedBox(width: 8),
              // Total discoveries
              Expanded(
                child: _buildCompactStatCard(
                  icon: Icons.explore,
                  iconColor: Colors.blue,
                  value: '${_localCaptures.length}',
                  label: 'Found',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: DashboardColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: DashboardColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverAndExploreSection() {
    return Container(
      decoration: _buildGlassDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: DashboardColors.primaryTeal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.explore,
                  color: DashboardColors.primaryTeal,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Discover & Explore',
                style: TextStyle(
                  color: DashboardColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Nearby Art Clusters
          if (_localCaptures.isEmpty)
            _buildEmptyClustersState()
          else
            _buildClustersList(),

          const SizedBox(height: 16),

          // Recent Achievements (compact)
          if (_artWalkAchievements.isNotEmpty) ...[
            const Text(
              'Recent Achievements',
              style: TextStyle(
                color: DashboardColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildCompactAchievementsList(),
          ] else
            _buildEmptyAchievementsState(),
        ],
      ),
    );
  }

  Widget _buildEmptyClustersState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_searching,
            color: Colors.white.withValues(alpha: 0.5),
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'No art clusters nearby',
            style: TextStyle(color: DashboardColors.textPrimary, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Move around to discover art in your area',
            style: TextStyle(
              color: DashboardColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClustersList() {
    // Group captures by location/area
    final clusters = _groupCapturesByLocation();

    return Column(
      children: clusters.entries.map((entry) {
        final locationName = entry.key;
        final captures = entry.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToLocation(locationName, captures),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: DashboardColors.accentOrange.withValues(
                          alpha: 0.2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${captures.length}',
                          style: const TextStyle(
                            color: DashboardColors.accentOrange,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locationName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${captures.length} artwork${captures.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Map<String, List<CaptureModel>> _groupCapturesByLocation() {
    final clusters = <String, List<CaptureModel>>{};

    for (final capture in _localCaptures) {
      final locationName = capture.locationName ?? 'Unknown Location';
      if (!clusters.containsKey(locationName)) {
        clusters[locationName] = [];
      }
      clusters[locationName]!.add(capture);
    }

    return clusters;
  }

  Widget _buildCompactAchievementsList() {
    return Column(
      children: _artWalkAchievements.take(2).map((achievement) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 12,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  achievement.title,
                  style: const TextStyle(
                    color: DashboardColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ==================== NAVIGATION METHODS ====================

  void _navigateToInstantDiscovery() {
    Navigator.pushNamed(context, '/art-walk/instant-discovery');
  }

  void _showNearbyArtMap() {
    // Show map modal or navigate to map view
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMapModal(),
    );
  }

  void _navigateToLocation(String locationName, List<CaptureModel> captures) {
    // Navigate to location-specific view or show captures for that location
    Navigator.pushNamed(
      context,
      '/art-walk/location',
      arguments: {'locationName': locationName, 'captures': captures},
    );
  }

  Widget _buildMapModal() {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Nearby Art Map',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),

            // Map content
            Expanded(child: _buildInteractiveMapSection()),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          DashboardColors.primaryTealLight,
          DashboardColors.accentOrangeLight,
          DashboardColors.backgroundGradientStart,
          DashboardColors.backgroundGradientEnd,
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ),
    );
  }

  BoxDecoration _buildGlassDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      boxShadow: [
        BoxShadow(
          color: DashboardColors.primaryTeal.withValues(alpha: 0.15),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _buildQuickActionsDashboard() {
    return Container(
      decoration: _buildGlassDecoration(),
      padding: const EdgeInsets.all(24),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
        children: [
          _buildQuickActionCard(
            'Start Art Walk',
            Icons.directions_walk_rounded,
            DashboardColors.accentOrange,
            () => Navigator.pushNamed(context, '/art-walk/create'),
          ),
          _buildInstantDiscoveryCard(),
          _buildSponsoredQuickActionCard(
            'Sponsored Walk',
            Icons.local_cafe_rounded,
            const Color(0xFF8E24AA), // Purple for sponsored content
            () => _showSponsoredWalkDialog(),
            'Coffee Shop Tour',
          ),
          _buildQuickActionCard(
            'Achievements',
            Icons.emoji_events_rounded,
            DashboardColors.accentOrangeLight,
            () => Navigator.pushNamed(context, '/achievements'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: DashboardColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstantDiscoveryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.primaryTeal.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openInstantDiscovery,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: DashboardColors.primaryTeal.withValues(
                          alpha: 0.2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.radar,
                        size: 16,
                        color: DashboardColors.primaryTeal,
                      ),
                    ),
                    if (_nearbyArtCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: DashboardColors.accentOrange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Text(
                            '$_nearbyArtCount',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                const Flexible(
                  child: Text(
                    'Instant Discovery',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSponsoredQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    String sponsorText,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(icon, size: 16, color: Colors.white),
                    ),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    sponsorText,
                    style: TextStyle(
                      fontSize: 6,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openInstantDiscovery() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'art_walk_art_walk_dashboard_text_getting_your_location'.tr(),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Get nearby art
      final nearbyArt = await _discoveryService.getNearbyArt(
        _currentPosition!,
        radiusMeters: 500,
      );

      if (!mounted) return;

      if (nearbyArt.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_art_walk_dashboard_text_no_art_nearby'.tr(),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Navigate to radar screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute<dynamic>(
          builder: (context) => InstantDiscoveryRadarScreen(
            userPosition: _currentPosition!,
            initialNearbyArt: nearbyArt,
          ),
        ),
      );

      // Refresh nearby art count if discoveries were made
      if (result == true && mounted) {
        _loadNearbyArtCount();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_art_walk_dashboard_error_error_loading_nearby'.tr(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSponsoredWalkDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sponsor logo/icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E24AA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_cafe,
                    size: 32,
                    color: Color(0xFF8E24AA),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Coffee Shop Art Tour',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sponsored by Local Brew Co.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Discover amazing street art while exploring the best coffee shops in town. Complete this walk and get 10% off your next coffee!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Maybe Later',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/art-walk/create',
                            arguments: {'sponsoredWalk': 'coffee-shop-tour'},
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8E24AA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Start Walk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInteractiveMapSection() {
    return Container(
      decoration: _buildGlassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Local Art Map',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: DashboardColors.headingDarkPurple,
                    ),
                  ),
                ),
                _buildModernButton(
                  'Explore',
                  Icons.fullscreen_rounded,
                  () => Navigator.pushNamed(context, '/art-walk/map'),
                ),
              ],
            ),
          ),
          Container(
            height: 200,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _currentPosition != null
                  ? (kIsWeb
                        ? _buildWebMapFallback()
                        : GoogleMap(
                            onMapCreated: (controller) =>
                                _mapController = controller,
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              zoom: 13,
                            ),
                            markers: _markers,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                          ))
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showArtistSupportDialog(String artistName) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DashboardColors.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 32,
                    color: DashboardColors.primaryTeal,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Support $artistName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Show your appreciation for this artist',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildTipButton('\$2', 2.0)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTipButton('\$5', 5.0)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTipButton('\$10', 10.0)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DashboardColors.accentOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: DashboardColors.accentOrange,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tips help artists continue creating amazing public art',
                          style: TextStyle(
                            fontSize: 12,
                            color: DashboardColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Maybe Later',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to artist profile for more support options
                          Navigator.pushNamed(
                            context,
                            '/artist/profile',
                            arguments: {'artistName': artistName},
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DashboardColors.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'View Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTipButton(String amount, double value) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Thank you for supporting the artist with $amount!',
              ),
              backgroundColor: DashboardColors.primaryTeal,
              duration: const Duration(seconds: 3),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: DashboardColors.accentOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DashboardColors.accentOrange.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DashboardColors.accentOrange,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildWebMapFallback() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 8),
            Text(
              'Local Art Map',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Map view available on mobile',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAchievementsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: DashboardColors.cardBackground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            color: DashboardColors.accentOrange.withValues(alpha: 0.5),
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Your achievement gallery awaits!',
            style: TextStyle(
              color: DashboardColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Start discovering art to unlock amazing achievements',
            style: TextStyle(
              color: DashboardColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
