import 'package:artbeat_artist/src/models/earnings_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EarningsModel', () {
    test('getGrowthPercentage calculates month-over-month growth', () {
      final now = DateTime.now();
      final currentMonth = now.month.toString();
      final previousMonth = (now.month == 1 ? 12 : now.month - 1).toString();

      final model = EarningsModel(
        id: 'earnings-1',
        artistId: 'artist-1',
        totalEarnings: 300,
        availableBalance: 100,
        pendingBalance: 20,
        boostEarnings: 10,
        sponsorshipEarnings: 20,
        commissionEarnings: 30,
        subscriptionEarnings: 40,
        artworkSalesEarnings: 200,
        lastUpdated: now,
        monthlyBreakdown: {currentMonth: 200, previousMonth: 100},
        recentTransactions: const [],
      );

      expect(model.getGrowthPercentage(), closeTo(100.0, 0.001));
    });

    test('getEarningsBreakdownPercentages totals to ~100%', () {
      final model = EarningsModel(
        id: 'earnings-2',
        artistId: 'artist-2',
        totalEarnings: 200,
        availableBalance: 0,
        pendingBalance: 0,
        boostEarnings: 20,
        sponsorshipEarnings: 20,
        commissionEarnings: 20,
        subscriptionEarnings: 20,
        artworkSalesEarnings: 120,
        lastUpdated: DateTime.now(),
        monthlyBreakdown: const {},
        recentTransactions: const [],
      );

      final breakdown = model.getEarningsBreakdownPercentages();
      final total = breakdown.values.fold<double>(0.0, (a, b) => a + b);
      expect(total, closeTo(100.0, 0.001));
      expect(breakdown['Artwork Sales'], closeTo(60.0, 0.001));
    });
  });
}
