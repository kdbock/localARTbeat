import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart' show ChallengeService;
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_core/artbeat_core.dart'
    hide ArtworkModel, GlassInputDecoration, WritingMetadata;
import 'package:artbeat_core/artbeat_core.dart' show WritingMetadata;
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';

/// Screen for viewing artwork details
class ArtworkDetailScreen extends StatefulWidget {
  final String artworkId;

  const ArtworkDetailScreen({super.key, required this.artworkId});

  @override
  State<ArtworkDetailScreen> createState() => _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends State<ArtworkDetailScreen> {
  final ArtworkService _artworkService = ArtworkService();
  final artist.SubscriptionService _subscriptionService =
      artist.SubscriptionService();
  final artist.VisibilityService _visibilityService =
      artist.VisibilityService();
  final AuctionService _auctionService = AuctionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  ArtworkModel? _artwork;
  ArtistProfileModel? _artist;
  String? _fallbackArtistName;
  String? _fallbackArtistImageUrl;

  // Auction state
  double? _currentHighestBid;
  List<AuctionBidModel> _bidHistory = [];

  @override
  void initState() {
    super.initState();
    _loadArtworkData();
  }

  Future<void> _loadArtworkData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get artwork details
      var artwork = await _artworkService.getArtworkById(widget.artworkId);

      // Track artwork view for analytics if artwork exists
      if (artwork != null) {
        _visibilityService.trackArtworkView(
          artworkId: widget.artworkId,
          artistId: artwork.userId,
        );
      }

      if (artwork == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('artwork_detail_not_found'.tr())),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Get artist profile
      final artistProfile = await _subscriptionService.getArtistProfileById(
        artwork.artistProfileId,
      );

      // If artist profile not found, try to get user information as fallback
      String? fallbackArtistName;
      String? fallbackArtistImageUrl;
      if (artistProfile == null) {
        try {
          final userService = UserService();
          final userData = await userService.getUserProfile(artwork.userId);
          fallbackArtistName =
              (userData?['fullName'] as String?) ??
              (userData?['displayName'] as String?) ??
              'Unknown Artist';
          fallbackArtistImageUrl = userData?['profileImageUrl'] as String?;
        } catch (e) {
          AppLogger.error('Error getting user profile for artist: $e');
          fallbackArtistName = 'Unknown Artist';
          fallbackArtistImageUrl = null;
        }
      }

      // Increment view count
      await _artworkService.incrementViewCount(widget.artworkId);

      // Refresh artwork to get updated view count
      final updatedArtwork = await _artworkService.getArtworkById(
        widget.artworkId,
      );
      if (updatedArtwork != null) {
        artwork = updatedArtwork;
      }

      // Check content type and route to appropriate detail screen
      if (artwork.contentType == ArtworkContentType.audio) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<dynamic>(
              builder: (context) =>
                  AudioContentDetailScreen(artworkId: widget.artworkId),
            ),
          );
        }
        return;
      }

      // Load auction data if this is an auction
      double? currentHighestBid;
      List<AuctionBidModel> bidHistory = [];
      if (artwork.auctionEnabled) {
        currentHighestBid = await _auctionService.getCurrentHighestBid(
          widget.artworkId,
        );
        bidHistory = await _auctionService.getBidHistory(widget.artworkId);
      }

      if (mounted) {
        setState(() {
          _artwork = artwork;
          _artist = artistProfile;
          _fallbackArtistName = fallbackArtistName;
          _fallbackArtistImageUrl = fallbackArtistImageUrl;
          _currentHighestBid = currentHighestBid;
          _bidHistory = bidHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'artwork_error_loading'.tr(namedArgs: {'error': e.toString()}),
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _shareArtwork() {
    if (_artwork == null) return;

    _showShareDialog();
  }

  Future<void> _showShareDialog() async {
    if (_artwork == null) return;

    final String artistName =
        _artist?.displayName ?? _fallbackArtistName ?? 'Artist';
    final String title = _artwork!.title;
    final String artworkUrl = 'https://artbeat.app/artwork/${_artwork!.id}';
    final String shareText =
        'Check out "$title" by $artistName on ARTbeat! 🎨\n\n$artworkUrl';

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'artwork_share_title'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"$title" by $artistName',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(
                    icon: Icons.message,
                    label: 'artwork_share_messages'.tr(),
                    onTap: () async {
                      Navigator.pop(context);
                      await SharePlus.instance.share(
                        ShareParams(
                          text: shareText,
                          subject: 'Amazing artwork on ARTbeat',
                        ),
                      );
                      await _trackShare('messages');
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.copy,
                    label: 'artwork_share_copy_link'.tr(),
                    onTap: () async {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('artwork_share_link_copied'.tr()),
                        ),
                      );
                      await _trackShare('copy_link');
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.share,
                    label: 'artwork_share_more'.tr(),
                    onTap: () async {
                      Navigator.pop(context);
                      await SharePlus.instance.share(
                        ShareParams(
                          text: shareText,
                          subject: 'Amazing artwork on ARTbeat',
                        ),
                      );
                      await _trackShare('system_share');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Social media options (placeholders for now)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(
                    icon: Icons.camera_alt,
                    label: 'artwork_share_stories'.tr(),
                    color: Colors.purple,
                    onTap: () async {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('artwork_share_stories_coming'.tr()),
                        ),
                      );
                      await _trackShare('stories');
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.facebook,
                    label: 'artwork_share_facebook'.tr(),
                    color: Colors.blue,
                    onTap: () async {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('artwork_share_facebook_coming'.tr()),
                        ),
                      );
                      await _trackShare('facebook');
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.photo_camera,
                    label: 'artwork_share_instagram'.tr(),
                    color: Colors.pink,
                    onTap: () async {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('artwork_share_instagram_coming'.tr()),
                        ),
                      );
                      await _trackShare('instagram');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('common_cancel'.tr()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (color ?? Theme.of(context).primaryColor).withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color ?? Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _trackShare(String platform) async {
    try {
      final engagementService = ContentEngagementService();
      await engagementService.toggleEngagement(
        contentId: _artwork!.id,
        contentType: 'artwork',
        engagementType: EngagementType.share,
        metadata: {
          'platform': platform,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Track share for challenge progress
      try {
        final challengeService = ChallengeService();
        await challengeService.recordSocialShare();
      } catch (e) {
        AppLogger.error('Error recording share to challenge: $e');
      }
    } catch (e) {
      AppLogger.error('Error tracking share: $e');
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

    final artwork = _artwork!;
    final artistProfile = _artist;

    return WorldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: HudTopBar(
          title: 'artwork_detail_title'.tr(),
          showBackButton: true,
          onBackPressed: () => Navigator.pop(context),
          actions: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _shareArtwork,
            ),
          ],
          subtitle: '',
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0A1330), Color(0xFF07060F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: SecureNetworkImage(
                        imageUrl: artwork.imageUrl,
                        fit: BoxFit.cover,
                        enableThumbnailFallback: true,
                        errorWidget: Container(
                          color: Colors.black12,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  radius: 26,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  artwork.title,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ArtworkModerationStatusChip(
                                  status: artwork.moderationStatus,
                                  showIcon: true,
                                ),
                                if (artwork.yearCreated != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '${artwork.yearCreated}',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (artwork.auctionEnabled)
                            _buildAuctionPriceDisplay(artwork)
                          else if (artwork.isForSale)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7C4DFF),
                                    Color(0xFF22D3EE),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                '\$${artwork.price?.toStringAsFixed(2) ?? 'For Sale'}',
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (artistProfile != null)
                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/artist/public-profile',
                              arguments: {'artistId': artistProfile.id},
                            );
                          },
                          child: Row(
                            children: [
                              UserAvatar(
                                imageUrl: artistProfile.profileImageUrl,
                                displayName: artistProfile.displayName,
                                radius: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      artistProfile.displayName,
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (artistProfile.location != null &&
                                        artistProfile.location!.isNotEmpty)
                                      Text(
                                        artistProfile.location!,
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        )
                      else if (_fallbackArtistName != null)
                        Row(
                          children: [
                            UserAvatar(
                              imageUrl: _fallbackArtistImageUrl,
                              displayName: _fallbackArtistName!,
                              radius: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _fallbackArtistName!,
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  radius: 26,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Details',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPropertyRow('Medium', artwork.medium),
                      if (artwork.dimensions != null)
                        _buildPropertyRow('Dimensions', artwork.dimensions!),
                      _buildPropertyRow('Style', artwork.styles.join(', ')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Writing metadata section for written content
                if (artwork.contentType == ArtworkContentType.written &&
                    artwork.writingMetadata != null)
                  GlassCard(
                    radius: 26,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📖 Written Work Details',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildWritingMetadataContent(artwork.writingMetadata!),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                GlassCard(
                  radius: 26,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        artwork.description,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                      if (artwork.tags?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: artwork.tags!
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.08,
                                  ),
                                  labelStyle: GoogleFonts.spaceGrotesk(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  radius: 26,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ContentEngagementBar(
                        contentId: artwork.id,
                        contentType: 'artwork',
                        initialStats: artwork.engagementStats,
                        showSecondaryActions: true,
                        artistId: artwork.userId,
                        artistName:
                            _artist?.displayName ??
                            _fallbackArtistName ??
                            'Unknown Artist',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.visibility,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${artwork.viewCount} views',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  radius: 26,
                  padding: const EdgeInsets.all(16),
                  child: ArtworkSocialWidget(
                    artworkId: artwork.id,
                    artworkTitle: artwork.title,
                    showComments: true,
                    showRatings: true,
                  ),
                ),
                const SizedBox(height: 16),
                if (artwork.auctionEnabled)
                  _buildAuctionActionButtons(artwork)
                else if (artwork.isForSale)
                  GradientCTAButton(
                    height: 52,
                    text: 'artwork_purchase_button'.tr(),
                    icon: Icons.shopping_cart,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/artwork/purchase',
                        arguments: {'artworkId': artwork.id},
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuctionActionButtons(ArtworkModel artwork) {
    final theme = Theme.of(context);
    final currentUser = _auth.currentUser;
    final isAuctionActive =
        artwork.auctionStatus == 'open' &&
        artwork.auctionEnd != null &&
        artwork.auctionEnd!.isAfter(DateTime.now());
    final isWinning =
        currentUser != null && artwork.currentHighestBidder == currentUser.uid;
    final canBid =
        currentUser != null &&
        currentUser.uid != artwork.userId &&
        isAuctionActive;

    return Column(
      children: [
        // Place Bid button
        if (canBid)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showPlaceBidModal,
              icon: const Icon(Icons.gavel),
              label: Text('auction.place_bid'.tr()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ),

        // Status messages
        if (!canBid) ...[
          if (currentUser == null)
            _buildStatusMessage('auction.login_to_bid'.tr(), Colors.orange)
          else if (currentUser.uid == artwork.userId)
            _buildStatusMessage('auction.cannot_bid_own'.tr(), Colors.grey)
          else if (!isAuctionActive)
            _buildStatusMessage('auction.auction_ended'.tr(), Colors.red),
        ] else if (isWinning)
          _buildStatusMessage('auction.you_are_winning'.tr(), Colors.green),

        const SizedBox(height: 16),

        // My Bids button
        if (currentUser != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<dynamic>(
                    builder: (context) => const MyBidsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.history),
              label: Text('auction.my_bids'.tr()),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

        // Bid history
        if (_bidHistory.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildBidHistory(),
        ],
      ],
    );
  }

  Widget _buildStatusMessage(String message, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBidHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'auction.bid_history'.tr(),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._bidHistory
            .take(5)
            .map(
              (bid) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${bid.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _formatBidTime(bid.timestamp),
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  String _formatBidTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showPlaceBidModal() {
    if (_artwork == null) return;

    final currentBid = _currentHighestBid ?? _artwork!.startingPrice ?? 0.0;
    final minimumBid = _auctionService.getMinimumNextBid(
      currentBid,
      _artwork!.startingPrice,
    );

    showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PlaceBidModal(
        artworkId: _artwork!.id,
        artwork: _artwork!,
        currentHighestBid: _currentHighestBid,
        minimumBid: minimumBid,
      ),
    ).then((success) {
      if (success == true) {
        // Refresh auction data
        _loadArtworkData();
      }
    });
  }

  Widget _buildAuctionPriceDisplay(ArtworkModel artwork) {
    final theme = Theme.of(context);
    final currentBid = _currentHighestBid ?? artwork.startingPrice ?? 0.0;
    final isAuctionActive =
        artwork.auctionStatus == 'open' &&
        artwork.auctionEnd != null &&
        artwork.auctionEnd!.isAfter(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auction badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isAuctionActive ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isAuctionActive ? 'auction.live'.tr() : 'auction.ended'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Current bid
          Text(
            'auction.current_bid'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          Text(
            '\$${currentBid.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),

          // Countdown timer
          if (isAuctionActive && artwork.auctionEnd != null) ...[
            const SizedBox(height: 8),
            _buildCountdownTimer(artwork.auctionEnd!),
          ],
        ],
      ),
    );
  }

  Widget _buildCountdownTimer(DateTime endTime) {
    return StreamBuilder(
      stream: Stream<int>.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final difference = endTime.difference(now);

        if (difference.isNegative) {
          return Text(
            'auction.ended'.tr(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          );
        }

        final days = difference.inDays;
        final hours = difference.inHours % 24;
        final minutes = difference.inMinutes % 60;
        final seconds = difference.inSeconds % 60;

        String timeString;
        if (days > 0) {
          timeString = '${days}d ${hours}h ${minutes}m';
        } else if (hours > 0) {
          timeString = '${hours}h ${minutes}m ${seconds}s';
        } else {
          timeString = '${minutes}m ${seconds}s';
        }

        return Row(
          children: [
            Icon(
              Icons.timer,
              size: 16,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              timeString,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWritingMetadataContent(WritingMetadata metadata) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Genre
        if (metadata.genre != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('📚', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Genre',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        metadata.genre!,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        // Word count
        if (metadata.wordCount != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('📄', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Word Count',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${metadata.wordCount!} words',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        // Reading time
        if (metadata.estimatedReadMinutes != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('⏱️', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Read Time',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${metadata.estimatedReadMinutes!} minutes',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        // Excerpt
        if (metadata.excerpt != null && metadata.excerpt!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Excerpt',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  metadata.excerpt!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
