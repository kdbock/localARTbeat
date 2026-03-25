import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_auth/artbeat_auth.dart';
import 'package:artbeat_capture/artbeat_capture.dart' as capture;
import 'package:artbeat_community/artbeat_community.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_messaging/artbeat_messaging.dart' as messaging;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'integrations/capture_art_walk_hooks.dart';

List<SingleChildWidget> createAppProviders() => [
  ChangeNotifierProvider<core.UserService>(
    create: (_) => core.UserService()..initialize(),
    lazy: false,
  ),
  ChangeNotifierProvider<core.ChapterPartnerProvider>(
    create: (_) => core.ChapterPartnerProvider()..initialize(),
    lazy: true,
  ),
  Provider<AuthService>(create: (_) => AuthService(), lazy: true),
  ChangeNotifierProvider<core.ConnectivityService>(
    create: (_) => core.ConnectivityService(),
    lazy: true,
  ),
  Provider<ThemeData>(create: (_) => core.ArtbeatTheme.lightTheme, lazy: false),
  ChangeNotifierProvider<core.ContentEngagementService>(
    create: (_) => core.ContentEngagementService()..initialize(),
    lazy: false,
  ),
  ChangeNotifierProvider<messaging.ChatService>(
    create: (_) => messaging.ChatService(),
    lazy: true,
  ),
  Provider<core.MessagingStatusService>(
    create: (_) => core.MessagingStatusService(),
    lazy: true,
  ),
  ChangeNotifierProvider<messaging.MessageReactionService>(
    create: (_) => messaging.MessageReactionService(),
    lazy: true,
  ),
  ChangeNotifierProvider<core.MessagingProvider>(
    create: (context) =>
        core.MessagingProvider(context.read<core.MessagingStatusService>()),
    lazy: true,
  ),
  Provider<messaging.PresenceService>(
    create: (_) => messaging.PresenceService(),
    lazy: false,
  ),
  ChangeNotifierProvider<messaging.PresenceProvider>(
    create: (context) =>
        messaging.PresenceProvider(context.read<messaging.PresenceService>()),
    lazy: false,
  ),
  ChangeNotifierProvider<CommunityService>(
    create: (_) => CommunityService(),
    lazy: true,
  ),
  ChangeNotifierProvider<core.CommunityProvider>(
    create: (_) => core.CommunityProvider(),
    lazy: true,
  ),
  ChangeNotifierProvider<core.SearchController>(
    create: (_) => core.SearchController(),
    lazy: true,
  ),
  Provider<core.ArtworkReadService>(
    create: (_) => core.ArtworkReadService()..initialize(),
    lazy: true,
  ),
  Provider<core.PublicArtReadService>(
    create: (_) => core.PublicArtReadService()..initialize(),
    lazy: true,
  ),
  Provider<ArtWalkService>(create: (_) => ArtWalkService(), lazy: true),
  Provider<ArtWalkProgressService>(
    create: (_) => ArtWalkProgressService(),
    lazy: true,
  ),
  Provider<ArtWalkNavigationService>(
    create: (_) => ArtWalkNavigationService(),
    lazy: true,
  ),
  Provider<AchievementService>(
    create: (_) => AchievementService(),
    lazy: true,
  ),
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
  Provider<ChallengeService>(
    create: (_) => ChallengeService()..initialize(),
    lazy: true,
  ),
  Provider<WeeklyGoalsService>(
    create: (_) => WeeklyGoalsService()..initialize(),
    lazy: true,
  ),
  Provider<RewardsService>(create: (_) => RewardsService(), lazy: true),
  Provider<capture.CaptureService>(
    create: (_) =>
        capture.CaptureService(postCaptureHooks: CaptureArtWalkHooks()),
    lazy: true,
  ),
  ProxyProvider<capture.CaptureService, core.CaptureServiceInterface>(
    update: (_, captureService, __) => captureService,
    lazy: true,
  ),
  ChangeNotifierProvider<core.SubscriptionService>(
    create: (_) => core.SubscriptionService()..initialize(),
    lazy: false,
  ),
  ChangeNotifierProxyProvider5<
    core.ArtworkReadService,
    core.SubscriptionService,
    core.UserService,
    capture.CaptureService,
    core.PublicArtReadService,
    core.DashboardViewModel
  >(
    create: (BuildContext context) => core.DashboardViewModel(
      artworkService: context.read<core.ArtworkReadService>(),
      subscriptionService: context.read<core.SubscriptionService>(),
      userService: context.read<core.UserService>(),
      captureService: context.read<capture.CaptureService>(),
      publicArtService: context.read<core.PublicArtReadService>(),
    ),
    update:
        (
          BuildContext context,
          core.ArtworkReadService artworkService,
          core.SubscriptionService subscriptionService,
          core.UserService userService,
          capture.CaptureService captureService,
          core.PublicArtReadService publicArtService,
          core.DashboardViewModel? previous,
        ) {
          final chapterProvider = context.read<core.ChapterPartnerProvider>();
          final viewModel =
              previous ??
              core.DashboardViewModel(
                artworkService: artworkService,
                subscriptionService: subscriptionService,
                userService: userService,
                captureService: captureService,
                publicArtService: publicArtService,
              );
          return viewModel..updateChapter(chapterProvider.activeChapterId);
        },
  ),
];
