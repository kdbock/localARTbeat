import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Handles Firebase App Check configuration ONLY
class SecureFirebaseConfig {
  const SecureFirebaseConfig._();

  static bool _appCheckInitialized = false;
  static String? _teamId;
  static String? _lastProviderMode;

  /// Configure App Check with optional debug override.
  ///
  /// Notes (current FlutterFire API):
  /// - `appleProvider` / `androidProvider` enums are deprecated.
  /// - Use `providerApple` / `providerAndroid` with provider classes instead.
  /// - Optionally pass a fixed debug token via [debugToken] to keep it stable.
  static Future<void> configureAppCheck({
    required String teamId,
    bool forceDebug = false,
    String? debugToken, // optional: set a stable debug token if you want
  }) async {
    _teamId = teamId;

    // Prevent duplicate initialization
    if (_appCheckInitialized) {
      debugPrint('🛡️ App Check already initialized, skipping...');
      return;
    }

    final bool useDebugProvider = kDebugMode || forceDebug;

    try {
      debugPrint('🛡️ ============================================');
      if (useDebugProvider) {
        _lastProviderMode = 'debug';
        debugPrint('🛡️ ACTIVATING APP CHECK IN DEBUG MODE');
        debugPrint('🛡️ Android: Debug provider');
        debugPrint('🛡️ iOS/macOS: Debug provider');
        if (debugToken != null && debugToken.isNotEmpty) {
          debugPrint('🛡️ Using fixed debug token');
          debugPrint('🛡️ Debug token length: ${debugToken.length}');
        }
      } else {
        _lastProviderMode = 'production';
        debugPrint('🛡️ ACTIVATING APP CHECK IN PRODUCTION MODE');
        debugPrint('🛡️ Android: Play Integrity');
        debugPrint('🛡️ iOS: App Attest with DeviceCheck fallback');
      }
      debugPrint('🛡️ ============================================');

      await FirebaseAppCheck.instance.activate(
        providerApple: useDebugProvider
            ? AppleDebugProvider(debugToken: debugToken)
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        providerAndroid: useDebugProvider
            ? AndroidDebugProvider(debugToken: debugToken)
            : const AndroidPlayIntegrityProvider(),
        providerWeb: ReCaptchaV3Provider(
          '6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI', // Test key
        ),
      );

      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

      FirebaseAppCheck.instance.onTokenChange.listen(
        (token) {
          debugPrint('🛡️ ============================================');
          debugPrint(
            useDebugProvider
                ? '🛡️ DEBUG APP CHECK TOKEN RECEIVED'
                : '🛡️ PRODUCTION APP CHECK TOKEN RECEIVED',
          );
          debugPrint('🛡️ Token length: ${token?.length ?? 0}');
          if (token != null && token.isNotEmpty) {
            debugPrint(
              useDebugProvider
                  ? '🛡️ ✅ Debug provider is working!'
                  : '🛡️ ✅ Production provider is working!',
            );
            try {
              final parts = token.split('.');
              if (parts.length >= 2) {
                debugPrint('🛡️ Token payload length: ${parts[1].length}');
              }
            } catch (_) {}
          }
          debugPrint('🛡️ ============================================');
        },
        onError: (Object error) {
          debugPrint('⚠️ ============================================');
          debugPrint(
            useDebugProvider
                ? '⚠️ DEBUG APP CHECK TOKEN ERROR: $error'
                : '⚠️ PRODUCTION APP CHECK TOKEN ERROR: $error',
          );
          debugPrint('⚠️ ============================================');
        },
      );

      debugPrint(
        useDebugProvider
            ? '🛡️ ✅ AppCheck activated with DEBUG providers'
            : '🛡️ ✅ AppCheck activated with PRODUCTION providers',
      );

      if (useDebugProvider) {
        debugPrint(
          '🛡️ Debug mode: waiting for App Check token via onTokenChange listener',
        );
      } else {
        try {
          debugPrint('🛡️ Testing production token fetch...');
          final token = await FirebaseAppCheck.instance.getToken(true);
          if (token != null && token.isNotEmpty) {
            debugPrint('🛡️ ✅ Production token fetch successful!');
            debugPrint('🛡️ Token length: ${token.length} characters');
          } else {
            debugPrint('⚠️ Production token is null or empty');
          }
        } catch (e) {
          debugPrint('⚠️ Production token fetch failed: $e');
          final message = e.toString();
          if (message.contains('App not registered')) {
            debugPrint(
              '⚠️ Firebase App Check does not recognize this Apple app ID. '
              'Verify the iOS app with bundle ID com.wordnerd.artbeat and app ID '
              '1:665020451634:ios:fcce3b8f65048f0578652b is registered in Firebase.',
            );
          }
          if (message.contains('App attestation failed')) {
            debugPrint(
              '⚠️ Apple production attestation failed. Confirm App Attest/DeviceCheck is enabled for the same Firebase iOS app.',
            );
          }
        }
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
    'providerMode': _lastProviderMode,
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
