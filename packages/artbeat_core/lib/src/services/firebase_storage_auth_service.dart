import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import '../firebase/secure_firebase_config.dart';
import '../utils/logger.dart';

/// Service to handle Firebase Storage authentication and token refresh
class FirebaseStorageAuthService {
  static final FirebaseStorageAuthService _instance =
      FirebaseStorageAuthService._internal();
  factory FirebaseStorageAuthService() => _instance;
  FirebaseStorageAuthService._internal();

  /// Refreshes both Firebase Auth and App Check tokens
  Future<bool> refreshTokens() async {
    try {
      bool authRefreshed = false;
      bool appCheckRefreshed = false;

      // Refresh Firebase Auth token
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await user.getIdToken(true); // Force refresh
          authRefreshed = true;
          if (kDebugMode) {
            AppLogger.firebase('✅ Firebase Auth token refreshed successfully');
          }
        } catch (e) {
          if (kDebugMode) {
            AppLogger.error('❌ Failed to refresh Firebase Auth token: $e');
          }
        }
      } else {
        if (kDebugMode) {
          AppLogger.warning('⚠️ No authenticated user found for token refresh');
        }
      }

      // Refresh App Check token
      if (!SecureFirebaseConfig.shouldBypassAppCheckTokenRefresh) {
        try {
          await FirebaseAppCheck.instance.getToken(true); // Force refresh
          appCheckRefreshed = true;
          if (kDebugMode) {
            AppLogger.info('✅ App Check token refreshed successfully');
          }
        } catch (e) {
          if (kDebugMode) {
            AppLogger.error('❌ Failed to refresh App Check token: $e');
          }
        }
      } else if (kDebugMode) {
        AppLogger.info(
          '🛡️ Skipping App Check token refresh for web debug session',
        );
      }

      return authRefreshed || appCheckRefreshed;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('❌ Error during token refresh: $e');
      }
      return false;
    }
  }

  /// Checks if the current user is authenticated
  bool get isAuthenticated {
    return FirebaseAuth.instance.currentUser != null;
  }

  /// Gets the current user's UID
  String? get currentUserId {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// Validates if a Firebase Storage URL is accessible
  Future<bool> validateStorageAccess(String url) async {
    try {
      // Basic URL validation
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        return false;
      }

      // Check if it's a Firebase Storage URL
      if (!url.contains('firebasestorage.googleapis.com')) {
        return true; // Not a Firebase Storage URL, assume it's accessible
      }

      // Check authentication
      if (!isAuthenticated) {
        if (kDebugMode) {
          AppLogger.warning(
            '⚠️ User not authenticated for Firebase Storage access',
          );
        }
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('❌ Error validating storage access: $e');
      }
      return false;
    }
  }

  /// Handles 403 errors by refreshing tokens and retrying
  Future<bool> handle403Error(String url) async {
    if (kDebugMode) {
      AppLogger.error('🔄 Handling 403 error for URL: $url');
    }

    // First, try refreshing tokens
    final tokensRefreshed = await refreshTokens();

    if (!tokensRefreshed) {
      if (kDebugMode) {
        AppLogger.error('❌ Could not refresh tokens for 403 error handling');
      }
      return false;
    }

    // Add a small delay to allow tokens to propagate
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (kDebugMode) {
      AppLogger.info('✅ Tokens refreshed, ready for retry');
    }

    return true;
  }

  /// Gets diagnostic information about the current authentication state
  Map<String, dynamic> getDiagnosticInfo() {
    final user = FirebaseAuth.instance.currentUser;

    return {
      'isAuthenticated': isAuthenticated,
      'userId': currentUserId,
      'userEmail': user?.email,
      'emailVerified': user?.emailVerified,
      'isAnonymous': user?.isAnonymous,
      'lastSignInTime': user?.metadata.lastSignInTime?.toIso8601String(),
      'creationTime': user?.metadata.creationTime?.toIso8601String(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
