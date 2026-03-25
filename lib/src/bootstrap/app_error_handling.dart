import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/foundation.dart';

bool isExpectedMissingImageError(Object error) {
  final errorString = error.toString();
  return errorString.contains('statusCode: 404') &&
      (errorString.contains('firebasestorage.googleapis.com') ||
          errorString.contains('firebase') ||
          errorString.contains('artwork') ||
          errorString.contains('HttpException'));
}

void logExpectedMissingImageError(Object error) {
  if (!kDebugMode) {
    return;
  }
  debugPrint('🖼️ Missing image (404): ${error.toString().split(',').first}');
}

void installGlobalErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    final error = details.exception;
    if (isExpectedMissingImageError(error)) {
      logExpectedMissingImageError(error);
      return;
    }

    CrashPreventionService.logCrashPrevention(
      operation: 'flutter_framework',
      errorType: error.runtimeType.toString(),
      additionalInfo: error.toString(),
    );

    AppLogger.error(
      'Flutter framework error: $error',
      error: error,
      stackTrace: details.stack,
    );

    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (isExpectedMissingImageError(error)) {
      logExpectedMissingImageError(error);
      return true;
    }

    CrashPreventionService.logCrashPrevention(
      operation: 'platform_error',
      errorType: error.runtimeType.toString(),
      additionalInfo: error.toString(),
    );

    AppLogger.error('Platform error: $error', error: error, stackTrace: stack);
    return !kDebugMode;
  };
}
