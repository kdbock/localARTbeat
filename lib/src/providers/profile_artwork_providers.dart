import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_profile/artbeat_profile.dart'
    as profile
    show
        ProfileConnectionService,
        ProfileActivityService,
        ProfileAnalyticsService,
        ProfileAchievementReadService,
        ProfileRewardsService,
        ProfileChallengeService;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> createProfileArtworkProviders() => [
  Provider<profile.ProfileConnectionService>(
    create: (_) => profile.ProfileConnectionService(),
    lazy: true,
  ),
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
  Provider<ArtworkService>(create: (_) => ArtworkService(), lazy: true),
  Provider<ChapterService>(create: (_) => ChapterService(), lazy: true),
  Provider<ArtworkDiscoveryService>(
    create: (_) => ArtworkDiscoveryService(),
    lazy: true,
  ),
  Provider<ArtworkPaginationService>(
    create: (_) => ArtworkPaginationService(),
    lazy: true,
  ),
  Provider<ArtworkLocalReadService>(
    create: (_) => ArtworkLocalReadService(),
    lazy: true,
  ),
  Provider<AuctionService>(create: (_) => AuctionService(), lazy: true),
  Provider<CollectionService>(create: (_) => CollectionService(), lazy: true),
  Provider<ArtworkRatingService>(
    create: (_) => ArtworkRatingService(),
    lazy: true,
  ),
  Provider<ArtworkCommentService>(
    create: (_) => ArtworkCommentService(),
    lazy: true,
  ),
  Provider<ArtworkVisibilityService>(
    create: (_) => ArtworkVisibilityService(),
    lazy: true,
  ),
];
