import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart'
    hide
        SubscriptionService,
        GlassCard,
        WorldBackground,
        HudTopBar,
        HudButton,
        GradientBadge;
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_community/artbeat_community.dart'
    show DirectCommissionService, ArtistCommissionSettings;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/subscription_service.dart' as artist_subscription;
import '../services/visibility_service.dart';
import '../widgets/top_followers_widget.dart';
import '../widgets/artist_social_stats_widget.dart';
import '../widgets/design_system.dart';

/// Screen for viewing an artist's public profile
class ArtistPublicProfileScreen extends StatefulWidget {
  final String userId;

  const ArtistPublicProfileScreen({super.key, required this.userId});

  @override
  State<ArtistPublicProfileScreen> createState() =>
      _ArtistPublicProfileScreenState();
}

class _ArtistPublicProfileScreenState extends State<ArtistPublicProfileScreen> {
  final artist_subscription.SubscriptionService _subscriptionService =
      artist_subscription.SubscriptionService();
  final artwork.ArtworkService _artworkService = artwork.ArtworkService();
  final VisibilityService _visibilityService = VisibilityService();
  final DirectCommissionService _commissionService = DirectCommissionService();

  bool _isLoading = true;
  ArtistProfileModel? _artistProfile;
  List<artwork.ArtworkModel> _artwork = [];
  String? _currentUserId;
  String? _artistProfileId; // Store the artist profile document ID
  bool _isFollowing = false;
  ArtistCommissionSettings? _commissionSettings;
  List<UserModel> _boosters = [];
  bool _isLoadingBoosters = false;
  DateTime? _earlyAccessUntil;
  String? _earlyAccessTier;

  @override
  void initState() {
    super.initState();
    _loadArtistProfile();
  }

  Future<void> _loadBoosters(String artistUserId) async {
    setState(() {
      _isLoadingBoosters = true;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('artist_boosters')
          .doc(artistUserId)
          .collection('boosters')
          .orderBy('lastBoostAt', descending: true)
          .limit(8)
          .get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _boosters = [];
            _isLoadingBoosters = false;
          });
        }
        return;
      }

      final boosterIds = snapshot.docs
          .map((doc) => doc.id)
          .where((id) => id.isNotEmpty)
          .toList();

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: boosterIds)
          .get();

      final boosters = usersSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      if (mounted) {
        setState(() {
          _boosters = boosters;
          _isLoadingBoosters = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _boosters = [];
          _isLoadingBoosters = false;
        });
      }
    }
  }

  Future<void> _loadBoosterStatus(String artistUserId) async {
    if (_currentUserId == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('artist_boosters')
          .doc(artistUserId)
          .collection('boosters')
          .doc(_currentUserId)
          .get();

      final data = doc.data();
      if (!doc.exists || data == null) return;

      if (mounted) {
        setState(() {
          _earlyAccessTier = data['earlyAccessTier'] as String?;
          _earlyAccessUntil = (data['earlyAccessUntil'] as Timestamp?)
              ?.toDate();
        });
      }
    } catch (_) {
      // Ignore booster status errors
    }
  }

  Future<void> _loadArtistProfile() async {
    // Loading artist profile
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID
      _currentUserId = _subscriptionService.getCurrentUserId();

      // Get artist profile by user ID
      final artistProfile = await _subscriptionService.getArtistProfileByUserId(
        widget.userId,
      );

      // Artist profile query completed

      if (artistProfile == null) {
        // No artist profile found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr('artist_artist_public_profile_text_artist_profile_not'),
              ),
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Track profile view for analytics if profile exists
      _visibilityService.trackArtistProfileView(
        artistProfileId: artistProfile.id,
        artistId: artistProfile.userId,
      );

      final artworkFuture =
          _artworkService.getArtworkByArtistProfileId(artistProfile.id);
      final followingFuture = _currentUserId != null
          ? _subscriptionService.isFollowingArtist(
              artistProfileId: artistProfile.id,
            )
          : Future.value(false);
      final commissionFuture = _commissionService
          .getArtistCommissionSettings(widget.userId)
          .catchError((_) => null);

      final results = await Future.wait([
        artworkFuture,
        followingFuture,
        commissionFuture,
      ]);

      final artworks = results[0] as List<artwork.ArtworkModel>;
      final isFollowing = results[1] as bool;
      final ArtistCommissionSettings? commissionSettings =
          results[2] as ArtistCommissionSettings?;

      if (mounted) {
        setState(() {
          _artistProfile = artistProfile;
          _artistProfileId = artistProfile.id; // Store the document ID
          _artwork = artworks;
          _isFollowing = isFollowing;
          if (commissionSettings != null) {
            _commissionSettings = commissionSettings;
          }
          _isLoading = false;
        });
      }

      _loadBoosters(artistProfile.userId);
      _loadBoosterStatus(artistProfile.userId);
    } catch (e) {
      // debugPrint('❌ ArtistPublicProfileScreen: Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('artist_artist_public_profile_error_error_loading_artist'),
            ),
          ),
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
            content: Text(
              tr('artist_artist_public_profile_text_please_log_in'),
            ),
          ),
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
            content: Text(tr('admin_unified_admin_dashboard_error_error_e')),
          ),
        );
      }
    }
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;

    final hasScheme = Uri.tryParse(url)?.hasScheme ?? false;
    final normalizedUrl = hasScheme ? url : 'https://$url';
    final uri = Uri.parse(normalizedUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('artist_artist_public_profile_text_could_not_open'),
            ),
          ),
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
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
            ),
          ),
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
            SliverToBoxAdapter(
              child: HudTopBar(
                title: 'artist_artist_public_profile_text_artist_profile'.tr(),
                subtitle: artist.displayName,
                onMenu: () => Navigator.pop(context),
                menuIcon: Icons.arrow_back,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              sliver: SliverToBoxAdapter(
                child: _buildHeroCard(artist, isPremium),
              ),
            ),
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              sliver: SliverToBoxAdapter(
                child: GlassCard(
                  child: ArtistSocialStatsWidget(
                    artistProfileId: _artistProfileId!,
                    followerCount: artist.followersCount,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              sliver: SliverToBoxAdapter(
                child: GlassCard(child: _buildBoosterTrailSection()),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              sliver: SliverToBoxAdapter(
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'artist_artist_public_profile_section_about'
                            .tr(),
                        accentColor: const Color(0xFF22D3EE),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        (artist.bio != null && artist.bio!.trim().isNotEmpty)
                            ? artist.bio!
                            : 'artist_artist_public_profile_text_no_bio'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                      if (_commissionSettings?.acceptingCommissions ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(
                                title:
                                    'artist_artist_public_profile_section_commissions'
                                        .tr(),
                                accentColor: const Color(0xFF7C4DFF),
                              ),
                              const SizedBox(height: 12),
                              _buildCommissionDetails(),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              sliver: SliverToBoxAdapter(
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title:
                            'artist_artist_public_profile_section_specialties'
                                .tr(),
                        accentColor: const Color(0xFF34D399),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...artist.mediums.map(
                            (medium) => Chip(
                              label: Text(
                                medium,
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.08,
                              ),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                          ),
                          ...artist.styles.map(
                            (style) => Chip(
                              label: Text(
                                style,
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              backgroundColor: const Color(
                                0xFF22D3EE,
                              ).withValues(alpha: 0.15),
                              side: BorderSide(
                                color: const Color(
                                  0xFF22D3EE,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SectionHeader(
                        title: 'artist_artist_public_profile_section_connect'
                            .tr(),
                        accentColor: const Color(0xFF7C4DFF),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (_hasLink(socialLinks['website']))
                            _buildSocialButton(
                              icon: Icons.language,
                              labelKey:
                                  'artist_artist_public_profile_tooltip_website',
                              color: const Color(0xFF22D3EE),
                              onTap: () => _launchUrl(socialLinks['website']),
                            ),
                          if (_hasLink(socialLinks['instagram']))
                            _buildSocialButton(
                              icon: Icons.camera_alt,
                              labelKey:
                                  'artist_artist_public_profile_tooltip_instagram',
                              color: const Color(0xFFFF3D8D),
                              onTap: () => _launchUrl(
                                'https://instagram.com/${socialLinks['instagram']}',
                              ),
                            ),
                          if (_hasLink(socialLinks['facebook']))
                            _buildSocialButton(
                              icon: Icons.facebook,
                              labelKey:
                                  'artist_artist_public_profile_tooltip_facebook',
                              color: const Color(0xFF3B5998),
                              onTap: () => _launchUrl(socialLinks['facebook']),
                            ),
                          if (_hasLink(socialLinks['twitter']))
                            _buildSocialButton(
                              icon: Icons.alternate_email,
                              labelKey:
                                  'artist_artist_public_profile_tooltip_twitter',
                              color: const Color(0xFF1DA1F2),
                              onTap: () => _launchUrl(
                                'https://twitter.com/${socialLinks['twitter']}',
                              ),
                            ),
                          if (_hasLink(socialLinks['etsy']))
                            _buildSocialButton(
                              icon: Icons.shopping_bag,
                              labelKey:
                                  'artist_artist_public_profile_tooltip_etsy',
                              color: const Color(0xFFFFC857),
                              onTap: () => _launchUrl(socialLinks['etsy']),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              sliver: SliverToBoxAdapter(
                child: GlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SectionHeader(
                        title: 'artist_artist_public_profile_section_artwork'
                            .tr(),
                        accentColor: const Color(0xFFFFC857),
                      ),
                      Text(
                        'artist_artist_public_profile_label_piece_count'.tr(
                          namedArgs: {'count': '${_artwork.length}'},
                        ),
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
              sliver: (_artwork.isEmpty
                  ? SliverToBoxAdapter(
                      child: GlassCard(
                        child: Center(
                          child: Text(
                            'artist_artist_public_profile_text_no_artwork_available'
                                .tr(),
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
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final artwork = _artwork[index];
                        return _buildArtworkItem(artwork);
                      }, childCount: _artwork.length),
                    )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoosterTrailSection() {
    final streakMonths = _artistProfile?.boostStreakMonths ?? 0;
    final hasStreak = streakMonths >= 2;
    final hasEarlyAccess =
        _earlyAccessUntil != null && _earlyAccessUntil!.isAfter(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'artist_artist_public_profile_section_boosters'.tr(),
          accentColor: const Color(0xFFF97316),
        ),
        if (hasStreak || hasEarlyAccess) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hasStreak)
                _buildStatusPill(
                  icon: Icons.bolt_rounded,
                  label: 'artist_boost_streak_label'.tr(
                    namedArgs: {'count': streakMonths.toString()},
                  ),
                ),
              if (hasEarlyAccess)
                _buildStatusPill(
                  icon: Icons.lock_open_rounded,
                  label: _earlyAccessTier != null
                      ? 'artist_early_access_label'.tr(
                          namedArgs: {'tier': _earlyAccessTier!},
                        )
                      : 'artist_early_access_label_generic'.tr(),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        if (_isLoadingBoosters)
          const Center(child: CircularProgressIndicator())
        else if (_boosters.isEmpty)
          Text(
            'artist_artist_public_profile_text_no_boosters'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _boosters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final booster = _boosters[index];
                return Tooltip(
                  message: booster.fullName.isNotEmpty
                      ? booster.fullName
                      : booster.username,
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: ImageUrlValidator.safeNetworkImage(
                      booster.profileImageUrl,
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    child:
                        !ImageUrlValidator.isValidImageUrl(
                          booster.profileImageUrl,
                        )
                        ? Text(
                            booster.fullName.isNotEmpty
                                ? booster.fullName[0].toUpperCase()
                                : (booster.username.isNotEmpty
                                      ? booster.username[0].toUpperCase()
                                      : '?'),
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHeroCard(ArtistProfileModel artist, bool isPremium) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCoverImage(artist),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(
                      imageUrl: artist.profileImageUrl,
                      displayName: artist.displayName,
                      radius: 40,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  artist.displayName,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                    letterSpacing: -0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (artist.isVerified)
                                const Icon(
                                  Icons.verified,
                                  color: Color(0xFF22D3EE),
                                  size: 20,
                                ),
                            ],
                          ),
                          if (artist.location != null &&
                              artist.location!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      artist.location!,
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (isPremium)
                                GradientBadge(
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
                                            ? 'artist_artist_public_profile_badge_premium_gallery'
                                                  .tr()
                                            : artist.subscriptionTier ==
                                                  SubscriptionTier.creator
                                            ? 'artist_artist_public_profile_badge_creator_plan'
                                                  .tr()
                                            : artist
                                                  .subscriptionTier
                                                  .displayName,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_commissionSettings?.acceptingCommissions ??
                                  false)
                                GradientBadge(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF34D399),
                                      Color(0xFF22D3EE),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.bolt,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          tr('art_walk_accepting_commissions'),
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPrimaryActions(),
                const SizedBox(height: 12),
                _buildSecondaryActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(ArtistProfileModel artist) {
    final hasCover =
        artist.coverImageUrl != null &&
        artist.coverImageUrl!.isNotEmpty &&
        Uri.tryParse(artist.coverImageUrl!)?.hasScheme == true;

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: hasCover
                ? SecureNetworkImage(
                    imageUrl: artist.coverImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      color: Colors.white.withValues(alpha: 0.04),
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
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF07060F),
                          Color(0xFF0A1330),
                          Color(0xFF071C18),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.image, size: 48, color: Colors.white38),
                    ),
                  ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActions() {
    return Row(
      children: [
        Expanded(
          child: HudButton(
            label: _isFollowing
                ? 'artist_artist_public_profile_button_following'.tr()
                : 'artist_artist_public_profile_button_follow'.tr(),
            onPressed: _toggleFollow,
            height: 50,
            radius: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassButton(
            label: 'artist_artist_public_profile_action_message'.tr(),
            icon: Icons.message_rounded,
            onPressed: _handleMessageAction,
            height: 50,
            radius: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryActions() {
    return Row(
      children: [
        Expanded(
          child: GlassButton(
            label: 'artist_artist_public_profile_action_gift'.tr(),
            icon: Icons.card_giftcard,
            onPressed: _handleGiftAction,
            accentColor: const Color(0xFFFFC857),
            height: 50,
            radius: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassButton(
            label: 'artist_artist_public_profile_action_commission'.tr(),
            icon: Icons.work_outline_rounded,
            onPressed: _handleCommissionAction,
            accentColor: const Color(0xFF7C4DFF),
            height: 50,
            radius: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildCommissionDetails() {
    final settings = _commissionSettings;
    if (settings == null) return const SizedBox.shrink();

    final availableTypes = settings.availableTypes
        .map((t) => t.displayName)
        .toList();
    final hasPrice = settings.basePrice > 0;
    final hasTurnaround = settings.averageTurnaroundDays > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF34D399), Color(0xFF22D3EE)],
                  ),
                ),
                child: const Icon(Icons.brush, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr('art_walk_commission_details'),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (hasPrice || hasTurnaround) const SizedBox(height: 10),
          if (hasPrice)
            _buildCommissionInfoRow(
              tr('art_walk_base_price'),
              'artist_artist_public_profile_label_commission_start'.tr(
                namedArgs: {
                  'price': '\$${settings.basePrice.toStringAsFixed(2)}',
                },
              ),
            ),
          if (hasTurnaround)
            _buildCommissionInfoRow(
              tr('art_walk_turnaround'),
              'artist_artist_public_profile_label_commission_timeline'.tr(
                namedArgs: {'days': '${settings.averageTurnaroundDays}'},
              ),
            ),
          if (availableTypes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'artist_artist_public_profile_label_available_commissions'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableTypes
                  .map(
                    (type) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        type,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommissionInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String labelKey,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: labelKey.tr(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                labelKey.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasLink(String? value) => value != null && value.trim().isNotEmpty;

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
                    child:
                        artwork.imageUrl.isNotEmpty &&
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
                          horizontal: 8,
                          vertical: 4,
                        ),
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
      '⚡ Boost action triggered for artist: ${_artistProfile!.userId}',
    );
    AppLogger.info('🎁 Artist name: ${_artistProfile!.displayName}');

    // Check if user is authenticated
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('artist_artist_public_profile_text_please_log_in_8'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user is trying to boost themselves
    if (_currentUserId == _artistProfile!.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('artist_artist_public_profile_text_you_cannot_send'),
          ),
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
      builder: (context) => ArtistBoostWidget(
        recipientId: _artistProfile!.userId,
        recipientName: _artistProfile!.displayName,
        onBoostCompleted: () {
          // Refresh artist profile to show updated momentum and supporter status
          _loadArtistProfile();
        },
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
