import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing artist earnings from various sources
class EarningsModel {
  final String id;
  final String artistId;
  final double totalEarnings;
  final double availableBalance;
  final double pendingBalance;
  final double giftEarnings;
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
    required this.giftEarnings,
    required this.sponsorshipEarnings,
    required this.commissionEarnings,
    required this.subscriptionEarnings,
    required this.artworkSalesEarnings,
    required this.lastUpdated,
    required this.monthlyBreakdown,
    required this.recentTransactions,
  });

  factory EarningsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return EarningsModel(
      id: doc.id,
      artistId: data['artistId'] as String? ?? '',
      totalEarnings: (data['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      availableBalance: (data['availableBalance'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: (data['pendingBalance'] as num?)?.toDouble() ?? 0.0,
      giftEarnings: (data['giftEarnings'] as num?)?.toDouble() ?? 0.0,
      sponsorshipEarnings:
          (data['sponsorshipEarnings'] as num?)?.toDouble() ?? 0.0,
      commissionEarnings:
          (data['commissionEarnings'] as num?)?.toDouble() ?? 0.0,
      subscriptionEarnings:
          (data['subscriptionEarnings'] as num?)?.toDouble() ?? 0.0,
      artworkSalesEarnings:
          (data['artworkSalesEarnings'] as num?)?.toDouble() ?? 0.0,
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      monthlyBreakdown: Map<String, double>.from(
        data['monthlyBreakdown'] as Map<String, dynamic>? ?? {},
      ),
      recentTransactions: (data['recentTransactions'] as List<dynamic>?)
              ?.map(
                  (t) => EarningsTransaction.fromMap(t as Map<String, dynamic>))
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
      'giftEarnings': giftEarnings,
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
    final currentMonth = DateTime.now().month.toString();
    final previousMonth = (DateTime.now().month - 1).toString();

    final currentEarnings = monthlyBreakdown[currentMonth] ?? 0.0;
    final previousEarnings = monthlyBreakdown[previousMonth] ?? 0.0;

    if (previousEarnings == 0) return 0.0;
    return ((currentEarnings - previousEarnings) / previousEarnings) * 100;
  }

  /// Get earnings by source as percentages
  Map<String, double> getEarningsBreakdownPercentages() {
    if (totalEarnings == 0) return {};

    return {
      'Gifts': (giftEarnings / totalEarnings) * 100,
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
      id: data['id'] as String? ?? '',
      artistId: data['artistId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      fromUserId: data['fromUserId'] as String? ?? '',
      fromUserName: data['fromUserName'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? 'pending',
      description: data['description'] as String? ?? '',
      metadata: Map<String, dynamic>.from(
          data['metadata'] as Map<String, dynamic>? ?? {}),
    );
  }

  factory EarningsTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EarningsTransaction(
      id: doc.id,
      artistId: data['artistId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      fromUserId: data['fromUserId'] as String? ?? '',
      fromUserName: data['fromUserName'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? 'pending',
      description: data['description'] as String? ?? '',
      metadata: Map<String, dynamic>.from(
          data['metadata'] as Map<String, dynamic>? ?? {}),
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
