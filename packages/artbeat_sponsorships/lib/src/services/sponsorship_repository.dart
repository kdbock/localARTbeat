import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sponsorship.dart';
import '../models/sponsorship_status.dart';

class SponsorshipRepository {
  SponsorshipRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'sponsorships';

  /// Create a new sponsorship (initially pending unless specified otherwise)
  Future<void> createSponsorship(Sponsorship sponsorship) async {
    await _firestore
        .collection(_collection)
        .doc(sponsorship.id)
        .set(sponsorship.toMap());
  }

  /// Fetch a single sponsorship by ID
  Future<Sponsorship?> getById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return Sponsorship.fromSnapshot(doc);
  }

  /// Fetch all sponsorships for a business
  Future<List<Sponsorship>> getForBusiness(String businessId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(Sponsorship.fromSnapshot)
        .toList();
  }

  /// Fetch sponsorships by status (admin use)
  Future<List<Sponsorship>> getByStatus(SponsorshipStatus status) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: status.value)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(Sponsorship.fromSnapshot)
        .toList();
  }

  /// Update sponsorship status (admin controlled)
  Future<void> updateStatus({
    required String sponsorshipId,
    required SponsorshipStatus status,
  }) async {
    await _firestore.collection(_collection).doc(sponsorshipId).update({
      'status': status.value,
    });
  }

  /// Hard-expire a sponsorship immediately
  Future<void> expire(String sponsorshipId) async {
    await _firestore.collection(_collection).doc(sponsorshipId).update({
      'status': SponsorshipStatus.expired.value,
      'endDate': Timestamp.now(),
    });
  }

  /// Delete sponsorship (rare, admin only)
  Future<void> delete(String sponsorshipId) async {
    await _firestore.collection(_collection).doc(sponsorshipId).delete();
  }
}
