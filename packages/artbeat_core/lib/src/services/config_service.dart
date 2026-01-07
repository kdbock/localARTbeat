import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import '../utils/env_loader.dart';

/// Service for managing configuration and environment variables securely
class ConfigService {
  static ConfigService? _instance;
  static ConfigService get instance => _instance ??= ConfigService._();

  ConfigService._();

  bool _isInitialized = false;
  final EnvLoader _envLoader = EnvLoader();

  /// Initialize the config service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _envLoader.init();
      _isInitialized = true;
      if (kDebugMode) {
        AppLogger.info('✅ ConfigService initialized successfully');
      }
    } catch (e) {
      // Log the error but don't fail the app initialization
      if (kDebugMode) {
        AppLogger.warning('⚠️ Failed to initialize ConfigService: $e');
        AppLogger.info('💡 App will continue with default configuration');
      }
      // Mark as initialized even if loading failed to prevent retries
      _isInitialized = true;
    }
  }

  /// Get a configuration value securely
  String? get(String key) {
    try {
      final value = _envLoader.get(key);
      return value.isEmpty ? null : value;
    } catch (e) {
      AppLogger.error('Error getting config value for $key: $e');
      return null;
    }
  }

  /// Get Firebase options securely
  Map<String, String?> get firebaseConfig => {
    'apiKey': get('FIREBASE_API_KEY'),
    'appId': get('FIREBASE_APP_ID'),
    'messagingSenderId': get('FIREBASE_MESSAGING_SENDER_ID'),
    'projectId': get('FIREBASE_PROJECT_ID'),
    'storageBucket': get('FIREBASE_STORAGE_BUCKET'),
  };

  /// Get Google Maps API key securely
  String? get googleMapsApiKey => get('GOOGLE_MAPS_API_KEY');

  /// Get Firebase App Check debug token securely
  String? get firebaseAppCheckDebugToken =>
      get('FIREBASE_APP_CHECK_DEBUG_TOKEN');
}
