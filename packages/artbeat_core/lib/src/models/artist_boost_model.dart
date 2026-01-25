import 'package:cloud_firestore/cloud_firestore.dart';

enum BoostType {
  preset, // Fixed preset boosts only ($4.99, $9.99, $24.99, $49.99) - Apple compliant
  campaign, // Campaign-related boosts (preset amounts only)
  // Removed: custom amounts (Apple IAP compliance)
  // Removed: subscription boosts (replaced by sponsorship system)
}

class ArtistBoostModel {
  final String id;
  final String senderId;
  final String recipientId;
  final String
  boostType; // Small Boost, Medium Boost, Large Boost, Premium Boost, or Custom
  final double amount;
  final int xpAmount;
  final int momentumAmount;
  final Timestamp createdAt;
  final BoostType type;
  final String? message;
  final String? senderName;
  final String? campaignId; // For campaign boosts
  final String? subscriptionId; // For subscription boosts
  final bool isRecurring;
  final String? paymentIntentId;
  final String status; // pending, completed, failed, refunded

  ArtistBoostModel({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.boostType,
    required this.amount,
    this.xpAmount = 0,
    int? momentumAmount,
    required this.createdAt,
    this.type = BoostType.preset,
    this.message,
    this.senderName,
    this.campaignId,
    this.subscriptionId,
    this.isRecurring = false,
    this.paymentIntentId,
    this.status = 'completed',
  }) : momentumAmount = momentumAmount ?? xpAmount;

  factory ArtistBoostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ArtistBoostModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      recipientId: data['recipientId'] as String? ?? '',
      boostType:
          data['boostType'] as String? ?? data['giftType'] as String? ?? '',
      amount: (data['amount'] as num? ?? 0).toDouble(),
      xpAmount: data['xpAmount'] as int? ?? data['xp'] as int? ?? 0,
      momentumAmount:
          data['momentumAmount'] as int? ??
          data['momentum'] as int? ??
          data['xpAmount'] as int? ??
          data['xp'] as int? ??
          0,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      type: _parseBoostType(data['type'] as String?),
      message: data['message'] as String?,
      senderName: data['senderName'] as String?,
      campaignId: data['campaignId'] as String?,
      subscriptionId: data['subscriptionId'] as String?,
      isRecurring: data['isRecurring'] as bool? ?? false,
      paymentIntentId: data['paymentIntentId'] as String?,
      status: data['status'] as String? ?? 'completed',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'recipientId': recipientId,
      'boostType': boostType,
      'amount': amount,
      'xpAmount': xpAmount,
      'momentumAmount': momentumAmount,
      'createdAt': createdAt,
      'type': type.name,
      if (message != null) 'message': message,
      if (senderName != null) 'senderName': senderName,
      if (campaignId != null) 'campaignId': campaignId,
      if (subscriptionId != null) 'subscriptionId': subscriptionId,
      'isRecurring': isRecurring,
      if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
      'status': status,
    };
  }

  static BoostType _parseBoostType(String? typeString) {
    switch (typeString) {
      case 'campaign':
        return BoostType.campaign;
      default:
        return BoostType.preset;
    }
  }

  // Helper methods
  DateTime get timestamp => createdAt.toDate();
  bool get isCustomAmount =>
      false; // No custom amounts allowed (Apple IAP compliance)
  bool get isCampaignBoost => type == BoostType.campaign && campaignId != null;
  bool get isSubscriptionBoost =>
      false; // No subscription boosts (replaced by sponsorship system)
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  ArtistBoostModel copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? boostType,
    double? amount,
    int? xpAmount,
    int? momentumAmount,
    Timestamp? createdAt,
    BoostType? type,
    String? message,
    String? senderName,
    String? campaignId,
    String? subscriptionId,
    bool? isRecurring,
    String? paymentIntentId,
    String? status,
  }) {
    return ArtistBoostModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      boostType: boostType ?? this.boostType,
      amount: amount ?? this.amount,
      xpAmount: xpAmount ?? this.xpAmount,
      momentumAmount: momentumAmount ?? this.momentumAmount,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      message: message ?? this.message,
      senderName: senderName ?? this.senderName,
      campaignId: campaignId ?? this.campaignId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      isRecurring: isRecurring ?? this.isRecurring,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      status: status ?? this.status,
    );
  }
}
