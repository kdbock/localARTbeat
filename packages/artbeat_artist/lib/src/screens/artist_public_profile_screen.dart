import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart' hide SubscriptionService;
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_community/artbeat_community.dart'
    show DirectCommissionService, ArtistCommissionSettings;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/subscription_service.dart' as artist_subscription;
import '../services/analytics_service.dart';
import '../widgets/commission_badge_widget.dart';
import '../widgets/top_followers_widget.dart';
import '../widgets/artist_social_stats_widget.dart';
import '../widgets/design_system.dart';

/// Screen for viewing an artist's public profile
class ArtistPublicProfileScreen extends StatefulWidget {
  final String userId;

  const ArtistPublicProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ArtistPublicProfileScreen> createState() =>
      _ArtistPublicProfileScreenState();
}

class _ArtistPublicProfileScreenState extends State<ArtistPublicProfileScreen> {
  final artist_subscription.SubscriptionService _subscriptionService =
      artist_subscription.SubscriptionService();
  final artwork.ArtworkService _artworkService = artwork.ArtworkService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final DirectCommissionService _commissionService = DirectCommissionService();

  bool _isLoading = true;
  ArtistProfileModel? _artistProfile;
  List<artwork.ArtworkModel> _artwork = [];
  String? _currentUserId;
  String? _artistProfileId; // Store the artist profile document ID
  bool _isFollowing = false;
  ArtistCommissionSettings? _commissionSettings;

  @override
  void initState() {
    super.initState();
    _loadArtistProfile();
  }

  Future<void> _loadArtistProfile() async {
    // Loading artist profile
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID
      _currentUserId = _subscriptionService.getCurrentUserId();
      // Current user ID retrieved

      // Get artist profile by user ID
      final artistProfile =
          await _subscriptionService.getArtistProfileByUserId(widget.userId);

      // Artist profile query completed

      if (artistProfile == null) {
        // No artist profile found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(tr(
                    'artist_artist_public_profile_text_artist_profile_not'))),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Track profile view for analytics if profile exists
      _analyticsService.trackArtistProfileView(
        artistProfileId: artistProfile.id,
        artistId: artistProfile.userId,
      );

      // Get artist's artwork using the artist profile document ID
      // debugPrint(
      //     '🔍 ArtistPublicProfileScreen: About to query artwork with artistProfileId: ${artistProfile.id}');
      final artwork =
          await _artworkService.getArtworkByArtistProfileId(artistProfile.id);

      // debugPrint(
      //     '🖼️ ArtistPublicProfileScreen: Found ${artwork.length} artworks');

      // Check if current user is following this artist
      bool isFollowing = false;
      if (_currentUserId != null) {
        isFollowing = await _subscriptionService.isFollowingArtist(
          artistProfileId: artistProfile.id,
        );
        // debugPrint(
        //     '👥 ArtistPublicProfileScreen: Following status: $isFollowing');
      }

      // Load commission settings for this artist
      ArtistCommissionSettings? commissionSettings;
      try {
        commissionSettings =
            await _commissionService.getArtistCommissionSettings(widget.userId);
      } catch (e) {
        // Artist may not have commission settings - that's OK
      }

      if (mounted) {
        setState(() {
          _artistProfile = artistProfile;
          _artistProfileId = artistProfile.id; // Store the document ID
          _artwork = artwork;
          _isFollowing = isFollowing;
          _commissionSettings = commissionSettings;
          _isLoading = false;
        });
        // debugPrint(
        //     '✅ ArtistPublicProfileScreen: Successfully loaded profile UI');
      }
    } catch (e) {
      // debugPrint('❌ ArtistPublicProfileScreen: Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tr(
                  'artist_artist_public_profile_error_error_loading_artist'))),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_currentUserId == null) {
      // Prompt user to log in
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(tr('artist_artist_public_profile_text_please_log_in'))),
        );
      }
      return;
    }

    try {
      final result = await _subscriptionService.toggleFollowArtist(
        artistProfileId: _artistProfileId!,
      );

      if (mounted) {
        setState(() {
          _isFollowing = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tr('admin_unified_admin_dashboard_error_error_e'))),
        );
      }
    }
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(tr('artist_artist_public_profile_text_could_not_open'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const WorldBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final artist = _artistProfile!;
    final bool isPremium = artist.subscriptionTier != SubscriptionTier.free;
    final socialLinks = artist.socialLinks;

    return WorldBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // Top HUD Bar
          SliverToBoxAdapter(
            child: HudTopBar(
              title: 'artist_artist_public_profile_text_artist_profile'.tr(),
              onMenu: () => Navigator.pop(context),
            ),
          ),

          // Cover image section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  image: artist.coverImageUrl != null &&
                          artist.coverImageUrl!.isNotEmpty &&
                          Uri.tryParse(artist.coverImageUrl!)?.hasScheme == true
                      ? DecorationImage(
                          image: NetworkImage(artist.coverImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: Colors.grey[800],
                ),
                child: artist.coverImageUrl == null ||
                        artist.coverImageUrl!.isEmpty ||
                        Uri.tryParse(artist.coverImageUrl!)?.hasScheme != true
                    ? const Center(
                        child: Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.white54,
                        ),
                      )
                    : null,
              ),
            ),
          ),

          // Artist info card
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            sliver: SliverToBoxAdapter(
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile image and follow button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserAvatar(
                          imageUrl: artist.profileImageUrl,
                          displayName: artist.displayName,
                          radius: 40,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    artist.displayName,
                                    style: GoogleFonts.spaceGrotesk(
                                      color:
                                          Colors.white.withValues(alpha: 0.95),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (artist.isVerified)
                                    const Icon(Icons.verified,
                                        color: Color(0xFF22D3EE), size: 20),
                                ],
                              ),
                              if (artist.location != null &&
                                  artist.location!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 16, color: Colors.white70),
                                      const SizedBox(width: 4),
                                      Text(
                                        artist.location!,
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 12),
                              HudButton(
                                label: _isFollowing ? 'Following' : 'Follow',
                                onPressed: _toggleFollow,
                                height: 44,
                                radius: 22,
                              ),
                              const SizedBox(height: 12),
                              // Engagement buttons row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  EngagementButton(
                                    icon: Icons.card_giftcard,
                                    label: 'Gift',
                                    color: const Color(0xFFFFC857),
                                    onTap: () => _handleGiftAction(),
                                  ),
                                  EngagementButton(
                                    icon: Icons.message,
                                    label: 'Message',
                                    color: const Color(0xFF22D3EE),
                                    onTap: () => _handleMessageAction(),
                                  ),
                                  EngagementButton(
                                    icon: Icons.work,
                                    label: 'Commission',
                                    color: const Color(0xFF7C4DFF),
                                    onTap: () => _handleCommissionAction(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Commission Badge
                    if (_commissionSettings?.acceptingCommissions ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: CommissionBadge(
                          acceptingCommissions: true,
                          basePrice: _commissionSettings?.basePrice,
                          turnaroundDays:
                              _commissionSettings?.averageTurnaroundDays,
                        ),
                      ),

                    // Subscription badge
                    if (isPremium)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: GradientBadge(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                artist.userType == UserType.gallery
                                    ? 'Gallery Business'
                                    : artist.subscriptionTier ==
                                            SubscriptionTier.creator
                                        ? 'Creator Plan'
                                        : artist.subscriptionTier.displayName,
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Top Followers Section
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            sliver: SliverToBoxAdapter(
              child: GlassCard(
                child: TopFollowersWidget(
                  artistProfileId: _artistProfileId!,
                  artistUserId: widget.userId,
                ),
              ),
            ),
          ),

          // Social Stats Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: GlassCard(
                child: ArtistSocialStatsWidget(
                  artistProfileId: _artistProfileId!,
                  followerCount: artist.followersCount,
                ),
              ),
            ),
          ),

          // Divider
          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            sliver: SliverToBoxAdapter(
              child: Divider(
                color: Colors.grey[300],
              ),
            ),
          ),

          // Bio Section
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            sliver: SliverToBoxAdapter(
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bio
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        artist.bio ?? 'No bio provided',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ),

                    // Commission Info Card
                    if (_commissionSettings?.acceptingCommissions ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: CommissionInfoCard(
                          basePrice: _commissionSettings?.basePrice,
                          turnaroundDays:
                              _commissionSettings?.averageTurnaroundDays,
                          availableTypes: _commissionSettings?.availableTypes
                              .map((t) => t.displayName)
                              .toList(),
                        ),
                      ),

                    // Specialties
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: SectionHeader(
                        title: 'Specialties',
                        accentColor: Color(0xFF34D399),
                      ),
                    ),

                    // Mediums and styles
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...artist.mediums.map((medium) => Chip(
                                label: Text(
                                  medium,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.08),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              )),
                          ...artist.styles.map((style) => Chip(
                                label: Text(
                                  style,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                backgroundColor: const Color(0xFF22D3EE)
                                    .withValues(alpha: 0.15),
                                side: BorderSide(
                                  color: const Color(0xFF22D3EE)
                                      .withValues(alpha: 0.3),
                                ),
                              )),
                        ],
                      ),
                    ),

                    // Social media and website links
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: SectionHeader(
                        title: 'Connect',
                        accentColor: Color(0xFF7C4DFF),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if (socialLinks['website'] != null &&
                              socialLinks['website']!.isNotEmpty)
                            IconButton(
                              onPressed: () =>
                                  _launchUrl(socialLinks['website']),
                              icon: const Icon(Icons.language,
                                  color: Colors.white70),
                              tooltip: 'Website',
                            ),
                          if (socialLinks['instagram'] != null &&
                              socialLinks['instagram']!.isNotEmpty)
                            IconButton(
                              onPressed: () => _launchUrl(
                                  'https://instagram.com/${socialLinks['instagram']}'),
                              icon: const Icon(Icons.camera_alt,
                                  color: Colors.white70),
                              tooltip: 'Instagram',
                            ),
                          if (socialLinks['facebook'] != null &&
                              socialLinks['facebook']!.isNotEmpty)
                            IconButton(
                              onPressed: () =>
                                  _launchUrl(socialLinks['facebook']),
                              icon: const Icon(Icons.facebook,
                                  color: Colors.white70),
                              tooltip: 'Facebook',
                            ),
                          if (socialLinks['twitter'] != null &&
                              socialLinks['twitter']!.isNotEmpty)
                            IconButton(
                              onPressed: () => _launchUrl(
                                  'https://twitter.com/${socialLinks['twitter']}'),
                              icon: const Icon(Icons.email,
                                  color: Colors.white70),
                              tooltip: 'Twitter',
                            ),
                          if (socialLinks['etsy'] != null &&
                              socialLinks['etsy']!.isNotEmpty)
                            IconButton(
                              onPressed: () => _launchUrl(socialLinks['etsy']),
                              icon: const Icon(Icons.shopping_bag,
                                  color: Colors.white70),
                              tooltip: 'Etsy',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Artwork section title
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            sliver: SliverToBoxAdapter(
              child: GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionHeader(
                      title: 'Artwork',
                      accentColor: Color(0xFFFFC857),
                    ),
                    Text(
                      '${_artwork.length} pieces',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Artwork grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
            sliver: (_artwork.isEmpty
                ? SliverToBoxAdapter(
                    child: GlassCard(
                      child: Center(
                        child: Text(
                          'No artwork available',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  )
                : SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final artwork = _artwork[index];
                        return _buildArtworkItem(artwork);
                      },
                      childCount: _artwork.length,
                    ),
                  )),
          ),
        ],
      ),
    ));
  }

  Widget _buildArtworkItem(artwork.ArtworkModel artwork) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/artist/artwork-detail',
          arguments: {'artworkId': artwork.id},
        );
      },
      child: GlassCard(
        radius: 16,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork image
            Expanded(
              child: Stack(
                children: [
                  // Image
                  SizedBox(
                    width: double.infinity,
                    child: artwork.imageUrl.isNotEmpty &&
                            Uri.tryParse(artwork.imageUrl)?.hasScheme == true
                        ? SecureNetworkImage(
                            imageUrl: artwork.imageUrl,
                            fit: BoxFit.cover,
                            enableThumbnailFallback: true,
                            errorWidget: Container(
                              color: Colors.white.withValues(alpha: 0.05),
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.white30,
                                ),
                              ),
                            ),
                            placeholder: Container(
                              color: Colors.white.withValues(alpha: 0.05),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF22D3EE),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.white.withValues(alpha: 0.05),
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.white30,
                              ),
                            ),
                          ),
                  ),

                  // For sale badge
                  if (artwork.isForSale)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GradientBadge(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        radius: 12,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFC857), Color(0xFFFF3D8D)],
                        ),
                        child: Text(
                          '\$${artwork.price?.toStringAsFixed(2) ?? 'For Sale'}',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.black.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Artwork info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork.title,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artwork.medium,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleGiftAction() {
    if (_artistProfile == null) return;

    // Debug: Add logging to understand what's happening
    AppLogger.info(
        '🎁 Gift action triggered for artist: ${_artistProfile!.userId}');
    AppLogger.info('🎁 Artist name: ${_artistProfile!.displayName}');

    // Check if user is authenticated
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(tr('artist_artist_public_profile_text_please_log_in_8')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user is trying to gift themselves
    if (_currentUserId == _artistProfile!.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(tr('artist_artist_public_profile_text_you_cannot_send')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => GiftSelectionWidget(
        recipientId: _artistProfile!.userId,
        recipientName: _artistProfile!.displayName,
      ),
    );
  }

  void _handleMessageAction() {
    Navigator.pushNamed(
      context,
      '/messaging/user-chat',
      arguments: {
        'userId': _artistProfile!.userId,
        'recipientName': _artistProfile!.displayName,
      },
    );
  }

  void _handleCommissionAction() {
    Navigator.pushNamed(
      context,
      '/commission/request',
      arguments: {
        'artistId': _artistProfile!.userId,
        'artistName': _artistProfile!.displayName,
      },
    );
  }
}
