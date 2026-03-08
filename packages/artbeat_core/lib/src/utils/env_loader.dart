import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'logger.dart';

/// Utility class for loading environment variables and configuration
class EnvLoader {
  static final EnvLoader _instance = EnvLoader._internal();
  factory EnvLoader() => _instance;

  EnvLoader._internal();

  /// Map of environment variables
  final Map<String, String> _envVars = {};

  /// Initialize environment variables
  Future<void> init() async {
    try {
      // 1. Try to load baseline .env if it exists
      try {
        await dotenv.load(fileName: '.env');
        _envVars.addAll(dotenv.env);
        AppLogger.info('📝 Loaded baseline .env file');
      } catch (_) {
        // Ignore if .env doesn't exist
      }

      // 2. Load environment-specific file and merge
      try {
        const primaryEnv = kReleaseMode ? '.env.production' : '.env.example';

        try {
          await dotenv.load(fileName: primaryEnv);
        } catch (_) {
          // CI and shared environments typically only ship example files.
          if (kReleaseMode) {
            await dotenv.load(fileName: '.env.production.example');
          } else {
            rethrow;
          }
        }

        // Merge with care: only use real values, never placeholders.
        // Keep valid baseline values from .env when .env.example is placeholder-only.
        dotenv.env.forEach((key, value) {
          if (_isPlaceholderValue(value)) return;

          final existing = _envVars[key];
          if (existing != null &&
              existing.isNotEmpty &&
              !_isPlaceholderValue(existing)) {
            return;
          }

          _envVars[key] = value;
        });

        AppLogger.info('📝 Loaded $primaryEnv and merged configuration');
      } catch (e) {
        AppLogger.warning(
          '⚠️ Could not load primary .env file ($e), using baseline only',
        );
      }

      // 3. Merge with String.fromEnvironment for build-time overrides
      // This allows both .env files and --dart-define to work together
      // Note: We use const defines for critical variables to ensure reliability
      const apiBaseUrlDefine = String.fromEnvironment('API_BASE_URL');
      if (apiBaseUrlDefine.isNotEmpty) {
        _envVars['API_BASE_URL'] = apiBaseUrlDefine;
      }

      const stripeKeyDefine = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
      if (stripeKeyDefine.isNotEmpty) {
        _envVars['STRIPE_PUBLISHABLE_KEY'] = stripeKeyDefine;
      }

      const firebaseRegionDefine = String.fromEnvironment('FIREBASE_REGION');
      if (firebaseRegionDefine.isNotEmpty) {
        _envVars['FIREBASE_REGION'] = firebaseRegionDefine;
      }

      const googleMapsKeyDefine = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
      if (googleMapsKeyDefine.isNotEmpty) {
        _envVars['GOOGLE_MAPS_API_KEY'] = googleMapsKeyDefine;
      }

      const firebaseApiKeyDefine = String.fromEnvironment('FIREBASE_API_KEY');
      if (firebaseApiKeyDefine.isNotEmpty) {
        _envVars['FIREBASE_API_KEY'] = firebaseApiKeyDefine;
      }

      const firebaseAppIdDefine = String.fromEnvironment('FIREBASE_APP_ID');
      if (firebaseAppIdDefine.isNotEmpty) {
        _envVars['FIREBASE_APP_ID'] = firebaseAppIdDefine;
      }

      const firebaseMessagingSenderIdDefine = String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
      );
      if (firebaseMessagingSenderIdDefine.isNotEmpty) {
        _envVars['FIREBASE_MESSAGING_SENDER_ID'] =
            firebaseMessagingSenderIdDefine;
      }

      const firebaseProjectIdDefine = String.fromEnvironment(
        'FIREBASE_PROJECT_ID',
      );
      if (firebaseProjectIdDefine.isNotEmpty) {
        _envVars['FIREBASE_PROJECT_ID'] = firebaseProjectIdDefine;
      }

      const firebaseStorageBucketDefine = String.fromEnvironment(
        'FIREBASE_STORAGE_BUCKET',
      );
      if (firebaseStorageBucketDefine.isNotEmpty) {
        _envVars['FIREBASE_STORAGE_BUCKET'] = firebaseStorageBucketDefine;
      }

      const appleTeamIdDefine = String.fromEnvironment('APPLE_TEAM_ID');
      if (appleTeamIdDefine.isNotEmpty) {
        _envVars['APPLE_TEAM_ID'] = appleTeamIdDefine;
      }

      // Set defaults for critical values if still empty
      _envVars.putIfAbsent('API_BASE_URL', () => 'https://api.artbeat.app');
      _envVars.putIfAbsent('FIREBASE_REGION', () => 'us-central1');
      _envVars.putIfAbsent(
        'STRIPE_PUBLISHABLE_KEY',
        () =>
            'pk_live_51QpJ6iAO5ulTKoALD0MCyfwOCP2ivyVgKNK457uvrjJ0N9uj9Y7uSAtWfYq7nyuFZFqMjF4BHaDOYuMpwxd0PdbK00Ooktqk6z',
      );

      AppLogger.info(
        '✅ Environment variables loaded successfully (${_envVars.length} variables)',
      );
    } catch (e) {
      AppLogger.error('❌ Error loading environment variables: $e');
    }
  }

  /// Get an environment variable value
  String get(String key, {String defaultValue = ''}) {
    return _envVars[key] ?? defaultValue;
  }

  /// Check if an environment variable exists
  bool has(String key) {
    return _envVars.containsKey(key);
  }

  /// Get all environment variables
  Map<String, String> getAll() {
    return Map.unmodifiable(_envVars);
  }

  bool _isPlaceholderValue(String value) {
    final v = value.trim();
    if (v.isEmpty) return true;

    return v.contains(r'${') ||
        v.contains('XXXXXXXX') ||
        v.toLowerCase().contains('your_') ||
        v.toLowerCase().contains('placeholder');
  }
}
