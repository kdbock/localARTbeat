// Copyright (c) 2025 ArtBeat. All rights reserved.
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_core/firebase_options.dart';
import 'package:artbeat_messaging/artbeat_messaging.dart' as messaging;
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'config/maps_config.dart';
import 'src/managers/app_lifecycle_manager.dart';
import 'src/services/app_permission_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging system first
  AppLogger.initialize();

  // Global Flutter error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    CrashPreventionService.logCrashPrevention(
      operation: 'flutter_framework',
      errorType: details.exception.runtimeType.toString(),
      additionalInfo: details.exception.toString(),
    );

    AppLogger.error(
      'Flutter framework error: ${details.exception}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Platform-level error handling
  PlatformDispatcher.instance.onError = (error, stack) {
    CrashPreventionService.logCrashPrevention(
      operation: 'platform_error',
      errorType: error.runtimeType.toString(),
      additionalInfo: error.toString(),
    );

    AppLogger.error('Platform error: $error', error: error, stackTrace: stack);
    return true;
  };

  PerformanceMonitor.startTimer('app_startup');

  try {
    // Localization FIRST
    await EasyLocalization.ensureInitialized();

    // Lifecycle manager (non-blocking)
    AppLifecycleManager().initialize();

    // Parallel critical startup tasks
    await Future.wait([
      ConfigService.instance.initialize(),
      MapsConfig.initialize(),
      EnvLoader().init(),
    ]);

    // 🔥 FIREBASE MUST EXIST BEFORE ANYTHING ELSE
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } on FirebaseException catch (error) {
        if (error.code != 'duplicate-app') {
          rethrow;
        }
        AppLogger.warning(
          'Duplicate Firebase initialization avoided: ${error.message}',
        );
      }
    }

    try {
      await SecureFirebaseConfig.configureAppCheck(teamId: 'H49R32NPY6');
    } on Object catch (e) {
      AppLogger.error('App Check activation failed', error: e);
    }

    // Auth safety
    try {
      await AuthSafetyService.initialize();
    } on Object catch (e) {
      AppLogger.warning('⚠️ Auth Safety Service failed: $e');
    }

    // Stripe safety
    try {
      final env = EnvLoader();
      final stripeKey = env.get('STRIPE_PUBLISHABLE_KEY');
      if (stripeKey.isNotEmpty) {
        await StripeSafetyService.initialize(publishableKey: stripeKey);
      } else {
        AppLogger.warning('⚠️ STRIPE_PUBLISHABLE_KEY missing');
      }
    } on Object catch (e) {
      AppLogger.warning('⚠️ Stripe Safety Service failed: $e');
    }

    // In-app purchases
    try {
      await InAppPurchaseSetup().initialize();
    } on Object catch (e) {
      AppLogger.warning('⚠️ IAP initialization failed: $e');
    }

    _initializeNonCriticalServices();
    _initializeAppPermissions();

    PerformanceMonitor.endTimer('app_startup');

    if (kDebugMode) {
      AppLogger.firebase('✅ Firebase apps: ${Firebase.apps.length}');
      AppLogger.firebase(
        '🔍 Firebase app names: ${Firebase.apps.map((a) => a.name).toList()}',
      );
    }
  } on Object catch (e, stackTrace) {
    CrashPreventionService.logCrashPrevention(
      operation: 'app_initialization',
      errorType: e.runtimeType.toString(),
      additionalInfo: e.toString(),
    );

    if (kDebugMode) {
      AppLogger.error(
        '❌ Initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
    }

    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Error',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                const ElevatedButton(onPressed: main, child: Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
    return;
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
        Locale('pt'),
        Locale('zh'),
        Locale('ar'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MyApp(),
    ),
  );
}

/// Background services
void _initializeNonCriticalServices() {
  Future.delayed(const Duration(milliseconds: 100), () async {
    try {
      await ImageManagementService().initialize();
      AppLogger.info('✅ Image management ready');
    } on Object catch (_) {}

    try {
      await messaging.NotificationService(
        onNavigateToRoute: (route) {
          navigatorKey.currentState?.pushNamed(route);
        },
      ).initialize();
      AppLogger.info('✅ Notifications ready');
    } on Object catch (_) {}

    try {
      final stepTrackingService = StepTrackingService();
      final challengeService = ChallengeService();
      await stepTrackingService.initialize(challengeService: challengeService);
      await stepTrackingService.startTracking();
      AppLogger.info('✅ Step tracking active');
    } on Object catch (_) {}
  });
}

/// Permissions
void _initializeAppPermissions() {
  Future.delayed(const Duration(milliseconds: 500), () async {
    try {
      await AppPermissionService().initializePermissions();
      AppLogger.info('✅ Permissions initialized');
    } on Object catch (_) {}
  });
}
