import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:artbeat_core/artbeat_core.dart' hide GradientBadge;
import 'package:artbeat_core/src/services/in_app_gift_service.dart';

import '../../models/direct_commission_model.dart';
import '../../models/group_models.dart';
import '../../services/direct_commission_service.dart';
import '../../widgets/widgets.dart';

import 'create_group_post_screen.dart';

/// Screen showing an individual artist's community feed

class ArtistCommunityFeedScreen extends StatefulWidget {
  final ArtistProfileModel artist;
  const ArtistCommunityFeedScreen({Key? key, required this.artist})
    : super(key: key);

  @override
  _ArtistCommunityFeedScreenState createState() =>
      _ArtistCommunityFeedScreenState();
}

class _ArtistCommunityFeedScreenState extends State<ArtistCommunityFeedScreen> {
  // State variables
  final List<ArtistGroupPost> _posts = [];
  final List<ArtistGroupPost> _filteredPosts = [];
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  final int _postsPerPage = 10;
  late ScrollController _scrollController;
  bool _isCurrentUserArtist = false;
  final InAppGiftService _giftService = InAppGiftService();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _checkIfCurrentUserArtist();
    _loadArtistPosts();

    // Mark community as visited when this screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CommunityProvider>().markCommunityAsVisited();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_isLoading) {
      _loadMorePosts();
    }
  }

  void _checkIfCurrentUserArtist() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid == widget.artist.userId) {
      _isCurrentUserArtist = true;
    }
  }

  Future<void> _loadArtistPosts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _posts.clear();
      _lastDocument = null;
    });
    try {
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('groupType', isEqualTo: 'artist')
          .where('userId', isEqualTo: widget.artist.userId)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(_postsPerPage)
          .get();

      if (!mounted) return;

      if (postsSnapshot.docs.isNotEmpty) {
        _lastDocument = postsSnapshot.docs.last;
        final loadedPosts = <ArtistGroupPost>[];
        for (final doc in postsSnapshot.docs) {
          try {
            final post = ArtistGroupPost.fromFirestore(doc);
            loadedPosts.add(post);
          } catch (e) {
            // debugPrint('Error parsing post ${doc.id}: $e');
          }
        }
        // Posts loaded successfully
        setState(() {
          _posts.addAll(loadedPosts);
          _filteredPosts.clear();
          _filteredPosts.addAll(loadedPosts);
          _isLoading = false;
        });
      } else {
        // debugPrint('No posts found for ${widget.artist.displayName}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // debugPrint('Error loading artist posts: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'artist_feed_load_error'.tr(
          namedArgs: {'error': e.toString()},
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || _lastDocument == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('groupType', isEqualTo: 'artist')
          .where('userId', isEqualTo: widget.artist.userId)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_postsPerPage)
          .get();

      if (!mounted) return;

      if (postsSnapshot.docs.isNotEmpty) {
        _lastDocument = postsSnapshot.docs.last;

        final morePosts = <ArtistGroupPost>[];
        for (final doc in postsSnapshot.docs) {
          try {
            final post = ArtistGroupPost.fromFirestore(doc);
            morePosts.add(post);
          } catch (e) {
            // debugPrint('Error parsing post ${doc.id}: $e');
          }
        }

        if (mounted) {
          setState(() {
            _posts.addAll(morePosts);
            _filteredPosts.addAll(morePosts);
          });
        }
      }
    } catch (e) {
      // debugPrint('Error loading more posts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'artist_feed_load_more_error'.tr(namedArgs: {'error': '$e'}),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _handleAppreciate(ArtistGroupPost post) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(post.id);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) return;

        final currentCount = postDoc.data()?['applauseCount'] ?? 0;
        transaction.update(postRef, {'applauseCount': currentCount + 1});

        // Track user appreciation to prevent duplicate appreciations
        final userAppreciationRef = FirebaseFirestore.instance
            .collection('user_appreciations')
            .doc('${user.uid}_${post.id}');

        transaction.set(userAppreciationRef, {
          'userId': user.uid,
          'postId': post.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('artist_feed_appreciate_success'.tr()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'artist_feed_appreciate_error'.tr(namedArgs: {'error': '$e'}),
            ),
          ),
        );
      }
    }
  }

  void _handleComment(BaseGroupPost post) {
    // Show post detail modal instead of full screen
    PostDetailModal.show(context, post);
  }

  void _handleFeature(BaseGroupPost post) async {
    try {
      // Mark post as featured in Firestore
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(post.id);

      // First check if the document exists
      final postDoc = await postRef.get();
      if (!postDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('artist_feed_feature_missing'.tr()),
            ),
          );
        }
        return;
      }

      // Update the post to mark it as featured
      await postRef.update({'isFeatured': true});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('artist_feed_feature_success'.tr()),
          ),
        );
      }
    } catch (e) {
      // debugPrint('Error featuring post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'artist_feed_feature_error'.tr(namedArgs: {'error': '$e'}),
            ),
          ),
        );
      }
    }
  }

  void _handleGift(BaseGroupPost post) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => GiftSelectionWidget(
        recipientId: post.userId,
        recipientName: post.userName,
      ),
    );
  }

  void _handleSponsor(BaseGroupPost post) {
    // Redirect to gift system (sponsorship removed for simplicity)
    _handleGift(post);
  }

  void _handleCommission(BaseGroupPost post) {
    // Navigate to commission request screen for the artist
    Navigator.pushNamed(
      context,
      '/commission/request',
      arguments: {'artistId': post.userId, 'artistName': post.userName},
    );
  }

  void _handleShare(BaseGroupPost post) async {
    try {
      final shareText = 'artist_feed_share_text'.tr(
        namedArgs: {
          'content': post.content,
          'artist': post.userName,
        },
      );
      await SharePlus.instance.share(ShareParams(text: shareText));

      // Update share count in Firestore
      await _updateShareCount(post.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'artist_feed_share_error'.tr(namedArgs: {'error': '$e'}),
            ),
          ),
        );
      }
    }
  }

  /// Update share count in Firestore
  Future<void> _updateShareCount(String postId) async {
    try {
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(postId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) return;

        final currentCount = postDoc.data()?['shareCount'] ?? 0;
        transaction.update(postRef, {'shareCount': currentCount + 1});
      });
    } catch (e) {
      // debugPrint('Failed to update share count: $e');
    }
  }

  void _handleDirectMessage() {
    // Navigate to direct messaging with this artist
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid != widget.artist.userId) {
      // Create or navigate to chat with this artist
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'recipientId': widget.artist.userId,
          'recipientName': widget.artist.displayName,
          'recipientAvatar': widget.artist.profileImageUrl,
        },
      );
    }
  }

  void _handleArtistLike() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'artist_feed_like_toast'.tr(namedArgs: {'name': widget.artist.displayName}),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleArtistFollow() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'artist_feed_follow_toast'.tr(namedArgs: {'name': widget.artist.displayName}),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleArtistGift() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('artist_feed_gift_processing'.tr()),
        duration: const Duration(seconds: 1),
      ),
    );

    final success = await _giftService.purchaseQuickGift(widget.artist.userId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('artist_feed_gift_success'.tr()),
          backgroundColor: const Color(0xFF34D399),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('artist_feed_gift_error'.tr()),
          backgroundColor: const Color(0xFFFF3D8D),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleArtistSponsor() {
    showDialog<void>(
      context: context,
      builder: (context) {
        final tiers = [
          'artist_feed_sponsor_tier_bronze'.tr(),
          'artist_feed_sponsor_tier_silver'.tr(),
          'artist_feed_sponsor_tier_gold'.tr(),
        ];

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: GlassPanel(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.volunteer_activism, color: Color(0xFF34D399)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'artist_feed_sponsor_title'.tr(
                          namedArgs: {'name': widget.artist.displayName},
                        ),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'artist_feed_sponsor_intro'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'artist_feed_sponsor_choose_tier'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.65),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 12),
                ...tiers.map(
                  (tier) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        tier,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: HudButton(
                        isPrimary: false,
                        text: 'common_cancel'.tr(),
                        onPressed: () => Navigator.pop(context),
                        height: 48,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientCTAButton(
                        text: 'artist_feed_sponsor_cta'.tr(),
                        icon: Icons.volunteer_activism,
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'artist_feed_sponsor_thanks'.tr(
                                  namedArgs: {'name': widget.artist.displayName},
                                ),
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        height: 48,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleCommissionRequest() {
    // Show commission request dialog with form
    showDialog<void>(
      context: context,
      builder: (context) => _CommissionRequestDialog(artist: widget.artist),
    );
  }

  Widget _buildArtistHeader() {
    final headlineStyle = GoogleFonts.spaceGrotesk(
      fontSize: 20,
      fontWeight: FontWeight.w900,
      color: Colors.white,
    );
    final bodyStyle = GoogleFonts.spaceGrotesk(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.white.withValues(alpha: 0.75),
    );

    return GlassCard(
      showAccentGlow: true,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: ImageUrlValidator.safeNetworkImage(
                  widget.artist.profileImageUrl,
                ),
                child: !ImageUrlValidator.isValidImageUrl(
                  widget.artist.profileImageUrl,
                )
                    ? const Icon(Icons.person, size: 36, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.artist.displayName,
                            style: headlineStyle,
                          ),
                        ),
                        if (widget.artist.isVerified)
                          GradientBadge(
                            text: 'artist_feed_verified_badge'.tr(),
                            icon: Icons.verified,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                          ),
                      ],
                    ),
                    if (widget.artist.location?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.artist.location!,
                              style: bodyStyle,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (widget.artist.bio?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.artist.bio!,
                        style: bodyStyle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (widget.artist.mediums.isNotEmpty ||
              widget.artist.styles.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...widget.artist.mediums
                    .map((medium) => _buildTag(medium, const Color(0xFF7C4DFF))),
                ...widget.artist.styles
                    .map((style) => _buildTag(style, const Color(0xFFFFC857))),
              ],
            ),
          ],
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPrimaryAction(
                  icon: Icons.favorite,
                  label: 'artist_feed_action_like'.tr(),
                  onPressed: _handleArtistLike,
                ),
                if (!_isCurrentUserArtist)
                  _buildPrimaryAction(
                    icon: Icons.person_add,
                    label: 'artist_feed_action_follow'.tr(),
                    onPressed: _handleArtistFollow,
                  ),
                _buildPrimaryAction(
                  icon: Icons.card_giftcard,
                  label: 'artist_feed_action_gift'.tr(),
                  onPressed: _handleArtistGift,
                ),
                _buildPrimaryAction(
                  icon: Icons.volunteer_activism,
                  label: 'artist_feed_action_sponsor'.tr(),
                  onPressed: _handleArtistSponsor,
                  isPrimary: true,
                ),
                if (!_isCurrentUserArtist)
                  _buildPrimaryAction(
                    icon: Icons.message,
                    label: 'artist_feed_action_message'.tr(),
                    onPressed: _handleDirectMessage,
                  ),
                _buildPrimaryAction(
                  icon: Icons.palette,
                  label: 'artist_feed_action_commission'.tr(),
                  onPressed: _handleCommissionRequest,
                  isPrimary: true,
                ),
              ],
            ),
          ),
          if (_isCurrentUserArtist) ...[
            const SizedBox(height: 24),
            GradientCTAButton(
              text: 'artist_feed_create_post_cta'.tr(),
              icon: Icons.add,
              onPressed: _showCreatePostOptions,
              height: 52,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPrimaryAction({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: HudButton(
        isPrimary: isPrimary,
        icon: icon,
        text: label,
        onPressed: onPressed,
        height: 48,
        width: 160,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'artist_feed_loading_label'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'artist_feed_error_generic'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            HudButton(
              isPrimary: true,
              text: 'artist_feed_error_retry'.tr(),
              onPressed: _loadArtistPosts,
              height: 48,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final title = 'artist_feed_empty_title'.tr(
      namedArgs: {'name': widget.artist.displayName},
    );
    final subtitle = _isCurrentUserArtist
        ? 'artist_feed_empty_artist_prompt'.tr()
        : 'artist_feed_empty_viewer_prompt'.tr();

    return Center(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.75),
              ),
              textAlign: TextAlign.center,
            ),
            if (_isCurrentUserArtist) ...[
              const SizedBox(height: 24),
              GradientCTAButton(
                text: 'artist_feed_create_post_cta'.tr(),
                icon: Icons.add,
                onPressed: _showCreatePostOptions,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreatePostOptions() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: GlassPanel(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.palette, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'artist_feed_create_sheet_title'.tr(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'artist_feed_create_sheet_subtitle'.tr(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildCreateOption(
                        icon: Icons.photo_camera,
                        title: 'artist_feed_create_option_artwork_title'.tr(),
                        subtitle:
                            'artist_feed_create_option_artwork_subtitle'.tr(),
                        color: const Color(0xFF7C4DFF),
                        postType: 'artwork',
                      ),
                      _buildCreateOption(
                        icon: Icons.video_camera_back,
                        title: 'artist_feed_create_option_process_title'.tr(),
                        subtitle:
                            'artist_feed_create_option_process_subtitle'.tr(),
                        color: const Color(0xFF22D3EE),
                        postType: 'process',
                      ),
                      _buildCreateOption(
                        icon: Icons.text_fields,
                        title: 'artist_feed_create_option_update_title'.tr(),
                        subtitle:
                            'artist_feed_create_option_update_subtitle'.tr(),
                        color: const Color(0xFFFFC857),
                        postType: 'update',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String postType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute<bool>(
                builder: (context) => CreateGroupPostScreen(
                  groupType: GroupType.artist,
                  postType: postType,
                ),
              ),
            );
            if (result == true) {
              _loadArtistPosts();
            }
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    final TextEditingController searchController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: GlassPanel(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.search, color: Colors.white.withValues(alpha: 0.8)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'artist_feed_search_title'.tr(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      decoration: GlassInputDecoration(
                        hintText: 'artist_feed_search_hint'.tr(),
                        prefixIcon: const Icon(Icons.search, color: Colors.white),
                      ),
                      onChanged: (value) {
                        setModalState(() {});
                        _filterPosts(value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'artist_feed_search_scope'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: HudButton(
                            isPrimary: false,
                            text: 'common_close'.tr(),
                            onPressed: () {
                              searchController.dispose();
                              Navigator.of(context).pop();
                            },
                            height: 48,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) => searchController.dispose());
  }

  void _filterPosts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPosts.clear();
        _filteredPosts.addAll(_posts);
      } else {
        final searchQuery = query.toLowerCase();
        _filteredPosts.clear();
        _filteredPosts.addAll(
          _posts.where((post) {
            final content = post.content.toLowerCase();
            final userName = post.userName.toLowerCase();
            final location = post.location.toLowerCase();
            final artworkTitle = post.artworkTitle.toLowerCase();
            final artworkDescription = post.artworkDescription.toLowerCase();
            final medium = post.medium.toLowerCase();
            final style = post.style.toLowerCase();
            final tags = post.tags.map((tag) => tag.toLowerCase()).join(' ');

            return content.contains(searchQuery) ||
                userName.contains(searchQuery) ||
                location.contains(searchQuery) ||
                artworkTitle.contains(searchQuery) ||
                artworkDescription.contains(searchQuery) ||
                medium.contains(searchQuery) ||
                style.contains(searchQuery) ||
                tags.contains(searchQuery);
          }).toList(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      appBar: HudTopBar(
        title: 'artist_feed_title'.tr(
          namedArgs: {'name': widget.artist.displayName},
        ),
        glassBackground: true,
        actions: [
          IconButton(
            tooltip: 'artist_feed_search_tooltip'.tr(),
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            tooltip: 'artist_feed_messages_tooltip'.tr(),
            icon: const Icon(Icons.message, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/messaging'),
          ),
        ],
      ),
      body: WorldBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: _buildArtistHeader(),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildFeedContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    if (_hasError) {
      return _buildErrorState();
    }
    if (_filteredPosts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: const Color(0xFF7C4DFF),
      onRefresh: _loadArtistPosts,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        itemCount: _filteredPosts.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredPosts.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF22D3EE),
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            );
          }

          final post = _filteredPosts[index];
          final showEngagement = !_isCurrentUserArtist ||
              post.userId != FirebaseAuth.instance.currentUser?.uid;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GlassCard(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  GroupPostCard(
                    post: post,
                    groupType: GroupType.artist,
                    onAppreciate: () => _handleAppreciate(post),
                    onComment: () => _handleComment(post),
                    onFeature: () => _handleFeature(post),
                    onGift: () => _handleGift(post),
                    onShare: () => _handleShare(post),
                  ),
                  if (showEngagement)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildInlineEngagementRow(post),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInlineEngagementRow(ArtistGroupPost post) {
    return Row(
      children: [
        Expanded(
          child: HudButton(
            isPrimary: false,
            icon: Icons.volunteer_activism,
            text: 'artist_feed_action_sponsor'.tr(),
            onPressed: () => _handleSponsor(post),
            height: 48,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: HudButton(
            isPrimary: true,
            icon: Icons.work_outline,
            text: 'artist_feed_action_commission'.tr(),
            onPressed: () => _handleCommission(post),
            height: 48,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: HudButton(
            isPrimary: false,
            icon: Icons.message_outlined,
            text: 'artist_feed_action_message'.tr(),
            onPressed: _handleDirectMessage,
            height: 48,
          ),
        ),
      ],
    );
  }
}

/// Commission request dialog with form and image upload
class _CommissionRequestDialog extends StatefulWidget {
  final ArtistProfileModel artist;

  const _CommissionRequestDialog({required this.artist});

  @override
  _CommissionRequestDialogState createState() =>
      _CommissionRequestDialogState();
}

class _CommissionRequestDialogState extends State<_CommissionRequestDialog> {
  final TextEditingController _descriptionController = TextEditingController();
  final DirectCommissionService _commissionService = DirectCommissionService();
  final EnhancedStorageService _storageService = EnhancedStorageService();
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _referenceImageUrls = [];
  bool _isSubmitting = false;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      // Show image source selection dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: GlassPanel(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'artist_feed_reference_source_title'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildImageSourceTile(
                  icon: Icons.photo_library,
                  label: 'artist_feed_reference_gallery'.tr(),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const SizedBox(height: 12),
                _buildImageSourceTile(
                  icon: Icons.camera_alt,
                  label: 'artist_feed_reference_camera'.tr(),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 16),
                HudButton(
                  isPrimary: false,
                  text: 'common_cancel'.tr(),
                  onPressed: () => Navigator.pop(context),
                  height: 44,
                ),
              ],
            ),
          ),
        ),
      );

      if (source == null) return;

      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      // Upload to Firebase Storage
      final File imageFile = File(pickedFile.path);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      final uploadResult = await _storageService.uploadImageWithOptimization(
        imageFile: imageFile,
        category: 'commission_references',
        generateThumbnail: true,
      );

      if (!mounted) return;

      setState(() {
        _referenceImageUrls.add(uploadResult['imageUrl']!);
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('artist_feed_reference_upload_success'.tr()),
          backgroundColor: const Color(0xFF34D399),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'artist_feed_reference_upload_error'.tr(namedArgs: {'error': '$e'}),
          ),
          backgroundColor: const Color(0xFFFF3D8D),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildImageSourceTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeReferenceImage(int index) {
    setState(() {
      _referenceImageUrls.removeAt(index);
    });
  }

  Future<void> _submitCommissionRequest() async {
    // Validate description
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('artist_feed_commission_missing_description'.tr()),
          backgroundColor: const Color(0xFFFF3D8D),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create commission request
      final requesterName = FirebaseAuth.instance.currentUser?.displayName ??
          'artist_feed_commission_request_client'.tr();
      final commissionId = await _commissionService.createCommissionRequest(
        artistId: widget.artist.userId,
        artistName: widget.artist.displayName,
        type: CommissionType.digital, // Default type, can be customized
        title: 'artist_feed_commission_request_title'.tr(
          namedArgs: {'name': requesterName},
        ),
        description: _descriptionController.text.trim(),
        specs: CommissionSpecs(
          size: 'To be determined',
          medium: 'To be determined',
          style: 'To be determined',
          colorScheme: 'To be determined',
          revisions: 1,
          commercialUse: false,
          deliveryFormat: 'To be determined',
          customRequirements: {},
        ),
        deadline: null, // Will be set by artist in quote
        metadata: {
          'referenceImages': _referenceImageUrls,
          'submittedFrom': 'artist_community_feed',
        },
      );

      if (!mounted) return;

      // Close dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'artist_feed_commission_success'.tr(
              namedArgs: {'name': widget.artist.displayName},
            ),
          ),
          backgroundColor: const Color(0xFF34D399),
          duration: const Duration(seconds: 4),
        ),
      );

      AppLogger.info('Commission request created: $commissionId');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'artist_feed_commission_error'.tr(namedArgs: {'error': '$e'}),
          ),
          backgroundColor: const Color(0xFFFF3D8D),
          duration: const Duration(seconds: 3),
        ),
      );

      AppLogger.error('Failed to create commission request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: GlassPanel(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.palette, color: Color(0xFFFFC857)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'artist_feed_commission_dialog_title'.tr(
                        namedArgs: {'name': widget.artist.displayName},
                      ),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF34D399)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'artist_feed_commission_banner'.tr(
                          namedArgs: {'name': widget.artist.displayName},
                        ),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'artist_feed_commission_details_title'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              GlassTextField(
                controller: _descriptionController,
                maxLines: 4,
                enabled: !_isSubmitting,
                decoration: GlassInputDecoration(
                  hintText: 'artist_feed_commission_details_placeholder'.tr(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'artist_feed_reference_section_title'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _isSubmitting || _isUploadingImage
                    ? null
                    : _pickAndUploadImage,
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.image,
                        color: Colors.white.withValues(
                          alpha: _isUploadingImage ? 0.4 : 0.8,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isUploadingImage
                              ? 'artist_feed_reference_uploading'.tr()
                              : 'artist_feed_reference_upload_cta'.tr(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      if (_isUploadingImage)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.add_photo_alternate, color: Colors.white),
                    ],
                  ),
                ),
              ),
              if (_referenceImageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _referenceImageUrls.asMap().entries.map((entry) {
                    final index = entry.key;
                    final url = entry.value;
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            url,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeReferenceImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: HudButton(
                      isPrimary: false,
                      text: 'common_cancel'.tr(),
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      height: 48,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientCTAButton(
                      text: 'artist_feed_commission_send_cta'.tr(),
                      icon: Icons.send,
                      onPressed: _isSubmitting ? null : _submitCommissionRequest,
                      isLoading: _isSubmitting,
                      height: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
