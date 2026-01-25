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
      // Load from .env files if they exist
      try {
        const primaryEnv = kReleaseMode ? '.env.production' : '.env';
        await dotenv.load(fileName: primaryEnv);
        _envVars.addAll(dotenv.env);
      } catch (e) {
        AppLogger.warning(
          '⚠️ Could not load primary .env file, trying fallback: $e',
        );
        try {
          await dotenv.load(fileName: '.env');
          _envVars.addAll(dotenv.env);
        } catch (fallbackError) {
          AppLogger.warning(
            '⚠️ Could not load fallback .env file, using environment defines: $fallbackError',
          );
        }
      }

      // Merge with String.fromEnvironment for build-time overrides
      // This allows both .env files and --dart-define to work together
      final List<String> keysToCheck = [
        'API_BASE_URL',
        'GOOGLE_MAPS_API_KEY',
        'STRIPE_PUBLISHABLE_KEY',
        'FIREBASE_REGION',
        'FIREBASE_API_KEY',
        'FIREBASE_APP_ID',
        'FIREBASE_MESSAGING_SENDER_ID',
        'FIREBASE_PROJECT_ID',
        'FIREBASE_STORAGE_BUCKET',
      ];

      for (final key in keysToCheck) {
        final envValue = String.fromEnvironment(key);
        if (envValue.isNotEmpty) {
          _envVars[key] = envValue;
        }
      }

      // Set defaults for critical values if still empty
      _envVars.putIfAbsent('API_BASE_URL', () => 'https://api.artbeat.app');
      _envVars.putIfAbsent('FIREBASE_REGION', () => 'us-central1');

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
}
