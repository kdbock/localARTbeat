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

    // Prevent duplicate initialization
    if (_appCheckInitialized) {
      debugPrint('🛡️ App Check already initialized, skipping...');
      return;
    }

    try {
      // If forceDebug is true, use debug provider even in release mode
      // This is helpful for developers without business registration
      final bool useDebugProvider = kDebugMode || forceDebug;

      if (useDebugProvider) {
        debugPrint('🛡️ ============================================');
        debugPrint('🛡️ ACTIVATING APP CHECK IN DEBUG MODE');
        debugPrint('🛡️ ============================================');
        await FirebaseAppCheck.instance.activate(
          // ignore: deprecated_member_use
          androidProvider: AndroidProvider.debug,
          // ignore: deprecated_member_use
          appleProvider: AppleProvider.debug,
        );
        await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

        // Add token change listener to monitor App Check token generation
        FirebaseAppCheck.instance.onTokenChange.listen(
          (token) {
            debugPrint('🛡️ ============================================');
            debugPrint('🛡️ APP CHECK TOKEN CHANGED/REFRESHED:');
            debugPrint('🛡️ $token');
            debugPrint('🛡️ ============================================');
          },
          onError: (Object error) {
            debugPrint('⚠️ ============================================');
            debugPrint('⚠️ APP CHECK TOKEN ERROR: $error');
            debugPrint('⚠️ ============================================');
          },
        );

        debugPrint('🛡️ AppCheck activated with DEBUG provider');

        // Wait a moment for the provider to initialize
        await Future<void>.delayed(const Duration(milliseconds: 500));

        try {
          debugPrint('🛡️ Fetching debug token...');
          debugPrint('🛡️ ============================================');
          debugPrint('🛡️ IMPORTANT: Check Xcode console for debug token!');
          debugPrint('🛡️ Look for: "Firebase App Check debug token:"');
          debugPrint('🛡️ ============================================');

          final token = await FirebaseAppCheck.instance.getToken(true);
          debugPrint('🛡️ ============================================');
          debugPrint('🛡️ APP CHECK DEBUG TOKEN:');
          debugPrint('🛡️ $token');
          debugPrint('🛡️ ============================================');
          debugPrint('🛡️ Add this token to Firebase Console:');
          debugPrint('🛡️ 1. Go to Firebase Console > App Check');
          debugPrint('🛡️ 2. Select your iOS app');
          debugPrint('🛡️ 3. Add this token to Debug Tokens');
          debugPrint('🛡️ ============================================');

          if (token == null || token.isEmpty) {
            debugPrint('⚠️ Token is null/empty, retrying...');
            Future<void>.delayed(const Duration(seconds: 2), () async {
              try {
                final retryToken = await FirebaseAppCheck.instance.getToken(
                  true,
                );
                debugPrint('🛡️ ============================================');
                debugPrint('🛡️ APP CHECK DEBUG TOKEN (RETRY):');
                debugPrint('🛡️ $retryToken');
                debugPrint('🛡️ ============================================');
              } catch (e) {
                debugPrint('⚠️ AppCheck DEBUG token retry failed: $e');
              }
            });
          }
        } catch (e) {
          debugPrint('⚠️ ============================================');
          debugPrint('⚠️ AppCheck DEBUG token fetch failed: $e');
          debugPrint('⚠️ ============================================');
        }
      } else {
        debugPrint('🛡️ ============================================');
        debugPrint('🛡️ ACTIVATING APP CHECK IN PRODUCTION MODE');
        debugPrint('🛡️ Using: AppAttest with DeviceCheck fallback');
        debugPrint('🛡️ ============================================');
        await FirebaseAppCheck.instance.activate(
          // ignore: deprecated_member_use
          androidProvider: AndroidProvider.playIntegrity,
          // ignore: deprecated_member_use
          appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
        );
        await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

        // Add token change listener to monitor production tokens
        FirebaseAppCheck.instance.onTokenChange.listen(
          (token) {
            debugPrint('🛡️ ============================================');
            debugPrint('🛡️ PRODUCTION APP CHECK TOKEN RECEIVED');
            debugPrint('🛡️ Token length: ${token?.length ?? 0}');
            if (token != null && token.isNotEmpty) {
              debugPrint('🛡️ ✅ AppAttest/DeviceCheck is working!');
              // Decode JWT to see provider
              try {
                final parts = token.split('.');
                if (parts.length >= 2) {
                  debugPrint('🛡️ Token payload length: ${parts[1].length}');
                  debugPrint(
                    '🛡️ Token type: Production (AppAttest or DeviceCheck)',
                  );
                }
              } catch (_) {}
            }
            debugPrint('🛡️ ============================================');
          },
          onError: (Object error) {
            debugPrint('⚠️ ============================================');
            debugPrint('⚠️ PRODUCTION APP CHECK TOKEN ERROR: $error');
            debugPrint('⚠️ ============================================');
          },
        );

        debugPrint('🛡️ ✅ AppCheck activated with PRODUCTION providers');
        debugPrint('🛡️ iOS: AppAttest with DeviceCheck fallback');
        debugPrint('🛡️ Android: Play Integrity');

        // Test token fetch
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
