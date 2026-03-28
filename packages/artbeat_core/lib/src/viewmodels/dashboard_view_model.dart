import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:artbeat_core/artbeat_core.dart';

class DashboardViewModel extends ChangeNotifier {
  final EventReadService _eventService;
  final ArtworkReadService _artworkService;
  final PublicArtReadService _publicArtService;
  final SocialActivityReadService _socialService;
  final SubscriptionService _subscriptionService;
  final ArtistService _artistService;
  final ArtistFollowService _artistFollowService;
  final UserService _userService;
  final UserProgressionService _progressionService;
  final DiscoveryProgressReadService _discoveryProgressService;
  final CaptureServiceInterface _captureService;
  final ContentEngagementService _engagementService;
  final CommunityPostReadService _communityService;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? chapterId;

  UserModel? _currentUser;
  bool _isInitializing = false;
  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _isLoadingEvents = true;
  bool _isLoadingUpcomingEvents = true;
  bool _isLoadingArtwork = true;
  bool _isLoadingBooks = true;
  bool _isLoadingArtists = true;
  bool _isLoadingLocation = true;
  bool _isMapPreviewReady = false;
  final bool _isLoadingMap = false;
  bool _isLoadingAchievements = true;
  bool _isLoadingLocalCaptures = true;
  bool _isLoadingPosts = true;
  bool _isLoadingUserProgress = true;
  bool _isLoadingActivities = true;

  String? _eventsError;
  String? _upcomingEventsError;
  String? _artworkError;
  String? _booksError;
  String? _achievementsError;
  String? _artistsError;
  String? _locationError;
  String? _localCapturesError;
  String? _postsError;

  List<EventModel> _events = [];
  final List<EventModel> _upcomingEvents = [];
  List<ArtworkModel> _artwork = [];
  List<ArtworkModel> _books = [];
  List<ArtistProfileModel> _artists = [];
  Set<Marker> _markers = {};
  Position? _currentLocation;
  LatLng? _mapLocation;
  List<AchievementModel> _achievements = [];
  List<CaptureModel> _localCaptures = [];
  List<CommunityPostModel> _posts = [];
  List<SocialActivityModel> _activities = [];
  DailyChallengeModel? _todaysChallenge;
  final Map<String, Set<Marker>> _markerCache = {};
  LatLng? _lastMarkerLocation;
  LatLng? _pendingMarkerLocation;
  Timer? _markerRefreshTimer;
  DateTime? _lastMarkerLoadedAt;
  static const Duration _markerThrottleDuration = Duration(milliseconds: 700);

  // User progress stats
  int _totalDiscoveries = 0;
  int _currentStreak = 0;
  int _weeklyProgress = 0;
  int _loginStreak = 0;

  DashboardViewModel({
    EventReadService? eventService,
    ArtworkReadService? artworkService,
    PublicArtReadService? publicArtService,
    SocialActivityReadService? socialService,
    required SubscriptionService subscriptionService,
    ArtistService? artistService,
    ArtistFollowService? artistFollowService,
    UserProgressionService? progressionService,
    DiscoveryProgressReadService? discoveryProgressService,
    required UserService userService,
    CaptureServiceInterface? captureService,
    ContentEngagementService? engagementService,
    CommunityPostReadService? communityService,
    this.chapterId,
  }) : _eventService = eventService ?? EventReadService(),
       _artworkService = artworkService ?? ArtworkReadService(),
       _publicArtService = publicArtService ?? PublicArtReadService(),
       _socialService = socialService ?? SocialActivityReadService(),
       _subscriptionService = subscriptionService,
       _artistService = artistService ?? ArtistService(),
       _artistFollowService = artistFollowService ?? ArtistFollowService(),
       _progressionService = progressionService ?? UserProgressionService(),
       _discoveryProgressService =
           discoveryProgressService ?? DiscoveryProgressReadService(),
       _userService = userService,
       _captureService = captureService ?? DefaultCaptureService(),
       _engagementService = engagementService ?? ContentEngagementService(),
       _communityService = communityService ?? CommunityPostReadService();

  /// Initializes dashboard data and state
  Future<void> initialize() async {
    debugPrint(
      '🔍 DashboardViewModel: initialize() called, _isInitializing=$_isInitializing, _isInitialized=$_isInitialized',
    );
    if (_isInitializing || _isInitialized) {
      debugPrint(
        '🔍 DashboardViewModel: Already initialized or initializing, skipping...',
      );
      return; // Prevent multiple initializations
    }
    _isInitializing = true;

    try {
      debugPrint('🔍 DashboardViewModel: Starting initialization...');
      _resetLoadingStates(notify: false);
      // First load current user since other operations depend on it
      await _loadCurrentUser();
      AppLogger.info('👤 Current user loaded: ${_currentUser?.id}');

      // Start critical data loading
      await Future.wait<void>([
        _loadLocation(notify: false),
        _loadUserProgress(notify: false),
      ]);

      // Mark as initialized early so UI can show basic info
      _isInitialized = true;
      _isInitializing = false;
      _safeNotifyListeners();
      debugPrint('🔍 DashboardViewModel: Initialized with critical data');

      // Then load all other data in background
      unawaited(
        Future.wait<void>([
          _loadEvents(notify: true),
          _loadArtwork(notify: true),
          _loadBooks(notify: true),
          _loadArtists(notify: true),
          _loadAchievements(notify: true),
          _loadLocalCaptures(notify: true),
          _loadPosts(notify: true),
          _loadTodaysChallenge(notify: true),
          _loadActivities(notify: true),
        ]),
      );

      debugPrint('🔍 DashboardViewModel: ✅ Background data loading started');
    } catch (e, stack) {
      debugPrint('🔍 DashboardViewModel: ❌ Initialization error: $e');
      AppLogger.error('❌ Error initializing dashboard: $e');
      AppLogger.error('❌ Stack trace: $stack');
    } finally {
      _isInitializing = false;
      _safeNotifyListeners();
      debugPrint('🔍 DashboardViewModel: _isInitializing set to false');
    }
  }

  void _resetLoadingStates({bool notify = true}) {
    _isLoadingEvents = true;
    _isLoadingUpcomingEvents = true;
    _isLoadingArtwork = true;
    _isLoadingBooks = true;
    _isLoadingArtists = true;
    _isLoadingLocation = true;
    _isLoadingAchievements = true;
    _isLoadingLocalCaptures = true;
    _isLoadingPosts = true;
    _isLoadingActivities = true;
    _isLoadingUserProgress = true;
    if (notify) _safeNotifyListeners();
  }

  /// Safely notify listeners, catching disposal errors
  void _safeNotifyListeners() {
    if (_isDisposed) {
      debugPrint('⚠️ Attempted to notify listeners on disposed ViewModel');
      return;
    }
    try {
      notifyListeners();
    } catch (e) {
      // Ignore errors if widget is disposed
      AppLogger.warning(
        '⚠️ Attempted to notify listeners on disposed ViewModel',
      );
    }
  }

  Future<void> _loadCurrentUser() async {
    if (_auth.currentUser == null) {
      _currentUser = null;
      return;
    }

    try {
      _currentUser = await _userService.getCurrentUserModel();
    } catch (e) {
      AppLogger.error('Error loading current user: $e');
      _currentUser = null;
    }
  }

  /// Refreshes the current user data from the server
  Future<void> refreshUserData() async {
    await _loadCurrentUser();
    _safeNotifyListeners();
  }

  // Getters
  bool get isInitializing => _isInitializing;
  bool get isLoadingEvents => _isLoadingEvents;
  bool get isLoadingUpcomingEvents => _isLoadingUpcomingEvents;
  bool get isLoadingArtwork => _isLoadingArtwork;
  bool get isLoadingBooks => _isLoadingBooks;
  bool get isLoadingArtists => _isLoadingArtists;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get isMapPreviewReady => _isMapPreviewReady;
  bool get isLoadingMap => _isLoadingMap;
  bool get isLoadingLocalCaptures => _isLoadingLocalCaptures;
  bool get isLoadingAchievements => _isLoadingAchievements;
  bool get isLoadingPosts => _isLoadingPosts;
  bool get isAuthenticated => _auth.currentUser != null;
  String? get eventsError => _eventsError;
  String? get upcomingEventsError => _upcomingEventsError;
  String? get artworkError => _artworkError;
  String? get booksError => _booksError;
  String? get achievementsError => _achievementsError;
  String? get artistsError => _artistsError;
  String? get locationError => _locationError;
  String? get localCapturesError => _localCapturesError;
  String? get postsError => _postsError;

  /// Update active chapter and reload data
  void updateChapter(String? newChapterId) {
    if (chapterId == newChapterId) return;

    chapterId = newChapterId;

    // If already initialized, trigger a refresh
    if (_isInitialized) {
      refresh();
    }
  }

  List<EventModel> get events => _isDisposed ? [] : List.unmodifiable(_events);
  List<EventModel> get upcomingEvents => List.unmodifiable(_upcomingEvents);
  List<ArtworkModel> get artwork =>
      _isDisposed ? [] : List.unmodifiable(_artwork);
  List<ArtworkModel> get books => _isDisposed ? [] : List.unmodifiable(_books);
  List<ArtistProfileModel> get artists =>
      _isDisposed ? [] : List.unmodifiable(_artists);
  Set<Marker> get markers => Set.unmodifiable(_markers);
  Position? get currentLocation => _currentLocation;
  List<AchievementModel> get achievements => List.unmodifiable(_achievements);
  List<CaptureModel> get localCaptures => List.unmodifiable(_localCaptures);
  List<CommunityPostModel> get posts => List.unmodifiable(_posts);
  List<SocialActivityModel> get activities => List.unmodifiable(_activities);
  LatLng? get mapLocation => _mapLocation;
  UserModel? get currentUser => _isDisposed ? null : _currentUser;
  DailyChallengeModel? get todaysChallenge => _todaysChallenge;

  // User progress getters
  int get totalDiscoveries => _totalDiscoveries;
  int get currentStreak => _currentStreak;
  int get weeklyProgress => _weeklyProgress;
  int get loginStreak => _loginStreak;
  bool get isLoadingUserProgress => _isLoadingUserProgress;
  bool get isLoadingActivities => _isLoadingActivities;
  bool get isDisposed => _isDisposed;

  // Methods
  /// Reload just the activities feed
  Future<void> reloadActivities() async {
    debugPrint('🔍 DashboardViewModel: reloadActivities() called');
    await _loadActivities();
  }

  Future<void> refresh() async {
    if (_isInitializing) {
      // If still initializing, wait for it to complete
      return;
    }

    try {
      _resetLoadingStates(notify: false);
      await _loadCurrentUser();

      final locationLoad = _loadLocation(notify: true);

      await Future.wait<void>([
        locationLoad,
        _loadEvents(notify: true),
        _loadArtwork(notify: true),
        _loadBooks(notify: true),
        _loadArtists(notify: true),
        _loadAchievements(notify: true),
        _loadLocalCaptures(notify: true),
        _loadPosts(notify: true),
        _loadUserProgress(notify: true),
        // Activities depend on location for "nearby" features
        (() async {
          await locationLoad;
          await _loadActivities(notify: true);
        })(),
      ]);
    } catch (e, stack) {
      AppLogger.error('❌ Error refreshing dashboard: $e');
      AppLogger.error('❌ Stack trace: $stack');
    } finally {
      _safeNotifyListeners();
    }
  }

  Future<void> _loadAchievements({bool notify = true}) async {
    try {
      if (_currentUser == null) {
        _achievements = [];
        _achievementsError = null;
        return;
      }

      _achievements = await _userService.getUserAchievements(_currentUser!.id);
      _achievementsError = null;
    } catch (e) {
      AppLogger.error('Error loading achievements: $e');
      _achievementsError = e.toString();
      _achievements = [];
    } finally {
      _isLoadingAchievements = false;
      if (notify) _safeNotifyListeners();
    }
  }

  Future<void> _loadEvents({bool notify = true}) async {
    try {
      _isLoadingEvents = true;
      if (notify) _safeNotifyListeners();

      final events = await _eventService.getUpcomingPublicEvents(
        chapterId: chapterId,
      );
      _events = events;
      _eventsError = null;
    } catch (e) {
      AppLogger.error('Error loading events: $e');
      _eventsError = e.toString();
      _events = [];
    } finally {
      _isLoadingEvents = false;
      if (notify) _safeNotifyListeners();
    }
  }

  Future<void> _loadArtwork({bool notify = true}) async {
    try {
      _isLoadingArtwork = true;
      if (notify) _safeNotifyListeners();

      // Try featured artwork first, fallback to public artwork
      var artworkServiceModels = await _artworkService.getFeaturedArtwork(
        chapterId: chapterId,
      );
      if (artworkServiceModels.isEmpty) {
        AppLogger.info('No featured artwork found, loading public artwork...');
        artworkServiceModels = await _artworkService.getAllPublicArtwork(
          limit: 10,
          chapterId: chapterId,
        );
      }

      _artwork = artworkServiceModels;

      _artworkError = null;
      AppLogger.info('✅ Loaded ${_artwork.length} artworks successfully');
    } catch (e) {
      AppLogger.error('Error loading artwork: $e');
      _artworkError = e.toString();
      _artwork = [];
    } finally {
      _isLoadingArtwork = false;
      if (notify) _safeNotifyListeners();
    }
  }

  Future<void> _loadBooks({bool notify = true}) async {
    try {
      _isLoadingBooks = true;
      if (notify) _safeNotifyListeners();

      final booksServiceModels = await _artworkService.getWrittenContent(
        limit: 10,
        includeSerialized: true,
        includeCompleted: true,
      );

      _books = booksServiceModels;

      _booksError = null;
      AppLogger.info('✅ Loaded ${_books.length} books successfully');
    } catch (e) {
      AppLogger.error('Error loading books: $e');
      _booksError = e.toString();
      _books = [];
    } finally {
      _isLoadingBooks = false;
      if (notify) _safeNotifyListeners();
    }
  }

  Future<void> _loadArtists({bool notify = true}) async {
    try {
      _isLoadingArtists = true;
      if (notify) _safeNotifyListeners();

      final featuredArtists = await _artistService.getFeaturedArtistProfiles();
      if (featuredArtists.isNotEmpty) {
        _artists = featuredArtists;
      } else {
        final allArtists = await _artistService.getAllArtistProfiles(limit: 20);
        _artists = allArtists;
      }
      _artistsError = null;
    } catch (e) {
      AppLogger.error('Error loading artists: $e');
      _artistsError = e.toString();
      _artists = [];
    } finally {
      _isLoadingArtists = false;
      if (notify) _safeNotifyListeners();
    }
  }

  Future<void> _loadLocalCaptures({bool notify = true}) async {
    try {
      _isLoadingLocalCaptures = true;
      if (notify) _safeNotifyListeners();

      // Get all captures
      final allCaptures = await _captureService.getAllCaptures();

      // Show all captures regardless of location (removed 15-mile restriction)
      _localCaptures = allCaptures;

      _localCapturesError = null;
    } catch (e) {
      AppLogger.error('Error loading local captures: $e');
      _localCapturesError = e.toString();
      _localCaptures = [];
    } finally {
      _isLoadingLocalCaptures = false;
      if (notify) _safeNotifyListeners();
    }
  }

  Future<void> _loadPosts({bool notify = true}) async {
    try {
      _isLoadingPosts = true;
      if (notify) _safeNotifyListeners();

      // Load recent posts from community service
      final posts = await _communityService.getFeed(limit: 10);

      _posts = posts;
      _postsError = null;
      AppLogger.info('✅ Loaded ${_posts.length} posts successfully');
    } catch (e) {
      AppLogger.error('Error loading posts: $e');
      _postsError = e.toString();
      _posts = [];
    } finally {
      _isLoadingPosts = false;
      if (notify) _safeNotifyListeners();
    }
  }

  Future<void> _loadActivities({bool notify = true}) async {
    try {
      _isLoadingActivities = true;
      if (notify) _safeNotifyListeners();

      debugPrint('🔍 DashboardViewModel: Starting to load activities');

      // Load recent social activities from all users
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('🔍 DashboardViewModel: ❌ No user logged in');
        _activities = [];
        AppLogger.info('No user logged in, no activities to load');
        return;
      }

      debugPrint('🔍 DashboardViewModel: User logged in: ${user.uid}');

      final allActivities = <SocialActivityModel>[];

      // Try to load nearby activities if location is available
      if (_currentLocation != null) {
        debugPrint('🔍 DashboardViewModel: Loading nearby activities');
        try {
          final nearbyActivities = await _socialService.getNearbyActivities(
            userPosition: _currentLocation!,
            radiusKm: 50.0, // 50km radius for broader coverage
            limit: 20,
          );
          debugPrint(
            '🔍 DashboardViewModel: Loaded ${nearbyActivities.length} nearby activities',
          );
          allActivities.addAll(nearbyActivities);
        } catch (e) {
          debugPrint(
            '🔍 DashboardViewModel: ⚠️ Error loading nearby activities: $e',
          );
        }
      } else {
        debugPrint(
          '🔍 DashboardViewModel: ⚠️ Location not available, skipping nearby activities',
        );
      }

      // If no nearby activities found, load recent activities from all users
      // by querying the socialActivities collection directly
      if (allActivities.isEmpty) {
        debugPrint(
          '🔍 DashboardViewModel: No nearby activities, loading recent activities from all users',
        );
        try {
          // Load recent activities without location filter
          final recentActivities = await _socialService.getRecentActivities(
            limit: 20,
          );
          debugPrint(
            '🔍 DashboardViewModel: Loaded ${recentActivities.length} recent activities',
          );
          allActivities.addAll(recentActivities);
        } catch (e) {
          debugPrint(
            '🔍 DashboardViewModel: ⚠️ Error loading recent activities: $e',
          );
        }
      }

      // Sort by timestamp (most recent first)
      allActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Take top 20 activities
      _activities = allActivities.take(20).toList();

      debugPrint(
        '🔍 DashboardViewModel: Final activities count: ${_activities.length}',
      );

      AppLogger.info('✅ Loaded ${_activities.length} activities successfully');
    } catch (e, stack) {
      debugPrint('🔍 DashboardViewModel: ❌ Error loading activities: $e');
      debugPrint('🔍 DashboardViewModel: Stack trace: $stack');
      AppLogger.error('Error loading activities: $e');
      _activities = [];
    } finally {
      _isLoadingActivities = false;
      if (notify) _safeNotifyListeners();
      debugPrint(
        '🔍 DashboardViewModel: Finished loading activities, total: ${_activities.length}',
      );
    }
  }

  Future<void> _loadLocation({bool notify = true}) async {
    try {
      _isLoadingLocation = true;
      if (notify) _safeNotifyListeners();

      final lastKnown = await LocationUtils.getLastKnownPositionSafe();
      if (lastKnown != null) {
        _currentLocation = lastKnown;
        _mapLocation = LatLng(lastKnown.latitude, lastKnown.longitude);
        _safeNotifyListeners();
        unawaited(_loadNearbyArtMarkers());
      }

      // Use shorter timeout for better UX - if location takes too long, fallback faster
      final position =
          await LocationUtils.getCurrentPosition(
            timeoutDuration: const Duration(seconds: 8), // Reduced timeout
          ).timeout(
            const Duration(seconds: 10), // Overall timeout reduced
            onTimeout: () {
              AppLogger.warning(
                '⚠️ Location request timed out after 10 seconds',
              );
              throw TimeoutException(
                'Location request timed out',
                const Duration(seconds: 10),
              );
            },
          );

      _currentLocation = position;
      _mapLocation = LatLng(position.latitude, position.longitude);

      await _loadNearbyArtMarkers();
      _locationError = null;
      debugPrint(
        '✅ Location loaded successfully: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      AppLogger.error('❌ Error loading location: $e');
      _locationError = e.toString();

      // Set default location to Raleigh, NC if location fails
      _mapLocation = const LatLng(35.7796, -78.6382);
      AppLogger.info('🌍 Using default location: Raleigh, NC');

      // Still try to load markers for default location
      try {
        await _loadNearbyArtMarkers();
      } catch (markerError) {
        debugPrint(
          '❌ Error loading markers for default location: $markerError',
        );
      }
    } finally {
      _isLoadingLocation = false;
      if (notify) _safeNotifyListeners();
    }
  }

  Future<void> _loadNearbyArtMarkers({bool force = false}) async {
    if (_mapLocation == null) return;

    final location = _mapLocation!;
    final now = DateTime.now();
    if (!force &&
        _lastMarkerLoadedAt != null &&
        now.difference(_lastMarkerLoadedAt!) < _markerThrottleDuration &&
        _lastMarkerLocation != null &&
        _isLocationClose(location, _lastMarkerLocation!)) {
      _pendingMarkerLocation = location;
      _scheduleMarkerRefresh();
      return;
    }

    try {
      final cacheKey =
          '${location.latitude.toStringAsFixed(2)}_${location.longitude.toStringAsFixed(2)}';
      if (_markerCache.containsKey(cacheKey)) {
        _markers = _markerCache[cacheKey]!;
        _isMapPreviewReady = true;
        _safeNotifyListeners();
        return;
      }

      final newMarkers = <Marker>{};

      // Add current location marker if we have it
      newMarkers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _mapLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Current Location'),
        ),
      );

      // Get nearby art pieces from ArtWalk service
      final List<PublicArtModel> nearbyArt = await _publicArtService
          .getPublicArtNearLocation(
            latitude: location.latitude,
            longitude: location.longitude,
            radiusKm: 10, // 10km radius
          );
      final List<PublicArtModel> limitedNearbyArt = nearbyArt
          .take(300)
          .toList();

      // Cluster markers to reduce load when many nearby items exist
      final Map<String, List<PublicArtModel>> clusters = {};
      const double clusterSize = 0.01; // ~1km grid

      for (final art in limitedNearbyArt) {
        final lat = art.location.latitude;
        final lng = art.location.longitude;
        final key =
            '${(lat / clusterSize).floor()}_${(lng / clusterSize).floor()}';
        clusters.putIfAbsent(key, () => []).add(art);
      }

      for (final entry in clusters.entries) {
        final List<PublicArtModel> items = entry.value;
        final PublicArtModel first = items.first;
        final position = LatLng(
          first.location.latitude,
          first.location.longitude,
        );

        if (items.length == 1) {
          newMarkers.add(
            Marker(
              markerId: MarkerId('art_${first.id}'),
              position: position,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet,
              ),
              infoWindow: InfoWindow(
                title: first.title,
                snippet: first.artistName,
              ),
            ),
          );
        } else {
          newMarkers.add(
            Marker(
              markerId: MarkerId('cluster_${entry.key}'),
              position: position,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRose,
              ),
              infoWindow: InfoWindow(
                title: '${items.length} nearby artworks',
                snippet: 'Zoom in to see individual pieces',
              ),
            ),
          );
        }
      }

      _markers = newMarkers;
      _markerCache[cacheKey] = newMarkers;
      _isMapPreviewReady = true;
      _lastMarkerLocation = location;
      _lastMarkerLoadedAt = DateTime.now();
      _safeNotifyListeners();
    } catch (e) {
      AppLogger.error('Error loading nearby art markers: $e');
      _isMapPreviewReady = false;
      _safeNotifyListeners();
    }
  }

  bool _isLocationClose(LatLng a, LatLng b, {double thresholdMeters = 250}) {
    final distance = Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
    return distance < thresholdMeters;
  }

  void _scheduleMarkerRefresh() {
    if (_markerRefreshTimer?.isActive ?? false) return;
    _markerRefreshTimer = Timer(_markerThrottleDuration, () {
      _markerRefreshTimer = null;
      if (_pendingMarkerLocation != null) {
        _mapLocation = _pendingMarkerLocation;
        _pendingMarkerLocation = null;
      }
      unawaited(_loadNearbyArtMarkers(force: true));
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _markerRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTodaysChallenge({bool notify = true}) async {
    try {
      debugPrint('🎯 DashboardViewModel: Loading today\'s challenge');
      // Temporarily disable service call for testing
      // _todaysChallenge = await _challengeService.getTodaysChallenge();

      // Use a test challenge instead
      _todaysChallenge = DailyChallengeModel(
        id: 'test_daily_challenge',
        userId: 'test_user',
        title: 'Art Hunter',
        description: 'Discover 3 pieces of public art in your neighborhood',
        type: DailyChallengeType.daily,
        targetCount: 3,
        currentCount: 1,
        rewardXP: 150,
        rewardDescription: '🏆 Explorer Badge + 150 XP',
        isCompleted: false,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 18)),
      );

      debugPrint(
        '🎯 DashboardViewModel: Loaded challenge: ${_todaysChallenge?.title ?? "None"}',
      );
      AppLogger.info(
        'Loaded today\'s challenge: ${_todaysChallenge?.title ?? "None"}',
      );
    } catch (e) {
      debugPrint('🎯 DashboardViewModel: ❌ Error loading challenge: $e');
      AppLogger.error('Error loading today\'s challenge: $e');
      _todaysChallenge = null;
    } finally {
      if (notify) _safeNotifyListeners();
    }
  }

  // Intentionally removed duplicate methods that were declared again below

  Future<void> _loadUserProgress({bool notify = true}) async {
    try {
      if (_currentUser == null) {
        _totalDiscoveries = 0;
        _currentStreak = 0;
        _weeklyProgress = 0;
        _loginStreak = 0;
        _isLoadingUserProgress = false;
        return;
      }

      final userId = _currentUser?.id;
      int loginStreak = 0;
      if (userId != null) {
        try {
          final loginResult = await _progressionService.processDailyLogin(
            userId,
          );
          loginStreak = (loginResult['streak'] as int?) ?? 0;

          // If a new login was processed today, refresh the user model to get updated XP/Level
          if (loginResult['alreadyLoggedIn'] == false) {
            AppLogger.info('✨ Daily login processed, refreshing user data...');
            await _loadCurrentUser();
          }
        } catch (e) {
          AppLogger.error('❌ Error getting login streak: $e');
        }
      }
      _loginStreak = loginStreak;

      // Optionally, still get discovery stats for other dashboard data
      final stats = await _discoveryProgressService.getUserProgressStats();

      _totalDiscoveries = stats['totalDiscoveries'] ?? 0;
      _currentStreak = stats['currentStreak'] ?? 0;
      _weeklyProgress = stats['weeklyProgress'] ?? 0;

      AppLogger.info(
        '✅ User progress loaded: $_totalDiscoveries discoveries, $_currentStreak streak, $_weeklyProgress this week, loginStreak: $_loginStreak',
      );
    } catch (e) {
      AppLogger.error('❌ Error loading user progress: $e');
      _totalDiscoveries = 0;
      _currentStreak = 0;
      _weeklyProgress = 0;
      _loginStreak = 0;
    } finally {
      _isLoadingUserProgress = false;
      if (notify) _safeNotifyListeners();
    }
  }

  Future<void> followArtist({required String artistId}) async {
    if (!isAuthenticated) {
      throw Exception('User must be logged in to follow artists');
    }

    try {
      // Optimistic update
      _artists = _artists
          .map((a) => a.id == artistId ? a.copyWith(isFollowing: true) : a)
          .toList();
      _safeNotifyListeners();

      final subscription = await _subscriptionService.getUserSubscription();
      if (subscription != null) {
        final success = await _artistFollowService.followArtist(artistId);
        if (!success) {
          throw Exception('Failed to follow artist');
        }
        AppLogger.info('Artist follow requested: $artistId');
      }
    } catch (e) {
      // Revert on error
      _artists = _artists
          .map((a) => a.id == artistId ? a.copyWith(isFollowing: false) : a)
          .toList();
      _safeNotifyListeners();
      rethrow;
    }
  }

  Future<void> unfollowArtist({required String artistId}) async {
    if (!isAuthenticated) {
      throw Exception('User must be logged in to unfollow artists');
    }

    try {
      // Optimistic update
      _artists = _artists
          .map((a) => a.id == artistId ? a.copyWith(isFollowing: false) : a)
          .toList();
      _safeNotifyListeners();

      final subscription = await _subscriptionService.getUserSubscription();
      if (subscription != null) {
        final success = await _artistFollowService.unfollowArtist(artistId);
        if (!success) {
          throw Exception('Failed to unfollow artist');
        }
        AppLogger.info('Artist unfollow requested: $artistId');
      }
    } catch (e) {
      // Revert on error
      _artists = _artists
          .map((a) => a.id == artistId ? a.copyWith(isFollowing: true) : a)
          .toList();
      _safeNotifyListeners();
      rethrow;
    }
  }

  /// Updates an artist in the artists list
  void updateArtist(ArtistProfileModel updatedArtist) {
    final index = _artists.indexWhere((a) => a.userId == updatedArtist.userId);
    if (index != -1) {
      _artists[index] = updatedArtist;
      _safeNotifyListeners();
    }
  }

  /// Handles when the Google Map is created - currently not used
  void onMapCreated(GoogleMapController controller) {
    // Map controller initialization
    _safeNotifyListeners();
  }

  /// Toggle like for a capture
  Future<bool> toggleCaptureLike(String captureId) async {
    if (!isAuthenticated) {
      throw Exception('User must be logged in to like captures');
    }

    try {
      final isLiked = await _engagementService.toggleEngagement(
        contentId: captureId,
        contentType: 'capture',
        engagementType: EngagementType.like,
      );

      // Update local captures list to reflect the change
      _localCaptures = _localCaptures.map((capture) {
        if (capture.id == captureId) {
          // Note: CaptureModel doesn't have a likes count field
          // We'll handle the liked state separately in the UI
          return capture;
        }
        return capture;
      }).toList();

      _safeNotifyListeners();
      return isLiked;
    } catch (e) {
      AppLogger.error('Error toggling capture like: $e');
      rethrow;
    }
  }

  /// Check if current user has liked a capture
  Future<bool> hasUserLikedCapture(String captureId) async {
    if (!isAuthenticated) return false;

    try {
      return await _engagementService.hasUserEngaged(
        contentId: captureId,
        engagementType: EngagementType.like,
      );
    } catch (e) {
      AppLogger.error('Error checking capture like status: $e');
      return false;
    }
  }
}
