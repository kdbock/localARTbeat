import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/public_art_model.dart';
import 'rewards_service.dart';
import 'challenge_service.dart';

/// Service for managing instant art discovery (Pokemon Go style)
class InstantDiscoveryService {
  static final InstantDiscoveryService _instance =
      InstantDiscoveryService._internal();

  factory InstantDiscoveryService() => _instance;

  InstantDiscoveryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RewardsService _rewardsService = RewardsService();
  final ChallengeService _challengeService = ChallengeService();

  // Cache for discovered art IDs
  Set<String>? _discoveredArtIds;
  DateTime? _discoveredArtCacheTime;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Get nearby public art within radius (in meters)
  Future<List<PublicArtModel>> getNearbyArt(
    Position userPosition, {
    double radiusMeters = 500,
  }) async {
    try {
      // Get user's discovered art to filter out
      final discoveredIds = await _getDiscoveredArtIds();

      // Create GeoFirePoint from user position
      final center = GeoFirePoint(
        GeoPoint(userPosition.latitude, userPosition.longitude),
      );

      // Query publicArt collection within radius
      final publicArtRef = _firestore.collection('publicArt');

      // Use geoflutterfire_plus for geospatial query
      final publicArtGeoQuery = GeoCollectionReference(publicArtRef)
          .subscribeWithin(
            center: center,
            radiusInKm: radiusMeters / 1000, // Convert meters to km
            field: 'geo',
            geopointFrom: (data) =>
                (data['location'] as GeoPoint?) ?? const GeoPoint(0, 0),
            strictMode: true,
          )
          .take(1); // Take first emission

      final publicArtResults = await publicArtGeoQuery.first;

      // Query captures collection within radius (only public captures)
      final capturesRef = _firestore.collection('captures');
      final capturesGeoQuery = GeoCollectionReference(capturesRef)
          .subscribeWithin(
            center: center,
            radiusInKm: radiusMeters / 1000, // Convert meters to km
            field: 'geo',
            geopointFrom: (data) =>
                (data['location'] as GeoPoint?) ?? const GeoPoint(0, 0),
            strictMode: true,
          )
          .take(1); // Take first emission

      final capturesResults = await capturesGeoQuery.first;

      // Convert publicArt to PublicArtModel and filter out discovered art
      final nearbyPublicArt = publicArtResults
          .map((doc) {
            try {
              return PublicArtModel.fromFirestore(doc);
            } catch (e) {
              AppLogger.error('Error parsing public art: $e');
              return null;
            }
          })
          .whereType<PublicArtModel>()
          .where((art) => !discoveredIds.contains(art.id))
          .toList();

      // Convert captures to PublicArtModel and filter for public captures only
      final nearbyCaptures = capturesResults
          .map((doc) {
            try {
              final data = doc.data();
              // Only include public captures
              if (data != null && (data['isPublic'] as bool? ?? false)) {
                final capture = CaptureModel.fromFirestore(doc, null);
                return _convertCaptureToPublicArt(capture);
              }
              return null;
            } catch (e) {
              AppLogger.error('Error parsing capture: $e');
              return null;
            }
          })
          .whereType<PublicArtModel>()
          .where((art) => !discoveredIds.contains(art.id))
          .toList();

      // Combine both lists
      final nearbyArt = [...nearbyPublicArt, ...nearbyCaptures];

      // Sort by proximity
      nearbyArt.sort((a, b) {
        final distA = Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          a.location.latitude,
          a.location.longitude,
        );
        final distB = Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          b.location.latitude,
          b.location.longitude,
        );
        return distA.compareTo(distB);
      });

      return nearbyArt;
    } catch (e) {
      AppLogger.error('Error getting nearby art: $e');
      return [];
    }
  }

  /// Stream of nearby art (real-time updates)
  Stream<List<PublicArtModel>> watchNearbyArt({
    required Position userPosition,
    double radiusMeters = 500,
  }) async* {
    try {
      // Get user's discovered art to filter out
      final discoveredIds = await _getDiscoveredArtIds();

      // Create GeoFirePoint from user position
      final center = GeoFirePoint(
        GeoPoint(userPosition.latitude, userPosition.longitude),
      );

      // Query publicArt collection within radius
      final publicArtRef = _firestore.collection('publicArt');

      // Use geoflutterfire_plus for geospatial query
      final publicArtGeoStream = GeoCollectionReference(publicArtRef)
          .subscribeWithin(
            center: center,
            radiusInKm: radiusMeters / 1000, // Convert meters to km
            field: 'geo',
            geopointFrom: (data) =>
                (data['location'] as GeoPoint?) ?? const GeoPoint(0, 0),
            strictMode: true,
          );

      // Query captures collection within radius
      final capturesRef = _firestore.collection('captures');

      // Combine both streams
      await for (final _ in publicArtGeoStream) {
        // Get latest results from both collections
        final publicArtResults = await GeoCollectionReference(publicArtRef)
            .subscribeWithin(
              center: center,
              radiusInKm: radiusMeters / 1000,
              field: 'geo',
              geopointFrom: (data) =>
                  (data['location'] as GeoPoint?) ?? const GeoPoint(0, 0),
              strictMode: true,
            )
            .take(1)
            .first;

        final capturesResults = await GeoCollectionReference(capturesRef)
            .subscribeWithin(
              center: center,
              radiusInKm: radiusMeters / 1000,
              field: 'geo',
              geopointFrom: (data) =>
                  (data['location'] as GeoPoint?) ?? const GeoPoint(0, 0),
              strictMode: true,
            )
            .take(1)
            .first;

        // Convert publicArt to PublicArtModel and filter out discovered art
        final nearbyPublicArt = publicArtResults
            .map((doc) {
              try {
                return PublicArtModel.fromFirestore(doc);
              } catch (e) {
                AppLogger.error('Error parsing public art: $e');
                return null;
              }
            })
            .whereType<PublicArtModel>()
            .where((art) => !discoveredIds.contains(art.id))
            .toList();

        // Convert captures to PublicArtModel and filter for public captures only
        final nearbyCaptures = capturesResults
            .map((doc) {
              try {
                final data = doc.data();
                // Only include public captures
                if (data != null && (data['isPublic'] as bool? ?? false)) {
                  final capture = CaptureModel.fromFirestore(doc, null);
                  return _convertCaptureToPublicArt(capture);
                }
                return null;
              } catch (e) {
                AppLogger.error('Error parsing capture: $e');
                return null;
              }
            })
            .whereType<PublicArtModel>()
            .where((art) => !discoveredIds.contains(art.id))
            .toList();

        // Combine both lists
        final nearbyArt = [...nearbyPublicArt, ...nearbyCaptures];

        // Sort by proximity
        nearbyArt.sort((a, b) {
          final distA = Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            a.location.latitude,
            a.location.longitude,
          );
          final distB = Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            b.location.latitude,
            b.location.longitude,
          );
          return distA.compareTo(distB);
        });

        yield nearbyArt;
      }
    } catch (e) {
      AppLogger.error('Error watching nearby art: $e');
      yield [];
    }
  }

  /// Calculate distance between user and art
  double calculateDistance(Position userPosition, PublicArtModel art) {
    return Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      art.location.latitude,
      art.location.longitude,
    );
  }

  /// Get proximity message based on distance
  String getProximityMessage(double distanceMeters) {
    if (distanceMeters < 10) {
      return "🔥 You're right on top of it!";
    } else if (distanceMeters < 25) {
      return "🔥 Almost there! Look around!";
    } else if (distanceMeters < 50) {
      return "🌟 Very close! Keep going!";
    } else if (distanceMeters < 100) {
      return "👀 Getting warmer...";
    } else if (distanceMeters < 250) {
      return "🚶 You're on the right track!";
    } else {
      return "🗺️ Head in this direction";
    }
  }

  /// Save a discovery to user's discoveries collection
  Future<String?> saveDiscovery(
    PublicArtModel art,
    Position capturePosition,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Calculate distance from art
      final distance = Geolocator.distanceBetween(
        capturePosition.latitude,
        capturePosition.longitude,
        art.location.latitude,
        art.location.longitude,
      );

      // Create discovery document
      final discoveryData = {
        'userId': userId,
        'publicArtId': art.id,
        'title': art.title,
        'artistName': art.artistName,
        'imageUrl': art.imageUrl,
        'artType': art.artType,
        'location': art.location,
        'captureLocation': GeoPoint(
          capturePosition.latitude,
          capturePosition.longitude,
        ),
        'distance': distance,
        'discoveredAt': FieldValue.serverTimestamp(),
        'isInstantDiscovery': true,
      };

      // Save to user's discoveries subcollection
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('discoveries')
          .add(discoveryData);

      // Invalidate cache
      _discoveredArtIds = null;
      _discoveredArtCacheTime = null;

      // Award XP
      await _awardDiscoveryXP(userId);

      // Update challenge progress
      await _challengeService.recordArtDiscovery();

      // Track time-based discovery (early bird or night owl)
      await _challengeService.recordTimeBasedDiscovery();

      // Track art style discovery if available
      if (art.artType != null && art.artType!.isNotEmpty) {
        await _challengeService.recordStyleDiscovery(art.artType!);
      }

      // Track neighborhood discovery if address is available
      if (art.address != null && art.address!.isNotEmpty) {
        // Extract neighborhood from address (simple approach - use first part)
        final neighborhood = _extractNeighborhood(art.address!);
        if (neighborhood.isNotEmpty) {
          await _challengeService.recordNeighborhoodDiscovery(neighborhood);
        }
      }

      AppLogger.info('✅ Saved discovery: ${art.title}');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Error saving discovery: $e');
      return null;
    }
  }

  /// Award XP for discovery with bonuses
  Future<void> _awardDiscoveryXP(String userId) async {
    try {
      // Check if this is first discovery today
      final isFirstToday = await _isFirstDiscoveryToday(userId);

      if (isFirstToday) {
        // First discovery of the day: +50 XP
        await _rewardsService.awardXP(
          'first_discovery_today',
          customAmount: 50,
        );
      } else {
        // Regular discovery: +20 XP
        await _rewardsService.awardXP('instant_discovery', customAmount: 20);
      }

      // Check for streak bonus
      final streak = await _getDiscoveryStreak(userId);
      if (streak >= 3) {
        // Streak bonus: +10 XP per streak
        await _rewardsService.awardXP(
          'discovery_streak',
          customAmount: 10 * streak,
        );
      }
    } catch (e) {
      AppLogger.error('Error awarding discovery XP: $e');
    }
  }

  /// Check if this is the first discovery today
  Future<bool> _isFirstDiscoveryToday(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('discoveries')
          .where('discoveredAt', isGreaterThanOrEqualTo: startOfDay)
          .limit(1)
          .get();

      return snapshot.docs.isEmpty;
    } catch (e) {
      AppLogger.error('Error checking first discovery: $e');
      return false;
    }
  }

  /// Get current discovery streak
  /// Counts consecutive days with at least one discovery, starting from today or yesterday
  Future<int> _getDiscoveryStreak(String userId) async {
    try {
      // Get discoveries from last 30 days to check for streaks
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('discoveries')
          .where('discoveredAt', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .orderBy('discoveredAt', descending: true)
          .get();

      if (snapshot.docs.isEmpty) return 0;

      // Group discoveries by date (date only, no time)
      final Map<String, bool> discoveryDates = {};
      for (var doc in snapshot.docs) {
        final discoveredAt = (doc.data()['discoveredAt'] as Timestamp).toDate();
        final dateKey =
            '${discoveredAt.year}-${discoveredAt.month.toString().padLeft(2, '0')}-${discoveredAt.day.toString().padLeft(2, '0')}';
        discoveryDates[dateKey] = true;
      }

      // Get today and yesterday as date keys
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayKey =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      // Determine starting point for streak calculation
      int startOffset = 0;
      if (discoveryDates.containsKey(today)) {
        // User has discovered something today, start from today
        startOffset = 0;
      } else if (discoveryDates.containsKey(yesterdayKey)) {
        // No discovery today, but has one yesterday - streak is still active
        startOffset = 1;
      } else {
        // No discoveries today or yesterday - streak is broken
        return 0;
      }

      // Count consecutive days starting from the appropriate date
      int streak = 0;
      for (int i = startOffset; i < 30; i++) {
        final checkDate = now.subtract(Duration(days: i));
        final dateKey =
            '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

        if (discoveryDates.containsKey(dateKey)) {
          streak++;
        } else {
          // Gap found, streak ends
          break;
        }
      }

      return streak;
    } catch (e) {
      AppLogger.error('Error getting discovery streak: $e');
      return 0;
    }
  }

  /// Get list of art IDs user has already discovered
  Future<Set<String>> _getDiscoveredArtIds() async {
    try {
      // Check cache
      if (_discoveredArtIds != null &&
          _discoveredArtCacheTime != null &&
          DateTime.now().difference(_discoveredArtCacheTime!) < _cacheTimeout) {
        return _discoveredArtIds!;
      }

      final userId = _auth.currentUser?.uid;
      if (userId == null) return {};

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('discoveries')
          .get();

      final ids = snapshot.docs
          .map((doc) => doc.data()['publicArtId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet();

      // Update cache
      _discoveredArtIds = ids;
      _discoveredArtCacheTime = DateTime.now();

      return ids;
    } catch (e) {
      AppLogger.error('Error getting discovered art IDs: $e');
      return {};
    }
  }

  /// Check if user has discovered specific art
  Future<bool> hasUserDiscovered(String artId) async {
    final discoveredIds = await _getDiscoveredArtIds();
    return discoveredIds.contains(artId);
  }

  /// Get user's discovery count
  Future<int> getDiscoveryCount() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('discoveries')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Error getting discovery count: $e');
      return 0;
    }
  }

  /// Get user's discoveries
  Future<List<Map<String, dynamic>>> getUserDiscoveries({
    int limit = 20,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('discoveries')
          .orderBy('discoveredAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      AppLogger.error('Error getting user discoveries: $e');
      return [];
    }
  }

  /// Get user progress stats for dashboard
  Future<Map<String, int>> getUserProgressStats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {'totalDiscoveries': 0, 'currentStreak': 0, 'weeklyProgress': 0};
      }

      // Get total discoveries count
      final totalDiscoveries = await getDiscoveryCount();

      // Get current streak
      final streak = await _getDiscoveryStreak(userId);

      // Get weekly progress (discoveries this week)
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDate = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );

      final weeklySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('discoveries')
          .where('discoveredAt', isGreaterThanOrEqualTo: startOfWeekDate)
          .count()
          .get();

      final weeklyProgress = weeklySnapshot.count ?? 0;

      return {
        'totalDiscoveries': totalDiscoveries,
        'currentStreak': streak,
        'weeklyProgress': weeklyProgress,
      };
    } catch (e) {
      AppLogger.error('Error getting user progress stats: $e');
      return {'totalDiscoveries': 0, 'currentStreak': 0, 'weeklyProgress': 0};
    }
  }

  /// Clear cache (useful for testing or manual refresh)
  void clearCache() {
    _discoveredArtIds = null;
    _discoveredArtCacheTime = null;
  }

  /// Monitor location changes and send notifications for nearby art discoveries
  /// Returns a stream that emits notifications when new art is discovered nearby
  Stream<Map<String, dynamic>> monitorNearbyArtNotifications({
    required Position userPosition,
    double notificationRadiusMeters = 100, // Notify when art is within 100m
    Duration checkInterval = const Duration(
      seconds: 30,
    ), // Check every 30 seconds
  }) async* {
    final user = _auth.currentUser;
    if (user == null) return;

    // Keep track of art we've already notified about to avoid spam
    final notifiedArtIds = <String>{};
    final lastNotificationTime = <String, DateTime>{};

    while (true) {
      try {
        // Get nearby art within notification radius
        final nearbyArt = await getNearbyArt(
          userPosition,
          radiusMeters: notificationRadiusMeters,
        );

        // Filter to art we haven't notified about recently
        final now = DateTime.now();
        final newNearbyArt = nearbyArt.where((art) {
          // Skip if we've already notified about this art recently (within last hour)
          final lastNotified = lastNotificationTime[art.id];
          if (lastNotified != null &&
              now.difference(lastNotified).inMinutes < 60) {
            return false;
          }

          // Skip if user has already discovered this art
          if (notifiedArtIds.contains(art.id)) {
            return false;
          }

          return true;
        }).toList();

        // Send notifications for new nearby art
        for (final art in newNearbyArt) {
          final distance = Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            art.location.latitude,
            art.location.longitude,
          );

          // Calculate distance in appropriate units
          final distanceText = distance < 1000
              ? '${distance.round()}m'
              : '${(distance / 1000).toStringAsFixed(1)}km';

          // Send notification
          await NotificationService().sendNotification(
            userId: user.uid,
            title: '🎨 Art Nearby!',
            message:
                '${art.title} is just $distanceText away. Tap to discover!',
            type:
                NotificationType.achievement, // Using achievement type for now
            data: {
              'artId': art.id,
              'latitude': art.location.latitude,
              'longitude': art.location.longitude,
              'distance': distance,
              'notificationType': 'nearby_art',
            },
          );

          // Mark as notified
          notifiedArtIds.add(art.id);
          lastNotificationTime[art.id] = now;

          // Emit notification data for UI updates
          yield {
            'type': 'nearby_art_discovered',
            'art': art.toMap(),
            'distance': distance,
            'distanceText': distanceText,
            'timestamp': now,
          };
        }

        // Wait before next check
        await Future<void>.delayed(checkInterval);
      } catch (e) {
        AppLogger.error('Error monitoring nearby art notifications: $e');
        // Wait a bit longer on error before retrying
        await Future<void>.delayed(const Duration(seconds: 60));
      }
    }
  }

  /// Convert CaptureModel to PublicArtModel for consistency
  PublicArtModel _convertCaptureToPublicArt(CaptureModel capture) {
    return PublicArtModel(
      id: capture.id,
      userId: capture.userId,
      title: capture.title ?? 'Untitled Capture',
      description: capture.description ?? '',
      imageUrl: capture.imageUrl,
      artistName: capture.artistName,
      location: capture.location ?? const GeoPoint(0, 0),
      address: capture.locationName,
      tags: capture.tags ?? [],
      artType: capture.artType,
      isVerified: false, // Captures are not pre-verified
      viewCount: 0, // Captures don't track views in the same way
      likeCount: 0, // Captures don't track likes in the same way
      usersFavorited: [], // Captures don't track favorites in the same way
      createdAt: Timestamp.fromDate(capture.createdAt),
      updatedAt: capture.updatedAt != null
          ? Timestamp.fromDate(capture.updatedAt!)
          : null,
    );
  }

  /// Extract neighborhood name from address string
  /// Addresses typically follow format: "Street, Neighborhood, City, State ZIP"
  /// This extracts the second component (neighborhood) if available
  String _extractNeighborhood(String address) {
    try {
      // Split by comma and trim whitespace
      final parts = address.split(',').map((s) => s.trim()).toList();

      // If we have at least 2 parts, the second one is usually the neighborhood
      // Example: "123 Main St, Downtown, San Francisco, CA 94102"
      // Returns: "Downtown"
      if (parts.length >= 2) {
        final neighborhood = parts[1];
        // Return if it's not empty and doesn't look like a state/zip
        if (neighborhood.isNotEmpty &&
            !RegExp(r'^[A-Z]{2}$').hasMatch(neighborhood) && // Not a state code
            !RegExp(r'^\d{5}').hasMatch(neighborhood)) {
          // Not a ZIP code
          return neighborhood;
        }
      }

      // Fallback: if we only have one part or can't extract neighborhood,
      // use the first part (street name) as a simple identifier
      if (parts.isNotEmpty) {
        return parts[0];
      }

      return '';
    } catch (e) {
      AppLogger.error('Error extracting neighborhood from address: $e');
      return '';
    }
  }
}
