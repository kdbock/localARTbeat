import 'dart:async';
import 'dart:io' show SocketException;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import '../models/public_art_model.dart';
import '../widgets/art_walk_drawer.dart';

import '../widgets/offline_map_fallback.dart';
import '../widgets/offline_art_walk_widget.dart';
import '../theme/art_walk_design_system.dart';

/// Screen that displays a map with nearby captures and art walks
class ArtWalkMapScreen extends StatefulWidget {
  const ArtWalkMapScreen({super.key});

  @override
  State<ArtWalkMapScreen> createState() => _ArtWalkMapScreenState();
}

class _ArtWalkMapScreenState extends State<ArtWalkMapScreen> {
  // Services
  final CaptureService _captureService = CaptureService();
  final UserService _userService = UserService();

  // Scaffold key for drawer control
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Map controller and state
  GoogleMapController? _mapController;
  Position? _currentPosition;
  LatLng? _currentMapCenter; // Track current map center for filtering
  String _currentZipCode = '';
  bool _hasMovedToUserLocation = false;
  bool _isLoading = true;
  bool _isSearchingZip = false;
  bool _hasMapError = false;
  String _mapErrorMessage = '';
  bool _showCapturesSlider = false;

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
    _initializeMapsAndLocation();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _mapController?.dispose();
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
          _currentPosition = position;
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

  /// Load nearby captures for given coordinates
  Future<void> _loadNearbyCaptures(double latitude, double longitude) async {
    try {
      // Get all captures and filter by location
      final allCaptures = await _captureService.getAllCaptures(limit: 100);

      // Filter captures by distance (within 10km radius)
      final nearbyCaptures = <CaptureModel>[];
      for (final capture in allCaptures) {
        if (capture.location != null) {
          final distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            capture.location!.latitude,
            capture.location!.longitude,
          );

          // Convert distance from meters to kilometers
          if (distance / 1000 <= 10.0) {
            nearbyCaptures.add(capture);
          }
        }
      }

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
      setState(() => _currentPosition = newPosition);
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
            limit: 100,
          );
          AppLogger.info('📍 Found ${publicCaptures.length} public captures');
          nearbyCaptures = _filterCapturesByDistance(
            publicCaptures,
            _currentMapCenter!.latitude,
            _currentMapCenter!.longitude,
          );
          AppLogger.info(
            '📍 Filtered to ${nearbyCaptures.length} nearby public captures',
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
            nearbyCaptures = _filterCapturesByDistance(
              userCaptures,
              _currentMapCenter!.latitude,
              _currentMapCenter!.longitude,
            );
            AppLogger.info(
              '👤 Filtered to ${nearbyCaptures.length} nearby user captures',
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

  /// Filter captures by distance from given coordinates
  List<CaptureModel> _filterCapturesByDistance(
    List<CaptureModel> captures,
    double latitude,
    double longitude,
  ) {
    final nearbyCaptures = <CaptureModel>[];
    AppLogger.info(
      '📏 Filtering ${captures.length} captures within 10km of ($latitude, $longitude)',
    );

    for (final capture in captures) {
      if (capture.location != null) {
        final distance = Geolocator.distanceBetween(
          latitude,
          longitude,
          capture.location!.latitude,
          capture.location!.longitude,
        );

        final distanceKm = distance / 1000;
        // Convert distance from meters to kilometers
        if (distanceKm <= 10.0) {
          nearbyCaptures.add(capture);
          AppLogger.info(
            '✅ Capture ${capture.id} at distance ${distanceKm.toStringAsFixed(2)}km - INCLUDED',
          );
        } else {
          AppLogger.info(
            '❌ Capture ${capture.id} at distance ${distanceKm.toStringAsFixed(2)}km - EXCLUDED',
          );
        }
      } else {
        AppLogger.warning('⚠️ Capture ${capture.id} has no location data');
      }
    }

    AppLogger.info(
      '📏 Filtered result: ${nearbyCaptures.length} nearby captures',
    );
    return nearbyCaptures;
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
        appBar: ArtWalkDesignSystem.buildAppBar(
          title: 'art_walk_art_walk_map_text_art_walk_map'.tr(),
          showBackButton: false, // Don't show back button
          scaffoldKey: _scaffoldKey, // Provide scaffold key for hamburger menu
          useHudStyle: true, // Use HUD style to match enhanced bottom nav
          actions: [
            IconButton(
              icon: Icon(
                Icons.search,
                color: ArtWalkDesignSystem.hudInactiveColor.withValues(
                  alpha: 0.8,
                ),
              ),
              onPressed: () => Navigator.pushNamed(context, '/search'),
            ),
            IconButton(
              icon: Icon(
                Icons.message,
                color: ArtWalkDesignSystem.hudInactiveColor.withValues(
                  alpha: 0.8,
                ),
              ),
              onPressed: () => Navigator.pushNamed(context, '/messaging'),
            ),
            Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications,
                    color: ArtWalkDesignSystem.hudInactiveColor.withValues(
                      alpha: 0.8,
                    ),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/notifications'),
                ),
                // TODO: Add notification badge logic here if needed
              ],
            ),
            IconButton(
              icon: Icon(
                Icons.account_circle,
                color: ArtWalkDesignSystem.hudInactiveColor.withValues(
                  alpha: 0.8,
                ),
              ),
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Google Map
            kIsWeb
                ? Container(
                    color: Colors.grey[100],
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
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'art_walk_art_walk_map_text_map_features_mobile'
                                .tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
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

            // Loading indicator
            if (_isLoading || _isSearchingZip)
              Container(
                decoration: BoxDecoration(
                  gradient: ArtWalkDesignSystem.hudHeaderGradient,
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(
                      ArtWalkDesignSystem.paddingXL,
                    ),
                    decoration: ArtWalkDesignSystem.hudGlassDecoration(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ArtWalkDesignSystem.hudActiveColor,
                          ),
                        ),
                        const SizedBox(height: ArtWalkDesignSystem.paddingM),
                        Text(
                          _isSearchingZip
                              ? 'Searching location...'
                              : 'Loading map...',
                          style: ArtWalkDesignSystem.hudCardTitleStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Error message - using OfflineMapFallback widget
            if (_hasMapError)
              _nearbyCaptures.isNotEmpty
                  ? OfflineMapFallback(
                      onRetry: _initializeMapsAndLocation,
                      hasData: true,
                      errorMessage: _mapErrorMessage,
                      nearbyArt: _nearbyCaptures
                          .map((capture) => PublicArtModel.fromCapture(capture))
                          .toList(),
                    )
                  : OfflineArtWalkWidget(onRetry: _initializeMapsAndLocation),

            // ZIP code search bar
            Positioned(
              top: ArtWalkDesignSystem.paddingM,
              left: ArtWalkDesignSystem.paddingM,
              right: ArtWalkDesignSystem.paddingM,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ArtWalkDesignSystem.paddingM,
                ),
                decoration: ArtWalkDesignSystem.hudGlassDecoration(
                  borderRadius: ArtWalkDesignSystem.radiusM,
                ),
                child: TextField(
                  style: ArtWalkDesignSystem.hudCardTitleStyle,
                  decoration: InputDecoration(
                    hintText: _currentZipCode.isEmpty
                        ? 'Enter ZIP code'
                        : 'Enter ZIP code (current: $_currentZipCode)',
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
                            icon: Icon(
                              Icons.refresh,
                              color: ArtWalkDesignSystem.hudActiveColor,
                              size: 20,
                            ),
                            onPressed: () async {
                              // Reset to default Kinston, NC
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
                                '✅ Reset to default location: Kinston, NC (28501)',
                              );
                            },
                          ),
                        Icon(
                          Icons.search,
                          color: ArtWalkDesignSystem.hudActiveColor,
                        ),
                      ],
                    ),
                  ),
                  onSubmitted: (zipCode) async {
                    if (zipCode.isNotEmpty && zipCode.length >= 5) {
                      setState(() => _isSearchingZip = true);

                      // Show loading message
                      _showSnackBar('Searching for ZIP code $zipCode...');

                      final coordinates = await _getCoordinatesFromZipCode(
                        zipCode.trim(),
                      );
                      if (coordinates != null) {
                        await _moveMapToLocation(
                          coordinates.latitude,
                          coordinates.longitude,
                          12.0,
                          forceMove: true, // Force move for ZIP code searches
                        );
                        await _loadNearbyCaptures(
                          coordinates.latitude,
                          coordinates.longitude,
                        );
                        await _updateUserZipCode(zipCode.trim());
                        setState(() => _currentZipCode = zipCode.trim());
                        _showSnackBar('✅ Location updated to $zipCode');
                      } else {
                        _showSnackBar(
                          '❌ ZIP code $zipCode not found. Try: 28501, 90210, 10001, 60601, or 94102',
                        );
                      }
                      setState(() => _isSearchingZip = false);
                    } else {
                      _showSnackBar('Please enter a valid ZIP code (5 digits)');
                    }
                  },
                ),
              ),
            ),

            // Create Art Walk button - positioned next to ZIP code search
            Positioned(
              top: 80, // Below the ZIP code search bar
              left: ArtWalkDesignSystem.paddingM,
              right: ArtWalkDesignSystem.paddingM,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: ArtWalkDesignSystem.hudButtonGradient,
                  boxShadow: [
                    BoxShadow(
                      color: ArtWalkDesignSystem.hudActiveColor.withValues(alpha: 0.3),
                      blurRadius: 18,
                      spreadRadius: 1,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: ArtWalkDesignSystem.hudInactiveColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/art-walk/create');
                  },
                  icon: Icon(
                    Icons.add_location,
                    color: ArtWalkDesignSystem.hudInactiveColor,
                  ),
                  label: Text(
                    'art_walk_art_walk_map_text_create_art_walk'.tr(),
                    style: TextStyle(
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

            // Filter buttons - moved higher up to avoid bottom nav overlap
            Positioned(
              bottom: 140,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: ArtWalkDesignSystem.hudGlassDecoration(
                  borderRadius: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFilterButton(
                      'art_walk_art_walk_map_text_public'.tr(),
                      'public',
                    ),
                    _buildFilterButton(
                      'art_walk_art_walk_map_text_my_captures'.tr(),
                      'my_captures',
                    ),
                    _buildFilterButton(
                      'art_walk_art_walk_map_text_my_artwalks'.tr(),
                      'my_artwalks',
                    ),
                  ],
                ),
              ),
            ),

            // Right-side action buttons - positioned to not overlap with bottom nav
            Positioned(
              bottom: 90,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle captures slider
                  FloatingActionButton(
                    heroTag: 'toggle_slider',
                    mini: true,
                    backgroundColor: ArtWalkDesignSystem.hudBackground
                        .withValues(alpha: 0.8),
                    foregroundColor: ArtWalkDesignSystem.hudInactiveColor,
                    onPressed: () {
                      setState(() {
                        _showCapturesSlider = !_showCapturesSlider;
                      });
                    },
                    child: Icon(_showCapturesSlider ? Icons.close : Icons.list),
                  ),
                  const SizedBox(height: 8),

                  // My location button
                  FloatingActionButton(
                    heroTag: 'my_location',
                    mini: true,
                    backgroundColor: ArtWalkDesignSystem.hudBackground
                        .withValues(alpha: 0.8),
                    foregroundColor: ArtWalkDesignSystem.hudInactiveColor,
                    onPressed: _currentPosition != null
                        ? () {
                            _mapController?.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: LatLng(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                  ),
                                  zoom: 15.0,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),

            // Captures slider
            if (_showCapturesSlider)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: ArtWalkDesignSystem.hudBackground.withValues(
                      alpha: 0.9,
                    ),
                    border: Border(
                      top: BorderSide(
                        color: ArtWalkDesignSystem.hudBorder.withValues(
                          alpha: 0.3,
                        ),
                        width: 1,
                      ),
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${"art_walk_art_walk_map_text_nearby_captures".tr()} (${_nearbyCaptures.length})',
                              style: ArtWalkDesignSystem.hudCardTitleStyle,
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() => _showCapturesSlider = false);
                              },
                              icon: Icon(
                                Icons.close,
                                color: ArtWalkDesignSystem.hudInactiveColor
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _nearbyCaptures.isEmpty
                            ? Center(
                                child: Text(
                                  'art_walk_art_walk_map_text_no_captures_found'
                                      .tr(),
                                  style:
                                      ArtWalkDesignSystem.hudCardSubtitleStyle,
                                ),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _nearbyCaptures.length,
                                itemBuilder: (context, index) {
                                  final capture = _nearbyCaptures[index];
                                  return _buildCaptureCard(capture);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
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
        child: ElevatedButton(
          onPressed: () => _changeFilter(filter),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? ArtWalkDesignSystem.hudActiveColor.withValues(alpha: 0.2)
                : ArtWalkDesignSystem.hudBackground.withValues(alpha: 0.3),
            foregroundColor: isSelected
                ? ArtWalkDesignSystem.hudActiveColor
                : ArtWalkDesignSystem.hudInactiveColor.withValues(alpha: 0.8),
            elevation: isSelected ? 2 : 0,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            minimumSize: const Size(0, 32),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(
              color: isSelected
                  ? ArtWalkDesignSystem.hudActiveColor.withValues(alpha: 0.5)
                  : ArtWalkDesignSystem.hudBorder.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buildCaptureCard(CaptureModel capture) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
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
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    capture.title ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (capture.artistName != null)
                    Text(
                      capture.artistName!,
                      style: const TextStyle(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Image
          if (capture.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capture.title ?? 'Untitled',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (capture.artistName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'by ${capture.artistName}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (capture.description != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    capture.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (capture.locationName != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          capture.locationName!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Close button centered since we removed the redundant "View Details" button
                // The bottom sheet already shows all capture details
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('admin_admin_payment_text_close'.tr()),
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
