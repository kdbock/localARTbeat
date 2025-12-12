import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';
import 'rewards_service.dart';

/// Service for managing art walk progress tracking
class ArtWalkProgressService {
  static final ArtWalkProgressService _instance =
      ArtWalkProgressService._internal();
  factory ArtWalkProgressService() => _instance;
  ArtWalkProgressService._internal();

  FirebaseFirestore? _firestoreInstance;
  FirebaseAuth? _authInstance;

  // Lazy initialization getters
  FirebaseFirestore get _firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authInstance ??= FirebaseAuth.instance;

  final Logger _logger = Logger();
  final RewardsService _rewardsService = RewardsService();

  // Auto-save timer
  Timer? _autoSaveTimer;
  ArtWalkProgress? _currentProgress;

  // Collection references
  CollectionReference get _progressCollection =>
      _firestore.collection('artWalkProgress');

  /// Start a new art walk progress
  Future<ArtWalkProgress> startWalk({
    required String artWalkId,
    required int totalArtCount,
    String? userId,
  }) async {
    final uid = userId ?? getCurrentUserId();
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Check if there's already progress for this walk
      final existingProgress = await getWalkProgress(uid, artWalkId);
      if (existingProgress != null && !existingProgress.isCompleted) {
        // Resume existing progress
        _currentProgress = existingProgress;
        _startAutoSave();
        _logger.i(
          '📊 startWalk() - Resuming existing progress: $artWalkId with ${existingProgress.visitedArt.length} visited pieces',
        );
        return existingProgress;
      }

      _logger.i(
        '📊 startWalk() - Creating new progress for walk: $artWalkId (no existing progress found)',
      );

      // Create new progress
      final progressId = '${uid}_$artWalkId';
      final now = DateTime.now();

      final progress = ArtWalkProgress(
        id: progressId,
        userId: uid,
        artWalkId: artWalkId,
        visitedArt: const [],
        startedAt: now,
        lastActiveAt: now,
        status: WalkStatus.inProgress,
        currentArtIndex: 0,
        navigationState: const {},
        totalArtCount: totalArtCount,
        totalPointsEarned: 0,
      );

      // Save to Firestore
      await _progressCollection.doc(progressId).set(progress.toFirestore());

      _currentProgress = progress;
      _startAutoSave();

      _logger.i('Started new art walk progress: $progressId');
      return progress;
    } catch (e) {
      _logger.e('Error starting art walk progress: $e');
      rethrow;
    }
  }

  /// Record a visit to an art piece
  Future<ArtWalkProgress> recordArtVisit({
    required String artId,
    required Position userLocation,
    required Position artLocation,
    String? photoPath,
    Duration? viewingTime,
  }) async {
    if (_currentProgress == null) {
      throw Exception('No active art walk progress');
    }

    try {
      _logger.i(
        '📊 recordArtVisit() - Starting for artId=$artId, current visitedArt.length=${_currentProgress!.visitedArt.length}',
      );

      // Calculate distance from art
      final distance = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        artLocation.latitude,
        artLocation.longitude,
      );

      // Determine if user was near the art (within 30m)
      final wasNearArt = distance <= 30.0;

      // Calculate points based on proximity and verification
      final int points = _calculateVisitPoints(distance, photoPath != null);

      // Create art visit record
      final artVisit = ArtVisit(
        artId: artId,
        visitedAt: DateTime.now(),
        visitLocation: GeoPoint(userLocation.latitude, userLocation.longitude),
        pointsAwarded: points,
        wasNearArt: wasNearArt,
        photoTaken: photoPath,
        distanceFromArt: distance,
        timeSpentViewing: viewingTime,
      );

      // Check if already visited
      final alreadyVisited = _currentProgress!.visitedArt.any(
        (v) => v.artId == artId,
      );
      if (alreadyVisited) {
        _logger.w('Art piece $artId already visited');
        return _currentProgress!;
      }

      // Update progress
      final updatedVisitedArt = List<ArtVisit>.from(
        _currentProgress!.visitedArt,
      )..add(artVisit);
      final updatedProgress = _currentProgress!.copyWith(
        visitedArt: updatedVisitedArt,
        lastActiveAt: DateTime.now(),
        currentArtIndex: _currentProgress!.currentArtIndex + 1,
        totalPointsEarned: _currentProgress!.totalPointsEarned + points,
      );

      _logger.i(
        '📊 recordArtVisit() - Updated progress: visitedArt.length=${updatedProgress.visitedArt.length}',
      );

      // Save to Firestore
      await _saveProgress(updatedProgress);

      // Award XP through rewards service
      await _rewardsService.awardXP('art_visit', customAmount: points);

      // Check for milestone achievements
      await _checkMilestoneAchievements(updatedProgress);

      _currentProgress = updatedProgress;

      _logger.i(
        'Recorded art visit: $artId, points: $points, distance: ${distance.toStringAsFixed(1)}m, now have ${_currentProgress!.visitedArt.length} visited pieces',
      );
      return updatedProgress;
    } catch (e) {
      _logger.e('Error recording art visit: $e');
      rethrow;
    }
  }

  /// Complete the current art walk
  Future<ArtWalkProgress> completeWalk() async {
    if (_currentProgress == null) {
      throw Exception('No active art walk progress');
    }

    try {
      _logger.i(
        '📊 completeWalk() - Starting completion. Current progress: visitedArt.length=${_currentProgress!.visitedArt.length}, artWalkId=${_currentProgress!.artWalkId}',
      );

      // Calculate completion bonus
      final completionBonus = _calculateCompletionBonus(_currentProgress!);

      // Create completed progress with updated total points earned
      final completedProgress = _currentProgress!.copyWith(
        status: WalkStatus.completed,
        completedAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
        totalPointsEarned:
            _currentProgress!.totalPointsEarned + completionBonus,
      );

      _logger.i(
        '📊 completeWalk() - Completed progress: visitedArt.length=${completedProgress.visitedArt.length}, bonus=$completionBonus',
      );

      // Save to Firestore
      await _saveProgress(completedProgress);

      // Award completion bonus points
      if (completionBonus > 0) {
        await _rewardsService.awardXP(
          'art_walk_completion',
          customAmount: completionBonus,
        );
      }

      // Stop auto-save
      _stopAutoSave();

      _currentProgress = null;

      _logger.i(
        'Completed art walk: ${completedProgress.artWalkId} with bonus: $completionBonus and ${completedProgress.visitedArt.length} visited pieces',
      );
      return completedProgress;
    } catch (e) {
      _logger.e('Error completing art walk: $e');
      rethrow;
    }
  }

  /// Pause the current art walk
  Future<ArtWalkProgress> pauseWalk() async {
    if (_currentProgress == null) {
      throw Exception('No active art walk progress');
    }

    try {
      final pausedProgress = _currentProgress!.copyWith(
        status: WalkStatus.paused,
        lastActiveAt: DateTime.now(),
      );

      await _saveProgress(pausedProgress);
      _stopAutoSave();

      _currentProgress = pausedProgress;

      _logger.i('Paused art walk: ${pausedProgress.artWalkId}');
      return pausedProgress;
    } catch (e) {
      _logger.e('Error pausing art walk: $e');
      rethrow;
    }
  }

  /// Resume a paused art walk
  Future<ArtWalkProgress> resumeWalk(String progressId) async {
    try {
      final progress = await getWalkProgressById(progressId);
      if (progress == null) {
        throw Exception('Progress not found: $progressId');
      }

      if (progress.status != WalkStatus.paused) {
        throw Exception('Walk is not paused');
      }

      final resumedProgress = progress.copyWith(
        status: WalkStatus.inProgress,
        lastActiveAt: DateTime.now(),
      );

      await _saveProgress(resumedProgress);

      _currentProgress = resumedProgress;
      _startAutoSave();

      _logger.i('Resumed art walk: ${resumedProgress.artWalkId}');
      return resumedProgress;
    } catch (e) {
      _logger.e('Error resuming art walk: $e');
      rethrow;
    }
  }

  /// Abandon the current art walk
  Future<void> abandonWalk() async {
    if (_currentProgress == null) {
      throw Exception('No active art walk progress');
    }

    try {
      final abandonedProgress = _currentProgress!.copyWith(
        status: WalkStatus.abandoned,
        lastActiveAt: DateTime.now(),
      );

      await _saveProgress(abandonedProgress);
      _stopAutoSave();

      _currentProgress = null;

      _logger.i('Abandoned art walk: ${abandonedProgress.artWalkId}');
    } catch (e) {
      _logger.e('Error abandoning art walk: $e');
      rethrow;
    }
  }

  /// Get walk progress for a user and art walk
  Future<ArtWalkProgress?> getWalkProgress(
    String userId,
    String artWalkId,
  ) async {
    try {
      final progressId = '${userId}_$artWalkId';
      final doc = await _progressCollection.doc(progressId).get();

      if (!doc.exists) return null;

      final progress = ArtWalkProgress.fromFirestore(doc);
      return progress;
    } catch (e) {
      _logger.e('Error getting walk progress: $e');
      return null;
    }
  }

  /// Set the current progress (used when loading existing progress from outside the service)
  void setCurrentProgress(ArtWalkProgress progress) {
    _currentProgress = progress;
    _startAutoSave();
    _logger.i(
      '📊 setCurrentProgress() - Set current progress for walk: ${progress.artWalkId}, visitedArt.length=${progress.visitedArt.length}',
    );
  }

  /// Get walk progress by ID
  Future<ArtWalkProgress?> getWalkProgressById(String progressId) async {
    try {
      final doc = await _progressCollection.doc(progressId).get();

      if (!doc.exists) return null;

      return ArtWalkProgress.fromFirestore(doc);
    } catch (e) {
      _logger.e('Error getting walk progress by ID: $e');
      return null;
    }
  }

  /// Get all incomplete walks for a user
  Future<List<ArtWalkProgress>> getIncompleteWalks(String userId) async {
    try {
      final query = await _progressCollection
          .where('userId', isEqualTo: userId)
          .where(
            'status',
            whereIn: [WalkStatus.inProgress.name, WalkStatus.paused.name],
          )
          .orderBy('lastActiveAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ArtWalkProgress.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Check if it's a Firestore index error
      if (e.toString().contains('requires an index')) {
        _logger.w(
          'Firestore index not created yet for incomplete walks query. Returning empty list.',
        );
        // Return empty list silently - this is expected during development
        return [];
      } else {
        _logger.e('Error getting incomplete walks: $e');
        return [];
      }
    }
  }

  /// Get completed walks for a user
  Future<List<ArtWalkProgress>> getCompletedWalks(String userId) async {
    try {
      final query = await _progressCollection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: WalkStatus.completed.name)
          .orderBy('completedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ArtWalkProgress.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Check if it's a Firestore index error
      if (e.toString().contains('requires an index')) {
        _logger.w(
          'Firestore index not created yet for completed walks query. Returning empty list.',
        );
        // Return empty list silently - this is expected during development
        return [];
      } else {
        _logger.e('Error getting completed walks: $e');
        return [];
      }
    }
  }

  /// Clean up stale progress (older than 7 days)
  Future<void> cleanupStaleProgress() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      final query = await _progressCollection
          .where('lastActiveAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .where(
            'status',
            whereIn: [WalkStatus.inProgress.name, WalkStatus.paused.name],
          )
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {'status': WalkStatus.abandoned.name});
      }

      if (query.docs.isNotEmpty) {
        await batch.commit();
        _logger.i('Cleaned up ${query.docs.length} stale progress records');
      }
    } catch (e) {
      _logger.e('Error cleaning up stale progress: $e');
    }
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get current active progress
  ArtWalkProgress? get currentProgress => _currentProgress;

  /// Calculate points for an art visit based on distance and verification
  int _calculateVisitPoints(double distance, bool hasPhoto) {
    int basePoints = 5; // General check-in

    if (distance <= 30.0) {
      basePoints = 10; // Within 30m
      if (hasPhoto) {
        basePoints = 15; // Verified with photo
      }
    }

    return basePoints;
  }

  /// Calculate completion bonus based on progress
  int _calculateCompletionBonus(ArtWalkProgress progress) {
    int bonus = 100; // Base completion bonus

    // Perfect completion bonus
    if (progress.progressPercentage >= 1.0) {
      bonus += 50;
    }

    // Speed bonus (completed in under 2 hours)
    if (progress.timeSpent.inHours < 2) {
      bonus += 25;
    }

    // Photo documentation bonus
    final photosCount = progress.visitedArt
        .where((v) => v.photoTaken != null)
        .length;
    if (photosCount >= progress.visitedArt.length * 0.5) {
      bonus += 30; // Documented at least 50% with photos
    }

    return bonus;
  }

  /// Check for milestone achievements
  Future<void> _checkMilestoneAchievements(ArtWalkProgress progress) async {
    // 25% milestone
    if (progress.progressPercentage >= 0.25 &&
        progress.progressPercentage < 0.5) {
      await _rewardsService.awardXP('art_walk_milestone_25', customAmount: 10);
    }
    // 50% milestone
    else if (progress.progressPercentage >= 0.5 &&
        progress.progressPercentage < 0.75) {
      await _rewardsService.awardXP('art_walk_milestone_50', customAmount: 15);
    }
    // 75% milestone
    else if (progress.progressPercentage >= 0.75 &&
        progress.progressPercentage < 1.0) {
      await _rewardsService.awardXP('art_walk_milestone_75', customAmount: 20);
    }
  }

  /// Save progress to Firestore
  Future<void> _saveProgress(ArtWalkProgress progress) async {
    await _progressCollection.doc(progress.id).set(progress.toFirestore());
  }

  /// Start auto-save timer
  void _startAutoSave() {
    _stopAutoSave(); // Stop any existing timer

    _autoSaveTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_currentProgress != null) {
        _saveProgress(
          _currentProgress!.copyWith(lastActiveAt: DateTime.now()),
        ).catchError((Object e) {
          _logger.e('Auto-save failed: $e');
        });
      }
    });
  }

  /// Stop auto-save timer
  void _stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  /// Dispose of resources
  void dispose() {
    _stopAutoSave();
  }
}
