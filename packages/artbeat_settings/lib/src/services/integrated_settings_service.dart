import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Production-ready integrated settings service with caching and performance optimization
/// Implementation Date: September 5, 2025
class IntegratedSettingsService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Cache management
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Stream subscriptions for real-time updates
  StreamSubscription<DocumentSnapshot>? _userSettingsSubscription;
  StreamSubscription<DocumentSnapshot>? _accountSettingsSubscription;

  // Performance tracking
  int _cacheHits = 0;
  int _cacheMisses = 0;

  IntegratedSettingsService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance {
    _initializeService();
  }

  /// Initialize the service with caching and listeners
  Future<void> _initializeService() async {
    _setupRealtimeListeners();
  }

  /// Set up real-time listeners for settings changes
  void _setupRealtimeListeners() {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      _userSettingsSubscription?.cancel();
      _userSettingsSubscription = _firestore
          .collection('userSettings')
          .doc(userId)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists) {
              _invalidateCache();
              notifyListeners();
            }
          });

      _accountSettingsSubscription?.cancel();
      _accountSettingsSubscription = _firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .listen((_) {
            _invalidateCache('accountSettings');
            notifyListeners();
          });
    }
  }

  /// Performance metrics getter
  Map<String, dynamic> get performanceMetrics => {
    'cacheHits': _cacheHits,
    'cacheMisses': _cacheMisses,
    'hitRatio': _cacheHits / (_cacheHits + _cacheMisses),
    'cachedItems': _cache.length,
  };

  /// Generic cache management
  T? _getCached<T>(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null &&
        DateTime.now().difference(timestamp) < _cacheExpiry) {
      _cacheHits++;
      return _cache[key] as T?;
    }
    _cacheMisses++;
    return null;
  }

  void _setCached(String key, dynamic value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  void _invalidateCache([String? specificKey]) {
    if (specificKey != null) {
      _cache.remove(specificKey);
      _cacheTimestamps.remove(specificKey);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }

  /// Get comprehensive user settings with caching
  Future<UserSettingsModel> getUserSettings() async {
    const cacheKey = 'userSettings';

    // Try cache first
    final cached = _getCached<UserSettingsModel>(cacheKey);
    if (cached != null) return cached;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore.collection('userSettings').doc(userId).get();

      UserSettingsModel settings;
      if (!doc.exists) {
        // Create default settings
        settings = UserSettingsModel.defaultSettings(userId);
        await _createDefaultUserSettings(settings);
      } else {
        settings = UserSettingsModel.fromMap(doc.data()!);
      }

      // Cache the result
      _setCached(cacheKey, settings);
      return settings;
    } catch (e) {
      AppLogger.error('Error getting user settings: $e');
      rethrow;
    }
  }

  /// Create default user settings in Firestore
  Future<void> _createDefaultUserSettings(UserSettingsModel settings) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('userSettings')
        .doc(userId)
        .set(settings.toMap());
  }

  /// Update user settings with optimistic updates and caching
  Future<void> updateUserSettings(UserSettingsModel settings) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Optimistic update - update cache immediately
      _setCached('userSettings', settings);
      notifyListeners();

      // Update Firestore
      await _firestore
          .collection('userSettings')
          .doc(userId)
          .set(settings.toMap(), SetOptions(merge: true));
    } catch (e) {
      // Revert optimistic update on error
      _invalidateCache('userSettings');
      AppLogger.error('Error updating user settings: $e');
      rethrow;
    }
  }

  /// Get notification settings with caching
  Future<NotificationSettingsModel> getNotificationSettings() async {
    const cacheKey = 'notificationSettings';

    final cached = _getCached<NotificationSettingsModel>(cacheKey);
    if (cached != null) return cached;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore
          .collection('notificationSettings')
          .doc(userId)
          .get();

      NotificationSettingsModel settings;
      if (!doc.exists) {
        settings = NotificationSettingsModel.defaultSettings(userId);
        await _firestore
            .collection('notificationSettings')
            .doc(userId)
            .set(settings.toMap());
      } else {
        settings = NotificationSettingsModel.fromMap(doc.data()!);
      }

      _setCached(cacheKey, settings);
      return settings;
    } catch (e) {
      AppLogger.error('Error getting notification settings: $e');
      rethrow;
    }
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(
    NotificationSettingsModel settings,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Optimistic update
      _setCached('notificationSettings', settings);
      notifyListeners();

      await _firestore
          .collection('notificationSettings')
          .doc(userId)
          .set(settings.toMap(), SetOptions(merge: true));
    } catch (e) {
      _invalidateCache('notificationSettings');
      AppLogger.error('Error updating notification settings: $e');
      rethrow;
    }
  }

  /// Get privacy settings with caching
  Future<PrivacySettingsModel> getPrivacySettings() async {
    const cacheKey = 'privacySettings';

    final cached = _getCached<PrivacySettingsModel>(cacheKey);
    if (cached != null) return cached;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore
          .collection('privacySettings')
          .doc(userId)
          .get();

      PrivacySettingsModel settings;
      if (!doc.exists) {
        settings = PrivacySettingsModel.defaultSettings(userId);
        await _firestore
            .collection('privacySettings')
            .doc(userId)
            .set(settings.toMap());
      } else {
        settings = PrivacySettingsModel.fromMap(doc.data()!);
      }

      _setCached(cacheKey, settings);
      return settings;
    } catch (e) {
      AppLogger.error('Error getting privacy settings: $e');
      rethrow;
    }
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings(PrivacySettingsModel settings) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Optimistic update
      _setCached('privacySettings', settings);
      notifyListeners();

      await _firestore
          .collection('privacySettings')
          .doc(userId)
          .set(settings.toMap(), SetOptions(merge: true));
    } catch (e) {
      _invalidateCache('privacySettings');
      AppLogger.error('Error updating privacy settings: $e');
      rethrow;
    }
  }

  /// Get security settings with caching
  Future<SecuritySettingsModel> getSecuritySettings() async {
    const cacheKey = 'securitySettings';

    final cached = _getCached<SecuritySettingsModel>(cacheKey);
    if (cached != null) return cached;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore
          .collection('securitySettings')
          .doc(userId)
          .get();

      SecuritySettingsModel settings;
      if (!doc.exists) {
        settings = SecuritySettingsModel.defaultSettings(userId);
        await _firestore
            .collection('securitySettings')
            .doc(userId)
            .set(settings.toMap());
      } else {
        settings = SecuritySettingsModel.fromMap(doc.data()!);
      }

      _setCached(cacheKey, settings);
      return settings;
    } catch (e) {
      AppLogger.error('Error getting security settings: $e');
      rethrow;
    }
  }

  /// Update security settings
  Future<void> updateSecuritySettings(SecuritySettingsModel settings) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Optimistic update
      _setCached('securitySettings', settings);
      notifyListeners();

      await _firestore
          .collection('securitySettings')
          .doc(userId)
          .set(settings.toMap(), SetOptions(merge: true));
    } catch (e) {
      _invalidateCache('securitySettings');
      AppLogger.error('Error updating security settings: $e');
      rethrow;
    }
  }

  /// Get account settings with caching
  Future<AccountSettingsModel> getAccountSettings() async {
    const cacheKey = 'accountSettings';

    final cached = _getCached<AccountSettingsModel>(cacheKey);
    if (cached != null) return cached;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore.collection('users').doc(userId).get();
      final authUser = _auth.currentUser;

      AccountSettingsModel settings;
      if (!doc.exists) {
        final user = authUser!;
        settings = AccountSettingsModel(
          userId: userId,
          email: user.email ?? '',
          username: '',
          displayName: user.displayName ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _firestore
            .collection('users')
            .doc(userId)
            .set(
              _buildAccountSettingsPayload(settings),
              SetOptions(merge: true),
            );
      } else {
        settings = AccountSettingsModel.fromUserDocument(
          doc.data()!,
          authUser: authUser,
        );
      }

      _setCached(cacheKey, settings);
      return settings;
    } catch (e) {
      AppLogger.error('Error getting account settings: $e');
      rethrow;
    }
  }

  /// Update account settings
  Future<void> updateAccountSettings(AccountSettingsModel settings) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Optimistic update
      _setCached('accountSettings', settings);
      notifyListeners();

      await _firestore
          .collection('users')
          .doc(userId)
          .set(_buildAccountSettingsPayload(settings), SetOptions(merge: true));
    } catch (e) {
      _invalidateCache('accountSettings');
      AppLogger.error('Error updating account settings: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _buildAccountSettingsPayload(
    AccountSettingsModel settings,
  ) {
    return {
      'userId': settings.userId,
      'email': settings.email,
      'username': settings.username,
      'displayName': settings.displayName,
      'fullName': settings.displayName,
      'phoneNumber': settings.phoneNumber,
      'profileImageUrl': settings.profileImageUrl,
      'bio': settings.bio,
      'emailVerified': settings.emailVerified,
      'phoneVerified': settings.phoneVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Get blocked users with caching
  Future<List<BlockedUserModel>> getBlockedUsers() async {
    const cacheKey = 'blockedUsers';

    final cached = _getCached<List<BlockedUserModel>>(cacheKey);
    if (cached != null) return cached;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Use the same structure as ModerationService: users/{userId}/blockedUsers
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('blockedUsers')
          .get();

      final blockedUsers = <BlockedUserModel>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final blockedUserId = data['blockedUserId'] as String;
        final blockedAt =
            (data['blockedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

        // First try to get stored user name from block relationship
        String userName = data['blockedUserName'] as String? ?? '';
        String profileImage = '';

        // If no stored name, fetch from users collection
        if (userName.isEmpty) {
          try {
            final userDoc = await _firestore
                .collection('users')
                .doc(blockedUserId)
                .get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              AppLogger.info(
                '🔍 Fetching user data for blocked user $blockedUserId: ${userData.keys}',
              );

              // Use same priority as community service
              userName =
                  userData['fullName'] as String? ??
                  userData['displayName'] as String? ??
                  userData['name'] as String? ??
                  'Unknown User';
              profileImage = userData['profileImage'] as String? ?? '';

              AppLogger.info('📝 Resolved blocked user name: $userName');
            }
          } catch (e) {
            AppLogger.error(
              '⚠️ Could not fetch user details for blocked user $blockedUserId: $e',
            );
            userName = 'Unknown User';
          }
        }

        blockedUsers.add(
          BlockedUserModel(
            blockedUserId: blockedUserId,
            blockedUserName: userName,
            blockedAt: blockedAt,
            reason: (data['reason'] ?? '') as String,
            blockedBy: userId,
            blockedUserProfileImage: profileImage,
          ),
        );
      }

      // Sort by blocked date, most recent first
      blockedUsers.sort((a, b) => b.blockedAt.compareTo(a.blockedAt));

      _setCached(cacheKey, blockedUsers);
      return blockedUsers;
    } catch (e) {
      AppLogger.error('Error getting blocked users: $e');
      return [];
    }
  }

  /// Block a user
  Future<void> blockUser(
    String targetUserId,
    String targetUserName,
    String reason,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Use the same structure as ModerationService: users/{userId}/blockedUsers/{targetUserId}
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('blockedUsers')
          .doc(targetUserId)
          .set({
            'blockedUserId': targetUserId,
            'blockedAt': FieldValue.serverTimestamp(),
            'reason': reason,
            'blockedUserName': targetUserName,
          });

      // Invalidate cache to force refresh
      _invalidateCache('blockedUsers');
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error blocking user: $e');
      rethrow;
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String targetUserId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Use the same structure as ModerationService: users/{userId}/blockedUsers/{targetUserId}
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('blockedUsers')
          .doc(targetUserId)
          .delete();

      // Invalidate cache to force refresh
      _invalidateCache('blockedUsers');
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error unblocking user: $e');
      rethrow;
    }
  }

  /// Get device activity with caching
  Future<List<DeviceActivityModel>> getDeviceActivity() async {
    const cacheKey = 'deviceActivity';

    final cached = _getCached<List<DeviceActivityModel>>(cacheKey);
    if (cached != null) return cached;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('deviceActivity')
          .where('userId', isEqualTo: userId)
          .orderBy('lastActive', descending: true)
          .limit(20)
          .get();

      final devices = querySnapshot.docs
          .map((doc) => DeviceActivityModel.fromMap(doc.data()))
          .toList();

      _setCached(cacheKey, devices);
      return devices;
    } catch (e) {
      AppLogger.error('Error getting device activity: $e');
      return [];
    }
  }

  /// Log device activity
  Future<void> logDeviceActivity(DeviceActivityModel activity) async {
    try {
      await _firestore
          .collection('deviceActivity')
          .doc(activity.deviceId)
          .set(activity.toMap(), SetOptions(merge: true));

      // Invalidate cache to force refresh
      _invalidateCache('deviceActivity');
    } catch (e) {
      AppLogger.error('Error logging device activity: $e');
    }
  }

  /// Request data download (GDPR compliance)
  Future<void> requestDataDownload() async {
    await _createDataRequest('download');
  }

  /// Request data deletion (GDPR compliance)
  Future<void> requestDataDeletion() async {
    await _createDataRequest('deletion');
  }

  Future<void> _createDataRequest(String requestType) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      final now = DateTime.now().toUtc();
      final acknowledgementDueAt = Timestamp.fromDate(
        now.add(const Duration(hours: 72)),
      );
      final completionDueAt = Timestamp.fromDate(
        now.add(const Duration(days: 30)),
      );

      final existingPending = await _firestore
          .collection('dataRequests')
          .where('userId', isEqualTo: userId)
          .where('requestType', isEqualTo: requestType)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (existingPending.docs.isNotEmpty) {
        throw Exception(
          'You already have a pending $requestType request. Please wait for processing.',
        );
      }

      await _firestore.collection('dataRequests').add({
        'userId': userId,
        'requestType': requestType,
        'type': requestType,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'submittedVia': 'privacy_settings',
        'slaAcknowledgementHours': 72,
        'slaAcknowledgementDueAt': acknowledgementDueAt,
        'slaCompletionDays': 30,
        'slaCompletionDueAt': completionDueAt,
        'acknowledgedAt': null,
        'fulfilledAt': null,
        'deniedAt': null,
        'reviewedBy': null,
        'reviewNotes': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Error requesting data $requestType request: $e');
      rethrow;
    }
  }

  /// Preload all settings for performance
  Future<void> preloadAllSettings() async {
    try {
      await Future.wait([
        getUserSettings(),
        getNotificationSettings(),
        getPrivacySettings(),
        getSecuritySettings(),
        getAccountSettings(),
        getBlockedUsers(),
        getDeviceActivity(),
      ]);
    } catch (e) {
      AppLogger.error('Error preloading settings: $e');
    }
  }

  /// Clear all cached data
  void clearCache() {
    _invalidateCache();
    notifyListeners();
  }

  @override
  void dispose() {
    _userSettingsSubscription?.cancel();
    _accountSettingsSubscription?.cancel();
    super.dispose();
  }
}
