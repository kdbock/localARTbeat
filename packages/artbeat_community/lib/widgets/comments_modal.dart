import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/post_model.dart';
import '../models/art_models.dart';
import '../services/art_community_service.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Modal widget for displaying and adding comments to a post
class CommentsModal extends StatefulWidget {
  final PostModel post;
  final ArtCommunityService communityService;
  final VoidCallback? onCommentAdded;

  const CommentsModal({
    super.key,
    required this.post,
    required this.communityService,
    this.onCommentAdded,
  });

  @override
  State<CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends State<CommentsModal> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ArtComment> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  final FocusNode _textFieldFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _textFieldFocus.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      AppLogger.info(
        '💬 CommentsModal: Loading comments for post ${widget.post.id}',
      );
      setState(() => _isLoading = true);
      final comments = await widget.communityService.getComments(
        widget.post.id,
      );
      setState(() {
        _comments = comments;
        _isLoading = false;
      });

      AppLogger.info(
        '💬 CommentsModal: Successfully loaded ${comments.length} comments',
      );

      // Debug: Show a snackbar with the result
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Debug: Loaded ${comments.length} comments for post ${widget.post.id}',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }

      // Debug: Log each comment
      for (int i = 0; i < comments.length; i++) {
        AppLogger.info(
          '💬 Comment ${i}: "${comments[i].content}" by ${comments[i].userName}',
        );
      }

      // Also log the post ID for debugging
      AppLogger.info(
        '💬 CommentsModal: Post ID being queried: "${widget.post.id}"',
      );
    } catch (e) {
      AppLogger.error('Error loading comments: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load comments: $e')));
      }
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final commentId = await widget.communityService.addComment(
        widget.post.id,
        content,
      );

      if (commentId != null) {
        // Clear the text field
        _commentController.clear();

        // Reload comments to show the new one
        await _loadComments();

        // Notify parent that a comment was added
        widget.onCommentAdded?.call();

        // Scroll to bottom to show new comment
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }

        // Remove focus from text field
        _textFieldFocus.unfocus();
      } else {
        throw Exception('Failed to add comment');
      }
    } catch (e) {
      AppLogger.error('Error adding comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add comment. Please try again.'),
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside of text field
        FocusScope.of(context).unfocus();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: MediaQuery.of(context).size.height * 0.75,
        padding: EdgeInsets.only(bottom: keyboardHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    color: ArtbeatColors.primaryPurple,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr(
                      'comments_modal_title',
                      args: [_comments.length.toString()],
                    ),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: ArtbeatColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Comments list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            tr('comments_modal_no_comments_title'),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: ArtbeatColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr('comments_modal_no_comments_subtitle'),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: ArtbeatColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        return _buildCommentItem(comment);
                      },
                    ),
            ),

            // Comment input
            if (user != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // User avatar
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: ImageUrlValidator.safeNetworkImage(
                        user.photoURL,
                      ),
                      child: !ImageUrlValidator.isValidImageUrl(user.photoURL)
                          ? Text(
                              (user.displayName?.isNotEmpty == true
                                      ? user.displayName![0]
                                      : 'U')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Text input
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Prevent dismissing keyboard when tapping the text field
                        },
                        child: TextField(
                          controller: _commentController,
                          focusNode: _textFieldFocus,
                          decoration: InputDecoration(
                            hintText: tr('comments_modal_add_comment_hint'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: ArtbeatColors.primaryPurple,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _addComment(),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Send button
                    GestureDetector(
                      onTap: _isSubmitting ? null : _addComment,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _isSubmitting
                              ? Colors.grey
                              : ArtbeatColors.primaryPurple,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
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

  Widget _buildCommentItem(ArtComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          CircleAvatar(
            radius: 16,
            backgroundImage: ImageUrlValidator.safeNetworkImage(
              comment.userAvatarUrl,
            ),
            child: !ImageUrlValidator.isValidImageUrl(comment.userAvatarUrl)
                ? Text(
                    comment.userName.isNotEmpty
                        ? comment.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User name and time
                Row(
                  children: [
                    Text(
                      comment.userName.isNotEmpty
                          ? comment.userName
                          : tr('comments_modal_anonymous'),
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: ArtbeatColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(comment.createdAt),
                      style: GoogleFonts.spaceGrotesk(
                        color: ArtbeatColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Comment text
                Text(
                  comment.content,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ArtbeatColors.textPrimary,
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
