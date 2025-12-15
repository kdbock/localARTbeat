// Copyright (c) 2025 ArtBeat. All rights reserved.
import 'dart:io';

import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/artbeat_core.dart';
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

  // Set up global error handling
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

  // Handle errors outside of Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    CrashPreventionService.logCrashPrevention(
      operation: 'platform_error',
      errorType: error.runtimeType.toString(),
      additionalInfo: error.toString(),
    );

    AppLogger.error('Platform error: $error', error: error, stackTrace: stack);
    return true;
  };

  // Start performance monitoring
  PerformanceMonitor.startTimer('app_startup');

  try {
    // Initialize easy_localization first
    await EasyLocalization.ensureInitialized();

    // Initialize app lifecycle manager (non-blocking)
    AppLifecycleManager().initialize();

    // Initialize critical services in parallel
    final List<Future<void>> criticalInitializations = [
      ConfigService.instance.initialize(),
      MapsConfig.initialize(),
      EnvLoader().init(),
    ];

    // Reset Firebase state on hot restart in debug mode
    if (kDebugMode) {
      SecureFirebaseConfig.resetInitializationState();
    }

    // Wait for critical services
    await Future.wait(criticalInitializations);

    // Initialize Firebase (most critical) - MUST be first
    await SecureFirebaseConfig.ensureInitialized(
      teamId: 'H49R32NPY6',
      debug: kDebugMode,
    );

    // Initialize auth safety service BEFORE any auth operations
    try {
      await AuthSafetyService.initialize();
    } on Object catch (e) {
      AppLogger.warning('⚠️ Auth Safety Service initialization failed: $e');
      // Continue - auth will be retried later
    }

    // Initialize Stripe safety service BEFORE any payment operations
    try {
      final envLoader = EnvLoader();
      final stripeKey = envLoader.get('STRIPE_PUBLISHABLE_KEY');
      if (stripeKey.isNotEmpty) {
        await StripeSafetyService.initialize(publishableKey: stripeKey);
      } else {
        AppLogger.warning('⚠️ STRIPE_PUBLISHABLE_KEY not found in environment');
      }
    } on Object catch (e) {
      AppLogger.warning('⚠️ Stripe Safety Service initialization failed: $e');
      // Continue - Stripe will be unavailable but app won't crash
    }

    // Initialize in-app purchase service with retry logic
    try {
      final crashRecovery = CrashRecoveryService();
      final iapInitialized = await crashRecovery
          .executeInitializationWithPanicRecovery(
            initialization: () async {
              await InAppPurchaseSetup().initialize();
              return true;
            },
            initName: 'InAppPurchaseSetup',
          );

      if (!iapInitialized) {
        AppLogger.warning(
          '⚠️ In-app purchase initialization failed - purchases will not be available',
        );
      }
    } on Object catch (e) {
      AppLogger.warning('⚠️ In-app purchase initialization error: $e');
      // Continue - purchases will be unavailable but app won't crash
    }

    // Initialize non-critical services in background after app starts
    _initializeNonCriticalServices();

    // Initialize app permissions
    _initializeAppPermissions();

    // End startup timing
    PerformanceMonitor.endTimer('app_startup');

    if (kDebugMode) {
      // Log Firebase status for debugging
      final status = SecureFirebaseConfig.getStatus();
      if (status['initialized'] == true) {
        AppLogger.firebase('✅ Firebase confirmed ready');
        AppLogger.firebase(
          '🔍 Firebase app names: ${Firebase.apps.map((app) => app.name).toList()}',
        );
      }
    }
  } on Object catch (e, stackTrace) {
    // Use crash prevention service for better error handling
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
      AppLogger.error('❌ Error type: ${e.runtimeType}');
      AppLogger.error('❌ Error details: ${e.toString()}');
      if (e is FileSystemException) {
        AppLogger.error('❌ File system error - Path: ${e.path}');
        AppLogger.error('❌ File system error - Message: ${e.message}');
      }
      // Print to console for immediate visibility
      print('❌❌❌ INITIALIZATION ERROR ❌❌❌');
      print('Error: $e');
      print('Stack trace: $stackTrace');
    }

    // Handle duplicate app errors specifically
    if (e.toString().contains('duplicate-app') ||
        e.toString().contains('already exists')) {
      if (kDebugMode) {
        AppLogger.warning(
          '🔥 Duplicate app error caught in main, proceeding with app launch',
        );
      }
      // Continue with app launch since Firebase is already initialized
    } else {
      // For other errors, show user-friendly error message
      final userFriendlyMessage =
          CrashPreventionService.getUserFriendlyErrorMessage(e);
      String errorDetails = userFriendlyMessage;

      if (kDebugMode) {
        errorDetails += '\n\nDebug info: ${e.toString()}';
        if (e is FileSystemException) {
          errorDetails += '\nFile: ${e.path}\nMessage: ${e.message}';
        }
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
                  Text('Error: $errorDetails', textAlign: TextAlign.center),
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

/// Initialize non-critical services in background to avoid blocking app startup
void _initializeNonCriticalServices() {
  Future.delayed(const Duration(milliseconds: 100), () async {
    // Initialize image management service
    try {
      await ImageManagementService().initialize();
      if (kDebugMode) {
        AppLogger.info('✅ Image management service initialized');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        AppLogger.error('❌ Image management service initialization failed: $e');
      }
      // Don't fail the entire app for image service
    }

    // Initialize messaging notification service
    try {
      await messaging.NotificationService().initialize();
      if (kDebugMode) {
        AppLogger.info('✅ Messaging notification service initialized');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        AppLogger.error(
          '❌ Messaging notification service initialization failed: $e',
        );
      }
      // Don't fail the entire app for notification service
    }

    // Initialize in-app purchase service
    try {
      await InAppPurchaseSetup().initialize();
      if (kDebugMode) {
        AppLogger.info('✅ In-app purchase service initialized');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        AppLogger.error('❌ In-app purchase service initialization failed: $e');
      }
      // Don't fail the entire app for purchase service
    }

    // Initialize step tracking service
    try {
      final stepTrackingService = StepTrackingService();
      final challengeService = ChallengeService();
      await stepTrackingService.initialize(challengeService: challengeService);
      await stepTrackingService.startTracking();
      if (kDebugMode) {
        AppLogger.info('✅ Step tracking service initialized and started');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        AppLogger.error('❌ Step tracking service initialization failed: $e');
      }
      // Don't fail the entire app for step tracking service
    }
  });
}

/// Initialize app permissions in background to request essential permissions
void _initializeAppPermissions() {
  Future.delayed(const Duration(milliseconds: 500), () async {
    try {
      await AppPermissionService().initializePermissions();
      if (kDebugMode) {
        AppLogger.info('✅ App permissions service initialized');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        AppLogger.error('❌ App permissions service initialization failed: $e');
      }
      // Don't fail the entire app for permission service
    }
  });
}
