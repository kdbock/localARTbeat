import 'package:artbeat_art_walk/src/models/comment_model.dart';
import 'package:artbeat_art_walk/src/services/art_walk_service.dart';
import 'package:artbeat_art_walk/src/widgets/comment_tile.dart';
import 'package:artbeat_art_walk/src/widgets/typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:artbeat_core/shared_widgets.dart';

class ArtWalkCommentSection extends StatefulWidget {
  final String artWalkId;
  final String artWalkTitle;
  final ArtWalkService? artWalkService;

  const ArtWalkCommentSection({
    super.key,
    required this.artWalkId,
    required this.artWalkTitle,
    this.artWalkService,
  });

  @override
  State<ArtWalkCommentSection> createState() => _ArtWalkCommentSectionState();
}

class _ArtWalkCommentSectionState extends State<ArtWalkCommentSection> {
  ArtWalkService? _artWalkService;
  ArtWalkService get artWalkService =>
      _artWalkService ??= widget.artWalkService ?? ArtWalkService();

  final TextEditingController _commentController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isReplying = false;
  String? _parentCommentId;
  String? _parentCommentAuthor;
  double? _selectedRating;
  List<CommentModel> _comments = [];
  bool _hasLoadedComments = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedComments) {
      _hasLoadedComments = true;
      _loadComments();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);

    try {
      final comments = await artWalkService.getArtWalkComments(
        widget.artWalkId,
      );
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_art_walk_comment_section_error_error_loading_comments'
                  .tr()
                  .replaceAll('{error}', e.toString()),
            ),
          ),
        );
      });
    }
  }

  Future<void> _submitComment() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'art_walk_art_walk_comment_section_text_you_must_be_logged_in_to_comment'
                .tr(),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final content = _commentController.text.trim();
      await artWalkService.addCommentToArtWalk(
        artWalkId: widget.artWalkId,
        content: content,
        parentCommentId: _parentCommentId,
        rating: _isReplying ? null : _selectedRating,
      );

      _commentController.clear();
      setState(() {
        _isReplying = false;
        _parentCommentId = null;
        _parentCommentAuthor = null;
        _selectedRating = null;
      });

      await _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_art_walk_comment_section_error_error_posting_comment'
                  .tr()
                  .replaceAll('{error}', e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _replyToComment(String commentId, String authorName) {
    setState(() {
      _isReplying = true;
      _parentCommentId = commentId;
      _parentCommentAuthor = authorName;
    });
    _commentController.text = '';
    _inputFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _isReplying = false;
      _parentCommentId = null;
      _parentCommentAuthor = null;
    });
    _commentController.text = '';
    _inputFocusNode.unfocus();
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0B1026),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        title: Text(
          'art_walk_art_walk_comment_section_text_delete_comment'.tr(),
          style: AppTypography.screenTitle(
            Colors.white.withValues(alpha: 0.92),
          ),
        ),
        content: Text(
          'art_walk_art_walk_comment_section_text_are_you_sure_you_want_to_delete_this_comment'
              .tr(),
          style: AppTypography.body(Colors.white.withValues(alpha: 0.75)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'art_walk_button_cancel'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'art_walk_button_delete'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: const Color(0xFFFF3D8D),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await artWalkService.deleteArtWalkComment(
        artWalkId: widget.artWalkId,
        commentId: commentId,
      );
      await _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_art_walk_comment_section_error_error_deleting_comment'
                  .tr()
                  .replaceAll('{error}', e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleCommentLike(String commentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_art_walk_comment_section_text_you_must_be_logged_in_to_like_comments'
                  .tr(),
            ),
          ),
        );
      }
      return;
    }

    try {
      await artWalkService.toggleCommentLike(
        artWalkId: widget.artWalkId,
        commentId: commentId,
      );
      await _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_art_walk_comment_section_error_error_liking_comment'
                  .tr()
                  .replaceAll('{error}', e.toString()),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'art_walk_comment_section_title'.tr(),
          style: AppTypography.screenTitle(),
        ),
        const SizedBox(height: 16),
        GlassCard(
          borderRadius: 30,
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isReplying)
                  _RatingSelector(
                    selectedRating: _selectedRating,
                    onSelect: (rating) =>
                        setState(() => _selectedRating = rating),
                  ),
                if (_isReplying) ...[
                  _ReplyBanner(
                    authorName: _parentCommentAuthor ?? '',
                    onCancel: _cancelReply,
                  ),
                  const SizedBox(height: 12),
                ],
                _CommentInputField(
                  controller: _commentController,
                  focusNode: _inputFocusNode,
                  isReplying: _isReplying,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'art_walk_comment_section_error_empty_comment'
                          .tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (_isReplying) ...[
                      Expanded(
                        child: _GlassOutlineButton(
                          icon: Icons.close,
                          label: 'art_walk_comment_section_button_cancel_reply'
                              .tr(),
                          onTap: _cancelReply,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: GradientCTAButton(
                        label: _isReplying
                            ? 'art_walk_comment_section_button_reply_submit'
                                  .tr()
                            : 'art_walk_comment_section_button_post'.tr(),
                        icon: Icons.send,
                        onPressed: _submitComment,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_comments.isEmpty)
          GlassCard(
            borderRadius: 28,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 12),
                Text(
                  'art_walk_comment_section_empty_state'.tr(),
                  style: AppTypography.body(
                    Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final comment = _comments[index];
              final replies = comment.replies ?? [];
              final timeAgo = timeago.format(comment.createdAt);
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              final isAuthor = comment.userId == currentUserId;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommentTile(
                    authorName: comment.userName,
                    authorPhotoUrl: comment.userPhotoUrl,
                    content: comment.content,
                    timeAgo: timeAgo,
                    likeCount: comment.likeCount,
                    rating: comment.rating,
                    isAuthor: isAuthor,
                    onReply: () =>
                        _replyToComment(comment.id, comment.userName),
                    onDelete: isAuthor
                        ? () => _deleteComment(comment.id)
                        : null,
                    onLike: () => _toggleCommentLike(comment.id),
                  ),
                  if (replies.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 28, top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: replies.map((reply) {
                          final replyTimeAgo = timeago.format(reply.createdAt);
                          final isReplyAuthor = reply.userId == currentUserId;
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: CommentTile(
                              authorName: reply.userName,
                              authorPhotoUrl: reply.userPhotoUrl,
                              content: reply.content,
                              timeAgo: replyTimeAgo,
                              likeCount: reply.likeCount,
                              isAuthor: isReplyAuthor,
                              isReply: true,
                              onDelete: isReplyAuthor
                                  ? () => _deleteComment(reply.id)
                                  : null,
                              onLike: () => _toggleCommentLike(reply.id),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _RatingSelector extends StatelessWidget {
  final double? selectedRating;
  final ValueChanged<double> onSelect;

  const _RatingSelector({required this.selectedRating, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'art_walk_comment_section_rate_label'.tr(),
          style: AppTypography.sectionLabel(
            Colors.white.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            final value = (index + 1).toDouble();
            final isActive = (selectedRating ?? 0) >= value;
            return Padding(
              padding: EdgeInsets.only(right: index == 4 ? 0 : 10),
              child: GestureDetector(
                onTap: () => onSelect(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isActive
                        ? const Color(0xFFFFC857).withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFFFC857).withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    color: isActive
                        ? const Color(0xFFFFC857)
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ReplyBanner extends StatelessWidget {
  final String authorName;
  final VoidCallback onCancel;

  const _ReplyBanner({required this.authorName, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            color: Colors.white.withValues(alpha: 0.8),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'art_walk_comment_section_replying_to'.tr(
                namedArgs: {'author': authorName},
              ),
              style: AppTypography.body(Colors.white.withValues(alpha: 0.8)),
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close, size: 18),
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}

class _CommentInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isReplying;
  final String? Function(String?)? validator;

  const _CommentInputField({
    required this.controller,
    required this.focusNode,
    required this.isReplying,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      style: AppTypography.body(),
      minLines: 1,
      maxLines: 4,
      textInputAction: TextInputAction.newline,
      decoration: InputDecoration(
        hintText: isReplying
            ? 'art_walk_comment_section_input_reply_hint'.tr()
            : 'art_walk_comment_section_input_comment_hint'.tr(),
        hintStyle: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFF22D3EE)),
        ),
      ),
    );
  }
}

class _GlassOutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassOutlineButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        icon: Icon(icon, color: Colors.white, size: 18),
        label: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.04),
        ),
        onPressed: onTap,
      ),
    );
  }
}
