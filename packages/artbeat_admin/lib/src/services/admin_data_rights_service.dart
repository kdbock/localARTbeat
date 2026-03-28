import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDataRightsService {
  AdminDataRightsService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  String? get currentAdminId => _auth.currentUser?.uid;

  Query<Map<String, dynamic>> requestsQuery({int limit = 200}) {
    return _firestore
        .collection('dataRequests')
        .orderBy('requestedAt', descending: true)
        .limit(limit);
  }

  Future<void> updateStatus(
    DocumentReference<Map<String, dynamic>> ref,
    String newStatus,
    Map<String, dynamic> currentData, {
    String? reviewNotes,
  }) async {
    final reviewerId = currentAdminId;
    final updates = <String, dynamic>{
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewerId,
    };

    if (reviewNotes != null && reviewNotes.trim().isNotEmpty) {
      updates['reviewNotes'] = reviewNotes.trim();
    }

    if (newStatus == 'in_review') {
      updates['acknowledgedAt'] = FieldValue.serverTimestamp();
    }
    if (newStatus == 'fulfilled') {
      updates['fulfilledAt'] = FieldValue.serverTimestamp();
      updates['acknowledgedAt'] =
          updates['acknowledgedAt'] ?? FieldValue.serverTimestamp();
    }
    if (newStatus == 'denied') {
      updates['deniedAt'] = FieldValue.serverTimestamp();
      updates['acknowledgedAt'] =
          updates['acknowledgedAt'] ?? FieldValue.serverTimestamp();
    }

    final requestType =
        (currentData['requestType'] ?? currentData['type'] ?? '').toString();
    final userId = (currentData['userId'] ?? '').toString();
    if (newStatus == 'fulfilled' && requestType == 'deletion') {
      if (userId.trim().isEmpty) {
        throw StateError('Cannot fulfill deletion request: missing userId.');
      }
      final callable = _functions.httpsCallable('processDataDeletionRequest');
      await callable.call<Map<String, dynamic>>({
        'requestId': ref.id,
        'userId': userId,
        'reviewNotes': reviewNotes,
      });
      return;
    }

    await ref.update(updates);
  }
}
