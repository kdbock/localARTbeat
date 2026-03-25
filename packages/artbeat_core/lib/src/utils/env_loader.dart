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
      // 1. Load the single local runtime env file when present.
      // `.env.example` is documentation only and is not used at runtime.
      try {
        await dotenv.load(fileName: '.env');
        _envVars.addAll(dotenv.env);
        AppLogger.info('📝 Loaded local .env file');
      } catch (_) {
        AppLogger.info(
          '📝 No local .env file found. Falling back to build-time defines.',
        );
      }

      // 2. Merge with String.fromEnvironment for build-time overrides.
      // CI/release should prefer explicit `--dart-define` values.
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

      const firebaseFunctionsBaseUrlDefine = String.fromEnvironment(
        'FIREBASE_FUNCTIONS_BASE_URL',
      );
      if (firebaseFunctionsBaseUrlDefine.isNotEmpty) {
        _envVars['FIREBASE_FUNCTIONS_BASE_URL'] =
            firebaseFunctionsBaseUrlDefine;
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
      _envVars.putIfAbsent('FIREBASE_PROJECT_ID', () => 'wordnerd-artbeat');

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

  /// Resolve the Firebase Cloud Functions base URL for the active environment.
  String get cloudFunctionsBaseUrl {
    final configuredBaseUrl = get('FIREBASE_FUNCTIONS_BASE_URL').trim();
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    final region = get('FIREBASE_REGION', defaultValue: 'us-central1').trim();
    final projectId = get(
      'FIREBASE_PROJECT_ID',
      defaultValue: 'wordnerd-artbeat',
    ).trim();

    return 'https://$region-$projectId.cloudfunctions.net';
  }

  /// Get all environment variables
  Map<String, String> getAll() {
    return Map.unmodifiable(_envVars);
  }

}
