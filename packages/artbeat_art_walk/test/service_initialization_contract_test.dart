import 'package:artbeat_art_walk/src/services/challenge_service.dart';
import 'package:artbeat_art_walk/src/services/instant_discovery_service.dart';
import 'package:artbeat_art_walk/src/services/rewards_service.dart';
import 'package:artbeat_art_walk/src/services/social_service.dart';
import 'package:artbeat_art_walk/src/services/weekly_goals_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Art walk service initialization contracts', () {
    test(
      'ChallengeService can be constructed without eager Firebase access',
      () {
        expect(ChallengeService.new, returnsNormally);
      },
    );

    test(
      'WeeklyGoalsService can be constructed without eager Firebase access',
      () {
        expect(WeeklyGoalsService.new, returnsNormally);
      },
    );

    test('RewardsService can be constructed without eager Firebase access', () {
      expect(RewardsService.new, returnsNormally);
    });

    test('SocialService can be constructed without eager Firebase access', () {
      expect(SocialService.new, returnsNormally);
    });

    test(
      'InstantDiscoveryService can be constructed without eager Firebase access',
      () {
        expect(InstantDiscoveryService.new, returnsNormally);
      },
    );
  });
}
