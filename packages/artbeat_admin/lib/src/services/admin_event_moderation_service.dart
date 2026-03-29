import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';

import '../models/admin_event_model.dart';

class AdminEventModerationService {
  AdminEventModerationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<List<Map<String, dynamic>>> getFlaggedEventsWithDetails() async {
    final user = _requireUser();
    await _ensureModerator(user.uid);

    try {
      final flagsQuery = await _firestore
          .collection('event_flags')
          .where('status', isEqualTo: 'pending')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final results = <Map<String, dynamic>>[];
      for (final flagDoc in flagsQuery.docs) {
        final flagData = flagDoc.data();
        final eventId = flagData['eventId'] as String?;
        if (eventId == null || eventId.isEmpty) {
          continue;
        }

        final eventDoc =
            await _firestore.collection('events').doc(eventId).get();
        if (!eventDoc.exists) {
          continue;
        }

        results.add({
          'flag': flagData,
          'flagId': flagDoc.id,
          'event': AdminEventModel.fromFirestore(eventDoc),
        });
      }
      return results;
    } catch (e) {
      AppLogger.error('Failed to load flagged events: $e');
      return [];
    }
  }

  Future<List<AdminEventModel>> getPendingEvents() async {
    final user = _requireUser();
    await _ensureModerator(user.uid);

    try {
      final query = await _firestore
          .collection('events')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      return query.docs
          .map(AdminEventModel.fromFirestore)
          .where(
            (event) => const [
              'flagged',
              'under_review',
              'pending',
            ].contains(event.moderationStatus),
          )
          .toList();
    } catch (e) {
      AppLogger.error('Failed to load pending events: $e');
      return [];
    }
  }

  Future<List<AdminEventModel>> getApprovedEvents() async {
    final user = _requireUser();
    await _ensureModerator(user.uid);

    try {
      final query = await _firestore
          .collection('events')
          .where('moderationStatus', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return query.docs.map(AdminEventModel.fromFirestore).toList();
    } catch (e) {
      AppLogger.error('Failed to load approved events: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getModerationAnalytics() async {
    final user = _requireUser();
    await _ensureModerator(user.uid);

    try {
      final totalFlags =
          await _firestore.collection('event_flags').count().get();
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
      final totalEvents = await _firestore.collection('events').count().get();
      final flaggedEvents = await _firestore
          .collection('events')
          .where('moderationStatus', isEqualTo: 'flagged')
          .count()
          .get();

      return {
        'totalReviews': reviewedFlags.count ?? 0,
        'approvalRate': (totalFlags.count ?? 0) > 0
            ? ((reviewedFlags.count ?? 0) / (totalFlags.count ?? 1))
            : 0.0,
        'flags': {
          'total': totalFlags.count ?? 0,
          'pending': pendingFlags.count ?? 0,
        },
        'events': {
          'total': totalEvents.count ?? 0,
          'flagged': flaggedEvents.count ?? 0,
        },
      };
    } catch (e) {
      AppLogger.error('Failed to load event moderation analytics: $e');
      return {'error': e.toString()};
    }
  }

  Future<void> reviewEvent(
    String eventId,
    bool approved, {
    String? reviewNotes,
  }) async {
    final user = _requireUser();
    await _ensureModerator(user.uid);

    await _firestore.collection('events').doc(eventId).update({
      'moderationStatus': approved ? 'approved' : 'rejected',
      'isActive': approved,
      'reviewedBy': user.uid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewNotes': reviewNotes,
      'lastModerated': FieldValue.serverTimestamp(),
    });

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
  }

  Future<void> dismissFlag(String flagId, String dismissalReason) async {
    final user = _requireUser();
    await _ensureModerator(user.uid);

    await _firestore.collection('event_flags').doc(flagId).update({
      'status': 'dismissed',
      'dismissalReason': dismissalReason,
      'dismissedBy': user.uid,
      'dismissedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteEvent(String eventId) async {
    final user = _requireUser();
    await _ensureModerator(user.uid);

    final eventDoc = await _firestore.collection('events').doc(eventId).get();
    final event =
        eventDoc.exists ? AdminEventModel.fromFirestore(eventDoc) : null;

    await _firestore.collection('events').doc(eventId).delete();

    if (event?.isRecurring == true) {
      final snapshot = await _firestore
          .collection('events')
          .where('parentEventId', isEqualTo: eventId)
          .get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user;
  }

  Future<void> _ensureModerator(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    final role = (userData?['userType'] ?? userData?['role']) as String?;
    if (role != 'admin' && role != 'moderator') {
      throw Exception('Insufficient permissions for event moderation');
    }
  }
}
