// Copyright (c) 2025 ArtBeat. All rights reserved.
import 'dart:async';

import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'src/bootstrap/app_error_handling.dart';
import 'src/bootstrap/core_startup.dart';
import 'src/bootstrap/deferred_startup.dart';
import 'src/bootstrap/startup_diagnostics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (forceMinimalRenderApp) {
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

  installStartupDiagnostics();

  installGlobalErrorHandlers();

  PerformanceMonitor.startTimer('app_startup');

  try {
    await initializeCoreStartup();

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
                ElevatedButton(
                  onPressed: main,
                  child: Text('common_retry'.tr()),
                ),
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
  unawaited(Future<void>(kickOffDeferredInits));
}
