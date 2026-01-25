import 'package:cloud_firestore/cloud_firestore.dart';

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
      userId: data['userId'] as String? ?? '',
      artworkId: data['artworkId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
      winnerUserId: data['winnerUserId'] as String?,
      finalPrice: (data['finalPrice'] as num?)?.toDouble(),
      paymentStatus: data['paymentStatus'] as String? ?? 'pending',
      paymentDeadline: (data['paymentDeadline'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
