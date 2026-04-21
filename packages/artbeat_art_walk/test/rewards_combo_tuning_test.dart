import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_art_walk/src/services/rewards_service.dart';

void main() {
  group('RewardsService combo tuning', () {
    final service = RewardsService();

    test('uses base multiplier when only one quest completed today', () {
      final xp = service.calculateXPWithMultiplier(
        baseXP: 100,
        questsCompletedToday: 1,
        hasDailyWeeklyCombo: false,
      );
      expect(xp, 100);
    });

    test('applies two-quest multiplier', () {
      final xp = service.calculateXPWithMultiplier(
        baseXP: 100,
        questsCompletedToday: 2,
        hasDailyWeeklyCombo: false,
      );
      expect(xp, 115);
    });

    test('applies three-plus multiplier', () {
      final xp = service.calculateXPWithMultiplier(
        baseXP: 100,
        questsCompletedToday: 3,
        hasDailyWeeklyCombo: false,
      );
      expect(xp, 130);
    });

    test('applies combo bonus on top of quest-count multiplier with cap', () {
      final xp = service.calculateXPWithMultiplier(
        baseXP: 100,
        questsCompletedToday: 3,
        hasDailyWeeklyCombo: true,
      );
      // 1.30 + 0.15 = 1.45 (below max 1.50)
      expect(xp, 145);
    });

    test('caps multiplier at max configured value', () {
      final xp = service.calculateXPWithMultiplier(
        baseXP: 100,
        questsCompletedToday: 99,
        hasDailyWeeklyCombo: true,
      );
      // still capped at 1.45 with current defaults (3+ + combo)
      expect(xp, lessThanOrEqualTo(150));
      expect(xp, 145);
    });
  });
}
