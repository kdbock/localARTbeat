// Copyright (c) 2025 ArtBeat. All rights reserved.
import 'dart:async';

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

    await _initializeCoreServices();

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

  // Heavy and network-bound setup continues after first frame
  unawaited(_kickOffDeferredInits());
}

Future<void> _initializeCoreServices() async {
  await Future.wait([
    _guardedInit(ConfigService.instance.initialize, 'ConfigService'),
    _guardedInit(MapsConfig.initialize, 'MapsConfig'),
    _guardedInit(EnvLoader().init, 'EnvLoader'),
    _guardedInit(
      () async {
        debugPrint('🛡️ ========================================');
        debugPrint('🛡️ STARTING FIREBASE & APP CHECK INIT');
        debugPrint('🛡️ ========================================');
        if (Firebase.apps.isEmpty) {
          debugPrint('🛡️ Initializing Firebase Core...');
          try {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            ).timeout(const Duration(seconds: 8));
            debugPrint('🛡️ ✅ Firebase Core initialized successfully');
          } catch (e) {
            if (e.toString().contains('duplicate-app')) {
              debugPrint('🛡️ Firebase Core already initialized (duplicate-app)');
            } else {
              debugPrint('⚠️ Firebase Core initialization error: $e');
              rethrow;
            }
          }
        } else {
          debugPrint('🛡️ Firebase Core already initialized');
        }
        
        // ALWAYS Initialize App Check, even if Firebase was already initialized
        // This prevents permission denied errors during initial data fetching
        // In debug mode: uses debug provider (requires debug token in Firebase Console)
        // In release mode: uses AppAttest with DeviceCheck fallback
        debugPrint('🛡️ About to call configureAppCheck...');
        try {
          await SecureFirebaseConfig.configureAppCheck(
            teamId: 'H49R32NPY6',
            forceDebug: false, // Set to true only for debugging production App Check issues
          ).timeout(const Duration(seconds: 8));
          debugPrint('🛡️ ✅ configureAppCheck completed successfully');
        } catch (e) {
          debugPrint('⚠️ configureAppCheck error: $e');
          // Don't rethrow - allow app to continue without App Check
        }
      },
      'Firebase & App Check',
      timeout: const Duration(seconds: 20),
    ),
  ]);
}

Future<void> _kickOffDeferredInits() async {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_runDeferredInits());
  });
}

Future<void> _runDeferredInits() async {
  // Parallelize critical but deferred services
  await Future.wait([
    _guardedInit(AuthSafetyService.initialize, 'Auth Safety'),
    _guardedInit(() async {
      final env = EnvLoader();
      final stripeKey = env.get('STRIPE_PUBLISHABLE_KEY');
      if (stripeKey.isNotEmpty) {
        await StripeSafetyService.initialize(publishableKey: stripeKey);
      } else {
        AppLogger.warning('⚠️ STRIPE_PUBLISHABLE_KEY missing');
      }
    }, 'Stripe Safety'),
    _guardedInit(() => InAppPurchaseSetup().initialize(), 'IAP'),
  ]);

  // Existing non-critical background tasks
  _initializeNonCriticalServices();
  _initializeAppPermissions();
}

Future<void> _guardedInit(
  Future<void> Function() action,
  String label, {
  Duration timeout = const Duration(seconds: 4),
}) async {
  try {
    await action().timeout(timeout);
  } on TimeoutException {
    AppLogger.warning('⚠️ $label init timed out after ${timeout.inSeconds}s');
  } on Object catch (e, stack) {
    AppLogger.warning('⚠️ $label init skipped: $e');
    AppLogger.error('$label init error', error: e, stackTrace: stack);
  }
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
