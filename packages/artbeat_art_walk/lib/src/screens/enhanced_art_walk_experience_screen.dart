import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' show sin, cos, sqrt, atan2, pi;

/// Enhanced art walk experience screen with turn-by-turn navigation
class EnhancedArtWalkExperienceScreen extends StatefulWidget {
  final String artWalkId;
  final ArtWalkModel artWalk;
  final ArtWalkService? artWalkService;

  const EnhancedArtWalkExperienceScreen({
    super.key,
    required this.artWalkId,
    required this.artWalk,
    this.artWalkService,
  });

  @override
  State<EnhancedArtWalkExperienceScreen> createState() =>
      _EnhancedArtWalkExperienceScreenState();
}

class _EnhancedArtWalkExperienceScreenState
    extends State<EnhancedArtWalkExperienceScreen>
    with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<PublicArtModel> _artPieces = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  bool _isNavigationMode = false;
  bool _showCompactNavigation = false;
  bool _isStartingNavigation = false;

  // Progress tracking
  ArtWalkProgress? _currentProgress;
  final ArtWalkProgressService _progressService = ArtWalkProgressService();
  final AudioNavigationService _audioService = AudioNavigationService();
  final SocialService _socialService = SocialService();

  // New services for enhanced UX
  SmartOnboardingService? _onboardingService;
  HapticFeedbackService? _hapticService;

  // Tutorial overlay state
  TutorialStep? _currentTutorialStep;
  bool _showTutorialOverlay = false;

  // Navigation services
  ArtWalkService? _artWalkService;
  ArtWalkService get artWalkService =>
      _artWalkService ??= widget.artWalkService ?? ArtWalkService();
  late ArtWalkNavigationService _navigationService;
  ArtWalkRouteModel? _currentRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _navigationService = ArtWalkNavigationService();
    _initializeServices();
    _initializeWalk();
  }

  @override
  void dispose() {
    debugPrint('🧭 Experience Screen: dispose() called');
    WidgetsBinding.instance.removeObserver(this);

    // Properly stop navigation before disposing
    if (_isNavigationMode) {
      debugPrint('🧭 Experience Screen: Stopping navigation before dispose');
      _navigationService.stopNavigation();
    }

    debugPrint('🧭 Experience Screen: Disposing navigation service');
    _navigationService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        // App is going to background - pause navigation to prevent crashes
        if (_isNavigationMode) {
          _pauseNavigationForBackground();
        }
        break;
      case AppLifecycleState.resumed:
        // App is coming back to foreground - resume navigation if it was active
        if (_isNavigationMode && _currentRoute != null) {
          _resumeNavigationFromBackground();
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        // App is being closed or becoming inactive - stop navigation
        if (_isNavigationMode) {
          _stopNavigation();
        }
        break;
      case AppLifecycleState.hidden:
        // Handle hidden state if needed
        break;
    }
  }

  /// Pause navigation when app goes to background
  void _pauseNavigationForBackground() {
    // Don't fully stop navigation, just pause location tracking
    // This prevents crashes while maintaining navigation state
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'art_walk_enhanced_art_walk_experience_text_navigation_paused_while'
                .tr(),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Resume navigation when app comes back to foreground
  void _resumeNavigationFromBackground() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'art_walk_enhanced_art_walk_experience_text_navigation_resumed'
                .tr(),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _initializeServices() async {
    await _audioService.initialize();

    // Initialize new services
    final prefs = await SharedPreferences.getInstance();
    _onboardingService = SmartOnboardingService(prefs, _audioService);
    await _onboardingService!.initializeOnboarding();

    _hapticService = await HapticFeedbackService.getInstance();
  }

  Future<void> _initializeWalk() async {
    await _getCurrentLocation();
    await _loadArtPieces();
    await _loadOrCreateProgress();
    _createMarkersAndRoute();

    setState(() {
      _isLoading = false;
    });

    // Show tutorial for first-time users
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorial();
    });

    // Don't auto-start navigation - let user manually start it
    if (_currentPosition == null) {
      // Show message if location is not available
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location not available. Please enable location services for navigation.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location services are disabled. Please enable them in settings.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permission denied. Navigation features will be limited.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission permanently denied. Please enable in app settings.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_enhanced_art_walk_experience_error_error_getting_location'
                  .tr(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadArtPieces() async {
    try {
      final artPieces = await artWalkService.getArtInWalk(widget.artWalkId);
      setState(() {
        _artPieces = artPieces;
      });
    } catch (e) {
      // debugPrint('Error loading art pieces: $e');
    }
  }

  Future<void> _loadOrCreateProgress() async {
    try {
      final userId = artWalkService.getCurrentUserId();
      if (userId == null) return;

      // Try to load existing progress
      debugPrint(
        '📊 _loadOrCreateProgress() - Attempting to load progress for userId=$userId, artWalkId=${widget.artWalkId}',
      );

      final existingProgress = await _progressService.getWalkProgress(
        userId,
        widget.artWalkId,
      );

      if (existingProgress != null) {
        debugPrint(
          '📊 _loadOrCreateProgress() - Found existing progress with ${existingProgress.visitedArt.length} visited pieces',
        );

        // Ensure totalArtCount matches current art walk
        final correctedProgress =
            existingProgress.totalArtCount != _artPieces.length
            ? existingProgress.copyWith(totalArtCount: _artPieces.length)
            : existingProgress;

        debugPrint(
          '📊 _loadOrCreateProgress() - Calling setCurrentProgress with ${correctedProgress.visitedArt.length} visited pieces',
        );

        // Set the progress service's internal current progress so that recordArtVisit and completeWalk work correctly
        _progressService.setCurrentProgress(correctedProgress);

        setState(() {
          _currentProgress = correctedProgress;
        });
      } else {
        debugPrint(
          '📊 _loadOrCreateProgress() - No existing progress found, creating new walk',
        );

        // Create new progress if none exists
        final newProgress = await _progressService.startWalk(
          artWalkId: widget.artWalkId,
          totalArtCount: _artPieces.length,
          userId: userId,
        );
        setState(() {
          _currentProgress = newProgress;
        });
      }
    } catch (e) {
      debugPrint('Error loading progress: $e');
    }
  }

  void _createMarkersAndRoute() {
    if (_artPieces.isEmpty) return;

    final markers = <Marker>{};
    final polylinePoints = <LatLng>[];

    // Add current location marker if available
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
      polylinePoints.add(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      );
    }

    // Create markers for each art piece
    for (int i = 0; i < _artPieces.length; i++) {
      final art = _artPieces[i];
      final isVisited = _isArtVisited(art.id);
      final isNext = i == _getNextUnvisitedIndex() && !isVisited;

      markers.add(
        Marker(
          markerId: MarkerId(art.id),
          position: LatLng(art.location.latitude, art.location.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isVisited
                ? BitmapDescriptor.hueGreen
                : isNext
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: '${i + 1}. ${art.title}',
            snippet: isVisited ? 'Visited ✓' : 'Tap for details',
          ),
          onTap: () => _showArtDetail(art),
        ),
      );

      polylinePoints.add(LatLng(art.location.latitude, art.location.longitude));
    }

    // Create route polyline
    if (polylinePoints.length > 1) {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('art_walk_route'),
          points: polylinePoints,
          color: _isNavigationMode ? Colors.blue : Colors.grey,
          width: _isNavigationMode ? 5 : 3,
          patterns: _isNavigationMode
              ? []
              : [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _startNavigation() async {
    // Prevent multiple simultaneous navigation starts
    if (_isStartingNavigation || _isNavigationMode) {
      debugPrint('🧭 Navigation already starting or active, ignoring tap');
      return;
    }

    // Haptic feedback for button press
    await _hapticService?.buttonPressed();

    if (_currentPosition == null || _artPieces.isEmpty) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to start navigation. Check your location settings.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _isStartingNavigation = true;
      });

      // Optimize the route for efficiency before generating navigation
      final currentLocation = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      final optimizedArtPieces =
          RouteOptimizationUtils.optimizeRouteFromLocation(
            _artPieces,
            currentLocation,
          );

      // Generate route with optimized art pieces
      debugPrint('🧭 Experience Screen: Generating route...');
      final route = await _navigationService.generateRoute(
        widget.artWalkId,
        optimizedArtPieces,
        _currentPosition!,
      );

      debugPrint(
        '🧭 Experience Screen: Route generated, entering navigation mode',
      );
      setState(() {
        _currentRoute = route;
        _artPieces =
            optimizedArtPieces; // Update art pieces to reflect optimized order
        _isNavigationMode = true;
        _isLoading = false;
        _isStartingNavigation = false;
      });
      debugPrint('🧭 Experience Screen: _isNavigationMode set to true');

      // Start navigation
      debugPrint('🧭 Experience Screen: Starting navigation service...');
      await _navigationService.startNavigation(route);
      debugPrint('🧭 Experience Screen: Navigation service started');

      // Update map with detailed route
      _updateMapWithRoute(route);

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Navigation started! Follow the turn-by-turn instructions.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isStartingNavigation = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('art_walk_art_walk_detail_error_failed_to_start'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopNavigation() async {
    // Haptic feedback for button press
    await _hapticService?.buttonPressed();

    await _navigationService.stopNavigation();
    setState(() {
      _isNavigationMode = false;
      _currentRoute = null;
      _showCompactNavigation = false;
      _isStartingNavigation = false;
    });
    _createMarkersAndRoute();

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'art_walk_enhanced_art_walk_experience_text_navigation_stopped'.tr(),
        ),
        backgroundColor: Colors.grey,
      ),
    );
  }

  void _handlePreviousStep() {
    debugPrint('🧭 Experience Screen: Handling previous step request');

    // Add haptic feedback
    _hapticService?.buttonPressed();

    // Check if we're in navigation mode
    if (!_isNavigationMode || _currentRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'art_walk_enhanced_art_walk_experience_text_navigation_not_active'
                .tr(),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Get current navigation state
    final currentStep = _navigationService.currentStep;
    final currentSegment = _navigationService.currentSegment;

    if (currentStep == null || currentSegment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'art_walk_enhanced_art_walk_experience_text_no_navigation_step'
                .tr(),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Check if we can go to previous step
    final currentStepIndex = currentSegment.steps.indexOf(currentStep);

    if (currentStepIndex > 0) {
      // Go to previous step in current segment
      debugPrint('🧭 Going to previous step in current segment');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'art_walk_enhanced_art_walk_experience_text_showing_previous_navigation'
                .tr(),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      // Note: The navigation service would need a method to manually set step index
      // For now, just show feedback that the feature is recognized
    } else {
      // We're at the first step of current segment
      // Could go to previous segment if available
      final currentSegmentIndex = _currentRoute!.segments.indexOf(
        currentSegment,
      );

      if (currentSegmentIndex > 0) {
        debugPrint('🧭 At first step, could go to previous segment');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_enhanced_art_walk_experience_text_at_first_step'.tr(),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // We're at the very beginning
        debugPrint('🧭 Already at the first step of the route');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_enhanced_art_walk_experience_text_already_at_the'.tr(),
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _updateMapWithRoute(ArtWalkRouteModel route) {
    // Update polylines with detailed route
    final polylines = <Polyline>{};

    for (int i = 0; i < route.segments.length; i++) {
      final segment = route.segments[i];
      final polylinePoints = <LatLng>[];

      for (final step in segment.steps) {
        polylinePoints.addAll(step.polylinePoints);
      }

      if (polylinePoints.isNotEmpty) {
        polylines.add(
          Polyline(
            polylineId: PolylineId('segment_$i'),
            points: polylinePoints,
            color: Colors.blue,
            width: 5,
          ),
        );
      }
    }

    setState(() {
      _polylines = polylines;
    });
  }

  void _showArtDetail(PublicArtModel art) {
    // Haptic feedback for marker tap
    _hapticService?.markerTapped();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ArtDetailBottomSheet(
        art: art,
        onVisitPressed: () => _markAsVisited(art),
        isVisited: _isArtVisited(art.id),
        distanceText: _getDistanceToArt(art),
      ),
    );
  }

  Future<void> _markAsVisited(PublicArtModel art) async {
    if (_isArtVisited(art.id) || _currentProgress == null) return;

    try {
      // Use the progress service to record the visit
      final updatedProgress = await _progressService.recordArtVisit(
        artId: art.id,
        userLocation: _currentPosition!,
        artLocation: Position(
          latitude: art.location.latitude,
          longitude: art.location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        ),
      );

      setState(() {
        _currentProgress = updatedProgress;
      });

      _createMarkersAndRoute();

      // Announce visit with audio
      await _audioService.celebrateArtVisit(art, 10);

      // Haptic feedback for achievement
      await _hapticService?.artPieceVisited();

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('art_walk_enhanced_art_walk_experience_text_marked_as_visited'.tr().replaceAll('{title}', art.title)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      if (_isWalkCompleted()) {
        _showWalkCompletionDialog();
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'art_walk_enhanced_art_walk_experience_error_error_marking_as'.tr(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Record a visit to an art piece when completing a navigation segment
  Future<void> _recordSegmentCompletionVisit(RouteSegment segment) async {
    try {
      // Find the art piece with the matching ID
      PublicArtModel? artPiece;
      for (final art in _artPieces) {
        if (art.id == segment.toArtPieceId) {
          artPiece = art;
          break;
        }
      }

      if (artPiece != null && !_isArtVisited(artPiece.id)) {
        debugPrint(
          '📊 Auto-recording visit for art piece: ${artPiece.id} during navigation',
        );

        // Mark it as visited using the existing visit recording
        await _markAsVisited(artPiece);
      }
    } catch (e) {
      debugPrint('📊 Error auto-recording segment completion visit: $e');
      // Don't throw - just silently handle errors so navigation isn't blocked
    }
  }

  void _showWalkCompletionDialog() {
    // Haptic feedback for walk completion
    _hapticService?.walkCompleted();

    // Calculate actual rewards
    final completionBonus = _calculateCompletionBonus();
    final photosCount =
        _currentProgress?.visitedArt
            .where((v) => v.photoTaken != null)
            .length ??
        0;
    final timeSpent = _currentProgress?.timeSpent ?? Duration.zero;
    final isPerfect = _currentProgress?.progressPercentage == 1.0;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(
          'art_walk_enhanced_art_walk_experience_text_walk_completed'.tr(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Congratulations! You\'ve completed this art walk.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rewards earned:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'art_walk_enhanced_art_walk_experience_text_completionbonus_xp_total'
                  .tr(args: [completionBonus.toString()]),
            ),
            if (isPerfect)
              Text(
                'art_walk_enhanced_art_walk_experience_text_perfect_completion_bonus'
                    .tr(),
              ),
            if (timeSpent.inHours < 2)
              Text(
                'art_walk_enhanced_art_walk_experience_text_speed_bonus_25'
                    .tr(),
              ),
            if (photosCount >= (_currentProgress?.visitedArt.length ?? 0) * 0.5)
              Text(
                'art_walk_enhanced_art_walk_experience_text_photo_documentation_bonus'
                    .tr(),
              ),
            const SizedBox(height: 8),
            Text(
              '• ${_currentProgress?.visitedArt.length ?? 0} art pieces visited',
            ),
            Text(
              'art_walk_enhanced_art_walk_experience_text_photoscount_photos_taken'
                  .tr(),
            ),
            Text(
              'art_walk_enhanced_art_walk_experience_text_formatdurationtimespent_duration'
                  .tr(),
            ),
            const SizedBox(height: 8),
            Text(
              'art_walk_enhanced_art_walk_experience_success_achievement_progress_updated'
                  .tr(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'art_walk_enhanced_art_walk_experience_text_review_walk'.tr(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _completeWalk();
            },
            child: Text(
              'art_walk_enhanced_art_walk_experience_text_claim_rewards'.tr(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeWalk() async {
    try {
      debugPrint('📊 _completeWalk() - Starting walk completion');

      // Ensure the final art piece is marked as visited if we're in navigation mode
      if (_isNavigationMode && _currentRoute != null && _artPieces.isNotEmpty) {
        debugPrint(
          '📊 _completeWalk() - Recording final art piece visit for safety',
        );
        final lastSegment = _currentRoute?.segments.last;
        if (lastSegment != null) {
          await _recordSegmentCompletionVisit(lastSegment);
        }
      }

      final completedProgress = await _progressService.completeWalk();
      debugPrint(
        '📊 _completeWalk() - Walk completed with ${completedProgress.visitedArt.length} visited pieces',
      );

      // Calculate actual distance traveled
      double totalDistance = 0.0;
      for (int i = 0; i < completedProgress.visitedArt.length - 1; i++) {
        final current = completedProgress.visitedArt[i];
        final next = completedProgress.visitedArt[i + 1];
        totalDistance += _calculateDistance(
          current.visitLocation.latitude,
          current.visitLocation.longitude,
          next.visitLocation.latitude,
          next.visitLocation.longitude,
        );
      }

      // Get new achievements
      final userId = FirebaseAuth.instance.currentUser?.uid;
      List<AchievementModel> newAchievements = [];
      if (userId != null) {
        final achievementService = AchievementService();
        newAchievements = await achievementService.checkForNewAchievements(
          userId: userId,
          walkCompleted: true,
          distanceWalked: totalDistance,
          artPiecesVisited: completedProgress.visitedArt.length,
        );
      }

      // Calculate personal bests
      final personalBests = await _calculatePersonalBests(
        distance: totalDistance,
        duration: completedProgress.timeSpent,
        artPieces: completedProgress.visitedArt.length,
      );

      // Get milestones
      final milestones = await _getMilestones(
        await _getTotalWalksCompleted(),
        await _getTotalDistance() + totalDistance,
      );

      // Create celebration data
      final celebrationData = CelebrationData(
        walk: widget.artWalk,
        progress: completedProgress,
        walkDuration: completedProgress.timeSpent,
        distanceWalked: totalDistance,
        artPiecesVisited: completedProgress.visitedArt.length,
        pointsEarned: completedProgress.totalPointsEarned,
        newAchievements: newAchievements,
        visitedArtPhotos: completedProgress.visitedArt
            .where((visit) => visit.photoTaken != null)
            .map((visit) => visit.photoTaken!)
            .toList(),
        personalBests: personalBests,
        milestones: milestones
            .map(
              (milestone) => CelebrationMilestone(
                id: milestone
                    .toLowerCase()
                    .replaceAll(' ', '_')
                    .replaceAll('!', '')
                    .replaceAll('🎉', '')
                    .replaceAll('🌟', '')
                    .replaceAll('🏆', '')
                    .replaceAll('🎨', '')
                    .replaceAll('👑', '')
                    .replaceAll('🌈', '')
                    .replaceAll('🚶', '')
                    .replaceAll('🏃', '')
                    .replaceAll('🎯', ''),
                title: milestone,
                description: milestone,
                icon: milestone.contains('🎉')
                    ? '🎉'
                    : milestone.contains('🌟')
                    ? '🌟'
                    : milestone.contains('🏆')
                    ? '🏆'
                    : '🎨',
                pointsAwarded: 0,
                type: MilestoneType.artPieces,
                metadata: const {},
              ),
            )
            .toList(),
        celebrationType: CelebrationType.regularCompletion,
        userPhotoUrl: widget.artWalk.coverImageUrl,
      );

      // Post walk completed activity to social feed
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _socialService.postActivity(
            userId: user.uid,
            userName: user.displayName ?? 'Anonymous Walker',
            userAvatar: user.photoURL,
            type: SocialActivityType.walkCompleted,
            message:
                'Completed "${widget.artWalk.title}" - visited ${completedProgress.visitedArt.length} art pieces!',
            location: _currentPosition,
            metadata: {
              'walkTitle': widget.artWalk.title,
              'artPiecesVisited': completedProgress.visitedArt.length,
              'distanceWalked': totalDistance,
              'walkDuration': completedProgress.timeSpent.inMinutes,
            },
          );
        }
      } catch (e) {
        // Don't fail the walk completion if social posting fails
        debugPrint('Failed to post walk completed activity: $e');
      }

      // Navigate to celebration screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) =>
                ArtWalkCelebrationScreen(celebrationData: celebrationData),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_enhanced_art_walk_experience_error_error_completing_walk'
                  .tr(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  /// Calculate personal bests for this walk
  Future<Map<String, dynamic>> _calculatePersonalBests({
    required double distance,
    required Duration duration,
    required int artPieces,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return {};

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final data = userDoc.data() ?? {};
      final stats = data['artWalkStats'] as Map<String, dynamic>? ?? {};

      final bests = <String, dynamic>{};

      // Check for personal bests
      if (distance > ((stats['longestWalk'] as num?) ?? 0)) {
        bests['longestWalk'] = distance;
      }
      if (artPieces > ((stats['mostArtInOneWalk'] as num?) ?? 0)) {
        bests['mostArtInOneWalk'] = artPieces;
      }
      if (duration.inMinutes < ((stats['fastestWalk'] as num?) ?? 999999)) {
        bests['fastestWalk'] = duration.inMinutes;
      }

      // Update Firestore if any bests
      if (bests.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {
            'artWalkStats': {...stats, ...bests},
          },
        );
      }

      return bests;
    } catch (e) {
      debugPrint('Error calculating personal bests: $e');
      return {};
    }
  }

  /// Get milestones achieved
  Future<List<String>> _getMilestones(
    int totalWalksCompleted,
    double totalDistance,
  ) async {
    final milestones = <String>[];

    // Walk count milestones
    if (totalWalksCompleted == 1) milestones.add('First Walk Completed! 🎉');
    if (totalWalksCompleted == 5) milestones.add('5 Walks Completed! 🌟');
    if (totalWalksCompleted == 10) milestones.add('10 Walks Completed! 🏆');
    if (totalWalksCompleted == 25) milestones.add('25 Walks Completed! 🎨');
    if (totalWalksCompleted == 50) milestones.add('50 Walks Completed! 👑');
    if (totalWalksCompleted == 100) {
      milestones.add('100 Walks - Art Legend! 🌈');
    }

    // Distance milestones (in km)
    final distanceKm = totalDistance / 1000;
    if (distanceKm >= 10 && distanceKm < 10.5) {
      milestones.add('10km Walked! 🚶');
    }
    if (distanceKm >= 50 && distanceKm < 50.5) {
      milestones.add('50km Walked! 🏃');
    }
    if (distanceKm >= 100 && distanceKm < 100.5) {
      milestones.add('100km Walked! 🎯');
    }

    return milestones;
  }

  /// Get total walks completed by user
  Future<int> _getTotalWalksCompleted() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 0;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final data = userDoc.data() ?? {};
      final stats = data['stats'] as Map<String, dynamic>? ?? {};
      return stats['walksCompleted'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error getting total walks completed: $e');
      return 0;
    }
  }

  /// Get total distance walked by user
  Future<double> _getTotalDistance() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 0.0;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final data = userDoc.data() ?? {};
      final stats = data['artWalkStats'] as Map<String, dynamic>? ?? {};
      return (stats['totalDistance'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('Error getting total distance: $e');
      return 0.0;
    }
  }

  String _getDistanceToArt(PublicArtModel art) {
    if (_currentPosition == null) return '';

    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      art.location.latitude,
      art.location.longitude,
    );

    if (distance < 1000) {
      return '${distance.round()}m away';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km away';
    }
  }

  int _getNextUnvisitedIndex() {
    if (_currentProgress == null) return 0;

    for (int i = 0; i < _artPieces.length; i++) {
      if (!_isArtVisited(_artPieces[i].id)) {
        return i;
      }
    }
    return 0;
  }

  bool _isArtVisited(String artId) {
    if (_currentProgress == null) return false;
    return _currentProgress!.visitedArt.any((visit) => visit.artId == artId);
  }

  bool _isWalkCompleted() {
    if (_currentProgress == null) return false;
    return _currentProgress!.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MainLayout(
        currentIndex: -1,
        child: Scaffold(
          appBar: EnhancedUniversalHeader(
            title: widget.artWalk.title,
            showLogo: false,
            showBackButton: true,
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
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
        }
      },
      child: MainLayout(
        currentIndex: -1,
        child: Scaffold(
          appBar:
              EnhancedUniversalHeader(
                    title: _buildTitleWithProgress(),
                    showLogo: false,
                    showBackButton: true,
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
                    actions: [
                      if (_isNavigationMode)
                        IconButton(
                          icon: Icon(
                            _showCompactNavigation
                                ? Icons.expand_more
                                : Icons.expand_less,
                          ),
                          onPressed: () {
                            setState(() {
                              _showCompactNavigation = !_showCompactNavigation;
                            });
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                'art_walk_enhanced_art_walk_experience_text_how_to_use'
                                    .tr(),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '• Tap "Start Navigation" for turn-by-turn directions',
                                  ),
                                  Text(
                                    'art_walk_enhanced_art_walk_experience_text_follow_the_blue'
                                        .tr(),
                                  ),
                                  const Text(
                                    '• Tap markers to view art details',
                                  ),
                                  const Text(
                                    '• Mark art as visited when you reach it',
                                  ),
                                  Text(
                                    'art_walk_enhanced_art_walk_experience_text_green_markers_visited'
                                        .tr(),
                                  ),
                                  const Text(
                                    '• Orange marker = next destination',
                                  ),
                                  Text(
                                    'art_walk_enhanced_art_walk_experience_text_red_markers_not'
                                        .tr(),
                                  ),
                                  if (_isNavigationMode) ...[
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Navigation Mode:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      '• Follow turn-by-turn instructions',
                                    ),
                                    const Text(
                                      '• Tap expand/collapse button to adjust navigation view',
                                    ),
                                  ],
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(
                                    'art_walk_enhanced_art_walk_experience_text_got_it'
                                        .tr(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: _handleMenuAction,
                        itemBuilder: (context) => [
                          if (_currentProgress?.status == WalkStatus.inProgress)
                            PopupMenuItem(
                              value: 'pause',
                              child: Row(
                                children: [
                                  const Icon(Icons.pause),
                                  const SizedBox(width: 8),
                                  Text(
                                    'art_walk_enhanced_art_walk_experience_text_pause_walk'
                                        .tr(),
                                  ),
                                ],
                              ),
                            ),
                          if (_currentProgress?.status == WalkStatus.paused)
                            PopupMenuItem(
                              value: 'resume',
                              child: Row(
                                children: [
                                  const Icon(Icons.play_arrow),
                                  const SizedBox(width: 8),
                                  Text(
                                    'art_walk_enhanced_art_walk_experience_text_resume_walk'
                                        .tr(),
                                  ),
                                ],
                              ),
                            ),
                          if (_currentProgress?.canComplete == true)
                            PopupMenuItem(
                              value: 'complete',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'art_walk_enhanced_art_walk_experience_text_complete_walk'
                                        .tr(),
                                  ),
                                ],
                              ),
                            ),
                          PopupMenuItem(
                            value: 'progress',
                            child: Row(
                              children: [
                                const Icon(Icons.analytics),
                                const SizedBox(width: 8),
                                Text(
                                  'art_walk_enhanced_art_walk_experience_text_view_progress'
                                      .tr(),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'abandon',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.exit_to_app,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'art_walk_enhanced_art_walk_experience_text_abandon_walk'
                                      .tr(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                  as PreferredSizeWidget,
          body: Stack(
            children: [
              // Map
              if (kIsWeb)
                _buildWebMapFallback()
              else
                GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _centerOnUserLocation();
                  },
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          )
                        : _artPieces.isNotEmpty
                        ? LatLng(
                            _artPieces[0].location.latitude,
                            _artPieces[0].location.longitude,
                          )
                        : const LatLng(35.5951, -82.5515),
                    zoom: 16.0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),

              // Enhanced Progress Visualization
              if (!_isNavigationMode || _showCompactNavigation)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: EnhancedProgressVisualization(
                    visitedCount: _currentProgress?.visitedArt.length ?? 0,
                    totalCount:
                        _currentProgress?.totalArtCount ?? _artPieces.length,
                    progressPercentage:
                        _currentProgress?.progressPercentage ?? 0.0,
                    isNavigationMode: _isNavigationMode,
                    onTap: () {
                      // Could expand to show detailed progress or achievements
                      _hapticService?.buttonPressed();
                    },
                  ),
                ),

              // Turn-by-turn navigation widget
              if (_isNavigationMode) ...[
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Builder(
                    builder: (context) {
                      debugPrint(
                        '🧭 Experience Screen: Building TurnByTurnNavigationWidget',
                      );
                      return TurnByTurnNavigationWidget(
                        navigationService: _navigationService,
                        isCompact: _showCompactNavigation,
                        onNextStep: () {
                          debugPrint(
                            '🧭 Experience Screen: Next step requested',
                          );
                          try {
                            // Before advancing, record a visit to the current segment's destination
                            final currentSegment =
                                _navigationService.currentSegment;
                            if (currentSegment != null &&
                                _currentPosition != null) {
                              _recordSegmentCompletionVisit(currentSegment);
                            }

                            _navigationService.nextStep();
                            debugPrint(
                              '🧭 Experience Screen: Next step called successfully',
                            );
                          } catch (e) {
                            debugPrint(
                              '🧭 Experience Screen: Error calling next step: $e',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'art_walk_enhanced_art_walk_experience_error_error_advancing_navigation'
                                      .tr(),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        onPreviousStep: () {
                          debugPrint(
                            '🧭 Experience Screen: Previous step requested',
                          );
                          try {
                            _handlePreviousStep();
                          } catch (e) {
                            debugPrint(
                              '🧭 Experience Screen: Error handling previous step: $e',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'art_walk_enhanced_art_walk_experience_error_error_with_previous'
                                      .tr(),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        onStopNavigation: () {
                          debugPrint(
                            '🧭 Experience Screen: Stop navigation requested',
                          );
                          try {
                            _stopNavigation();
                            debugPrint(
                              '🧭 Experience Screen: Stop navigation completed',
                            );
                          } catch (e) {
                            debugPrint(
                              '🧭 Experience Screen: Error stopping navigation: $e',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'art_walk_enhanced_art_walk_experience_error_error_stopping_navigation'
                                      .tr(),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        onCompleteWalk: () {
                          debugPrint(
                            '🧭 Experience Screen: Complete walk requested',
                          );
                          try {
                            _completeWalk();
                            debugPrint(
                              '🧭 Experience Screen: Complete walk called successfully',
                            );
                          } catch (e) {
                            debugPrint(
                              '🧭 Experience Screen: Error completing walk: $e',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'art_walk_enhanced_art_walk_experience_error_error_completing_walk'
                                      .tr(),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],

              // Navigation control button
              Positioned(
                bottom: 80,
                left: 16,
                right: 16,
                child: Builder(
                  builder: (context) {
                    debugPrint(
                      '🧭 UI State: _isNavigationMode = $_isNavigationMode',
                    );
                    debugPrint(
                      '🧭 UI State: _currentPosition = $_currentPosition',
                    );
                    debugPrint(
                      '🧭 UI State: _artPieces.length = ${_artPieces.length}',
                    );
                    debugPrint('🧭 UI State: Building navigation button area');

                    return Container(
                      color: Colors.red.withValues(
                        alpha: 0.3,
                      ), // Temporary debug background
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (!_isNavigationMode) ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isStartingNavigation
                                    ? null
                                    : () {
                                        debugPrint(
                                          '🧭 Start Navigation button pressed',
                                        );
                                        _startNavigation();
                                      },
                                icon: _isStartingNavigation
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Icon(Icons.navigation),
                                label: Text(
                                  _isStartingNavigation
                                      ? 'Starting...'
                                      : 'Start Navigation',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  debugPrint(
                                    '🧭 Stop Navigation button pressed',
                                  );
                                  _stopNavigation();
                                },
                                icon: const Icon(Icons.stop),
                                label: Text(
                                  'art_walk_enhanced_art_walk_experience_text_stop_navigation'
                                      .tr(),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Tutorial overlay
              if (_showTutorialOverlay && _currentTutorialStep != null)
                TutorialOverlay(
                  step: _currentTutorialStep!,
                  onDismiss: _dismissTutorial,
                  onComplete: _completeTutorial,
                ),
            ],
          ),
          floatingActionButton: _currentPosition != null
              ? FloatingActionButton(
                  onPressed: _centerOnUserLocation,
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  tooltip: 'Center on my location',
                  child: const Icon(Icons.my_location),
                )
              : null,
        ),
      ),
    );
  }

  void _centerOnUserLocation() {
    // Haptic feedback for button press
    _hapticService?.buttonPressed();

    if (_currentPosition == null || _mapController == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        16.0,
      ),
    );
  }

  /// Show tutorial overlay
  void _showTutorial() {
    if (_onboardingService == null) return;

    final tutorialStep = _onboardingService!.getNextTutorialStep(
      'art_walk_experience',
    );
    if (tutorialStep != null) {
      setState(() {
        _currentTutorialStep = tutorialStep;
        _showTutorialOverlay = true;
      });
    }
  }

  /// Dismiss tutorial overlay
  void _dismissTutorial() {
    setState(() {
      _showTutorialOverlay = false;
      _currentTutorialStep = null;
    });
  }

  /// Complete tutorial step
  void _completeTutorial() {
    if (_onboardingService != null && _currentTutorialStep != null) {
      _onboardingService!.completeTutorialStep(_currentTutorialStep!.id);
    }
    _dismissTutorial();
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
              'Enhanced Art Walk',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Interactive map features are optimized for mobile devices.\nUse the navigation controls below to explore art pieces.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // ========== NEW UX IMPROVEMENT METHODS ==========

  /// Build title with progress for app bar
  String _buildTitleWithProgress() {
    if (_currentProgress == null) return widget.artWalk.title;
    final visited = _currentProgress!.visitedArt.length;
    final total = _currentProgress!.totalArtCount;
    return '${widget.artWalk.title} ($visited/$total)';
  }

  /// Handle back button press with confirmation
  Future<bool> _onWillPop() async {
    if (_currentProgress?.status == WalkStatus.inProgress ||
        _currentProgress?.status == WalkStatus.paused) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'art_walk_enhanced_art_walk_experience_text_leave_walk'.tr(),
          ),
          content: const Text(
            'Your progress will be saved and you can resume this walk later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('art_walk_enhanced_art_walk_create_text_stay'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('art_walk_enhanced_art_walk_create_text_leave'.tr()),
            ),
          ],
        ),
      );
      return shouldExit ?? false;
    }
    return true;
  }

  /// Handle menu actions
  Future<void> _handleMenuAction(String action) async {
    await _hapticService?.buttonPressed();

    switch (action) {
      case 'pause':
        await _pauseWalkAction();
        break;
      case 'resume':
        await _resumeWalkAction();
        break;
      case 'complete':
        await _manualCompleteWalk();
        break;
      case 'progress':
        _showProgressDialog();
        break;
      case 'abandon':
        await _abandonWalkAction();
        break;
    }
  }

  /// Pause walk action
  Future<void> _pauseWalkAction() async {
    try {
      final pausedProgress = await _progressService.pauseWalk();
      setState(() {
        _currentProgress = pausedProgress;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_enhanced_art_walk_experience_text_walk_paused_you'.tr(),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_enhanced_art_walk_experience_error_error_pausing_walk'
                  .tr(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Resume walk action
  Future<void> _resumeWalkAction() async {
    try {
      if (_currentProgress == null) return;

      final resumedProgress = await _progressService.resumeWalk(
        _currentProgress!.id,
      );
      setState(() {
        _currentProgress = resumedProgress;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Walk resumed. Let\'s continue!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_enhanced_art_walk_experience_error_error_resuming_walk'
                  .tr(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Manual complete walk (for early completion at 80%+)
  Future<void> _manualCompleteWalk() async {
    if (_currentProgress == null || !_currentProgress!.canComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You need to visit at least 80% of art pieces to complete early.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'art_walk_enhanced_art_walk_experience_text_complete_walk_early'.tr(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve visited ${_currentProgress!.visitedArt.length}/${_currentProgress!.totalArtCount} art pieces.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Completing early means:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• You won\'t get the perfect completion bonus'),
            Text(
              'art_walk_enhanced_art_walk_experience_text_you_can_still'.tr(),
            ),
            const SizedBox(height: 8),
            Text(
              'art_walk_enhanced_art_walk_experience_text_would_you_like'.tr(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'art_walk_enhanced_art_walk_experience_text_keep_exploring'.tr(),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'art_walk_enhanced_art_walk_experience_text_complete_now'.tr(),
            ),
          ),
        ],
      ),
    );

    if (shouldComplete == true) {
      _showWalkCompletionDialog();
    }
  }

  /// Show progress dialog
  void _showProgressDialog() {
    if (_currentProgress == null) return;

    final visited = _currentProgress!.visitedArt.length;
    final total = _currentProgress!.totalArtCount;
    final percentage = (_currentProgress!.progressPercentage * 100)
        .toStringAsFixed(0);
    final timeSpent = _currentProgress!.timeSpent;
    final photosCount = _currentProgress!.visitedArt
        .where((v) => v.photoTaken != null)
        .length;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'art_walk_enhanced_art_walk_experience_text_walk_progress'.tr(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$percentage% Complete',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            _buildProgressRow(
              Icons.location_on,
              'Art Pieces',
              '$visited / $total visited',
            ),
            _buildProgressRow(Icons.camera_alt, 'Photos', '$photosCount taken'),
            _buildProgressRow(
              Icons.timer,
              'Duration',
              _formatDuration(timeSpent),
            ),
            _buildProgressRow(
              Icons.stars,
              'Points',
              '${_currentProgress!.totalPointsEarned} XP earned',
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _currentProgress!.progressPercentage,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 8,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('admin_admin_payment_text_close'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Abandon walk action
  Future<void> _abandonWalkAction() async {
    final shouldAbandon = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'art_walk_enhanced_art_walk_experience_text_abandon_walk_76'.tr(),
        ),
        content: const Text(
          'Are you sure you want to abandon this walk? All progress will be lost and cannot be recovered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('admin_admin_payment_text_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'art_walk_enhanced_art_walk_experience_text_abandon'.tr(),
            ),
          ),
        ],
      ),
    );

    if (shouldAbandon == true) {
      try {
        await _progressService.abandonWalk();

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'art_walk_enhanced_art_walk_experience_error_error_abandoning_walk'
                    .tr(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Calculate completion bonus (mirrors service logic)
  int _calculateCompletionBonus() {
    if (_currentProgress == null) return 0;

    int bonus = 100; // Base completion bonus

    // Perfect completion bonus
    if (_currentProgress!.progressPercentage >= 1.0) {
      bonus += 50;
    }

    // Speed bonus (completed in under 2 hours)
    if (_currentProgress!.timeSpent.inHours < 2) {
      bonus += 25;
    }

    // Photo documentation bonus
    final photosCount = _currentProgress!.visitedArt
        .where((v) => v.photoTaken != null)
        .length;
    if (photosCount >= _currentProgress!.visitedArt.length * 0.5) {
      bonus += 30; // Documented at least 50% with photos
    }

    return bonus;
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
