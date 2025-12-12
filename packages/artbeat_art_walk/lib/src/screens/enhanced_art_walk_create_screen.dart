import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_settings/artbeat_settings.dart';
import 'package:flutter/foundation.dart';

// Enhanced Create Art Walk specific colors (matching Dashboard theme)
class EnhancedCreateColors {
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
  static Color headingDarkPurple = const Color(
    0xFF2D1B69,
  ); // Dark purple, almost black
}

/// Enhanced Art Walk Create Screen with Map View
class EnhancedArtWalkCreateScreen extends StatefulWidget {
  static const String routeName = '/enhanced-create-art-walk';

  final String? artWalkId; // For editing existing art walk
  final ArtWalkModel? artWalkToEdit; // Pre-loaded art walk data

  const EnhancedArtWalkCreateScreen({
    super.key,
    this.artWalkId,
    this.artWalkToEdit,
  });

  @override
  State<EnhancedArtWalkCreateScreen> createState() =>
      _EnhancedArtWalkCreateScreenState();
}

class _EnhancedArtWalkCreateScreenState
    extends State<EnhancedArtWalkCreateScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedDurationController = TextEditingController();
  final _zipCodeController = TextEditingController();

  // Map related
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Position? _currentPosition;
  LatLng? _mapCenter;

  // Art pieces and route
  final List<PublicArtModel> _selectedArtPieces = [];
  List<PublicArtModel> _availableArtPieces = [];
  List<LatLng> _routePoints = [];

  // State variables
  File? _coverImageFile;
  bool _isLoading = false;
  bool _isPublic = true;
  bool _showMapView = true;
  double _estimatedDistance = 0.0;
  final bool _isUploading = false;

  // Animation
  late AnimationController _introAnimationController;
  bool _hasShownIntro = false;

  // Services
  final ArtWalkService _artWalkService = ArtWalkService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final IntegratedSettingsService _userSettingsService =
      IntegratedSettingsService();

  // User preferences
  UserSettingsModel? _userSettings;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _introAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Start with intro if not editing
    if (widget.artWalkId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showIntroDialog();
      });
    }

    // Initialize form if editing existing art walk
    if (widget.artWalkToEdit != null) {
      _initializeEditingMode();
    }

    _initializeLocation();
    _loadUserSettings();
    _loadAvailableArtPiecesAfterLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedDurationController.dispose();
    _zipCodeController.dispose();
    _introAnimationController.dispose();
    super.dispose();
  }

  void _initializeEditingMode() {
    final artWalk = widget.artWalkToEdit!;
    _titleController.text = artWalk.title;
    _descriptionController.text = artWalk.description;
    _isPublic = artWalk.isPublic;
    _estimatedDurationController.text =
        artWalk.estimatedDuration?.toString() ?? '';
    _zipCodeController.text = artWalk.zipCode ?? '';
    _estimatedDistance = artWalk.estimatedDistance ?? 0.0;
  }

  Future<void> _loadUserSettings() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final settings = await _userSettingsService.getUserSettings();
        setState(() {
          _userSettings = settings;
        });
      }
    } catch (e) {
      debugPrint('Error loading user settings: $e');
      // Use default settings with miles for American users
      setState(() {
        _userSettings = UserSettingsModel.defaultSettings(
          _auth.currentUser?.uid ?? '',
        );
      });
    }
  }

  Future<void> _initializeLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _mapCenter = LatLng(position.latitude, position.longitude);
      });

      // Update zip code based on current location
      await _updateZipCodeFromLocation(_mapCenter!);
    } catch (e) {
      // debugPrint('Error getting current location: $e');
      // Default to central NC if location fails
      setState(() {
        _mapCenter = const LatLng(35.7796, -78.6382);
      });
    }
  }

  Future<void> _updateZipCodeFromLocation(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        setState(() {
          _zipCodeController.text = placemark.postalCode ?? '';
        });
      }
    } catch (e) {
      // debugPrint('Error getting zip code from location: $e');
    }
  }

  Future<void> _loadAvailableArtPiecesAfterLocation() async {
    const int maxWaitAttempts = 30;
    int waitAttempt = 0;

    while ((_currentPosition == null && _mapCenter == null) &&
        waitAttempt < maxWaitAttempts) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      waitAttempt++;
    }

    await _loadAvailableArtPieces();
  }

  Future<void> _loadAvailableArtPieces() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use current position if available, otherwise default to central NC
      final latitude = _currentPosition?.latitude ?? 35.7796;
      final longitude = _currentPosition?.longitude ?? -78.6382;

      // Fetch all captures (captures are public art) - fresh from Firestore, no cache
      final captureService = CaptureService();
      final captures = await captureService.getAllCapturesFresh(limit: 500);

      // Filter captures within 30 mile radius for American audience
      const double radiusInMiles = 30.0;
      const double radiusInMeters = radiusInMiles * 1609.34;

      final List<(PublicArtModel, double)> artWithDistance = [];

      for (final capture in captures) {
        if (capture.location == null) continue;

        try {
          final distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            capture.location!.latitude,
            capture.location!.longitude,
          );

          if (distance <= radiusInMeters) {
            final publicArt = PublicArtModel(
              id: capture.id,
              title: capture.title ?? 'Captured Art',
              artistName: capture.artistName ?? 'Unknown Artist',
              imageUrl: capture.imageUrl,
              location: capture.location ?? const GeoPoint(0, 0),
              description: capture.description ?? '',
              tags: capture.tags ?? [],
              userId: capture.userId,
              usersFavorited: const [],
              createdAt: Timestamp.fromDate(capture.createdAt),
            );
            artWithDistance.add((publicArt, distance));
          }
        } catch (e) {
          debugPrint(
            'Error calculating distance for capture ${capture.title}: $e',
          );
        }
      }

      // Sort by distance (closest first)
      artWithDistance.sort((a, b) => a.$2.compareTo(b.$2));

      final List<PublicArtModel> finalCaptureArt = artWithDistance
          .map((item) => item.$1)
          .toList();

      debugPrint('Total captures fetched: ${captures.length}');
      debugPrint(
        'Filtered captures within 30 miles: ${finalCaptureArt.length}',
      );
      debugPrint('Current location: $latitude, $longitude');

      setState(() {
        _availableArtPieces = finalCaptureArt;
        _updateMapMarkers();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_enhanced_art_walk_create_error_error_loading_art'.tr(),
            ),
          ),
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

  void _updateMapMarkers() {
    final markers = <Marker>{};

    // Add markers for all available art pieces
    for (final art in _availableArtPieces) {
      final isSelected = _selectedArtPieces.contains(art);
      final markerId = MarkerId(art.id);

      markers.add(
        Marker(
          markerId: markerId,
          position: LatLng(art.location.latitude, art.location.longitude),
          icon: isSelected
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title: art.title,
            snippet: art.artistName,
            onTap: () => _toggleArtPieceSelection(art),
          ),
          onTap: () => _toggleArtPieceSelection(art),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _toggleArtPieceSelection(PublicArtModel art) {
    setState(() {
      if (_selectedArtPieces.contains(art)) {
        _selectedArtPieces.remove(art);
      } else {
        _selectedArtPieces.add(art);
      }
    });

    _updateMapMarkers();
    _updateRoute();
  }

  void _updateRoute() {
    if (_selectedArtPieces.isEmpty) {
      setState(() {
        _polylines.clear();
        _routePoints.clear();
        _estimatedDistance = 0.0;
      });
      return;
    }

    // Get current location or default
    final currentLocation = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _mapCenter ?? const LatLng(35.7796, -78.6382);

    // Sort selected art pieces by distance to create an optimal route
    final sortedPieces = RouteOptimizationUtils.optimizeRouteFromLocation(
      _selectedArtPieces,
      currentLocation,
    );

    // Create route points starting from current location
    final routePoints = <LatLng>[
      currentLocation, // Start at current location
      ...sortedPieces.map(
        (art) => LatLng(art.location.latitude, art.location.longitude),
      ),
      currentLocation, // Return to start
    ];

    // Calculate total distance including start and return
    double totalDistance = 0.0;
    for (int i = 0; i < routePoints.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        routePoints[i].latitude,
        routePoints[i].longitude,
        routePoints[i + 1].latitude,
        routePoints[i + 1].longitude,
      );
    }

    // Convert to user's preferred unit
    final String distanceUnit = _userSettings?.distanceUnit ?? 'miles';
    final double convertedDistance = distanceUnit == 'miles'
        ? DistanceUtils.metersToMiles(totalDistance)
        : DistanceUtils.metersToKilometers(totalDistance);

    setState(() {
      _routePoints = routePoints;
      _estimatedDistance = convertedDistance;
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          color: ArtbeatColors.primary,
          width: 3,
        ),
      };
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    // Map controller initialized
  }

  void _onMapTap(LatLng position) {
    _updateZipCodeFromLocation(position);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedArtPieces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'art_walk_enhanced_art_walk_create_text_please_select_at'.tr(),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isEditing = widget.artWalkId != null;

      // Get art piece IDs
      final artworkIds = _selectedArtPieces.map((art) => art.id).toList();

      // Calculate estimated duration based on distance and number of pieces
      // Assume 3 mph walking speed + 10 minutes per art piece for viewing
      final String distanceUnit = _userSettings?.distanceUnit ?? 'miles';
      final double minutesPerUnit = distanceUnit == 'miles'
          ? 20.0
          : 12.4; // 20 min/mile or 12.4 min/km
      final walkingMinutes = _estimatedDistance * minutesPerUnit;
      final viewingMinutes =
          _selectedArtPieces.length * 10; // 10 minutes per art piece
      final estimatedMinutes = walkingMinutes + viewingMinutes;

      if (isEditing) {
        // Update existing art walk
        await _artWalkService.updateArtWalk(
          walkId: widget.artWalkId!,
          title: _titleController.text,
          description: _descriptionController.text,
          artworkIds: artworkIds,
          coverImageFile: _coverImageFile,
          isPublic: _isPublic,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'art_walk_enhanced_art_walk_create_success_art_walk_updated'
                    .tr(),
              ),
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        // Create new art walk using the service method
        final userId = _auth.currentUser?.uid;
        if (userId == null) {
          throw Exception('User not authenticated');
        }

        // Create route data
        final routeData = _routePoints
            .map((point) => '${point.latitude},${point.longitude}')
            .join(';');

        // Determine start location - use first selected art piece or current position
        GeoPoint startLocation;
        if (_selectedArtPieces.isNotEmpty) {
          final firstArt = _selectedArtPieces.first;
          startLocation = GeoPoint(
            firstArt.location.latitude,
            firstArt.location.longitude,
          );
        } else if (_currentPosition != null) {
          startLocation = GeoPoint(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );
        } else {
          throw Exception('Unable to determine start location');
        }

        // Create the art walk using the service method
        final artWalkId = await _artWalkService.createArtWalk(
          title: _titleController.text,
          description: _descriptionController.text,
          artworkIds: artworkIds,
          startLocation: startLocation,
          routeData: routeData,
          coverImageFile: _coverImageFile,
          isPublic: _isPublic,
        );

        if (artWalkId != null && mounted) {
          // Create ArtWalkModel from the created data
          final createdArtWalk = ArtWalkModel(
            id: artWalkId,
            title: _titleController.text,
            description: _descriptionController.text,
            userId: userId,
            artworkIds: artworkIds,
            isPublic: _isPublic,
            zipCode: _zipCodeController.text,
            estimatedDuration: estimatedMinutes,
            estimatedDistance: _estimatedDistance,
            routeData: routeData,
            createdAt: DateTime.now(),
            viewCount: 0,
            imageUrls: _coverImageFile != null
                ? []
                : [], // Will be populated by service
            coverImageUrl: null, // Will be populated by service
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'art_walk_enhanced_art_walk_create_success_art_walk_created'
                    .tr(),
              ),
            ),
          );

          // Navigate to review screen instead of just popping back
          Navigator.of(context).pushReplacementNamed(
            ArtWalkRoutes.review,
            arguments: {'artWalkId': artWalkId, 'artWalk': createdArtWalk},
          );
        } else {
          throw Exception('Failed to create art walk');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error ${widget.artWalkId != null ? 'updating' : 'creating'} art walk: $e',
            ),
          ),
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

  void _showIntroDialog() {
    if (_hasShownIntro) return;
    _hasShownIntro = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Create Your Art Walk Journey',
          style: TextStyle(color: Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_walk, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Ready to curate your own artistic adventure?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a unique path through local art pieces, share your favorite spots, and inspire others to explore the artistic side of your city.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Let\'s Begin',
              style: TextStyle(color: Color.fromARGB(255, 247, 248, 249)),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MODERN DESIGN METHODS ====================

  BoxDecoration _buildBackgroundDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          EnhancedCreateColors.primaryTealLight,
          EnhancedCreateColors.accentOrangeLight,
          EnhancedCreateColors.backgroundGradientStart,
          EnhancedCreateColors.backgroundGradientEnd,
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ),
    );
  }

  BoxDecoration _buildGlassDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      boxShadow: [
        BoxShadow(
          color: EnhancedCreateColors.primaryTeal.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'art_walk_enhanced_art_walk_create_text_leave_art_walk'.tr(),
            ),
            content: Text(
              'art_walk_enhanced_art_walk_create_text_your_progress_will'.tr(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('art_walk_enhanced_art_walk_create_text_stay'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'art_walk_enhanced_art_walk_create_text_leave'.tr(),
                ),
              ),
            ],
          ),
        );
        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: MainLayout(
        currentIndex: -1,
        appBar: EnhancedUniversalHeader(
          title: widget.artWalkId == null ? 'Create Art Walk' : 'Edit Art Walk',
          showLogo: false,
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xFF4FB3BE), // Light Teal
              Color(0xFFFF9E80), // Light Orange/Peach
            ],
          ),
          titleGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xFF4FB3BE), // Light Teal
              Color(0xFFFF9E80), // Light Orange/Peach
            ],
          ),
        ),
        child: _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Stack(
      children: [
        // Background gradient
        Container(decoration: _buildBackgroundDecoration()),
        Column(
          children: [
            // Persistent selected items bar
            if (_selectedArtPieces.isNotEmpty) _buildPersistentSelectedBar(),
            // Scrollable content
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  // Dismiss keyboard when tapping outside text fields
                  FocusScope.of(context).unfocus();
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildProgressIndicator(),
                        const SizedBox(height: 16),
                        _buildTitleField(),
                        const SizedBox(height: 16),
                        _buildDescriptionField(),
                        const SizedBox(height: 24),
                        _buildMapSection(),
                        const SizedBox(height: 24),
                        _buildArtPiecesSection(),
                        const SizedBox(height: 32),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_isUploading) // Add loading overlay
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildPersistentSelectedBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: _buildGlassDecoration().copyWith(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            '${_selectedArtPieces.length} art piece${_selectedArtPieces.length == 1 ? '' : 's'} selected',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // Show thumbnails of first few selected items
          ..._selectedArtPieces
              .take(3)
              .map(
                (art) => Container(
                  margin: const EdgeInsets.only(left: 4),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      art.title.isNotEmpty ? art.title[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          if (_selectedArtPieces.length > 3)
            Container(
              margin: const EdgeInsets.only(left: 4),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  '+${_selectedArtPieces.length - 3}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final int progress = _calculateProgress();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getProgressMessage(progress),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  int _calculateProgress() {
    int progress = 0;
    if (_titleController.text.isNotEmpty) progress += 20;
    if (_descriptionController.text.isNotEmpty) progress += 20;
    if (_selectedArtPieces.isNotEmpty) progress += 30;
    if (_routePoints.isNotEmpty) progress += 30;
    return progress;
  }

  String _getProgressMessage(int progress) {
    if (progress < 20) return 'Start by giving your walk a name! 🎨';
    if (progress < 40)
      return 'Great title! Now describe your artistic journey ✍️';
    if (progress < 70) return 'Add some art pieces to create your path 🗺️';
    if (progress < 100) return 'Almost there! Finalize your route 🎯';
    return 'Perfect! Ready to share your art walk! 🎉';
  }

  Widget _buildTitleField() {
    return Container(
      decoration: _buildGlassDecoration(),
      child: TextFormField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Title',
          hintText: 'Give your art walk a creative name',
          prefixIcon: Icon(Icons.title, color: Colors.white70),
          border: InputBorder.none,
          filled: false,
          labelStyle: TextStyle(color: Colors.white70),
          hintStyle: TextStyle(color: Colors.white54),
        ),
        style: const TextStyle(color: Colors.white),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a title';
          }
          return null;
        },
        onChanged: (_) => setState(() {}), // Update progress
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: _buildGlassDecoration(),
      child: TextFormField(
        controller: _descriptionController,
        decoration: const InputDecoration(
          labelText: 'Description',
          hintText: 'Describe your art walk experience',
          prefixIcon: Icon(Icons.description, color: Colors.white70),
          border: InputBorder.none,
          filled: false,
          labelStyle: TextStyle(color: Colors.white70),
          hintStyle: TextStyle(color: Colors.white54),
        ),
        style: const TextStyle(color: Colors.white),
        maxLines: 3,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a description';
          }
          return null;
        },
        onChanged: (_) => setState(() {}), // Update progress
      ),
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Map View',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Map or List View Toggle
        Container(
          decoration: const BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _showMapView = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _showMapView
                          ? EnhancedCreateColors.primaryTeal
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        'Map',
                        style: TextStyle(
                          color: _showMapView ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _showMapView = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !_showMapView
                          ? EnhancedCreateColors.primaryTeal
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        'List',
                        style: TextStyle(
                          color: !_showMapView ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Map or List View
        SizedBox(
          height: 200, // Reduced from 300
          child: _showMapView ? _buildMapView() : _buildListView(),
        ),
      ],
    );
  }

  Widget _buildArtPiecesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Art Pieces (${_availableArtPieces.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Available Art Pieces
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          _availableArtPieces.isEmpty
              ? Center(
                  child: Text(
                    'art_walk_enhanced_art_walk_create_text_no_art_pieces'.tr(),
                  ),
                )
              : SizedBox(
                  height: 300, // Fixed height for grid
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                        ),
                    itemCount: _availableArtPieces.length,
                    itemBuilder: (context, index) {
                      final art = _availableArtPieces[index];
                      final isSelected = _selectedArtPieces.contains(art);

                      return _buildCompactArtCard(art, isSelected);
                    },
                  ),
                ),
      ],
    );
  }

  Widget _buildCompactArtCard(PublicArtModel art, bool isSelected) {
    return Card(
      color: isSelected
          ? EnhancedCreateColors.primaryTeal.withValues(alpha: 0.1)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? EnhancedCreateColors.primaryTeal
              : Colors.grey.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _toggleArtPieceSelection(art),
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 140, // Increased height for larger image
          child: Stack(
            children: [
              // Image section with larger size
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: EnhancedCreateColors.backgroundGradientStart,
                  image:
                      ImageUrlValidator.safeCorrectedNetworkImage(
                            art.imageUrl,
                          ) !=
                          null
                      ? DecorationImage(
                          image: ImageUrlValidator.safeCorrectedNetworkImage(
                            art.imageUrl,
                          )!,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !ImageUrlValidator.isValidImageUrl(art.imageUrl)
                    ? const Icon(
                        Icons.palette,
                        color: EnhancedCreateColors.primaryTeal,
                        size: 40,
                      )
                    : null,
              ),

              // Bottom fade overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60, // Height of the fade area
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // Title and distance overlay on fade
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      art.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 12,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Distance indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: EnhancedCreateColors.accentOrange.withValues(
                          alpha: 0.9,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '~${_calculateDistance(art)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: EnhancedCreateColors.primaryTeal.withValues(
                        alpha: 0.9,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateDistance(PublicArtModel art) {
    if (_currentPosition == null) return '?';
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      art.location.latitude,
      art.location.longitude,
    );

    final String distanceUnit = _userSettings?.distanceUnit ?? 'miles';
    return DistanceUtils.formatDistance(
      distance,
      unit: distanceUnit,
      includeUnit: false,
    );
  }

  Widget _buildMapView() {
    if (_mapCenter == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (kIsWeb) {
      return _buildWebMapFallback();
    }

    return GoogleMap(
      onMapCreated: _onMapCreated,
      onTap: _onMapTap,
      initialCameraPosition: CameraPosition(target: _mapCenter!, zoom: 12.0),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapType: MapType.normal,
      zoomControlsEnabled: true,
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _availableArtPieces.length,
      itemBuilder: (context, index) {
        final art = _availableArtPieces[index];
        final isSelected = _selectedArtPieces.contains(art);

        return Card(
          child: ListTile(
            leading:
                ImageUrlValidator.safeCorrectedNetworkImage(art.imageUrl) !=
                    null
                ? CircleAvatar(
                    child: Builder(
                      builder: (context) {
                        if (kDebugMode) {
                          print('🖼️ Loading art image: ${art.imageUrl}');
                        }
                        return Image(
                          image: ImageUrlValidator.safeCorrectedNetworkImage(
                            art.imageUrl,
                          )!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              if (kDebugMode) {
                                print(
                                  '✅ Art image loaded successfully: ${art.imageUrl}',
                                );
                              }
                              return child;
                            }
                            return const CircularProgressIndicator();
                          },
                          errorBuilder: (context, error, stackTrace) {
                            if (kDebugMode) {
                              print(
                                '❌ Art image load error: $error for ${art.imageUrl}',
                              );
                              print('Stack trace: $stackTrace');
                            }
                            return const Icon(Icons.art_track);
                          },
                        );
                      },
                    ),
                  )
                : Builder(
                    builder: (context) {
                      if (kDebugMode) {
                        print(
                          '⚠️ Art image URL invalid or empty: "${art.imageUrl}"',
                        );
                      }
                      return CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
            title: Text(art.title),
            subtitle: Text(art.artistName ?? 'Unknown Artist'),
            trailing: Checkbox(
              value: isSelected,
              onChanged: (value) => _toggleArtPieceSelection(art),
            ),
            onTap: () => _toggleArtPieceSelection(art),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    final progress = _calculateProgress();
    return Container(
      decoration: _buildGlassDecoration(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 56,
        child: ElevatedButton(
          onPressed: progress == 100 ? _submitForm : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: progress == 100
                ? EnhancedCreateColors.primaryTeal
                : Colors.white24,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: progress == 100 ? 4 : 0,
          ),
          child: Text(
            progress == 100 ? 'Share Your Art Walk' : 'Complete Your Walk',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildWebMapFallback() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Create Art Walk',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Map-based art walk creation is optimized for mobile devices.\nUse the list view below to select art pieces for your walk.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
