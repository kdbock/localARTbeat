import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'dart:convert';

/// Service for managing artist payouts from the admin dashboard
class AdminPayoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UnifiedPaymentService _paymentService = UnifiedPaymentService();

  /// Get all pending payout requests
  Stream<List<Map<String, dynamic>>> getPendingPayouts() {
    return _firestore
        .collection('payouts')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Process a payout request via Cloud Function
  Future<bool> processPayout(String payoutId) async {
    try {
      // 1. Get payout details
      final payoutDoc =
          await _firestore.collection('payouts').doc(payoutId).get();
      if (!payoutDoc.exists) throw Exception('Payout not found');

      final payoutData = payoutDoc.data()!;
      final artistId = payoutData['artistId'] as String;
      final amount = (payoutData['amount'] as num).toDouble();
      final accountId = payoutData['accountId'] as String;

      // 2. Update status to processing
      await _firestore.collection('payouts').doc(payoutId).update({
        'status': 'processing',
        'processedAt': FieldValue.serverTimestamp(),
      });

      // 3. Trigger the Cloud Function
      final response = await _paymentService.makeAuthenticatedRequest(
        functionKey:
            'processPayout', // This should be registered in UnifiedPaymentService
        body: {
          'payoutId': payoutId,
          'artistId': artistId,
          'amount': amount,
          'accountId': accountId,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        // 4. Update payout as completed
        await _firestore.collection('payouts').doc(payoutId).update({
          'status': 'completed',
          'transactionId':
              result['stripeTransferId'] ?? result['transactionId'],
          'processedAt': FieldValue.serverTimestamp(),
        });

        // 5. Update artist earnings record
        await _firestore.collection('artist_earnings').doc(artistId).update({
          'pendingBalance': FieldValue.increment(-amount),
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        return true;
      } else {
        final error = json.decode(response.body)['error'] ?? 'Unknown error';
        throw Exception(error);
      }
    } catch (e) {
      // Handle failure: move back to pending or mark as failed
      await _firestore.collection('payouts').doc(payoutId).update({
        'status': 'failed',
        'failureReason': e.toString(),
        'processedAt': FieldValue.serverTimestamp(),
      });

      rethrow;
    }
  }

  /// Reject a payout request
  Future<void> rejectPayout(String payoutId, String reason) async {
    final payoutDoc =
        await _firestore.collection('payouts').doc(payoutId).get();
    if (!payoutDoc.exists) throw Exception('Payout not found');

    final payoutData = payoutDoc.data()!;
    final artistId = payoutData['artistId'] as String;
    final amount = (payoutData['amount'] as num).toDouble();

    await _firestore.collection('payouts').doc(payoutId).update({
      'status': 'rejected',
      'failureReason': reason,
      'processedAt': FieldValue.serverTimestamp(),
    });

    // Move funds back from pending to available
    await _firestore.collection('artist_earnings').doc(artistId).update({
      'availableBalance': FieldValue.increment(amount),
      'pendingBalance': FieldValue.increment(-amount),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
}
