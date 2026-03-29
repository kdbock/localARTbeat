import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/analytics_model.dart';
import '../utils/user_activity_utils.dart';

/// Service for cohort analysis and advanced user segmentation
class CohortAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get comprehensive cohort analysis
  Future<List<CohortData>> getCohortAnalysis({
    required DateTime startDate,
    required DateTime endDate,
    CohortPeriod period = CohortPeriod.monthly,
  }) async {
    try {
      switch (period) {
        case CohortPeriod.weekly:
          return await _getWeeklyCohorts(startDate, endDate);
        case CohortPeriod.monthly:
          return await _getMonthlyCohorts(startDate, endDate);
        case CohortPeriod.quarterly:
          return await _getQuarterlyCohorts(startDate, endDate);
      }
    } catch (e) {
      throw Exception('Failed to get cohort analysis: $e');
    }
  }

  /// Get weekly cohort analysis
  Future<List<CohortData>> _getWeeklyCohorts(
      DateTime startDate, DateTime endDate) async {
    final List<CohortData> cohorts = [];

    // Start from the beginning of the week
    DateTime cohortStart = _getStartOfWeek(startDate);

    while (cohortStart.isBefore(endDate)) {
      final cohortEnd = cohortStart.add(const Duration(days: 7));

      // Get users who joined in this cohort week
      final cohortUsers = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: cohortStart)
          .where('createdAt', isLessThan: cohortEnd)
          .get();

      if (cohortUsers.docs.isNotEmpty) {
        final retentionRates = await _calculateWeeklyRetention(
          cohortUsers.docs,
          cohortStart,
          endDate,
        );

        final lifetimeValue = await _calculateCohortLifetimeValue(
          cohortUsers.docs.map((doc) => doc.id).toList(),
        );

        cohorts.add(CohortData(
          cohortMonth: _formatWeek(cohortStart),
          totalUsers: cohortUsers.docs.length,
          retentionRates: retentionRates,
          averageLifetimeValue: lifetimeValue,
        ));
      }

      cohortStart = cohortEnd;
    }

    return cohorts;
  }

  /// Get monthly cohort analysis
  Future<List<CohortData>> _getMonthlyCohorts(
      DateTime startDate, DateTime endDate) async {
    final List<CohortData> cohorts = [];

    // Start from 12 months ago to get a full year of cohorts
    DateTime cohortDate = DateTime(startDate.year, startDate.month - 12, 1);

    while (cohortDate.isBefore(endDate)) {
      final cohortEndDate = DateTime(cohortDate.year, cohortDate.month + 1, 1);

      // Get users who joined in this cohort month
      final cohortUsers = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: cohortDate)
          .where('createdAt', isLessThan: cohortEndDate)
          .get();

      if (cohortUsers.docs.isNotEmpty) {
        final retentionRates = await _calculateMonthlyRetention(
          cohortUsers.docs,
          cohortDate,
          endDate,
        );

        final lifetimeValue = await _calculateCohortLifetimeValue(
          cohortUsers.docs.map((doc) => doc.id).toList(),
        );

        cohorts.add(CohortData(
          cohortMonth:
              '${cohortDate.year}-${cohortDate.month.toString().padLeft(2, '0')}',
          totalUsers: cohortUsers.docs.length,
          retentionRates: retentionRates,
          averageLifetimeValue: lifetimeValue,
        ));
      }

      cohortDate = DateTime(cohortDate.year, cohortDate.month + 1, 1);
    }

    return cohorts;
  }

  /// Get quarterly cohort analysis
  Future<List<CohortData>> _getQuarterlyCohorts(
      DateTime startDate, DateTime endDate) async {
    final List<CohortData> cohorts = [];

    // Start from 4 quarters ago
    DateTime cohortDate =
        DateTime(startDate.year, ((startDate.month - 1) ~/ 3) * 3 - 9 + 1, 1);

    while (cohortDate.isBefore(endDate)) {
      final cohortEndDate = DateTime(cohortDate.year, cohortDate.month + 3, 1);

      // Get users who joined in this cohort quarter
      final cohortUsers = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: cohortDate)
          .where('createdAt', isLessThan: cohortEndDate)
          .get();

      if (cohortUsers.docs.isNotEmpty) {
        final retentionRates = await _calculateQuarterlyRetention(
          cohortUsers.docs,
          cohortDate,
          endDate,
        );

        final lifetimeValue = await _calculateCohortLifetimeValue(
          cohortUsers.docs.map((doc) => doc.id).toList(),
        );

        cohorts.add(CohortData(
          cohortMonth:
              'Q${((cohortDate.month - 1) ~/ 3) + 1} ${cohortDate.year}',
          totalUsers: cohortUsers.docs.length,
          retentionRates: retentionRates,
          averageLifetimeValue: lifetimeValue,
        ));
      }

      cohortDate = DateTime(cohortDate.year, cohortDate.month + 3, 1);
    }

    return cohorts;
  }

  /// Calculate weekly retention rates
  Future<Map<int, double>> _calculateWeeklyRetention(
    List<QueryDocumentSnapshot> cohortUsers,
    DateTime cohortStart,
    DateTime endDate,
  ) async {
    final Map<int, double> retentionRates = {};

    // Calculate retention for each subsequent week (up to 12 weeks)
    for (int week = 1; week <= 12; week++) {
      final checkDate = cohortStart.add(Duration(days: week * 7));
      if (checkDate.isAfter(endDate)) break;

      int activeUsers = 0;
      for (var doc in cohortUsers) {
        final data = doc.data() as Map<String, dynamic>;
        final lastActiveAt = getEffectiveLastActive(data);

        if (lastActiveAt != null &&
            lastActiveAt.isAfter(checkDate) &&
            lastActiveAt.isBefore(checkDate.add(const Duration(days: 7)))) {
          activeUsers++;
        }
      }

      retentionRates[week] = (activeUsers / cohortUsers.length) * 100;
    }

    return retentionRates;
  }

  /// Calculate monthly retention rates
  Future<Map<int, double>> _calculateMonthlyRetention(
    List<QueryDocumentSnapshot> cohortUsers,
    DateTime cohortStart,
    DateTime endDate,
  ) async {
    final Map<int, double> retentionRates = {};

    // Calculate retention for each subsequent month (up to 12 months)
    for (int month = 1; month <= 12; month++) {
      final checkDate =
          DateTime(cohortStart.year, cohortStart.month + month, 1);
      if (checkDate.isAfter(endDate)) break;

      int activeUsers = 0;
      for (var doc in cohortUsers) {
        final data = doc.data() as Map<String, dynamic>;
        final lastActiveAt = getEffectiveLastActive(data);

        if (lastActiveAt != null &&
            lastActiveAt.year == checkDate.year &&
            lastActiveAt.month == checkDate.month) {
          activeUsers++;
        }
      }

      retentionRates[month] = (activeUsers / cohortUsers.length) * 100;
    }

    return retentionRates;
  }

  /// Calculate quarterly retention rates
  Future<Map<int, double>> _calculateQuarterlyRetention(
    List<QueryDocumentSnapshot> cohortUsers,
    DateTime cohortStart,
    DateTime endDate,
  ) async {
    final Map<int, double> retentionRates = {};

    // Calculate retention for each subsequent quarter (up to 4 quarters)
    for (int quarter = 1; quarter <= 4; quarter++) {
      final checkDate =
          DateTime(cohortStart.year, cohortStart.month + (quarter * 3), 1);
      if (checkDate.isAfter(endDate)) break;

      final quarterEnd = DateTime(checkDate.year, checkDate.month + 3, 1);

      int activeUsers = 0;
      for (var doc in cohortUsers) {
        final data = doc.data() as Map<String, dynamic>;
        final lastActiveAt = getEffectiveLastActive(data);

        if (lastActiveAt != null &&
            lastActiveAt.isAfter(checkDate) &&
            lastActiveAt.isBefore(quarterEnd)) {
          activeUsers++;
        }
      }

      retentionRates[quarter] = (activeUsers / cohortUsers.length) * 100;
    }

    return retentionRates;
  }

  /// Calculate lifetime value for a cohort
  Future<double> _calculateCohortLifetimeValue(List<String> userIds) async {
    if (userIds.isEmpty) return 0.0;

    try {
      double totalRevenue = 0.0;

      // Get subscription revenue for these users
      final subscriptionSnapshot = await _firestore
          .collection('subscriptions')
          .where('userId',
              whereIn: userIds.take(10).toList()) // Firestore limit
          .get();

      for (var doc in subscriptionSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        totalRevenue += amount;
      }

      // Get event ticket revenue for these users
      final ticketSnapshot = await _firestore
          .collection('event_tickets')
          .where('userId', whereIn: userIds.take(10).toList())
          .get();

      for (var doc in ticketSnapshot.docs) {
        final data = doc.data();
        final price = (data['price'] as num?)?.toDouble() ?? 0.0;
        totalRevenue += price;
      }

      // Get commission revenue from artwork sales by these users
      final salesSnapshot = await _firestore
          .collection('artwork_sales')
          .where('artistId', whereIn: userIds.take(10).toList())
          .get();

      for (var doc in salesSnapshot.docs) {
        final data = doc.data();
        final salePrice = (data['salePrice'] as num?)?.toDouble() ?? 0.0;
        final commissionRate =
            (data['commissionRate'] as num?)?.toDouble() ?? 0.1;
        totalRevenue += salePrice * commissionRate;
      }

      return totalRevenue / userIds.length;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get user segments based on behavior and value
  Future<Map<String, UserSegment>> getUserSegments() async {
    try {
      final Map<String, UserSegment> segments = {};

      // High-value users (top 10% by revenue)
      final highValueUsers = await _getHighValueUsers();
      segments['high_value'] = UserSegment(
        name: 'High Value Users',
        description: 'Top 10% users by lifetime value',
        userCount: highValueUsers.length,
        averageLifetimeValue: _calculateAverageLifetimeValue(highValueUsers),
        retentionRate: await _calculateSegmentRetention(highValueUsers),
        characteristics: ['High spending', 'Regular engagement', 'Long tenure'],
      );

      // Active users (logged in within last 7 days)
      final activeUsers = await _getActiveUsers();
      segments['active'] = UserSegment(
        name: 'Active Users',
        description: 'Users active within the last 7 days',
        userCount: activeUsers.length,
        averageLifetimeValue: _calculateAverageLifetimeValue(activeUsers),
        retentionRate: await _calculateSegmentRetention(activeUsers),
        characteristics: ['Recent activity', 'Regular usage', 'Engaged'],
      );

      // At-risk users (haven't been active in 14-30 days)
      final atRiskUsers = await _getAtRiskUsers();
      segments['at_risk'] = UserSegment(
        name: 'At-Risk Users',
        description: 'Users inactive for 14-30 days',
        userCount: atRiskUsers.length,
        averageLifetimeValue: _calculateAverageLifetimeValue(atRiskUsers),
        retentionRate: await _calculateSegmentRetention(atRiskUsers),
        characteristics: [
          'Declining activity',
          'Potential churn',
          'Need re-engagement'
        ],
      );

      // New users (joined within last 30 days)
      final newUsers = await _getNewUsers();
      segments['new'] = UserSegment(
        name: 'New Users',
        description: 'Users who joined within the last 30 days',
        userCount: newUsers.length,
        averageLifetimeValue: _calculateAverageLifetimeValue(newUsers),
        retentionRate: await _calculateSegmentRetention(newUsers),
        characteristics: [
          'Recently joined',
          'Onboarding phase',
          'High potential'
        ],
      );

      return segments;
    } catch (e) {
      throw Exception('Failed to get user segments: $e');
    }
  }

  /// Get high-value users
  Future<List<Map<String, dynamic>>> _getHighValueUsers() async {
    // This would typically involve complex queries across multiple collections
    // For now, return users with subscriptions as a proxy for high value
    final snapshot = await _firestore
        .collection('users')
        .where('hasActiveSubscription', isEqualTo: true)
        .limit(100)
        .get();

    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();
  }

  /// Get active users
  Future<List<Map<String, dynamic>>> _getActiveUsers() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    final snapshot = await _firestore.collection('users').get();

    return snapshot.docs
        .where((doc) =>
            (getEffectiveLastActive(doc.data())?.isAfter(sevenDaysAgo) ??
                false))
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();
  }

  /// Get at-risk users
  Future<List<Map<String, dynamic>>> _getAtRiskUsers() async {
    final fourteenDaysAgo = DateTime.now().subtract(const Duration(days: 14));
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    final snapshot = await _firestore.collection('users').get();

    return snapshot.docs
        .where((doc) {
          final lastActive = getEffectiveLastActive(doc.data());
          return lastActive != null &&
              lastActive.isBefore(fourteenDaysAgo) &&
              lastActive.isAfter(thirtyDaysAgo);
        })
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();
  }

  /// Get new users
  Future<List<Map<String, dynamic>>> _getNewUsers() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    final snapshot = await _firestore
        .collection('users')
        .where('createdAt', isGreaterThan: thirtyDaysAgo)
        .get();

    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();
  }

  /// Calculate average lifetime value for a user segment
  double _calculateAverageLifetimeValue(List<Map<String, dynamic>> users) {
    if (users.isEmpty) return 0.0;

    double totalValue = 0.0;
    for (var user in users) {
      totalValue += (user['lifetimeValue'] as num?)?.toDouble() ?? 0.0;
    }

    return totalValue / users.length;
  }

  /// Calculate retention rate for a user segment
  Future<double> _calculateSegmentRetention(
      List<Map<String, dynamic>> users) async {
    if (users.isEmpty) return 0.0;

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    int retainedUsers = 0;

    for (var user in users) {
      final lastActiveAt = getEffectiveLastActive(user);
      if (lastActiveAt != null && lastActiveAt.isAfter(thirtyDaysAgo)) {
        retainedUsers++;
      }
    }

    return (retainedUsers / users.length) * 100;
  }

  /// Helper methods
  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  String _formatWeek(DateTime date) {
    final endOfWeek = date.add(const Duration(days: 6));
    return '${date.month}/${date.day} - ${endOfWeek.month}/${endOfWeek.day}';
  }
}

/// Cohort analysis period
enum CohortPeriod {
  weekly,
  monthly,
  quarterly,
}

/// User segment model
class UserSegment {
  final String name;
  final String description;
  final int userCount;
  final double averageLifetimeValue;
  final double retentionRate;
  final List<String> characteristics;

  UserSegment({
    required this.name,
    required this.description,
    required this.userCount,
    required this.averageLifetimeValue,
    required this.retentionRate,
    required this.characteristics,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'userCount': userCount,
      'averageLifetimeValue': averageLifetimeValue,
      'retentionRate': retentionRate,
      'characteristics': characteristics,
    };
  }

  factory UserSegment.fromMap(Map<String, dynamic> map) {
    return UserSegment(
      name: (map['name'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      userCount: (map['userCount'] as int?) ?? 0,
      averageLifetimeValue:
          (map['averageLifetimeValue'] as num?)?.toDouble() ?? 0.0,
      retentionRate: (map['retentionRate'] as num?)?.toDouble() ?? 0.0,
      characteristics:
          List<String>.from((map['characteristics'] as List<dynamic>?) ?? []),
    );
  }
}
