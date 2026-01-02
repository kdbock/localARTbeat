import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/artbeat_core.dart'
    hide GlassCard, WorldBackground, HudTopBar, GradientCTAButton;
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
  late final ArtWalkService _artWalkService;
  late final AchievementService _achievementService;
  late ArtWalkNavigationService _navigationService;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
    _artWalkService = context.read<ArtWalkService>();
    _achievementService = context.read<AchievementService>();
    _navigationService = context.read<ArtWalkNavigationService>();
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
            title: 'art_walk_art_walk_detail_marker_title'.tr(
              namedArgs: {'index': '${i + 1}', 'title': art.title},
            ),
            snippet: art.artistName != null && art.artistName!.trim().isNotEmpty
                ? 'art_walk_art_walk_detail_marker_by_artist'.tr(
                    namedArgs: {'artist': art.artistName!},
                  )
                : null,
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
        color: ArtWalkDesignSystem.primaryTeal,
        width: 4,
      ),
    };
  }

  Future<void> _shareArtWalk() async {
    if (_walk == null) return;

    try {
      await share_plus.SharePlus.instance.share(
        share_plus.ShareParams(
          text: 'art_walk_art_walk_detail_share_message'.tr(
            namedArgs: {'title': _walk!.title},
          ),
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
              label: 'art_walk_art_walk_detail_button_view_all'.tr(),
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
        SnackBar(
          content: Text(
            'art_walk_art_walk_detail_text_navigation_started'.tr(),
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
      return _buildStatusScaffold(
        ArtWalkScreenTemplate.buildLoadingState(
          message: 'art_walk_art_walk_detail_text_loading_art_walk_details'
              .tr(),
        ),
      );
    }

    if (_walk == null) {
      return _buildStatusScaffold(
        ArtWalkScreenTemplate.buildEmptyState(
          title: 'art_walk_art_walk_detail_text_art_walk_not'.tr(),
          subtitle: 'art_walk_art_walk_detail_text_the_requested_art'.tr(),
          icon: Icons.error_outline,
          actionText: 'art_walk_common_go_back'.tr(),
          onAction: () => Navigator.pop(context),
        ),
      );
    }

    return ArtWalkWorldScaffold(
      title: 'art_walk_art_walk_detail_text_art_walk_details',
      scaffoldKey: _scaffoldKey,
      drawer: const ArtWalkDrawer(),
      actions: [
        IconButton(
          icon: const Icon(Icons.ios_share),
          tooltip: 'art_walk_art_walk_detail_button_share'.tr(),
          onPressed: _shareArtWalk,
        ),
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          tooltip: 'art_walk_art_walk_detail_button_messages'.tr(),
          onPressed: () => Navigator.pushNamed(context, '/messaging'),
        ),
      ],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSection(),
              const SizedBox(height: 24),
              _buildStatsSection(),
              const SizedBox(height: 16),
              _buildStartingPointCard(),
              const SizedBox(height: 24),
              _buildPrimaryActions(),
              if (_showNavigationPanel) ...[
                const SizedBox(height: 24),
                _buildNavigationPanelCard(),
              ],
              const SizedBox(height: 24),
              _buildMapSection(),
              const SizedBox(height: 24),
              _buildArtListSection(),
              const SizedBox(height: 32),
              ArtWalkCommentSection(
                artWalkId: widget.walkId,
                artWalkTitle: _walk!.title,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusScaffold(Widget child) {
    return ArtWalkWorldScaffold(
      title: 'art_walk_art_walk_detail_text_art_walk_details',
      scaffoldKey: _scaffoldKey,
      drawer: const ArtWalkDrawer(),
      body: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }

  Widget _buildHeroSection() {
    return GlassCard(
      borderRadius: 32,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            SizedBox(
              height: 240,
              width: double.infinity,
              child: _buildDetailBackground(),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _walk!.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _walk!.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      Colors.white.withValues(alpha: 0.85),
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

  Widget _buildStatsSection() {
    final stats = <Widget>[];

    stats.add(
      _buildStatPill(
        icon: Icons.photo_outlined,
        label: 'art_walk_art_walk_detail_stat_artworks'.tr(),
        value: '${_artPieces.length}',
      ),
    );

    final distance = _walk!.estimatedDistance ?? _calculateTotalDistance();
    if (distance > 0) {
      stats.add(
        _buildStatPill(
          icon: Icons.route_outlined,
          label: 'art_walk_art_walk_detail_stat_distance'.tr(),
          value: 'art_walk_art_walk_detail_stat_distance_value'.tr(
            namedArgs: {'miles': distance.toStringAsFixed(1)},
          ),
        ),
      );
    }

    final duration = _walk!.estimatedDuration;
    if (duration != null) {
      stats.add(
        _buildStatPill(
          icon: Icons.access_time,
          label: 'art_walk_art_walk_detail_stat_duration'.tr(),
          value: 'art_walk_art_walk_detail_stat_duration_value'.tr(
            namedArgs: {'minutes': duration.round().toString()},
          ),
        ),
      );
    } else if (distance > 0) {
      stats.add(
        _buildStatPill(
          icon: Icons.access_time,
          label: 'art_walk_art_walk_detail_stat_estimated_time'.tr(),
          value: 'art_walk_art_walk_detail_stat_estimated_time_value'.tr(
            namedArgs: {'minutes': (distance * 19).round().toString()},
          ),
        ),
      );
    }

    stats.add(
      _buildStatPill(
        icon: Icons.visibility,
        label: 'art_walk_art_walk_detail_stat_views'.tr(),
        value: _walk!.viewCount.toString(),
      ),
    );

    return GlassCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(24),
      child: Wrap(spacing: 16, runSpacing: 16, children: stats),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 180),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.black.withValues(alpha: 0.3),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: ArtWalkDesignSystem.primaryTeal, size: 20),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.helper(Colors.white.withValues(alpha: 0.85)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartingPointCard() {
    return GlassCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ArtWalkDesignSystem.primaryTeal,
                      ArtWalkDesignSystem.primaryTealLight,
                    ],
                  ),
                ),
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Text(
                'art_walk_art_walk_detail_section_starting_point'.tr(),
                style: AppTypography.screenTitle(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'art_walk_art_walk_detail_body_starting_point_description'.tr(),
            style: AppTypography.body(Colors.white.withValues(alpha: 0.85)),
          ),
          if (_artPieces.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'art_walk_art_walk_detail_body_first_stop'.tr(
                namedArgs: {'title': _artPieces.first.title},
              ),
              style: AppTypography.sectionLabel(
                ArtWalkDesignSystem.primaryTeal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrimaryActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GradientCTAButton(
          label: 'art_walk_art_walk_detail_button_start_art_walk_navigation'
              .tr(),
          icon: Icons.navigation,
          onPressed: _startNavigation,
        ),
        const SizedBox(height: 8),
        Text(
          'art_walk_art_walk_detail_helper_turn_by_turn'.tr(),
          style: AppTypography.helper(Colors.white.withValues(alpha: 0.85)),
        ),
        const SizedBox(height: 24),
        if (!_hasCompletedWalk)
          GradientCTAButton(
            label: _isCompletingWalk
                ? 'art_walk_art_walk_detail_button_completing'.tr()
                : 'art_walk_art_walk_detail_button_complete_walk'.tr(),
            icon: Icons.check_circle,
            onPressed: _isCompletingWalk ? null : _completeArtWalk,
          )
        else
          GlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.celebration,
                  color: ArtWalkDesignSystem.primaryTeal,
                ),
                const SizedBox(width: 16),
                Text(
                  'art_walk_art_walk_detail_status_completed'.tr(),
                  style: AppTypography.body(
                    Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNavigationPanelCard() {
    return GlassCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                child: const Icon(
                  Icons.navigation,
                  color: ArtWalkDesignSystem.primaryTeal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'art_walk_art_walk_detail_section_navigation'.tr(),
                  style: AppTypography.sectionLabel(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'art_walk_button_cancel'.tr(),
                onPressed: _stopDetailNavigation,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isNavigationActive && _currentRoute != null)
            TurnByTurnNavigationWidget(
              navigationService: _navigationService,
              isCompact: true,
              onStopNavigation: _stopDetailNavigation,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'art_walk_art_walk_detail_body_start_navigation_prompt'.tr(),
                  style: AppTypography.body(
                    Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 16),
                GradientCTAButton(
                  label: 'art_walk_art_walk_detail_text_start_navigation'.tr(),
                  icon: Icons.navigation,
                  height: 48,
                  onPressed: _startDetailNavigation,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return GlassCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.map_outlined,
                color: ArtWalkDesignSystem.primaryTeal,
              ),
              const SizedBox(width: 16),
              Text(
                'art_walk_art_walk_detail_section_map_preview'.tr(),
                style: AppTypography.sectionLabel(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 256,
              child: kIsWeb
                  ? _buildWebMapFallback()
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _markers.isNotEmpty
                            ? _markers.first.position
                            : const LatLng(37.7749, -122.4194),
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
        ],
      ),
    );
  }

  Widget _buildArtListSection() {
    if (_artPieces.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'art_walk_art_walk_detail_section_art_in_walk'.tr(),
          style: AppTypography.sectionLabel(),
        ),
        const SizedBox(height: 16),
        ..._artPieces.asMap().entries.map((entry) {
          final index = entry.key;
          final art = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _artPieces.length - 1 ? 0 : 16,
            ),
            child: _buildArtCard(art, index, key: ValueKey('art_${art.id}')),
          );
        }),
      ],
    );
  }

  Widget _buildArtCard(PublicArtModel art, int index, {Key? key}) {
    return Semantics(
      button: true,
      label: art.title,
      child: GestureDetector(
        key: key,
        onTap: () => _openArtDetail(art),
        child: GlassCard(
          borderRadius: 28,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ArtWalkDesignSystem.primaryTeal,
                      ArtWalkDesignSystem.primaryTealLight,
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SecureNetworkImage(
                  imageUrl: art.imageUrl,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    width: 96,
                    height: 96,
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      art.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (art.artistName != null &&
                        art.artistName!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'art_walk_art_detail_bottom_sheet_text_by_artist'.tr(
                          namedArgs: {'artist': art.artistName!},
                        ),
                        style: AppTypography.body(
                          ArtWalkDesignSystem.primaryTeal,
                        ),
                      ),
                    ],
                    if (art.artType != null &&
                        art.artType!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        art.artType!,
                        style: AppTypography.helper(
                          Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _openArtDetail(PublicArtModel art) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ArtDetailBottomSheet(art: art),
    );
  }

  Widget _buildWebMapFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF07060F), Color(0xFF0A1330)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.map_outlined,
              size: 48,
              color: ArtWalkDesignSystem.primaryTeal,
            ),
            const SizedBox(height: 16),
            Text(
              'art_walk_art_walk_detail_text_art_walk_map_preview'.tr(),
              style: AppTypography.screenTitle(ArtWalkDesignSystem.primaryTeal),
            ),
            const SizedBox(height: 8),
            Text(
              'art_walk_art_walk_detail_text_map_helper'.tr(),
              style: AppTypography.body(Colors.white.withValues(alpha: 0.75)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
