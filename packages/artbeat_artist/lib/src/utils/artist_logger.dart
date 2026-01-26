import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Centralized logging utility for the ARTbeat Artist package
/// Provides secure, production-ready logging with proper level filtering
class ArtistLogger {
  static final Logger _logger = Logger(
    filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(),
    printer: kDebugMode
        ? PrettyPrinter(
            methodCount: 2,
            errorMethodCount: 8,
            lineLength: 120,
            colors: true,
            printEmojis: true,
            dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
          )
        : SimplePrinter(),
    output: ConsoleOutput(),
  );

  /// Log debug information (only in debug mode)
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log informational messages
  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning messages
  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error messages
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log severe/fatal errors
  static void severe(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Service-specific logger for artist service operations
  static void artistService(
    String operation, {
    String? details,
    Object? error,
  }) {
    final message =
        'ArtistService: $operation${details != null ? ' - $details' : ''}';
    if (error != null) {
      _logger.e(message, error: error);
    } else {
      _logger.i(message);
    }
  }

  /// Service-specific logger for integration service operations
  static void integrationService(
    String operation, {
    String? details,
    Object? error,
  }) {
    final message =
        'IntegrationService: $operation${details != null ? ' - $details' : ''}';
    if (error != null) {
      _logger.e(message, error: error);
    } else {
      _logger.i(message);
    }
  }

  /// Service-specific logger for subscription operations
  static void subscriptionService(
    String operation, {
    String? details,
    Object? error,
  }) {
    final message =
        'SubscriptionService: $operation${details != null ? ' - $details' : ''}';
    if (error != null) {
      _logger.e(message, error: error);
    } else {
      _logger.i(message);
    }
  }

  /// Service-specific logger for community service operations
  static void communityService(
    String operation, {
    String? details,
    Object? error,
  }) {
    final message =
        'CommunityService: $operation${details != null ? ' - $details' : ''}';
    if (error != null) {
      _logger.e(message, error: error);
    } else {
      _logger.i(message);
    }
  }

  /// Secure payment operation logging (never logs sensitive data)
  static void paymentOperation(
    String operation, {
    String? transactionId,
    Object? error,
  }) {
    final message =
        'UnifiedPaymentService: $operation${transactionId != null ? ' (ID: ${_sanitizeTransactionId(transactionId)})' : ''}';
    if (error != null) {
      _logger.e(message, error: _sanitizeError(error));
    } else {
      _logger.i(message);
    }
  }

  /// Sanitize transaction ID for logging (show only last 4 characters)
  static String _sanitizeTransactionId(String transactionId) {
    if (transactionId.length <= 4) return '****';
    return '****${transactionId.substring(transactionId.length - 4)}';
  }

  /// Sanitize error messages to prevent sensitive data leakage
  static Object _sanitizeError(Object error) {
    final errorString = error.toString();
    // Remove potential sensitive data patterns
    final sanitized = errorString
        .replaceAll(RegExp(r'sk_[a-zA-Z0-9_]+'), '[STRIPE_SECRET_KEY]')
        .replaceAll(RegExp(r'pk_[a-zA-Z0-9_]+'), '[STRIPE_PUBLIC_KEY]')
        .replaceAll(RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w+\b'), '[EMAIL_ADDRESS]')
        .replaceAll(
          RegExp(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b'),
          '[CARD_NUMBER]',
        );

    return sanitized;
  }
}
