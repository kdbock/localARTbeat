import 'dart:async';

import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_core/firebase_options.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../config/maps_config.dart';
import '../managers/app_lifecycle_manager.dart';

Future<void> initializeCoreStartup() async {
  try {
    await EasyLocalization.ensureInitialized().timeout(
      const Duration(seconds: 5),
    );
  } on TimeoutException {
    AppLogger.warning('⚠️ Localization init timed out');
  } on Exception catch (e) {
    AppLogger.error('❌ Localization init failed: $e');
  }

  AppLifecycleManager().initialize();

  await _guardedInit(
    EnvLoader().init,
    'EnvLoader',
    timeout: const Duration(seconds: 10),
  );
  final envValid = EnvValidator().validateAll();
  if (!envValid) {
    throw Exception('Invalid environment configuration');
  }

  await initializeFirebaseCore();
  await _guardedInit(
    ConfigService.instance.initialize,
    'ConfigService',
    timeout: const Duration(seconds: 20),
  );
  await _guardedInit(
    initializeAppCheck,
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

Future<void> initializeFirebaseCore() async {
  debugPrint('🛡️ ========================================');
  debugPrint('🛡️ STARTING FIREBASE CORE INIT');
  debugPrint('🛡️ ========================================');

  try {
    if (Firebase.apps.isNotEmpty) {
      Firebase.app();
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
    debugPrint('🛡️ ✅ Firebase Core is available after retry');
  } on Object catch (e) {
    throw StateError(
      'Firebase initialization failed; default app unavailable after retry: $e',
    );
  }
}

Future<void> initializeAppCheck() async {
  if (Firebase.apps.isEmpty) {
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
  }
}

Future<void> guardedInit(
  Future<void> Function() action,
  String label, {
  Duration timeout = const Duration(seconds: 4),
}) => _guardedInit(action, label, timeout: timeout);

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
