import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/artwork_model.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppLogger;

/// Moderation action types
enum ModerationAction { approve, reject, flag, unflag, requestChanges }

/// Moderation priority levels
enum ModerationPriority { low, medium, high, urgent }

/// Enhanced moderation service for comprehensive content moderation
///
/// Provides advanced moderation capabilities including AI-powered content analysis,
/// batch operations, moderation queues, and detailed audit trails.
class EnhancedModerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Submit artwork for moderation with priority and category
  Future<String?> submitForModeration({
    required String artworkId,
    ModerationPriority priority = ModerationPriority.medium,
    String? category,
    String? submissionNotes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final moderationData = {
        'artworkId': artworkId,
        'submitterId': user.uid,
        'priority': priority.name,
        'category': category ?? 'general',
        'status': 'pending',
        'submissionNotes': submissionNotes,
        'submittedAt': Timestamp.now(),
        'assignedModerator': null,
        'moderationHistory': <Map<String, dynamic>>[],
        'flagReasons': <String>[],
        'aiAnalysis': null,
        'humanReview': null,
        'estimatedReviewTime': _calculateEstimatedReviewTime(priority),
      };

      final docRef = await _firestore
          .collection('moderation_queue')
          .add(moderationData);

      // Update artwork moderation status
      await _firestore.collection('artwork').doc(artworkId).update({
        'moderationStatus': 'pending',
        'moderationQueueId': docRef.id,
        'submittedForModerationAt': Timestamp.now(),
      });

      // Trigger AI analysis if enabled
      await _triggerAIAnalysis(artworkId, docRef.id);

      return docRef.id;
    } catch (e) {
      AppLogger.error('Error submitting for moderation: $e');
      return null;
    }
  }

  /// Perform moderation action with detailed logging
  Future<bool> performModerationAction({
    required String moderationId,
    required ModerationAction action,
    String? reason,
    String? notes,
    List<String>? tags,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get moderation record
      final moderationDoc = await _firestore
          .collection('moderation_queue')
          .doc(moderationId)
          .get();

      if (!moderationDoc.exists) return false;

      final moderationData = moderationDoc.data()!;
      final artworkId = moderationData['artworkId'] as String;

      // Create action record
      final actionRecord = {
        'action': action.name,
        'moderatorId': user.uid,
        'reason': reason,
        'notes': notes,
        'tags': tags ?? [],
        'timestamp': Timestamp.now(),
        'ip': 'unknown', // Could be enhanced with IP tracking
        'userAgent': 'mobile_app',
      };

      // Update moderation history
      final updatedHistory = List<Map<String, dynamic>>.from(
        moderationData['moderationHistory'] as List? ?? [],
      );
      updatedHistory.add(actionRecord);

      // Determine new status
      String newStatus;
      String artworkModerationStatus;

      switch (action) {
        case ModerationAction.approve:
          newStatus = 'approved';
          artworkModerationStatus = 'approved';
          break;
        case ModerationAction.reject:
          newStatus = 'rejected';
          artworkModerationStatus = 'rejected';
          break;
        case ModerationAction.flag:
          newStatus = 'flagged';
          artworkModerationStatus = 'flagged';
          break;
        case ModerationAction.unflag:
          newStatus = 'approved';
          artworkModerationStatus = 'approved';
          break;
        case ModerationAction.requestChanges:
          newStatus = 'changes_requested';
          artworkModerationStatus = 'pending_changes';
          break;
      }

      // Update moderation record
      await moderationDoc.reference.update({
        'status': newStatus,
        'moderationHistory': updatedHistory,
        'assignedModerator': user.uid,
        'completedAt':
            action == ModerationAction.approve ||
                action == ModerationAction.reject
            ? Timestamp.now()
            : null,
        'lastActionAt': Timestamp.now(),
        'lastActionBy': user.uid,
      });

      // Update artwork status
      final artworkUpdateData = {
        'moderationStatus': artworkModerationStatus,
        'moderatedAt': Timestamp.now(),
        'moderatedBy': user.uid,
      };

      if (action == ModerationAction.flag && tags != null) {
        artworkUpdateData['flagReasons'] = tags;
        artworkUpdateData['flagged'] = true;
      } else if (action == ModerationAction.unflag) {
        artworkUpdateData['flagged'] = false;
        artworkUpdateData['flagReasons'] = [];
      }

      await _firestore
          .collection('artwork')
          .doc(artworkId)
          .update(artworkUpdateData);

      // Send notification to artwork owner
      await _sendModerationNotification(artworkId, action, reason, notes);

      // Log the action for audit
      await _logAuditEvent(moderationId, actionRecord);

      return true;
    } catch (e) {
      AppLogger.error('Error performing moderation action: $e');
      return false;
    }
  }

  /// Get moderation queue with filtering and sorting
  Future<List<Map<String, dynamic>>> getModerationQueue({
    String?
    status, // 'pending', 'approved', 'rejected', 'flagged', 'changes_requested'
    ModerationPriority? priority,
    String? category,
    String? assignedModerator,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('moderation_queue')
          .orderBy('priority', descending: true)
          .orderBy('submittedAt', descending: false);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      if (priority != null) {
        query = query.where('priority', isEqualTo: priority.name);
      }

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      if (assignedModerator != null) {
        query = query.where('assignedModerator', isEqualTo: assignedModerator);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      final results = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Get artwork details
        final artworkId = data['artworkId'] as String;
        final artworkDoc = await _firestore
            .collection('artwork')
            .doc(artworkId)
            .get();

        if (artworkDoc.exists) {
          data['artwork'] = ArtworkModel.fromFirestore(artworkDoc);
        }

        results.add(data);
      }

      return results;
    } catch (e) {
      AppLogger.error('Error getting moderation queue: $e');
      return [];
    }
  }

  /// Assign moderator to a moderation item
  Future<bool> assignModerator(String moderationId, String moderatorId) async {
    try {
      await _firestore.collection('moderation_queue').doc(moderationId).update({
        'assignedModerator': moderatorId,
        'assignedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      AppLogger.error('Error assigning moderator: $e');
      return false;
    }
  }

  /// Get moderation statistics for dashboard
  Future<Map<String, dynamic>> getModerationStats({int days = 30}) async {
    try {
      final cutoffDate = Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: days)),
      );

      // Get all moderation records in the timeframe
      final snapshot = await _firestore
          .collection('moderation_queue')
          .where('submittedAt', isGreaterThan: cutoffDate)
          .get();

      final records = snapshot.docs.map((doc) => doc.data()).toList();

      // Calculate statistics
      final totalSubmissions = records.length;
      final pendingCount = records
          .where((r) => r['status'] == 'pending')
          .length;
      final approvedCount = records
          .where((r) => r['status'] == 'approved')
          .length;
      final rejectedCount = records
          .where((r) => r['status'] == 'rejected')
          .length;
      final flaggedCount = records
          .where((r) => r['status'] == 'flagged')
          .length;

      // Calculate average processing time
      double avgProcessingTime = 0.0;
      final completedRecords = records
          .where((r) => r['completedAt'] != null && r['submittedAt'] != null)
          .toList();

      if (completedRecords.isNotEmpty) {
        final totalTime = completedRecords.fold(0, (sum, record) {
          final submitted = record['submittedAt'] as Timestamp;
          final completed = record['completedAt'] as Timestamp;
          return sum +
              completed.millisecondsSinceEpoch -
              submitted.millisecondsSinceEpoch;
        });
        avgProcessingTime =
            totalTime / completedRecords.length / (1000 * 60 * 60); // hours
      }

      // Get moderator performance
      final moderatorStats = <String, Map<String, int>>{};
      for (final record in records) {
        final history = record['moderationHistory'] as List? ?? [];
        for (final action in history) {
          final moderatorId = action['moderatorId'] as String?;
          if (moderatorId != null) {
            moderatorStats[moderatorId] ??= {
              'approvals': 0,
              'rejections': 0,
              'flags': 0,
              'total': 0,
            };

            final actionType = action['action'] as String;
            switch (actionType) {
              case 'approve':
                moderatorStats[moderatorId]!['approvals'] =
                    (moderatorStats[moderatorId]!['approvals'] ?? 0) + 1;
                break;
              case 'reject':
                moderatorStats[moderatorId]!['rejections'] =
                    (moderatorStats[moderatorId]!['rejections'] ?? 0) + 1;
                break;
              case 'flag':
                moderatorStats[moderatorId]!['flags'] =
                    (moderatorStats[moderatorId]!['flags'] ?? 0) + 1;
                break;
            }
            moderatorStats[moderatorId]!['total'] =
                (moderatorStats[moderatorId]!['total'] ?? 0) + 1;
          }
        }
      }

      return {
        'timeframeDays': days,
        'totalSubmissions': totalSubmissions,
        'pendingCount': pendingCount,
        'approvedCount': approvedCount,
        'rejectedCount': rejectedCount,
        'flaggedCount': flaggedCount,
        'approvalRate': totalSubmissions > 0
            ? (approvedCount / totalSubmissions) * 100
            : 0.0,
        'avgProcessingTimeHours': avgProcessingTime,
        'moderatorStats': moderatorStats,
        'backlogSize': pendingCount,
        'processingEfficiency': totalSubmissions > 0
            ? ((approvedCount + rejectedCount) / totalSubmissions) * 100
            : 0.0,
      };
    } catch (e) {
      AppLogger.error('Error getting moderation stats: $e');
      return {};
    }
  }

  /// Get audit trail for a specific artwork
  Future<List<Map<String, dynamic>>> getAuditTrail(String artworkId) async {
    try {
      // Get moderation records
      final moderationSnapshot = await _firestore
          .collection('moderation_queue')
          .where('artworkId', isEqualTo: artworkId)
          .get();

      final auditTrail = <Map<String, dynamic>>[];

      for (final doc in moderationSnapshot.docs) {
        final data = doc.data();
        final history = data['moderationHistory'] as List? ?? [];

        for (final action in history) {
          auditTrail.add({
            'type': 'moderation_action',
            'action': action['action'],
            'moderatorId': action['moderatorId'],
            'reason': action['reason'],
            'notes': action['notes'],
            'timestamp': action['timestamp'],
            'moderationId': doc.id,
          });
        }
      }

      // Get audit log entries
      final auditSnapshot = await _firestore
          .collection('audit_log')
          .where('artworkId', isEqualTo: artworkId)
          .orderBy('timestamp', descending: true)
          .get();

      for (final doc in auditSnapshot.docs) {
        final data = doc.data();
        auditTrail.add({'type': 'audit_log', ...data});
      }

      // Sort by timestamp
      auditTrail.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp;
        final bTime = b['timestamp'] as Timestamp;
        return bTime.compareTo(aTime);
      });

      return auditTrail;
    } catch (e) {
      AppLogger.error('Error getting audit trail: $e');
      return [];
    }
  }

  /// Bulk moderation actions
  Future<Map<String, bool>> bulkModerationAction({
    required List<String> moderationIds,
    required ModerationAction action,
    String? reason,
    String? notes,
  }) async {
    final results = <String, bool>{};

    for (final moderationId in moderationIds) {
      final success = await performModerationAction(
        moderationId: moderationId,
        action: action,
        reason: reason,
        notes: notes,
      );
      results[moderationId] = success;
    }

    return results;
  }

  /// Private helper methods

  int _calculateEstimatedReviewTime(ModerationPriority priority) {
    switch (priority) {
      case ModerationPriority.urgent:
        return 1; // 1 hour
      case ModerationPriority.high:
        return 4; // 4 hours
      case ModerationPriority.medium:
        return 24; // 24 hours
      case ModerationPriority.low:
        return 72; // 72 hours
    }
  }

  Future<void> _triggerAIAnalysis(String artworkId, String moderationId) async {
    try {
      // This would integrate with AI moderation services
      // For now, we'll create a placeholder analysis
      await _firestore.collection('moderation_queue').doc(moderationId).update({
        'aiAnalysis': {
          'status': 'pending',
          'triggeredAt': Timestamp.now(),
          'service': 'vision_ai',
        },
      });

      // In a real implementation, this would call an AI service
      // and update the analysis results
    } catch (e) {
      AppLogger.error('Error triggering AI analysis: $e');
    }
  }

  Future<void> _sendModerationNotification(
    String artworkId,
    ModerationAction action,
    String? reason,
    String? notes,
  ) async {
    try {
      // Get artwork to find the owner
      final artworkDoc = await _firestore
          .collection('artwork')
          .doc(artworkId)
          .get();
      if (!artworkDoc.exists) return;

      final artworkData = artworkDoc.data()!;
      final ownerId =
          artworkData['userId'] as String? ??
          artworkData['artistProfileId'] as String?;

      if (ownerId == null) return;

      String title, message;
      switch (action) {
        case ModerationAction.approve:
          title = 'Artwork Approved';
          message =
              'Your artwork "${artworkData['title']}" has been approved and is now live.';
          break;
        case ModerationAction.reject:
          title = 'Artwork Rejected';
          message =
              'Your artwork "${artworkData['title']}" has been rejected. Reason: ${reason ?? 'No reason provided'}';
          break;
        case ModerationAction.flag:
          title = 'Artwork Flagged';
          message =
              'Your artwork "${artworkData['title']}" has been flagged for review. Reason: ${reason ?? 'Policy violation'}';
          break;
        case ModerationAction.requestChanges:
          title = 'Changes Requested';
          message =
              'Please make changes to your artwork "${artworkData['title']}". ${notes ?? ''}';
          break;
        default:
          return;
      }

      await _firestore.collection('notifications').add({
        'userId': ownerId,
        'type': 'moderation_action',
        'title': title,
        'message': message,
        'data': {
          'artworkId': artworkId,
          'action': action.name,
          'reason': reason,
          'notes': notes,
        },
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      AppLogger.error('Error sending moderation notification: $e');
    }
  }

  Future<void> _logAuditEvent(
    String moderationId,
    Map<String, dynamic> actionRecord,
  ) async {
    try {
      await _firestore.collection('audit_log').add({
        'type': 'moderation_action',
        'moderationId': moderationId,
        'action': actionRecord['action'],
        'moderatorId': actionRecord['moderatorId'],
        'reason': actionRecord['reason'],
        'notes': actionRecord['notes'],
        'timestamp': actionRecord['timestamp'],
        'metadata': {
          'ip': actionRecord['ip'],
          'userAgent': actionRecord['userAgent'],
        },
      });
    } catch (e) {
      AppLogger.error('Error logging audit event: $e');
    }
  }
}
