import 'package:artbeat_profile/artbeat_profile.dart'
    as profile
    show
        ProfileActivityService,
        ProfileAnalyticsService,
        ProfileAchievementReadService,
        ProfileRewardsService,
        ProfileChallengeService;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> createProfileArtworkProviders() => [
  Provider<profile.ProfileActivityService>(
    create: (_) => profile.ProfileActivityService(),
    lazy: true,
  ),
  Provider<profile.ProfileAnalyticsService>(
    create: (_) => profile.ProfileAnalyticsService(),
    lazy: true,
  ),
  Provider<profile.ProfileAchievementReadService>(
    create: (_) => profile.ProfileAchievementReadService(),
    lazy: true,
  ),
  Provider<profile.ProfileRewardsService>(
    create: (_) => profile.ProfileRewardsService(),
    lazy: true,
  ),
  Provider<profile.ProfileChallengeService>(
    create: (_) => profile.ProfileChallengeService(),
    lazy: true,
  ),
];
