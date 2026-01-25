import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/artbeat_event.dart';

/// Event moderation service for content review and management
/// Handles flagging, reviewing, and approving events for publication
class EventModerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  /// Flag an event for review with a specific reason
  Future<void> flagEvent(String eventId, String reason) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Check if event exists
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      // Create flag record
      await _firestore.collection('event_flags').add({
        'eventId': eventId,
        'flaggedBy': user.uid,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, reviewed, dismissed
        'flagType': _determineFlagType(reason),
      });

      // Update event status if it's a critical flag
      if (_isCriticalFlag(reason)) {
        await _firestore.collection('events').doc(eventId).update({
          'moderationStatus': 'flagged',
          'isActive': false, // Suspend event immediately for critical issues
          'lastModerated': FieldValue.serverTimestamp(),
        });
      } else {
        // Non-critical flags just mark for review
        await _firestore.collection('events').doc(eventId).update({
          'moderationStatus': 'under_review',
          'lastModerated': FieldValue.serverTimestamp(),
        });
      }

      _logger.i('Event flagged successfully');
    } on FirebaseException catch (e) {
      _logger.e('Firebase error flagging event: ${e.message}', error: e);
      rethrow;
    } on Exception catch (e) {
      _logger.e('Error flagging event: $e', error: e);
      rethrow;
    }
  }

  /// Review and approve/reject a flagged event
  Future<void> reviewEvent(
    String eventId,
    bool approved, {
    String? reviewNotes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Check if user has moderation permissions (admin/moderator)
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      if (userData == null || !_hasModeratorPermissions(userData)) {
        throw Exception('Insufficient permissions for event moderation');
      }

      // Update event status based on review decision
      await _firestore.collection('events').doc(eventId).update({
        'moderationStatus': approved ? 'approved' : 'rejected',
        'isActive': approved,
        'reviewedBy': user.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewNotes': reviewNotes,
        'lastModerated': FieldValue.serverTimestamp(),
      });

      // Update all related flags as reviewed
      final flagsQuery = await _firestore
          .collection('event_flags')
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'pending')
          .get();

      final batch = _firestore.batch();
      for (final flagDoc in flagsQuery.docs) {
        batch.update(flagDoc.reference, {
          'status': 'reviewed',
          'reviewDecision': approved ? 'approved' : 'rejected',
          'reviewedBy': user.uid,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      _logger.i(
        'Event review completed: ${approved ? 'approved' : 'rejected'}',
      );
    } on FirebaseException catch (e) {
      _logger.e('Firebase error reviewing event: ${e.message}', error: e);
      rethrow;
    } on Exception catch (e) {
      _logger.e('Error reviewing event: $e', error: e);
      rethrow;
    }
  }

  /// Get all events pending moderation review
  Future<List<ArtbeatEvent>> getPendingEvents() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Check moderation permissions
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      if (userData == null || !_hasModeratorPermissions(userData)) {
        throw Exception('Insufficient permissions to view pending events');
      }

      // Get events that need review
      // We query recent events and filter in-memory to handle missing moderationStatus fields
      final query = await _firestore
          .collection('events')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      return query.docs
          .map(ArtbeatEvent.fromFirestore)
          .where(
            (event) => [
              'flagged',
              'under_review',
              'pending',
            ].contains(event.moderationStatus),
          )
          .toList();
    } on FirebaseException catch (e) {
      _logger.e(
        'Firebase error getting pending events: ${e.message}',
        error: e,
      );
      return [];
    } on Exception catch (e) {
      _logger.e('Error getting pending events: $e', error: e);
      return [];
    }
  }

  /// Get all approved events
  Future<List<ArtbeatEvent>> getApprovedEvents() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Check moderation permissions
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      if (userData == null || !_hasModeratorPermissions(userData)) {
        throw Exception('Insufficient permissions to view approved events');
      }

      // Get approved events
      final query = await _firestore
          .collection('events')
          .where('moderationStatus', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return query.docs.map(ArtbeatEvent.fromFirestore).toList();
    } on FirebaseException catch (e) {
      _logger.e(
        'Firebase error getting approved events: ${e.message}',
        error: e,
      );
      return [];
    } on Exception catch (e) {
      _logger.e('Error getting approved events: $e', error: e);
      return [];
    }
  }

  /// Get flagged events with flag details
  Future<List<Map<String, dynamic>>> getFlaggedEventsWithDetails() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Check moderation permissions
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      if (userData == null || !_hasModeratorPermissions(userData)) {
        throw Exception('Insufficient permissions to view flagged events');
      }

      final flagsQuery = await _firestore
          .collection('event_flags')
          .where('status', isEqualTo: 'pending')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final results = <Map<String, dynamic>>[];

      for (final flagDoc in flagsQuery.docs) {
        final flagData = flagDoc.data();
        final eventId = flagData['eventId'] as String;

        // Get event details
        final eventDoc = await _firestore
            .collection('events')
            .doc(eventId)
            .get();
        if (eventDoc.exists) {
          results.add({
            'flag': flagData,
            'flagId': flagDoc.id,
            'event': ArtbeatEvent.fromFirestore(eventDoc),
          });
        }
      }

      return results;
    } on FirebaseException catch (e) {
      _logger.e(
        'Firebase error getting flagged events: ${e.message}',
        error: e,
      );
      return [];
    } on Exception catch (e) {
      _logger.e('Error getting flagged events: $e', error: e);
      return [];
    }
  }

  /// Dismiss a flag without taking action on the event
  Future<void> dismissFlag(String flagId, String dismissalReason) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Check moderation permissions
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      if (userData == null || !_hasModeratorPermissions(userData)) {
        throw Exception('Insufficient permissions to dismiss flags');
      }

      await _firestore.collection('event_flags').doc(flagId).update({
        'status': 'dismissed',
        'dismissalReason': dismissalReason,
        'dismissedBy': user.uid,
        'dismissedAt': FieldValue.serverTimestamp(),
      });

      _logger.i('Flag dismissed successfully');
    } on FirebaseException catch (e) {
      _logger.e('Firebase error dismissing flag: ${e.message}', error: e);
      rethrow;
    } on Exception catch (e) {
      _logger.e('Error dismissing flag: $e', error: e);
      rethrow;
    }
  }

  /// Helper: Determine flag type based on reason
  String _determineFlagType(String reason) {
    final lowerReason = reason.toLowerCase();

    if (lowerReason.contains('spam') || lowerReason.contains('scam')) {
      return 'spam';
    } else if (lowerReason.contains('inappropriate') ||
        lowerReason.contains('offensive')) {
      return 'inappropriate_content';
    } else if (lowerReason.contains('fake') ||
        lowerReason.contains('misleading')) {
      return 'misinformation';
    } else if (lowerReason.contains('copyright') ||
        lowerReason.contains('plagiarism')) {
      return 'intellectual_property';
    } else {
      return 'other';
    }
  }

  /// Helper: Check if a flag is critical and requires immediate action
  bool _isCriticalFlag(String reason) {
    final criticalKeywords = [
      'spam',
      'scam',
      'fraud',
      'illegal',
      'harmful',
      'threatening',
      'harassment',
    ];

    final lowerReason = reason.toLowerCase();
    return criticalKeywords.any(lowerReason.contains);
  }

  /// Helper: Check if user has moderator permissions
  bool _hasModeratorPermissions(Map<String, dynamic> userData) {
    final role = (userData['userType'] ?? userData['role']) as String?;
    return role == 'admin' || role == 'moderator';
  }

  /// Get moderation analytics
  Future<Map<String, dynamic>> getModerationAnalytics() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Check permissions
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      if (userData == null || !_hasModeratorPermissions(userData)) {
        throw Exception(
          'Insufficient permissions to view moderation analytics',
        );
      }

      // Get flag statistics
      final totalFlags = await _firestore
          .collection('event_flags')
          .count()
          .get();

      final pendingFlags = await _firestore
          .collection('event_flags')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      final reviewedFlags = await _firestore
          .collection('event_flags')
          .where('status', isEqualTo: 'reviewed')
          .count()
          .get();

      // Get event statistics
      final totalEvents = await _firestore.collection('events').count().get();

      final flaggedEvents = await _firestore
          .collection('events')
          .where('moderationStatus', isEqualTo: 'flagged')
          .count()
          .get();

      return {
        'flags': {
          'total': totalFlags.count ?? 0,
          'pending': pendingFlags.count ?? 0,
          'reviewed': reviewedFlags.count ?? 0,
          'pendingPercentage': (totalFlags.count ?? 0) > 0
              ? (((pendingFlags.count ?? 0) / (totalFlags.count ?? 1) * 100)
                    .round())
              : 0,
        },
        'events': {
          'total': totalEvents.count ?? 0,
          'flagged': flaggedEvents.count ?? 0,
          'flaggedPercentage': (totalEvents.count ?? 0) > 0
              ? (((flaggedEvents.count ?? 0) / (totalEvents.count ?? 1) * 100)
                    .round())
              : 0,
        },
        'generatedAt': FieldValue.serverTimestamp(),
      };
    } on FirebaseException catch (e) {
      _logger.e(
        'Firebase error getting moderation analytics: ${e.message}',
        error: e,
      );
      return {'error': e.toString()};
    } on Exception catch (e) {
      _logger.e('Error getting moderation analytics: $e', error: e);
      return {'error': e.toString()};
    }
  }
}
