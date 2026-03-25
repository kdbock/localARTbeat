import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_sponsorship.dart';

class AdminSponsorshipModerationService {
  AdminSponsorshipModerationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'sponsorships';

  Future<List<AdminSponsorship>> getAllSponsorships() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(AdminSponsorship.fromSnapshot).toList();
    } catch (e) {
      throw Exception('Failed to load sponsorship moderation queue: $e');
    }
  }

  Future<void> updateSponsorshipStatus({
    required String sponsorshipId,
    required String status,
    required String adminId,
    String? moderationNotes,
  }) async {
    try {
      await _firestore.collection(_collection).doc(sponsorshipId).update({
        'status': status,
        'moderationNotes': moderationNotes,
        'reviewedBy': adminId,
        'reviewedAt': Timestamp.now(),
      });
    } catch (e) {
      AppLogger.error('Failed to update sponsorship moderation status: $e');
      rethrow;
    }
  }
}
