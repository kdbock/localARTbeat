import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:artbeat_core/artbeat_core.dart';

class DashboardViewModel extends ChangeNotifier {
  final SocialActivityReadService _socialService;
  final ArtistFollowService _artistFollowService;
  final UserService _userService;
  final UserProgressionService _progressionService;
  final DiscoveryProgressReadService _discoveryProgressService;
  final ContentEngagementService _engagementService;
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
  final bool _isMapPreviewReady = false;
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

  final List<EventModel> _events = [];
  final List<EventModel> _upcomingEvents = [];
  final List<ArtworkModel> _artwork = [];
  final List<ArtworkModel> _books = [];
  List<ArtistProfileModel> _artists = [];
  final Set<Marker> _markers = {};
  Position? _currentLocation;
  LatLng? _mapLocation;
  final List<AchievementModel> _achievements = [];
  List<CaptureModel> _localCaptures = [];
  final List<CommunityPostModel> _posts = [];
  List<SocialActivityModel> _activities = [];
  DailyChallengeModel? _todaysChallenge;

  // User progress stats
  int _totalDiscoveries = 0;
  int _currentStreak = 0;
  int _weeklyProgress = 0;
  int _loginStreak = 0;

  DashboardViewModel({
    SocialActivityReadService? socialService,
    ArtistFollowService? artistFollowService,
    UserProgressionService? progressionService,
    DiscoveryProgressReadService? discoveryProgressService,
    required UserService userService,
    ContentEngagementService? engagementService,
    this.chapterId,
  }) : _socialService = socialService ?? SocialActivityReadService(),
       _artistFollowService = artistFollowService ?? ArtistFollowService(),
       _progressionService = progressionService ?? UserProgressionService(),
       _discoveryProgressService =
           discoveryProgressService ?? DiscoveryProgressReadService(),
       _userService = userService,
       _engagementService = engagementService ?? ContentEngagementService();

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

      await _loadUserProgress(notify: false);
      _markPausedDashboardSectionsLoaded();

      // Mark as initialized early so UI can show basic info
      _isInitialized = true;
      _isInitializing = false;
      _safeNotifyListeners();
      debugPrint('🔍 DashboardViewModel: Initialized with critical data');

      debugPrint('🔍 DashboardViewModel: ✅ Revamp dashboard data loaded');
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

  void _markPausedDashboardSectionsLoaded() {
    _isLoadingEvents = false;
    _isLoadingUpcomingEvents = false;
    _isLoadingArtwork = false;
    _isLoadingBooks = false;
    _isLoadingArtists = false;
    _isLoadingLocation = false;
    _isLoadingAchievements = false;
    _isLoadingLocalCaptures = false;
    _isLoadingPosts = false;
    _isLoadingActivities = false;
  }

  /// Safely notify listeners, catching disposal errors
  void _safeNotifyListeners() {
    if (_isDisposed) {
      return;
    }
    try {
      notifyListeners();
    } catch (e) {
      if (_isDisposed) {
        return;
      }
      AppLogger.warning('Error notifying dashboard listeners: $e');
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
      await _loadUserProgress(notify: true);
      _markPausedDashboardSectionsLoaded();
    } catch (e, stack) {
      AppLogger.error('❌ Error refreshing dashboard: $e');
      AppLogger.error('❌ Stack trace: $stack');
    } finally {
      _safeNotifyListeners();
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

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
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

      final success = await _artistFollowService.followArtist(artistId);
      if (!success) {
        throw Exception('Failed to follow artist');
      }
      AppLogger.info('Artist follow requested: $artistId');
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

      final success = await _artistFollowService.unfollowArtist(artistId);
      if (!success) {
        throw Exception('Failed to unfollow artist');
      }
      AppLogger.info('Artist unfollow requested: $artistId');
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
