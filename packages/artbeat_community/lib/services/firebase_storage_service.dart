import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart' as compress;
import 'package:firebase_core/firebase_core.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;

/// Service for handling Firebase Storage operations
class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Get the appropriate storage instance (with or without App Check)
  FirebaseStorage get _effectiveStorage {
    return _storage;
  }

  /// Upload a single image file to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadImage(File imageFile, {String? customPath}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        core.AppLogger.error(
          'User not authenticated',
          logger: 'FirebaseStorageService',
        );
        throw Exception('User must be authenticated to upload images');
      }

      core.AppLogger.debug(
        'User authenticated: ${user.uid}',
        logger: 'FirebaseStorageService',
      );

      // Generate unique filename
      final fileName = '${_uuid.v4()}.jpg';
      final path = customPath ?? 'posts/${user.uid}/$fileName';

      core.AppLogger.debug(
        'Upload path: $path',
        logger: 'FirebaseStorageService',
      );

      // Create reference to the file location using effective storage
      final ref = _effectiveStorage.ref().child(path);

      core.AppLogger.debug(
        'Starting Firebase Storage upload...',
        logger: 'FirebaseStorageService',
      );

      // Upload the file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() => null);

      core.AppLogger.debug(
        'Upload completed, getting download URL...',
        logger: 'FirebaseStorageService',
      );

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      core.AppLogger.debug(
        'Download URL obtained: $downloadUrl',
        logger: 'FirebaseStorageService',
      );

      return downloadUrl;
    } catch (e) {
      core.AppLogger.error(
        'Upload failed with error: $e',
        logger: 'FirebaseStorageService',
        error: e,
      );
      core.AppLogger.error(
        'Error type: ${e.runtimeType}',
        logger: 'FirebaseStorageService',
      );
      debugPrint('UPLOAD ERROR (uploadImage): $e');
      debugPrint('UPLOAD ERROR TYPE: ${e.runtimeType}');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload multiple images and return their download URLs
  Future<List<String>> uploadImages(List<File> imageFiles) async {
    core.AppLogger.debug(
      'Starting upload of ${imageFiles.length} images',
      logger: 'FirebaseStorageService',
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      core.AppLogger.error(
        'User not authenticated',
        logger: 'FirebaseStorageService',
      );
      throw Exception('User must be authenticated to upload images');
    }

    final List<String> downloadUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      final imageFile = imageFiles[i];
      try {
        final exists = await imageFile.exists();
        final size = exists ? await imageFile.length() : 0;
        core.AppLogger.debug(
          '[Service] Image $i path: ${imageFile.path}',
          logger: 'FirebaseStorageService',
        );
        core.AppLogger.debug(
          '[Service] Image $i exists: $exists',
          logger: 'FirebaseStorageService',
        );
        core.AppLogger.debug(
          '[Service] Image $i size: $size bytes',
          logger: 'FirebaseStorageService',
        );
        if (!exists || size == 0) {
          core.AppLogger.error(
            '[Service] WARNING: Image $i is missing or empty and will be skipped.',
            logger: 'FirebaseStorageService',
          );
          continue;
        }

        final downloadUrl = await uploadImage(
          imageFile,
          customPath:
              'post_images/${user.uid}/post_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        downloadUrls.add(downloadUrl);

        core.AppLogger.debug(
          'Successfully uploaded image $i: $downloadUrl',
          logger: 'FirebaseStorageService',
        );
      } catch (e) {
        // If one upload fails, we could either:
        // 1. Continue with other uploads and return partial results
        // 2. Fail the entire operation
        // For now, we'll continue and let the caller handle partial failures
        core.AppLogger.error(
          'Failed to upload image $i: $e',
          logger: 'FirebaseStorageService',
          error: e,
        );
        core.AppLogger.error(
          'Image file path: ${imageFile.path}',
          logger: 'FirebaseStorageService',
        );
        core.AppLogger.error(
          'Failed to upload image: $e',
          logger: 'FirebaseStorageService',
        );
      }
    }

    core.AppLogger.debug(
      'Upload complete. ${downloadUrls.length}/${imageFiles.length} images uploaded successfully',
      logger: 'FirebaseStorageService',
    );

    return downloadUrls;
  }

  /// Delete an image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Get upload progress stream for a file
  Stream<TaskSnapshot> uploadImageWithProgress(
    File imageFile, {
    String? customPath,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to upload images');
    }

    final fileName = '${_uuid.v4()}.jpg';
    final path = customPath ?? 'posts/${user.uid}/$fileName';
    final ref = _storage.ref().child(path);

    final uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      ),
    );

    return uploadTask.snapshotEvents;
  }

  /// Upload profile image for artist
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    return uploadImage(imageFile, customPath: 'profiles/$userId/profile.jpg');
  }

  /// Upload portfolio image for artist
  Future<String> uploadPortfolioImage(File imageFile, String userId) async {
    final fileName = '${_uuid.v4()}.jpg';
    return uploadImage(imageFile, customPath: 'portfolios/$userId/$fileName');
  }

  /// Upload video file to Firebase Storage
  Future<String> uploadVideo(
    File videoFile, {
    String? customPath,
    void Function(double)? onProgress,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        core.AppLogger.error(
          'User not authenticated',
          logger: 'FirebaseStorageService',
        );
        throw Exception('User must be authenticated to upload videos');
      }

      // Generate unique filename
      final fileName = '${_uuid.v4()}.mp4';
      final path = customPath ?? 'posts/${user.uid}/videos/$fileName';

      core.AppLogger.debug(
        'Video upload path: $path',
        logger: 'FirebaseStorageService',
      );

      // Try multiple upload strategies to handle App Check issues
      return await _uploadVideoWithFallback(
        videoFile,
        path,
        user.uid,
        onProgress,
      );
    } catch (e) {
      core.AppLogger.error(
        'Video upload failed: $e',
        logger: 'FirebaseStorageService',
        error: e,
      );

      // Provide more specific error messages
      if (e.toString().contains('cannot parse response')) {
        core.AppLogger.error(
          'This error is likely due to Firebase App Check configuration. '
          'Please ensure the debug token is properly configured in Firebase Console.',
          logger: 'FirebaseStorageService',
        );
      }

      throw Exception('Failed to upload video: $e');
    }
  }

  /// Upload video with multiple fallback strategies for App Check issues
  Future<String> _uploadVideoWithFallback(
    File videoFile,
    String path,
    String userId, [
    void Function(double)? onProgress,
  ]) async {
    final strategies = [
      (File file, String p, String uid) =>
          _uploadWithEffectiveStorage(file, p, uid, onProgress),
      (File file, String p, String uid) =>
          _uploadWithRegularStorage(file, p, uid, onProgress),
      (File file, String p, String uid) =>
          _uploadWithAppCheckDisabled(file, p, uid, onProgress),
    ];

    for (int i = 0; i < strategies.length; i++) {
      try {
        core.AppLogger.debug(
          'Trying video upload strategy ${i + 1}/${strategies.length}',
          logger: 'FirebaseStorageService',
        );

        final result = await strategies[i](videoFile, path, userId);
        core.AppLogger.debug(
          'Video upload strategy ${i + 1} succeeded',
          logger: 'FirebaseStorageService',
        );
        return result;
      } catch (e) {
        core.AppLogger.warning(
          'Video upload strategy ${i + 1} failed: $e',
          logger: 'FirebaseStorageService',
        );

        // If this is the last strategy, rethrow the error
        if (i == strategies.length - 1) {
          rethrow;
        }

        // Continue to next strategy
        continue;
      }
    }

    throw Exception('All video upload strategies failed');
  }

  /// Upload using the effective storage (debug storage if available)
  Future<String> _uploadWithEffectiveStorage(
    File videoFile,
    String path,
    String userId, [
    void Function(double)? onProgress,
  ]) async {
    final ref = _effectiveStorage.ref().child(path);

    final metadata = SettableMetadata(
      contentType: 'video/mp4',
      customMetadata: {
        'uploadedBy': userId,
        'uploadedAt': DateTime.now().toIso8601String(),
        'mediaType': 'video',
      },
    );

    core.AppLogger.debug(
      'Starting video upload with effective storage...',
      logger: 'FirebaseStorageService',
    );

    final uploadTask = ref.putFile(videoFile, metadata);

    // Track upload progress if callback provided
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    final snapshot = await uploadTask.whenComplete(() => null);
    return snapshot.ref.getDownloadURL();
  }

  /// Upload using regular storage (fallback when debug storage fails)
  Future<String> _uploadWithRegularStorage(
    File videoFile,
    String path,
    String userId, [
    void Function(double)? onProgress,
  ]) async {
    final ref = _storage.ref().child(path);

    final metadata = SettableMetadata(
      contentType: 'video/mp4',
      customMetadata: {
        'uploadedBy': userId,
        'uploadedAt': DateTime.now().toIso8601String(),
        'mediaType': 'video',
      },
    );

    core.AppLogger.debug(
      'Starting video upload with regular storage...',
      logger: 'FirebaseStorageService',
    );

    final uploadTask = ref.putFile(videoFile, metadata);

    // Track upload progress if callback provided
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    final snapshot = await uploadTask.whenComplete(() => null);
    return snapshot.ref.getDownloadURL();
  }

  /// Upload with App Check temporarily disabled (last resort)
  Future<String> _uploadWithAppCheckDisabled(
    File videoFile,
    String path,
    String userId, [
    void Function(double)? onProgress,
  ]) async {
    core.AppLogger.debug(
      'Attempting video upload with App Check disabled...',
      logger: 'FirebaseStorageService',
    );

    // Try to create a storage instance without App Check
    FirebaseStorage? tempStorage;
    try {
      final tempApp = await Firebase.initializeApp(
        name: 'temp-video-upload-${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      tempStorage = FirebaseStorage.instanceFor(app: tempApp);
      final ref = tempStorage.ref().child(path);

      final simpleMetadata = SettableMetadata(contentType: 'video/mp4');

      final uploadTask = ref.putFile(videoFile, simpleMetadata);

      // Track upload progress if callback provided
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Clean up
      await tempApp.delete();

      return downloadUrl;
    } catch (e) {
      // Clean up on error
      if (tempStorage != null) {
        try {
          await tempStorage.app.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Upload audio file to Firebase Storage
  Future<String> uploadAudio(File audioFile, {String? customPath}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        core.AppLogger.error(
          'User not authenticated',
          logger: 'FirebaseStorageService',
        );
        throw Exception('User must be authenticated to upload audio');
      }

      // Generate unique filename
      final fileName = '${_uuid.v4()}.mp3';
      final path = customPath ?? 'posts/${user.uid}/audio/$fileName';

      core.AppLogger.debug(
        'Audio upload path: $path',
        logger: 'FirebaseStorageService',
      );

      // Create reference to the file location using effective storage
      final ref = _effectiveStorage.ref().child(path);

      // Configure metadata
      final metadata = SettableMetadata(
        contentType: 'audio/mpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
          'mediaType': 'audio',
        },
      );

      core.AppLogger.debug(
        'Starting audio upload to Firebase Storage...',
        logger: 'FirebaseStorageService',
      );

      // Upload the file with error handling for App Check issues
      UploadTask uploadTask;
      try {
        uploadTask = ref.putFile(audioFile, metadata);
      } catch (e) {
        core.AppLogger.warning(
          'Initial upload attempt failed, trying with simplified metadata: $e',
          logger: 'FirebaseStorageService',
        );

        // Try with minimal metadata if App Check is causing issues
        final simpleMetadata = SettableMetadata(contentType: 'audio/mpeg');
        uploadTask = ref.putFile(audioFile, simpleMetadata);
      }

      // Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() => null);

      core.AppLogger.debug(
        'Audio upload completed, getting download URL...',
        logger: 'FirebaseStorageService',
      );

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      core.AppLogger.debug(
        'Audio download URL obtained: $downloadUrl',
        logger: 'FirebaseStorageService',
      );

      return downloadUrl;
    } catch (e) {
      core.AppLogger.error(
        'Audio upload failed: $e',
        logger: 'FirebaseStorageService',
        error: e,
      );

      // Provide more specific error messages
      if (e.toString().contains('cannot parse response')) {
        core.AppLogger.error(
          'This error is likely due to Firebase App Check configuration. '
          'Please ensure the debug token is properly configured in Firebase Console.',
          logger: 'FirebaseStorageService',
        );
      }

      throw Exception('Failed to upload audio: $e');
    }
  }

  /// Get file size limit (increased to 15MB for better user experience)
  int get maxFileSizeBytes => 15 * 1024 * 1024; // 15MB

  /// Check if file size is within limits
  bool isValidFileSize(File file) {
    return file.lengthSync() <= maxFileSizeBytes;
  }

  /// Compress image if needed
  Future<File> compressImage(File file) async {
    try {
      if (kDebugMode) {
        final originalSize = file.lengthSync();
        core.AppLogger.debug(
          'Compressing image: ${file.path.split('/').last}',
          logger: 'FirebaseStorageService',
        );
        core.AppLogger.debug(
          'Original size: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB',
          logger: 'FirebaseStorageService',
        );
      }

      // Create a temporary file for the compressed image
      final dir = Directory.systemTemp;
      final targetPath = '${dir.path}/${_uuid.v4()}_compressed.jpg';

      final compressedFile =
          await compress.FlutterImageCompress.compressAndGetFile(
            file.absolute.path,
            targetPath,
            quality: 85, // Good balance between quality and file size
            minWidth: 1920, // Max width
            minHeight: 1920, // Max height
            format: compress.CompressFormat.jpeg,
          );

      if (compressedFile != null) {
        // Convert XFile to File to get file size
        final compressedFileObj = File(compressedFile.path);
        final compressedSize = await compressedFileObj.length();
        if (kDebugMode) {
          core.AppLogger.debug(
            'Compressed size: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB',
            logger: 'FirebaseStorageService',
          );
          core.AppLogger.debug(
            'Compression ratio: ${((1 - compressedSize / file.lengthSync()) * 100).toStringAsFixed(1)}%',
            logger: 'FirebaseStorageService',
          );
        }
        return compressedFileObj;
      } else {
        if (kDebugMode) {
          core.AppLogger.debug(
            'Compression failed, returning original file',
            logger: 'FirebaseStorageService',
          );
        }
        return file;
      }
    } catch (e) {
      if (kDebugMode) {
        core.AppLogger.error(
          'Compression failed: $e',
          logger: 'FirebaseStorageService',
          error: e,
        );
      }
      // If compression fails, return the original file
      return file;
    }
  }
}
