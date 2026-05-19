import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/logger.dart';

/// Phase 0 UX baseline analytics for first-session startup flow.
class UxSessionAnalyticsService {
  factory UxSessionAnalyticsService() => _instance;
  UxSessionAnalyticsService._internal();
  static final UxSessionAnalyticsService _instance =
      UxSessionAnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseAuth? _auth;

  final String _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  bool _didTrackSessionStart = false;
  bool _didTrackSplashShown = false;
  bool _didTrackSplashToDashboard = false;
  bool _didTrackFirstMeaningfulAction = false;

  void _initIfNeeded() {
    if (_analytics == null) {
      try {
        _analytics = FirebaseAnalytics.instance;
      } on Exception catch (error) {
        AppLogger.warning('UX analytics unavailable: $error');
      }
    }
    if (_auth == null) {
      try {
        _auth = FirebaseAuth.instance;
      } on Exception catch (error) {
        AppLogger.warning('UX auth context unavailable: $error');
      }
    }
  }

  Future<void> trackSessionStart({required String source}) async {
    _initIfNeeded();
    if (_didTrackSessionStart) return;
    _didTrackSessionStart = true;
    await _safeLogEvent('ux_session_start', {
      'session_id': _sessionId,
      'is_authenticated': _auth?.currentUser != null ? 1 : 0,
      'source': source,
    });
  }

  Future<void> trackSplashShown() async {
    if (_didTrackSplashShown) return;
    _didTrackSplashShown = true;
    await _safeLogEvent('ux_splash_shown', {'session_id': _sessionId});
  }

  Future<void> trackSplashToDashboard({required String routeName}) async {
    if (_didTrackSplashToDashboard) return;
    _didTrackSplashToDashboard = true;
    await _safeLogEvent('ux_splash_to_dashboard', {
      'session_id': _sessionId,
      'route_name': routeName,
    });
  }

  Future<void> trackAuthInterrupt({
    required String routeName,
    required String source,
  }) async {
    await _safeLogEvent('ux_auth_interrupt', {
      'session_id': _sessionId,
      'route_name': routeName,
      'source': source,
    });
  }

  Future<void> trackRouteRendered({
    required String routeName,
    required String source,
    required int durationMs,
    required bool success,
  }) async {
    await _safeLogEvent('ux_route_rendered', {
      'session_id': _sessionId,
      'route_name': routeName,
      'source': source,
      'duration_ms': durationMs,
      'success': success ? 1 : 0,
    });
  }

  Future<void> trackFirstMeaningfulAction({
    required String action,
    required String routeName,
    required int durationMs,
  }) async {
    if (_didTrackFirstMeaningfulAction) return;
    _didTrackFirstMeaningfulAction = true;
    await _safeLogEvent('ux_first_meaningful_action', {
      'session_id': _sessionId,
      'action': action,
      'route_name': routeName,
      'duration_ms': durationMs,
    });
  }

  Future<void> trackDrawerOpen() async {
    await _safeLogEvent('ux_drawer_open', {'session_id': _sessionId});
  }

  Future<void> trackDrawerRouteTap({
    required String routeName,
    required String source,
    required bool isMainRoute,
  }) async {
    await _safeLogEvent('ux_drawer_route_tap', {
      'session_id': _sessionId,
      'route_name': routeName,
      'source': source,
      'is_main_route': isMainRoute ? 1 : 0,
    });
  }

  Future<void> trackChecklistShown({
    required String rolePath,
    required int stepCount,
  }) async {
    await _safeLogEvent('ux_checklist_shown', {
      'session_id': _sessionId,
      'role_path': rolePath,
      'step_count': stepCount,
    });
  }

  Future<void> trackChecklistStepCompleted({
    required String rolePath,
    required String step,
    required int completedCount,
    required int totalCount,
  }) async {
    await _safeLogEvent('ux_checklist_step_completed', {
      'session_id': _sessionId,
      'role_path': rolePath,
      'step': step,
      'completed_count': completedCount,
      'total_count': totalCount,
    });
  }

  Future<void> trackSimpleModeEnabled({
    required String source,
  }) async {
    await _safeLogEvent('ux_simple_mode_enabled', {
      'session_id': _sessionId,
      'source': source,
    });
  }

  Future<void> trackExploreMoreOpened({
    required String source,
  }) async {
    await _safeLogEvent('ux_explore_more_opened', {
      'session_id': _sessionId,
      'source': source,
    });
  }

  Future<void> _safeLogEvent(
    String name,
    Map<String, Object> parameters,
  ) async {
    _initIfNeeded();
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logEvent(name: name, parameters: parameters);
    } on Exception catch (error) {
      AppLogger.warning('UX analytics event failed: $name, $error');
    }
  }
}
