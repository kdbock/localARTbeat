import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

/// Model representing artist earnings from various sources
class EarningsModel {
  final String id;
  final String artistId;
  final double totalEarnings;
  final double availableBalance;
  final double pendingBalance;
  final double boostEarnings;
  final double sponsorshipEarnings;
  final double commissionEarnings;
  final double subscriptionEarnings;
  final double artworkSalesEarnings;
  final DateTime lastUpdated;
  final Map<String, double> monthlyBreakdown;
  final List<EarningsTransaction> recentTransactions;

  EarningsModel({
    required this.id,
    required this.artistId,
    required this.totalEarnings,
    required this.availableBalance,
    required this.pendingBalance,
    required this.boostEarnings,
    required this.sponsorshipEarnings,
    required this.commissionEarnings,
    required this.subscriptionEarnings,
    required this.artworkSalesEarnings,
    required this.lastUpdated,
    required this.monthlyBreakdown,
    required this.recentTransactions,
  });

  factory EarningsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return EarningsModel(
      id: doc.id,
      artistId: FirestoreUtils.safeStringDefault(data['artistId']),
      totalEarnings: FirestoreUtils.safeDouble(data['totalEarnings']),
      availableBalance: FirestoreUtils.safeDouble(data['availableBalance']),
      pendingBalance: FirestoreUtils.safeDouble(data['pendingBalance']),
      boostEarnings: FirestoreUtils.safeDouble(
        data['boostEarnings'] ??
            data['promotionSupportEarnings'] ??
            data['giftEarnings'],
      ),
      sponsorshipEarnings: FirestoreUtils.safeDouble(
        data['sponsorshipEarnings'],
      ),
      commissionEarnings: FirestoreUtils.safeDouble(data['commissionEarnings']),
      subscriptionEarnings: FirestoreUtils.safeDouble(
        data['subscriptionEarnings'],
      ),
      artworkSalesEarnings: FirestoreUtils.safeDouble(
        data['artworkSalesEarnings'],
      ),
      lastUpdated: FirestoreUtils.safeDateTime(data['lastUpdated']),
      monthlyBreakdown:
          (data['monthlyBreakdown'] as Map?)?.map(
            (key, value) => MapEntry(
              FirestoreUtils.safeStringDefault(key),
              FirestoreUtils.safeDouble(value),
            ),
          ) ??
          {},
      recentTransactions:
          (data['recentTransactions'] as List<dynamic>?)
              ?.map(
                (t) => EarningsTransaction.fromMap(t as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'artistId': artistId,
      'totalEarnings': totalEarnings,
      'availableBalance': availableBalance,
      'pendingBalance': pendingBalance,
      'boostEarnings': boostEarnings,
      'sponsorshipEarnings': sponsorshipEarnings,
      'commissionEarnings': commissionEarnings,
      'subscriptionEarnings': subscriptionEarnings,
      'artworkSalesEarnings': artworkSalesEarnings,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'monthlyBreakdown': monthlyBreakdown,
      'recentTransactions': recentTransactions.map((t) => t.toMap()).toList(),
    };
  }

  /// Calculate earnings growth percentage
  double getGrowthPercentage() {
    final now = DateTime.now();
    final currentMonth = now.month.toString();
    final previousMonth = (now.month == 1 ? 12 : now.month - 1).toString();

    final currentEarnings = monthlyBreakdown[currentMonth] ?? 0.0;
    final previousEarnings = monthlyBreakdown[previousMonth] ?? 0.0;

    if (previousEarnings == 0) return 0.0;
    return ((currentEarnings - previousEarnings) / previousEarnings) * 100;
  }

  /// Get earnings by source as percentages
  Map<String, double> getEarningsBreakdownPercentages() {
    if (totalEarnings == 0) return {};

    return {
      'Boost Engagement': (boostEarnings / totalEarnings) * 100,
      'Sponsorships': (sponsorshipEarnings / totalEarnings) * 100,
      'Commissions': (commissionEarnings / totalEarnings) * 100,
      'Subscriptions': (subscriptionEarnings / totalEarnings) * 100,
      'Artwork Sales': (artworkSalesEarnings / totalEarnings) * 100,
    };
  }
}

/// Individual earnings transaction
class EarningsTransaction {
  final String id;
  final String artistId;
  final String
  type; // gift, sponsorship, commission, subscription, artwork_sale
  final double amount;
  final String fromUserId;
  final String fromUserName;
  final DateTime timestamp;
  final String status; // completed, pending, failed
  final String description;
  final Map<String, dynamic> metadata;

  EarningsTransaction({
    required this.id,
    required this.artistId,
    required this.type,
    required this.amount,
    required this.fromUserId,
    required this.fromUserName,
    required this.timestamp,
    required this.status,
    required this.description,
    required this.metadata,
  });

  factory EarningsTransaction.fromMap(Map<String, dynamic> data) {
    return EarningsTransaction(
      id: FirestoreUtils.safeStringDefault(data['id']),
      artistId: FirestoreUtils.safeStringDefault(data['artistId']),
      type: FirestoreUtils.safeStringDefault(data['type']),
      amount: FirestoreUtils.safeDouble(data['amount']),
      fromUserId: FirestoreUtils.safeStringDefault(data['fromUserId']),
      fromUserName: FirestoreUtils.safeStringDefault(data['fromUserName']),
      timestamp: FirestoreUtils.safeDateTime(data['timestamp']),
      status: FirestoreUtils.safeStringDefault(data['status'], 'pending'),
      description: FirestoreUtils.safeStringDefault(data['description']),
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  factory EarningsTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EarningsTransaction(
      id: doc.id,
      artistId: FirestoreUtils.safeStringDefault(data['artistId']),
      type: FirestoreUtils.safeStringDefault(data['type']),
      amount: FirestoreUtils.safeDouble(data['amount']),
      fromUserId: FirestoreUtils.safeStringDefault(data['fromUserId']),
      fromUserName: FirestoreUtils.safeStringDefault(data['fromUserName']),
      timestamp: FirestoreUtils.safeDateTime(data['timestamp']),
      status: FirestoreUtils.safeStringDefault(data['status'], 'pending'),
      description: FirestoreUtils.safeStringDefault(data['description']),
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'artistId': artistId,
      'type': type,
      'amount': amount,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'description': description,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'artistId': artistId,
      'type': type,
      'amount': amount,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'description': description,
      'metadata': metadata,
    };
  }
}
