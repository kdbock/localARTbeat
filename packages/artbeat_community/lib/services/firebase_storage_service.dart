import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart' as compress;
import 'package:artbeat_core/artbeat_core.dart' as core;

/// Service for handling Firebase Storage operations
/// IMPORTANT:
/// - Firebase must be initialized ONCE elsewhere (SecureFirebaseConfig)
/// - This service NEVER initializes Firebase
class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // ------------------------------------------------------------
  // IMAGE UPLOADS
  // ------------------------------------------------------------

  /// Upload a single image file
  Future<String> uploadImage(File imageFile, {String? customPath}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to upload images');
    }

    final fileName = '${_uuid.v4()}.jpg';
    final path = customPath ?? 'posts/${user.uid}/$fileName';
    final ref = _storage.ref().child(path);

    core.AppLogger.debug('Uploading image → $path');

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

    final snapshot = await uploadTask.whenComplete(() {});
    return snapshot.ref.getDownloadURL();
  }

  /// Upload multiple images
  Future<List<String>> uploadImages(List<File> imageFiles) async {
    final List<String> urls = [];
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User must be authenticated');
    }

    for (int i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      if (!await file.exists() || await file.length() == 0) continue;

      final url = await uploadImage(
        file,
        customPath:
            'post_images/${user.uid}/post_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
      );
      urls.add(url);
    }

    return urls;
  }

  /// Delete an image
  Future<void> deleteImage(String imageUrl) async {
    await _storage.refFromURL(imageUrl).delete();
  }

  /// Upload with progress stream
  Stream<TaskSnapshot> uploadImageWithProgress(
    File imageFile, {
    String? customPath,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated');
    }

    final fileName = '${_uuid.v4()}.jpg';
    final path = customPath ?? 'posts/${user.uid}/$fileName';
    final ref = _storage.ref().child(path);

    return ref
        .putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'))
        .snapshotEvents;
  }

  // ------------------------------------------------------------
  // VIDEO UPLOADS (NO FALLBACKS, NO TEMP APPS)
  // ------------------------------------------------------------

  Future<String> uploadVideo(
    File videoFile, {
    String? customPath,
    void Function(double)? onProgress,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to upload videos');
    }

    final fileName = '${_uuid.v4()}.mp4';
    final path = customPath ?? 'posts/${user.uid}/videos/$fileName';
    final ref = _storage.ref().child(path);

    core.AppLogger.debug('Uploading video → $path');

    final uploadTask = ref.putFile(
      videoFile,
      SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      ),
    );

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      });
    }

    final snapshot = await uploadTask.whenComplete(() {});
    return snapshot.ref.getDownloadURL();
  }

  // ------------------------------------------------------------
  // AUDIO UPLOADS
  // ------------------------------------------------------------

  Future<String> uploadAudio(File audioFile, {String? customPath}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated');
    }

    final fileName = '${_uuid.v4()}.mp3';
    final path = customPath ?? 'posts/${user.uid}/audio/$fileName';
    final ref = _storage.ref().child(path);

    final uploadTask = ref.putFile(
      audioFile,
      SettableMetadata(contentType: 'audio/mpeg'),
    );

    final snapshot = await uploadTask.whenComplete(() {});
    return snapshot.ref.getDownloadURL();
  }

  // ------------------------------------------------------------
  // PROFILE / PORTFOLIO HELPERS
  // ------------------------------------------------------------

  Future<String> uploadProfileImage(File imageFile, String userId) {
    return uploadImage(imageFile, customPath: 'profiles/$userId/profile.jpg');
  }

  Future<String> uploadPortfolioImage(File imageFile, String userId) {
    return uploadImage(
      imageFile,
      customPath: 'portfolios/$userId/${_uuid.v4()}.jpg',
    );
  }

  // ------------------------------------------------------------
  // UTILITIES
  // ------------------------------------------------------------

  int get maxFileSizeBytes => 15 * 1024 * 1024;

  bool isValidFileSize(File file) {
    return file.lengthSync() <= maxFileSizeBytes;
  }

  /// Compress image (safe, optional)
  Future<File> compressImage(File file) async {
    try {
      final targetPath =
          '${Directory.systemTemp.path}/${_uuid.v4()}_compressed.jpg';

      final result = await compress.FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85,
        minWidth: 1920,
        minHeight: 1920,
        format: compress.CompressFormat.jpeg,
      );

      return result != null ? File(result.path) : file;
    } catch (_) {
      return file;
    }
  }
}
