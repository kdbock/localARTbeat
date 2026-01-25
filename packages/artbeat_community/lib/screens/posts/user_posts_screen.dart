import 'package:artbeat_core/artbeat_core.dart' hide GradientBadge;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/post_model.dart';
import '../../services/art_community_service.dart';
import '../../widgets/enhanced_post_card.dart';
import '../../widgets/gradient_badge.dart';
import '../../widgets/post_detail_modal.dart';

class _UserPostsPalette {
  static const Color textPrimary = Color(0xF2FFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color accentTeal = Color(0xFF22D3EE);
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color accentPink = Color(0xFFFF3D8D);
  static const Color accentGreen = Color(0xFF34D399);
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPurple, accentTeal, accentGreen],
  );
}

class UserPostsScreen extends StatefulWidget {
  const UserPostsScreen({super.key});

  @override
  State<UserPostsScreen> createState() => _UserPostsScreenState();
}

class _UserPostsScreenState extends State<UserPostsScreen> {
  final ArtCommunityService _communityService = ArtCommunityService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<PostModel> _userPosts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserPosts();
  }

  @override
  void dispose() {
    _communityService.dispose();
    super.dispose();
  }

  Future<void> _loadUserPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'community_user_posts.error_not_authenticated'.tr();
          _isLoading = false;
        });
        return;
      }

      final postsQuery = await _firestore
          .collection('posts')
          .where('authorId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final posts = postsQuery.docs.map(_mapDocToPostModel).toList();

      if (!mounted) return;
      setState(() {
        _userPosts = posts;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'community_user_posts.error_loading'.tr(
          namedArgs: {'message': e.toString()},
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HudTopBar(
        title: 'screen_title_my_posts'.tr(),
        glassBackground: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'community_user_posts.create_cta'.tr(),
            onPressed: _navigateToCreatePost,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          ),
        ],
        subtitle: '',
      ),
      body: WorldBackground(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _isLoading ? _buildLoadingState() : _buildBody(bottomInset),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: SizedBox(
        width: 64,
        height: 64,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            _UserPostsPalette.accentTeal,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(double bottomInset) {
    final children = <Widget>[_buildHeroCard(), const SizedBox(height: 16)];

    if (_error != null) {
      children.add(_buildErrorCard());
      children.add(const SizedBox(height: 16));
    }

    if (_userPosts.isEmpty) {
      children.add(_buildEmptyState());
    } else {
      children.addAll(_buildPostCards());
    }

    children.add(SizedBox(height: bottomInset + 24));

    return RefreshIndicator(
      color: _UserPostsPalette.accentTeal,
      onRefresh: _loadUserPosts,
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: children,
      ),
    );
  }

  Widget _buildHeroCard() {
    final totalPosts = _userPosts.length;
    final totalLikes = _userPosts.fold<int>(
      0,
      (sum, post) => sum + post.engagementStats.likeCount,
    );
    final totalComments = _userPosts.fold<int>(
      0,
      (sum, post) => sum + post.engagementStats.commentCount,
    );
    final latestPost = _userPosts.isEmpty ? null : _userPosts.first;
    final latestLabel = latestPost == null
        ? 'community_user_posts.hero_subtitle_empty'.tr()
        : _formatRelativeTime(latestPost.createdAt);

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(24),
      showAccentGlow: true,
      accentColor: _UserPostsPalette.accentTeal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientBadge(
            text: 'community_user_posts.hero_badge'.tr(),
            icon: Icons.auto_awesome,
            gradient: _UserPostsPalette.primaryGradient,
          ),
          const SizedBox(height: 16),
          Text(
            'community_user_posts.hero_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _UserPostsPalette.textPrimary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'community_user_posts.hero_subtitle'.tr(
              namedArgs: {
                'count': totalPosts.toString(),
                'recent': latestLabel,
              },
            ),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _UserPostsPalette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatTile(
                icon: Icons.collections_outlined,
                label: 'community_user_posts.stats_posts'.tr(),
                value: totalPosts.toString().padLeft(2, '0'),
                accent: _UserPostsPalette.accentPurple,
              ),
              _StatTile(
                icon: Icons.favorite_border,
                label: 'community_user_posts.stats_likes'.tr(),
                value: totalLikes.toString().padLeft(2, '0'),
                accent: _UserPostsPalette.accentPink,
              ),
              _StatTile(
                icon: Icons.forum_outlined,
                label: 'community_user_posts.stats_comments'.tr(),
                value: totalComments.toString().padLeft(2, '0'),
                accent: _UserPostsPalette.accentGreen,
              ),
            ],
          ),
          const SizedBox(height: 24),
          HudButton.primary(
            onPressed: _navigateToCreatePost,
            text: 'community_user_posts.create_cta'.tr(),
            icon: Icons.add,
            height: 52,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(24),
      showAccentGlow: true,
      accentColor: _UserPostsPalette.accentPink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(Icons.error_outline, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'community_user_posts.error_state_title'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _UserPostsPalette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _error ?? '',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _UserPostsPalette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          HudButton.secondary(
            onPressed: _loadUserPosts,
            text: 'community_user_posts.retry_cta'.tr(),
            icon: Icons.refresh,
            height: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(24),
      showAccentGlow: true,
      accentColor: _UserPostsPalette.accentPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: _UserPostsPalette.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.post_add, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'community_user_posts.empty_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _UserPostsPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'community_user_posts.empty_subtitle'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _UserPostsPalette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          HudButton.primary(
            onPressed: _navigateToCreatePost,
            text: 'community_user_posts.empty_cta'.tr(),
            icon: Icons.add,
            height: 52,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPostCards() {
    return _userPosts
        .map(
          (post) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: EnhancedPostCard(
              post: post,
              communityService: _communityService,
              onTap: () => _openPost(post),
              onEdit: () => _handleEdit(post),
              onDelete: () => _showDeleteDialog(post),
            ),
          ),
        )
        .toList();
  }

  void _openPost(PostModel post) {
    PostDetailModal.showFromPostModel(context, post);
  }

  void _handleEdit(PostModel post) {
    _showSnackBar('community_user_posts.edit_unavailable'.tr());
  }

  void _showDeleteDialog(PostModel post) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: GlassCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'community_user_posts.delete_confirm_title'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _UserPostsPalette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'community_user_posts.delete_confirm_message'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _UserPostsPalette.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: HudButton.secondary(
                        onPressed: () => Navigator.of(context).pop(),
                        text: 'community_user_posts.delete_confirm_cancel'.tr(),
                        icon: Icons.close,
                        height: 48,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HudButton.destructive(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _deletePost(post.id);
                        },
                        text: 'community_user_posts.delete_confirm_cta'.tr(),
                        icon: Icons.delete,
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

  Future<void> _deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      setState(() {
        _userPosts.removeWhere((post) => post.id == postId);
      });
      _showSnackBar('community_user_posts.delete_success'.tr());
    } catch (e) {
      _showSnackBar(
        'community_user_posts.delete_failure'.tr(
          namedArgs: {'message': e.toString()},
        ),
      );
    }
  }

  void _navigateToCreatePost() {
    Navigator.pushNamed(context, '/community/create-post');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 1) {
      return 'community_user_posts.time_days'.tr(
        namedArgs: {'count': difference.inDays.toString()},
      );
    }
    if (difference.inHours >= 1) {
      return 'community_user_posts.time_hours'.tr(
        namedArgs: {'count': difference.inHours.toString()},
      );
    }
    if (difference.inMinutes >= 1) {
      return 'community_user_posts.time_minutes'.tr(
        namedArgs: {'count': difference.inMinutes.toString()},
      );
    }
    return 'community_user_posts.time_now'.tr();
  }

  PostModel _mapDocToPostModel(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final imageUrls = [..._asStringList(data['imageUrls'])];
    final fallbackImage = (data['imageUrl'] as String?)?.trim();
    if (fallbackImage != null && fallbackImage.isNotEmpty) {
      imageUrls.add(fallbackImage);
    }

    final tags = _asStringList(data['tags']);
    final mentionedUsers = _asStringList(data['mentionedUsers']);
    final engagement = data['engagementStats'] as Map<String, dynamic>?;

    final likes =
        _asInt(engagement?['likeCount']) ?? _asInt(data['likesCount']) ?? 0;
    final comments =
        _asInt(engagement?['commentCount']) ??
        _asInt(data['commentsCount']) ??
        0;
    final shares =
        _asInt(engagement?['shareCount']) ?? _asInt(data['sharesCount']) ?? 0;

    return PostModel(
      id: doc.id,
      userId:
          (data['userId'] as String?) ?? (data['authorId'] as String?) ?? '',
      userName:
          (data['userName'] as String?) ??
          (data['authorName'] as String?) ??
          '',
      userPhotoUrl:
          (data['userPhotoUrl'] as String?) ??
          (data['authorProfileImage'] as String?) ??
          '',
      content:
          (data['content'] as String?) ??
          (data['postContent'] as String?) ??
          '',
      imageUrls: imageUrls,
      videoUrl: data['videoUrl'] as String?,
      audioUrl: data['audioUrl'] as String?,
      tags: tags,
      location:
          (data['location'] as String?) ?? (data['city'] as String?) ?? '',
      geoPoint: data['geoPoint'] as GeoPoint?,
      zipCode: data['zipCode'] as String?,
      createdAt: createdAt,
      engagementStats: EngagementStats(
        likeCount: likes,
        commentCount: comments,
        shareCount: shares,
        lastUpdated: createdAt,
      ),
      isPublic: (data['isPublic'] as bool?) ?? true,
      mentionedUsers: mentionedUsers.isEmpty ? null : mentionedUsers,
      metadata: data['metadata'] as Map<String, dynamic>?,
      isUserVerified:
          (data['isUserVerified'] as bool?) ??
          (data['authorVerified'] as bool?) ??
          false,
      moderationStatus: PostModerationStatus.fromString(
        (data['moderationStatus'] as String?) ?? 'approved',
      ),
      flagged: (data['flagged'] as bool?) ?? false,
      flaggedAt: (data['flaggedAt'] as Timestamp?)?.toDate(),
      moderationNotes: data['moderationNotes'] as String?,
      isLikedByCurrentUser: (data['isLikedByCurrentUser'] as bool?) ?? false,
      groupType: data['groupType'] as String?,
    );
  }

  List<String> _asStringList(dynamic source) {
    if (source == null) return [];
    if (source is Iterable) {
      return source
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
    }
    if (source is String && source.trim().isNotEmpty) {
      return [source.trim()];
    }
    return [];
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
      glassOpacity: 0.08,
      borderOpacity: 0.16,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
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
