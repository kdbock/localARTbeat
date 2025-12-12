import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show CaptureModel, CaptureServiceInterface, UserService, AppLogger;

// Import ArtWalkService for achievement checking
import 'package:artbeat_art_walk/artbeat_art_walk.dart' as art_walk;

// Import offline services
import 'offline_queue_service.dart';

/// Service for managing art captures in the ARTbeat app.
class CaptureService implements CaptureServiceInterface {
  static final CaptureService _instance = CaptureService._internal();

  final Connectivity _connectivity = Connectivity();
  final UserService _userService = UserService();
  final art_walk.RewardsService _rewardsService = art_walk.RewardsService();

  // Cache for getAllCaptures
  List<CaptureModel>? _cachedAllCaptures;
  DateTime? _allCapturesCacheTime;
  static const Duration _cacheTimeout = Duration(minutes: 5);
  bool _isLoadingAllCaptures = false;

  factory CaptureService() {
    return _instance;
  }

  CaptureService._internal();

  /// Lazy Firebase Firestore instance
  FirebaseFirestore get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      AppLogger.firebase('Firebase not initialized yet: $e');
      rethrow;
    }
  }

  /// Collection reference for captures
  CollectionReference get _capturesRef => _firestore.collection('captures');

  /// Collection reference for public art
  CollectionReference get _publicArtRef => _firestore.collection('publicArt');

  /// Clear the cached captures
  void clearCapturesCache() {
    _cachedAllCaptures = null;
    _allCapturesCacheTime = null;
    AppLogger.info('🧹 Captures cache cleared');
  }

  /// Get all captures for a specific user
  Future<List<CaptureModel>> getCapturesForUser(String? userId) async {
    if (userId == null) return [];

    try {
      final querySnapshot = await _capturesRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => CaptureModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching captures: $e');
      return [];
    }
  }

  /// Force fetch all captures, bypassing cache entirely
  Future<List<CaptureModel>> getAllCapturesFresh({int limit = 500}) async {
    try {
      debugPrint(
        '🚀 CaptureService.getAllCapturesFresh() fetching fresh from Firestore with limit: $limit',
      );

      // Try with orderBy first
      try {
        final querySnapshot = await _capturesRef
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();

        final captures = <CaptureModel>[];
        for (final doc in querySnapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null && data.isNotEmpty) {
              final capture = CaptureModel.fromJson({...data, 'id': doc.id});
              captures.add(capture);
            }
          } catch (e) {
            AppLogger.error('❌ Error parsing capture ${doc.id}: $e');
          }
        }

        debugPrint(
          '✅ CaptureService.getAllCapturesFresh() found ${captures.length} captures',
        );
        return captures;
      } catch (orderByError) {
        AppLogger.info('🔄 OrderBy query failed, trying without orderBy...');

        final fallbackQuery = await _capturesRef.limit(limit).get();

        final captures = <CaptureModel>[];
        for (final doc in fallbackQuery.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null && data.isNotEmpty) {
              final capture = CaptureModel.fromJson({...data, 'id': doc.id});
              captures.add(capture);
            }
          } catch (e) {
            AppLogger.error('❌ Error parsing capture ${doc.id}: $e');
          }
        }

        captures.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        debugPrint(
          '✅ CaptureService.getAllCapturesFresh() fallback found ${captures.length} captures',
        );
        return captures;
      }
    } catch (e) {
      AppLogger.error('❌ Error in getAllCapturesFresh: $e');
      return [];
    }
  }

  /// Save a new capture (with offline support)
  Future<String?> saveCaptureWithOfflineSupport({
    required CaptureModel capture,
    required String localImagePath,
  }) async {
    try {
      // Check internet connectivity
      final connectivityResults = await _connectivity.checkConnectivity();
      final isConnected = connectivityResults.any(
        (result) => result != ConnectivityResult.none,
      );

      if (isConnected) {
        // Online: save directly to Firestore
        return await saveCapture(capture);
      } else {
        // Offline: add to queue for later sync
        final offlineQueueService = OfflineQueueService();
        final localCaptureId = await offlineQueueService.addCaptureToQueue(
          captureData: capture,
          localImagePath: localImagePath,
        );

        AppLogger.info('Capture added to offline queue: $localCaptureId');
        return localCaptureId; // Return the local ID for immediate UI updates
      }
    } catch (e) {
      AppLogger.error('Error saving capture with offline support: $e');
      return null;
    }
  }

  /// Save a new capture
  Future<String?> saveCapture(CaptureModel capture) async {
    try {
      // Create geo field for GeoFlutterFire geospatial queries
      final Map<String, dynamic> geoData = {};
      if (capture.location != null) {
        final geoPoint = capture.location!;
        geoData['geo'] = {
          'geohash': _generateGeohash(geoPoint.latitude, geoPoint.longitude),
          'geopoint': geoPoint,
        };
      }

      // Save to captures collection (for user's personal collection)
      final docRef = await _capturesRef.add({
        'userId': capture.userId,
        'title': capture.title,
        'textAnnotations': capture.textAnnotations,
        'imageUrl': capture.imageUrl,
        'thumbnailUrl': capture.thumbnailUrl,
        'createdAt': capture.createdAt,
        'updatedAt': capture.updatedAt,
        'location': capture.location,
        'locationName': capture.locationName,
        'description': capture.description,
        'isProcessed': capture.isProcessed,
        'tags': capture.tags,
        'artistId': capture.artistId,
        'artistName': capture.artistName,
        'isPublic': capture.isPublic,
        'artType': capture.artType,
        'artMedium': capture.artMedium,
        'status': capture.status.name,
        ...geoData, // Add geo field for geospatial queries
      });

      // Update user's capture count
      await _userService.incrementUserCaptureCount(capture.userId);

      // If capture is public and processed, also save to publicArt collection
      if (capture.isPublic && capture.isProcessed) {
        await _saveToPublicArt(capture.copyWith(id: docRef.id));
      }

      return docRef.id;
    } catch (e) {
      AppLogger.error('Error saving capture: $e');
      return null;
    }
  }

  /// Save capture to publicArt collection for art walks
  Future<void> _saveToPublicArt(CaptureModel capture) async {
    try {
      // Create geo field for GeoFlutterFire geospatial queries
      final Map<String, dynamic> geoData = {};
      if (capture.location != null) {
        final geoPoint = capture.location!;
        geoData['geo'] = {
          'geohash': _generateGeohash(geoPoint.latitude, geoPoint.longitude),
          'geopoint': geoPoint,
        };
      }

      await _publicArtRef.doc(capture.id).set({
        'userId': capture.userId,
        'title': capture.title ?? 'Untitled',
        'description': capture.description ?? '',
        'imageUrl': capture.imageUrl,
        'thumbnailUrl': capture.thumbnailUrl,
        'artistName': capture.artistName,
        'location': capture.location,
        'address': capture.locationName,
        'tags': capture.tags ?? [],
        'artType': capture.artType ?? 'Street Art',
        'artMedium': capture.artMedium,
        'isVerified': false,
        'viewCount': 0,
        'likeCount': 0,
        'usersFavorited': <String>[],
        'createdAt': capture.createdAt,
        'updatedAt': capture.updatedAt,
        'captureId': capture.id, // Reference to original capture
        ...geoData, // Add geo field for geospatial queries
      });
      AppLogger.info('✅ Saved capture ${capture.id} to publicArt collection');
    } catch (e) {
      AppLogger.error('❌ Error saving to publicArt collection: $e');
    }
  }

  /// Generate geohash for a location (simple implementation)
  /// For production, consider using a proper geohash library
  String _generateGeohash(double latitude, double longitude) {
    // Simple geohash generation (9 characters precision ~4.8m x 4.8m)
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    final latRange = [-90.0, 90.0];
    final lonRange = [-180.0, 180.0];
    var hash = '';
    var isEven = true;
    var bit = 0;
    var ch = 0;

    while (hash.length < 9) {
      if (isEven) {
        final mid = (lonRange[0] + lonRange[1]) / 2;
        if (longitude > mid) {
          ch |= (1 << (4 - bit));
          lonRange[0] = mid;
        } else {
          lonRange[1] = mid;
        }
      } else {
        final mid = (latRange[0] + latRange[1]) / 2;
        if (latitude > mid) {
          ch |= (1 << (4 - bit));
          latRange[0] = mid;
        } else {
          latRange[1] = mid;
        }
      }

      isEven = !isEven;

      if (bit < 4) {
        bit++;
      } else {
        hash += base32[ch];
        bit = 0;
        ch = 0;
      }
    }

    return hash;
  }

  /// Create a new capture
  Future<CaptureModel> createCapture(CaptureModel capture) async {
    try {
      // Create geo field for GeoFlutterFire geospatial queries
      final Map<String, dynamic> captureData = capture.toFirestore();
      if (capture.location != null) {
        final geoPoint = capture.location!;
        captureData['geo'] = {
          'geohash': _generateGeohash(geoPoint.latitude, geoPoint.longitude),
          'geopoint': geoPoint,
        };
      }

      // CRITICAL: Save to Firestore first - this is the only blocking operation
      final docRef = await _capturesRef.add(captureData);
      final newCapture = capture.copyWith(id: docRef.id);

      // OPTIMIZATION: Run all secondary operations in the background
      // This allows the UI to respond immediately while these complete asynchronously
      _processPostCaptureOperations(newCapture);

      return newCapture;
    } catch (e) {
      AppLogger.error('Error creating capture: $e');
      rethrow;
    }
  }

  /// Process all post-capture operations asynchronously in the background
  /// This prevents blocking the UI while secondary operations complete
  Future<void> _processPostCaptureOperations(CaptureModel newCapture) async {
    // Run all operations in parallel where possible using Future.wait
    // Wrap each in try-catch to prevent one failure from affecting others

    try {
      await Future.wait([
        // Update user's capture count
        _userService.incrementUserCaptureCount(newCapture.userId).catchError((
          Object e,
        ) {
          AppLogger.error('Error incrementing user capture count: $e');
          return false; // Return a value to satisfy the Future<bool> return type
        }),

        // Award XP for creating a capture
        _rewardsService.awardXP('art_capture_created').catchError((Object e) {
          AppLogger.error('Error awarding XP: $e');
          return null; // Return null on error
        }),

        // Record photo capture for daily challenges
        _recordChallengeProgress().catchError((Object e) {
          AppLogger.error('Error recording challenge progress: $e');
          return null; // Return null on error
        }),

        // Update weekly goals for photography
        _updateWeeklyGoals().catchError((Object e) {
          AppLogger.error('Error updating weekly goals: $e');
          return null; // Return null on error
        }),

        // Post social activity for the capture
        _postSocialActivity(newCapture).catchError((Object e) {
          AppLogger.error('Error posting social activity: $e');
          return null; // Return null on error
        }),

        // If capture is public and processed, save to publicArt collection
        if (newCapture.isPublic && newCapture.isProcessed)
          _saveToPublicArt(newCapture).catchError((Object e) {
            AppLogger.error('Error saving to publicArt: $e');
            return null; // Return null on error
          }),
      ], eagerError: false); // Continue even if some operations fail

      // Trigger achievement check (non-blocking)
      _checkCaptureAchievements(newCapture.userId);

      AppLogger.info('✅ All post-capture operations completed');
    } catch (e) {
      AppLogger.error('Error in post-capture operations: $e');
      // Don't rethrow - these are background operations
    }
  }

  /// Record challenge progress for photo capture
  Future<void> _recordChallengeProgress() async {
    try {
      final challengeService = art_walk.ChallengeService();
      await Future.wait([
        challengeService.recordPhotoCapture(),
        challengeService.recordTimeBasedDiscovery(),
      ]);
      AppLogger.info('✅ Recorded photo capture for daily challenges');
    } catch (e) {
      AppLogger.error('Error recording photo capture for challenges: $e');
      rethrow;
    }
  }

  /// Update weekly goals for photography
  Future<void> _updateWeeklyGoals() async {
    try {
      final weeklyGoalsService = art_walk.WeeklyGoalsService();
      final currentGoals = await weeklyGoalsService.getCurrentWeekGoals();

      // Update photography-related weekly goals in parallel
      final updates = currentGoals
          .where(
            (goal) =>
                goal.category == art_walk.WeeklyGoalCategory.photography &&
                !goal.isCompleted,
          )
          .map(
            (goal) => weeklyGoalsService.updateWeeklyGoalProgress(goal.id, 1),
          )
          .toList();

      if (updates.isNotEmpty) {
        await Future.wait(updates);
      }

      AppLogger.info('✅ Updated weekly goals for photo capture');
    } catch (e) {
      AppLogger.error('Error updating weekly goals: $e');
      rethrow;
    }
  }

  /// Post social activity for the capture
  Future<void> _postSocialActivity(CaptureModel newCapture) async {
    try {
      debugPrint('🔍 CaptureService: Starting to post social activity...');
      debugPrint('🔍 CaptureService: Capture ID: ${newCapture.id}');
      debugPrint('🔍 CaptureService: Is Public: ${newCapture.isPublic}');

      if (!newCapture.isPublic) {
        debugPrint(
          '🔍 CaptureService: ❌ Capture is not public, skipping activity',
        );
        return;
      }

      final user = await _userService.getCurrentUserModel();
      debugPrint(
        '🔍 CaptureService: User retrieved: ${user?.username ?? "null"}',
      );

      if (user == null) {
        debugPrint('🔍 CaptureService: ❌ User is null, cannot post activity');
        AppLogger.warning('Cannot post social activity: user is null');
        return;
      }

      debugPrint(
        '🔍 CaptureService: ✅ User and public check passed, posting activity...',
      );

      // Convert GeoPoint to Position for SocialService
      Position? position;
      if (newCapture.location != null) {
        position = Position(
          latitude: newCapture.location!.latitude,
          longitude: newCapture.location!.longitude,
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

      await art_walk.SocialService().postActivity(
        userId: newCapture.userId,
        userName: user.fullName.isNotEmpty ? user.fullName : user.username,
        userAvatar: user.profileImageUrl,
        type: art_walk.SocialActivityType.capture,
        message: 'captured new artwork',
        location: position,
        metadata: {
          'captureId': newCapture.id,
          'artTitle': newCapture.title ?? 'Untitled',
        },
      );

      debugPrint(
        '🔍 CaptureService: ✅ Posted social activity for capture ${newCapture.id}',
      );
      AppLogger.info('✅ Posted social activity for capture');
    } catch (e, stackTrace) {
      debugPrint('🔍 CaptureService: ❌ Error posting social activity: $e');
      debugPrint('🔍 CaptureService: Stack trace: $stackTrace');
      AppLogger.error('Error posting social activity: $e\nStack: $stackTrace');
      rethrow;
    }
  }

  /// Update an existing capture
  Future<bool> updateCapture(
    String captureId,
    Map<String, dynamic> updates,
  ) async {
    try {
      // If location is being updated, also update the geo field
      final Map<String, dynamic> updateData = {...updates};
      if (updates.containsKey('location') && updates['location'] != null) {
        final geoPoint = updates['location'] as GeoPoint;
        updateData['geo'] = {
          'geohash': _generateGeohash(geoPoint.latitude, geoPoint.longitude),
          'geopoint': geoPoint,
        };
      }

      await _capturesRef.doc(captureId).update({
        ...updateData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If the capture is being made public and processed, add to publicArt
      if (updates['isPublic'] == true && updates['isProcessed'] == true) {
        final captureDoc = await _capturesRef.doc(captureId).get();
        if (captureDoc.exists) {
          final captureData = captureDoc.data() as Map<String, dynamic>;
          final capture = CaptureModel.fromJson({
            ...captureData,
            'id': captureId,
          });
          await _saveToPublicArt(capture);

          // Trigger achievement check when capture becomes public
          _checkCaptureAchievements(capture.userId);
        }
      }
      // If the capture is being made private, remove from publicArt
      else if (updates['isPublic'] == false) {
        await _publicArtRef.doc(captureId).delete();
        AppLogger.info(
          '🗑️ Removed capture $captureId from publicArt collection',
        );
      }

      return true;
    } catch (e) {
      AppLogger.error('Error updating capture: $e');
      return false;
    }
  }

  /// Delete a capture
  Future<bool> deleteCapture(String captureId) async {
    try {
      // Get the capture document first to retrieve userId
      final captureDoc = await _capturesRef.doc(captureId).get();
      if (captureDoc.exists) {
        final data = captureDoc.data() as Map<String, dynamic>?;
        final userId = data?['userId'] as String?;

        // Delete from both collections
        await _capturesRef.doc(captureId).delete();
        await _publicArtRef.doc(captureId).delete();

        // Update user's capture count if we have userId
        if (userId != null) {
          await _userService.decrementUserCaptureCount(userId);
        }

        AppLogger.info('🗑️ Deleted capture $captureId from both collections');
        return true;
      } else {
        AppLogger.error('❌ Capture $captureId not found');
        return false;
      }
    } catch (e) {
      AppLogger.error('Error deleting capture: $e');
      return false;
    }
  }

  /// Get a single capture by ID
  Future<CaptureModel?> getCaptureById(String captureId) async {
    try {
      final docSnapshot = await _capturesRef.doc(captureId).get();
      if (!docSnapshot.exists) return null;

      return CaptureModel.fromJson({
        ...docSnapshot.data() as Map<String, dynamic>,
        'id': docSnapshot.id,
      });
    } catch (e) {
      AppLogger.error('Error fetching capture: $e');
      return null;
    }
  }

  /// Get all captures (for dashboard display)
  Future<List<CaptureModel>> getAllCaptures({int limit = 50}) async {
    // Prevent multiple simultaneous calls
    if (_isLoadingAllCaptures) {
      debugPrint(
        '🔄 CaptureService.getAllCaptures() already loading, waiting...',
      );
      // Wait for the current load to complete
      while (_isLoadingAllCaptures) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      return _cachedAllCaptures ?? [];
    }

    // Check cache first
    if (_cachedAllCaptures != null &&
        _allCapturesCacheTime != null &&
        DateTime.now().difference(_allCapturesCacheTime!) < _cacheTimeout) {
      AppLogger.info(
        '📦 CaptureService.getAllCaptures() returning cached data',
      );
      return _cachedAllCaptures!;
    }

    _isLoadingAllCaptures = true;

    try {
      debugPrint(
        '🚀 CaptureService.getAllCaptures() fetching from Firestore with limit: $limit',
      );

      // Try with orderBy first - get all captures for public display
      final querySnapshot = await _capturesRef
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final captures = <CaptureModel>[];
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null && data.isNotEmpty) {
            final capture = CaptureModel.fromJson({...data, 'id': doc.id});
            captures.add(capture);
          }
        } catch (e) {
          AppLogger.error('❌ Error parsing capture ${doc.id}: $e');
          // Skip this document and continue with others
        }
      }

      // Cache the results
      _cachedAllCaptures = captures;
      _allCapturesCacheTime = DateTime.now();

      debugPrint(
        '✅ CaptureService.getAllCaptures() found ${captures.length} captures',
      );
      return captures;
    } catch (e) {
      AppLogger.error('❌ Error fetching all captures with orderBy: $e');

      // Fallback: Try without orderBy to avoid index requirement
      try {
        AppLogger.info('🔄 Trying fallback query without orderBy...');
        final fallbackQuery = await _capturesRef.limit(limit).get();

        final captures = <CaptureModel>[];
        for (final doc in fallbackQuery.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null && data.isNotEmpty) {
              final capture = CaptureModel.fromJson({...data, 'id': doc.id});
              captures.add(capture);
            }
          } catch (e) {
            AppLogger.error(
              '❌ Error parsing capture ${doc.id} in fallback: $e',
            );
            // Skip this document and continue with others
          }
        }

        // Sort manually by createdAt
        captures.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Cache the results
        _cachedAllCaptures = captures;
        _allCapturesCacheTime = DateTime.now();

        AppLogger.info(
          '✅ Fallback query found ${captures.length} all captures',
        );
        return captures;
      } catch (fallbackError) {
        AppLogger.error('❌ Fallback query also failed: $fallbackError');
        return [];
      }
    } finally {
      _isLoadingAllCaptures = false;
    }
  }

  /// Clear the cache for getAllCaptures
  void clearAllCapturesCache() {
    _cachedAllCaptures = null;
    _allCapturesCacheTime = null;
  }

  /// Search captures by query (implements CaptureServiceInterface)
  @override
  Future<List<CaptureModel>> searchCaptures(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final lowerQuery = query.toLowerCase().trim();
      AppLogger.info(
        '🔍 CaptureService.searchCaptures() searching for: "$query"',
      );

      // Get all captures first (leverages existing caching)
      final allCaptures = await getAllCaptures(limit: 200);

      // Filter captures based on query
      final filteredCaptures = allCaptures.where((capture) {
        // Search in title
        if (capture.title?.toLowerCase().contains(lowerQuery) == true) {
          return true;
        }

        // Search in description
        if (capture.description?.toLowerCase().contains(lowerQuery) == true) {
          return true;
        }

        // Search in location name
        if (capture.locationName?.toLowerCase().contains(lowerQuery) == true) {
          return true;
        }

        // Search in artist name
        if (capture.artistName?.toLowerCase().contains(lowerQuery) == true) {
          return true;
        }

        // Search in tags
        if (capture.tags?.any(
              (tag) => tag.toLowerCase().contains(lowerQuery),
            ) ==
            true) {
          return true;
        }

        // Search in art type and medium
        if (capture.artType?.toLowerCase().contains(lowerQuery) == true) {
          return true;
        }
        if (capture.artMedium?.toLowerCase().contains(lowerQuery) == true) {
          return true;
        }

        return false;
      }).toList();

      AppLogger.info(
        '✅ CaptureService.searchCaptures() found ${filteredCaptures.length} matches',
      );
      return filteredCaptures;
    } catch (e) {
      AppLogger.error('❌ CaptureService.searchCaptures() error: $e');
      return [];
    }
  }

  /// Get public captures
  Future<List<CaptureModel>> getPublicCaptures({int limit = 20}) async {
    try {
      // Try the indexed query first
      final querySnapshot = await _capturesRef
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => CaptureModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching public captures with index: $e');

      // Fallback: Try without orderBy to avoid index requirement
      try {
        AppLogger.info('🔄 Trying fallback query without orderBy...');
        final fallbackQuery = await _capturesRef
            .where('isPublic', isEqualTo: true)
            .limit(limit)
            .get();

        final captures = fallbackQuery.docs
            .map(
              (doc) => CaptureModel.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }),
            )
            .toList();

        // Sort manually by createdAt
        captures.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        AppLogger.info(
          '✅ Fallback query found ${captures.length} public captures',
        );
        return captures;
      } catch (fallbackError) {
        AppLogger.error('❌ Fallback query also failed: $fallbackError');
        return [];
      }
    }
  }

  /// Get user captures with limit
  Future<List<CaptureModel>> getUserCaptures({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _capturesRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => CaptureModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching user captures: $e');

      // Fallback without orderBy
      try {
        final fallbackQuery = await _capturesRef
            .where('userId', isEqualTo: userId)
            .limit(limit)
            .get();

        final captures = fallbackQuery.docs
            .map(
              (doc) => CaptureModel.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }),
            )
            .toList();

        // Sort manually by createdAt
        captures.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return captures;
      } catch (fallbackError) {
        debugPrint(
          '❌ Fallback user captures query also failed: $fallbackError',
        );
        return [];
      }
    }
  }

  /// Get user capture count
  Future<int> getUserCaptureCount(String userId) async {
    try {
      final querySnapshot = await _capturesRef
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return querySnapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Error getting user capture count: $e');

      // Fallback: get all documents and count manually
      try {
        final querySnapshot = await _capturesRef
            .where('userId', isEqualTo: userId)
            .get();

        return querySnapshot.docs.length;
      } catch (fallbackError) {
        debugPrint(
          '❌ Fallback capture count query also failed: $fallbackError',
        );
        return 0;
      }
    }
  }

  /// Get user capture views (total views across all user's captures)
  Future<int> getUserCaptureViews(String userId) async {
    try {
      final querySnapshot = await _capturesRef
          .where('userId', isEqualTo: userId)
          .get();

      int totalViews = 0;
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final views = data['views'] as int? ?? 0;
        totalViews += views;
      }

      return totalViews;
    } catch (e) {
      AppLogger.error('Error getting user capture views: $e');
      return 0;
    }
  }

  /// Admin: Get captures pending moderation
  Future<List<CaptureModel>> getPendingCaptures({int limit = 50}) async {
    try {
      final querySnapshot = await _capturesRef
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: false) // Oldest first for review
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => CaptureModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching pending captures: $e');

      // Fallback without orderBy
      try {
        final fallbackQuery = await _capturesRef
            .where('status', isEqualTo: 'pending')
            .limit(limit)
            .get();

        final captures = fallbackQuery.docs
            .map(
              (doc) => CaptureModel.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }),
            )
            .toList();

        // Sort manually by createdAt
        captures.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return captures;
      } catch (fallbackError) {
        debugPrint(
          '❌ Fallback pending captures query also failed: $fallbackError',
        );
        return [];
      }
    }
  }

  /// Admin: Approve a capture
  Future<bool> approveCapture(
    String captureId, {
    String? moderationNotes,
  }) async {
    try {
      // Get capture data to find userId for XP awarding
      final captureDoc = await _capturesRef.doc(captureId).get();
      if (!captureDoc.exists) {
        AppLogger.info('Capture $captureId not found');
        return false;
      }

      final captureData = captureDoc.data() as Map<String, dynamic>;
      final userId = captureData['userId'] as String?;

      // Update capture status
      await _capturesRef.doc(captureId).update({
        'status': 'approved',
        'moderationNotes': moderationNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Award XP for approved capture
      if (userId != null) {
        try {
          final rewardsService = art_walk.RewardsService();
          await rewardsService.awardXP('art_capture_approved');
          debugPrint(
            '✅ Awarded 50 XP for approved capture $captureId to user $userId',
          );
        } catch (xpError) {
          AppLogger.error(
            '⚠️ Error awarding XP for capture approval: $xpError',
          );
          // Don't fail the approval if XP fails
        }
      }

      return true;
    } catch (e) {
      AppLogger.error('Error approving capture: $e');
      return false;
    }
  }

  /// Admin: Reject a capture
  Future<bool> rejectCapture(
    String captureId, {
    String? moderationNotes,
  }) async {
    try {
      await _capturesRef.doc(captureId).update({
        'status': 'rejected',
        'moderationNotes': moderationNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      AppLogger.error('Error rejecting capture: $e');
      return false;
    }
  }

  /// Admin: Delete a capture completely
  Future<bool> adminDeleteCapture(String captureId) async {
    try {
      // Get the capture document first to retrieve userId
      final captureDoc = await _capturesRef.doc(captureId).get();
      if (captureDoc.exists) {
        final data = captureDoc.data() as Map<String, dynamic>?;
        final userId = data?['userId'] as String?;

        // Delete capture
        await _capturesRef.doc(captureId).delete();

        // Update user's capture count if we have userId
        if (userId != null) {
          await _userService.decrementUserCaptureCount(userId);
        }

        return true;
      } else {
        AppLogger.error('❌ Capture $captureId not found');
        return false;
      }
    } catch (e) {
      AppLogger.error('Error admin deleting capture: $e');
      return false;
    }
  }

  /// Get captures by status
  Future<List<CaptureModel>> getCapturesByStatus(
    String status, {
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _capturesRef
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => CaptureModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching captures by status: $e');

      // Fallback without orderBy
      try {
        final fallbackQuery = await _capturesRef
            .where('status', isEqualTo: status)
            .limit(limit)
            .get();

        final captures = fallbackQuery.docs
            .map(
              (doc) => CaptureModel.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }),
            )
            .toList();

        // Sort manually by createdAt
        captures.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return captures;
      } catch (fallbackError) {
        debugPrint(
          '❌ Fallback status captures query also failed: $fallbackError',
        );
        return [];
      }
    }
  }

  /// Admin: Get reported/flagged captures
  Future<List<CaptureModel>> getReportedCaptures({int limit = 50}) async {
    try {
      final querySnapshot = await _capturesRef
          .where('reportCount', isGreaterThan: 0)
          .orderBy('reportCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => CaptureModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching reported captures: $e');

      // Fallback without orderBy
      try {
        final fallbackQuery = await _capturesRef
            .where('reportCount', isGreaterThan: 0)
            .limit(limit)
            .get();

        final captures = fallbackQuery.docs
            .map(
              (doc) => CaptureModel.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }),
            )
            .toList();

        // Sort manually by reportCount
        captures.sort((a, b) => b.reportCount.compareTo(a.reportCount));
        return captures;
      } catch (fallbackError) {
        debugPrint(
          '❌ Fallback reported captures query also failed: $fallbackError',
        );
        return [];
      }
    }
  }

  /// Admin: Clear reports from a capture
  Future<bool> clearCaptureReports(String captureId) async {
    try {
      await _capturesRef.doc(captureId).update({
        'reportCount': 0,
        'isFlagged': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info('✅ Reports cleared for capture: $captureId');
      return true;
    } catch (e) {
      AppLogger.error('Error clearing capture reports: $e');
      return false;
    }
  }

  /// Migration method: Move existing public captures to publicArt collection
  Future<void> migrateCapturesToPublicArt() async {
    try {
      debugPrint(
        '🔄 Starting migration of captures to publicArt collection...',
      );

      // Get all public and processed captures
      final snapshot = await _capturesRef
          .where('isPublic', isEqualTo: true)
          .where('isProcessed', isEqualTo: true)
          .get();

      AppLogger.analytics(
        '📊 Found ${snapshot.docs.length} public captures to migrate',
      );

      int migrated = 0;
      int errors = 0;

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final capture = CaptureModel.fromJson({...data, 'id': doc.id});

          // Check if already exists in publicArt
          final existingDoc = await _publicArtRef.doc(doc.id).get();
          if (!existingDoc.exists) {
            await _saveToPublicArt(capture);
            migrated++;
            AppLogger.info('✅ Migrated capture ${doc.id}');
          } else {
            AppLogger.info('⏭️ Capture ${doc.id} already exists in publicArt');
          }
        } catch (e) {
          errors++;
          AppLogger.error('❌ Error migrating capture ${doc.id}: $e');
        }
      }

      AppLogger.error(
        '🎉 Migration completed: $migrated migrated, $errors errors',
      );
    } catch (e) {
      AppLogger.error('❌ Migration failed: $e');
    }
  }

  /// Check capture achievements for a user
  Future<void> _checkCaptureAchievements(String userId) async {
    try {
      // Use the ArtWalkService to check capture achievements
      final artWalkService = art_walk.ArtWalkService();
      await artWalkService.checkCaptureAchievements(userId);
    } catch (e) {
      AppLogger.error('❌ Error checking capture achievements: $e');
      // Don't rethrow - achievement checking shouldn't break capture creation
    }
  }

  /// Backfill geo field for existing captures (migration utility)
  /// This should be called once to add geo fields to existing captures
  Future<void> backfillGeoFieldForCaptures({int batchSize = 100}) async {
    try {
      AppLogger.info('🔄 Starting geo field backfill for captures...');

      // Query captures that have location but no geo field
      final querySnapshot = await _capturesRef
          .where('location', isNull: false)
          .limit(batchSize)
          .get();

      int updatedCount = 0;
      int skippedCount = 0;

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;

          // Skip if geo field already exists
          if (data.containsKey('geo')) {
            skippedCount++;
            continue;
          }

          final location = data['location'] as GeoPoint?;
          if (location != null) {
            // Add geo field
            await doc.reference.update({
              'geo': {
                'geohash': _generateGeohash(
                  location.latitude,
                  location.longitude,
                ),
                'geopoint': location,
              },
            });
            updatedCount++;
            AppLogger.info('✅ Added geo field to capture ${doc.id}');
          }
        } catch (e) {
          AppLogger.error('❌ Error updating capture ${doc.id}: $e');
        }
      }

      AppLogger.info(
        '✅ Geo field backfill complete: $updatedCount updated, $skippedCount skipped',
      );
    } catch (e) {
      AppLogger.error('❌ Error during geo field backfill: $e');
      rethrow;
    }
  }

  // ============================================================================
  // LIKE/ENGAGEMENT METHODS
  // ============================================================================

  /// Like a capture
  Future<bool> likeCapture(String captureId, String userId) async {
    try {
      // Check if user already liked this capture
      final existingLike = await _firestore
          .collection('engagements')
          .where('contentId', isEqualTo: captureId)
          .where('contentType', isEqualTo: 'capture')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'like')
          .limit(1)
          .get();

      if (existingLike.docs.isNotEmpty) {
        AppLogger.info('User already liked this capture');
        return false; // Already liked
      }

      // Create engagement record
      await _firestore.collection('engagements').add({
        'contentId': captureId,
        'contentType': 'capture',
        'userId': userId,
        'type': 'like',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update capture like count
      final captureRef = _capturesRef.doc(captureId);
      await captureRef.update({
        'engagementStats.likeCount': FieldValue.increment(1),
        'engagementStats.lastUpdated': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Capture $captureId liked by $userId');
      return true;
    } catch (e) {
      AppLogger.error('Error liking capture: $e');
      return false;
    }
  }

  /// Unlike a capture
  Future<bool> unlikeCapture(String captureId, String userId) async {
    try {
      // Find and delete the like engagement
      final engagementQuery = await _firestore
          .collection('engagements')
          .where('contentId', isEqualTo: captureId)
          .where('contentType', isEqualTo: 'capture')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'like')
          .get();

      for (final doc in engagementQuery.docs) {
        await doc.reference.delete();
      }

      // Update capture like count
      final captureRef = _capturesRef.doc(captureId);
      await captureRef.update({
        'engagementStats.likeCount': FieldValue.increment(-1),
        'engagementStats.lastUpdated': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Capture $captureId unliked by $userId');
      return true;
    } catch (e) {
      AppLogger.error('Error unliking capture: $e');
      return false;
    }
  }

  /// Check if user liked a capture
  Future<bool> hasUserLikedCapture(String captureId, String userId) async {
    try {
      final query = await _firestore
          .collection('engagements')
          .where('contentId', isEqualTo: captureId)
          .where('contentType', isEqualTo: 'capture')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'like')
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      AppLogger.error('Error checking if user liked capture: $e');
      return false;
    }
  }

  // ============================================================================
  // COMMENT METHODS
  // ============================================================================

  /// Add a comment to a capture
  Future<String?> addComment({
    required String captureId,
    required String userId,
    required String userName,
    required String userAvatar,
    required String text,
  }) async {
    try {
      // Add comment to engagements collection with additional metadata
      final docRef = await _firestore
          .collection('engagements')
          .add(<String, dynamic>{
            'contentId': captureId,
            'contentType': 'capture',
            'userId': userId,
            'type': 'comment',
            'text': text,
            'userName': userName,
            'userAvatar': userAvatar,
            'createdAt': FieldValue.serverTimestamp(),
            'likeCount': 0,
            'likedBy': <String>[],
          });

      // Update capture comment count
      await _capturesRef.doc(captureId).update({
        'engagementStats.commentCount': FieldValue.increment(1),
        'engagementStats.lastUpdated': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Comment added to capture $captureId');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Error adding comment: $e');
      return null;
    }
  }

  /// Get comments for a capture
  Future<List<dynamic>> getComments(String captureId) async {
    try {
      final querySnapshot = await _firestore
          .collection('engagements')
          .where('contentId', isEqualTo: captureId)
          .where('contentType', isEqualTo: 'capture')
          .where('type', isEqualTo: 'comment')
          .orderBy('createdAt', descending: true)
          .get();

      final comments = <Map<String, dynamic>>[];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        comments.add({'id': doc.id, ...data});
      }

      return comments;
    } catch (e) {
      AppLogger.error('Error fetching comments: $e');
      return [];
    }
  }

  /// Delete a comment
  Future<bool> deleteComment(String captureId, String commentId) async {
    try {
      // Delete the comment
      await _firestore.collection('engagements').doc(commentId).delete();

      // Update capture comment count
      await _capturesRef.doc(captureId).update({
        'engagementStats.commentCount': FieldValue.increment(-1),
        'engagementStats.lastUpdated': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Comment $commentId deleted from capture $captureId');
      return true;
    } catch (e) {
      AppLogger.error('Error deleting comment: $e');
      return false;
    }
  }

  /// Like a comment
  Future<bool> likeComment(String commentId, String userId) async {
    try {
      final commentRef = _firestore.collection('engagements').doc(commentId);

      await commentRef.update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likeCount': FieldValue.increment(1),
      });

      AppLogger.info('✅ Comment $commentId liked by $userId');
      return true;
    } catch (e) {
      AppLogger.error('Error liking comment: $e');
      return false;
    }
  }

  /// Unlike a comment
  Future<bool> unlikeComment(String commentId, String userId) async {
    try {
      final commentRef = _firestore.collection('engagements').doc(commentId);

      await commentRef.update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likeCount': FieldValue.increment(-1),
      });

      AppLogger.info('✅ Comment $commentId unliked by $userId');
      return true;
    } catch (e) {
      AppLogger.error('Error unliking comment: $e');
      return false;
    }
  }
}
