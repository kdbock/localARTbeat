import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_core/auth_service.dart' as core_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> createCoreFoundationProviders() => [
  ChangeNotifierProvider<core.UserService>.value(
    value: core.UserService()..initialize(),
  ),
  ChangeNotifierProvider<core.ChapterPartnerProvider>(
    create: (_) => core.ChapterPartnerProvider()..initialize(),
    lazy: true,
  ),
  Provider<core.ChapterPartnerService>(
    create: (_) => core.ChapterPartnerService(),
    lazy: true,
  ),
  Provider<core_auth.AuthService>(
    create: (_) => core_auth.AuthService(),
    lazy: true,
  ),
  ChangeNotifierProvider<core.ConnectivityService>(
    create: (_) => core.ConnectivityService(),
    lazy: true,
  ),
  Provider<core.OnboardingService>(
    create: (_) => core.OnboardingService(),
    lazy: true,
  ),
  Provider<core.LegalConsentService>(
    create: (_) => core.LegalConsentService(),
    lazy: true,
  ),
  Provider<core.UserProgressionService>(
    create: (_) => core.UserProgressionService(),
    lazy: true,
  ),
  Provider<core.DailyChallengeReadService>(
    create: (_) => core.DailyChallengeReadService(),
    lazy: true,
  ),
  Provider<core.CommunityPostReadService>(
    create: (_) => core.CommunityPostReadService(),
    lazy: true,
  ),
  ChangeNotifierProvider<core.LeaderboardService>(
    create: (_) => core.LeaderboardService(),
    lazy: true,
  ),
  Provider<ThemeData>(create: (_) => core.ArtbeatTheme.lightTheme, lazy: false),
  ChangeNotifierProvider<core.ContentEngagementService>(
    create: (_) => core.ContentEngagementService()..initialize(),
    lazy: false,
  ),
  Provider<core.EnhancedStorageService>(
    create: (_) => core.EnhancedStorageService(),
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
  Provider<core.StorePreviewReadService>(
    create: (_) => core.StorePreviewReadService(),
    lazy: true,
  ),
  Provider<core.UserMaintenanceService>(
    create: (_) => core.UserMaintenanceService(),
    lazy: true,
  ),
  Provider<core.ArtistService>(
    create: (_) => core.ArtistService()..initialize(),
    lazy: true,
  ),
  Provider<core.PublicArtReadService>(
    create: (_) => core.PublicArtReadService()..initialize(),
    lazy: true,
  ),
  ChangeNotifierProvider<core.SubscriptionService>.value(
    value: core.SubscriptionService()..initialize(),
  ),
  Provider<core.InAppSubscriptionService>(
    create: (_) => core.InAppSubscriptionService()..initialize(),
    lazy: true,
  ),
  Provider<core.ArtistBoostService>(
    create: (_) => core.ArtistBoostService(),
    lazy: true,
  ),
  Provider<core.CommissionArtistPreviewService>(
    create: (_) => core.CommissionArtistPreviewService(),
    lazy: true,
  ),
  Provider<core.FeedbackService>(
    create: (_) => core.FeedbackService(),
    lazy: true,
  ),
  Provider<core.UsageTrackingService>(
    create: (_) => core.UsageTrackingService(),
    lazy: true,
  ),
  Provider<core.PaymentAnalyticsService>(
    create: (_) => core.PaymentAnalyticsService(),
    lazy: true,
  ),
  Provider<core.ImageManagementService>(
    create: (_) => core.ImageManagementService()..initialize(),
    lazy: true,
  ),
  Provider<core.ArtistFeatureService>(
    create: (_) => core.ArtistFeatureService(),
    lazy: true,
  ),
  Provider<core.UnifiedPaymentService>(
    create: (_) => core.UnifiedPaymentService(),
    lazy: true,
  ),
  ChangeNotifierProvider<core.CouponService>(
    create: (_) => core.CouponService(),
    lazy: true,
  ),
];
