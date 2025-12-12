import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:logger/logger.dart';
import 'dart:math';

final Logger _logger = Logger();

class ArtWalkDetailScreen extends StatefulWidget {
  final String walkId;

  const ArtWalkDetailScreen({super.key, required this.walkId});

  @override
  State<ArtWalkDetailScreen> createState() => _ArtWalkDetailScreenState();
}

class _ArtWalkDetailScreenState extends State<ArtWalkDetailScreen> {
  final ArtWalkService _artWalkService = ArtWalkService();
  final AchievementService _achievementService = AchievementService();
  late ArtWalkNavigationService _navigationService;
  bool _isLoading = true;
  bool _isCompletingWalk = false;
  bool _hasCompletedWalk = false;
  bool _showNavigationPanel = false; // Track navigation panel visibility
  bool _isNavigationActive = false; // Track if navigation is currently running
  ArtWalkModel? _walk;
  List<PublicArtModel> _artPieces = [];
  Set<Marker> _markers = <Marker>{};
  Set<Polyline> _polylines = <Polyline>{};
  ArtWalkRouteModel? _currentRoute;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _navigationService = ArtWalkNavigationService();
    _loadArtWalk();
  }

  @override
  void dispose() {
    _disposed = true;
    // Stop navigation if active
    if (_isNavigationActive) {
      _navigationService.stopNavigation();
    }
    _navigationService.dispose();
    super.dispose();
  }

  /// Check if the current user has already completed this walk
  Future<void> _checkCompletionStatus() async {
    if (_walk == null) return;

    final userId = _artWalkService.getCurrentUserId();
    if (userId == null) return;

    try {
      final hasCompleted = await _achievementService.hasCompletedArtWalk(
        userId,
        _walk!.id,
      );
      if (mounted && !_disposed) {
        setState(() {
          _hasCompletedWalk = hasCompleted;
        });
      }
    } catch (e) {
      // debugPrint('Error checking completion status: ${e.toString()}');
    }
  }

  Future<void> _loadArtWalk() async {
    if (mounted && !_disposed) {
      setState(() => _isLoading = true);
    }

    try {
      // First check for expired cache and clean it if needed
      await _artWalkService.checkAndClearExpiredCache();

      // Load the art walk
      final walk = await _artWalkService.getArtWalkById(widget.walkId);
      if (walk == null) {
        throw Exception('Art walk not found');
      }

      // Record the view (only if online)
      try {
        await _artWalkService.recordArtWalkView(walk.id);
      } catch (e) {
        // If offline, this will fail, but that's okay
        // debugPrint('Could not record view, probably offline: ${e.toString()}');
      }

      // Load all art pieces in the walk
      final artPieces = await _artWalkService.getArtInWalk(walk.id);

      // Create markers
      final markers = _createMarkers(artPieces);

      // Create polylines if route data available
      // final polylines = _createPolylines(walk, artPieces); // Updated: routePolyline removed from model
      final polylines = _createPolylines(artPieces); // Pass only artPieces

      if (mounted && !_disposed) {
        setState(() {
          _walk = walk;
          _artPieces = artPieces;
          _markers = markers;
          _polylines = polylines;
        });

        // Check if user has completed this walk
        await _checkCompletionStatus();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('art_walk_art_walk_detail_error_error_etostring'.tr()),
        ),
      );
    } finally {
      if (mounted && !_disposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  Set<Marker> _createMarkers(List<PublicArtModel> artPieces) {
    final Set<Marker> markers = {};

    for (int i = 0; i < artPieces.length; i++) {
      final art = artPieces[i];

      // Skip art pieces with invalid coordinates to prevent NaN errors
      if (!art.location.latitude.isFinite || !art.location.longitude.isFinite) {
        // debugPrint(
        //   "⚠️ Skipping marker for art with invalid coordinates: ${art.id}",
        // );
        continue;
      }

      markers.add(
        Marker(
          markerId: MarkerId(art.id),
          position: LatLng(art.location.latitude, art.location.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(
            title: '${i + 1}. ${art.title}',
            snippet: art.artistName != null ? 'by ${art.artistName}' : null,
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _createPolylines(
    // ArtWalkModel walk, // Removed walk parameter
    List<PublicArtModel> artPieces,
  ) {
    // If there are not enough art pieces, return empty set
    if (artPieces.length < 2) {
      return {};
    }

    // Filter out any art with invalid coordinates to prevent NaN errors
    final validArtPieces = artPieces
        .where(
          (art) =>
              art.location.latitude.isFinite && art.location.longitude.isFinite,
        )
        .toList();

    // Check if we still have enough valid points
    if (validArtPieces.length < 2) {
      // debugPrint("⚠️ Not enough valid coordinates for polyline");
      return {};
    }

    // Create points for polyline from valid art pieces only
    final points = validArtPieces
        .map((art) => LatLng(art.location.latitude, art.location.longitude))
        .toList();

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: Colors.blue,
        width: 4,
      ),
    };
  }

  Future<void> _shareArtWalk() async {
    if (_walk == null) return;

    try {
      await share_plus.SharePlus.instance.share(
        share_plus.ShareParams(
          text: 'Check out this Art Walk: "${_walk!.title}" on WordNerd!',
        ),
      );

      await _artWalkService.recordArtWalkShare(_walk!.id);
      _logger.i('Shared successfully');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'art_walk_art_walk_detail_error_error_sharing_etostring'.tr(),
          ),
        ),
      );
      _logger.e('Error sharing: ${e.toString()}');
    }
  }

  Widget _buildDetailBackground() {
    // Try to show cover image first
    if (_walk!.coverImageUrl != null && _walk!.coverImageUrl!.isNotEmpty) {
      return SecureNetworkImage(
        imageUrl: _walk!.coverImageUrl!,
        fit: BoxFit.cover,
        errorWidget: _buildFallbackBackground(),
      );
    }

    // Try to show first image from imageUrls
    if (_walk!.imageUrls.isNotEmpty) {
      return SecureNetworkImage(
        imageUrl: _walk!.imageUrls.first,
        fit: BoxFit.cover,
        errorWidget: _buildFallbackBackground(),
      );
    }

    // Show fallback background
    return _buildFallbackBackground();
  }

  Widget _buildFallbackBackground() {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.map, size: 60, color: Colors.white),
      ),
    );
  }

  /// Calculate total distance for the walk
  double _calculateTotalDistance() {
    if (_artPieces.isEmpty) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < _artPieces.length - 1; i++) {
      final art1 = _artPieces[i];
      final art2 = _artPieces[i + 1];
      totalDistance += _calculateDistance(
        art1.location.latitude,
        art1.location.longitude,
        art2.location.latitude,
        art2.location.longitude,
      );
    }
    return totalDistance;
  }

  /// Calculate distance between two points in miles
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 3959.0; // miles
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) *
            cos(lat2 * pi / 180.0) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  void _startNavigation() {
    if (_walk == null) return;

    // Navigate to the enhanced art walk experience
    Navigator.pushNamed(
      context,
      ArtWalkRoutes.experience,
      arguments: {'artWalkId': _walk!.id, 'artWalk': _walk!},
    );
  }

  Future<void> _completeArtWalk() async {
    if (_walk == null) return;

    final userId = _artWalkService.getCurrentUserId();
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('art_walk_art_walk_detail_text_you_must_be'.tr()),
        ),
      );
      return;
    }

    setState(() => _isCompletingWalk = true);

    try {
      await _artWalkService.recordArtWalkCompletion(artWalkId: _walk!.id);

      // Check if user received any new achievements
      final unviewedAchievements = await _achievementService
          .getUnviewedAchievements();

      if (mounted) {
        setState(() {
          _hasCompletedWalk = true;
          _isCompletingWalk = false;
        });
      }

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'art_walk_art_walk_detail_text_art_walk_completed'.tr(),
          ),
        ),
      );

      // If there are new achievements, show them
      if (unviewedAchievements.isNotEmpty) {
        for (final achievement in unviewedAchievements) {
          // Show one achievement at a time with a dialog
          if (!mounted) return;
          await NewAchievementDialog.show(context, achievement.id);
          // Mark as viewed after showing
          await _achievementService.markAchievementAsViewed(achievement.id);
        }

        // Show a snackbar with option to view all achievements
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('art_walk_art_walk_detail_text_you_earned_new'.tr()),
            action: SnackBarAction(
              label: 'View All',
              onPressed: () {
                if (!mounted) return;
                Navigator.pushNamed(context, '/achievements');
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompletingWalk = false);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'art_walk_art_walk_detail_error_error_completing_art'.tr(),
          ),
        ),
      );
    }
  }

  /// Start turn-by-turn navigation in the detail screen
  Future<void> _startDetailNavigation() async {
    if (_walk == null || _artPieces.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('art_walk_art_walk_detail_text_unable_to_start'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Get current location
      final currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Generate route
      final route = await _navigationService.generateRoute(
        _walk!.id,
        _artPieces,
        currentPosition,
      );

      if (!mounted) return;

      setState(() {
        _currentRoute = route;
        _isNavigationActive = true;
        _showNavigationPanel = true;
        _isLoading = false;
      });

      // Start navigation
      await _navigationService.startNavigation(route);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Navigation started! Follow the turn-by-turn instructions.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('art_walk_art_walk_detail_error_failed_to_start'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Stop turn-by-turn navigation
  Future<void> _stopDetailNavigation() async {
    await _navigationService.stopNavigation();

    if (!mounted) return;
    setState(() {
      _isNavigationActive = false;
      _showNavigationPanel = false;
      _currentRoute = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('art_walk_art_walk_detail_text_navigation_stopped'.tr()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MainLayout(
        currentIndex: -1,
        drawer: const ArtWalkDrawer(),
        child: Scaffold(
          key: const ValueKey('loading'),
          appBar: ArtWalkDesignSystem.buildAppBar(
            title: 'Art Walk Details',
            showBackButton: true,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.chat,
                  color: ArtWalkDesignSystem.textLight,
                ),
                onPressed: () => Navigator.pushNamed(context, '/messaging'),
              ),
            ],
          ),
          body: ArtWalkDesignSystem.buildScreenContainer(
            child: ArtWalkScreenTemplate.buildLoadingState(
              message: 'Loading art walk details...',
            ),
          ),
        ),
      );
    }

    if (_walk == null) {
      return MainLayout(
        currentIndex: -1,
        drawer: const ArtWalkDrawer(),
        child: Scaffold(
          key: const ValueKey('not_found'),
          appBar: ArtWalkDesignSystem.buildAppBar(
            title: 'Art Walk Details',
            showBackButton: true,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.chat,
                  color: ArtWalkDesignSystem.textLight,
                ),
                onPressed: () => Navigator.pushNamed(context, '/messaging'),
              ),
            ],
          ),
          body: ArtWalkDesignSystem.buildScreenContainer(
            child: ArtWalkScreenTemplate.buildEmptyState(
              title: 'Art Walk Not Found',
              subtitle: 'The requested art walk could not be found.',
              icon: Icons.error_outline,
              actionText: 'Go Back',
              onAction: () => Navigator.pop(context),
            ),
          ),
        ),
      );
    }

    return MainLayout(
      currentIndex: -1,
      drawer: const ArtWalkDrawer(),
      child: Scaffold(
        key: ValueKey('art_walk_${_walk!.id}'),
        body: CustomScrollView(
          key: ValueKey('scroll_view_${_walk!.id}'),
          slivers: [
            // App bar with image - using Art Walk colors
            SliverAppBar(
              expandedHeight: 200.0,
              pinned: true,
              backgroundColor: const Color(
                0xFF00838F,
              ), // Art Walk header color - matches Welcome Travel user box teal
              foregroundColor: Colors.white, // Art Walk text/icon color
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _walk!.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Limelight',
                    fontWeight: FontWeight.normal,
                  ),
                ),
                background: _buildDetailBackground(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: _shareArtWalk,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/messaging'),
                  tooltip: 'Messages',
                ),
              ],
            ),

            // Content
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats and info card
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _walk!.description,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),

                          // Stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStat(
                                Icons.photo,
                                '${_artPieces.length}',
                                'Artworks',
                              ),
                              if (_artPieces.length > 1)
                                _buildStat(
                                  Icons.straighten,
                                  '${_calculateTotalDistance().toStringAsFixed(1)} mi',
                                  'Distance',
                                ),
                              if (_walk!.estimatedDuration != null)
                                _buildStat(
                                  Icons.access_time,
                                  '${_walk!.estimatedDuration!.round()} min',
                                  'Duration',
                                )
                              else if (_artPieces.length > 1)
                                _buildStat(
                                  Icons.access_time,
                                  '${(_calculateTotalDistance() * 19).round()} min',
                                  'Est. Time',
                                ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Starting point information
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.my_location,
                                      color: Colors.blue[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Starting Point',
                                      style: TextStyle(
                                        color: Colors.blue[600],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your current location will be used as the starting point. The app will guide you through each art piece in order.',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 14,
                                  ),
                                ),
                                if (_artPieces.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'First stop: ${_artPieces.first.title}',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Start art walk with navigation button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _startNavigation,
                              icon: const Icon(Icons.navigation),
                              label: const Text(
                                'Start Art Walk with Navigation',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Helper text
                          Text(
                            'Get turn-by-turn directions to each art piece',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          // Complete art walk button (only show if not already completed)
                          if (!_hasCompletedWalk) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isCompletingWalk
                                    ? null
                                    : _completeArtWalk,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                icon: _isCompletingWalk
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.check_circle),
                                label: Text(
                                  _isCompletingWalk
                                      ? 'Completing...'
                                      : 'Complete Art Walk',
                                ),
                              ),
                            ),
                          ],
                          // Show completed status if walk is completed
                          if (_hasCompletedWalk) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Completed',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Turn-by-turn navigation panel (expandable)
                  if (_showNavigationPanel) ...[
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.navigation,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Turn-by-Turn Navigation',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: _stopDetailNavigation,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Turn-by-turn navigation widget
                              if (_isNavigationActive && _currentRoute != null)
                                TurnByTurnNavigationWidget(
                                  navigationService: _navigationService,
                                  isCompact: true,
                                  onStopNavigation: _stopDetailNavigation,
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Start navigation to see turn-by-turn directions to each art piece.',
                                        style: TextStyle(fontSize: 14),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        onPressed: _startDetailNavigation,
                                        icon: const Icon(Icons.navigation),
                                        label: Text(
                                          'art_walk_art_walk_detail_text_start_navigation'
                                              .tr(),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
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
                  ],

                  // Map preview
                  Container(
                    height: 250,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb
                          ? _buildWebMapFallback()
                          : GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _markers.isNotEmpty
                                    ? _markers.first.position
                                    : const LatLng(
                                        37.7749,
                                        -122.4194,
                                      ), // Default to SF
                                zoom: 13,
                              ),
                              markers: _markers,
                              polylines: _polylines,
                              liteModeEnabled: true,
                              zoomControlsEnabled: false,
                              scrollGesturesEnabled: false,
                              rotateGesturesEnabled: false,
                              zoomGesturesEnabled: false,
                              tiltGesturesEnabled: false,
                              myLocationButtonEnabled: false,
                            ),
                    ),
                  ),

                  // Art pieces list
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Art in this Walk',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._artPieces.asMap().entries.map((entry) {
                          final index = entry.key;
                          final art = entry.value;
                          return _buildArtCard(
                            art,
                            index,
                            key: ValueKey('art_${art.id}'),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Comment section
            SliverToBoxAdapter(
              child: ArtWalkCommentSection(
                artWalkId: widget.walkId,
                artWalkTitle: _walk!.title,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildArtCard(PublicArtModel art, int index, {Key? key}) {
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index number
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
            child: SecureNetworkImage(
              imageUrl: art.imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorWidget: Container(
                width: 100,
                height: 100,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    art.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (art.artistName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'by ${art.artistName}',
                      style: const TextStyle(color: Colors.blue, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 6),
                  if (art.artType != null)
                    Text(
                      art.artType!,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebMapFallback() {
    return Container(
      color: const Color(0xFF00838F).withValues(alpha: 0.1), // Art Walk teal
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 48,
              color: Color(0xFF00838F), // Art Walk teal
            ),
            SizedBox(height: 16),
            Text(
              'Art Walk Map Preview',
              style: TextStyle(
                color: Color(0xFF00838F),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Interactive map available on mobile devices',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
