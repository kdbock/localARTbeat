import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_community/artbeat_community.dart';

class AdminCommunityModerationScreen extends StatefulWidget {
  const AdminCommunityModerationScreen({super.key});

  @override
  State<AdminCommunityModerationScreen> createState() =>
      _AdminCommunityModerationScreenState();
}

class _AdminCommunityModerationScreenState
    extends State<AdminCommunityModerationScreen>
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

  @override
  Widget build(BuildContext context) {
    final totalFlagged = _flaggedPosts.length + _flaggedComments.length;
    final oldestFlagged = _oldestFlaggedTimestamp();

    return WorldBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: HudTopBar(
          title: 'screen_title_moderation'.tr(),
          showBackButton: true,
          onBackPressed: () => Navigator.of(context).pop(),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _isLoading ? null : _loadModerationQueue,
            ),
          ],
          subtitle: '',
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
                  gradient: LinearGradient(
                    colors: [Color(0xFF8C52FF), Color(0xFF00BF63)],
                  ),
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
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'moderation_queue_hero_subtitle'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
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
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalFlagged',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
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
            label: 'Posts',
            value: '${_flaggedPosts.length}',
            icon: Icons.article,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Comments',
            value: '${_flaggedComments.length}',
            icon: Icons.forum,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'SLA',
            value: oldestFlagged == null
                ? 'Clean'
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
          gradient: const LinearGradient(
            colors: [Color(0xFF8C52FF), Color(0xFF00BF63)],
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
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
          Tab(text: 'Posts (${_flaggedPosts.length})'),
          Tab(text: 'Comments (${_flaggedComments.length})'),
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
        _buildPostsList(),
        _buildCommentsList(),
      ],
    );
  }

  Widget _buildPostsList() {
    if (_flaggedPosts.isEmpty) {
      return const Center(
          child: Text('No flagged posts',
              style: TextStyle(color: Colors.white70)));
    }
    return ListView.builder(
      itemCount: _flaggedPosts.length,
      itemBuilder: (context, index) {
        final post = _flaggedPosts[index];
        return Card(
          color: Colors.white.withValues(alpha: 0.1),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white)),
            subtitle: Text('By: ${post.authorName}',
                style: const TextStyle(color: Colors.white70)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _approvePost(post)),
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removePost(post)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentsList() {
    if (_flaggedComments.isEmpty) {
      return const Center(
          child: Text('No flagged comments',
              style: TextStyle(color: Colors.white70)));
    }
    return ListView.builder(
      itemCount: _flaggedComments.length,
      itemBuilder: (context, index) {
        final comment = _flaggedComments[index];
        return Card(
          color: Colors.white.withValues(alpha: 0.1),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(comment.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white)),
            subtitle: Text('By: ${comment.userName}',
                style: const TextStyle(color: Colors.white70)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _approveComment(comment)),
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeComment(comment)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}
