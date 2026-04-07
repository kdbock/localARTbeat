import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Centralized onboarding analytics wrapper to keep naming stable.
class OnboardingAnalyticsService {
  factory OnboardingAnalyticsService() => _instance;
  OnboardingAnalyticsService._internal() {
    _initAnalytics();
  }

  static final OnboardingAnalyticsService _instance =
      OnboardingAnalyticsService._internal();

  static const String flowUserOnboardingV1 = 'user_onboarding_v1';

  static const String eventScreenView = 'onboarding_screen_view';
  static const String eventRoleSelected = 'onboarding_role_selected';
  static const String eventPermissionResult = 'onboarding_permission_result';
  static const String eventCompletion = 'onboarding_completion';

  static const String keyFlow = 'flow';
  static const String keyStepIndex = 'step_index';
  static const String keyStepName = 'step_name';
  static const String keyRolePath = 'role_path';
  static const String keyRole = 'role';
  static const String keyPermission = 'permission';
  static const String keyResult = 'result';
  static const String keyAction = 'action';
  static const String keyEventName = 'event_name';
  static const String keyUserId = 'user_id';
  static const String keyRecordedAt = 'recorded_at';

  static const String _eventsCollection = 'onboarding_funnel_events';

  FirebaseAnalytics? _analytics;
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;

  void _initAnalytics() {
    try {
      _analytics = FirebaseAnalytics.instance;
    } on Exception catch (error) {
      core.AppLogger.warning('Onboarding analytics unavailable: $error');
    }

    try {
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
    } on Exception catch (error) {
      core.AppLogger.warning('Onboarding report storage unavailable: $error');
    }
  }

  Future<void> trackScreenView({
    required int stepIndex,
    required String stepName,
    required String rolePath,
    String flow = flowUserOnboardingV1,
  }) async {
    await _trackEvent(
      name: eventScreenView,
      parameters: {
        keyFlow: flow,
        keyStepIndex: stepIndex,
        keyStepName: stepName,
        keyRolePath: rolePath,
      },
    );
  }

  Future<void> trackRoleSelected({
    required String role,
    String flow = flowUserOnboardingV1,
  }) async {
    await _trackEvent(
      name: eventRoleSelected,
      parameters: {keyFlow: flow, keyRole: role},
    );
  }

  Future<void> trackPermissionResult({
    required String permission,
    required String result,
    required String rolePath,
    String flow = flowUserOnboardingV1,
  }) async {
    await _trackEvent(
      name: eventPermissionResult,
      parameters: {
        keyFlow: flow,
        keyPermission: permission,
        keyResult: result,
        keyRolePath: rolePath,
      },
    );
  }

  Future<void> trackCompletion({
    required String action,
    required String rolePath,
    String flow = flowUserOnboardingV1,
  }) async {
    await _trackEvent(
      name: eventCompletion,
      parameters: {keyFlow: flow, keyAction: action, keyRolePath: rolePath},
    );
  }

  Future<void> _trackEvent({
    required String name,
    required Map<String, Object> parameters,
  }) async {
    final analytics = _analytics;
    if (analytics != null) {
      try {
        await analytics.logEvent(name: name, parameters: parameters);
      } on Exception catch (error) {
        core.AppLogger.warning(
          'Onboarding analytics event failed: $name, $error',
        );
      }
    }

    final firestore = _firestore;
    if (firestore != null) {
      try {
        final eventDocument = <String, dynamic>{
          keyEventName: name,
          keyFlow: parameters[keyFlow] ?? flowUserOnboardingV1,
          keyUserId: _auth?.currentUser?.uid,
          keyRecordedAt: DateTime.now().toUtc(),
          'timestamp': FieldValue.serverTimestamp(),
          ...parameters,
        };

        await firestore.collection(_eventsCollection).add(eventDocument);
      } on Exception catch (error) {
        core.AppLogger.warning(
          'Onboarding report storage failed: $name, $error',
        );
      }
    }
  }
}
