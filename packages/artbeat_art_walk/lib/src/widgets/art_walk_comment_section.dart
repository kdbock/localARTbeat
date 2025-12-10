import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_art_walk/src/services/art_walk_service.dart';
import 'package:artbeat_art_walk/src/models/comment_model.dart';
import 'package:timeago/timeago.dart' as timeago;

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
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isReplying = false;
  String? _parentCommentId;
  String? _parentCommentAuthor;
  double? _selectedRating;
  List<CommentModel> _comments = [];
  bool _hasLoadedComments = false;

  @override
  void initState() {
    super.initState();
  }

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
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('art_walk_art_walk_comment_section_error_error_loading_comments'.tr().replaceAll('{error}', e.toString())),
              ),
            );
          }
        });
      }
    }
  }

  Future<void> _submitComment() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('art_walk_art_walk_comment_section_text_you_must_be_logged_in_to_comment'.tr())),
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
        rating: _isReplying
            ? null
            : _selectedRating, // Only include rating for top-level comments
      );

      // Reset the form
      _commentController.clear();
      setState(() {
        _isReplying = false;
        _parentCommentId = null;
        _parentCommentAuthor = null;
        _selectedRating = null;
      });

      // Reload comments
      await _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('art_walk_art_walk_comment_section_error_error_posting_comment'.tr().replaceAll('{error}', e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _replyToComment(String commentId, String authorName) {
    setState(() {
      _isReplying = true;
      _parentCommentId = commentId;
      _parentCommentAuthor = authorName;
    });
    _commentController.text = '';
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelReply() {
    setState(() {
      _isReplying = false;
      _parentCommentId = null;
      _parentCommentAuthor = null;
    });
    _commentController.text = '';
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('art_walk_art_walk_comment_section_text_delete_comment'.tr()),
        content: Text('art_walk_art_walk_comment_section_text_are_you_sure_you_want_to_delete_this_comment'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('art_walk_button_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
          SnackBar(content: Text('art_walk_art_walk_comment_section_error_error_deleting_comment'.tr().replaceAll('{error}', e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleCommentLike(String commentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('art_walk_art_walk_comment_section_text_you_must_be_logged_in_to_like_comments'.tr()),
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
          SnackBar(content: Text('art_walk_art_walk_comment_section_error_error_liking_comment'.tr().replaceAll('{error}', e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Comments & Reviews',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // Comment form
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating selector (only for top-level comments)
                if (!_isReplying)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rate this art walk:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            final rating = index + 1.0;
                            return IconButton(
                              icon: Icon(
                                rating <= (_selectedRating ?? 0)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: rating <= (_selectedRating ?? 0)
                                    ? Colors.amber
                                    : Colors.grey,
                                size: 28,
                              ),
                              onPressed: () {
                                setState(() => _selectedRating = rating);
                              },
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                // Reply status bar
                if (_isReplying)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Replying to $_parentCommentAuthor',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: _cancelReply,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Comment text field
                TextFormField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: _isReplying
                        ? 'Write a reply...'
                        : 'Write a comment or review...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.all(12.0),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _submitComment,
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Comment cannot be empty';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),

        // Comments list
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _comments.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No comments yet. Be the first to comment!',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  final timeAgo = timeago.format(comment.createdAt);

                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                  final isAuthor = comment.userId == currentUserId;

                  // Get replies
                  final replies = comment.replies ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main comment
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

                      // Replies
                      if (replies.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: replies.map<Widget>((reply) {
                              final replyTimeAgo = timeago.format(
                                reply.createdAt,
                              );
                              final isReplyAuthor =
                                  reply.userId == currentUserId;

                              return CommentTile(
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
                              );
                            }).toList(),
                          ),
                        ),

                      const Divider(),
                    ],
                  );
                },
              ),
      ],
    );
  }
}

class CommentTile extends StatelessWidget {
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final String timeAgo;
  final int likeCount;
  final double? rating;
  final bool isAuthor;
  final bool isReply;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final VoidCallback onLike;

  const CommentTile({
    super.key,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    required this.timeAgo,
    required this.likeCount,
    this.rating,
    this.isAuthor = false,
    this.isReply = false,
    this.onReply,
    this.onDelete,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 8.0,
        bottom: isReply ? 0.0 : 8.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Author avatar
              CircleAvatar(
                radius: isReply ? 14.0 : 18.0,
                backgroundColor: Colors.grey.shade300,
                backgroundImage:
                    authorPhotoUrl != null &&
                        authorPhotoUrl!.isNotEmpty &&
                        Uri.tryParse(authorPhotoUrl!)?.hasScheme == true
                    ? NetworkImage(authorPhotoUrl!)
                    : null,
                child:
                    authorPhotoUrl == null ||
                        authorPhotoUrl!.isEmpty ||
                        Uri.tryParse(authorPhotoUrl!)?.hasScheme != true
                    ? Icon(
                        Icons.person,
                        size: isReply ? 16.0 : 20.0,
                        color: Colors.grey.shade700,
                      )
                    : null,
              ),
              const SizedBox(width: 8),

              // Author name and timestamp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: isReply ? 12.0 : 14.0,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: isReply ? 10.0 : 12.0,
                      ),
                    ),
                  ],
                ),
              ),

              // Delete option for author
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: onDelete,
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),

          // Rating (only for top-level comments)
          if (rating != null && !isReply)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 44.0),
              child: Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating! ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  );
                }),
              ),
            ),

          // Comment content
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 44.0),
            child: Text(content),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 44.0),
            child: Row(
              children: [
                // Like button
                TextButton.icon(
                  icon: const Icon(Icons.thumb_up, size: 14),
                  label: Text(
                    likeCount > 0 ? likeCount.toString() : 'Like',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onLike,
                ),

                // Reply button for top-level comments
                if (onReply != null && !isReply)
                  TextButton.icon(
                    icon: const Icon(Icons.reply, size: 14),
                    label: const Text('Reply', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: onReply,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
