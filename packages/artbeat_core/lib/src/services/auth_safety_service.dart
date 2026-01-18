import 'package:google_sign_in/google_sign_in.dart';
import '../utils/logger.dart';

/// Service to safely handle authentication flows with proper error handling
class AuthSafetyService {
  static final AuthSafetyService _instance = AuthSafetyService._internal();
  factory AuthSafetyService() => _instance;
  AuthSafetyService._internal();

  static bool _isInitialized = false;
  static bool _googleSignInAvailable = false;
  static bool _initialized = false;
  static GoogleSignInAccount? _lastAuthenticatedUser;

  static GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

  /// Initialize authentication safety service
  static Future<void> initialize() async {
    try {
      if (_isInitialized) {
        AppLogger.info('🔐 Auth Safety Service already initialized');
        return;
      }

      AppLogger.info('🔐 Initializing Auth Safety Service...');

      // Initialize Google Sign-In with null safety
      try {
        await GoogleSignIn.instance.initialize();
        
        // Listen to authentication events to track the current user
        GoogleSignIn.instance.authenticationEvents.listen((event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            _lastAuthenticatedUser = event.user;
          } else if (event is GoogleSignInAuthenticationEventSignOut) {
            _lastAuthenticatedUser = null;
          }
        });
        
        _googleSignInAvailable = true;
        AppLogger.info('✅ Google Sign-In initialized');
      } catch (e) {
        AppLogger.warning('⚠️ Google Sign-In initialization failed: $e');
        _googleSignInAvailable = false;
      }

      _initialized = true;
      _isInitialized = true;
      AppLogger.info('✅ Auth Safety Service initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to initialize Auth Safety Service',
        error: e,
        stackTrace: stackTrace,
      );
      _isInitialized = false;
      rethrow;
    }
  }

  /// Safely attempt Google Sign-In
  static Future<GoogleSignInAccount?> safeGoogleSignIn({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      if (!_initialized) {
        throw Exception('Auth Safety Service not initialized');
      }

      if (!_googleSignInAvailable) {
        throw Exception('Google Sign-In not available');
      }

      AppLogger.info('🔐 Attempting safe Google Sign-In...');

      // Check if already signed in
      final currentUser = _lastAuthenticatedUser;
      if (currentUser != null) {
        AppLogger.info('✅ User already signed in: ${currentUser.email}');
        return currentUser;
      }

      // Attempt sign in using authenticate() for 7.x
      final account = await _googleSignIn.authenticate().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('Google Sign-In timed out', timeout);
        },
      );

      AppLogger.info('✅ Google Sign-In successful: ${account.email}');
      return account;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        AppLogger.info('ℹ️ Google Sign-In was cancelled by user');
      } else {
        _handleAuthError('google_sign_in', e.toString(), e);
      }
      return null;
    } on TimeoutException catch (e) {
      _handleAuthError(
        'google_sign_in',
        'Sign-in timed out. Please check your connection.',
        e,
      );
      return null;
    } on Exception catch (e, stackTrace) {
      _handleAuthError('google_sign_in', e.toString(), e, stackTrace);
      return null;
    }
  }

  /// Safely sign out from Google
  static Future<bool> safeGoogleSignOut() async {
    try {
      if (!_initialized || !_googleSignInAvailable) {
        AppLogger.warning('⚠️ Cannot sign out: Service not initialized');
        return false;
      }

      AppLogger.info('🔐 Signing out from Google...');
      await _googleSignIn.signOut();
      AppLogger.info('✅ Successfully signed out from Google');
      return true;
    } catch (e) {
      AppLogger.error('❌ Error signing out from Google: $e');
      return false;
    }
  }

  /// Safely disconnect Google account
  static Future<bool> safeGoogleDisconnect() async {
    try {
      if (!_initialized || !_googleSignInAvailable) {
        AppLogger.warning('⚠️ Cannot disconnect: Service not initialized');
        return false;
      }

      AppLogger.info('🔐 Disconnecting Google account...');
      await _googleSignIn.disconnect();
      AppLogger.info('✅ Successfully disconnected Google account');
      return true;
    } catch (e) {
      AppLogger.error('❌ Error disconnecting Google account: $e');
      return false;
    }
  }

  /// Get current Google Sign-In user safely
  static GoogleSignInAccount? getCurrentUser() {
    try {
      if (!_initialized || !_googleSignInAvailable) {
        return null;
      }
      return _lastAuthenticatedUser;
    } catch (e) {
      AppLogger.error('❌ Error getting current Google user: $e');
      return null;
    }
  }

  /// Check if user is signed in with Google
  static bool get isGoogleSignedIn {
    try {
      return _lastAuthenticatedUser != null;
    } catch (e) {
      return false;
    }
  }

  /// Validate authentication data before use
  static bool validateAuthData(Map<String, dynamic>? authData) {
    try {
      if (authData == null) {
        AppLogger.warning('⚠️ Auth data is null');
        return false;
      }

      final userId = authData['uid'];
      if (userId == null || (userId is String && userId.isEmpty)) {
        AppLogger.warning('⚠️ Missing user ID in auth data');
        return false;
      }

      AppLogger.info('✅ Auth data validation successful');
      return true;
    } catch (e) {
      AppLogger.error('❌ Error validating auth data: $e');
      return false;
    }
  }

  /// Handle auth errors with appropriate logging
  static void _handleAuthError(
    String operationName,
    String errorMessage,
    Object? error, [
    StackTrace? stackTrace,
  ]) {
    AppLogger.error(
      '❌ Auth operation failed: $operationName\n'
      'Error: $errorMessage',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Check if auth safety service is ready
  static bool get isReady {
    return _isInitialized && _googleSignInAvailable;
  }

  /// Check if auth safety service is initialized
  static bool get isInitialized => _isInitialized;

  /// Get initialization status details
  static Map<String, bool> getStatusDetails() {
    return {
      'initialized': _isInitialized,
      'googleSignInAvailable': _googleSignInAvailable,
      'isReady': isReady,
    };
  }

  /// Reset auth safety service (for testing or recovery)
  static void reset() {
    _isInitialized = false;
    _lastAuthenticatedUser = null;
    _googleSignInAvailable = false;
    _initialized = false;
    AppLogger.info('🔐 Auth Safety Service reset');
  }
}

/// Custom exception for auth timeout
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  TimeoutException(this.message, this.timeout);

  @override
  String toString() => message;
}
