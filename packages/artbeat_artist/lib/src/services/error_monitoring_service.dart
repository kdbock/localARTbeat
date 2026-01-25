import 'dart:async';
import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../utils/artist_logger.dart';

/// Production-ready error monitoring service
/// Provides secure error reporting for the ARTbeat Artist package
class ErrorMonitoringService {
  static FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  /// Check if we're in a test environment
  static bool get _isTestEnvironment {
    return (Zone.current[#test] != null) ||
        (Platform.environment.containsKey('FLUTTER_TEST')) ||
        const bool.fromEnvironment('dart.vm.product') == false;
  }

  /// Initialize error monitoring (call during app startup)
  static Future<void> initialize() async {
    try {
      // Set up Crashlytics for error collection
      if (!kDebugMode) {
        FlutterError.onError = _crashlytics.recordFlutterFatalError;

        // Handle errors from outside Flutter framework
        PlatformDispatcher.instance.onError = (error, stack) {
          _crashlytics.recordError(error, stack, fatal: true);
          return true;
        };
      }

      ArtistLogger.info('Error monitoring initialized successfully');
    } catch (e, stackTrace) {
      ArtistLogger.error(
        'Failed to initialize error monitoring',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Record a non-fatal error with context
  static void recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
    bool fatal = false,
  }) {
    try {
      // Skip Firebase calls in test environment
      if (_isTestEnvironment) {
        ArtistLogger.error(
          'Test Mode: Would record error to Crashlytics',
          error: exception,
          stackTrace: stackTrace,
        );
        return;
      }

      // Sanitize context data to prevent sensitive information leakage
      final sanitizedContext = _sanitizeContext(context);

      // Set custom keys for debugging
      if (sanitizedContext != null) {
        for (final entry in sanitizedContext.entries) {
          _crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
      }

      if (reason != null) {
        _crashlytics.setCustomKey('error_reason', reason);
      }

      // Record the error
      _crashlytics.recordError(
        exception,
        stackTrace,
        fatal: fatal,
        information:
            sanitizedContext?.values.map((v) => v.toString()).toList() ?? [],
      );

      // Also log locally for development
      ArtistLogger.error(
        'Error recorded: ${reason ?? exception.toString()}',
        error: exception,
        stackTrace: stackTrace,
      );
    } catch (e) {
      // Fallback logging if Crashlytics fails
      ArtistLogger.error('⛔ Failed to record error to Crashlytics', error: e);
    }
  }

  /// Set user context for error reporting
  static void setUserContext({
    required String userId,
    String? userType,
    String? subscriptionTier,
  }) {
    try {
      // Skip Firebase calls in test environment
      if (_isTestEnvironment) {
        ArtistLogger.info('Test Mode: Would set user context');
        return;
      }

      _crashlytics.setUserIdentifier(userId);

      if (userType != null) {
        _crashlytics.setCustomKey('user_type', userType);
      }

      if (subscriptionTier != null) {
        _crashlytics.setCustomKey('subscription_tier', subscriptionTier);
      }

      ArtistLogger.debug('User context set for error reporting');
    } catch (e) {
      ArtistLogger.error('⛔ Failed to set user context', error: e);
    }
  }

  /// Track custom events for business intelligence
  static void logEvent(String eventName, {Map<String, dynamic>? parameters}) {
    try {
      // Skip Firebase calls in test environment
      if (_isTestEnvironment) {
        ArtistLogger.info('Test Mode: Would log event $eventName');
        return;
      }

      final sanitizedParams = _sanitizeContext(parameters);
      _crashlytics.log('$eventName: $sanitizedParams');

      ArtistLogger.info('Event logged: $eventName');
    } catch (e) {
      ArtistLogger.error('⛔ Failed to log event', error: e);
    }
  }

  /// Sanitize context data to prevent sensitive information leakage
  static Map<String, dynamic>? _sanitizeContext(Map<String, dynamic>? context) {
    if (context == null) return null;

    final sanitized = <String, dynamic>{};

    for (final entry in context.entries) {
      final key = entry.key.toLowerCase();
      var value = entry.value;

      // Skip sensitive fields
      if (_isSensitiveField(key)) {
        continue;
      }

      // Sanitize values
      if (value is String) {
        value = _sanitizeString(value);
      }

      // Limit context size
      if (sanitized.length >= 10) break;

      sanitized[entry.key] = value;
    }

    return sanitized.isNotEmpty ? sanitized : null;
  }

  /// Check if field contains sensitive information
  static bool _isSensitiveField(String fieldName) {
    final sensitive = [
      'password',
      'token',
      'secret',
      'key',
      'auth',
      'email',
      'phone',
      'ssn',
      'credit',
      'card',
      'stripe',
      'payment',
      'billing',
    ];

    return sensitive.any((s) => fieldName.contains(s));
  }

  /// Sanitize string values to prevent data leakage
  static String _sanitizeString(String value) {
    return value
        .replaceAll(RegExp(r'sk_[a-zA-Z0-9_]+'), '[STRIPE_SECRET]')
        .replaceAll(RegExp(r'pk_[a-zA-Z0-9_]+'), '[STRIPE_PUBLIC]')
        .replaceAll(RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w+\b'), '[EMAIL]')
        .replaceAll(
          RegExp(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b'),
          '[CARD]',
        )
        .replaceAll(RegExp(r'\b\d{3}-\d{2}-\d{4}\b'), '[SSN]');
  }

  /// Create safe error wrapper for service operations
  static Future<T> safeExecute<T>(
    String operation,
    Future<T> Function() function, {
    T? fallbackValue,
    Map<String, dynamic>? context,
  }) async {
    try {
      final result = await function();
      return result;
    } catch (e, stackTrace) {
      recordError(
        e,
        stackTrace,
        reason: 'Failed to execute $operation',
        context: context,
      );

      if (fallbackValue != null) {
        return fallbackValue;
      }

      rethrow;
    }
  }
}
