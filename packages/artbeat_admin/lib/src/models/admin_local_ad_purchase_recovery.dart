import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLocalAdPurchaseRecovery {
  final String id;
  final String userId;
  final String status;
  final String? error;
  final DateTime createdAt;
  final String? purchaseId;
  final String? transactionId;
  final String? subscriptionProductId;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? resolutionNotes;

  const AdminLocalAdPurchaseRecovery({
    required this.id,
    required this.userId,
    required this.status,
    this.error,
    required this.createdAt,
    this.purchaseId,
    this.transactionId,
    this.subscriptionProductId,
    this.reviewedBy,
    this.reviewedAt,
    this.resolutionNotes,
  });

  factory AdminLocalAdPurchaseRecovery.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    return AdminLocalAdPurchaseRecovery(
      id: id,
      userId: (map['userId'] ?? '') as String,
      status: (map['status'] ?? 'pending_manual_recovery') as String,
      error: map['error'] as String?,
      createdAt: ((map['createdAt']) as Timestamp?)?.toDate() ?? DateTime.now(),
      purchaseId: map['purchaseId'] as String?,
      transactionId: map['transactionId'] as String?,
      subscriptionProductId: map['subscriptionProductId'] as String?,
      reviewedBy: map['reviewedBy'] as String?,
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
      resolutionNotes: map['resolutionNotes'] as String?,
    );
  }

  factory AdminLocalAdPurchaseRecovery.fromSnapshot(DocumentSnapshot snapshot) {
    return AdminLocalAdPurchaseRecovery.fromMap(
      snapshot.data() as Map<String, dynamic>,
      snapshot.id,
    );
  }
}
