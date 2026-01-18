
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Handles Firebase App Check configuration ONLY
class SecureFirebaseConfig {
  const SecureFirebaseConfig._();

  static bool _appCheckInitialized = false;
  static String? _teamId;

  /// Configure App Check with optional business verification
  static Future<void> configureAppCheck({
    required String teamId,
    bool forceDebug = false,
  }) async {
    _teamId = teamId;

    try {
      // If forceDebug is true, use debug provider even in release mode
      // This is helpful for developers without business registration
      final bool useDebugProvider = kDebugMode || forceDebug;

      if (useDebugProvider) {
        await FirebaseAppCheck.instance.activate(
          // ignore: deprecated_member_use
          androidProvider: AndroidProvider.debug,
          // ignore: deprecated_member_use
          appleProvider: AppleProvider.debug,
        );
        debugPrint('🛡️ AppCheck activated with DEBUG provider');
      } else {
        await FirebaseAppCheck.instance.activate(
          // ignore: deprecated_member_use
          androidProvider: AndroidProvider.playIntegrity,
          // ignore: deprecated_member_use
          appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
        );
        debugPrint('🛡️ AppCheck activated with PRODUCTION providers');
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
