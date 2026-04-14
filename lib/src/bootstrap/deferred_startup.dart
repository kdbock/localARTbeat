import 'dart:async';

import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_messaging/artbeat_messaging.dart' as messaging;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../app.dart';
import '../services/app_permission_service.dart';
import 'core_startup.dart';

void kickOffDeferredInits() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_runDeferredInits());
  });
}

Future<void> _runDeferredInits() async {
  final deferredInits = <Future<void>>[
    guardedInit(AuthSafetyService.initialize, 'Auth Safety'),
    guardedInit(() async {
      final env = EnvLoader();
      final stripeKey = env.getRequired('STRIPE_PUBLISHABLE_KEY');
      final stripeMode = stripeKey.startsWith('pk_live_')
          ? 'pk_live'
          : stripeKey.startsWith('pk_test_')
          ? 'pk_test'
          : 'unknown';
      AppLogger.info('💳 Active Stripe publishable key mode: $stripeMode');
      await StripeSafetyService.initialize(publishableKey: stripeKey);
    }, 'Stripe Safety'),
    guardedInit(() => InAppPurchaseSetup().initialize(), 'IAP'),
  ];

  await Future.wait(deferredInits);

  _initializeNonCriticalServices();
  _initializeAppPermissions();
}

void _initializeNonCriticalServices() {
  Future.delayed(const Duration(milliseconds: 100), () async {
    if (Firebase.apps.isNotEmpty) {
      try {
        await messaging.NotificationService(
          onNavigateToRoute: (route) {
            navigatorKey.currentState?.pushNamed(route);
          },
        ).initialize();
        AppLogger.info('✅ Notifications ready');
      } on Object catch (error, stackTrace) {
        _logDeferredInitFailure(
          stage: 'non_critical.notifications',
          error: error,
          stackTrace: stackTrace,
        );
      }
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
    } on Object catch (error, stackTrace) {
      _logDeferredInitFailure(
        stage: 'non_critical.step_tracking',
        error: error,
        stackTrace: stackTrace,
      );
    }
  });
}

void _initializeAppPermissions() {
  Future.delayed(const Duration(milliseconds: 500), () async {
    try {
      await AppPermissionService().initializePermissions();
      AppLogger.info('✅ Permissions initialized');
    } on Object catch (error, stackTrace) {
      _logDeferredInitFailure(
        stage: 'non_critical.permissions',
        error: error,
        stackTrace: stackTrace,
      );
    }
  });
}

void _logDeferredInitFailure({
  required String stage,
  required Object error,
  required StackTrace stackTrace,
}) {
  AppLogger.warning(
    '⚠️ Deferred startup stage failed: $stage',
    error: error,
    stackTrace: stackTrace,
  );
  AppLogger.error(
    'Deferred startup diagnostics',
    error: error,
    stackTrace: stackTrace,
    logger: 'DeferredStartup',
  );
}
