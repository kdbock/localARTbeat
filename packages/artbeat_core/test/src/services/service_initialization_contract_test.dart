import 'package:artbeat_core/src/services/achievement_service.dart';
import 'package:artbeat_core/src/services/ai_service.dart';
import 'package:artbeat_core/src/services/artist_boost_service.dart';
import 'package:artbeat_core/src/services/artist_feature_service.dart';
import 'package:artbeat_core/src/services/artist_service.dart';
import 'package:artbeat_core/src/services/auth_service.dart';
import 'package:artbeat_core/src/services/biometric_auth_service.dart';
import 'package:artbeat_core/src/services/content_engagement_service.dart';
import 'package:artbeat_core/src/services/daily_challenge_read_service.dart';
import 'package:artbeat_core/src/services/discovery_progress_read_service.dart';
import 'package:artbeat_core/src/services/engagement_migration_service.dart';
import 'package:artbeat_core/src/services/filter_service.dart';
import 'package:artbeat_core/src/services/in_app_purchase_service.dart';
import 'package:artbeat_core/src/services/in_app_subscription_service.dart';
import 'package:artbeat_core/src/services/leaderboard_service.dart';
import 'package:artbeat_core/src/services/monetization_funnel_service.dart';
import 'package:artbeat_core/src/services/payment_analytics_service.dart';
import 'package:artbeat_core/src/services/search/search_analytics.dart';
import 'package:artbeat_core/src/services/social_activity_read_service.dart';
import 'package:artbeat_core/src/services/subscription_service.dart';
import 'package:artbeat_core/src/services/subscription_migration_service.dart';
import 'package:artbeat_core/src/services/usage_tracking_service.dart';
import 'package:artbeat_core/src/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Service initialization contracts', () {
    test('UserService initializes safely in flutter test mode', () {
      final userService = UserService();

      userService.initialize();

      expect(userService.currentUser, isNull);
    });

    test(
      'SubscriptionService can be constructed without eager Firebase access',
      () {
        expect(SubscriptionService.new, returnsNormally);
      },
    );

    test(
      'ContentEngagementService can be constructed without eager Firebase access',
      () {
        expect(ContentEngagementService.new, returnsNormally);
      },
    );

    test('AuthService can be constructed without eager Firebase access', () {
      expect(AuthService.new, returnsNormally);
    });

    test(
      'AchievementService can be constructed without eager Firebase access',
      () {
        expect(AchievementService.new, returnsNormally);
      },
    );

    test('AIService can be constructed without eager Firebase access', () {
      expect(AIService.new, returnsNormally);
    });

    test(
      'ArtistBoostService can be constructed without eager Firebase access',
      () {
        expect(ArtistBoostService.new, returnsNormally);
      },
    );

    test(
      'ArtistFeatureService can be constructed without eager Firebase access',
      () {
        expect(ArtistFeatureService.new, returnsNormally);
      },
    );

    test('ArtistService can be constructed without eager Firebase access', () {
      expect(ArtistService.new, returnsNormally);
    });

    test(
      'BiometricAuthService can be constructed without eager Firebase access',
      () {
        expect(BiometricAuthService.new, returnsNormally);
      },
    );

    test(
      'DailyChallengeReadService can be constructed without eager Firebase access',
      () {
        expect(DailyChallengeReadService.new, returnsNormally);
      },
    );

    test(
      'DiscoveryProgressReadService can be constructed without eager Firebase access',
      () {
        expect(DiscoveryProgressReadService.new, returnsNormally);
      },
    );

    test(
      'EngagementMigrationService can be constructed without eager Firebase access',
      () {
        expect(EngagementMigrationService.new, returnsNormally);
      },
    );

    test('FilterService can be constructed without eager Firebase access', () {
      expect(FilterService.new, returnsNormally);
    });

    test(
      'InAppPurchaseService can be constructed without eager Firebase access',
      () {
        expect(InAppPurchaseService.new, returnsNormally);
      },
    );

    test(
      'InAppSubscriptionService can be constructed without eager Firebase access',
      () {
        expect(InAppSubscriptionService.new, returnsNormally);
      },
    );

    test(
      'LeaderboardService can be constructed without eager Firebase access',
      () {
        expect(LeaderboardService.new, returnsNormally);
      },
    );

    test(
      'MonetizationFunnelService can be constructed without eager Firebase access',
      () {
        expect(MonetizationFunnelService.new, returnsNormally);
      },
    );

    test(
      'PaymentAnalyticsService can be constructed without eager Firebase access',
      () {
        expect(PaymentAnalyticsService.new, returnsNormally);
      },
    );

    test(
      'SearchAnalytics can be constructed without eager Firebase access',
      () {
        expect(SearchAnalytics.new, returnsNormally);
      },
    );

    test(
      'SocialActivityReadService can be constructed without eager Firebase access',
      () {
        expect(SocialActivityReadService.new, returnsNormally);
      },
    );

    test(
      'SubscriptionMigrationService can be constructed without eager Firebase access',
      () {
        expect(SubscriptionMigrationService.new, returnsNormally);
      },
    );

    test(
      'UsageTrackingService can be constructed without eager Firebase access',
      () {
        expect(UsageTrackingService.new, returnsNormally);
      },
    );
  });
}
