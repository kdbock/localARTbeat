import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/feedback_model.dart';
import '../utils/logger.dart';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  FirebaseFirestore? _firestoreInstance;
  FirebaseStorage? _storageInstance;
  FirebaseAuth? _authInstance;

  void initialize() {
    _firestoreInstance ??= FirebaseFirestore.instance;
    _storageInstance ??= FirebaseStorage.instance;
    _authInstance ??= FirebaseAuth.instance;
  }

  FirebaseFirestore get _firestore {
    initialize();
    return _firestoreInstance!;
  }

  FirebaseStorage get _storage {
    initialize();
    return _storageInstance!;
  }

  FirebaseAuth get _auth {
    initialize();
    return _authInstance!;
  }

  // Collection reference
  CollectionReference get _feedbackCollection =>
      _firestore.collection('developer_feedback');

  // Submit feedback
  Future<String> submitFeedback({
    required String title,
    required String description,
    required FeedbackType type,
    required FeedbackPriority priority,
    required List<String> packageModules,
    List<File>? images,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to submit feedback');
      }

      // Get device and app info
      final deviceInfo = await _getDeviceInfo();
      final appVersion = await _getAppVersion();

      // Upload images if provided
      final imageUrls = <String>[];
      if (images != null && images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final imageUrl = await _uploadImage(
            images[i],
            '${user.uid}_${DateTime.now().millisecondsSinceEpoch}_$i',
          );
          imageUrls.add(imageUrl);
        }
      }

      // Create feedback model
      final feedback = FeedbackModel(
        id: '', // Will be set by Firestore
        userId: user.uid,
        userEmail: user.email ?? '',
        userName: user.displayName ?? 'Anonymous',
        title: title,
        description: description,
        type: type,
        priority: priority,
        status: FeedbackStatus.open,
        packageModules: packageModules,
        deviceInfo: deviceInfo,
        appVersion: appVersion,
        imageUrls: imageUrls,
        metadata: additionalMetadata ?? {},
        createdAt: DateTime.now(),
      );

      // Submit to Firestore
      final docRef = await _feedbackCollection.add(feedback.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }

  // Get all feedback (for admin)
  Stream<List<FeedbackModel>> getAllFeedback() {
    return _feedbackCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FeedbackModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get feedback by status
  Stream<List<FeedbackModel>> getFeedbackByStatus(FeedbackStatus status) {
    return _feedbackCollection
        .where('status', isEqualTo: status.index)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FeedbackModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get feedback by package module
  Stream<List<FeedbackModel>> getFeedbackByPackage(String packageModule) {
    return _feedbackCollection
        .where('packageModules', arrayContains: packageModule)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FeedbackModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get user's feedback
  Stream<List<FeedbackModel>> getUserFeedback(String userId) {
    return _feedbackCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FeedbackModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Update feedback status (admin only)
  Future<void> updateFeedbackStatus(
    String feedbackId,
    FeedbackStatus newStatus,
  ) async {
    try {
      await _feedbackCollection.doc(feedbackId).update({
        'status': newStatus.index,
        'resolvedAt':
            newStatus == FeedbackStatus.resolved ||
                newStatus == FeedbackStatus.closed
            ? Timestamp.fromDate(DateTime.now())
            : null,
      });
    } catch (e) {
      throw Exception('Failed to update feedback status: $e');
    }
  }

  // Add developer response (admin only)
  Future<void> addDeveloperResponse(String feedbackId, String response) async {
    try {
      await _feedbackCollection.doc(feedbackId).update({
        'developerResponse': response,
        'status': FeedbackStatus.inProgress.index,
      });
    } catch (e) {
      throw Exception('Failed to add developer response: $e');
    }
  }

  // Delete feedback (admin only)
  Future<void> deleteFeedback(String feedbackId) async {
    try {
      // Get feedback to delete associated images
      final doc = await _feedbackCollection.doc(feedbackId).get();
      if (doc.exists) {
        final feedback = FeedbackModel.fromFirestore(doc);

        // Delete images from storage
        for (final imageUrl in feedback.imageUrls) {
          try {
            await _storage.refFromURL(imageUrl).delete();
          } catch (e) {
            // Continue even if image deletion fails
            AppLogger.error('Failed to delete image: $imageUrl, Error: $e');
          }
        }
      }

      // Delete feedback document
      await _feedbackCollection.doc(feedbackId).delete();
    } catch (e) {
      throw Exception('Failed to delete feedback: $e');
    }
  }

  // Get feedback statistics
  Future<Map<String, dynamic>> getFeedbackStats() async {
    try {
      final snapshot = await _feedbackCollection.get();
      final feedbacks = snapshot.docs
          .map((doc) => FeedbackModel.fromFirestore(doc))
          .toList();

      final stats = <String, dynamic>{
        'total': feedbacks.length,
        'open': feedbacks.where((f) => f.status == FeedbackStatus.open).length,
        'inProgress': feedbacks
            .where((f) => f.status == FeedbackStatus.inProgress)
            .length,
        'resolved': feedbacks
            .where((f) => f.status == FeedbackStatus.resolved)
            .length,
        'closed': feedbacks
            .where((f) => f.status == FeedbackStatus.closed)
            .length,
        'byType': <String, int>{},
        'byPriority': <String, int>{},
        'byPackage': <String, int>{},
      };

      // Count by type
      for (final type in FeedbackType.values) {
        stats['byType'][type.displayName] = feedbacks
            .where((f) => f.type == type)
            .length;
      }

      // Count by priority
      for (final priority in FeedbackPriority.values) {
        stats['byPriority'][priority.displayName] = feedbacks
            .where((f) => f.priority == priority)
            .length;
      }

      // Count by package
      final packageCounts = <String, int>{};
      for (final feedback in feedbacks) {
        for (final packageModule in feedback.packageModules) {
          packageCounts[packageModule] =
              (packageCounts[packageModule] ?? 0) + 1;
        }
      }
      stats['byPackage'] = packageCounts;

      return stats;
    } catch (e) {
      throw Exception('Failed to get feedback statistics: $e');
    }
  }

  // Private helper methods
  Future<String> _uploadImage(File image, String fileName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to upload images');
      }

      final ref = _storage
          .ref()
          .child('feedback_images')
          .child(user.uid)
          .child('$fileName.jpg');
      final uploadTask = ref.putFile(image);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<String> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return 'iOS ${iosInfo.systemVersion} - ${iosInfo.model}';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return 'Android ${androidInfo.version.release} - ${androidInfo.model}';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return 'macOS ${macInfo.osRelease} - ${macInfo.model}';
      } else {
        return 'Unknown Platform';
      }
    } catch (e) {
      return 'Device info unavailable';
    }
  }

  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version} (${packageInfo.buildNumber})';
    } catch (e) {
      return 'Version unavailable';
    }
  }

  // Get available package modules
  static List<String> getAvailablePackages() {
    return [
      'artbeat_core',
      'artbeat_auth',
      'artbeat_profile',
      'artbeat_artist',
      'artbeat_artwork',
      'artbeat_art_walk',
      'artbeat_community',
      'artbeat_capture',
      'artbeat_messaging',
      'artbeat_settings',
      'artbeat_admin',
      'artbeat_ads',
      'main_app',
      'general',
    ];
  }
}
