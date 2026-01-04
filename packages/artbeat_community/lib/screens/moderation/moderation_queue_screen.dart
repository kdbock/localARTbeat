import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart';

import '../../models/comment_model.dart';
import '../../models/post_model.dart';
import '../../services/moderation_service.dart';
import '../../widgets/post_detail_modal.dart';

class ModerationQueueScreen extends StatefulWidget {
  const ModerationQueueScreen({super.key});

  @override
  State<ModerationQueueScreen> createState() => _ModerationQueueScreenState();
}

class _ModerationQueueScreenState extends State<ModerationQueueScreen>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final ModerationService _moderationService = ModerationService();
  late final TabController _tabController;

  List<PostModel> _flaggedPosts = [];
  List<CommentModel> _flaggedComments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadModerationQueue();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadModerationQueue() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final posts = await _moderationService.getFlaggedPosts();
      final comments = await _moderationService.getFlaggedComments();

      if (!mounted) return;

      setState(() {
        _flaggedPosts = posts;
        _flaggedComments = comments;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading moderation queue: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(
        'moderation_queue_snackbar_load_error'.tr(
          namedArgs: {'error': e.toString()},
        ),
      );
    }
  }

  Future<void> _approvePost(PostModel post) async {
    try {
      await _moderationService.approvePost(post.id);
      if (!mounted) return;
      setState(() => _flaggedPosts.remove(post));
      _showSnackBar('moderation_queue_snackbar_post_approved'.tr());
    } catch (e) {
      _showSnackBar(
        'moderation_queue_snackbar_post_approve_error'.tr(
          namedArgs: {'error': e.toString()},
        ),
      );
    }
  }

  Future<void> _removePost(PostModel post) async {
    try {
      await _moderationService.removePost(post.id);
      if (!mounted) return;
      setState(() => _flaggedPosts.remove(post));
      _showSnackBar('moderation_queue_snackbar_post_removed'.tr());
    } catch (e) {
      _showSnackBar(
        'moderation_queue_snackbar_post_remove_error'.tr(
          namedArgs: {'error': e.toString()},
        ),
      );
    }
  }

  Future<void> _approveComment(CommentModel comment) async {
    try {
      await _moderationService.approveComment(comment.id);
      if (!mounted) return;
      setState(() => _flaggedComments.remove(comment));
      _showSnackBar('moderation_queue_snackbar_comment_approved'.tr());
    } catch (e) {
      _showSnackBar(
        'moderation_queue_snackbar_comment_approve_error'.tr(
          namedArgs: {'error': e.toString()},
        ),
      );
    }
  }

  Future<void> _removeComment(CommentModel comment) async {
    try {
      await _moderationService.removeComment(comment.id);
      if (!mounted) return;
      setState(() => _flaggedComments.remove(comment));
      _showSnackBar('moderation_queue_snackbar_comment_removed'.tr());
    } catch (e) {
      _showSnackBar(
        'moderation_queue_snackbar_comment_remove_error'.tr(
          namedArgs: {'error': e.toString()},
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF141226),
        content: Text(
          message,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  DateTime? _oldestFlaggedTimestamp() {
    final timestamps = <DateTime>[];
    for (final post in _flaggedPosts) {
      timestamps.add(post.flaggedAt ?? post.createdAt);
    }
    for (final comment in _flaggedComments) {
      timestamps.add(comment.flaggedAt ?? comment.createdAt.toDate());
    }
    if (timestamps.isEmpty) return null;
    timestamps.sort();
    return timestamps.first;
  }

  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays >= 1) {
      return '${diff.inDays}d ${diff.inHours % 24}h';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m';
    }
    return '${diff.inSeconds}s';
  }

  String _flagReasonText(String? notes, {required bool isPost}) {
    if (notes != null && notes.trim().isNotEmpty) {
      return notes.trim();
    }
    return isPost
        ? 'moderation_queue_default_post_reason'.tr()
        : 'moderation_queue_default_comment_reason'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final totalFlagged = _flaggedPosts.length + _flaggedComments.length;
    final oldestFlagged = _oldestFlaggedTimestamp();

    return WorldBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        drawer: const ArtbeatDrawer(),
        appBar: HudTopBar(
          title: 'screen_title_moderation'.tr(),
          showBackButton: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _isLoading ? null : _loadModerationQueue,
            ),
          ], subtitle: '',
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                _buildHeroCard(totalFlagged),
                const SizedBox(height: 16),
                _buildStatsRow(oldestFlagged),
                const SizedBox(height: 16),
                _buildTabSwitcher(),
                const SizedBox(height: 16),
                Expanded(child: _buildTabContent()),
                const SizedBox(height: 16),
                GradientCTAButton(
                  text: 'moderation_queue_action_refresh'.tr(),
                  icon: Icons.refresh,
                  width: double.infinity,
                  onPressed: _isLoading ? null : _loadModerationQueue,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(int totalFlagged) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      showAccentGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _ModerationPalette.primaryGradient,
                ),
                child: const Icon(Icons.shield_moon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'moderation_queue_hero_title'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _ModerationPalette.textPrimary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'moderation_queue_hero_subtitle'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _ModerationPalette.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'moderation_queue_label_open_items'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _ModerationPalette.textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalFlagged',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: _ModerationPalette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: HudButton.secondary(
                  text: 'moderation_queue_action_refresh'.tr(),
                  icon: Icons.auto_awesome,
                  onPressed: _isLoading ? null : _loadModerationQueue,
                  height: 52,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(DateTime? oldestFlagged) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'moderation_queue_stat_posts'.tr(),
            value: '${_flaggedPosts.length}',
            icon: Icons.article,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'moderation_queue_stat_comments'.tr(),
            value: '${_flaggedComments.length}',
            icon: Icons.forum,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'moderation_queue_stat_sla'.tr(),
            value: oldestFlagged == null
                ? 'moderation_queue_stat_sla_clean'.tr()
                : _formatRelativeTime(oldestFlagged),
            icon: Icons.schedule,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSwitcher() {
    return GlassCard(
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: _ModerationPalette.primaryGradient,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        splashBorderRadius: BorderRadius.circular(20),
        labelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
        tabs: [
          Tab(
            text: 'moderation_queue_tab_posts'.tr(
              namedArgs: {'count': '${_flaggedPosts.length}'},
            ),
          ),
          Tab(
            text: 'moderation_queue_tab_comments'.tr(
              namedArgs: {'count': '${_flaggedComments.length}'},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _flaggedPosts.isEmpty
            ? _buildEmptyState(
                icon: Icons.auto_awesome,
                title: 'moderation_queue_empty_posts_title'.tr(),
                message: 'moderation_queue_empty_posts_subtitle'.tr(),
              )
            : _buildPostsList(),
        _flaggedComments.isEmpty
            ? _buildEmptyState(
                icon: Icons.chat_bubble_outline,
                title: 'moderation_queue_empty_comments_title'.tr(),
                message: 'moderation_queue_empty_comments_subtitle'.tr(),
              )
            : _buildCommentsList(),
      ],
    );
  }

  Widget _buildPostsList() {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      itemBuilder: (context, index) => _buildPostItem(_flaggedPosts[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: _flaggedPosts.length,
    );
  }

  Widget _buildCommentsList() {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      itemBuilder: (context, index) => _buildCommentItem(
        _flaggedComments[index],
      ),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: _flaggedComments.length,
    );
  }

  Widget _buildPostItem(PostModel post) {
    final reason = _flagReasonText(post.moderationNotes, isPost: true);
    final location = post.location.isNotEmpty ? post.location : '—';
    final flaggedAge = _formatRelativeTime(post.flaggedAt ?? post.createdAt);

    return GlassCard(
      onTap: () => PostDetailModal.showFromPostModel(context, post),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: ImageUrlValidator.safeNetworkImage(
                  post.userPhotoUrl,
                ),
                child: !ImageUrlValidator.isValidImageUrl(post.userPhotoUrl)
                    ? Text(
                        post.userName.isNotEmpty
                            ? post.userName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$location · $flaggedAge',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post.content,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          if (post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ImageManagementService().getOptimizedImage(
                      imageUrl: post.imageUrls[index],
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      isThumbnail: true,
                      errorWidget: Container(
                        width: 140,
                        height: 140,
                        color: Colors.white.withValues(alpha: 0.1),
                        child: const Icon(Icons.error, color: Colors.white70),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemCount: post.imageUrls.length,
              ),
            ),
          ],
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'moderation_queue_label_tags'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.7),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: post.tags
                  .map(
                    (tag) => GradientBadge(
                      child: Text(
                        '#$tag',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'moderation_queue_label_flag_reason'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildMetadataPill(
                icon: Icons.place,
                label: 'moderation_queue_label_location'.tr(),
                value: location,
              ),
              _buildMetadataPill(
                icon: Icons.schedule,
                label: 'moderation_queue_label_flagged_time'.tr(),
                value: flaggedAge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GradientCTAButton(
                  text: 'moderation_queue_action_approve'.tr(),
                  icon: Icons.check_circle,
                  onPressed: () => _approvePost(post),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: HudButton.destructive(
                  text: 'moderation_queue_action_remove'.tr(),
                  icon: Icons.delete_forever,
                  onPressed: () => _removePost(post),
                  height: 52,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    final reason = _flagReasonText(comment.moderationNotes, isPost: false);
    final flaggedAge = _formatRelativeTime(
      comment.flaggedAt ?? comment.createdAt.toDate(),
    );

    return GlassCard(
      onTap: () => _showCommentDetails(comment, reason, flaggedAge),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: ImageUrlValidator.safeNetworkImage(
                  comment.userAvatarUrl,
                ),
                child: !ImageUrlValidator.isValidImageUrl(comment.userAvatarUrl)
                    ? Text(
                        comment.userName.isNotEmpty
                            ? comment.userName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${'moderation_queue_label_comment_type'.tr()}: ${comment.type}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            comment.content,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildMetadataPill(
            icon: Icons.link,
            label: 'moderation_queue_label_on_post'.tr(),
            value: comment.postId,
          ),
          const SizedBox(height: 16),
          _buildMetadataPill(
            icon: Icons.schedule,
            label: 'moderation_queue_label_flagged_time'.tr(),
            value: flaggedAge,
          ),
          const SizedBox(height: 16),
          Text(
            'moderation_queue_label_flag_reason'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GradientCTAButton(
                  text: 'moderation_queue_action_approve'.tr(),
                  icon: Icons.check_circle,
                  onPressed: () => _approveComment(comment),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: HudButton.destructive(
                  text: 'moderation_queue_action_remove'.tr(),
                  icon: Icons.delete_sweep,
                  onPressed: () => _removeComment(comment),
                  height: 52,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCommentDetails(
    CommentModel comment,
    String reason,
    String flaggedAge,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            top: 24,
          ),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'moderation_queue_comment_details_title'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${'moderation_queue_label_comment_type'.tr()}: ${comment.type}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'moderation_queue_comment_details_body_label'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  comment.content,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'moderation_queue_label_flag_reason'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reason,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMetadataPill(
                  icon: Icons.schedule,
                  label: 'moderation_queue_label_flagged_time'.tr(),
                  value: flaggedAge,
                ),
                const SizedBox(height: 16),
                HudButton.secondary(
                  text: 'moderation_queue_action_close'.tr(),
                  icon: Icons.check,
                  onPressed: () => Navigator.of(context).pop(),
                  height: 52,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              '$label: ',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
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

class _ModerationPalette {
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE), Color(0xFF34D399)],
  );

  static const Color textPrimary = Color(0xF2FFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
}
