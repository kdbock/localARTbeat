import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

import '../models/admin_permissions.dart';
import '../models/transaction_model.dart';
import 'audit_trail_service.dart';
import 'payment_audit_service.dart';

class BulkRefundResult {
  const BulkRefundResult({
    required this.successCount,
    required this.failedTransactionIds,
  });

  final int successCount;
  final List<String> failedTransactionIds;
}

class AdminPaymentOperationsService {
  AdminPaymentOperationsService({
    FirebaseFirestore? firestore,
    UnifiedPaymentService? paymentService,
    PaymentAuditService? paymentAuditService,
    AuditTrailService? auditTrailService,
    AdminRoleService? roleService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _paymentService = paymentService ?? UnifiedPaymentService(),
        _paymentAuditService = paymentAuditService ?? PaymentAuditService(),
        _auditTrailService = auditTrailService ?? AuditTrailService(),
        _roleService = roleService ?? AdminRoleService();

  final FirebaseFirestore _firestore;
  final UnifiedPaymentService _paymentService;
  final PaymentAuditService _paymentAuditService;
  final AuditTrailService _auditTrailService;
  final AdminRoleService _roleService;

  Future<AdminUser> _requireCurrentAdmin() async {
    final admin = await _roleService.getCurrentAdmin();
    if (admin == null) {
      throw Exception('Admin authentication required');
    }
    return admin;
  }

  Future<void> processRefund(TransactionModel transaction) async {
    final admin = await _requireCurrentAdmin();
    final paymentIntentId = transaction.metadata['paymentIntentId'] as String?;

    if (paymentIntentId != null) {
      await _paymentService.requestRefund(
        paymentId: paymentIntentId,
        amount: transaction.amount,
        reason: 'Admin processed refund',
      );
    } else {
      AppLogger.warning(
        'No paymentIntentId found for transaction ${transaction.id}. Recording refund in database only.',
      );
    }

    await _firestore.collection('refunds').add({
      'originalTransactionId': transaction.id,
      'paymentIntentId': paymentIntentId,
      'amount': transaction.amount,
      'currency': transaction.currency,
      'userId': transaction.userId,
      'userName': transaction.userName,
      'reason': 'Admin processed refund',
      'processedBy': admin.id,
      'processedByEmail': admin.email,
      'processedAt': FieldValue.serverTimestamp(),
      'status': 'completed',
    });

    await _firestore.collection('payment_history').doc(transaction.id).update({
      'status': 'refunded',
      'refundedAt': FieldValue.serverTimestamp(),
      'refundedBy': admin.id,
    });

    await _paymentAuditService.logRefundAction(
      adminId: admin.id,
      adminEmail: admin.email,
      transactionId: transaction.id,
      refundAmount: transaction.amount,
      reason: 'Admin processed refund',
      userId: transaction.userId,
      notes: 'Processed via transaction details',
    );

    await _auditTrailService.logAdminAction(
      action: 'process_refund',
      category: 'financial',
      targetUserId: transaction.userId,
      description:
          'Processed refund for transaction ${transaction.id} (\$${transaction.amount})',
      metadata: {
        'transaction_id': transaction.id,
        'amount': transaction.amount,
        'user_name': transaction.userName,
      },
    );
  }

  Future<BulkRefundResult> processBulkRefunds(
    List<TransactionModel> transactions,
  ) async {
    final admin = await _requireCurrentAdmin();
    var successCount = 0;
    final failedTransactionIds = <String>[];

    for (final transaction in transactions) {
      try {
        final paymentIntentId =
            transaction.metadata['paymentIntentId'] as String?;

        if (paymentIntentId != null) {
          await _paymentService.requestRefund(
            paymentId: paymentIntentId,
            amount: transaction.amount,
            reason: 'Bulk admin refund',
          );
        }

        await _firestore.collection('refunds').add({
          'originalTransactionId': transaction.id,
          'amount': transaction.amount,
          'currency': transaction.currency,
          'userId': transaction.userId,
          'userName': transaction.userName,
          'reason': 'Bulk admin refund',
          'processedBy': admin.id,
          'processedByEmail': admin.email,
          'processedAt': FieldValue.serverTimestamp(),
          'status': 'completed',
        });

        await _firestore
            .collection('payment_history')
            .doc(transaction.id)
            .update({
          'status': 'refunded',
          'refundedAt': FieldValue.serverTimestamp(),
          'refundedBy': admin.id,
        });

        await _paymentAuditService.logRefundAction(
          adminId: admin.id,
          adminEmail: admin.email,
          transactionId: transaction.id,
          refundAmount: transaction.amount,
          reason: 'Bulk admin refund',
          userId: transaction.userId,
          notes: 'Part of bulk refund operation',
        );

        successCount++;
      } catch (e) {
        AppLogger.error('Failed to refund transaction ${transaction.id}: $e');
        failedTransactionIds.add(transaction.id);
      }
    }

    return BulkRefundResult(
      successCount: successCount,
      failedTransactionIds: failedTransactionIds,
    );
  }

  Future<void> bulkUpdateStatuses({
    required Set<String> transactionIds,
    required List<TransactionModel> transactions,
    required String newStatus,
  }) async {
    final admin = await _requireCurrentAdmin();
    final batch = _firestore.batch();
    final updateData = {
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': admin.id,
    };

    for (final transactionId in transactionIds) {
      final docRef =
          _firestore.collection('payment_history').doc(transactionId);
      batch.update(docRef, updateData);

      await _paymentAuditService.logPaymentAction(
        adminId: admin.id,
        adminEmail: admin.email,
        action: 'STATUS_UPDATE',
        transactionId: transactionId,
        details: {
          'newStatus': newStatus,
          'previousStatus':
              transactions.firstWhere((t) => t.id == transactionId).status,
          'bulkOperation': true,
        },
      );
    }

    await batch.commit();
  }
}
