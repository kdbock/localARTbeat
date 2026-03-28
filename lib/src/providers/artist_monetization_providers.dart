import 'package:artbeat_ads/artbeat_ads.dart';
import 'package:artbeat_artist/artbeat_artist.dart'
    as artist
    show
        EarningsService,
        GalleryHubReadService,
        ArtistGalleryDiscoveryReadService,
        ArtistAuctionReadService,
        SubscriptionService,
        VisibilityService,
        ArtworkService,
        ArtistProfileService,
        EventServiceAdapter;
import 'package:artbeat_capture/artbeat_capture.dart' as capture;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_core/auth_service.dart' as core_auth;
import 'package:artbeat_events/artbeat_events.dart' as events;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> createArtistMonetizationProviders() => [
  Provider<artist.SubscriptionService>(
    create:
        (context) => artist.SubscriptionService(
          auth: context.read<core_auth.AuthService>().auth,
          userService: context.read<core.UserService>(),
        ),
    lazy: true,
  ),
  Provider<artist.VisibilityService>(
    create: (_) => artist.VisibilityService(),
    lazy: true,
  ),
  Provider<artist.ArtworkService>(
    create:
        (context) => artist.ArtworkService(
          auth: context.read<core_auth.AuthService>().auth,
        ),
    lazy: true,
  ),
  Provider<artist.ArtistProfileService>(
    create: (_) => artist.ArtistProfileService(),
    lazy: true,
  ),
  Provider<artist.EarningsService>(
    create: (_) => artist.EarningsService(),
    lazy: true,
  ),
  Provider<artist.GalleryHubReadService>(
    create: (_) => artist.GalleryHubReadService(),
    lazy: true,
  ),
  Provider<artist.ArtistGalleryDiscoveryReadService>(
    create: (_) => artist.ArtistGalleryDiscoveryReadService(),
    lazy: true,
  ),
  Provider<artist.ArtistAuctionReadService>(
    create: (_) => artist.ArtistAuctionReadService(),
    lazy: true,
  ),
  Provider<artist.EventServiceAdapter>(
    create:
        (context) => artist.EventServiceAdapter(
          auth: context.read<core_auth.AuthService>().auth,
          eventService: context.read<events.EventService>(),
        ),
    lazy: true,
  ),
  Provider<LocalAdService>(create: (_) => LocalAdService(), lazy: true),
  ChangeNotifierProvider<AdReportService>(
    create: (_) => AdReportService(),
    lazy: true,
  ),
  Provider<LocalAdIapService>(create: (_) => LocalAdIapService(), lazy: true),
  ChangeNotifierProxyProvider5<
    core.ArtworkReadService,
    core.SubscriptionService,
    core.UserService,
    capture.CaptureService,
    core.PublicArtReadService,
    core.DashboardViewModel
  >(
    create: (context) => core.DashboardViewModel(
      artworkService: context.read<core.ArtworkReadService>(),
      subscriptionService: context.read<core.SubscriptionService>(),
      artistService: context.read<core.ArtistService>(),
      userService: context.read<core.UserService>(),
      captureService: context.read<capture.CaptureService>(),
      publicArtService: context.read<core.PublicArtReadService>(),
    ),
    update:
        (
          context,
          artworkService,
          subscriptionService,
          userService,
          captureService,
          publicArtService,
          previous,
        ) {
          final chapterProvider = context.read<core.ChapterPartnerProvider>();
          final viewModel =
              previous ??
              core.DashboardViewModel(
                artworkService: artworkService,
                subscriptionService: subscriptionService,
                artistService: context.read<core.ArtistService>(),
                userService: userService,
                captureService: captureService,
                publicArtService: publicArtService,
              );
          return viewModel..updateChapter(chapterProvider.activeChapterId);
        },
  ),
];
