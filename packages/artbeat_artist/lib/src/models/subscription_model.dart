import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show SubscriptionTier, FirestoreUtils;

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
      id: FirestoreUtils.safeStringDefault(map['id']),
      userId: FirestoreUtils.safeStringDefault(map['userId']),
      tier: SubscriptionTier.fromLegacyName(
        FirestoreUtils.safeStringDefault(map['tier'], 'free'),
      ),
      startDate: FirestoreUtils.safeDateTime(map['startDate']),
      endDate: map['endDate'] != null
          ? FirestoreUtils.safeDateTime(map['endDate'])
          : null,
      stripeSubscriptionId: FirestoreUtils.safeString(map['stripeSubscriptionId']),
      stripePriceId: FirestoreUtils.safeString(map['stripePriceId']),
      stripeCustomerId: FirestoreUtils.safeString(map['stripeCustomerId']),
      autoRenew: FirestoreUtils.safeBool(map['autoRenew'], false),
      canceledAt: map['canceledAt'] != null
          ? FirestoreUtils.safeDateTime(map['canceledAt'])
          : null,
      createdAt: FirestoreUtils.safeDateTime(map['createdAt']),
      updatedAt: FirestoreUtils.safeDateTime(map['updatedAt']),
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
