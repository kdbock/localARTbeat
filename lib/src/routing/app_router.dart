import 'package:artbeat_admin/artbeat_admin.dart' as admin;
import 'package:artbeat_ads/artbeat_ads.dart' as ads;
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_auth/artbeat_auth.dart' as auth;
import 'package:artbeat_community/artbeat_community.dart' as community;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_events/artbeat_events.dart' as events;
import 'package:artbeat_messaging/artbeat_messaging.dart' as messaging;
import 'package:artbeat_profile/artbeat_profile.dart' as profile;
import 'package:artbeat_settings/artbeat_settings.dart' as settings_pkg;
import 'package:artbeat_sponsorships/artbeat_sponsorships.dart' as sponsorships;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../screens/notifications_screen.dart';
import '../guards/auth_guard.dart';
import '../screens/about_screen.dart';
import '../screens/ads_route_screen.dart';
import '../screens/artwork_auction_management_route_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/rewards_screen.dart';
import '../screens/terms_of_service_screen.dart';
import 'handlers/art_walk_route_handler.dart';
import 'handlers/capture_route_handler.dart';
import 'handlers/profile_route_handler.dart';
import 'handlers/root_route_handler.dart';
import 'route_utils.dart';

/// Main application router that handles all route generation
class AppRouter {
  final _authGuard = AuthGuard();
  final _artWalkRouteHandler = const ArtWalkRouteHandler();
  final _rootRouteHandler = const RootRouteHandler();
  final _captureRouteHandler = const CaptureRouteHandler();
  final _profileRouteHandler = const ProfileRouteHandler();

  // Shared view model instance for artist onboarding
  // This ensures state persists across all onboarding screens
  static core.ArtistOnboardingViewModel? _onboardingViewModel;

  /// Main route generation method
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;
    if (routeName == null) {
      return RouteUtils.createNotFoundRoute();
    }

    core.AppLogger.info('🛣️ Navigating to: $routeName');

    // Check if user is authenticated for protected routes
    if (!_authGuard.isAuthenticated &&
        _rootRouteHandler.isProtectedRoute(routeName)) {
      return RouteUtils.createSimpleRoute(child: const auth.LoginScreen());
    }

    final directRoute = _rootRouteHandler.handleDirectRoute(
      settings,
      buildOnboardingScreen: _buildOnboardingScreen,
    );
    if (directRoute != null) {
      return directRoute;
    }

    // Try specialized routes
    final specializedRoute = _handleSpecializedRoutes(settings);
    if (specializedRoute != null) {
      return specializedRoute;
    }

    // Route not found
    return RouteUtils.createNotFoundRoute();
  }

  /// Get or create shared onboarding view model instance
  core.ArtistOnboardingViewModel _getOnboardingViewModel() {
    if (_onboardingViewModel == null) {
      _onboardingViewModel = core.ArtistOnboardingViewModel();
      _onboardingViewModel!.initialize();
    }
    return _onboardingViewModel!;
  }

  /// Build onboarding screen with shared view model
  Widget _buildOnboardingScreen(String routeName) {
    final viewModel = _getOnboardingViewModel();

    Widget screen;
    switch (routeName) {
      case core.AppRoutes.artistOnboardingWelcome:
        screen = const core.WelcomeScreen();
        break;
      case core.AppRoutes.artistOnboardingIntroduction:
        screen = const core.ArtistIntroductionScreen();
        break;
      case core.AppRoutes.artistOnboardingStory:
        screen = const core.ArtistStoryScreen();
        break;
      case core.AppRoutes.artistOnboardingArtwork:
        screen = const core.ArtworkUploadScreen();
        break;
      case core.AppRoutes.artistOnboardingFeatured:
        screen = const core.FeaturedArtworkScreen();
        break;
      case core.AppRoutes.artistOnboardingBenefits:
        screen = const core.BenefitsScreen();
        break;
      case core.AppRoutes.artistOnboardingSelection:
        screen = const core.TierSelectionScreen();
        break;
      default:
        screen = const core.WelcomeScreen();
    }

    return ChangeNotifierProvider<core.ArtistOnboardingViewModel>.value(
      value: viewModel,
      child: screen,
    );
  }

  /// Handles specialized routes that aren't in core handler
  Route<dynamic>? _handleSpecializedRoutes(RouteSettings settings) {
    final routeName = settings.name;

    // Artist routes
    if (routeName!.startsWith('/artist')) {
      return _handleArtistRoutes(settings);
    }

    // Artwork routes
    if (routeName.startsWith('/artwork')) {
      return _handleArtworkRoutes(settings);
    }

    // Gallery routes
    if (routeName.startsWith('/gallery')) {
      return _handleGalleryRoutes(settings);
    }

    // Commission routes
    if (routeName.startsWith('/commission')) {
      return _handleCommissionRoutes(settings);
    }

    // Community routes
    if (routeName.startsWith('/community')) {
      return _handleCommunityRoutes(settings);
    }

    // Art Walk routes (including admin moderation)
    if (routeName.startsWith('/art-walk') ||
        routeName.startsWith('/enhanced') ||
        routeName.startsWith('/artwalk') ||
        routeName.startsWith('/instant')) {
      return _handleArtWalkRoutes(settings);
    }

    // Messaging routes
    if (routeName.startsWith('/messaging')) {
      return _handleMessagingRoutes(settings);
    }

    // Events routes
    if (routeName.startsWith('/events')) {
      return _handleEventsRoutes(settings);
    }

    // Ads routes
    if (routeName.startsWith('/ads')) {
      return _handleAdsRoutes(settings);
    }

    // Admin routes
    if (routeName.startsWith('/admin')) {
      return _handleAdminRoutes(settings);
    }

    // Profile routes
    if (routeName.startsWith('/profile')) {
      return _handleProfileRoutes(settings);
    }

    // Settings routes
    if (routeName.startsWith('/settings')) {
      return _handleSettingsRoutes(settings);
    }

    // Capture routes
    if (routeName.startsWith('/capture')) {
      return _handleCaptureRoutes(settings);
    }

    // Subscription routes
    if (routeName.startsWith('/subscription')) {
      return _handleSubscriptionRoutes(settings);
    }

    // In-App Purchase routes
    if (routeName.startsWith('/iap')) {
      return _handleIapRoutes(settings);
    }

    // Miscellaneous routes
    return _handleMiscRoutes(settings);
  }

  /// Handles artist-related routes
  Route<dynamic>? _handleArtistRoutes(RouteSettings settings) {
    switch (settings.name) {
      case '/artist/signup':
        return RouteUtils.createSimpleRoute(
          child: const artist.ArtistOnboardScreen(),
        );
      case core.AppRoutes.artistDashboard:
        return RouteUtils.createMainNavRoute(
          child: const artist.GalleryHubScreen(),
        );

      case core.AppRoutes.artistOnboarding:
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () => core.MainLayout(
            currentIndex: -1,
            appBar: RouteUtils.createAppBar('Join as Artist'),
            child: Builder(
              builder: (context) {
                final firebaseUser = FirebaseAuth.instance.currentUser;
                if (firebaseUser == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                return const artist.ArtistOnboardScreen();
              },
            ),
          ),
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      // New Artist Onboarding Flow - wrapped with Provider
      // IMPORTANT: All routes share the same ViewModel instance to persist state
      case core.AppRoutes.artistOnboardingWelcome:
      case core.AppRoutes.artistOnboardingIntroduction:
      case core.AppRoutes.artistOnboardingStory:
      case core.AppRoutes.artistOnboardingArtwork:
      case core.AppRoutes.artistOnboardingFeatured:
      case core.AppRoutes.artistOnboardingBenefits:
      case core.AppRoutes.artistOnboardingSelection:
        return RouteUtils.createSimpleRoute(
          child: _buildOnboardingScreen(settings.name!),
        );

      case core.AppRoutes.artistOnboardingComplete:
        return RouteUtils.createSimpleRoute(
          child: ChangeNotifierProvider(
            create: (_) => core.ArtistOnboardingViewModel()..initialize(),
            child: const core.OnboardingCompletionScreen(),
          ),
        );

      case core.AppRoutes.artistProfileEdit:
        return RouteUtils.createMainLayoutRoute(
          child: const artist.ArtistProfileEditScreen(),
        );

      case core.AppRoutes.artistPublicProfile:
        final artistId = RouteUtils.getArgument<String>(settings, 'artistId');
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final targetUserId = artistId ?? currentUserId;

        if (targetUserId == null) {
          return RouteUtils.createErrorRoute(
            'Please log in to view your profile',
          );
        }
        return RouteUtils.createMainLayoutRoute(
          child: artist.ArtistPublicProfileScreen(userId: targetUserId),
        );

      case core.AppRoutes.artistAnalytics:
        return RouteUtils.createMainLayoutRoute(
          child: const artist.VisibilityInsightsScreen(),
        );

      case core.AppRoutes.artistArtwork:
        return RouteUtils.createMainLayoutRoute(
          child: const artwork.ArtistArtworkManagementScreen(),
        );

      case core.AppRoutes.artistFeed:
        final args = settings.arguments as Map<String, dynamic>?;
        final artistUserId = args?['artistUserId'] as String?;
        if (artistUserId != null) {
          // For now, create a loading screen that will fetch the artist data
          return RouteUtils.createMainLayoutRoute(
            child: _ArtistFeedLoader(artistUserId: artistUserId),
          );
        }
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Artist not found')),
        );

      case core.AppRoutes.artistBrowse:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 3,
          child: const artist.ArtistBrowseScreen(),
        );

      case core.AppRoutes.artistEarnings:
        return RouteUtils.createMainLayoutRoute(
          child: const artist.ArtistEarningsHub(),
        );

      case core.AppRoutes.artistPayoutRequest:
        final args = settings.arguments as Map<String, dynamic>?;
        final availableBalance = args?['availableBalance'] as double? ?? 0.0;
        final onPayoutRequested = args?['onPayoutRequested'] as VoidCallback?;
        return RouteUtils.createMainLayoutRoute(
          child: artist.PayoutRequestScreen(
            availableBalance: availableBalance,
            onPayoutRequested: onPayoutRequested ?? () {},
          ),
        );

      case core.AppRoutes.artistPayoutAccounts:
        return RouteUtils.createMainLayoutRoute(
          child: const artist.PayoutAccountsScreen(),
        );

      case core.AppRoutes.artistFeatured:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 3,
          child: const artist.ArtistBrowseScreen(mode: 'featured'),
        );

      case core.AppRoutes.artistApprovedAds:
        return RouteUtils.createComingSoonRoute('Approved Ads');

      case '/artist/artwork-detail':
        final artworkId = RouteUtils.getArgument<String>(settings, 'artworkId');
        if (artworkId == null) {
          return RouteUtils.createErrorRoute('Artwork not found');
        }
        return RouteUtils.createSimpleRoute(
          child: artwork.ArtworkDetailScreen(artworkId: artworkId),
        );

      default:
        return RouteUtils.createNotFoundRoute('Artist feature');
    }
  }

  /// Handles artwork-related routes
  Route<dynamic>? _handleArtworkRoutes(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.artworkUpload:
      case core.AppRoutes.artworkUploadChoice:
        return RouteUtils.createMainLayoutRoute(
          child: const artwork.UploadChoiceScreen(),
        );

      case core.AppRoutes.artworkUploadVisual:
        return RouteUtils.createMainLayoutRoute(
          child: const artwork.EnhancedArtworkUploadScreen(),
        );

      case core.AppRoutes.artworkUploadWritten:
        return RouteUtils.createMainLayoutRoute(
          child: const artwork.WrittenContentUploadScreen(),
        );

      case core.AppRoutes.artworkBrowse:
        return RouteUtils.createSimpleRoute(
          child: const artwork.ArtworkBrowseScreen(),
        );

      case core.AppRoutes.artworkEdit:
        final artworkId = RouteUtils.getArgument<String>(settings, 'artworkId');
        final artworkModel = RouteUtils.getArgument<artwork.ArtworkModel>(
          settings,
          'artwork',
        );
        if (artworkId == null) {
          return RouteUtils.createErrorRoute('Artwork not found');
        }
        return RouteUtils.createSimpleRoute(
          child: artwork.ArtworkEditScreen(
            artworkId: artworkId,
            artwork: artworkModel,
          ),
        );

      case core.AppRoutes.artworkDetail:
        final artworkId = RouteUtils.getArgument<String>(settings, 'artworkId');
        if (artworkId == null) {
          return RouteUtils.createErrorRoute('Artwork not found');
        }
        return RouteUtils.createSimpleRoute(
          child: artwork.ArtworkDetailScreen(artworkId: artworkId),
        );

      case core.AppRoutes.artworkAuctionSetup:
        final modeName = RouteUtils.getArgument<String>(settings, 'mode');
        final mode = modeName == 'editing'
            ? artwork.AuctionSetupMode.editing
            : artwork.AuctionSetupMode.firstTime;
        return RouteUtils.createSimpleRoute(
          child: artwork.AuctionSetupWizardScreen(mode: mode),
        );

      case core.AppRoutes.artworkAuctionManage:
        final artworkId = RouteUtils.getArgument<String>(settings, 'artworkId');
        if (artworkId == null) {
          return RouteUtils.createErrorRoute('Artwork not found');
        }
        return RouteUtils.createSimpleRoute(
          child: ArtworkAuctionManagementRouteScreen(artworkId: artworkId),
        );

      case '/artwork/written-content':
        final writtenContentId = settings.arguments as String?;
        if (writtenContentId == null) {
          return RouteUtils.createErrorRoute('Written content not found');
        }
        return RouteUtils.createSimpleRoute(
          child: artwork.WrittenContentDetailScreen(
            artworkId: writtenContentId,
          ),
        );

      case core.AppRoutes.artworkPurchase:
        final artworkId = RouteUtils.getArgument<String>(settings, 'artworkId');
        if (artworkId == null) {
          return RouteUtils.createErrorRoute(
            'Artwork ID required for purchase',
          );
        }
        return RouteUtils.createSimpleRoute(
          child: artwork.ArtworkPurchaseScreen(artworkId: artworkId),
        );

      case core.AppRoutes.artworkFeatured:
        return RouteUtils.createSimpleRoute(
          child: const artwork.ArtworkFeaturedScreen(),
        );

      case core.AppRoutes.artworkRecent:
        return RouteUtils.createSimpleRoute(
          child: const artwork.ArtworkRecentScreen(),
        );

      case core.AppRoutes.artworkTrending:
        return RouteUtils.createSimpleRoute(
          child: const artwork.ArtworkTrendingScreen(),
        );

      case core.AppRoutes.artworkSearch:
        final searchQuery = RouteUtils.getArgument<String>(settings, 'query');
        return RouteUtils.createSimpleRoute(
          child: artwork.AdvancedArtworkSearchScreen(initialQuery: searchQuery),
        );

      case '/artwork/local':
        // Navigate to browse screen filtered by location
        return RouteUtils.createSimpleRoute(
          child: const artwork.ArtworkBrowseScreen(),
        );

      case '/artwork/discovery':
        // Navigate to browse screen for discovery
        return RouteUtils.createSimpleRoute(
          child: const artwork.ArtworkBrowseScreen(),
        );

      default:
        return RouteUtils.createNotFoundRoute('Artwork feature');
    }
  }

  /// Handles gallery-related routes
  Route<dynamic>? _handleGalleryRoutes(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.galleryArtistsManagement:
        return RouteUtils.createMainNavRoute(
          child: const artist.GalleryArtistsManagementScreen(),
        );

      case core.AppRoutes.galleryAnalytics:
        return RouteUtils.createMainLayoutRoute(
          child: const artist.GalleryVisibilityHubScreen(),
        );

      default:
        return RouteUtils.createNotFoundRoute('Gallery feature');
    }
  }

  /// Handles community-related routes
  Route<dynamic>? _handleCommunityRoutes(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.communityDashboard:
        return RouteUtils.createMainNavRoute(
          currentIndex: 3,
          child: const community.ArtCommunityHub(),
        );

      case core.AppRoutes.communityFeed:
        // Use createMainNavRoute to ensure proper MainLayout wrapping
        return RouteUtils.createMainNavRoute(
          currentIndex: 3,
          child: const community.ArtCommunityHub(),
        );

      case core.AppRoutes.communityArtists:
        return RouteUtils.createMainLayoutRoute(
          child: const community.PortfoliosScreen(),
        );

      case core.AppRoutes.communitySearch:
        return RouteUtils.createMainLayoutRoute(
          child: const core.SearchResultsPage(),
        );

      case core.AppRoutes.communityPosts:
        return RouteUtils.createMainLayoutRoute(
          child: const community.ArtCommunityHub(),
        );

      case core.AppRoutes.communityStudios:
        return RouteUtils.createMainLayoutRoute(
          child: const community.StudiosScreen(),
        );

      case core.AppRoutes.communityBoosts:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Boost Artists'),
          child: const community.ViewReceivedBoostsScreen(),
        );

      case core.AppRoutes.communityPortfolios:
        return RouteUtils.createMainLayoutRoute(
          child: const community.PortfoliosScreen(),
        );

      case core.AppRoutes.communityModeration:
        return _handleAdminRoutes(
          RouteSettings(
            name: admin.AdminRoutes.communityModeration,
            arguments: settings.arguments,
          ),
        );

      case core.AppRoutes.communitySponsorships:
        return RouteUtils.createMainLayoutRoute(
          child: const sponsorships.LocalBusinessScreen(),
        );

      case core.AppRoutes.communitySettings:
        return RouteUtils.createMainLayoutRoute(
          child: const community.QuietModeScreen(),
        );

      case core.AppRoutes.communityCreate:
        final args = settings.arguments as Map<String, dynamic>?;
        final prefilledImageUrl = args?['prefilledImageUrl'] as String?;
        final prefilledCaption = args?['prefilledCaption'] as String?;
        final isDiscussionPost = args?['isDiscussionPost'] as bool? ?? false;

        return RouteUtils.createMainLayoutRoute(
          child: community.CreatePostScreen(
            prefilledImageUrl: prefilledImageUrl,
            prefilledCaption: prefilledCaption,
            isDiscussionPost: isDiscussionPost,
          ),
        );

      case core.AppRoutes.communityMessaging:
        return RouteUtils.createMainLayoutRoute(
          child: const community.StudiosScreen(),
        );

      case core.AppRoutes.communityTrending:
        return RouteUtils.createMainLayoutRoute(
          child: const community.TrendingContentScreen(),
        );

      case core.AppRoutes.communityFeatured:
        return RouteUtils.createMainLayoutRoute(
          child: const community.ArtCommunityHub(),
        );

      case core.AppRoutes.community:
        // Redirect to community dashboard
        return RouteUtils.createSimpleRoute(
          child: const community.ArtCommunityHub(),
        );

      case core.AppRoutes.artCommunityHub:
        return RouteUtils.createMainNavRoute(
          currentIndex: 3,
          child: const community.ArtCommunityHub(),
        );

      default:
        return RouteUtils.createNotFoundRoute('Community feature');
    }
  }

  /// Handles commission-related routes
  Route<dynamic>? _handleCommissionRoutes(RouteSettings settings) {
    switch (settings.name) {
      case '/commission/request':
        final args = settings.arguments as Map<String, dynamic>?;
        final artistId = args?['artistId'] as String?;
        final artistName = args?['artistName'] as String?;

        // If no arguments provided, show the user's commission requests
        if (artistId == null || artistName == null) {
          return RouteUtils.createSimpleRoute(
            child: const community.DirectCommissionsScreen(),
          );
        }

        // If arguments provided, show commission request form for specific artist
        return RouteUtils.createSimpleRoute(
          child: community.CommissionRequestScreen(
            artistId: artistId,
            artistName: artistName,
          ),
        );

      case '/commission/hub':
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Commission Hub'),
          child: const community.CommissionHubScreen(),
        );

      default:
        return RouteUtils.createNotFoundRoute('Commission feature');
    }
  }

  /// Handles art walk-related routes
  Route<dynamic>? _handleArtWalkRoutes(RouteSettings settings) =>
      _artWalkRouteHandler.handleRoute(
        settings,
        handleAdminRoute: _handleAdminRoutes,
      );

  /// Handles messaging-related routes
  Route<dynamic>? _handleMessagingRoutes(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.messaging:
        return RouteUtils.createSimpleRoute(
          child: const messaging.ArtisticMessagingScreen(),
        );

      case core.AppRoutes.messagingInbox:
        return RouteUtils.createMainLayoutRoute(
          child: const messaging.MessagingDashboardScreen(),
        );

      case core.AppRoutes.messagingNew:
        return RouteUtils.createMainLayoutRoute(
          child: const messaging.ContactSelectionScreen(),
        );

      case core.AppRoutes.messagingChat:
        final args = settings.arguments as Map<String, dynamic>?;
        final chat = args?['chat'] as messaging.ChatModel?;
        if (chat != null) {
          return RouteUtils.createMainLayoutRoute(
            child: messaging.ChatScreen(chat: chat),
          );
        }
        return RouteUtils.createNotFoundRoute('Chat not found');

      case core.AppRoutes.messagingUserChat:
        final args = settings.arguments as Map<String, dynamic>?;
        final userId = args?['userId'] as String?;
        if (userId != null && userId.isNotEmpty) {
          // Create a temporary screen that will handle the chat creation
          return RouteUtils.createMainLayoutRoute(
            child: _UserChatLoader(userId: userId),
          );
        }
        return RouteUtils.createNotFoundRoute('User chat not found');

      case core.AppRoutes.messagingThread:
        final args = settings.arguments as Map<String, dynamic>?;
        final chat = args?['chat'] as messaging.ChatModel?;
        final threadId = args?['threadId'] as String?;
        if (chat != null && threadId != null) {
          return RouteUtils.createMainLayoutRoute(
            child: messaging.MessageThreadViewScreen(
              chat: chat,
              threadId: threadId,
            ),
          );
        }
        return RouteUtils.createNotFoundRoute('Thread not found');

      default:
        return RouteUtils.createNotFoundRoute('Messaging feature');
    }
  }

  /// Handles events-related routes
  Route<dynamic>? _handleEventsRoutes(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.events:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 4,
          drawer: const events.EventsDrawer(),
          child: const events.EventsDashboardScreen(),
        );

      case core.AppRoutes.eventsDiscover:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 4,
          drawer: const events.EventsDrawer(),
          child: const events.EventsListScreen(),
        );

      case core.AppRoutes.eventsDashboard:
      case core.AppRoutes.eventsArtistDashboard:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 4,
          drawer: const events.EventsDrawer(),
          child: const events.EventsDashboardScreen(),
        );

      case core.AppRoutes.eventsCreate:
        return RouteUtils.createMainLayoutRoute(
          drawer: const events.EventsDrawer(),
          child: const events.CreateEventScreen(),
        );

      case core.AppRoutes.eventsSearch:
        return RouteUtils.createSimpleRoute(
          child: const events.EventSearchScreen(),
        );

      case core.AppRoutes.myEvents:
        return RouteUtils.createMainLayoutRoute(
          drawer: const events.EventsDrawer(),
          child: const events.UserEventsDashboardScreen(),
        );

      case core.AppRoutes.myTickets:
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        return RouteUtils.createSimpleRoute(
          child: events.MyTicketsScreen(userId: currentUserId),
        );

      case core.AppRoutes.eventsDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final eventId = args?['eventId'] as String?;
        if (eventId != null) {
          return RouteUtils.createMainLayoutRoute(
            drawer: const events.EventsDrawer(),
            child: events.EventDetailsScreen(eventId: eventId),
          );
        }
        return RouteUtils.createNotFoundRoute();

      case core.AppRoutes.eventsCalendar:
        return RouteUtils.createMainLayoutRoute(
          drawer: const events.EventsDrawer(),
          child: const events.CalendarScreen(),
        );

      default:
        return RouteUtils.createComingSoonRoute('Events');
    }
  }

  /// Handles ads-related routes
  Route<dynamic>? _handleAdsRoutes(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.adsCreate:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Create Local Ad'),
          child: const ads.CreateLocalAdScreen(),
        );

      case core.AppRoutes.adsManagement:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('My Ads'),
          child: const ads.MyAdsScreen(),
        );

      case core.AppRoutes.adsStatistics:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Browse Local Ads'),
          child: const ads.LocalAdsListScreen(),
        );

      case '/ads/my-ads':
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('My Ads'),
          child: const ads.MyAdsScreen(),
        );

      case '/ads/my-statistics':
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Browse Local Ads'),
          child: const ads.LocalAdsListScreen(),
        );

      case core.AppRoutes.adPayment:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Submit Local Ad'),
          child: const ads.CreateLocalAdScreen(),
        );

      default:
        return RouteUtils.createComingSoonRoute('Ads feature');
    }
  }

  /// Handles admin-related routes
  Route<dynamic>? _handleAdminRoutes(RouteSettings settings) {
    // First try to use the admin package's route generator
    final adminRoute = admin.AdminRoutes.generateRoute(settings);
    if (adminRoute != null) {
      return adminRoute;
    }

    // Fallback for admin routes not handled by the admin package
    switch (settings.name) {
      case core.AppRoutes.adminCoupons:
        return RouteUtils.createMainLayoutRoute(
          child: const core.CouponManagementScreen(),
        );

      case core.AppRoutes.adminCouponManagement:
      case core.AppRoutes.adminUsers:
      case core.AppRoutes.adminModeration:
      case core.AppRoutes.artworkModeration:
      case core.AppRoutes.adminAdManagement:
      case core.AppRoutes.adminAdReview:
      case core.AppRoutes.adminAdTest:
      case core.AppRoutes.adminMessaging:
      case '/admin/artwork':
      case '/admin/enhanced-dashboard':
      case '/admin/financial-analytics':
      case '/admin/content-management-suite':
      case '/admin/advanced-content-management':
      case '/admin/moderation/events':
      case '/admin/moderation/art-walks':
      case '/admin/moderation/content':
      case '/admin/moderation/artworks':
      case '/admin/moderation/community':
      case '/admin/upload-tools':
        // All admin routes now redirect to the modern unified dashboard
        return RouteUtils.createSimpleRoute(
          child: const admin.ModernUnifiedAdminDashboard(),
        );

      default:
        return RouteUtils.createComingSoonRoute('Admin feature');
    }
  }

  /// Handles settings-related routes
  Route<dynamic>? _handleSettingsRoutes(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.settings:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Settings', showDeveloperTools: true),
          child: const settings_pkg.SettingsScreen(),
        );

      case core.AppRoutes.settingsAccount:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Account Settings'),
          child: const settings_pkg.AccountSettingsScreen(
            useOwnScaffold: false,
          ),
        );

      case core.AppRoutes.settingsNotifications:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Notification Settings'),
          child: const settings_pkg.NotificationSettingsScreen(),
        );

      case core.AppRoutes.settingsPrivacy:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Privacy Settings'),
          child: const settings_pkg.PrivacySettingsScreen(),
        );

      case core.AppRoutes.securitySettings:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Security Settings'),
          child: const settings_pkg.SecuritySettingsScreen(
            useOwnScaffold: false,
          ),
        );

      case core.AppRoutes.settingsLanguage:
        return RouteUtils.createSimpleRoute(
          child: const settings_pkg.LanguageSettingsScreen(),
        );

      case core.AppRoutes.settingsTheme:
        return RouteUtils.createSimpleRoute(
          child: const settings_pkg.ThemeSettingsScreen(),
        );

      case core.AppRoutes.paymentSettings:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Payment Settings'),
          child: const artist.PaymentMethodsScreen(),
        );

      case '/settings/become-artist':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: core.AuthRequiredScreen(),
              );
            }

            final user = RouteUtils.createUserModelFromFirebase(currentUser);
            return core.MainLayout(
              currentIndex: -1,
              child: settings_pkg.BecomeArtistScreen(user: user),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      default:
        // Handle blocked users and other dynamic routes
        if (settings.name == '/settings/blocked-users') {
          return RouteUtils.createMainLayoutRoute(
            appBar: RouteUtils.createAppBar('Blocked Users'),
            child: const settings_pkg.BlockedUsersScreen(useOwnScaffold: false),
          );
        }

        final feature = settings.name!.split('/').last;
        return RouteUtils.createComingSoonRoute(
          '${feature[0].toUpperCase()}${feature.substring(1)} Settings',
        );
    }
  }

  /// Handles profile-related routes
  Route<dynamic>? _handleProfileRoutes(RouteSettings settings) =>
      _profileRouteHandler.handleRoute(settings);

  /// Handles capture-related routes
  Route<dynamic>? _handleCaptureRoutes(RouteSettings settings) =>
      _captureRouteHandler.handleRoute(
        settings,
        handleAdminRoute: _handleAdminRoutes,
      );

  /// Handles in-app purchase routes
  Route<dynamic>? _handleIapRoutes(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.subscriptions:
        return RouteUtils.createMainLayoutRoute(
          child: const core.SubscriptionPlansScreen(),
        );

      case core.AppRoutes.boosts:
        return RouteUtils.createMainLayoutRoute(
          child: const core.ArtistBoostsScreen(),
        );

      case core.AppRoutes.ads:
        return RouteUtils.createMainLayoutRoute(child: const AdsRouteScreen());

      default:
        return RouteUtils.createNotFoundRoute('In-App Purchase feature');
    }
  }

  /// Handles subscription-related routes
  Route<dynamic>? _handleSubscriptionRoutes(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.subscriptionComparison:
        return RouteUtils.createMainLayoutRoute(
          child: const core.SubscriptionPurchaseScreen(
            tier: core.SubscriptionTier.starter,
          ),
        );

      case core.AppRoutes.subscriptionPlans:
        return RouteUtils.createMainLayoutRoute(
          child: const core.SubscriptionPlansScreen(),
        );

      case core.AppRoutes.paymentMethods:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Payment Methods'),
          child: const artist.PaymentMethodsScreen(),
        );

      case core.AppRoutes.paymentScreen:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Payment Screen'),
          child: const artist.PaymentMethodsScreen(),
        );

      case core.AppRoutes.paymentRefund:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Refunds'),
          child: const Center(child: Text('Refund management coming soon')),
        );

      default:
        return RouteUtils.createNotFoundRoute('Subscription feature');
    }
  }

  /// Handles miscellaneous routes
  Route<dynamic>? _handleMiscRoutes(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.achievements:
        return RouteUtils.createMainLayoutRoute(
          child: const profile.AchievementsScreen(),
        );

      case core.AppRoutes.achievementsInfo:
        return RouteUtils.createMainLayoutRoute(
          child: const profile.AchievementInfoScreen(),
        );

      case core.AppRoutes.leaderboard:
        return RouteUtils.createMainLayoutRoute(
          child: const core.LeaderboardScreen(),
        );

      case core.AppRoutes.notifications:
        return RouteUtils.createMainLayoutRoute(
          child: const NotificationsScreen(useScaffold: false),
          drawer: const events.EventsDrawer(),
          currentIndex: 4,
        );

      case core.AppRoutes.search:
        return RouteUtils.createMainLayoutRoute(
          child: const core.SearchResultsPage(),
        );

      case core.AppRoutes.searchResults:
        final searchArgs = settings.arguments as Map<String, dynamic>?;
        final searchQuery = searchArgs?['query'] as String?;
        return RouteUtils.createMainLayoutRoute(
          child: core.SearchResultsPage(initialQuery: searchQuery),
        );

      case core.AppRoutes.feedback:
        return RouteUtils.createMainLayoutRoute(
          child: const core.FeedbackForm(),
        );

      case core.AppRoutes.developerFeedbackAdmin:
        return RouteUtils.createMainLayoutRoute(
          child: const admin.ModernUnifiedAdminDashboard(),
        );

      case core.AppRoutes.systemInfo:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('System Info - Coming Soon')),
        );

      case core.AppRoutes.support:
      case '/help':
        return RouteUtils.createMainLayoutRoute(
          child: const core.HelpSupportScreen(),
        );

      case '/favorites':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Center(child: Text('Favorites not available')),
              );
            }
            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar('Favorites'),
              child: profile.FavoritesScreen(userId: currentUser.uid),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/rewards':
        return RouteUtils.createMainLayoutRoute(child: const RewardsScreen());

      case '/billing':
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Billing & Payments'),
          child: const artist.PaymentMethodsScreen(),
        );

      case '/about':
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('About ARTbeat'),
          child: const AboutScreen(),
        );

      case '/privacy-policy':
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Privacy Policy'),
          child: const PrivacyPolicyScreen(),
        );

      case '/terms-of-service':
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Terms of Service'),
          child: const TermsOfServiceScreen(),
        );

      default:
        // Fallback to splash screen for unknown routes
        return RouteUtils.createMainLayoutRoute(
          child: const core.SplashScreen(),
        );
    }
  }
}

/// Widget that loads artist profile data and then shows the artist feed
class _ArtistFeedLoader extends StatefulWidget {
  const _ArtistFeedLoader({required this.artistUserId});
  final String artistUserId;

  @override
  State<_ArtistFeedLoader> createState() => _ArtistFeedLoaderState();
}

class _ArtistFeedLoaderState extends State<_ArtistFeedLoader> {
  core.ArtistProfileModel? _artistProfile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArtistProfile();
  }

  Future<void> _loadArtistProfile() async {
    try {
      setState(() => _isLoading = true);

      // Try to get artist profile from artistProfiles collection
      final artistDoc = await FirebaseFirestore.instance
          .collection('artistProfiles')
          .where('userId', isEqualTo: widget.artistUserId)
          .limit(1)
          .get();

      if (artistDoc.docs.isNotEmpty) {
        _artistProfile = core.ArtistProfileModel.fromFirestore(
          artistDoc.docs.first,
        );
      } else {
        // If no artist profile found, try to get basic user info
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.artistUserId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          _artistProfile = core.ArtistProfileModel(
            id: widget.artistUserId,
            userId: widget.artistUserId,
            displayName:
                (userData?['displayName'] as String?) ?? 'Unknown Artist',
            username: userData?['username'] as String? ?? '',
            bio: userData?['bio'] as String?,
            profileImageUrl: userData?['profileImageUrl'] as String?,
            location: userData?['location'] as String?,
            userType: core.UserType.artist,
            createdAt:
                (userData?['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            updatedAt:
                (userData?['updatedAt'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            mediums: [],
            styles: [],
          );
        } else {
          _error = 'Artist not found';
        }
      }
    } on Exception catch (e) {
      _error = 'Failed to load artist: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadArtistProfile,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_artistProfile == null) {
      return const Scaffold(body: Center(child: Text('Artist not found')));
    }

    return community.ArtistCommunityFeedScreen(artist: _artistProfile!);
  }
}

/// Temporary widget to handle user chat navigation
class _UserChatLoader extends StatefulWidget {
  const _UserChatLoader({required this.userId});
  final String userId;

  @override
  State<_UserChatLoader> createState() => _UserChatLoaderState();
}

class _UserChatLoaderState extends State<_UserChatLoader> {
  @override
  void initState() {
    super.initState();
    _navigateToChat();
  }

  Future<void> _navigateToChat() async {
    try {
      // Use the MessagingNavigationHelper to navigate to the chat
      await messaging.MessagingNavigationHelper.navigateToUserChat(
        context,
        widget.userId,
      );

      // Navigation is now using pushReplacementNamed, so we don't need to pop
      // The loader screen will be replaced by the chat screen
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
