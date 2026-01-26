import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

/// Enum for ticket purchase status
enum TicketPurchaseStatus {
  pending,
  confirmed,
  refunded,
  cancelled;

  String get displayName {
    switch (this) {
      case TicketPurchaseStatus.pending:
        return 'Pending';
      case TicketPurchaseStatus.confirmed:
        return 'Confirmed';
      case TicketPurchaseStatus.refunded:
        return 'Refunded';
      case TicketPurchaseStatus.cancelled:
        return 'Cancelled';
    }
  }

  static TicketPurchaseStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return TicketPurchaseStatus.pending;
      case 'confirmed':
        return TicketPurchaseStatus.confirmed;
      case 'refunded':
        return TicketPurchaseStatus.refunded;
      case 'cancelled':
        return TicketPurchaseStatus.cancelled;
      default:
        return TicketPurchaseStatus.pending;
    }
  }
}

/// Model representing a ticket purchase by a user
class TicketPurchase {
  final String id;
  final String eventId;
  final String ticketTypeId;
  final String userId;
  final String userEmail;
  final String userName;
  final int quantity;
  final double totalAmount;
  final TicketPurchaseStatus status;
  final String? paymentIntentId; // Stripe payment intent ID
  final String? refundId; // Stripe refund ID if refunded
  final String? paymentId; // Stripe payment intent or charge ID for refund
  final double? amount; // Amount paid for this ticket (for refund)
  final DateTime purchaseDate;
  final DateTime? refundDate;
  final Map<String, dynamic>? metadata;

  const TicketPurchase({
    required this.id,
    required this.eventId,
    required this.ticketTypeId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.quantity,
    required this.totalAmount,
    required this.status,
    this.paymentIntentId,
    this.refundId,
    this.paymentId,
    this.amount,
    required this.purchaseDate,
    this.refundDate,
    this.metadata,
  });

  /// Factory constructor to create a new ticket purchase
  factory TicketPurchase.create({
    required String eventId,
    required String ticketTypeId,
    required String userId,
    required String userEmail,
    required String userName,
    required int quantity,
    required double totalAmount,
    String? paymentIntentId,
    Map<String, dynamic>? metadata,
  }) {
    return TicketPurchase(
      id: const Uuid().v4(),
      eventId: eventId,
      ticketTypeId: ticketTypeId,
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      quantity: quantity,
      totalAmount: totalAmount,
      status: totalAmount > 0
          ? TicketPurchaseStatus.pending
          : TicketPurchaseStatus.confirmed, // Free tickets are auto-confirmed
      paymentIntentId: paymentIntentId,
      purchaseDate: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Create TicketPurchase from Firestore document
  factory TicketPurchase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return TicketPurchase(
      id: doc.id,
      eventId: FirestoreUtils.safeStringDefault(data['eventId']),
      ticketTypeId: FirestoreUtils.safeStringDefault(data['ticketTypeId']),
      userId: FirestoreUtils.safeStringDefault(data['userId']),
      userEmail: FirestoreUtils.safeStringDefault(data['userEmail']),
      userName: FirestoreUtils.safeStringDefault(data['userName']),
      quantity: FirestoreUtils.safeInt(data['quantity'], 1),
      totalAmount: FirestoreUtils.safeDouble(data['totalAmount']),
      status: TicketPurchaseStatus.fromString(
        FirestoreUtils.safeStringDefault(data['status'], 'pending'),
      ),
      paymentIntentId: FirestoreUtils.safeString(data['paymentIntentId']),
      refundId: FirestoreUtils.safeString(data['refundId']),
      paymentId: FirestoreUtils.safeString(data['paymentId']),
      amount: FirestoreUtils.safeDouble(data['amount']),
      purchaseDate: FirestoreUtils.safeDateTime(data['purchaseDate']),
      refundDate: data['refundDate'] != null
          ? FirestoreUtils.safeDateTime(data['refundDate'])
          : null,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert TicketPurchase to Map for Firestore
  Map<String, dynamic> toFirestore() {
    final map = {
      'eventId': eventId,
      'ticketTypeId': ticketTypeId,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'quantity': quantity,
      'totalAmount': totalAmount,
      'status': status.name,
      'paymentIntentId': paymentIntentId,
      'refundId': refundId,
      'paymentId': paymentId,
      'amount': amount,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'refundDate': refundDate != null ? Timestamp.fromDate(refundDate!) : null,
      'metadata': metadata,
    };
    // Remove null values to prevent iOS crash in cloud_firestore plugin
    map.removeWhere((key, value) => value == null);
    return map;
  }

  /// Create a copy of this TicketPurchase with the given fields replaced
  TicketPurchase copyWith({
    String? id,
    String? eventId,
    String? ticketTypeId,
    String? userId,
    String? userEmail,
    String? userName,
    int? quantity,
    double? totalAmount,
    TicketPurchaseStatus? status,
    String? paymentIntentId,
    String? refundId,
    String? paymentId,
    double? amount,
    DateTime? purchaseDate,
    DateTime? refundDate,
    Map<String, dynamic>? metadata,
  }) {
    return TicketPurchase(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      ticketTypeId: ticketTypeId ?? this.ticketTypeId,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      quantity: quantity ?? this.quantity,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      refundId: refundId ?? this.refundId,
      paymentId: paymentId ?? this.paymentId,
      amount: amount ?? this.amount,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      refundDate: refundDate ?? this.refundDate,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if this purchase is for free tickets
  bool get isFree => totalAmount == 0.0;

  /// Check if this purchase can be refunded
  bool get canBeRefunded =>
      status == TicketPurchaseStatus.confirmed && refundId == null;

  /// Check if this purchase has been refunded
  bool get isRefunded => status == TicketPurchaseStatus.refunded;

  /// Check if this purchase is active (confirmed and not refunded)
  bool get isActive =>
      status == TicketPurchaseStatus.confirmed && refundId == null;

  /// Format total amount for display
  String get formattedAmount {
    if (isFree) return 'Free';
    return '\$${totalAmount.toStringAsFixed(2)}';
  }

  /// Generate QR code data for ticket validation
  String get qrCodeData {
    return 'artbeat://ticket/$id/$eventId/$userId';
  }

  @override
  String toString() {
    return 'TicketPurchase{id: $id, eventId: $eventId, quantity: $quantity, totalAmount: $totalAmount, status: $status}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketPurchase &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
