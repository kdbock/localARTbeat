import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Model for audit log entry
class AuditLog {
  final String id;
  final String userId;
  final String action;
  final String category;
  final String severity;
  final String ipAddress;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  AuditLog({
    required this.id,
    required this.userId,
    required this.action,
    required this.category,
    required this.severity,
    required this.ipAddress,
    required this.timestamp,
    required this.metadata,
  });

  factory AuditLog.fromMap(Map<String, dynamic> map, String id) {
    return AuditLog(
      id: id,
      userId: (map['adminId'] ?? map['userId'] ?? 'unknown') as String,
      action: (map['action'] ?? map['activity'] ?? map['event'] ?? 'unknown')
          as String,
      category: (map['category'] ?? 'unknown') as String,
      severity: (map['severity'] ?? 'info') as String,
      ipAddress: (map['ipAddress'] ?? 'unknown') as String,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }
}

/// Comprehensive audit trail service for compliance and logging
/// Tracks all admin actions, user activities, and system events
class AuditTrailService extends ChangeNotifier {
  static final AuditTrailService _instance = AuditTrailService._internal();
  factory AuditTrailService() => _instance;
  AuditTrailService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==========================================
  // AUDIT LOGGING METHODS
  // ==========================================

  /// Log an admin action for audit trail
  Future<void> logAdminAction({
    required String action,
    required String category,
    String? targetUserId,
    String? targetResourceId,
    Map<String, dynamic>? metadata,
    String? description,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final auditEntry = {
        'adminId': user.uid,
        'adminEmail': user.email,
        'action': action,
        'category': category,
        'targetUserId': targetUserId,
        'targetResourceId': targetResourceId,
        'description': description,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': await _getClientIP(),
        'userAgent': await _getUserAgent(),
        'severity': _determineSeverity(action, category),
      };

      await _firestore.collection('auditTrail').add(auditEntry);
    } catch (e) {
      AppLogger.error('Error logging admin action: $e');
    }
  }

  /// Log user activity for compliance monitoring
  Future<void> logUserActivity({
    required String userId,
    required String activity,
    required String category,
    String? resourceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final auditEntry = {
        'userId': userId,
        'activity': activity,
        'category': category,
        'resourceId': resourceId,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': await _getClientIP(),
        'severity': 'info',
      };

      await _firestore.collection('userActivityLog').add(auditEntry);
    } catch (e) {
      AppLogger.error('Error logging user activity: $e');
    }
  }

  /// Log system events for monitoring
  Future<void> logSystemEvent({
    required String event,
    required String category,
    String? severity,
    Map<String, dynamic>? metadata,
    String? description,
  }) async {
    try {
      final auditEntry = {
        'event': event,
        'category': category,
        'severity': severity ?? 'info',
        'description': description,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'source': 'system',
      };

      await _firestore.collection('systemEventLog').add(auditEntry);
    } catch (e) {
      AppLogger.error('Error logging system event: $e');
    }
  }

  // ==========================================
  // AUDIT RETRIEVAL METHODS
  // ==========================================

  /// Get audit trail entries with filtering
  Future<List<Map<String, dynamic>>> getAuditTrail({
    String? adminId,
    String? category,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection('auditTrail');

      if (adminId != null) {
        query = query.where('adminId', isEqualTo: adminId);
      }
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      if (action != null) {
        query = query.where('action', isEqualTo: action);
      }
      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      query = query.orderBy('timestamp', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      AppLogger.error('Error getting audit trail: $e');
      return [];
    }
  }

  /// Get audit trail stream
  Stream<List<AuditLog>> getAuditLogs({int limit = 100}) {
    return _firestore
        .collection('auditTrail')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AuditLog.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get user activity logs
  Future<List<Map<String, dynamic>>> getUserActivityLogs({
    String? userId,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection('userActivityLog');

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      query = query.orderBy('timestamp', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      AppLogger.error('Error getting user activity logs: $e');
      return [];
    }
  }

  /// Get system event logs
  Future<List<Map<String, dynamic>>> getSystemEventLogs({
    String? category,
    String? severity,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection('systemEventLog');

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      if (severity != null) {
        query = query.where('severity', isEqualTo: severity);
      }
      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      query = query.orderBy('timestamp', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      AppLogger.error('Error getting system event logs: $e');
      return [];
    }
  }

  // ==========================================
  // COMPLIANCE AND REPORTING METHODS
  // ==========================================

  /// Generate compliance report for a date range
  Future<Map<String, dynamic>> generateComplianceReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final auditEntries = await getAuditTrail(
        startDate: startDate,
        endDate: endDate,
        limit: 10000,
      );

      final userActivities = await getUserActivityLogs(
        startDate: startDate,
        endDate: endDate,
        limit: 10000,
      );

      final systemEvents = await getSystemEventLogs(
        startDate: startDate,
        endDate: endDate,
        limit: 10000,
      );

      // Analyze data for compliance metrics
      final adminActions = auditEntries.length;
      final userActivitiesCount = userActivities.length;
      final systemEventsCount = systemEvents.length;

      final criticalActions =
          auditEntries.where((entry) => entry['severity'] == 'critical').length;

      final warningActions =
          auditEntries.where((entry) => entry['severity'] == 'warning').length;

      // Group by categories
      final actionsByCategory = <String, int>{};
      for (final entry in auditEntries) {
        final category = entry['category'] as String? ?? 'unknown';
        actionsByCategory[category] = (actionsByCategory[category] ?? 0) + 1;
      }

      return {
        'reportPeriod': {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
        'summary': {
          'totalAdminActions': adminActions,
          'totalUserActivities': userActivitiesCount,
          'totalSystemEvents': systemEventsCount,
          'criticalActions': criticalActions,
          'warningActions': warningActions,
        },
        'actionsByCategory': actionsByCategory,
        'generatedAt': DateTime.now().toIso8601String(),
        'generatedBy': _auth.currentUser?.email ?? 'system',
      };
    } catch (e) {
      AppLogger.error('Error generating compliance report: $e');
      return {
        'error': e.toString(),
        'generatedAt': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get audit statistics for dashboard
  Future<Map<String, dynamic>> getAuditStatistics() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisWeek = now.subtract(const Duration(days: 7));
      final thisMonth = DateTime(now.year, now.month, 1);

      // Get counts for different time periods
      final todayActions = await _getActionCount(startDate: today);
      final weekActions = await _getActionCount(startDate: thisWeek);
      final monthActions = await _getActionCount(startDate: thisMonth);

      // Get recent critical actions
      final criticalActions = await getAuditTrail(
        startDate: thisWeek,
        limit: 10,
      );
      final recentCritical = criticalActions
          .where((action) => action['severity'] == 'critical')
          .toList();

      return {
        'todayActions': todayActions,
        'weekActions': weekActions,
        'monthActions': monthActions,
        'recentCriticalActions': recentCritical,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.error('Error getting audit statistics: $e');
      return {
        'error': e.toString(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }

  // ==========================================
  // HELPER METHODS
  // ==========================================

  /// Determine severity level based on action and category
  String _determineSeverity(String action, String category) {
    // Critical actions
    if (action.contains('delete') ||
        action.contains('ban') ||
        action.contains('suspend') ||
        category == 'security') {
      return 'critical';
    }

    // Warning actions
    if (action.contains('modify') ||
        action.contains('update') ||
        category == 'user_management') {
      return 'warning';
    }

    // Default to info
    return 'info';
  }

  /// Get client IP address (placeholder - would need actual implementation)
  Future<String> _getClientIP() async {
    // In a real implementation, this would get the actual client IP
    return 'unknown';
  }

  /// Get user agent (placeholder - would need actual implementation)
  Future<String> _getUserAgent() async {
    // In a real implementation, this would get the actual user agent
    return 'unknown';
  }

  /// Get action count for a date range
  Future<int> _getActionCount({DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = _firestore.collection('auditTrail');

      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Error getting action count: $e');
      return 0;
    }
  }

  // ==========================================
  // CONVENIENCE METHODS FOR COMMON ACTIONS
  // ==========================================

  /// Log user creation
  Future<void> logUserCreation(
      String userId, Map<String, dynamic> userDetails) async {
    await logAdminAction(
      action: 'create_user',
      category: 'user_management',
      targetUserId: userId,
      metadata: userDetails,
      description: 'New user account created',
    );
  }

  /// Log user deletion
  Future<void> logUserDeletion(String userId, String reason) async {
    await logAdminAction(
      action: 'delete_user',
      category: 'user_management',
      targetUserId: userId,
      metadata: {'reason': reason},
      description: 'User account deleted: $reason',
    );
  }

  /// Log content moderation
  Future<void> logContentModeration(
      String contentId, String action, String reason) async {
    await logAdminAction(
      action: 'moderate_content',
      category: 'content_moderation',
      targetResourceId: contentId,
      metadata: {'moderationAction': action, 'reason': reason},
      description: 'Content moderated: $action - $reason',
    );
  }

  /// Log system configuration change
  Future<void> logSystemConfigChange(
      String setting, dynamic oldValue, dynamic newValue) async {
    await logAdminAction(
      action: 'update_system_config',
      category: 'system_configuration',
      metadata: {
        'setting': setting,
        'oldValue': oldValue,
        'newValue': newValue,
      },
      description: 'System configuration updated: $setting',
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
