import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

/// Service for configuring Firebase settings and timeouts
class FirebaseConfigService {
  static final FirebaseConfigService _instance =
      FirebaseConfigService._internal();
  factory FirebaseConfigService() => _instance;
  FirebaseConfigService._internal();

  /// Configure Firebase settings for optimal performance
  Future<void> configureFirebase() async {
    try {
      // Configure Firestore settings with persistence enabled
      // and proper caching for offline support
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true, // This replaces enablePersistence
        cacheSizeBytes:
            104857600, // 100MB cache - more reasonable than unlimited
        sslEnabled: true,
      );

      AppLogger.firebase(
        '✅ Firebase configured successfully with persistence enabled',
      );
    } catch (e) {
      AppLogger.error('❌ Error configuring Firebase: $e');
      if (e is FirebaseException) {
        if (e.code == 'failed-precondition') {
          // Multiple tabs open, persistence can only be enabled in one tab at a time
          AppLogger.info(
            'Multiple tabs are open, offline persistence disabled',
          );
        } else if (e.code == 'unimplemented') {
          // The current browser does not support persistence
          AppLogger.info(
            'Current platform does not support offline persistence',
          );
        }
      }
      // Continue even if configuration fails - app should still work online
    }
  }
}
