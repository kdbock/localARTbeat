import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for security metrics
class SecurityMetrics {
  final int securityScore;
  final int activeThreats;
  final int failedLogins;
  final int blockedIps;
  final DateTime lastUpdated;

  SecurityMetrics({
    required this.securityScore,
    required this.activeThreats,
    required this.failedLogins,
    required this.blockedIps,
    required this.lastUpdated,
  });

  factory SecurityMetrics.fromMap(Map<String, dynamic> map) {
    return SecurityMetrics(
      securityScore: map['securityScore'] as int? ?? 0,
      activeThreats: map['activeThreats'] as int? ?? 0,
      failedLogins: map['failedLogins'] as int? ?? 0,
      blockedIps: map['blockedIps'] as int? ?? 0,
      lastUpdated:
          (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory SecurityMetrics.initial() {
    return SecurityMetrics(
      securityScore: 100,
      activeThreats: 0,
      failedLogins: 0,
      blockedIps: 0,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Model for blocked IP entry
class BlockedIP {
  final String id;
  final String ipAddress;
  final String reason;
  final String blockedBy;
  final DateTime blockedAt;

  BlockedIP({
    required this.id,
    required this.ipAddress,
    required this.reason,
    required this.blockedBy,
    required this.blockedAt,
  });

  factory BlockedIP.fromMap(Map<String, dynamic> map, String id) {
    return BlockedIP(
      id: id,
      ipAddress: map['ipAddress'] as String? ?? 'unknown',
      reason: map['reason'] as String? ?? 'No reason provided',
      blockedBy: map['blockedBy'] as String? ?? 'system',
      blockedAt: (map['blockedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Model for security event
class SecurityEvent {
  final String id;
  final String title;
  final String description;
  final String severity;
  final DateTime timestamp;

  SecurityEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
  });

  factory SecurityEvent.fromMap(Map<String, dynamic> map, String id) {
    return SecurityEvent(
      id: id,
      title: map['title'] as String? ?? 'Security Event',
      description: map['description'] as String? ?? '',
      severity: map['severity'] as String? ?? 'info',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
