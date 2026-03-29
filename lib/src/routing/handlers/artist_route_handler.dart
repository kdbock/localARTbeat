import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_community/artbeat_community.dart' as community;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_core/auth_service.dart' as core_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../guards/auth_guard.dart';
import '../route_utils.dart';

class ArtistRouteHandler {
  const ArtistRouteHandler({
    required core_auth.AuthService authService,
    required Widget Function(String routeName) buildOnboardingScreen,
  }) : _authService = authService,
       _buildOnboardingScreen = buildOnboardingScreen;

  final core_auth.AuthService _authService;
  final Widget Function(String routeName) _buildOnboardingScreen;

  Route<dynamic>? handleRoute(RouteSettings settings) {
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
                final firebaseUser = _authService.currentUser;
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
        final currentUserId = _authService.currentUser?.uid;
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
}

class _ArtistFeedLoader extends StatefulWidget {
  const _ArtistFeedLoader({required this.artistUserId});
  final String artistUserId;

  @override
  State<_ArtistFeedLoader> createState() => _ArtistFeedLoaderState();
}

class _ArtistFeedLoaderState extends State<_ArtistFeedLoader> {
  final _artistProfileService = artist.ArtistProfileService();
  final _userService = core.UserService();
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

      final artistProfile = await _artistProfileService
          .getArtistProfileByUserId(widget.artistUserId);

      if (artistProfile != null) {
        _artistProfile = artistProfile;
      } else {
        final user = await _userService.getUserById(widget.artistUserId);

        if (user != null) {
          _artistProfile = core.ArtistProfileModel(
            id: widget.artistUserId,
            userId: widget.artistUserId,
            displayName: user.displayName,
            username: user.username,
            bio: user.bio,
            profileImageUrl: user.profileImageUrl,
            location: user.location,
            userType: core.UserType.artist,
            createdAt: user.createdAt,
            updatedAt: user.lastActive ?? user.createdAt,
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
