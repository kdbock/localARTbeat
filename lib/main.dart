// Copyright (c) 2025 ArtBeat. All rights reserved.
import 'dart:async';
import 'dart:developer' as developer;

import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_core/firebase_options.dart';
import 'package:artbeat_messaging/artbeat_messaging.dart' as messaging;
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'app.dart';
import 'config/maps_config.dart';
import 'src/bootstrap/app_error_handling.dart';
import 'src/managers/app_lifecycle_manager.dart';
import 'src/services/app_permission_service.dart';

bool _performanceDiagnosticsInstalled = false;
bool _tapFrameCallbackScheduled = false;
final List<_PendingTapTrace> _pendingTapTraces = [];
// Toggle verbose rebuild tracing via --dart-define=VERBOSE_REBUILDS=true
const bool _enableVerboseRebuildLogging =
    // ignore: do_not_use_environment
    bool.fromEnvironment('VERBOSE_REBUILDS');
const bool _forceMinimalRenderApp =
    // ignore: do_not_use_environment
    bool.fromEnvironment('FORCE_MINIMAL_APP');
const Duration _slowFrameThreshold = Duration(milliseconds: 32);
const Duration _slowTapThreshold = Duration(milliseconds: 120);
Timer? _imageCacheStatsTimer;
bool _firebaseCoreReady = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_forceMinimalRenderApp) {
    runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF00AAFF),
          body: Center(
            child: Text(
              'FORCE_MINIMAL_APP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  // Initialize logging system first
  AppLogger.initialize();

  _installPerformanceDiagnostics();
  _enableDebugBuildFlags(_enableVerboseRebuildLogging);

  installGlobalErrorHandlers();

  PerformanceMonitor.startTimer('app_startup');

  try {
    // Localization FIRST
    try {
      await EasyLocalization.ensureInitialized().timeout(
        const Duration(seconds: 5),
      );
    } on TimeoutException {
      AppLogger.warning('⚠️ Localization init timed out');
    } on Exception catch (e) {
      AppLogger.error('❌ Localization init failed: $e');
    }

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

void _installPerformanceDiagnostics() {
  if (_performanceDiagnosticsInstalled || kReleaseMode) return;
  _performanceDiagnosticsInstalled = true;

  WidgetsBinding.instance.addTimingsCallback(_handleFrameTimings);
  GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
  _imageCacheStatsTimer?.cancel();
  _imageCacheStatsTimer = Timer.periodic(
    const Duration(seconds: 30),
    (_) => ImageManagementService().logCacheStats(label: 'periodic'),
  );
  Timer(
    const Duration(seconds: 6),
    () => ImageManagementService().logCacheStats(label: 'startup'),
  );
}

void _enableDebugBuildFlags(bool enableVerboseRebuilds) {
  if (!kDebugMode) return;
  debugProfileBuildsEnabled = true;
  debugProfilePaintsEnabled = true;
  debugPrintRebuildDirtyWidgets = enableVerboseRebuilds;
  developer.Timeline.instantSync(
    'DebugFlags.Enabled',
    arguments: {
      'profileBuilds': debugProfileBuildsEnabled,
      'profilePaints': debugProfilePaintsEnabled,
      'printRebuilds': debugPrintRebuildDirtyWidgets,
    },
  );
  AppLogger.info(
    '⚙️ Debug build profiling enabled: '
    'builds=$debugProfileBuildsEnabled paints=$debugProfilePaintsEnabled '
    'rebuilds=$debugPrintRebuildDirtyWidgets (verbose=$enableVerboseRebuilds)',
  );
}

void _handleFrameTimings(List<FrameTiming> timings) {
  for (final timing in timings) {
    final total = timing.totalSpan;
    if (total <= _slowFrameThreshold) {
      continue;
    }
    developer.Timeline.instantSync(
      'UI.SlowFrame',
      arguments: {
        'totalMs': total.inMilliseconds,
        'buildMs': timing.buildDuration.inMilliseconds,
        'rasterMs': timing.rasterDuration.inMilliseconds,
      },
    );
    AppLogger.warning(
      '⚠️ Slow frame: total=${total.inMilliseconds}ms '
      'build=${timing.buildDuration.inMilliseconds}ms '
      'raster=${timing.rasterDuration.inMilliseconds}ms',
    );
  }
}

void _handlePointerEvent(PointerEvent event) {
  if (event is! PointerDownEvent) return;
  final task = developer.TimelineTask()
    ..start(
      'UI.TapToFrame',
      arguments: {
        'kind': event.kind.toString(),
        'x': event.position.dx.round(),
        'y': event.position.dy.round(),
      },
    );
  final trace = _PendingTapTrace(task);
  _pendingTapTraces.add(trace);

  if (_tapFrameCallbackScheduled) {
    return;
  }
  _tapFrameCallbackScheduled = true;
  SchedulerBinding.instance.addPostFrameCallback((_) {
    _tapFrameCallbackScheduled = false;
    for (final pending in _pendingTapTraces) {
      pending.finish();
    }
    _pendingTapTraces.clear();
  });
}

class _PendingTapTrace {
  _PendingTapTrace(this.task) : stopwatch = Stopwatch()..start();

  final developer.TimelineTask task;
  final Stopwatch stopwatch;

  void finish() {
    stopwatch.stop();
    task.finish();
    if (stopwatch.elapsed >= _slowTapThreshold) {
      developer.Timeline.instantSync(
        'UI.SlowTap',
        arguments: {'tapToFrameMs': stopwatch.elapsedMilliseconds},
      );
      AppLogger.warning(
        '⚠️ Slow tap-to-frame: ${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }
}

Future<void> _initializeCoreServices() async {
  await _guardedInit(
    EnvLoader().init,
    'EnvLoader',
    timeout: const Duration(seconds: 10),
  );
  final envValid = EnvValidator().validateAll();
  if (!envValid && kReleaseMode) {
    throw Exception('Missing required environment variables');
  }

  await _initializeFirebaseCore();
  await _guardedInit(
    ConfigService.instance.initialize,
    'ConfigService',
    timeout: const Duration(seconds: 20),
  );
  await _guardedInit(
    _initializeAppCheck,
    'App Check',
    timeout: const Duration(seconds: 20),
  );

  await Future.wait([
    _guardedInit(
      () => ImageManagementService().initialize(),
      'ImageManagementService',
    ),
    _guardedInit(MapsConfig.initialize, 'MapsConfig'),
  ]);
}

Future<void> _initializeFirebaseCore() async {
  debugPrint('🛡️ ========================================');
  debugPrint('🛡️ STARTING FIREBASE CORE INIT');
  debugPrint('🛡️ ========================================');

  try {
    if (Firebase.apps.isNotEmpty) {
      Firebase.app();
      _firebaseCoreReady = true;
      debugPrint('🛡️ Firebase Core already initialized');
      return;
    }
  } on Object catch (e) {
    debugPrint('⚠️ Existing Firebase app check failed: $e');
  }

  try {
    debugPrint('🛡️ Initializing Firebase Core (attempt 1, 8s timeout)...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
    _firebaseCoreReady = true;
    debugPrint('🛡️ ✅ Firebase Core initialized successfully');
    return;
  } on TimeoutException catch (e) {
    debugPrint('⚠️ Firebase Core initialization timed out: $e');
  } on Object catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      debugPrint('⚠️ Firebase Core initialization error: $e');
    }
  }

  try {
    debugPrint('🛡️ Retrying Firebase Core init (attempt 2, 20s timeout)...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 20));
  } on Object catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      debugPrint('⚠️ Firebase Core retry failed: $e');
    }
  }

  try {
    Firebase.app();
    _firebaseCoreReady = true;
    debugPrint('🛡️ ✅ Firebase Core is available after retry');
  } on Object catch (e) {
    _firebaseCoreReady = false;
    throw StateError(
      'Firebase initialization failed; default app unavailable after retry: $e',
    );
  }
}

Future<void> _initializeAppCheck() async {
  if (!_firebaseCoreReady) {
    AppLogger.warning('⚠️ Skipping App Check: Firebase Core not ready');
    return;
  }

  debugPrint('🛡️ About to call configureAppCheck...');
  try {
    final debugToken = ConfigService.instance.firebaseAppCheckDebugToken;
    await SecureFirebaseConfig.configureAppCheck(
      teamId: 'H49R32NPY6',
      debugToken: debugToken,
    ).timeout(const Duration(seconds: 8));
    debugPrint('🛡️ ✅ configureAppCheck completed successfully');
  } on Exception catch (e) {
    debugPrint('⚠️ configureAppCheck error: $e');
    // Don't rethrow - allow app to continue without App Check
  }
}

Future<void> _kickOffDeferredInits() async {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_runDeferredInits());
  });
}

Future<void> _runDeferredInits() async {
  // Parallelize critical but deferred services
  final deferredInits = <Future<void>>[
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
  ];

  await Future.wait(deferredInits);

  // Existing non-critical background tasks
  _initializeNonCriticalServices(firebaseReady: _firebaseCoreReady);
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
void _initializeNonCriticalServices({required bool firebaseReady}) {
  Future.delayed(const Duration(milliseconds: 100), () async {
    if (firebaseReady) {
      try {
        await messaging.NotificationService(
          onNavigateToRoute: (route) {
            navigatorKey.currentState?.pushNamed(route);
          },
        ).initialize();
        AppLogger.info('✅ Notifications ready');
      } on Object catch (_) {}
    } else {
      AppLogger.warning(
        '⚠️ Skipping notification startup: Firebase Core unavailable',
      );
    }

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
