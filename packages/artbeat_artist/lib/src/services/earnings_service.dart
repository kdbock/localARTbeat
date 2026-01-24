import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/earnings_model.dart';
import '../models/payout_model.dart';

/// Service for managing artist earnings and payouts
class EarningsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get earnings for the current artist
  Future<EarningsModel?> getArtistEarnings() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final doc = await _firestore
          .collection('artist_earnings')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // Create initial earnings record
        final initialEarnings = EarningsModel(
          id: user.uid,
          artistId: user.uid,
          totalEarnings: 0.0,
          availableBalance: 0.0,
          pendingBalance: 0.0,
          boostEarnings: 0.0,
          sponsorshipEarnings: 0.0,
          commissionEarnings: 0.0,
          subscriptionEarnings: 0.0,
          artworkSalesEarnings: 0.0,
          lastUpdated: DateTime.now(),
          monthlyBreakdown: {},
          recentTransactions: [],
        );

        await _firestore
            .collection('artist_earnings')
            .doc(user.uid)
            .set(initialEarnings.toFirestore());

        return initialEarnings;
      }

      return EarningsModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get artist earnings: $e');
    }
  }

  /// Get earnings transactions for the current artist
  Future<List<EarningsTransaction>> getEarningsTransactions({
    int limit = 50,
    String? lastTransactionId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      Query query = _firestore
          .collection('earnings_transactions')
          .where('artistId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastTransactionId != null) {
        final lastDoc = await _firestore
            .collection('earnings_transactions')
            .doc(lastTransactionId)
            .get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => EarningsTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get earnings transactions: $e');
    }
  }

  /// Get earnings statistics for a specific period
  Future<Map<String, dynamic>> getEarningsStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      final snapshot = await _firestore
          .collection('earnings_transactions')
          .where('artistId', isEqualTo: user.uid)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final transactions = snapshot.docs
          .map((doc) => EarningsTransaction.fromFirestore(doc))
          .toList();

      // Calculate statistics
      final stats = {
        'totalEarnings': 0.0,
        'boostEarnings': 0.0,
        'sponsorshipEarnings': 0.0,
        'commissionEarnings': 0.0,
        'subscriptionEarnings': 0.0,
        'artworkSalesEarnings': 0.0,
        'transactionCount': transactions.length,
        'averageTransaction': 0.0,
        'dailyBreakdown': <String, double>{},
        'sourceBreakdown': <String, double>{},
      };

      for (final transaction in transactions) {
        final amount = transaction.amount;
        stats['totalEarnings'] = (stats['totalEarnings'] as double) + amount;

        // Breakdown by source
        switch (transaction.type) {
          case 'gift':
          case 'promotion_credit':
            stats['boostEarnings'] =
                (stats['boostEarnings'] as double) + amount;
            break;
          case 'sponsorship':
            stats['sponsorshipEarnings'] =
                (stats['sponsorshipEarnings'] as double) + amount;
            break;
          case 'commission':
            stats['commissionEarnings'] =
                (stats['commissionEarnings'] as double) + amount;
            break;
          case 'subscription':
            stats['subscriptionEarnings'] =
                (stats['subscriptionEarnings'] as double) + amount;
            break;
          case 'artwork_sale':
            stats['artworkSalesEarnings'] =
                (stats['artworkSalesEarnings'] as double) + amount;
            break;
        }

        // Daily breakdown
        final dateKey = transaction.timestamp.toIso8601String().split('T')[0];
        final dailyBreakdown = stats['dailyBreakdown'] as Map<String, double>;
        dailyBreakdown[dateKey] = (dailyBreakdown[dateKey] ?? 0.0) + amount;

        // Source breakdown
        final sourceBreakdown = stats['sourceBreakdown'] as Map<String, double>;
        sourceBreakdown[transaction.type] =
            (sourceBreakdown[transaction.type] ?? 0.0) + amount;
      }

      // Calculate average
      if (transactions.isNotEmpty) {
        stats['averageTransaction'] =
            (stats['totalEarnings'] as double) / transactions.length;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get earnings stats: $e');
    }
  }

  /// Request a payout
  Future<PayoutModel> requestPayout({
    required double amount,
    required String payoutAccountId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Check available balance
      final earnings = await getArtistEarnings();
      if (earnings == null) throw Exception('Earnings record not found');

      if (amount > earnings.availableBalance) {
        throw Exception('Insufficient available balance');
      }

      // Create payout request
      final payout = PayoutModel(
        id: _firestore.collection('payouts').doc().id,
        artistId: user.uid,
        amount: amount,
        status: 'pending',
        requestedAt: DateTime.now(),
        payoutMethod: 'bank_account',
        accountId: payoutAccountId,
      );

      // Save payout request
      await _firestore
          .collection('payouts')
          .doc(payout.id)
          .set(payout.toFirestore());

      // Update earnings - move from available to pending
      await _firestore.collection('artist_earnings').doc(user.uid).update({
        'availableBalance': FieldValue.increment(-amount),
        'pendingBalance': FieldValue.increment(amount),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return payout;
    } catch (e) {
      throw Exception('Failed to request payout: $e');
    }
  }

  /// Get payout history for the current artist
  Future<List<PayoutModel>> getPayoutHistory({int limit = 20}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final snapshot = await _firestore
          .collection('payouts')
          .where('artistId', isEqualTo: user.uid)
          .orderBy('requestedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PayoutModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get payout history: $e');
    }
  }

  /// Get payout accounts for the current artist
  Future<List<PayoutAccountModel>> getPayoutAccounts() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final snapshot = await _firestore
          .collection('payout_accounts')
          .where('artistId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PayoutAccountModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get payout accounts: $e');
    }
  }

  /// Delete a payout account
  Future<void> deletePayoutAccount(String accountId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Check if account has any pending payouts
      final pendingPayouts = await _firestore
          .collection('payouts')
          .where('artistId', isEqualTo: user.uid)
          .where('accountId', isEqualTo: accountId)
          .where('status', whereIn: ['pending', 'processing'])
          .get();

      if (pendingPayouts.docs.isNotEmpty) {
        throw Exception(
          'Cannot delete account with pending payouts. Please wait for payouts to complete.',
        );
      }

      // Delete the account
      await _firestore.collection('payout_accounts').doc(accountId).delete();
    } catch (e) {
      throw Exception('Failed to delete payout account: $e');
    }
  }

  /// Add a new payout account
  Future<PayoutAccountModel> addPayoutAccount({
    required String accountType,
    required String accountNumber,
    required String routingNumber,
    required String accountHolderName,
    String? bankName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final account = PayoutAccountModel(
        id: _firestore.collection('payout_accounts').doc().id,
        artistId: user.uid,
        accountType: accountType,
        accountNumber: accountNumber,
        routingNumber: routingNumber,
        accountHolderName: accountHolderName,
        bankName: bankName,
        isActive: true,
        isVerified: false,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('payout_accounts')
          .doc(account.id)
          .set(account.toFirestore());

      return account;
    } catch (e) {
      throw Exception('Failed to add payout account: $e');
    }
  }

  /// Update earnings when a transaction occurs (called by other services)
  Future<void> recordEarningsTransaction({
    required String artistId,
    required String type,
    required double amount,
    required String fromUserId,
    required String fromUserName,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Create transaction record
      final transaction = EarningsTransaction(
        id: _firestore.collection('earnings_transactions').doc().id,
        artistId: artistId,
        type: type,
        amount: amount,
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        timestamp: DateTime.now(),
        status: 'completed',
        description: description,
        metadata: metadata ?? {},
      );

      await _firestore
          .collection('earnings_transactions')
          .doc(transaction.id)
          .set(transaction.toFirestore());

      // Update artist earnings
      await _updateArtistEarnings(artistId, type, amount);
    } catch (e) {
      throw Exception('Failed to record earnings transaction: $e');
    }
  }

  /// Update artist earnings totals
  Future<void> _updateArtistEarnings(
    String artistId,
    String type,
    double amount,
  ) async {
    try {
      final earningsRef = _firestore
          .collection('artist_earnings')
          .doc(artistId);

      await _firestore.runTransaction((transaction) async {
        final earningsDoc = await transaction.get(earningsRef);

        if (!earningsDoc.exists) {
          // Create initial earnings record
          final initialEarnings = EarningsModel(
            id: artistId,
            artistId: artistId,
            totalEarnings: amount,
            availableBalance: amount,
            pendingBalance: 0.0,
            boostEarnings:
                (type == 'gift' ||
                    type == 'boost' ||
                    type == 'promotion_credit')
                ? amount
                : 0.0,
            sponsorshipEarnings: type == 'sponsorship' ? amount : 0.0,
            commissionEarnings: type == 'commission' ? amount : 0.0,
            subscriptionEarnings: type == 'subscription' ? amount : 0.0,
            artworkSalesEarnings: type == 'artwork_sale' ? amount : 0.0,
            lastUpdated: DateTime.now(),
            monthlyBreakdown: {DateTime.now().month.toString(): amount},
            recentTransactions: [],
          );

          transaction.set(earningsRef, initialEarnings.toFirestore());
        } else {
          // Update existing earnings
          final currentMonth = DateTime.now().month.toString();
          final currentData = earningsDoc.data()!;
          final monthlyBreakdown = Map<String, double>.from(
            currentData['monthlyBreakdown'] as Map<String, dynamic>? ?? {},
          );

          monthlyBreakdown[currentMonth] =
              (monthlyBreakdown[currentMonth] ?? 0.0) + amount;

          final updates = {
            'totalEarnings': FieldValue.increment(amount),
            'availableBalance': FieldValue.increment(amount),
            'lastUpdated': FieldValue.serverTimestamp(),
            'monthlyBreakdown': monthlyBreakdown,
          };

          // Update specific earning type
          switch (type) {
            case 'gift':
            case 'promotion_credit':
              updates['boostEarnings'] = FieldValue.increment(amount);
              break;
            case 'sponsorship':
              updates['sponsorshipEarnings'] = FieldValue.increment(amount);
              break;
            case 'commission':
              updates['commissionEarnings'] = FieldValue.increment(amount);
              break;
            case 'subscription':
              updates['subscriptionEarnings'] = FieldValue.increment(amount);
              break;
            case 'artwork_sale':
              updates['artworkSalesEarnings'] = FieldValue.increment(amount);
              break;
          }

          transaction.update(earningsRef, updates);
        }
      });
    } catch (e) {
      throw Exception('Failed to update artist earnings: $e');
    }
  }

  /// Get earnings summary for dashboard
  Future<Map<String, dynamic>> getEarningsSummary() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final earnings = await getArtistEarnings();
      if (earnings == null) return {};

      final currentMonth = DateTime.now().month.toString();
      final previousMonth = (DateTime.now().month - 1).toString();

      final currentMonthEarnings =
          earnings.monthlyBreakdown[currentMonth] ?? 0.0;
      final previousMonthEarnings =
          earnings.monthlyBreakdown[previousMonth] ?? 0.0;

      double growthPercentage = 0.0;
      if (previousMonthEarnings > 0) {
        growthPercentage =
            ((currentMonthEarnings - previousMonthEarnings) /
                previousMonthEarnings) *
            100;
      }

      return {
        'totalEarnings': earnings.totalEarnings,
        'availableBalance': earnings.availableBalance,
        'pendingBalance': earnings.pendingBalance,
        'currentMonthEarnings': currentMonthEarnings,
        'growthPercentage': growthPercentage,
        'earningsBreakdown': {
          'boost_earnings': earnings.boostEarnings,
          'sponsorships': earnings.sponsorshipEarnings,
          'commissions': earnings.commissionEarnings,
          'subscriptions': earnings.subscriptionEarnings,
          'artworkSales': earnings.artworkSalesEarnings,
        },
        'monthlyTrend': earnings.monthlyBreakdown,
      };
    } catch (e) {
      throw Exception('Failed to get earnings summary: $e');
    }
  }
}
