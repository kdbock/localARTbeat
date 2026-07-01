import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_capture/artbeat_capture.dart' as capture;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_events/artbeat_events.dart'
    as events
    show
        EventService,
        EventNotificationService,
        EventSubmissionCheckoutService;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../integrations/capture_art_walk_hooks.dart';

List<SingleChildWidget> createArtWalkEventsCaptureProviders() => [
  Provider<ArtWalkService>(create: (_) => ArtWalkService(), lazy: true),
  Provider<ArtWalkProgressService>(
    create: (_) => ArtWalkProgressService(),
    lazy: true,
  ),
  Provider<ArtWalkNavigationService>(
    create: (_) => ArtWalkNavigationService(),
    lazy: true,
  ),
  Provider<ArtWalkCaptureReadService>(
    create: (_) => ArtWalkCaptureReadService(),
    lazy: true,
  ),
  Provider<ArtWalkDistanceUnitService>(
    create: (_) => ArtWalkDistanceUnitService(),
    lazy: true,
  ),
  Provider<ArtWalkUserStatsService>(
    create: (_) => ArtWalkUserStatsService(),
    lazy: true,
  ),
  Provider<ArtWalkPreviewReadService>(
    create: (_) => ArtWalkPreviewReadService(),
    lazy: true,
  ),
  Provider<AchievementService>(create: (_) => AchievementService(), lazy: true),
  Provider<AudioNavigationService>(
    create: (_) => AudioNavigationService(),
    lazy: true,
  ),
  Provider<SocialService>(
    create: (_) => SocialService()..initialize(),
    lazy: true,
  ),
  Provider<InstantDiscoveryService>(
    create: (_) => InstantDiscoveryService()..initialize(),
    lazy: true,
  ),
  Provider<RewardsService>(create: (_) => RewardsService(), lazy: true),
  Provider<events.EventService>(
    create: (_) => events.EventService(),
    lazy: true,
  ),
  Provider<events.EventNotificationService>(
    create: (_) => events.EventNotificationService(),
    lazy: true,
  ),
  Provider<events.EventSubmissionCheckoutService>(
    create: (_) => events.EventSubmissionCheckoutService(),
    lazy: true,
  ),
  Provider<capture.CaptureService>(
    create: (_) =>
        capture.CaptureService(postCaptureHooks: CaptureArtWalkHooks()),
    lazy: true,
  ),
  Provider<capture.OfflineQueueService>(
    create: (_) => capture.OfflineQueueService(),
    lazy: false,
  ),
  ProxyProvider<capture.CaptureService, core.CaptureServiceInterface>(
    update: (_, captureService, __) => captureService,
    lazy: true,
  ),
];
