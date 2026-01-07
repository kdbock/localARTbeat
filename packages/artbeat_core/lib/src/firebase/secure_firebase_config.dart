
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Handles Firebase App Check configuration ONLY
class SecureFirebaseConfig {
  const SecureFirebaseConfig._();

  static bool _appCheckInitialized = false;
  static String? _teamId;

  /// Store Team ID (optional, informational only)
  static Future<void> configureAppCheck({required String teamId}) async {
    _teamId = teamId;

    try {
      // On simulator/dev use debug provider to avoid App Attest failures (403)
      const bool useDebugProvider = kDebugMode;

      if (useDebugProvider) {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
        debugPrint('🔐 AppCheck initialized in DEBUG mode');
      } else {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
        );
        debugPrint('🔐 AppCheck initialized with Attest/Integrity');
      }
    } catch (e) {
      debugPrint('⚠️ AppCheck activation failed: $e');
    }

    _appCheckInitialized = true;
  }

  /// Debug helpers (safe)
  static Map<String, dynamic> getStatus() => {
    'appCheckInitialized': _appCheckInitialized,
    'appsCount': 0, // intentionally not reading Firebase.apps here
    'teamId': _teamId,
  };

  static Future<bool> testStorageAccess() async {
    try {
      await FirebaseStorage.instance.ref('test').listAll();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> validateAppCheck() async {
    return {
      'initialized': _appCheckInitialized,
      'disabled': !_appCheckInitialized,
    };
  }
}
