import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show EnhancedStorageService, AppLogger;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  FirebaseStorage? _storage;
  FirebaseAuth? _auth;
  EnhancedStorageService? _enhancedStorage;

  FirebaseStorage? get _storageInstance {
    if (_storage == null) {
      try {
        _storage = FirebaseStorage.instance;
      } catch (e) {
        debugPrint(
          '❌ StorageService: Firebase Storage initialization failed: $e',
        );
        if (kDebugMode) {
          debugPrint(
            '👤 StorageService: Running in test environment - using null storage',
          );
        }
      }
    }
    return _storage;
  }

  FirebaseAuth? get _authInstance {
    if (_auth == null) {
      try {
        _auth = FirebaseAuth.instance;
      } catch (e) {
        AppLogger.error(
          '❌ StorageService: Firebase Auth initialization failed: $e',
        );
        if (kDebugMode) {
          debugPrint(
            '👤 StorageService: Running in test environment - using null auth',
          );
        }
      }
    }
    return _auth;
  }

  EnhancedStorageService get _enhancedStorageInstance {
    _enhancedStorage ??= EnhancedStorageService();
    return _enhancedStorage!;
  }

  /// Upload capture image specifically with retry logic
  Future<String> uploadCaptureImage(File file, String userId) async {
    int retryCount = 0;
    const maxRetries = 3;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    while (retryCount < maxRetries) {
      try {
        debugPrint(
          '🔄 StorageService: Starting capture image upload (attempt ${retryCount + 1})...',
        );

        // Use the optimized upload method and return just the main image URL
        // Pass timestamp to maintain consistent filename across retries
        final result = await _enhancedStorageInstance
            .uploadImageWithOptimization(
              imageFile: file,
              category: 'capture',
              generateThumbnail: true,
              timestamp: timestamp,
            );

        AppLogger.info('✅ StorageService: Capture image upload successful');
        return result['imageUrl'] ?? result.values.first;
      } catch (e) {
        retryCount++;
        AppLogger.error(
          '❌ StorageService: Upload attempt $retryCount failed: $e',
        );

        if (retryCount >= maxRetries) {
          debugPrint(
            '❌ StorageService: All attempts failed, trying fallback...',
          );
          // Fallback to legacy upload method
          return uploadImageWithRetry(file);
        }

        // Wait before retrying (exponential backoff)
        await Future<void>.delayed(Duration(seconds: retryCount * 2));
      }
    }

    throw Exception('Upload failed after $maxRetries attempts');
  }

  /// Upload with retry logic for fallback
  Future<String> uploadImageWithRetry(File file) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        return await uploadImage(file);
      } catch (e) {
        retryCount++;
        debugPrint(
          '❌ StorageService: Fallback upload attempt $retryCount failed: $e',
        );

        if (retryCount >= maxRetries) {
          rethrow;
        }

        // Wait before retrying
        await Future<void>.delayed(Duration(seconds: retryCount * 2));
      }
    }

    throw Exception('Fallback upload failed after $maxRetries attempts');
  }

  /// Upload image with optimization (recommended method)
  Future<Map<String, String>> uploadImageOptimized(File file) async {
    try {
      AppLogger.info('🔄 StorageService: Starting optimized upload...');

      final result = await _enhancedStorageInstance.uploadImageWithOptimization(
        imageFile: file,
        category: 'capture',
        generateThumbnail: true,
      );

      AppLogger.info('✅ StorageService: Optimized upload successful');
      return result;
    } catch (e) {
      AppLogger.error('❌ StorageService: Optimized upload failed: $e');
      rethrow;
    }
  }

  /// Legacy upload method (kept for backward compatibility)
  Future<String> uploadImage(File file) async {
    try {
      // Check if Firebase services are available (test environment handling)
      if (_authInstance == null || _storageInstance == null) {
        throw Exception('Firebase services not available in test environment');
      }

      // Check if user is authenticated
      final user = _authInstance!.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate file exists
      if (!await file.exists()) {
        throw Exception('Image file does not exist');
      }

      // Generate unique filename with timestamp and user ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'capture_${timestamp}_${user.uid}';

      // Use the capture_images path that already exists in your Storage
      final ref = _storageInstance!.ref().child(
        'capture_images/${user.uid}/$fileName.jpg',
      );

      AppLogger.info('StorageService: Starting upload...');
      AppLogger.info('StorageService: File path: ${file.path}');
      AppLogger.info('StorageService: File size: ${await file.length()} bytes');
      debugPrint(
        'StorageService: Storage path: capture_images/${user.uid}/$fileName.jpg',
      );
      AppLogger.info(
        'StorageService: Storage bucket: ${_storageInstance!.bucket}',
      );

      // Set metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadTime': DateTime.now().toIso8601String(),
        },
      );

      // Upload file
      final uploadTask = ref.putFile(file, metadata);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot taskSnapshot) {
        final progress =
            (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
        debugPrint(
          'StorageService: Upload progress: ${progress.toStringAsFixed(2)}%',
        );
      });

      // Wait for upload completion
      final snapshot = await uploadTask;
      AppLogger.info('StorageService: Upload completed successfully');

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      AppLogger.info('StorageService: Upload successful, URL: $downloadUrl');

      return downloadUrl;
    } on FirebaseException catch (e) {
      AppLogger.error(
        'StorageService: Firebase error: ${e.code} - ${e.message}',
      );
      throw Exception('Firebase upload failed: ${e.message}');
    } catch (e) {
      AppLogger.error('StorageService: General error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      if (_storageInstance == null) {
        throw Exception('Firebase Storage not available in test environment');
      }

      final ref = _storageInstance!.refFromURL(imageUrl);
      await ref.delete();
      AppLogger.info('StorageService: Image deleted successfully');
    } catch (e) {
      AppLogger.error('StorageService: Error deleting image: $e');
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Test Firebase Storage connectivity with detailed bucket info
  Future<bool> testStorageConnectivity() async {
    try {
      if (_authInstance == null || _storageInstance == null) {
        debugPrint(
          'StorageService: Firebase services not available in test environment',
        );
        return false;
      }

      final user = _authInstance!.currentUser;
      if (user == null) return false;

      AppLogger.info('StorageService: Testing connectivity...');
      AppLogger.info(
        'StorageService: Storage bucket: ${_storageInstance!.bucket}',
      );
      AppLogger.info('StorageService: App name: ${_storageInstance!.app.name}');
      debugPrint(
        'StorageService: Storage max upload size: ${_storageInstance!.maxUploadRetryTime}',
      );
      debugPrint(
        'StorageService: Storage max download size: ${_storageInstance!.maxDownloadRetryTime}',
      );

      // Try to list files in the root to see if we can access the bucket
      try {
        final listResult = await _storageInstance!.ref().listAll();
        debugPrint(
          'StorageService: Root directory accessible, found ${listResult.items.length} items',
        );
      } catch (e) {
        AppLogger.info('StorageService: Cannot list root directory: $e');
      }

      // Try to create a simple reference
      final testRef = _storageInstance!.ref('test_connection.txt');
      AppLogger.info(
        'StorageService: Test reference created: ${testRef.fullPath}',
      );
      AppLogger.info(
        'StorageService: Test reference bucket: ${testRef.bucket}',
      );
      AppLogger.info(
        'StorageService: Test reference storage: ${testRef.storage}',
      );

      return true;
    } catch (e) {
      AppLogger.info('StorageService: Connectivity test failed: $e');
      return false;
    }
  }

  /// Simple upload method with minimal path requirements
  Future<String> uploadImageSimple(File file) async {
    try {
      if (_authInstance == null || _storageInstance == null) {
        throw Exception('Firebase services not available in test environment');
      }

      final user = _authInstance!.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (!await file.exists()) {
        throw Exception('Image file does not exist');
      }

      // Test connectivity first
      final isConnected = await testStorageConnectivity();
      if (!isConnected) {
        throw Exception('Cannot connect to Firebase Storage');
      }

      // Use the simplest possible path - just filename in root
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'img_$timestamp.jpg';

      AppLogger.info('StorageService: Simple upload starting...');
      debugPrint(
        'StorageService: File: ${file.path} (${await file.length()} bytes)',
      );
      AppLogger.info('StorageService: Target: $fileName');

      final ref = _storageInstance!.ref(fileName);

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'timestamp': timestamp.toString(),
        },
      );

      final uploadTask = ref.putFile(file, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.info('StorageService: Simple upload successful: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      AppLogger.info('StorageService: Simple upload failed: $e');
      rethrow;
    }
  }

  /// Try uploading with explicit bucket configuration
  Future<String> uploadImageWithExplicitBucket(File file) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (!await file.exists()) {
        throw Exception('Image file does not exist');
      }

      // Try with different Firebase Storage configurations
      final storageInstances = [
        FirebaseStorage.instance,
        FirebaseStorage.instanceFor(
          bucket: 'wordnerd-artbeat.firebasestorage.app',
        ),
        FirebaseStorage.instanceFor(
          bucket: 'gs://wordnerd-artbeat.firebasestorage.app',
        ),
      ];

      for (int i = 0; i < storageInstances.length; i++) {
        try {
          final storage = storageInstances[i];
          debugPrint(
            'StorageService: Trying storage instance $i: ${storage.bucket}',
          );

          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'test_$timestamp.jpg';

          final ref = storage.ref(fileName);
          AppLogger.info('StorageService: Created reference: ${ref.fullPath}');

          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedBy': user.uid,
              'timestamp': timestamp.toString(),
            },
          );

          final uploadTask = ref.putFile(file, metadata);
          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();

          debugPrint(
            'StorageService: Explicit bucket upload successful: $downloadUrl',
          );
          return downloadUrl;
        } catch (e) {
          AppLogger.info('StorageService: Storage instance $i failed: $e');
          if (i == storageInstances.length - 1) {
            rethrow; // Last attempt failed, rethrow
          }
        }
      }

      throw Exception('All storage configurations failed');
    } catch (e) {
      AppLogger.info('StorageService: Explicit bucket upload failed: $e');
      rethrow;
    }
  }

  /// Enhanced diagnostic method to check Storage status
  Future<String> diagnosisStorageIssue() async {
    try {
      if (_authInstance == null || _storageInstance == null) {
        return 'DIAGNOSIS: Firebase services not available in test environment';
      }

      final user = _authInstance!.currentUser;
      if (user == null) {
        return 'DIAGNOSIS: User not authenticated';
      }

      AppLogger.info('=== Storage Diagnosis ===');
      AppLogger.info('User: ${user.uid}');
      AppLogger.info('Bucket: ${_storageInstance!.bucket}');

      // Test 1: Try to list root directory
      try {
        final listResult = await _storageInstance!.ref().listAll();
        debugPrint(
          'SUCCESS: Storage is enabled, found ${listResult.items.length} items',
        );
        return 'SUCCESS: Firebase Storage is properly configured';
      } catch (e) {
        AppLogger.error('List error: $e');

        if (e.toString().contains('object-not-found')) {
          return 'DIAGNOSIS: Firebase Storage is NOT ENABLED for this project. Please enable it in Firebase Console.';
        } else if (e.toString().contains('permission-denied')) {
          return 'DIAGNOSIS: Storage rules deny access. Check your storage.rules file.';
        } else {
          return 'DIAGNOSIS: Storage error - $e';
        }
      }
    } catch (e) {
      return 'DIAGNOSIS: General error - $e';
    }
  }
}
