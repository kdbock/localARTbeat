import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show SubscriptionTier;

/// Model for artist and gallery subscriptions
class SubscriptionModel {
  final String id;
  final String userId;
  final SubscriptionTier tier;
  final DateTime startDate;
  final DateTime? endDate;
  final String? stripeSubscriptionId;
  final String? stripePriceId;
  final String? stripeCustomerId;
  final bool autoRenew;
  final DateTime? canceledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns true if the subscription is currently active
  bool get isActive {
    final now = DateTime.now();
    return (endDate == null || endDate!.isAfter(now)) && canceledAt == null;
  }

  /// Returns true if the subscription has been canceled but is still within the paid period
  bool get isGracePeriod {
    final now = DateTime.now();
    return canceledAt != null && endDate != null && endDate!.isAfter(now);
  }

  /// Returns the status of the subscription
  String get status => isActive ? 'active' : 'inactive';

  /// Returns days remaining in the subscription
  int get daysRemaining {
    if (!isActive || endDate == null) return 0;
    return endDate!.difference(DateTime.now()).inDays;
  }

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.tier,
    required this.startDate,
    this.endDate,
    this.stripeSubscriptionId,
    this.stripePriceId,
    this.stripeCustomerId,
    required this.autoRenew,
    this.canceledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      id: map['id'] != null ? map['id'].toString() : '',
      userId: map['userId'] != null ? map['userId'].toString() : '',
      tier: SubscriptionTier.fromLegacyName((map['tier'] ?? 'free').toString()),
      startDate: map['startDate'] is Timestamp
          ? (map['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      endDate: map['endDate'] is Timestamp
          ? (map['endDate'] as Timestamp).toDate()
          : null,
      stripeSubscriptionId: map['stripeSubscriptionId'] != null
          ? map['stripeSubscriptionId'].toString()
          : null,
      stripePriceId: map['stripePriceId'] != null
          ? map['stripePriceId'].toString()
          : null,
      stripeCustomerId: map['stripeCustomerId'] != null
          ? map['stripeCustomerId'].toString()
          : null,
      autoRenew: map['autoRenew'] is bool ? map['autoRenew'] as bool : false,
      canceledAt: map['canceledAt'] is Timestamp
          ? (map['canceledAt'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'tier': tier.apiName,
      'startDate': startDate,
      'endDate': endDate,
      'stripeSubscriptionId': stripeSubscriptionId,
      'stripePriceId': stripePriceId,
      'stripeCustomerId': stripeCustomerId,
      'autoRenew': autoRenew,
      'canceledAt': canceledAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw Exception('Subscription document does not exist!');
    }
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SubscriptionModel.fromMap({...data, 'id': doc.id});
  }
}
