import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart';

import '../models/post_model.dart';
import '../services/art_community_service.dart';
import '../widgets/comments_modal.dart';
import '../widgets/enhanced_post_card.dart';
import '../widgets/fullscreen_image_viewer.dart';
import '../widgets/post_detail_modal.dart';

class _Palette {
  static const Color textPrimary = Color(0xF2FFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textTertiary = Color(0x73FFFFFF);
  static const Color purple = Color(0xFF7C4DFF);
  static const Color teal = Color(0xFF22D3EE);
  static const Color green = Color(0xFF34D399);
  static const Color pink = Color(0xFFFF3D8D);
}

class ArtistFeedScreen extends StatefulWidget {
  final String artistId;
  final String? artistName;

  const ArtistFeedScreen({super.key, required this.artistId, this.artistName});

  @override
  State<ArtistFeedScreen> createState() => _ArtistFeedScreenState();
}

class _ArtistFeedScreenState extends State<ArtistFeedScreen> {
  final ArtCommunityService _communityService = ArtCommunityService();
  List<PostModel> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtistAndPosts();
  }

  @override
  void dispose() {
    _communityService.dispose();
    super.dispose();
  }

  Future<void> _loadArtistAndPosts() async {
    setState(() => _isLoading = true);

    try {
      AppLogger.info('🎨 Loading artist feed for: ${widget.artistId}');
      final allPosts = await _communityService.getFeed(limit: 100);
      final artistPosts = allPosts
          .where((post) => post.userId == widget.artistId)
          .toList();

      AppLogger.info('🎨 Found ${artistPosts.length} posts from this artist');

      if (mounted) {
        setState(() {
          _posts = artistPosts;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('🎨 Error loading artist feed: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'community_artist_feed.error_loading'.tr(
              namedArgs: {'error': e.toString()},
            ),
          ),
        ),
      );
    }
  }

  void _handlePostTap(PostModel post) {
    PostDetailModal.showFromPostModel(context, post);
  }

  void _handleLike(PostModel post) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('community_artist_feed.sign_in_like'.tr()),
          ),
        );
        return;
      }

      final postIndex = _posts.indexWhere((p) => p.id == post.id);
      if (postIndex != -1) {
        setState(() {
          final currentLikeCount = _posts[postIndex].engagementStats.likeCount;
          final isCurrentlyLiked = _posts[postIndex].isLikedByCurrentUser;

          final newEngagementStats = EngagementStats(
            likeCount:
                isCurrentlyLiked ? currentLikeCount - 1 : currentLikeCount + 1,
            commentCount: _posts[postIndex].engagementStats.commentCount,
            shareCount: _posts[postIndex].engagementStats.shareCount,
            lastUpdated: DateTime.now(),
          );

          _posts[postIndex] = _posts[postIndex].copyWith(
            isLikedByCurrentUser: !isCurrentlyLiked,
            engagementStats: newEngagementStats,
          );
        });
      }

      final success = await _communityService.toggleLike(post.id);
      if (!success && postIndex != -1) {
        setState(() {
          final currentLikeCount = _posts[postIndex].engagementStats.likeCount;
          final isCurrentlyLiked = _posts[postIndex].isLikedByCurrentUser;

          final revertedEngagementStats = EngagementStats(
            likeCount:
                isCurrentlyLiked ? currentLikeCount - 1 : currentLikeCount + 1,
            commentCount: _posts[postIndex].engagementStats.commentCount,
            shareCount: _posts[postIndex].engagementStats.shareCount,
            lastUpdated: DateTime.now(),
          );

          _posts[postIndex] = _posts[postIndex].copyWith(
            isLikedByCurrentUser: !isCurrentlyLiked,
            engagementStats: revertedEngagementStats,
          );
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'community_artist_feed.update_like_failed'.tr(),
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error handling like: $e');
    }
  }

  void _handleComment(PostModel post) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('community_artist_feed.sign_in_comment'.tr()),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsModal(
        post: post,
        communityService: _communityService,
        onCommentAdded: _loadArtistAndPosts,
      ),
    );
  }

  void _handleShare(PostModel post) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('community_artist_feed.sign_in_share'.tr()),
          ),
        );
        return;
      }

      final sections = <String>[
        'community_artist_feed.share_prefix'.tr(),
      ];

      if (post.content.isNotEmpty) {
        sections.add('"${post.content}"');
      }

      sections.add(
        'community_artist_feed.share_original_author'.tr(
          namedArgs: {'author': post.userName},
        ),
      );

      if (post.location.isNotEmpty) {
        sections.add(
          'community_artist_feed.share_location'.tr(
            namedArgs: {'location': post.location},
          ),
        );
      }

      if (post.tags.isNotEmpty) {
        sections.add(
          'community_artist_feed.share_tags'.tr(
            namedArgs: {
              'tags': post.tags.map((tag) => '#$tag').join(' '),
            },
          ),
        );
      }

      final shareContent = sections.join('\n\n');

      final postId = await _communityService.createPost(
        content: shareContent,
        imageUrls: post.imageUrls,
        tags: post.tags,
        isArtistPost: false,
      );

      if (postId != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('community_artist_feed.share_success'.tr()),
            ),
          );
        }

        await _loadArtistAndPosts();
        _communityService.incrementShareCount(post.id);
      } else {
        throw Exception('share_failed');
      }
    } catch (e) {
      AppLogger.error('Error sharing post: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('community_artist_feed.share_failure'.tr()),
        ),
      );
    }
  }

  void _showFullscreenImage(
    String imageUrl,
    int initialIndex,
    List<String> allImages,
  ) {
    FullscreenImageViewer.show(
      context,
      imageUrls: allImages,
      initialIndex: initialIndex,
    );
  }

  String _resolveArtistName() {
    final provided = widget.artistName?.trim();
    if (provided == null || provided.isEmpty) {
      return 'community_artist_feed.unknown_artist'.tr();
    }
    return provided;
  }

  @override
  Widget build(BuildContext context) {
    final artistName = _resolveArtistName();
    final artistArgs = {'artist': artistName};
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HudTopBar(
        title: 'community_artist_feed.app_bar'.tr(namedArgs: artistArgs),
        glassBackground: true,
        actions: [
          IconButton(
            tooltip: 'community_artist_feed.refresh_cta'.tr(),
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _loadArtistAndPosts,
          ),
        ], subtitle: '',
      ),
      body: WorldBackground(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: _buildBody(context, artistArgs, bottomInset),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    Map<String, String> artistArgs,
    double bottomInset,
  ) {
    if (_isLoading) {
      return _buildLoadingState(context);
    }

    final children = <Widget>[
      _buildHeroSection(context, artistArgs),
      const SizedBox(height: 16),
    ];

    if (_posts.isEmpty) {
      children.add(_buildEmptyStateCard(artistArgs));
    } else {
      children.addAll(
        _posts.map(
          (post) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: EnhancedPostCard(
              post: post,
              onTap: () => _handlePostTap(post),
              onLike: () => _handleLike(post),
              onComment: () => _handleComment(post),
              onShare: () => _handleShare(post),
              onImageTap: (imageUrl, index) =>
                  _showFullscreenImage(imageUrl, index, post.imageUrls),
              onBlockStatusChanged: () => _loadArtistAndPosts(),
            ),
          ),
        ),
      );
    }

    children.add(SizedBox(height: bottomInset + 32));

    return RefreshIndicator(
      onRefresh: _loadArtistAndPosts,
      color: _Palette.purple,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: children,
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    Map<String, String> artistArgs,
  ) {
    final totalPosts = _posts.length;
    final totalLikes = _posts.fold<int>(
      0,
      (sum, post) => sum + post.engagementStats.likeCount,
    );
    final totalComments = _posts.fold<int>(
      0,
      (sum, post) => sum + post.engagementStats.commentCount,
    );

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'community_artist_feed.hero_title'.tr(namedArgs: artistArgs),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _Palette.textPrimary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'community_artist_feed.hero_subtitle'.tr(
              namedArgs: {'count': totalPosts.toString()},
            ),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _Palette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatsRow(totalPosts, totalLikes, totalComments),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: HudButton.primary(
                  onPressed: _isLoading ? null : _loadArtistAndPosts,
                  text: 'community_artist_feed.refresh_cta'.tr(),
                  icon: Icons.refresh,
                  height: 48,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: HudButton.secondary(
                  onPressed: () => Navigator.of(context).maybePop(),
                  text: 'community_artist_feed.back_cta'.tr(),
                  icon: Icons.arrow_back,
                  height: 48,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int totalPosts, int totalLikes, int totalComments) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final isWide = constraints.maxWidth >= 560;
        final columns = isWide ? 3 : 2;
        final tileWidth = columns == 3
            ? (constraints.maxWidth - spacing * 2) / 3
            : (constraints.maxWidth - spacing) / 2;

        final tiles = [
          _StatTile(
            label: 'community_artist_feed.posts_label'.tr(),
            value: totalPosts.toString(),
            icon: Icons.auto_awesome,
            accent: _Palette.teal,
          ),
          _StatTile(
            label: 'community_artist_feed.likes_label'.tr(),
            value: totalLikes.toString(),
            icon: Icons.favorite_rounded,
            accent: _Palette.pink,
          ),
          _StatTile(
            label: 'community_artist_feed.comments_label'.tr(),
            value: totalComments.toString(),
            icon: Icons.forum_rounded,
            accent: _Palette.green,
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: tiles
              .map(
                (tile) => SizedBox(
                  width: tileWidth,
                  child: tile,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildEmptyStateCard(Map<String, String> artistArgs) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _Palette.purple.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            child: const Icon(Icons.brush_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'community_artist_feed.empty_title'.tr(namedArgs: artistArgs),
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _Palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'community_artist_feed.empty_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _Palette.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(_Palette.purple),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'community_artist_feed.loading_label'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _Palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _Palette.textPrimary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _Palette.textTertiary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
