import 'dart:async';
import 'dart:io' show SocketException;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_art_walk/src/widgets/art_walk_drawer.dart';

import 'package:artbeat_art_walk/src/theme/art_walk_design_system.dart';

/// Screen that displays a map with nearby captures and art walks
class ArtWalkMapScreen extends StatefulWidget {
  const ArtWalkMapScreen({super.key});

  @override
  State<ArtWalkMapScreen> createState() => _ArtWalkMapScreenState();
}

class _ArtWalkMapScreenState extends State<ArtWalkMapScreen> {
  // Services
  late final CaptureService _captureService;
  late final UserService _userService;

  // Scaffold key for drawer control
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Map controller and state
  GoogleMapController? _mapController;
  LatLng? _currentMapCenter; // Track current map center for filtering
  String _currentZipCode = '';
  bool _hasMovedToUserLocation = false;
  bool _isLoading = true;
  bool _isSearchingZip = false;
  bool _hasMapError = false;
  String _mapErrorMessage = '';
  bool _showCapturesSlider = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _notificationSubscription;
  int _unreadNotificationCount = 0;

  // Map data
  final Set<Marker> _markers = <Marker>{};
  List<CaptureModel> _nearbyCaptures = [];
  String _artFilter = 'public'; // 'public', 'my_captures', 'my_artwalks'

  // Location and timer
  Timer? _locationUpdateTimer;
  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(35.23838, -77.52658), // Kinston, NC - 28501
    zoom: 10.0,
  );

  @override
  void initState() {
    super.initState();
    _captureService = context.read<CaptureService>();
    _userService = context.read<UserService>();
    _initializeMapsAndLocation();
    _listenToNotificationBadge();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _mapController?.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  /// Initialize maps and location
  Future<void> _initializeMapsAndLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasMapError = false;
    });

    try {
      // Get user's saved ZIP code from profile
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userProfile = await _userService.getUserProfile(user.uid);
        if (userProfile != null &&
            userProfile['zipCode'] != null &&
            userProfile['zipCode'].toString().isNotEmpty) {
          final profileZipCode = userProfile['zipCode'].toString();
          if (mounted) {
            setState(() {
              _currentZipCode = profileZipCode;
            });
          }
          AppLogger.info('Loaded ZIP code from profile: $profileZipCode');
        }
      }

      // If no saved ZIP code, default to Kinston, NC
      if (_currentZipCode.isEmpty) {
        if (mounted) {
          setState(() {
            _currentZipCode = '28501'; // Default to Kinston, NC
          });
        }
      }

      // Priority 1: Try to get current location
      final position = await _tryGetCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentMapCenter = LatLng(position.latitude, position.longitude);
        });
        await _moveMapToLocation(position.latitude, position.longitude, 14.0);
        await _loadNearbyCaptures(position.latitude, position.longitude);
        _startLocationUpdates();
      } else if (_currentZipCode.isNotEmpty) {
        // Priority 2: Use user's saved ZIP code
        AppLogger.info('Using saved ZIP code: $_currentZipCode');
        final coordinates = await _getCoordinatesFromZipCode(_currentZipCode);
        if (coordinates != null) {
          AppLogger.info(
            'Moving map to ZIP code $_currentZipCode coordinates: ${coordinates.latitude}, ${coordinates.longitude}',
          );
          if (mounted) {
            setState(() {
              _currentMapCenter = coordinates;
            });
          }
          await _moveMapToLocation(
            coordinates.latitude,
            coordinates.longitude,
            12.0,
          );
          await _loadNearbyCaptures(
            coordinates.latitude,
            coordinates.longitude,
          );
        } else {
          // Fallback to default location if ZIP code lookup fails
          if (mounted) {
            setState(() {
              _currentMapCenter = _defaultLocation.target;
            });
          }
          await _moveMapToLocation(
            _defaultLocation.target.latitude,
            _defaultLocation.target.longitude,
            10.0,
          );
          await _loadNearbyCaptures(
            _defaultLocation.target.latitude,
            _defaultLocation.target.longitude,
          );
        }
      } else {
        // Priority 3: Use default location (Kinston, NC - 28501)
        if (mounted) {
          setState(() {
            _currentMapCenter = _defaultLocation.target;
          });
        }
        await _moveMapToLocation(
          _defaultLocation.target.latitude,
          _defaultLocation.target.longitude,
          10.0,
        );
        await _loadNearbyCaptures(
          _defaultLocation.target.latitude,
          _defaultLocation.target.longitude,
        );
      }
    } catch (e) {
      AppLogger.error('❌ Error initializing location: $e');
      if (mounted) {
        setState(() {
          _hasMapError = true;
          _mapErrorMessage =
              'Error getting location: ${e.toString().split('] ').last}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _listenToNotificationBadge() {
    final user = FirebaseAuth.instance.currentUser;
    _notificationSubscription?.cancel();

    if (user == null) {
      if (mounted && _unreadNotificationCount != 0) {
        setState(() => _unreadNotificationCount = 0);
      }
      return;
    }

    _notificationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .limit(50)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;
            final unreadCount = snapshot.size;
            if (unreadCount == _unreadNotificationCount) return;
            setState(() => _unreadNotificationCount = unreadCount);
          },
          onError: (Object error, StackTrace stackTrace) {
            AppLogger.error(
              'Error listening to notification badge: $error\n$stackTrace',
            );
          },
        );
  }

  /// Try to get user's current location with proper error handling
  Future<Position?> _tryGetCurrentLocation() async {
    try {
      // Check if location services are enabled
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'art_walk_art_walk_map_error_location_services_disabled'.tr(),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return null;
      }

      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'art_walk_art_walk_map_error_location_permission_denied'.tr(),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position with a timeout
      final position =
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              // If getting high accuracy location times out, try lower accuracy
              return Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.medium,
                  timeLimit: Duration(seconds: 5),
                ),
              );
            },
          );

      return position;
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_art_walk_map_error_location_services_timeout'.tr(),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return null;
    } catch (e) {
      if (e is SocketException) {
        _showSnackBar('art_walk_art_walk_map_error_network_error'.tr());
      }
      return null;
    }
  }

  /// Get coordinates from ZIP code
  Future<LatLng?> _getCoordinatesFromZipCode(String zipCode) async {
    try {
      // Use LocationUtils from artbeat_core for proper ZIP code lookup
      final coordinates = await LocationUtils.getCoordinatesFromZipCode(
        zipCode,
      );
      if (coordinates != null) {
        return LatLng(coordinates.latitude, coordinates.longitude);
      }

      // Fallback for common ZIP codes if LocationUtils fails (useful for simulator)
      switch (zipCode) {
        case '28501': // Kinston, NC
          return const LatLng(35.23838, -77.52658);
        case '90210': // Beverly Hills, CA (popular test ZIP)
          return const LatLng(34.0901, -118.4065);
        case '10001': // New York, NY
          return const LatLng(40.7505, -73.9934);
        case '60601': // Chicago, IL
          return const LatLng(41.8781, -87.6298);
        case '94102': // San Francisco, CA
          return const LatLng(37.7749, -122.4194);
        default:
          AppLogger.info('ZIP code $zipCode not found in fallback list');
          return null;
      }
    } catch (e) {
      AppLogger.error('Error getting coordinates for ZIP code $zipCode: $e');
      return null;
    }
  }

  /// Move map to specified location
  Future<void> _moveMapToLocation(
    double latitude,
    double longitude,
    double zoom, {
    bool forceMove = false,
  }) async {
    if (_mapController != null &&
        mounted &&
        (!_hasMovedToUserLocation || forceMove)) {
      try {
        AppLogger.info(
          '📍 Moving map to: $latitude, $longitude (zoom: $zoom, force: $forceMove)',
        );
        await _mapController!
            .animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: LatLng(latitude, longitude), zoom: zoom),
              ),
            )
            .timeout(
              const Duration(seconds: 5),
            ); // Increased timeout for simulator
        if (!forceMove) {
          _hasMovedToUserLocation = true;
        }
        // Update current map center for filtering
        if (mounted) {
          setState(() {
            _currentMapCenter = LatLng(latitude, longitude);
          });
        }
        AppLogger.info('✅ Map movement completed');
      } catch (e) {
        AppLogger.error('⚠️ Error animating camera: $e');
        // Try a fallback method for simulator
        try {
          await _mapController!.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: LatLng(latitude, longitude), zoom: zoom),
            ),
          );
          AppLogger.info('✅ Map movement completed via fallback method');
        } catch (fallbackError) {
          AppLogger.error(
            '⚠️ Fallback camera movement also failed: $fallbackError',
          );
        }
      }
    } else {
      AppLogger.warning(
        '🚫 Map movement blocked - Controller: ${_mapController != null}, Mounted: $mounted, HasMoved: $_hasMovedToUserLocation, Force: $forceMove',
      );
    }
  }

  /// Load all captures with locations
  Future<void> _loadNearbyCaptures(double latitude, double longitude) async {
    try {
      // Load a reasonable number of captures (300 instead of 1000)
      final allCaptures = await _captureService.getAllCaptures(limit: 300);

      // Filter captures that have location data and are within 100 miles (160.934 km)
      const double maxDistanceKm = 160.934; // 100 miles in kilometers
      final nearbyCaptures = allCaptures
          .where((capture) => capture.location != null)
          .where((capture) {
            final distance =
                Geolocator.distanceBetween(
                  latitude,
                  longitude,
                  capture.location!.latitude,
                  capture.location!.longitude,
                ) /
                1000; // Convert meters to kilometers
            return distance <= maxDistanceKm;
          })
          .toList();

      AppLogger.info(
        '🗺️ Loaded ${allCaptures.length} total captures, filtered to ${nearbyCaptures.length} within 100 miles',
      );

      if (mounted) {
        setState(() {
          _nearbyCaptures = nearbyCaptures;
          _currentMapCenter = LatLng(latitude, longitude); // Track map center
        });
        _updateMarkers();
      }
    } catch (e) {
      AppLogger.error('❌ Error loading nearby captures: $e');
      if (mounted) {
        setState(() {
          _nearbyCaptures = [];
        });
        _updateMarkers();
      }
    }
  }

  /// Update user's ZIP code in profile
  Future<void> _updateUserZipCode(String zipCode) async {
    try {
      await _userService.updateUserZipCode(zipCode);
    } catch (e) {
      AppLogger.error('❌ Error updating user ZIP code: $e');
    }
  }

  /// Update markers on the map based on nearby captures
  void _updateMarkers() {
    if (!mounted) return;

    AppLogger.info(
      '🗺️ Updating markers with ${_nearbyCaptures.length} captures',
    );

    setState(() {
      _markers.clear();
      for (final capture in _nearbyCaptures) {
        if (capture.location != null) {
          _markers.add(
            Marker(
              markerId: MarkerId(capture.id),
              position: LatLng(
                capture.location!.latitude,
                capture.location!.longitude,
              ),
              infoWindow: InfoWindow(
                title: capture.title ?? 'Untitled',
                snippet: capture.artistName ?? 'Unknown Artist',
              ),
              onTap: () => _onMarkerTapped(capture),
            ),
          );
        }
      }
      AppLogger.info('🗺️ Added ${_markers.length} markers to map');
    });
  }

  /// Handle marker tap
  void _onMarkerTapped(CaptureModel capture) {
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CaptureDetailBottomSheet(capture: capture),
    );
  }

  /// Show snackbar
  void _showSnackBar(String message, {Duration? duration}) {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  /// Start location updates
  void _startLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshLocation(),
    );
  }

  /// Refresh location
  Future<void> _refreshLocation() async {
    if (!mounted) return;
    try {
      final newPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      await _updateNearbyCaptures();
    } catch (e) {
      AppLogger.error('❌ Error refreshing location: $e');
    }
  }

  /// Update nearby captures based on current position and filter
  Future<void> _updateNearbyCaptures() async {
    if (!mounted || _currentMapCenter == null) return;
    try {
      List<CaptureModel> nearbyCaptures = [];
      final user = FirebaseAuth.instance.currentUser;

      AppLogger.info(
        '🔄 Updating captures for filter: $_artFilter, user: ${user?.uid}',
      );
      AppLogger.info(
        '🗺️ Using map center: ${_currentMapCenter!.latitude}, ${_currentMapCenter!.longitude}',
      );

      switch (_artFilter) {
        case 'public':
          // Get all public captures (all user-captured art)
          final publicCaptures = await _captureService.getPublicCaptures(
            limit: 1000,
          );
          AppLogger.info('📍 Found ${publicCaptures.length} public captures');
          nearbyCaptures = publicCaptures
              .where((c) => c.location != null)
              .toList();
          AppLogger.info(
            '📍 Filtered to ${nearbyCaptures.length} public captures with locations',
          );
          break;
        case 'my_captures':
          // Get only current user's captures
          if (user != null) {
            final userCaptures = await _captureService.getCapturesForUser(
              user.uid,
            );
            AppLogger.info(
              '👤 Found ${userCaptures.length} user captures for ${user.uid}',
            );
            nearbyCaptures = userCaptures
                .where((c) => c.location != null)
                .toList();
            AppLogger.info(
              '👤 Filtered to ${nearbyCaptures.length} user captures with locations',
            );
          } else {
            AppLogger.warning('👤 No user logged in for my_captures filter');
          }
          break;
        case 'my_artwalks':
          // This case should not be reached since my_artwalks navigates directly
          AppLogger.info('🚶 My artwalks filter should have navigated already');
          break;
      }

      if (!mounted) return;
      setState(() {
        _nearbyCaptures = nearbyCaptures;
      });
      _updateMarkers();
    } catch (e) {
      AppLogger.error('❌ Error updating nearby captures: $e');
    }
  }

  /// Change filter
  void _changeFilter(String newFilter) {
    if (newFilter == 'my_artwalks') {
      // Navigate to user's art walk list
      Navigator.pushNamed(context, '/art-walk/list');
      return;
    }

    setState(() {
      _artFilter = newFilter;
    });
    _updateNearbyCaptures();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 1, // Art Walk tab
      scaffoldKey: _scaffoldKey,
      drawer: const ArtWalkDrawer(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // Map as the base layer
            Positioned.fill(
              child: kIsWeb
                  ? Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF07060F),
                            Color(0xFF0A1330),
                            Color(0xFF071C18),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'art_walk_art_walk_map_text_interactive_map'.tr(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'art_walk_art_walk_map_text_map_features_mobile'
                                  .tr(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GoogleMap(
                      initialCameraPosition: _defaultLocation,
                      markers: _markers,
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    ),
            ),

            // Glass header AppBar overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  height: 72,
                  decoration: ArtWalkDesignSystem.hudGlassDecoration(
                    borderRadius: 0,
                  ),
                  padding: const EdgeInsets.only(
                    top: 12,
                    left: 8,
                    right: 8,
                    bottom: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.menu,
                          color: ArtWalkDesignSystem.hudInactiveColor,
                        ),
                        onPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'art_walk_art_walk_map_text_art_walk_map'.tr(),
                          style: ArtWalkDesignSystem.hudCardTitleStyle.copyWith(
                            color: ArtWalkDesignSystem.hudActiveColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: ArtWalkDesignSystem.hudInactiveColor,
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/search'),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.message,
                          color: ArtWalkDesignSystem.hudInactiveColor,
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/messaging'),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications,
                              color: ArtWalkDesignSystem.hudInactiveColor,
                            ),
                            onPressed: () =>
                                Navigator.pushNamed(context, '/notifications'),
                          ),
                          if (_unreadNotificationCount > 0)
                            Positioned(
                              right: 6,
                              top: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: ArtWalkDesignSystem.hudActiveColor,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _unreadNotificationCount > 99
                                      ? '99+'
                                      : _unreadNotificationCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.account_circle,
                          color: ArtWalkDesignSystem.hudInactiveColor,
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/profile'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Search bar overlay
            Positioned(
              top: 135,
              left: ArtWalkDesignSystem.paddingM,
              right: ArtWalkDesignSystem.paddingM,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ArtWalkDesignSystem.paddingM,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    ArtWalkDesignSystem.radiusM,
                  ),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: TextField(
                  style: ArtWalkDesignSystem.hudCardTitleStyle.copyWith(
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: _currentZipCode.isEmpty
                        ? 'art_walk_art_walk_map_text_enter_zip_code'.tr()
                        : 'art_walk_art_walk_map_text_enter_zip_code_current'
                              .tr(namedArgs: {'zipCode': _currentZipCode}),
                    hintStyle: ArtWalkDesignSystem.hudCardSubtitleStyle
                        .copyWith(
                          color: ArtWalkDesignSystem.hudInactiveColor
                              .withValues(alpha: 0.6),
                        ),
                    border: InputBorder.none,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_currentZipCode != '28501')
                          IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: ArtWalkDesignSystem.hudActiveColor,
                              size: 20,
                            ),
                            onPressed: () async {
                              setState(() => _currentZipCode = '28501');
                              await _moveMapToLocation(
                                35.23838,
                                -77.52658,
                                12.0,
                                forceMove: true,
                              );
                              await _loadNearbyCaptures(35.23838, -77.52658);
                              await _updateUserZipCode('28501');
                              _showSnackBar(
                                'art_walk_art_walk_map_text_reset_default_location'
                                    .tr(),
                              );
                            },
                          ),
                        const Icon(
                          Icons.search,
                          color: ArtWalkDesignSystem.hudActiveColor,
                        ),
                      ],
                    ),
                  ),
                  onSubmitted: (zipCode) async {
                    if (zipCode.isNotEmpty && zipCode.length >= 5) {
                      setState(() => _isSearchingZip = true);
                      _showSnackBar(
                        'art_walk_art_walk_map_text_searching_zip_code'.tr(
                          namedArgs: {'zipCode': zipCode},
                        ),
                      );
                      final coordinates = await _getCoordinatesFromZipCode(
                        zipCode.trim(),
                      );
                      if (coordinates != null) {
                        await _moveMapToLocation(
                          coordinates.latitude,
                          coordinates.longitude,
                          12.0,
                          forceMove: true,
                        );
                        await _loadNearbyCaptures(
                          coordinates.latitude,
                          coordinates.longitude,
                        );
                        await _updateUserZipCode(zipCode.trim());
                        setState(() => _currentZipCode = zipCode.trim());
                        _showSnackBar(
                          'art_walk_art_walk_map_text_location_updated'.tr(
                            namedArgs: {'zipCode': zipCode},
                          ),
                        );
                      } else {
                        _showSnackBar(
                          'art_walk_art_walk_map_text_zip_code_not_found'.tr(
                            namedArgs: {'zipCode': zipCode},
                          ),
                        );
                      }
                      setState(() => _isSearchingZip = false);
                    } else {
                      _showSnackBar(
                        'art_walk_art_walk_map_text_enter_valid_zip'.tr(),
                      );
                    }
                  },
                ),
              ),
            ),

            // Create Art Walk button overlay
            Positioned(
              top: 190,
              left: ArtWalkDesignSystem.paddingM,
              right: ArtWalkDesignSystem.paddingM,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: ArtWalkDesignSystem.hudBackground.withValues(
                    alpha: 0.8,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ArtWalkDesignSystem.hudActiveColor.withValues(
                        alpha: 0.15,
                      ),
                      blurRadius: 18,
                      spreadRadius: 1,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/art-walk/create');
                  },
                  icon: const Icon(
                    Icons.add_location,
                    color: ArtWalkDesignSystem.hudInactiveColor,
                  ),
                  label: Text(
                    'art_walk_art_walk_map_text_create_art_walk'.tr(),
                    style: const TextStyle(
                      color: ArtWalkDesignSystem.hudInactiveColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ),

            // All other overlays (filter buttons, right-side actions, slider, etc.)
            // ...existing code for filter buttons, right-side actions, slider, etc. (leave as is)
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String filter) {
    final isSelected = _artFilter == filter;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: GestureDetector(
          onTap: () => _changeFilter(filter),
          child: Container(
            height: 48, // Ensure touch target is ≥44px
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isSelected
                  ? ArtWalkDesignSystem.hudActiveColor.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: isSelected
                    ? ArtWalkDesignSystem.hudActiveColor.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: ArtWalkDesignSystem.hudActiveColor.withValues(
                          alpha: 0.25,
                        ),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? ArtWalkDesignSystem.hudActiveColor
                      : Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureCard(CaptureModel capture) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: OptimizedImage(
                  imageUrl: capture.thumbnailUrl ?? capture.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    capture.title ?? 'Untitled',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ArtWalkDesignSystem.hudInactiveColor.withValues(
                        alpha: 0.92,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (capture.artistName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        capture.artistName!,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: ArtWalkDesignSystem.hudInactiveColor
                              .withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for capture details
class CaptureDetailBottomSheet extends StatelessWidget {
  final CaptureModel capture;

  const CaptureDetailBottomSheet({super.key, required this.capture});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: ArtWalkDesignSystem.hudBackground.withValues(alpha: 0.95),
        border: Border.all(
          color: ArtWalkDesignSystem.hudBorder.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: ArtWalkDesignSystem.hudInactiveColor.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Image
          if (capture.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: OptimizedImage(
                imageUrl: capture.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capture.title ?? 'Untitled',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ArtWalkDesignSystem.hudInactiveColor.withValues(
                      alpha: 0.92,
                    ),
                  ),
                ),
                if (capture.artistName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'by ${capture.artistName}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      color: ArtWalkDesignSystem.hudInactiveColor.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
                if (capture.description != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    capture.description!,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ArtWalkDesignSystem.hudInactiveColor.withValues(
                        alpha: 0.85,
                      ),
                    ),
                  ),
                ],
                if (capture.locationName != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: ArtWalkDesignSystem.hudActiveColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          capture.locationName!,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: ArtWalkDesignSystem.hudInactiveColor
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                // Close button centered since we removed the redundant "View Details" button
                // The bottom sheet already shows all capture details
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ArtWalkDesignSystem.hudActiveColor,
                        foregroundColor: ArtWalkDesignSystem.hudInactiveColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'art_walk_art_walk_map_text_close'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
