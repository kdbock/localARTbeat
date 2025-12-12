import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/notification_settings_model.dart';
import '../models/privacy_settings_model.dart';

/// Settings service for managing user settings and preferences
class SettingsService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SettingsService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Get settings for the current user
  Future<Map<String, dynamic>> getUserSettings() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore.collection('userSettings').doc(userId).get();

      if (!doc.exists) {
        // Create default settings if they don't exist
        final defaultSettings = {
          'darkMode': false,
          'notificationsEnabled': true,
          'emailNotifications': true,
          'pushNotifications': true,
          'privacySettings': {
            'profileVisibility': 'public',
            'allowMessages': true,
            'showLocation': false,
          },
          'securitySettings': {'twoFactorEnabled': false, 'loginAlerts': true},
        };

        await _firestore
            .collection('userSettings')
            .doc(userId)
            .set(defaultSettings);

        return defaultSettings;
      }

      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error getting user settings: $e');
      rethrow;
    }
  }

  /// Update a specific setting for the current user
  Future<void> updateSetting(String path, dynamic value) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Convert dot notation path to a proper update structure
      final Map<String, dynamic> updateData = {};
      updateData[path] = value;

      await _firestore
          .collection('userSettings')
          .doc(userId)
          .set(updateData, SetOptions(merge: true));

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error updating setting: $e');
      rethrow;
    }
  }

  /// Update user notification preferences
  Future<void> updateNotificationSettings({
    bool? emailNotifications,
    bool? pushNotifications,
    bool? inAppNotifications,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (emailNotifications != null) {
        updates['emailNotifications'] = emailNotifications;
      }

      if (pushNotifications != null) {
        updates['pushNotifications'] = pushNotifications;
      }

      if (inAppNotifications != null) {
        updates['inAppNotifications'] = inAppNotifications;
      }

      if (updates.isNotEmpty) {
        final userId = _auth.currentUser?.uid;
        if (userId == null) {
          throw Exception('User not authenticated');
        }

        await _firestore
            .collection('userSettings')
            .doc(userId)
            .set(updates, SetOptions(merge: true));

        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Error updating notification settings: $e');
      rethrow;
    }
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings({
    String? profileVisibility,
    bool? allowMessages,
    bool? showLocation,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (profileVisibility != null) {
        updates['privacySettings.profileVisibility'] = profileVisibility;
      }

      if (allowMessages != null) {
        updates['privacySettings.allowMessages'] = allowMessages;
      }

      if (showLocation != null) {
        updates['privacySettings.showLocation'] = showLocation;
      }

      if (updates.isNotEmpty) {
        final userId = _auth.currentUser?.uid;
        if (userId == null) {
          throw Exception('User not authenticated');
        }

        await _firestore
            .collection('userSettings')
            .doc(userId)
            .set(updates, SetOptions(merge: true));

        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Error updating privacy settings: $e');
      rethrow;
    }
  }

  /// Get a list of blocked user IDs
  Future<List<String>> getBlockedUsers() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore.collection('userSettings').doc(userId).get();

      if (!doc.exists || !doc.data()!.containsKey('blockedUsers')) {
        return [];
      }

      final blockedUsers = doc.data()!['blockedUsers'] as List<dynamic>;
      return blockedUsers.cast<String>();
    } catch (e) {
      AppLogger.error('Error getting blocked users: $e');
      return [];
    }
  }

  /// Block a user
  Future<void> blockUser(String targetUserId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('userSettings').doc(userId).set({
        'blockedUsers': FieldValue.arrayUnion([targetUserId]),
      }, SetOptions(merge: true));

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

      await _firestore.collection('userSettings').doc(userId).set({
        'blockedUsers': FieldValue.arrayRemove([targetUserId]),
      }, SetOptions(merge: true));

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error unblocking user: $e');
      rethrow;
    }
  }

  /// Get notification settings for the current user
  Future<NotificationSettingsModel> getNotificationSettings() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore
          .collection('userSettings')
          .doc(userId)
          .collection('notifications')
          .doc('preferences')
          .get();

      if (!doc.exists) {
        // Return default settings if they don't exist
        return NotificationSettingsModel.defaultSettings(userId);
      }

      return NotificationSettingsModel.fromFirestore(doc.data()!);
    } catch (e) {
      AppLogger.error('Error getting notification settings: $e');
      rethrow;
    }
  }

  /// Save notification settings for the current user
  Future<void> saveNotificationSettings(
    NotificationSettingsModel settings,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('userSettings')
          .doc(userId)
          .collection('notifications')
          .doc('preferences')
          .set(settings.toFirestore(), SetOptions(merge: true));

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error saving notification settings: $e');
      rethrow;
    }
  }

  /// Get privacy settings for the current user
  Future<PrivacySettingsModel> getPrivacySettings() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      try {
        final doc = await _firestore
            .collection('userSettings')
            .doc(userId)
            .collection('privacy')
            .doc('preferences')
            .get()
            .timeout(const Duration(seconds: 10));

        if (!doc.exists) {
          AppLogger.info(
            'No privacy settings found for user $userId - creating defaults',
          );
          return PrivacySettingsModel.defaultSettings(userId);
        }

        return PrivacySettingsModel.fromFirestore(doc.data()!);
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          AppLogger.warning(
            'Permission denied accessing privacy settings - returning defaults',
          );
          return PrivacySettingsModel.defaultSettings(userId);
        } else if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
          AppLogger.warning(
            'Firestore unavailable or timeout - returning defaults',
          );
          return PrivacySettingsModel.defaultSettings(userId);
        }
        rethrow;
      }
    } catch (e) {
      AppLogger.error('Error getting privacy settings: $e');
      rethrow;
    }
  }

  /// Save privacy settings for the current user
  Future<void> savePrivacySettings(PrivacySettingsModel settings) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('userSettings')
          .doc(userId)
          .collection('privacy')
          .doc('preferences')
          .set(settings.toFirestore(), SetOptions(merge: true));

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error saving privacy settings: $e');
      rethrow;
    }
  }

  /// Request user data download (GDPR compliance)
  Future<void> requestDataDownload() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create a data export request
      await _firestore.collection('dataExportRequests').add({
        'userId': userId,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': 'download',
      });

      AppLogger.info('Data download request created for user: $userId');
    } catch (e) {
      AppLogger.error('Error requesting data download: $e');
      rethrow;
    }
  }

  /// Request user data deletion (GDPR compliance)
  Future<void> requestDataDeletion() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create a data deletion request
      await _firestore.collection('dataDeletionRequests').add({
        'userId': userId,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': 'deletion',
      });

      AppLogger.info('Data deletion request created for user: $userId');
    } catch (e) {
      AppLogger.error('Error requesting data deletion: $e');
      rethrow;
    }
  }
}
