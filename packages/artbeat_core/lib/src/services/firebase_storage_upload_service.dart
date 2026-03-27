import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../utils/logger.dart';
import 'firebase_storage_auth_service.dart';

/// Shared upload primitive for Firebase Storage paths that need auth/App Check
/// refresh and consistent retry behavior.
class FirebaseStorageUploadService {
  static final FirebaseStorageUploadService _instance =
      FirebaseStorageUploadService._internal();

  factory FirebaseStorageUploadService() => _instance;

  FirebaseStorageUploadService._internal();

  final FirebaseStorageAuthService _tokenService = FirebaseStorageAuthService();

  Future<TaskSnapshot> uploadFileWithRetry({
    required Reference ref,
    required File file,
    SettableMetadata? metadata,
    int maxAttempts = 3,
    String operationLabel = 'storage file upload',
    void Function(TaskSnapshot snapshot)? onSnapshotEvent,
  }) async {
    await _tokenService.refreshTokens();

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final uploadTask = ref.putFile(file, metadata);
        if (onSnapshotEvent != null) {
          uploadTask.snapshotEvents.listen(onSnapshotEvent);
        }
        return await uploadTask;
      } catch (error) {
        if (_shouldRefreshTokens(error)) {
          AppLogger.warning(
            '$operationLabel auth failure on attempt $attempt; refreshing tokens',
          );
          await _tokenService.refreshTokens();
        }

        final shouldRetry = attempt < maxAttempts && isRetryableUploadError(error);
        AppLogger.error('$operationLabel attempt $attempt failed: $error');

        if (!shouldRetry) {
          rethrow;
        }

        await Future<void>.delayed(Duration(seconds: attempt));
      }
    }

    throw Exception('$operationLabel failed after $maxAttempts attempts');
  }

  Future<TaskSnapshot> uploadDataWithRetry({
    required Reference ref,
    required Uint8List data,
    SettableMetadata? metadata,
    int maxAttempts = 3,
    String operationLabel = 'storage data upload',
    void Function(TaskSnapshot snapshot)? onSnapshotEvent,
  }) async {
    await _tokenService.refreshTokens();

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final uploadTask = ref.putData(data, metadata);
        if (onSnapshotEvent != null) {
          uploadTask.snapshotEvents.listen(onSnapshotEvent);
        }
        return await uploadTask;
      } catch (error) {
        if (_shouldRefreshTokens(error)) {
          AppLogger.warning(
            '$operationLabel auth failure on attempt $attempt; refreshing tokens',
          );
          await _tokenService.refreshTokens();
        }

        final shouldRetry = attempt < maxAttempts && isRetryableUploadError(error);
        AppLogger.error('$operationLabel attempt $attempt failed: $error');

        if (!shouldRetry) {
          rethrow;
        }

        await Future<void>.delayed(Duration(seconds: attempt));
      }
    }

    throw Exception('$operationLabel failed after $maxAttempts attempts');
  }

  bool isRetryableUploadError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'unauthorized':
        case 'unauthenticated':
        case 'network-request-failed':
        case 'retry-limit-exceeded':
        case 'unknown':
          return true;
      }
    }

    final message = error.toString().toLowerCase();
    return message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout') ||
        message.contains('unavailable') ||
        message.contains('connection') ||
        message.contains('retry-limit-exceeded');
  }

  bool _shouldRefreshTokens(Object error) {
    return error is FirebaseException &&
        (error.code == 'unauthorized' || error.code == 'unauthenticated');
  }
}
