import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_settings_model.dart';

/// Service for admin settings operations
class AdminSettingsService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AdminSettingsService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  static const String _settingsDocId = 'app_settings';

  /// Get current admin settings
  Future<AdminSettingsModel> getSettings() async {
    try {
      final doc = await _firestore
          .collection('admin_settings')
          .doc(_settingsDocId)
          .get();

      if (doc.exists) {
        return AdminSettingsModel.fromDocument(doc);
      } else {
        // Create default settings if none exist
        final defaultSettings = AdminSettingsModel.defaultSettings();
        await _firestore
            .collection('admin_settings')
            .doc(_settingsDocId)
            .set(defaultSettings.toDocument());
        return defaultSettings;
      }
    } catch (e) {
      throw Exception('Failed to get settings: $e');
    }
  }

  /// Update admin settings
  Future<void> updateSettings(AdminSettingsModel settings) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final updatedSettings = settings.copyWith(
        lastUpdated: DateTime.now(),
        updatedBy: user.uid,
      );

      await _firestore
          .collection('admin_settings')
          .doc(_settingsDocId)
          .set(updatedSettings.toDocument());

      // Log the settings change
      await _logSettingsChange(user.uid, settings);
    } catch (e) {
      throw Exception('Failed to update settings: $e');
    }
  }

  /// Reset settings to default values
  Future<void> resetSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final defaultSettings = AdminSettingsModel.defaultSettings().copyWith(
        lastUpdated: DateTime.now(),
        updatedBy: user.uid,
      );

      await _firestore
          .collection('admin_settings')
          .doc(_settingsDocId)
          .set(defaultSettings.toDocument());

      // Log the settings reset
      await _logSettingsReset(user.uid);
    } catch (e) {
      throw Exception('Failed to reset settings: $e');
    }
  }

  /// Get a specific setting value
  Future<T?> getSetting<T>(String key) async {
    try {
      final doc = await _firestore
          .collection('admin_settings')
          .doc(_settingsDocId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return data?[key] as T?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get setting: $e');
    }
  }

  /// Update a specific setting
  Future<void> updateSetting<T>(String key, T value) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('admin_settings').doc(_settingsDocId).update({
        key: value,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': user.uid,
      });

      // Log the individual setting change
      await _logIndividualSettingChange(user.uid, key, value);
    } catch (e) {
      throw Exception('Failed to update setting: $e');
    }
  }

  /// Check if maintenance mode is enabled
  Future<bool> isMaintenanceModeEnabled() async {
    try {
      final maintenanceMode = await getSetting<bool>('maintenanceMode');
      return maintenanceMode ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if registration is enabled
  Future<bool> isRegistrationEnabled() async {
    try {
      final registrationEnabled = await getSetting<bool>('registrationEnabled');
      return registrationEnabled ?? true;
    } catch (e) {
      return true;
    }
  }

  /// Get maintenance message
  Future<String> getMaintenanceMessage() async {
    try {
      final message = await getSetting<String>('maintenanceMessage');
      return message ?? 'System under maintenance. Please try again later.';
    } catch (e) {
      return 'System under maintenance. Please try again later.';
    }
  }

  /// Get banned words list
  Future<List<String>> getBannedWords() async {
    try {
      final bannedWords = await getSetting<List<dynamic>>('bannedWords');
      return bannedWords?.cast<String>() ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Add banned word
  Future<void> addBannedWord(String word) async {
    try {
      final currentWords = await getBannedWords();
      if (!currentWords.contains(word.toLowerCase())) {
        currentWords.add(word.toLowerCase());
        await updateSetting('bannedWords', currentWords);
      }
    } catch (e) {
      throw Exception('Failed to add banned word: $e');
    }
  }

  /// Remove banned word
  Future<void> removeBannedWord(String word) async {
    try {
      final currentWords = await getBannedWords();
      currentWords.remove(word.toLowerCase());
      await updateSetting('bannedWords', currentWords);
    } catch (e) {
      throw Exception('Failed to remove banned word: $e');
    }
  }

  /// Get settings history
  Future<List<Map<String, dynamic>>> getSettingsHistory({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('admin_settings_logs')
          .orderBy('timestamp', descending: true);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to get settings history: $e');
    }
  }

  /// Export settings
  Future<Map<String, dynamic>> exportSettings() async {
    try {
      final settings = await getSettings();
      return {
        'settings': settings.toDocument(),
        'exportedAt': DateTime.now().toIso8601String(),
        'exportedBy': _auth.currentUser?.uid ?? 'unknown',
      };
    } catch (e) {
      throw Exception('Failed to export settings: $e');
    }
  }

  /// Import settings
  Future<void> importSettings(Map<String, dynamic> settingsData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate settings data
      if (!settingsData.containsKey('settings')) {
        throw Exception('Invalid settings data format');
      }

      final settingsMap = settingsData['settings'] as Map<String, dynamic>;

      // Update timestamps
      settingsMap['lastUpdated'] = FieldValue.serverTimestamp();
      settingsMap['updatedBy'] = user.uid;

      await _firestore
          .collection('admin_settings')
          .doc(_settingsDocId)
          .set(settingsMap);

      // Log the import
      await _logSettingsImport(user.uid);
    } catch (e) {
      throw Exception('Failed to import settings: $e');
    }
  }

  /// Log settings change
  Future<void> _logSettingsChange(
      String userId, AdminSettingsModel settings) async {
    try {
      await _firestore.collection('admin_settings_logs').add({
        'action': 'settings_updated',
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'details': {
          'settingsSnapshot': settings.toDocument(),
        },
      });
    } catch (e) {
      // Error logging intentionally suppressed in production
    }
  }

  /// Log settings reset
  Future<void> _logSettingsReset(String userId) async {
    try {
      await _firestore.collection('admin_settings_logs').add({
        'action': 'settings_reset',
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'details': {
          'message': 'Settings reset to default values',
        },
      });
    } catch (e) {
      // Error logging intentionally suppressed in production
    }
  }

  /// Log individual setting change
  Future<void> _logIndividualSettingChange(
      String userId, String key, dynamic value) async {
    try {
      await _firestore.collection('admin_settings_logs').add({
        'action': 'individual_setting_updated',
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'details': {
          'settingKey': key,
          'newValue': value,
        },
      });
    } catch (e) {
      // Error logging intentionally suppressed in production
    }
  }

  /// Log settings import
  Future<void> _logSettingsImport(String userId) async {
    try {
      await _firestore.collection('admin_settings_logs').add({
        'action': 'settings_imported',
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'details': {
          'message': 'Settings imported from external source',
        },
      });
    } catch (e) {
      // Error logging intentionally suppressed in production
    }
  }

  /// Backup settings
  Future<void> backupSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final settings = await getSettings();

      await _firestore.collection('admin_settings_backups').add({
        'settings': settings.toDocument(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
      });
    } catch (e) {
      throw Exception('Failed to backup settings: $e');
    }
  }

  /// Restore settings from backup
  Future<void> restoreSettingsFromBackup(String backupId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final backupDoc = await _firestore
          .collection('admin_settings_backups')
          .doc(backupId)
          .get();

      if (!backupDoc.exists) {
        throw Exception('Backup not found');
      }

      final backupData = backupDoc.data() as Map<String, dynamic>;
      final settingsData = backupData['settings'] as Map<String, dynamic>;

      // Update timestamps
      settingsData['lastUpdated'] = FieldValue.serverTimestamp();
      settingsData['updatedBy'] = user.uid;

      await _firestore
          .collection('admin_settings')
          .doc(_settingsDocId)
          .set(settingsData);

      // Log the restoration
      await _firestore.collection('admin_settings_logs').add({
        'action': 'settings_restored',
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'details': {
          'backupId': backupId,
          'message': 'Settings restored from backup',
        },
      });
    } catch (e) {
      throw Exception('Failed to restore settings from backup: $e');
    }
  }
}
