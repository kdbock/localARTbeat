import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../models/analytics_model.dart';
import 'financial_analytics_service.dart';

/// Service for managing financial data and analytics in admin dashboard
class FinancialService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FinancialAnalyticsService _analyticsService;

  FinancialService({
    FirebaseFirestore? firestore,
    FinancialAnalyticsService? analyticsService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _analyticsService = analyticsService ?? FinancialAnalyticsService();

  /// Get recent transactions for admin dashboard
  Future<List<TransactionModel>> getRecentTransactions({int limit = 10}) async {
    try {
      final transactions = <TransactionModel>[];

      // Get payment history from ads
      final adPayments = await _firestore
          .collection('payment_history')
          .orderBy('transactionDate', descending: true)
          .limit(limit ~/ 2)
          .get();

      for (final doc in adPayments.docs) {
        final data = doc.data();
        transactions.add(TransactionModel(
          id: doc.id,
          userId: data['userId'] as String? ?? '',
          userName: await _getUserName(data['userId'] as String? ?? ''),
          amount: ((data['amount'] as num?) ?? 0).toDouble(),
          currency: data['currency'] as String? ?? 'USD',
          type: 'ad_payment',
          status: data['status'] as String? ?? 'pending',
          paymentMethod: data['paymentMethod'] as String? ?? 'card',
          transactionDate: (data['transactionDate'] as Timestamp?)?.toDate() ??
              DateTime.now(),
          description: 'Advertisement Payment',
          itemId: data['adId'] as String?,
          itemTitle: data['adTitle'] as String?,
          metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
        ));
      }

      // Get subscription payments (if they exist)
      try {
        final subscriptions = await _firestore
            .collection('subscriptions')
            .where('status', isEqualTo: 'active')
            .orderBy('createdAt', descending: true)
            .limit(limit ~/ 2)
            .get();

        for (final doc in subscriptions.docs) {
          final data = doc.data();
          transactions.add(TransactionModel(
            id: doc.id,
            userId: data['userId'] as String? ?? '',
            userName: await _getUserName(data['userId'] as String? ?? ''),
            amount: ((data['amount'] as num?) ?? 29.99).toDouble(),
            currency: 'USD',
            type: 'subscription',
            status: 'completed',
            paymentMethod: data['paymentMethod'] as String? ?? 'card',
            transactionDate:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            description: 'Monthly Subscription',
            itemTitle: data['planName'] as String? ?? 'Premium Plan',
          ));
        }
      } catch (e) {
        debugPrint('No subscriptions collection found: $e');
      }

      // Sort by date and return limited results
      transactions
          .sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return transactions.take(limit).toList();
    } catch (e) {
      debugPrint('Error fetching recent transactions: $e');
      return [];
    }
  }

  /// Get financial metrics for dashboard
  Future<FinancialMetrics> getFinancialMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // Use the FinancialAnalyticsService for accurate calculations
      return await _analyticsService.getFinancialMetrics(
        startDate: start,
        endDate: end,
      );
    } catch (e) {
      debugPrint('Error calculating financial metrics: $e');
      return FinancialMetrics(
        totalRevenue: 0,
        subscriptionRevenue: 0,
        eventRevenue: 0,
        commissionRevenue: 0,
        averageRevenuePerUser: 0,
        monthlyRecurringRevenue: 0,
        churnRate: 0,
        lifetimeValue: 0,
        totalTransactions: 0,
        revenueGrowth: 0,
        subscriptionGrowth: 0,
        commissionGrowth: 0,
        revenueByCategory: {},
        revenueTimeSeries: [],
      );
    }
  }

  /// Get revenue breakdown by category
  Future<Map<String, double>> getRevenueBreakdown({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final metrics =
        await getFinancialMetrics(startDate: startDate, endDate: endDate);
    final total = metrics.totalRevenue;

    if (total == 0) {
      return {
        'Advertisements': 0,
        'Subscriptions': 0,
        'Artwork Sales': 0,
      };
    }

    return {
      'Advertisements':
          (metrics.revenueByCategory['advertisements'] ?? 0) / total * 100,
      'Subscriptions':
          (metrics.revenueByCategory['subscriptions'] ?? 0) / total * 100,
      'Artwork Sales':
          (metrics.revenueByCategory['artwork'] ?? 0) / total * 100,
    };
  }

  /// Get user name from user ID
  Future<String> _getUserName(String userId) async {
    if (userId.isEmpty) return 'Unknown User';

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['fullName'] as String? ??
            data['displayName'] as String? ??
            data['username'] as String? ??
            'Unknown User';
      }
    } catch (e) {
      debugPrint('Error fetching user name: $e');
    }

    return 'Unknown User';
  }

  /// Get top spending users
  Future<List<Map<String, dynamic>>> getTopSpendingUsers(
      {int limit = 5}) async {
    try {
      final userSpending = <String, double>{};
      final userNames = <String, String>{};

      // Get all completed payments
      final paymentsQuery = await _firestore
          .collection('payment_history')
          .where('status', isEqualTo: 'completed')
          .get();

      for (final doc in paymentsQuery.docs) {
        final data = doc.data();
        final userId = data['userId'] as String? ?? '';
        final amount = ((data['amount'] as num?) ?? 0).toDouble();

        if (userId.isNotEmpty) {
          userSpending[userId] = (userSpending[userId] ?? 0) + amount;
          if (!userNames.containsKey(userId)) {
            userNames[userId] = await _getUserName(userId);
          }
        }
      }

      // Sort and return top users
      final sortedUsers = userSpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedUsers
          .take(limit)
          .map((entry) => {
                'userId': entry.key,
                'userName': userNames[entry.key] ?? 'Unknown User',
                'totalSpent': entry.value,
                'formattedAmount': '\$${entry.value.toStringAsFixed(2)}',
              })
          .toList();
    } catch (e) {
      debugPrint('Error fetching top spending users: $e');
      return [];
    }
  }
}
