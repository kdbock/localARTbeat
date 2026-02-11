import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/security_model.dart';

/// Service for security-related operations
class SecurityService extends ChangeNotifier {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==========================================
  // SECURITY METRICS
  // ==========================================

  /// Get real-time security metrics
  Stream<SecurityMetrics> getSecurityMetrics() {
    return _firestore
        .collection('admin_settings')
        .doc('security_metrics')
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return SecurityMetrics.fromMap(doc.data()!);
      }
      return SecurityMetrics.initial();
    });
  }

  // ==========================================
  // IP BLOCKING
  // ==========================================

  /// Get all blocked IPs
  Stream<List<BlockedIP>> getBlockedIPs() {
    return _firestore
        .collection('blocked_ips')
        .orderBy('blockedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BlockedIP.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Block an IP address
  Future<void> blockIP(String ipAddress, String reason) async {
    try {
      final user = _auth.currentUser;
      await _firestore.collection('blocked_ips').add({
        'ipAddress': ipAddress,
        'reason': reason,
        'blockedBy': user?.uid ?? 'system',
        'blockedAt': FieldValue.serverTimestamp(),
      });

      // Update metrics
      await _firestore
          .collection('admin_settings')
          .doc('security_metrics')
          .update({
        'blockedIps': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to block IP: $e');
    }
  }

  /// Unblock an IP address
  Future<void> unblockIP(String id) async {
    try {
      await _firestore.collection('blocked_ips').doc(id).delete();

      // Update metrics
      await _firestore
          .collection('admin_settings')
          .doc('security_metrics')
          .update({
        'blockedIps': FieldValue.increment(-1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to unblock IP: $e');
    }
  }

  // ==========================================
  // SECURITY EVENTS
  // ==========================================

  /// Get recent security events
  Stream<List<SecurityEvent>> getRecentSecurityEvents({int limit = 10}) {
    return _firestore
        .collection('security_events')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SecurityEvent.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Log a security event
  Future<void> logSecurityEvent({
    required String title,
    required String description,
    required String severity,
  }) async {
    try {
      await _firestore.collection('security_events').add({
        'title': title,
        'description': description,
        'severity': severity,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Failed to log security event
    }
  }
}
