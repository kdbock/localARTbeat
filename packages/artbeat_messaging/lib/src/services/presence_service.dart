import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:artbeat_core/artbeat_core.dart';

/// Service to handle user presence (online/offline status)
class PresenceService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  Timer? _presenceTimer;
  StreamSubscription<User?>? _authSubscription;
  bool _isOnline = false;
  DateTime? _lastDebugLog;

  PresenceService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance {
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _startPresenceUpdates();
      } else {
        _stopPresenceUpdates();
      }
    });
  }

  /// Start updating user presence
  void _startPresenceUpdates() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    AppLogger.info(
      'PresenceService: Starting presence updates for user $userId',
    );

    // Set user as online immediately
    _setUserOnline(userId);

    // Update presence every 30 seconds
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _setUserOnline(userId);
    });

    _isOnline = true;

    // Debug: Check if user appears in online list after a short delay
    Timer(const Duration(seconds: 3), () {
      _debugCheckOnlineStatus(userId);
    });
  }

  /// Stop updating user presence
  void _stopPresenceUpdates() {
    final userId = _auth.currentUser?.uid;
    if (userId != null && _isOnline) {
      _setUserOffline(userId);
    }

    _presenceTimer?.cancel();
    _presenceTimer = null;
    _isOnline = false;

    AppLogger.info('PresenceService: Stopped presence updates');
  }

  /// Set user as online
  Future<void> _setUserOnline(String userId) async {
    try {
      // Check if user document exists, create if not
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        // Create basic user document
        final user = _auth.currentUser;
        await _firestore.collection('users').doc(userId).set({
          'uid': userId,
          'email': user?.email,
          'displayName': user?.displayName,
          'photoUrl': user?.photoURL,
          'isOnline': true,
          'lastSeen': Timestamp.now(),
          'lastActive': Timestamp.now(),
          'createdAt': Timestamp.now(),
        });
        AppLogger.info('PresenceService: Created user document for $userId');
      } else {
        // Update existing user document
        await _firestore.collection('users').doc(userId).update({
          'isOnline': true,
          'lastSeen': Timestamp.now(),
          'lastActive': Timestamp.now(),
        });
      }

      // Also update artist profile if exists
      await _updateArtistProfileOnlineStatus(userId, true);

      AppLogger.info('PresenceService: Set user $userId as online');
    } catch (e) {
      AppLogger.error('PresenceService: Error setting user online: $e');
    }
  }

  /// Set user as offline
  Future<void> _setUserOffline(String userId) async {
    try {
      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'isOnline': false,
        'lastSeen': Timestamp.now(),
        'lastActive': Timestamp.now(),
      });

      // Also update artist profile if exists
      await _updateArtistProfileOnlineStatus(userId, false);

      AppLogger.info('PresenceService: Set user $userId as offline');
    } catch (e) {
      AppLogger.error('PresenceService: Error setting user offline: $e');
    }
  }

  /// Update artist profile online status if the user has an artist profile
  Future<void> _updateArtistProfileOnlineStatus(
    String userId,
    bool isOnline,
  ) async {
    try {
      // Check if user has an artist profile
      final artistProfileQuery = await _firestore
          .collection('artistProfiles')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (artistProfileQuery.docs.isNotEmpty) {
        final artistProfileDoc = artistProfileQuery.docs.first;
        if (kDebugMode) {
          debugPrint(
            'PresenceService: Updated artist profile ${artistProfileDoc.id} online status to $isOnline',
          );
        }
      }
    } catch (e) {
      debugPrint(
        'PresenceService: Error updating artist profile online status: $e',
      );
    }
  }

  /// Debug method to check online status (only logs when there are issues)
  Future<void> _debugCheckOnlineStatus(String userId) async {
    try {
      // Check user document
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        debugPrint(
          'PresenceService Debug: User document does not exist for $userId',
        );
        return;
      }

      // Check artist profile
      final artistQuery = await _firestore
          .collection('artistProfiles')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (artistQuery.docs.isEmpty) {
        debugPrint(
          'PresenceService Debug: No artist profile found for $userId',
        );
      }

      // Only log counts periodically to avoid spam
      final now = DateTime.now();
      if (_lastDebugLog == null ||
          now.difference(_lastDebugLog!).inMinutes >= 5) {
        _lastDebugLog = now;

        final onlineUsersQuery = await _firestore
            .collection('users')
            .where('isOnline', isEqualTo: true)
            .get()
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                throw TimeoutException('Online users query timed out');
              },
            );

        final onlineArtistsQuery = await _firestore
            .collection('artistProfiles')
            .where('isOnline', isEqualTo: true)
            .get()
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                throw TimeoutException('Online artists query timed out');
              },
            );

        debugPrint(
          'PresenceService Debug: Total online users: ${onlineUsersQuery.docs.length}',
        );
        debugPrint(
          'PresenceService Debug: Total online artists: ${onlineArtistsQuery.docs.length}',
        );
      }
    } catch (e) {
      AppLogger.error('PresenceService Debug: Error checking status: $e');
    }
  }

  /// Manually update user activity (call when user interacts with the app)
  Future<void> updateActivity() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Check if user document exists, create if not
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        // Create basic user document
        final user = _auth.currentUser;
        await _firestore.collection('users').doc(userId).set({
          'uid': userId,
          'email': user?.email,
          'displayName': user?.displayName,
          'photoUrl': user?.photoURL,
          'isOnline': true,
          'lastSeen': Timestamp.now(),
          'lastActive': Timestamp.now(),
          'createdAt': Timestamp.now(),
        });
        debugPrint(
          'PresenceService: Created user document for $userId during activity update',
        );
      } else {
        // Update existing user document
        await _firestore.collection('users').doc(userId).update({
          'isOnline': true,
          'lastSeen': Timestamp.now(),
          'lastActive': Timestamp.now(),
        });
      }

      // Also update artist profile if exists
      await _updateArtistProfileOnlineStatus(userId, true);
    } catch (e) {
      AppLogger.error('PresenceService: Error updating activity: $e');
    }
  }

  /// Get online users stream
  Stream<List<Map<String, dynamic>>> getOnlineUsersStream() {
    return _firestore
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .orderBy('lastSeen', descending: true)
        .limit(20)
        .snapshots()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: (sink) {
            AppLogger.warning('⚠️ getOnlineUsersStream timed out');
            sink.close();
          },
        )
        .map((snapshot) {
          final currentUserId = _auth.currentUser?.uid;
          final now = DateTime.now();

          return snapshot.docs
              .where((doc) => doc.id != currentUserId) // Exclude current user
              .where((doc) {
                // Filter out users who haven't been seen in more than 5 minutes
                final data = doc.data();
                final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
                if (lastSeen != null) {
                  final difference = now.difference(lastSeen);
                  return difference.inMinutes <=
                      5; // Only keep users active within 5 minutes
                }
                return true; // Keep if no lastSeen (shouldn't happen, but safe default)
              })
              .map((doc) {
                final data = doc.data();
                return {
                  'id': doc.id,
                  'name':
                      data['displayName'] ??
                      data['fullName'] ??
                      data['username'] ??
                      'Unknown User',
                  'avatar': data['photoUrl'] ?? data['profileImageUrl'],
                  'isOnline': data['isOnline'] ?? false,
                  'lastSeen':
                      (data['lastSeen'] as Timestamp?)?.toDate() ??
                      DateTime.now(),
                  'role': data['role'] ?? 'User',
                };
              })
              .toList();
        });
  }

  /// Check if a specific user is online
  Future<bool> isUserOnline(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final isOnline = data['isOnline'] as bool? ?? false;
      final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();

      // Consider user offline if last seen was more than 5 minutes ago
      if (lastSeen != null) {
        final now = DateTime.now();
        final difference = now.difference(lastSeen);
        if (difference.inMinutes > 5) {
          return false;
        }
      }

      return isOnline;
    } catch (e) {
      AppLogger.error('PresenceService: Error checking if user is online: $e');
      return false;
    }
  }

  /// Get user's last seen time
  Future<DateTime?> getUserLastSeen(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return (data['lastSeen'] as Timestamp?)?.toDate() ??
          (data['lastActive'] as Timestamp?)?.toDate();
    } catch (e) {
      AppLogger.error('PresenceService: Error getting user last seen: $e');
      return null;
    }
  }

  /// Force immediate presence update and debug check (for testing)
  Future<void> forcePresenceUpdate() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      AppLogger.auth('PresenceService: No authenticated user for force update');
      return;
    }

    AppLogger.info('PresenceService: Force updating presence for $userId');
    await _setUserOnline(userId);
    await _debugCheckOnlineStatus(userId);
  }

  /// Dispose the service
  void dispose() {
    AppLogger.info('PresenceService: Disposing');
    _stopPresenceUpdates();
    _authSubscription?.cancel();
  }
}
