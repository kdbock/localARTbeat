import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Analytics Integration Service for capture performance tracking
/// Provides comprehensive analytics for capture usage and performance
class CaptureAnalyticsService extends ChangeNotifier {
  static final CaptureAnalyticsService _instance =
      CaptureAnalyticsService._internal();
  factory CaptureAnalyticsService() => _instance;
  CaptureAnalyticsService._internal();

  FirebaseFirestore? _firestoreInstance;
  FirebaseAuth? _authInstance;

  FirebaseFirestore get _firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authInstance ??= FirebaseAuth.instance;

  // Analytics data
  final Map<String, dynamic> _captureMetrics = {};
  final Map<String, dynamic> _userBehavior = {};
  final Map<String, dynamic> _performanceMetrics = {};
  final List<Map<String, dynamic>> _recentEvents = [];

  // ==========================================
  // EVENT TRACKING METHODS
  // ==========================================

  /// Track capture session start
  Future<void> trackCaptureSessionStart({
    String? cameraType,
    String? resolutionPreset,
    Map<String, dynamic>? additionalData,
  }) async {
    await _trackEvent('capture_session_start', {
      'cameraType': cameraType,
      'resolutionPreset': resolutionPreset,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Track capture session end
  Future<void> trackCaptureSessionEnd({
    required Duration sessionDuration,
    required int capturesCount,
    String? endReason,
    Map<String, dynamic>? additionalData,
  }) async {
    await _trackEvent('capture_session_end', {
      'sessionDuration': sessionDuration.inSeconds,
      'capturesCount': capturesCount,
      'endReason': endReason,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Track individual capture
  Future<void> trackCapture({
    required String captureType, // 'photo', 'video', 'burst'
    required String cameraMode, // 'auto', 'manual', 'advanced'
    double? processingTime,
    bool? useFlash,
    double? zoomLevel,
    String? resolution,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? additionalData,
  }) async {
    await _trackEvent('capture_taken', {
      'captureType': captureType,
      'cameraMode': cameraMode,
      'processingTime': processingTime,
      'useFlash': useFlash,
      'zoomLevel': zoomLevel,
      'resolution': resolution,
      'settings': settings,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Track camera feature usage
  Future<void> trackFeatureUsage({
    required String feature, // 'zoom', 'flash', 'timer', 'burst', 'hdr', etc.
    required String action, // 'enabled', 'disabled', 'used'
    dynamic value,
    Map<String, dynamic>? additionalData,
  }) async {
    await _trackEvent('feature_usage', {
      'feature': feature,
      'action': action,
      'value': value,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Track image processing usage
  Future<void> trackImageProcessing({
    required String processingType, // 'filter', 'enhancement', 'ai_analysis'
    required Duration processingTime,
    bool? success,
    String? errorMessage,
    Map<String, dynamic>? processingSettings,
  }) async {
    await _trackEvent('image_processing', {
      'processingType': processingType,
      'processingTime': processingTime.inMilliseconds,
      'success': success,
      'errorMessage': errorMessage,
      'processingSettings': processingSettings,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track AI/ML analysis usage
  Future<void> trackAIAnalysis({
    required String analysisType, // 'tags', 'style', 'colors', 'objects'
    required Duration analysisTime,
    double? confidence,
    int? tagsGenerated,
    bool? success,
    String? errorMessage,
  }) async {
    await _trackEvent('ai_analysis', {
      'analysisType': analysisType,
      'analysisTime': analysisTime.inMilliseconds,
      'confidence': confidence,
      'tagsGenerated': tagsGenerated,
      'success': success,
      'errorMessage': errorMessage,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track user interaction
  Future<void> trackUserInteraction({
    required String interaction, // 'tap', 'swipe', 'pinch', 'long_press'
    required String element, // 'capture_button', 'settings', 'gallery'
    Map<String, dynamic>? context,
  }) async {
    await _trackEvent('user_interaction', {
      'interaction': interaction,
      'element': element,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track performance metrics
  Future<void> trackPerformance({
    required String metric, // 'app_launch', 'camera_init', 'capture_save'
    required Duration duration,
    bool? success,
    String? errorMessage,
    Map<String, dynamic>? additionalData,
  }) async {
    await _trackEvent('performance_metric', {
      'metric': metric,
      'duration': duration.inMilliseconds,
      'success': success,
      'errorMessage': errorMessage,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Track error events
  Future<void> trackError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    await _trackEvent('error', {
      'errorType': errorType,
      'errorMessage': errorMessage,
      'stackTrace': stackTrace,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  // ==========================================
  // ANALYTICS RETRIEVAL METHODS
  // ==========================================

  /// Get capture analytics for a date range
  Future<Map<String, dynamic>> getCaptureAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();
      userId ??= _auth.currentUser?.uid;

      if (userId == null) {
        return {'error': 'User not authenticated'};
      }

      // Query analytics events
      final Query query = _firestore
          .collection('captureAnalytics')
          .where('userId', isEqualTo: userId)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      final snapshot = await query.get();
      final events = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Analyze the events
      return _analyzeEvents(events);
    } catch (e) {
      AppLogger.error('CaptureAnalyticsService: Error getting analytics: $e');
      return {'error': e.toString()};
    }
  }

  /// Get user behavior insights
  Future<Map<String, dynamic>> getUserBehaviorInsights({
    String? userId,
    int days = 30,
  }) async {
    try {
      userId ??= _auth.currentUser?.uid;
      if (userId == null) return {'error': 'User not authenticated'};

      final startDate = DateTime.now().subtract(Duration(days: days));
      final analytics = await getCaptureAnalytics(
        startDate: startDate,
        userId: userId,
      );

      if (analytics.containsKey('error')) return analytics;

      return {
        'mostUsedFeatures': analytics['featureUsage'] ?? <String, dynamic>{},
        'preferredCaptureTypes':
            analytics['captureTypes'] ?? <String, dynamic>{},
        'averageSessionDuration': analytics['averageSessionDuration'] ?? 0,
        'captureFrequency':
            analytics['captureFrequency'] ?? <String, dynamic>{},
        'peakUsageHours': analytics['peakUsageHours'] ?? <dynamic>[],
        'errorRate': analytics['errorRate'] ?? 0.0,
      };
    } catch (e) {
      debugPrint(
        'CaptureAnalyticsService: Error getting behavior insights: $e',
      );
      return {'error': e.toString()};
    }
  }

  /// Get performance metrics
  Future<Map<String, dynamic>> getPerformanceMetrics({
    String? userId,
    int days = 7,
  }) async {
    try {
      userId ??= _auth.currentUser?.uid;
      if (userId == null) return {'error': 'User not authenticated'};

      final startDate = DateTime.now().subtract(Duration(days: days));

      final Query query = _firestore
          .collection('captureAnalytics')
          .where('userId', isEqualTo: userId)
          .where('eventType', isEqualTo: 'performance_metric')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          );

      final snapshot = await query.get();
      final events = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      return _analyzePerformanceEvents(events);
    } catch (e) {
      debugPrint(
        'CaptureAnalyticsService: Error getting performance metrics: $e',
      );
      return {'error': e.toString()};
    }
  }

  /// Get real-time statistics
  Future<Map<String, dynamic>> getRealTimeStatistics() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {'error': 'User not authenticated'};

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final todayAnalytics = await getCaptureAnalytics(
        startDate: startOfDay,
        userId: userId,
      );

      return {
        'todayCaptureCount': todayAnalytics['totalCaptures'] ?? 0,
        'todaySessionCount': todayAnalytics['totalSessions'] ?? 0,
        'todaySessionDuration': todayAnalytics['totalSessionDuration'] ?? 0,
        'todayErrorCount': todayAnalytics['totalErrors'] ?? 0,
        'currentStreak': await _calculateCaptureStreak(userId),
        'lastCaptureTime': todayAnalytics['lastCaptureTime'],
      };
    } catch (e) {
      AppLogger.error(
        'CaptureAnalyticsService: Error getting real-time stats: $e',
      );
      return {'error': e.toString()};
    }
  }

  // ==========================================
  // ANALYSIS HELPER METHODS
  // ==========================================

  /// Analyze events to generate insights
  Map<String, dynamic> _analyzeEvents(List<Map<String, dynamic>> events) {
    final analysis = <String, dynamic>{};

    // Count events by type
    final eventCounts = <String, int>{};
    final captureTypes = <String, int>{};
    final featureUsage = <String, int>{};
    final errors = <Map<String, dynamic>>[];
    final sessionDurations = <int>[];

    for (final event in events) {
      final eventType = event['eventType'] as String? ?? 'unknown';
      eventCounts[eventType] = (eventCounts[eventType] ?? 0) + 1;

      switch (eventType) {
        case 'capture_taken':
          final captureType =
              event['data']['captureType'] as String? ?? 'unknown';
          captureTypes[captureType] = (captureTypes[captureType] ?? 0) + 1;
          break;
        case 'feature_usage':
          final feature = event['data']['feature'] as String? ?? 'unknown';
          featureUsage[feature] = (featureUsage[feature] ?? 0) + 1;
          break;
        case 'capture_session_end':
          final duration = event['data']['sessionDuration'] as int? ?? 0;
          sessionDurations.add(duration);
          break;
        case 'error':
          errors.add(event['data'] as Map<String, dynamic>? ?? {});
          break;
      }
    }

    // Calculate statistics
    analysis['totalEvents'] = events.length;
    analysis['eventCounts'] = eventCounts;
    analysis['totalCaptures'] = captureTypes.values.fold(
      0,
      (sum, count) => sum + count,
    );
    analysis['captureTypes'] = captureTypes;
    analysis['featureUsage'] = featureUsage;
    analysis['totalErrors'] = errors.length;
    analysis['errorRate'] = events.isNotEmpty
        ? errors.length / events.length
        : 0.0;
    analysis['totalSessions'] = eventCounts['capture_session_end'] ?? 0;

    if (sessionDurations.isNotEmpty) {
      analysis['averageSessionDuration'] =
          sessionDurations.reduce((a, b) => a + b) / sessionDurations.length;
      analysis['totalSessionDuration'] = sessionDurations.reduce(
        (a, b) => a + b,
      );
    }

    // Peak usage analysis
    analysis['peakUsageHours'] = _analyzePeakUsage(events);
    analysis['captureFrequency'] = _analyzeCaptureFrequency(events);

    return analysis;
  }

  /// Analyze performance events
  Map<String, dynamic> _analyzePerformanceEvents(
    List<Map<String, dynamic>> events,
  ) {
    final metrics = <String, List<int>>{};

    for (final event in events) {
      final data = event['data'] as Map<String, dynamic>? ?? {};
      final metric = data['metric'] as String? ?? 'unknown';
      final duration = data['duration'] as int? ?? 0;

      if (!metrics.containsKey(metric)) {
        metrics[metric] = [];
      }
      metrics[metric]!.add(duration);
    }

    final analysis = <String, dynamic>{};

    for (final entry in metrics.entries) {
      final metricName = entry.key;
      final durations = entry.value;

      if (durations.isNotEmpty) {
        durations.sort();
        analysis[metricName] = {
          'average': durations.reduce((a, b) => a + b) / durations.length,
          'median': durations[durations.length ~/ 2],
          'min': durations.first,
          'max': durations.last,
          'count': durations.length,
        };
      }
    }

    return analysis;
  }

  /// Analyze peak usage hours
  List<int> _analyzePeakUsage(List<Map<String, dynamic>> events) {
    final hourCounts = <int, int>{};

    for (final event in events) {
      final timestamp = event['data']['timestamp'] as String?;
      if (timestamp != null) {
        final dateTime = DateTime.tryParse(timestamp);
        if (dateTime != null) {
          final hour = dateTime.hour;
          hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
        }
      }
    }

    final sortedHours = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedHours.take(3).map((e) => e.key).toList();
  }

  /// Analyze capture frequency
  Map<String, int> _analyzeCaptureFrequency(List<Map<String, dynamic>> events) {
    final dailyCounts = <String, int>{};

    for (final event in events) {
      if (event['eventType'] == 'capture_taken') {
        final timestamp = event['data']['timestamp'] as String?;
        if (timestamp != null) {
          final dateTime = DateTime.tryParse(timestamp);
          if (dateTime != null) {
            final dateKey =
                '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
            dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
          }
        }
      }
    }

    return dailyCounts;
  }

  /// Calculate capture streak
  Future<int> _calculateCaptureStreak(String userId) async {
    try {
      // Get recent capture events
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final Query query = _firestore
          .collection('captureAnalytics')
          .where('userId', isEqualTo: userId)
          .where('eventType', isEqualTo: 'capture_taken')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo),
          )
          .orderBy('timestamp', descending: true);

      final snapshot = await query.get();
      final events = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Calculate streak
      int streak = 0;
      final today = DateTime.now();
      DateTime currentDate = DateTime(today.year, today.month, today.day);

      final captureDates = <String>{};
      for (final event in events) {
        final timestamp = event['data']['timestamp'] as String?;
        if (timestamp != null) {
          final dateTime = DateTime.tryParse(timestamp);
          if (dateTime != null) {
            final dateKey =
                '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
            captureDates.add(dateKey);
          }
        }
      }

      // Count consecutive days with captures
      while (true) {
        final dateKey =
            '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
        if (captureDates.contains(dateKey)) {
          streak++;
          currentDate = currentDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      AppLogger.error('CaptureAnalyticsService: Error calculating streak: $e');
      return 0;
    }
  }

  // ==========================================
  // CORE TRACKING METHOD
  // ==========================================

  /// Track an analytics event
  Future<void> _trackEvent(String eventType, Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final event = {
        'userId': user.uid,
        'eventType': eventType,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
        'appVersion': '1.0.0', // This should come from package info
        'platform': defaultTargetPlatform.toString(),
      };

      await _firestore.collection('captureAnalytics').add(event);

      // Update local recent events
      _recentEvents.insert(0, event);
      if (_recentEvents.length > 100) {
        _recentEvents.removeLast();
      }

      notifyListeners();
    } catch (e) {
      AppLogger.error('CaptureAnalyticsService: Error tracking event: $e');
    }
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  /// Get recent events (local cache)
  List<Map<String, dynamic>> get recentEvents =>
      List.unmodifiable(_recentEvents);

  /// Clear local cache
  void clearCache() {
    _recentEvents.clear();
    _captureMetrics.clear();
    _userBehavior.clear();
    _performanceMetrics.clear();
    notifyListeners();
  }

  /// Check if analytics are enabled
  bool get isAnalyticsEnabled => true; // This could be a user setting

  /// Get supported event types
  List<String> get supportedEventTypes => [
    'capture_session_start',
    'capture_session_end',
    'capture_taken',
    'feature_usage',
    'image_processing',
    'ai_analysis',
    'user_interaction',
    'performance_metric',
    'error',
  ];
}
