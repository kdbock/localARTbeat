import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Handles Firebase App Check configuration ONLY
class SecureFirebaseConfig {
  const SecureFirebaseConfig._();

  static bool _appCheckInitialized = false;
  static String? _teamId;

  /// Store Team ID (optional, informational only)
  static Future<void> configureAppCheck({required String teamId}) async {
    _teamId = teamId;

    await FirebaseAppCheck.instance.activate(
      providerApple: const AppleAppAttestProvider(), // ✅ Use `const` and correct param
    );

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
