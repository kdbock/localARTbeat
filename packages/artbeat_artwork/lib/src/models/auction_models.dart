import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

/// Model representing an auction bid
class AuctionBidModel {
  final String id;
  final String userId;
  final String artworkId;
  final double amount;
  final DateTime timestamp;

  AuctionBidModel({
    required this.id,
    required this.userId,
    required this.artworkId,
    required this.amount,
    required this.timestamp,
  });

  /// Create AuctionBidModel from Firestore document
  factory AuctionBidModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AuctionBidModel(
      id: doc.id,
      userId: FirestoreUtils.safeStringDefault(data['userId']),
      artworkId: FirestoreUtils.safeStringDefault(data['artworkId']),
      amount: FirestoreUtils.safeDouble(data['amount']),
      timestamp: FirestoreUtils.safeDateTime(data['timestamp']),
    );
  }

  /// Convert AuctionBidModel to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'artworkId': artworkId,
      'amount': amount,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

/// Model representing auction result
class AuctionResultModel {
  final String artworkId;
  final String? winnerUserId;
  final double? finalPrice;
  final String paymentStatus; // 'pending', 'paid', 'expired'
  final DateTime? paymentDeadline;
  final DateTime createdAt;

  AuctionResultModel({
    required this.artworkId,
    this.winnerUserId,
    this.finalPrice,
    this.paymentStatus = 'pending',
    this.paymentDeadline,
    required this.createdAt,
  });

  /// Create AuctionResultModel from Firestore document
  factory AuctionResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AuctionResultModel(
      artworkId: doc.id,
      winnerUserId: FirestoreUtils.safeString(data['winnerUserId']),
      finalPrice: FirestoreUtils.safeDouble(data['finalPrice']),
      paymentStatus: FirestoreUtils.safeStringDefault(
        data['paymentStatus'],
        'pending',
      ),
      paymentDeadline: data['paymentDeadline'] != null
          ? FirestoreUtils.safeDateTime(data['paymentDeadline'])
          : null,
      createdAt: FirestoreUtils.safeDateTime(data['createdAt']),
    );
  }

  /// Convert AuctionResultModel to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'winnerUserId': winnerUserId,
      'finalPrice': finalPrice,
      'paymentStatus': paymentStatus,
      'paymentDeadline': paymentDeadline != null
          ? Timestamp.fromDate(paymentDeadline!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Enum for auction status
enum AuctionStatus {
  open,
  closed,
  paid;

  String get value {
    switch (this) {
      case AuctionStatus.open:
        return 'open';
      case AuctionStatus.closed:
        return 'closed';
      case AuctionStatus.paid:
        return 'paid';
    }
  }

  static AuctionStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AuctionStatus.open;
      case 'closed':
        return AuctionStatus.closed;
      case 'paid':
        return AuctionStatus.paid;
      default:
        return AuctionStatus.open;
    }
  }
}
