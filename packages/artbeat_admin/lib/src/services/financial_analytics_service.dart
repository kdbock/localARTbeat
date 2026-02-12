import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/analytics_model.dart';

/// Service for financial analytics operations
class FinancialAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Get financial metrics for the specified date range
  Future<FinancialMetrics> getFinancialMetrics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get current user for authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      // Call Cloud Function for real financial data
      final callable = _functions.httpsCallable('getAdminFinancialAnalytics');
      final result = await callable.call<Map<String, dynamic>>({
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      });

      final data = result.data;
      if (!(data['success'] as bool? ?? false)) {
        throw Exception(data['error'] ?? 'Failed to fetch financial data');
      }

      final financialData = data['data'] as Map<String, dynamic>;
      final stripe = financialData['stripe'] as Map<String, dynamic>;
      final iap = financialData['iap'] as Map<String, dynamic>;
      final subscriptions =
          financialData['subscriptions'] as Map<String, dynamic>;
      final totals = financialData['totals'] as Map<String, dynamic>;

      // Get previous period for comparison
      final previousPeriod = endDate.difference(startDate);
      final previousStartDate = startDate.subtract(previousPeriod);

      // Get previous period data
      final previousResult = await callable.call<Map<String, dynamic>>({
        'startDate': previousStartDate.toIso8601String(),
        'endDate': startDate.toIso8601String(),
      });

      final previousData = previousResult.data;
      final previousTotals = previousData['success'] == true
          ? (previousData['data'] as Map<String, dynamic>)['totals']
              as Map<String, dynamic>
          : {'gross': 0.0, 'net': 0.0, 'refunds': 0.0};

      // Get revenue time series (simplified - could be enhanced)
      final revenueTimeSeries = await _getRevenueTimeSeries(startDate, endDate);

      // Get revenue by category
      final revenueByCategory = await _getRevenueByCategory(startDate, endDate);

      // Calculate churn rate from subscription data
      final churnRate = subscriptions['churnRate'] as double? ?? 0.0;

      // Calculate lifetime value (simplified)
      final lifetimeValue = await _calculateLifetimeValue();

      return FinancialMetrics(
        totalRevenue: totals['gross'] as double? ?? 0.0,
        subscriptionRevenue: stripe['gross'] as double? ?? 0.0, // Approximate
        eventRevenue: iap['gross'] as double? ?? 0.0, // Approximate
        commissionRevenue: 0.0, // Could be calculated from artwork sales
        averageRevenuePerUser: 0.0, // Would need user count
        monthlyRecurringRevenue: ((subscriptions['active'] as int? ?? 0) * 9.99)
            .toDouble(), // Approximate
        churnRate: churnRate,
        lifetimeValue: lifetimeValue,
        totalTransactions: (subscriptions['active'] as int? ?? 0) +
            (iap['transactions'] as int? ?? 0),
        revenueGrowth: _calculateGrowth(totals['gross'] as double? ?? 0.0,
            previousTotals['gross'] as double? ?? 0.0),
        subscriptionGrowth: _calculateGrowth(stripe['gross'] as double? ?? 0.0,
            previousTotals['gross'] as double? ?? 0.0),
        commissionGrowth: 0.0, // Not implemented yet
        revenueByCategory: revenueByCategory,
        revenueTimeSeries: revenueTimeSeries,
      );
    } catch (e) {
      // Fallback to Firestore data if Cloud Function fails
      return _getFallbackFinancialMetrics(startDate, endDate);
    }
  }

  /// Fallback method using Firestore data when Cloud Function fails
  Future<FinancialMetrics> _getFallbackFinancialMetrics(
      DateTime startDate, DateTime endDate) async {
    // Get previous period for comparison
    final previousPeriod = endDate.difference(startDate);
    final previousStartDate = startDate.subtract(previousPeriod);

    // Fetch financial data in parallel
    final results = await Future.wait<dynamic>([
      _getSubscriptionRevenue(startDate, endDate),
      _getSubscriptionRevenue(previousStartDate, startDate), // Previous period
      _getEventRevenue(startDate, endDate),
      _getEventRevenue(previousStartDate, startDate), // Previous period
      _getCommissionRevenue(startDate, endDate),
      _getCommissionRevenue(previousStartDate, startDate), // Previous period
      _getTransactionCount(startDate, endDate),
      _getRevenueTimeSeries(startDate, endDate),
      _getRevenueByCategory(startDate, endDate),
      _calculateChurnRate(startDate, endDate),
      _calculateLifetimeValue(),
    ]);

    final currentSubscriptionRevenue = results[0] as double;
    final previousSubscriptionRevenue = results[1] as double;
    final currentEventRevenue = results[2] as double;
    final previousEventRevenue = results[3] as double;
    final currentCommissionRevenue = results[4] as double;
    final previousCommissionRevenue = results[5] as double;
    final totalTransactions = results[6] as int;
    final revenueTimeSeries = results[7] as List<RevenueDataPoint>;
    final revenueByCategory = results[8] as Map<String, double>;
    final churnRate = results[9] as double;
    final lifetimeValue = results[10] as double;

    final totalRevenue = currentSubscriptionRevenue +
        currentEventRevenue +
        currentCommissionRevenue;
    final previousTotalRevenue = previousSubscriptionRevenue +
        previousEventRevenue +
        previousCommissionRevenue;

    // Calculate ARPU (Average Revenue Per User)
    final userCount = await _getUserCount(startDate, endDate);
    final averageRevenuePerUser =
        userCount > 0 ? totalRevenue / userCount : 0.0;

    // Calculate MRR (Monthly Recurring Revenue) - approximate from subscription revenue
    final monthlyRecurringRevenue =
        _calculateMRR(currentSubscriptionRevenue, startDate, endDate);

    return FinancialMetrics(
      totalRevenue: totalRevenue,
      subscriptionRevenue: currentSubscriptionRevenue,
      eventRevenue: currentEventRevenue,
      commissionRevenue: currentCommissionRevenue,
      averageRevenuePerUser: averageRevenuePerUser,
      monthlyRecurringRevenue: monthlyRecurringRevenue,
      churnRate: churnRate,
      lifetimeValue: lifetimeValue,
      totalTransactions: totalTransactions,
      revenueGrowth: _calculateGrowth(totalRevenue, previousTotalRevenue),
      subscriptionGrowth: _calculateGrowth(
          currentSubscriptionRevenue, previousSubscriptionRevenue),
      commissionGrowth:
          _calculateGrowth(currentCommissionRevenue, previousCommissionRevenue),
      revenueByCategory: revenueByCategory,
      revenueTimeSeries: revenueTimeSeries,
    );
  }

  /// Get subscription revenue for the specified date range
  Future<double> _getSubscriptionRevenue(
      DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .where('status', isEqualTo: 'active')
          .get();

      double totalRevenue = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        totalRevenue += amount;
      }

      return totalRevenue;
    } catch (e) {
      throw Exception('Failed to get subscription revenue: $e');
    }
  }

  /// Get event revenue for the specified date range
  Future<double> _getEventRevenue(DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('event_tickets')
          .where('purchasedAt', isGreaterThanOrEqualTo: startDate)
          .where('purchasedAt', isLessThanOrEqualTo: endDate)
          .get();

      double totalRevenue = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final price = (data['price'] as num?)?.toDouble() ?? 0.0;
        totalRevenue += price;
      }

      return totalRevenue;
    } catch (e) {
      throw Exception('Failed to get event revenue: $e');
    }
  }

  /// Get commission revenue for the specified date range
  Future<double> _getCommissionRevenue(
      DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('artwork_sales')
          .where('soldAt', isGreaterThanOrEqualTo: startDate)
          .where('soldAt', isLessThanOrEqualTo: endDate)
          .get();

      double totalCommission = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final salePrice = (data['salePrice'] as num?)?.toDouble() ?? 0.0;
        final commissionRate =
            (data['commissionRate'] as num?)?.toDouble() ?? 0.1; // Default 10%
        totalCommission += salePrice * commissionRate;
      }

      return totalCommission;
    } catch (e) {
      throw Exception('Failed to get commission revenue: $e');
    }
  }

  /// Get transaction count for the specified date range
  Future<int> _getTransactionCount(DateTime startDate, DateTime endDate) async {
    try {
      final results = await Future.wait([
        _firestore
            .collection('subscriptions')
            .where('createdAt', isGreaterThanOrEqualTo: startDate)
            .where('createdAt', isLessThanOrEqualTo: endDate)
            .get(),
        _firestore
            .collection('event_tickets')
            .where('purchasedAt', isGreaterThanOrEqualTo: startDate)
            .where('purchasedAt', isLessThanOrEqualTo: endDate)
            .get(),
        _firestore
            .collection('artwork_sales')
            .where('soldAt', isGreaterThanOrEqualTo: startDate)
            .where('soldAt', isLessThanOrEqualTo: endDate)
            .get(),
      ]);

      return results[0].docs.length +
          results[1].docs.length +
          results[2].docs.length;
    } catch (e) {
      throw Exception('Failed to get transaction count: $e');
    }
  }

  /// Get revenue time series data
  Future<List<RevenueDataPoint>> _getRevenueTimeSeries(
      DateTime startDate, DateTime endDate) async {
    try {
      final List<RevenueDataPoint> timeSeries = [];

      // Generate daily data points
      DateTime currentDate = startDate;
      while (currentDate.isBefore(endDate)) {
        final nextDate = currentDate.add(const Duration(days: 1));

        final results = await Future.wait<dynamic>([
          _getSubscriptionRevenue(currentDate, nextDate),
          _getEventRevenue(currentDate, nextDate),
          _getCommissionRevenue(currentDate, nextDate),
        ]);

        final subscriptionRevenue = results[0] as double;
        final eventRevenue = results[1] as double;
        final commissionRevenue = results[2] as double;

        if (subscriptionRevenue > 0) {
          timeSeries.add(RevenueDataPoint(
            date: currentDate,
            amount: subscriptionRevenue,
            category: 'subscriptions',
          ));
        }

        if (eventRevenue > 0) {
          timeSeries.add(RevenueDataPoint(
            date: currentDate,
            amount: eventRevenue,
            category: 'events',
          ));
        }

        if (commissionRevenue > 0) {
          timeSeries.add(RevenueDataPoint(
            date: currentDate,
            amount: commissionRevenue,
            category: 'commissions',
          ));
        }

        currentDate = nextDate;
      }

      return timeSeries;
    } catch (e) {
      throw Exception('Failed to get revenue time series: $e');
    }
  }

  /// Get revenue breakdown by category
  Future<Map<String, double>> _getRevenueByCategory(
      DateTime startDate, DateTime endDate) async {
    try {
      final results = await Future.wait<dynamic>([
        _getSubscriptionRevenue(startDate, endDate),
        _getEventRevenue(startDate, endDate),
        _getCommissionRevenue(startDate, endDate),
      ]);

      return {
        'subscriptions': results[0] as double,
        'events': results[1] as double,
        'commissions': results[2] as double,
      };
    } catch (e) {
      throw Exception('Failed to get revenue by category: $e');
    }
  }

  /// Calculate churn rate
  Future<double> _calculateChurnRate(
      DateTime startDate, DateTime endDate) async {
    try {
      // Get users who were active at the start of the period
      final startActiveUsers = await _firestore
          .collection('users')
          .where('lastActiveAt',
              isGreaterThanOrEqualTo:
                  startDate.subtract(const Duration(days: 30)))
          .where('lastActiveAt', isLessThan: startDate)
          .get();

      if (startActiveUsers.docs.isEmpty) return 0.0;

      // Get users who churned during the period (were active before but not during)
      int churnedUsers = 0;
      for (var doc in startActiveUsers.docs) {
        final data = doc.data();
        final lastActiveAt = (data['lastActiveAt'] as Timestamp?)?.toDate();

        if (lastActiveAt != null && lastActiveAt.isBefore(startDate)) {
          churnedUsers++;
        }
      }

      return (churnedUsers / startActiveUsers.docs.length) * 100;
    } catch (e) {
      throw Exception('Failed to calculate churn rate: $e');
    }
  }

  /// Calculate customer lifetime value
  Future<double> _calculateLifetimeValue() async {
    try {
      // Simplified LTV calculation: Average revenue per user / churn rate
      final totalUsers = await _firestore.collection('users').get();
      if (totalUsers.docs.isEmpty) return 0.0;

      // Get total revenue from all time
      final allTimeRevenue = await _getTotalRevenue();
      final averageRevenuePerUser = allTimeRevenue / totalUsers.docs.length;

      // Use a default churn rate if we can't calculate it
      const defaultChurnRate = 0.05; // 5% monthly churn

      return averageRevenuePerUser / defaultChurnRate;
    } catch (e) {
      throw Exception('Failed to calculate lifetime value: $e');
    }
  }

  /// Get total revenue from all time
  Future<double> _getTotalRevenue() async {
    try {
      final results = await Future.wait([
        _firestore.collection('subscriptions').get(),
        _firestore.collection('event_tickets').get(),
        _firestore.collection('artwork_sales').get(),
      ]);

      double totalRevenue = 0.0;

      // Subscription revenue
      for (var doc in results[0].docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        totalRevenue += amount;
      }

      // Event revenue
      for (var doc in results[1].docs) {
        final data = doc.data();
        final price = (data['price'] as num?)?.toDouble() ?? 0.0;
        totalRevenue += price;
      }

      // Commission revenue
      for (var doc in results[2].docs) {
        final data = doc.data();
        final salePrice = (data['salePrice'] as num?)?.toDouble() ?? 0.0;
        final commissionRate =
            (data['commissionRate'] as num?)?.toDouble() ?? 0.1;
        totalRevenue += salePrice * commissionRate;
      }

      return totalRevenue;
    } catch (e) {
      throw Exception('Failed to get total revenue: $e');
    }
  }

  /// Get user count for the specified date range
  Future<int> _getUserCount(DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get user count: $e');
    }
  }

  /// Calculate Monthly Recurring Revenue
  double _calculateMRR(
      double subscriptionRevenue, DateTime startDate, DateTime endDate) {
    final daysDifference = endDate.difference(startDate).inDays;
    if (daysDifference <= 0) return 0.0;

    // Convert to monthly revenue
    return (subscriptionRevenue / daysDifference) * 30;
  }

  /// Calculate growth percentage
  double _calculateGrowth(double current, double previous) {
    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous) * 100;
  }
}
