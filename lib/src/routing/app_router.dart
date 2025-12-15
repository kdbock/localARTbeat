import 'package:artbeat_admin/artbeat_admin.dart' as admin;
import 'package:artbeat_ads/artbeat_ads.dart' as ads;
import 'package:artbeat_art_walk/artbeat_art_walk.dart' as art_walk;
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_auth/artbeat_auth.dart' as auth;
import 'package:artbeat_capture/artbeat_capture.dart' as capture;
import 'package:artbeat_community/artbeat_community.dart' as community;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_events/artbeat_events.dart' as events;
import 'package:artbeat_messaging/artbeat_messaging.dart' as messaging;
import 'package:artbeat_profile/artbeat_profile.dart' as profile;
import 'package:artbeat_settings/artbeat_settings.dart' as settings_pkg;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../screens/in_app_purchase_demo_screen.dart';
import '../../screens/notifications_screen.dart';
import '../../test_payment_debug.dart';
import '../guards/auth_guard.dart';
import '../screens/about_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/rewards_screen.dart';
import '../screens/terms_of_service_screen.dart';
import 'app_routes.dart';
import 'route_utils.dart';

/// Main application router that handles all route generation
class AppRouter {
  final _authGuard = AuthGuard();

  /// Main route generation method
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;
    if (routeName == null) {
      return RouteUtils.createNotFoundRoute();
    }

    core.AppLogger.info('🛣️ Navigating to: $routeName');

    // Check if user is authenticated for protected routes
    if (!_authGuard.isAuthenticated && _isProtectedRoute(routeName)) {
      return RouteUtils.createSimpleRoute(child: const auth.LoginScreen());
    }

    // Core routes
    switch (routeName) {
      case '/store':
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Artbeat Store'),
          child: const core.ArtbeatStoreScreen(),
        );
      case AppRoutes.splash:
        return RouteUtils.createSimpleRoute(child: const core.SplashScreen());

      case AppRoutes.dashboard:
        return RouteUtils.createMainNavRoute(
          currentIndex: 0,
          child: const core.ArtbeatDashboardScreen(),
        );

      case '/debug/payment':
        return RouteUtils.createSimpleRoute(child: const PaymentDebugScreen());

      case AppRoutes.login:
        return RouteUtils.createSimpleRoute(child: const auth.LoginScreen());

      case AppRoutes.register:
        return RouteUtils.createSimpleRoute(child: const auth.RegisterScreen());

      case AppRoutes.forgotPassword:
        return RouteUtils.createSimpleRoute(
          child: const auth.ForgotPasswordScreen(),
        );

      // Profile route is handled in _handleProfileRoutes method

      case AppRoutes.profileEdit:
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        return RouteUtils.createMainNavRoute(
          child: profile.EditProfileScreen(userId: currentUserId),
        );

      case AppRoutes.artistDashboard:
        return RouteUtils.createMainNavRoute(
          child: const artist.ArtistDashboardScreen(),
        );

      case AppRoutes.artworkBrowse:
        return RouteUtils.createSimpleRoute(
          child: const artwork.ArtworkBrowseScreen(),
        );

      case AppRoutes.search:
        final args = settings.arguments as Map<String, dynamic>?;
        final query = args?['query'] as String?;

        // Extract query from route name if using query parameters
        String? initialQuery = query;
        if (initialQuery == null && routeName.contains('?')) {
          final uri = Uri.parse(routeName);
          initialQuery = uri.queryParameters['q'];
        }

        return RouteUtils.createMainNavRoute(
          child: core.SearchResultsPage(initialQuery: initialQuery),
        );

      case AppRoutes.searchResults:
        final args = settings.arguments as Map<String, dynamic>?;
        final query = args?['query'] as String?;

        return RouteUtils.createMainNavRoute(
          child: core.SearchResultsPage(initialQuery: query),
        );

      case AppRoutes.browse:
        return RouteUtils.createMainNavRoute(
          child: const core.FullBrowseScreen(),
        );

      case '/community/create-post':
        return RouteUtils.createMainNavRoute(
          child: const community.CreateGroupPostScreen(
            groupType: community.GroupType.artist,
            postType: 'artwork',
          ),
        );

      case '/events/create':
        return RouteUtils.createMainNavRoute(
          child: const events.CreateEventScreen(),
        );

      case AppRoutes.artistSearch:
      case AppRoutes.artistSearchShort:
        return RouteUtils.createMainNavRoute(
          child: const artist.ArtistBrowseScreen(),
        );

      case AppRoutes.trending:
        return RouteUtils.createMainNavRoute(
          child: const artist.ArtistBrowseScreen(), // Trending artists
        );

      case AppRoutes.local:
        return RouteUtils.createMainNavRoute(
          child: const events.EventsDashboardScreen(),
        );

      case AppRoutes.inAppPurchaseDemo:
        return RouteUtils.createMainNavRoute(
          child: const InAppPurchaseDemoScreen(),
        );
    }

    // Try specialized routes
    final specializedRoute = _handleSpecializedRoutes(settings);
    if (specializedRoute != null) {
      return specializedRoute;
    }

    // Route not found
    return RouteUtils.createNotFoundRoute();
  }

  bool _isProtectedRoute(String routeName) =>
      routeName != AppRoutes.splash &&
      routeName != AppRoutes.dashboard &&
      routeName != AppRoutes.login &&
      routeName != AppRoutes.register &&
      routeName != AppRoutes.forgotPassword &&
      routeName != AppRoutes.artistSearch &&
      routeName != AppRoutes.artistSearchShort &&
      routeName != AppRoutes.artistBrowse &&
      routeName != AppRoutes.artistFeatured &&
      routeName != AppRoutes.trending &&
      routeName != AppRoutes.local &&
      routeName != AppRoutes.artworkBrowse &&
      routeName != AppRoutes.artworkFeatured &&
      routeName != AppRoutes.artworkRecent &&
      routeName != AppRoutes.artworkTrending &&
      routeName != AppRoutes.artworkSearch &&
      routeName != AppRoutes.allEvents &&
      routeName != AppRoutes.search &&
      // Bottom navigation routes - allow anonymous browsing
      routeName != '/art-walk/map' &&
      routeName != '/art-walk/dashboard' &&
      routeName != '/capture/camera' &&
      routeName != '/community/hub' &&
      routeName != '/events/discover' &&
      !routeName.startsWith('/public/') &&
      !routeName.startsWith('/art-walk/') &&
      !routeName.startsWith('/community/');

  /// Handles specialized routes that aren't in core handler
  Route<dynamic>? _handleSpecializedRoutes(RouteSettings settings) {
    final routeName = settings.name!;

    // Artist routes
    if (routeName.startsWith('/artist')) {
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
        routeName.startsWith('/artwalk')) {
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
          child: const artist.Modern2025OnboardingScreen(),
        );
      case AppRoutes.artistDashboard:
        return RouteUtils.createMainNavRoute(
          child: const artist.ArtistDashboardScreen(),
        );

      case AppRoutes.artistOnboarding:
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

                final user = RouteUtils.createUserModelFromFirebase(
                  firebaseUser,
                );
                return artist.ArtistOnboardingScreen(
                  user: user,
                  onComplete: () => Navigator.of(context).pop(),
                );
              },
            ),
          ),
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case AppRoutes.artistProfileEdit:
        return RouteUtils.createMainLayoutRoute(
          child: const artist.ArtistProfileEditScreen(),
        );

      case AppRoutes.artistPublicProfile:
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

      case AppRoutes.artistAnalytics:
        return RouteUtils.createMainLayoutRoute(
          child: const artist.AnalyticsDashboardScreen(),
        );

      case AppRoutes.artistArtwork:
        return RouteUtils.createMainLayoutRoute(
          child: const artist.MyArtworkScreen(),
        );

      case AppRoutes.artistFeed:
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

      case AppRoutes.artistBrowse:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 3,
          child: const artist.ArtistBrowseScreen(),
        );

      case AppRoutes.artistEarnings:
        return RouteUtils.createMainLayoutRoute(
          child: const artist.ArtistEarningsDashboard(),
        );

      case AppRoutes.artistPayoutRequest:
        final args = settings.arguments as Map<String, dynamic>?;
        final availableBalance = args?['availableBalance'] as double? ?? 0.0;
        final onPayoutRequested = args?['onPayoutRequested'] as VoidCallback?;
        return RouteUtils.createMainLayoutRoute(
          child: artist.PayoutRequestScreen(
            availableBalance: availableBalance,
            onPayoutRequested: onPayoutRequested ?? () {},
          ),
        );

      case AppRoutes.artistPayoutAccounts:
        return RouteUtils.createMainLayoutRoute(
          child: const artist.PayoutAccountsScreen(),
        );

      case AppRoutes.artistFeatured:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 3,
          child: const artist.ArtistBrowseScreen(mode: 'featured'),
        );

      case AppRoutes.artistApprovedAds:
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
      case AppRoutes.artworkUpload:
      case AppRoutes.artworkUploadChoice:
        return RouteUtils.createMainLayoutRoute(
          child: const artwork.UploadChoiceScreen(),
        );

      case AppRoutes.artworkUploadVisual:
        return RouteUtils.createMainLayoutRoute(
          child: const artwork.EnhancedArtworkUploadScreen(),
        );

      case AppRoutes.artworkUploadWritten:
        return RouteUtils.createMainLayoutRoute(
          child: const artwork.WrittenContentUploadScreen(),
        );

      case AppRoutes.artworkBrowse:
        return RouteUtils.createSimpleRoute(
          child: const artwork.ArtworkBrowseScreen(),
        );

      case AppRoutes.artworkEdit:
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

      case AppRoutes.artworkDetail:
        final artworkId = RouteUtils.getArgument<String>(settings, 'artworkId');
        if (artworkId == null) {
          return RouteUtils.createErrorRoute('Artwork not found');
        }
        return RouteUtils.createSimpleRoute(
          child: artwork.ArtworkDetailScreen(artworkId: artworkId),
        );

      case AppRoutes.artworkFeatured:
        return RouteUtils.createSimpleRoute(
          child: const artwork.ArtworkFeaturedScreen(),
        );

      case AppRoutes.artworkRecent:
        return RouteUtils.createSimpleRoute(
          child: const artwork.ArtworkRecentScreen(),
        );

      case AppRoutes.artworkTrending:
        return RouteUtils.createSimpleRoute(
          child: const artwork.ArtworkTrendingScreen(),
        );

      case AppRoutes.artworkSearch:
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
      case AppRoutes.galleryArtistsManagement:
        return RouteUtils.createMainNavRoute(
          child: const artist.GalleryArtistsManagementScreen(),
        );

      case AppRoutes.galleryAnalytics:
        return RouteUtils.createMainLayoutRoute(
          child: const artist.GalleryAnalyticsDashboardScreen(),
        );

      default:
        return RouteUtils.createNotFoundRoute('Gallery feature');
    }
  }

  /// Handles community-related routes
  Route<dynamic>? _handleCommunityRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.communityDashboard:
        return RouteUtils.createMainNavRoute(
          currentIndex: 3,
          child: const community.ArtCommunityHub(),
        );

      case AppRoutes.communityFeed:
        // Use createMainNavRoute to ensure proper MainLayout wrapping
        return RouteUtils.createMainNavRoute(
          currentIndex: 3,
          child: const community.ArtCommunityHub(),
        );

      case AppRoutes.communityArtists:
        return RouteUtils.createMainLayoutRoute(
          child: const community.PortfoliosScreen(),
        );

      case AppRoutes.communitySearch:
        return RouteUtils.createMainLayoutRoute(
          child: const core.SearchResultsPage(),
        );

      case AppRoutes.communityPosts:
        return RouteUtils.createMainLayoutRoute(
          child: const community.ArtCommunityHub(),
        );

      case AppRoutes.communityStudios:
        return RouteUtils.createMainLayoutRoute(
          child: const community.StudiosScreen(),
        );

      case AppRoutes.communityGifts:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Gift Artists'),
          child: const community.ViewReceivedGiftsScreen(),
        );

      case AppRoutes.communityPortfolios:
        return RouteUtils.createMainLayoutRoute(
          child: const community.PortfoliosScreen(),
        );

      case AppRoutes.communityModeration:
        return RouteUtils.createMainLayoutRoute(
          child: const community.ModerationQueueScreen(),
        );

      case AppRoutes.communitySponsorships:
        // Sponsorship functionality removed - redirect to gifts
        return RouteUtils.createMainLayoutRoute(
          child: const community.ViewReceivedGiftsScreen(),
        );

      case AppRoutes.communitySettings:
        return RouteUtils.createMainLayoutRoute(
          child: const community.QuietModeScreen(),
        );

      case AppRoutes.communityCreate:
        return RouteUtils.createMainLayoutRoute(
          child: const community.CreatePostScreen(),
        );

      case AppRoutes.communityMessaging:
        return RouteUtils.createMainLayoutRoute(
          child: const community.StudiosScreen(),
        );

      case AppRoutes.communityTrending:
        return RouteUtils.createMainLayoutRoute(
          child: const community.TrendingContentScreen(),
        );

      case AppRoutes.communityFeatured:
        return RouteUtils.createMainLayoutRoute(
          child: const community.ArtCommunityHub(),
        );

      case AppRoutes.community:
        // Redirect to community dashboard
        return RouteUtils.createSimpleRoute(
          child: const community.ArtCommunityHub(),
        );

      case AppRoutes.artCommunityHub:
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
  Route<dynamic>? _handleArtWalkRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.artWalkDashboard:
        return RouteUtils.createSimpleRoute(
          child: const art_walk.ArtbeatArtwalkDashboardScreen(),
        );

      case AppRoutes.artWalkMap:
        return RouteUtils.createSimpleRoute(
          child: const art_walk.ArtWalkMapScreen(),
        );

      case AppRoutes.artWalkList:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const art_walk.ArtWalkListScreen(),
        );

      case AppRoutes.artWalkDetail:
        final walkId = RouteUtils.getArgument<String>(settings, 'walkId');
        if (walkId == null) {
          return RouteUtils.createErrorRoute('Art walk not found');
        }
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: art_walk.ArtWalkDetailScreen(walkId: walkId),
        );

      case AppRoutes.artWalkCreate:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const art_walk.EnhancedArtWalkCreateScreen(),
        );

      // Note: AppRoutes.enhancedArtWalkExperience is deprecated and now points to
      // the same path as AppRoutes.artWalkExperience (/art-walk/experience).
      // The route is handled by the art_walk module's route configuration.

      case AppRoutes.artWalkSearch:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(child: Text('Art Walk Search - Coming Soon')),
        );

      case AppRoutes.artWalkExplore:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(child: Text('Explore Art Walks - Coming Soon')),
        );

      case AppRoutes.artWalkStart:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(child: Text('Start Art Walk - Coming Soon')),
        );

      case AppRoutes.artWalkNearby:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(child: Text('Nearby Art Walks - Coming Soon')),
        );

      case AppRoutes.artWalkMyWalks:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const art_walk.EnhancedMyArtWalksScreen(),
        );

      case AppRoutes.artWalkMyCaptures:
        // Redirect to capture package for captures functionality
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const capture.MyCapturesScreen(),
        );

      case AppRoutes.artWalkCompleted:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(child: Text('Completed Art Walks - Coming Soon')),
        );

      case AppRoutes.artWalkSaved:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(child: Text('Saved Art Walks - Coming Soon')),
        );

      case AppRoutes.artWalkPopular:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(child: Text('Popular Art Walks - Coming Soon')),
        );

      case AppRoutes.artWalkAchievements:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(
            child: Text('Art Walk Achievements - Coming Soon'),
          ),
        );

      case AppRoutes.artWalkSettings:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const Center(child: Text('Art Walk Settings - Coming Soon')),
        );

      case AppRoutes.artWalkAdminModeration:
        core.AppLogger.info(
          '🔍 AppRouter: Handling artWalkAdminModeration route',
        );
        try {
          final route = RouteUtils.createMainLayoutRoute<dynamic>(
            child: const art_walk.AdminArtWalkModerationScreen(),
          );
          core.AppLogger.info('✅ AppRouter: Route created successfully');
          return route;
        } catch (e, stackTrace) {
          core.AppLogger.error('❌ AppRouter: Error creating route: $e');
          core.AppLogger.error('Stack trace: $stackTrace');
          rethrow;
        }

      case '/art-walk/review':
        final args = settings.arguments as Map<String, dynamic>?;
        final artWalkId = args?['artWalkId'] as String?;
        final artWalk = args?['artWalk'] as art_walk.ArtWalkModel?;

        if (artWalkId == null) {
          return RouteUtils.createErrorRoute('Art walk ID is required');
        }

        if (artWalk == null) {
          return RouteUtils.createErrorRoute('Art walk data is required');
        }

        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: art_walk.ArtWalkReviewScreen(
            artWalkId: artWalkId,
            artWalk: artWalk,
          ),
        );

      case '/art-walk/experience':
        final args = settings.arguments as Map<String, dynamic>?;
        final artWalkId = args?['artWalkId'] as String?;
        final artWalk = args?['artWalk'] as art_walk.ArtWalkModel?;

        if (artWalkId == null) {
          return RouteUtils.createErrorRoute('Art walk ID is required');
        }

        if (artWalk == null) {
          return RouteUtils.createErrorRoute('Art walk data is required');
        }

        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: art_walk.EnhancedArtWalkExperienceScreen(
            artWalkId: artWalkId,
            artWalk: artWalk,
          ),
        );

      case '/instant-discovery':
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const art_walk.InstantDiscoveryRadarScreen(),
        );

      case '/quest-history':
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const art_walk.QuestHistoryScreen(),
        );

      case '/weekly-goals':
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: const art_walk.WeeklyGoalsScreen(),
        );

      case '/art-walk/location':
        final args = settings.arguments as Map<String, dynamic>?;
        final locationName = args?['locationName'] as String?;
        final captures = args?['captures'] as List<capture.CaptureModel>?;

        if (locationName == null || captures == null) {
          return RouteUtils.createErrorRoute(
            'Location name and captures are required',
          );
        }

        // Show captures for the selected location
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 1,
          child: _LocationCapturesView(
            locationName: locationName,
            captures: captures,
          ),
        );

      default:
        return RouteUtils.createNotFoundRoute('Art Walk feature');
    }
  }

  /// Handles messaging-related routes
  Route<dynamic>? _handleMessagingRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.messaging:
        return RouteUtils.createMainLayoutRoute(
          child: const messaging.ArtisticMessagingScreen(),
        );

      case AppRoutes.messagingNew:
        return RouteUtils.createMainLayoutRoute(
          child: const messaging.ContactSelectionScreen(),
        );

      case AppRoutes.messagingChat:
        final args = settings.arguments as Map<String, dynamic>?;
        final chat = args?['chat'] as messaging.ChatModel?;
        if (chat != null) {
          return RouteUtils.createMainLayoutRoute(
            child: messaging.ChatScreen(chat: chat),
          );
        }
        return RouteUtils.createNotFoundRoute('Chat not found');

      case AppRoutes.messagingUserChat:
        final args = settings.arguments as Map<String, dynamic>?;
        final userId = args?['userId'] as String?;
        if (userId != null && userId.isNotEmpty) {
          // Create a temporary screen that will handle the chat creation
          return RouteUtils.createMainLayoutRoute(
            child: _UserChatLoader(userId: userId),
          );
        }
        return RouteUtils.createNotFoundRoute('User chat not found');

      case AppRoutes.messagingThread:
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
      case AppRoutes.events:
      case AppRoutes.eventsDiscover:
      case AppRoutes.eventsDashboard:
      case AppRoutes.eventsArtistDashboard:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 4,
          drawer: const events.EventsDrawer(),
          child: const events.EventsDashboardScreen(),
        );

      case AppRoutes.eventsCreate:
        return RouteUtils.createMainLayoutRoute(
          drawer: const events.EventsDrawer(),
          child: const events.CreateEventScreen(),
        );

      case AppRoutes.eventsSearch:
        return RouteUtils.createSimpleRoute(
          child: const events.EventSearchScreen(),
        );

      case AppRoutes.myEvents:
        return RouteUtils.createMainLayoutRoute(
          drawer: const events.EventsDrawer(),
          child: const events.UserEventsDashboardScreen(),
        );

      case AppRoutes.myTickets:
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        return RouteUtils.createSimpleRoute(
          child: events.MyTicketsScreen(userId: currentUserId),
        );

      case AppRoutes.eventsDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final eventId = args?['eventId'] as String?;
        if (eventId != null) {
          return RouteUtils.createMainLayoutRoute(
            drawer: const events.EventsDrawer(),
            child: events.EventDetailsScreen(eventId: eventId),
          );
        }
        return RouteUtils.createNotFoundRoute();

      default:
        return RouteUtils.createComingSoonRoute('Events');
    }
  }

  /// Handles ads-related routes
  Route<dynamic>? _handleAdsRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.adsCreate:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Create Ad'),
          child: const ads.CreateLocalAdScreen(),
        );

      case AppRoutes.adsManagement:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Manage Ads'),
          child: const ads.MyAdsScreen(),
        );

      case AppRoutes.adsStatistics:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Ad Statistics'),
          child: const ads.LocalAdsListScreen(),
        );

      case '/ads/my-ads':
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('My Ads'),
          child: const ads.MyAdsScreen(),
        );

      case '/ads/my-statistics':
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('My Ad Statistics'),
          child: const ads.LocalAdsListScreen(),
        );

      case AppRoutes.adPayment:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Ad Payment'),
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
      case AppRoutes.adminCoupons:
        return RouteUtils.createMainLayoutRoute(
          child: const core.CouponManagementScreen(),
        );

      case '/admin/artwork':
        return RouteUtils.createMainLayoutRoute(
          child: const admin.AdminArtworkManagementScreen(),
        );

      case AppRoutes.adminCouponManagement:
      case AppRoutes.adminUsers:
      case AppRoutes.adminModeration:
      case '/admin/enhanced-dashboard':
      case '/admin/financial-analytics':
      case '/admin/content-management-suite':
      case '/admin/advanced-content-management':
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
      case AppRoutes.settings:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Settings'),
          child: const settings_pkg.SettingsScreen(),
        );

      case AppRoutes.settingsAccount:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Account Settings'),
          child: const settings_pkg.AccountSettingsScreen(
            useOwnScaffold: false,
          ),
        );

      case AppRoutes.settingsNotifications:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Notification Settings'),
          child: const settings_pkg.NotificationSettingsScreen(),
        );

      case AppRoutes.settingsPrivacy:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Privacy Settings'),
          child: const settings_pkg.PrivacySettingsScreen(),
        );

      case AppRoutes.securitySettings:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Security Settings'),
          child: const settings_pkg.SecuritySettingsScreen(
            useOwnScaffold: false,
          ),
        );

      case AppRoutes.paymentSettings:
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
  Route<dynamic>? _handleProfileRoutes(RouteSettings settings) {
    switch (settings.name) {
      case '/profile':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Center(child: Text('Profile not available')),
              );
            }

            // Check if a specific userId was provided in arguments
            final args = settings.arguments as Map<String, dynamic>?;
            final targetUserId = args?['userId'] as String? ?? currentUser.uid;
            final isCurrentUser = targetUserId == currentUser.uid;

            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar(
                isCurrentUser ? 'Profile' : 'User Profile',
              ),
              child: profile.ProfileViewScreen(
                userId: targetUserId,
                isCurrentUser: isCurrentUser,
              ),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/edit':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Center(child: Text('Profile edit not available')),
              );
            }
            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar('Edit Profile'),
              child: profile.EditProfileScreen(
                userId: currentUser.uid,
                onProfileUpdated: () {
                  // Handle profile update if needed
                },
              ),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/picture':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final args = settings.arguments as Map<String, dynamic>?;
            final imageUrl = args?['imageUrl'] as String? ?? '';
            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar('Profile Picture'),
              child: profile.ProfilePictureViewerScreen(imageUrl: imageUrl),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/connections':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: profile.ProfileConnectionsScreen(),
          ),
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/activity':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () => const _ProfileActivityWrapper(),
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/analytics':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: profile.ProfileAnalyticsScreen(),
          ),
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/achievements':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: profile.AchievementsScreen(),
          ),
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/following':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Center(child: Text('Following not available')),
              );
            }
            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar('Following Artists'),
              child: profile.FollowedArtistsScreen(userId: currentUser.uid),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/followers':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Center(child: Text('Followers not available')),
              );
            }
            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar('Followers'),
              child: profile.FollowersListScreen(userId: currentUser.uid),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/liked':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Center(child: Text('Liked content not available')),
              );
            }
            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar('Liked Items'),
              child: profile.FavoritesScreen(userId: currentUser.uid),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/deep':
        // View another user's profile
        final args = settings.arguments as Map<String, dynamic>?;
        final userId = args?['userId'] as String?;
        if (userId == null) {
          return RouteUtils.createErrorRoute('No user ID provided');
        }
        return RouteUtils.createMainLayoutRoute(
          child: profile.ProfileViewScreen(userId: userId),
        );

      default:
        return RouteUtils.createComingSoonRoute('Profile feature');
    }
  }

  /// Handles capture-related routes
  Route<dynamic>? _handleCaptureRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.captures:
        return RouteUtils.createMainNavRoute(
          currentIndex: 2,
          child: const capture.EnhancedCaptureDashboardScreen(),
        );

      case AppRoutes.captureCamera:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.CaptureScreen(),
        );

      case AppRoutes.captureCameraSimple:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.CaptureScreen(),
        );

      case '/capture/smart':
        return RouteUtils.createMainNavRoute(
          currentIndex: 2,
          child: const capture.CaptureScreen(),
        );

      case AppRoutes.captureDashboard:
        return RouteUtils.createMainNavRoute(
          currentIndex: 2,
          child: const capture.EnhancedCaptureDashboardScreen(),
        );

      case AppRoutes.captureSearch:
        // Redirect to unified search
        return RouteUtils.createMainLayoutRoute(
          child: const core.SearchResultsPage(),
        );

      case AppRoutes.captureNearby:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.CapturesListScreen(),
        );

      case AppRoutes.capturePopular:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.CapturesListScreen(),
        );

      case AppRoutes.captureMyCaptures:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.MyCapturesScreen(),
        );

      case AppRoutes.capturePending:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.MyCapturesScreen(),
        );

      case AppRoutes.captureMap:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Capture Map - Coming Soon')),
        );

      case AppRoutes.captureBrowse:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.CapturesListScreen(),
        );

      case AppRoutes.captureApproved:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.MyCapturesScreen(),
        );

      case AppRoutes.captureSettings:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('Capture Settings - Coming Soon')),
        );

      case AppRoutes.captureAdminModeration:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.AdminContentModerationScreen(),
        );

      case AppRoutes.captureGallery:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.CapturesListScreen(),
        );

      case AppRoutes.captureCreate:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.CaptureScreen(),
        );

      case AppRoutes.capturePublic:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.CapturesListScreen(),
        );

      case AppRoutes.captureTerms:
        return RouteUtils.createMainLayoutRoute(
          child: const capture.TermsAndConditionsScreen(),
        );

      case AppRoutes.captureDetail:
        final captureId = RouteUtils.getArgument<String>(settings, 'captureId');
        if (captureId == null || captureId.isEmpty) {
          return RouteUtils.createErrorRoute('Capture ID is required');
        }
        return RouteUtils.createMainLayoutRoute(
          child: capture.CaptureDetailViewerScreen(captureId: captureId),
        );

      case AppRoutes.captureEdit:
        final captureModel = RouteUtils.getArgument<core.CaptureModel>(
          settings,
          'capture',
        );
        if (captureModel == null) {
          return RouteUtils.createErrorRoute('Capture data is required');
        }
        return RouteUtils.createMainLayoutRoute(
          child: capture.CaptureEditScreen(capture: captureModel),
        );

      default:
        return RouteUtils.createNotFoundRoute('Capture feature');
    }
  }

  /// Handles in-app purchase routes
  Route<dynamic>? _handleIapRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.subscriptions:
        return RouteUtils.createMainLayoutRoute(
          child: const core.SubscriptionsScreen(),
        );

      case AppRoutes.gifts:
        return RouteUtils.createMainLayoutRoute(
          child: const core.GiftsScreen(),
        );

      case AppRoutes.ads:
        return RouteUtils.createMainLayoutRoute(child: const core.AdsScreen());

      default:
        return RouteUtils.createNotFoundRoute('In-App Purchase feature');
    }
  }

  /// Handles subscription-related routes
  Route<dynamic>? _handleSubscriptionRoutes(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.subscriptionComparison:
        return RouteUtils.createMainLayoutRoute(
          child: const core.SubscriptionPurchaseScreen(
            tier: core.SubscriptionTier.starter,
          ),
        );

      case AppRoutes.subscriptionPlans:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Subscription Plans'),
          child: const core.SimpleSubscriptionPlansScreen(),
        );

      case AppRoutes.paymentMethods:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Payment Methods'),
          child: const artist.PaymentMethodsScreen(),
        );

      case AppRoutes.paymentScreen:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Payment Screen'),
          child: const artist.PaymentMethodsScreen(),
        );

      case AppRoutes.paymentRefund:
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
      case AppRoutes.achievements:
        return RouteUtils.createMainLayoutRoute(
          child: const profile.AchievementsScreen(),
        );

      case AppRoutes.achievementsInfo:
        return RouteUtils.createMainLayoutRoute(
          child: const profile.AchievementInfoScreen(),
        );

      case AppRoutes.leaderboard:
        return RouteUtils.createMainLayoutRoute(
          child: const core.LeaderboardScreen(),
        );

      case AppRoutes.notifications:
        return RouteUtils.createSimpleRoute(child: const NotificationsScreen());

      case AppRoutes.search:
        return RouteUtils.createMainLayoutRoute(
          child: const core.SearchResultsPage(),
        );

      case AppRoutes.searchResults:
        final searchArgs = settings.arguments as Map<String, dynamic>?;
        final searchQuery = searchArgs?['query'] as String?;
        return RouteUtils.createMainLayoutRoute(
          child: core.SearchResultsPage(initialQuery: searchQuery),
        );

      case AppRoutes.feedback:
        return RouteUtils.createMainLayoutRoute(
          child: const core.FeedbackForm(),
        );

      case AppRoutes.developerFeedbackAdmin:
        return RouteUtils.createMainLayoutRoute(
          child: const core.DeveloperFeedbackAdminScreen(),
        );

      case AppRoutes.systemInfo:
        return RouteUtils.createMainLayoutRoute(
          child: const Center(child: Text('System Info - Coming Soon')),
        );

      case AppRoutes.support:
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
          final userData = userDoc.data()!;
          _artistProfile = core.ArtistProfileModel(
            id: widget.artistUserId,
            userId: widget.artistUserId,
            displayName:
                (userData['displayName'] as String?) ?? 'Unknown Artist',
            bio: userData['bio'] as String?,
            profileImageUrl: userData['profileImageUrl'] as String?,
            location: userData['location'] as String?,
            userType: core.UserType.artist,
            createdAt:
                (userData['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            updatedAt:
                (userData['updatedAt'] as Timestamp?)?.toDate() ??
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

/// Wrapper for ProfileActivityScreen that provides proper AppBar integration
class _ProfileActivityWrapper extends StatefulWidget {
  const _ProfileActivityWrapper();

  @override
  State<_ProfileActivityWrapper> createState() =>
      _ProfileActivityWrapperState();
}

class _ProfileActivityWrapperState extends State<_ProfileActivityWrapper>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => core.MainLayout(
    currentIndex: -1,
    appBar: AppBar(
      title: const Text('Activity History'),
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Recent Activity', icon: Icon(Icons.timeline)),
          Tab(text: 'Unread', icon: Icon(Icons.notifications)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            // Refresh the ProfileActivityScreen by triggering a rebuild
            setState(() {});
          },
        ),
      ],
    ),
    child: _ProfileActivityContent(tabController: _tabController),
  );
}

/// Content widget for ProfileActivityScreen without Scaffold
class _ProfileActivityContent extends StatefulWidget {
  const _ProfileActivityContent({required this.tabController});
  final TabController tabController;

  @override
  State<_ProfileActivityContent> createState() =>
      _ProfileActivityContentState();
}

class _ProfileActivityContentState extends State<_ProfileActivityContent> {
  final profile.ProfileActivityService _activityService =
      profile.ProfileActivityService();
  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final user = core.UserService().currentUser;
    setState(() {
      _currentUserId = user?.uid;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return TabBarView(
      controller: widget.tabController,
      children: [_buildRecentActivityTab(), _buildUnreadTab()],
    );
  }

  Widget _buildRecentActivityTab() =>
      StreamBuilder<List<profile.ProfileActivityModel>>(
        stream: _activityService.streamProfileActivities(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(
              'Error loading activity',
              snapshot.error.toString(),
            );
          }

          final activities = snapshot.data ?? [];

          if (activities.isEmpty) {
            return _buildEmptyWidget(
              Icons.timeline_outlined,
              'No recent activity',
              'Your recent activity will appear here',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _buildActivityCard(activity);
            },
          );
        },
      );

  Widget _buildUnreadTab() => StreamBuilder<List<profile.ProfileActivityModel>>(
    stream: _activityService.streamProfileActivities(
      _currentUserId!,
      unreadOnly: true,
    ),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return _buildErrorWidget(
          'Error loading unread activities',
          snapshot.error.toString(),
        );
      }

      final unreadActivities = snapshot.data ?? [];

      if (unreadActivities.isEmpty) {
        return _buildEmptyWidget(
          Icons.check_circle_outline,
          'All caught up!',
          'You have no unread activities',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: unreadActivities.length,
        itemBuilder: (context, index) {
          final activity = unreadActivities[index];
          return _buildActivityCard(activity, isUnread: true);
        },
      );
    },
  );

  Widget _buildActivityCard(
    profile.ProfileActivityModel activity, {
    bool isUnread = false,
  }) {
    final title = _getActivityTitle(activity);
    final description =
        activity.description ?? _getActivityDescription(activity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isUnread ? Colors.blue.shade50 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: core.ImageUrlValidator.safeNetworkImage(
            activity.targetUserAvatar,
          ),
          backgroundColor: _getActivityColor(activity.activityType),
          child: activity.targetUserAvatar == null
              ? _getActivityIcon(activity.activityType)
              : null,
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(activity.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: isUnread
            ? const Icon(Icons.fiber_new, color: Colors.blue)
            : null,
        onTap: () => _handleActivityTap(activity),
      ),
    );
  }

  Widget _buildErrorWidget(String title, String error) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(title, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text(
          error,
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildEmptyWidget(IconData icon, String title, String subtitle) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  String _getActivityTitle(profile.ProfileActivityModel activity) {
    final userName = activity.targetUserName ?? 'Someone';
    switch (activity.activityType) {
      case 'profile_view':
        return '$userName viewed your profile';
      case 'follow':
        return '$userName started following you';
      case 'unfollow':
        return '$userName unfollowed you';
      case 'like':
        return '$userName liked your post';
      case 'comment':
        return '$userName commented on your post';
      default:
        return 'Activity: ${activity.activityType}';
    }
  }

  String _getActivityDescription(profile.ProfileActivityModel activity) {
    switch (activity.activityType) {
      case 'profile_view':
        return 'Check out who\'s interested in your profile!';
      case 'follow':
        return 'You gained a new follower!';
      case 'unfollow':
        return 'You lost a follower';
      case 'like':
        return 'Your content is getting appreciation!';
      case 'comment':
        return 'Someone engaged with your content!';
      default:
        return 'Activity occurred';
    }
  }

  Widget _getActivityIcon(String activityType) {
    switch (activityType) {
      case 'like':
        return const Icon(Icons.favorite, color: Colors.white, size: 20);
      case 'comment':
        return const Icon(Icons.chat_bubble, color: Colors.white, size: 20);
      case 'follow':
        return const Icon(Icons.person_add, color: Colors.white, size: 20);
      case 'unfollow':
        return const Icon(Icons.person_remove, color: Colors.white, size: 20);
      case 'profile_view':
        return const Icon(Icons.visibility, color: Colors.white, size: 20);
      default:
        return const Icon(Icons.timeline, color: Colors.white, size: 20);
    }
  }

  Color _getActivityColor(String activityType) {
    switch (activityType) {
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.blue;
      case 'follow':
        return Colors.green;
      case 'unfollow':
        return Colors.orange;
      case 'profile_view':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _handleActivityTap(profile.ProfileActivityModel activity) {
    // Show activity details or navigate based on type
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getActivityTitle(activity)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activity.description ?? _getActivityDescription(activity)),
            const SizedBox(height: 16),
            Text(
              'Time: ${_formatTimestamp(activity.createdAt)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (activity.metadata != null && activity.metadata!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...activity.metadata!.entries.map(
                (entry) => Text('${entry.key}: ${entry.value}'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!activity.isRead)
            TextButton(
              onPressed: () {
                _markAsRead([activity.id]);
                Navigator.pop(context);
              },
              child: const Text('Mark as read'),
            ),
        ],
      ),
    );
  }

  Future<void> _markAsRead(List<String> activityIds) async {
    try {
      await _activityService.markActivitiesAsRead(activityIds);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Widget to display captures for a specific location
class _LocationCapturesView extends StatelessWidget {
  const _LocationCapturesView({
    required this.locationName,
    required this.captures,
  });

  final String locationName;
  final List<capture.CaptureModel> captures;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(locationName), elevation: 0),
    body: captures.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, size: 64),
                SizedBox(height: 16),
              ],
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: captures.length,
            itemBuilder: (context, index) =>
                _buildCaptureCard(context, captures[index]),
          ),
  );

  Widget _buildCaptureCard(
    BuildContext context,
    capture.CaptureModel capture,
  ) => GestureDetector(
    onTap: () {
      Navigator.pushNamed(
        context,
        '/capture/detail',
        arguments: {'captureId': capture.id},
      );
    },
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          if (capture.imageUrl.isNotEmpty)
            Image.network(
              capture.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            )
          else
            Container(
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported),
            ),

          // Title overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: Text(
                capture.title ?? 'Untitled',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
