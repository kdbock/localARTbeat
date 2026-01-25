import 'package:artbeat_core/artbeat_core.dart' hide DateFormat, NumberFormat;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../../models/comment_model.dart';
import '../../models/post_model.dart';
import '../../widgets/widgets.dart';

class CommentsScreen extends StatefulWidget {
  final PostModel post;

  const CommentsScreen({super.key, required this.post});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commentFocusNode = FocusNode();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSendingComment = false;
  String _commentType = _commentCategories.first.value;
  CommentModel? _replyingTo;

  static const List<_CommentCategory> _commentCategories = [
    _CommentCategory(
      value: 'Appreciation',
      labelKey: 'comments_type_appreciation',
      icon: Icons.favorite_border,
    ),
    _CommentCategory(
      value: 'Constructive Critique',
      labelKey: 'comments_type_constructive_critique',
      icon: Icons.tips_and_updates_outlined,
    ),
    _CommentCategory(
      value: 'Technical Question',
      labelKey: 'comments_type_technical_question',
      icon: Icons.psychology_alt_outlined,
    ),
    _CommentCategory(
      value: 'Inspiration',
      labelKey: 'comments_type_inspiration',
      icon: Icons.auto_awesome,
    ),
    _CommentCategory(
      value: 'General Discussion',
      labelKey: 'comments_type_general_discussion',
      icon: Icons.chat_bubble_outline,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    AppLogger.debug('Loading comments for ${widget.post.id}');
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .get();

      if (!mounted) {
        return;
      }

      setState(() {
        _comments = snapshot.docs
            .map((doc) => CommentModel.fromFirestore(doc))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading comments: $e');
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      _showError('comments_load_error'.tr(namedArgs: {'error': '$e'}));
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      return;
    }

    setState(() => _isSendingComment = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('comments_sign_in_required'.tr());
        return;
      }

      final userService = Provider.of<UserService>(context, listen: false);
      final userModel = await userService.getUserById(user.uid);

      if (userModel == null) {
        _showError('comments_user_profile_error'.tr());
        return;
      }

      final avatarUrl = userModel.profileImageUrl;
      final parentId = _replyingTo?.id ?? '';

      final commentDoc = {
        'postId': widget.post.id,
        'userId': user.uid,
        'userName': userModel.fullName,
        'userAvatarUrl': avatarUrl,
        'content': content,
        'type': _commentType,
        'parentCommentId': parentId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final commentRef = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .collection('comments')
          .add(commentDoc);

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .update({'commentCount': FieldValue.increment(1)});

      final newComment = CommentModel(
        id: commentRef.id,
        postId: widget.post.id,
        userId: user.uid,
        userName: userModel.fullName,
        userAvatarUrl: avatarUrl,
        content: content,
        type: _commentType,
        parentCommentId: parentId,
        createdAt: Timestamp.now(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _comments = [..._comments, newComment];
        _commentController.clear();
        _replyingTo = null;
        _commentType = _commentCategories.first.value;
      });

      _scrollToBottom();
    } catch (e) {
      AppLogger.error('Error adding comment: $e');
      final message = e.toString();
      if (message.contains('permission-denied')) {
        _showError('comments_add_error_permission'.tr());
      } else if (message.contains('not-found')) {
        _showError('comments_add_error_missing_post'.tr());
      } else if (message.toLowerCase().contains('network')) {
        _showError('comments_add_error_network'.tr());
      } else {
        _showError('comments_add_error_generic'.tr());
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingComment = false);
      }
    }
  }

  void _setReplyTo(CommentModel comment) {
    setState(() {
      _replyingTo = comment;
      _commentController.text = '@${comment.userName} ';
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentController.text.length),
      );
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
      _commentController.clear();
    });
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF3D8D),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatPostDate() {
    final locale = context.locale.toString();
    return intl.DateFormat.yMMMd(locale).format(widget.post.createdAt);
  }

  String _formatMetric(int value) {
    final locale = context.locale.toString();
    return intl.NumberFormat.compact(locale: locale).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      appBar: HudTopBar(
        title: 'comments_title'.tr(),
        glassBackground: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'comments_refresh_tooltip'.tr(),
            onPressed: _isLoading ? null : _loadComments,
          ),
        ],
        subtitle: '',
      ),
      body: WorldBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 16),
                    _buildMetricsRow(),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: _buildThreadBody(),
                  ),
                ),
              ),
              _buildComposer(bottomPadding, keyboardInset),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return GlassCard(
      showAccentGlow: true,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(
                avatarUrl: widget.post.userPhotoUrl,
                userId: widget.post.userId,
                displayName: widget.post.userName,
                radius: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'comments_header_title'.tr(
                        namedArgs: {'name': widget.post.userName},
                      ),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'comments_header_meta'.tr(
                        namedArgs: {'date': _formatPostDate()},
                      ),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.post.content.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              widget.post.content,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'comments_header_subtitle'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    final stats = widget.post.engagementStats;
    return Row(
      children: [
        Expanded(
          child: _buildMetric(
            icon: Icons.forum_outlined,
            value: _formatMetric(stats.commentCount),
            label: 'comments_stat_comments'.tr(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetric(
            icon: Icons.favorite_outline,
            value: _formatMetric(stats.likeCount),
            label: 'comments_stat_applause'.tr(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetric(
            icon: Icons.ios_share,
            value: _formatMetric(stats.shareCount),
            label: 'comments_stat_shares'.tr(),
          ),
        ),
      ],
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.7),
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

  Widget _buildThreadBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
      );
    }

    if (_comments.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: const Color(0xFF7C4DFF),
      onRefresh: _loadComments,
      child: FeedbackThreadWidget(
        comments: _comments,
        onReply: _setReplyTo,
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: GlassCard(
        showAccentGlow: true,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.palette_outlined,
              size: 44,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 16),
            Text(
              'comments_empty_title'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'comments_empty_body'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            GradientCTAButton(
              text: 'comments_empty_cta'.tr(),
              icon: Icons.bolt,
              onPressed: () => _commentFocusNode.requestFocus(),
              height: 48,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(double bottomPadding, double keyboardInset) {
    final double composerBottom = keyboardInset > 0
        ? keyboardInset + 16.0
        : (bottomPadding == 0 ? 32.0 : bottomPadding + 24.0);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, composerBottom),
      child: Column(
        children: [
          if (_replyingTo != null) ...[
            _buildReplyBanner(),
            const SizedBox(height: 12),
          ],
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'comments_type_label'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _commentCategories
                      .map(_buildTypeChip)
                      .toList(growable: false),
                ),
                const SizedBox(height: 16),
                GlassTextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  enabled: !_isSendingComment,
                  maxLines: 5,
                  hintText: 'comments_input_placeholder'.tr(),
                  labelText: 'comments_input_label'.tr(),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: GradientCTAButton(
                    text: _isSendingComment
                        ? 'comments_sending_label'.tr()
                        : 'comments_send_label'.tr(),
                    icon: Icons.send,
                    onPressed: _isSendingComment ? null : _addComment,
                    isLoading: _isSendingComment,
                    height: 48,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBanner() {
    if (_replyingTo == null) {
      return const SizedBox.shrink();
    }
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.reply, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'comments_replying_to'.tr(
                namedArgs: {'name': _replyingTo!.userName},
              ),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          HudButton.secondary(
            text: 'comments_reply_cancel'.tr(),
            onPressed: _cancelReply,
            height: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(_CommentCategory category) {
    final isSelected = _commentType == category.value;
    return GestureDetector(
      onTap: _isSendingComment
          ? null
          : () => setState(() => _commentType = category.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7C4DFF),
                    Color(0xFF22D3EE),
                    Color(0xFF34D399),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              category.labelKey.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentCategory {
  final String value;
  final String labelKey;
  final IconData icon;

  const _CommentCategory({
    required this.value,
    required this.labelKey,
    required this.icon,
  });
}
