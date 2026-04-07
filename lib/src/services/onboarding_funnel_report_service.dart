import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'onboarding_analytics_service.dart';

class OnboardingFunnelReport {
  OnboardingFunnelReport({
    required this.totalEvents,
    required this.screenViews,
    required this.roleSelections,
    required this.permissionResults,
    required this.completions,
    required this.completionRate,
    required this.generatedAt,
  });

  final int totalEvents;
  final int screenViews;
  final Map<String, int> roleSelections;
  final Map<String, int> permissionResults;
  final Map<String, int> completions;
  final double completionRate;
  final DateTime generatedAt;
}

class OnboardingFunnelReportService {
  factory OnboardingFunnelReportService() => _instance;
  OnboardingFunnelReportService._internal() {
    _initFirestore();
  }

  static final OnboardingFunnelReportService _instance =
      OnboardingFunnelReportService._internal();

  static const String _eventsCollection = 'onboarding_funnel_events';
  FirebaseFirestore? _firestore;

  void _initFirestore() {
    try {
      _firestore = FirebaseFirestore.instance;
    } on Exception catch (error) {
      core.AppLogger.warning('Onboarding report query unavailable: $error');
    }
  }

  Future<OnboardingFunnelReport> getReport({
    String flow = OnboardingAnalyticsService.flowUserOnboardingV1,
    Duration lookback = const Duration(days: 7),
    int maxRows = 2000,
  }) async {
    final firestore = _firestore;
    if (firestore == null) {
      return OnboardingFunnelReport(
        totalEvents: 0,
        screenViews: 0,
        roleSelections: const {},
        permissionResults: const {},
        completions: const {},
        completionRate: 0,
        generatedAt: DateTime.now(),
      );
    }

    final nowUtc = DateTime.now().toUtc();
    final sinceUtc = nowUtc.subtract(lookback);

    try {
      final snapshot = await firestore
          .collection(_eventsCollection)
          .where(OnboardingAnalyticsService.keyFlow, isEqualTo: flow)
          .limit(maxRows)
          .get();

      final docs = snapshot.docs.where((doc) {
        final data = doc.data();
        final recordedAt = _extractDateTime(
          data[OnboardingAnalyticsService.keyRecordedAt],
        );
        return recordedAt != null && !recordedAt.isBefore(sinceUtc);
      });

      var totalEvents = 0;
      var screenViews = 0;
      final roleSelections = <String, int>{};
      final permissionResults = <String, int>{};
      final completions = <String, int>{};

      for (final doc in docs) {
        totalEvents += 1;
        final data = doc.data();
        final eventName =
            (data[OnboardingAnalyticsService.keyEventName] as String?) ?? '';

        if (eventName == OnboardingAnalyticsService.eventScreenView) {
          screenViews += 1;
        }

        if (eventName == OnboardingAnalyticsService.eventRoleSelected) {
          final role =
              (data[OnboardingAnalyticsService.keyRole] as String?) ??
              'unknown';
          roleSelections[role] = (roleSelections[role] ?? 0) + 1;
        }

        if (eventName == OnboardingAnalyticsService.eventPermissionResult) {
          final permission =
              (data[OnboardingAnalyticsService.keyPermission] as String?) ??
              'unknown';
          final result =
              (data[OnboardingAnalyticsService.keyResult] as String?) ??
              'unknown';
          final key = '$permission:$result';
          permissionResults[key] = (permissionResults[key] ?? 0) + 1;
        }

        if (eventName == OnboardingAnalyticsService.eventCompletion) {
          final action =
              (data[OnboardingAnalyticsService.keyAction] as String?) ??
              'unknown';
          completions[action] = (completions[action] ?? 0) + 1;
        }
      }

      final roleSelectionCount = roleSelections.values.fold<int>(
        0,
        (runningTotal, value) => runningTotal + value,
      );
      final completionCount = completions.values.fold<int>(
        0,
        (runningTotal, value) => runningTotal + value,
      );
      final completionRate = roleSelectionCount == 0
          ? 0.0
          : completionCount / roleSelectionCount;

      return OnboardingFunnelReport(
        totalEvents: totalEvents,
        screenViews: screenViews,
        roleSelections: roleSelections,
        permissionResults: permissionResults,
        completions: completions,
        completionRate: completionRate,
        generatedAt: DateTime.now(),
      );
    } on Exception catch (error) {
      core.AppLogger.warning('Onboarding report query failed: $error');
      return OnboardingFunnelReport(
        totalEvents: 0,
        screenViews: 0,
        roleSelections: const {},
        permissionResults: const {},
        completions: const {},
        completionRate: 0,
        generatedAt: DateTime.now(),
      );
    }
  }

  DateTime? _extractDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate().toUtc();
    }
    if (value is DateTime) {
      return value.toUtc();
    }
    return null;
  }
}
