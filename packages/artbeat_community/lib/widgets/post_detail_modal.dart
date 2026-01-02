import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';

import '../models/post_model.dart';
import '../models/group_models.dart';
import '../models/comment_model.dart';
import '../widgets/group_post_card.dart';

class PostDetailModal extends StatefulWidget {
  final BaseGroupPost post;

  const PostDetailModal({super.key, required this.post});

  @override
  State<PostDetailModal> createState() => _PostDetailModalState();

  static Future<void> show(BuildContext context, BaseGroupPost post) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostDetailModal(post: post),
    );
  }

  static Future<void> showFromPostModel(
    BuildContext context,
    PostModel postModel,
  ) {
    // Create a wrapper BaseGroupPost from PostModel
    final wrappedPost = _PostModelWrapper(postModel);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostDetailModal(post: wrappedPost),
    );
  }
}

/// Wrapper class to adapt PostModel to ArtistGroupPost interface
class _PostModelWrapper extends ArtistGroupPost {
  _PostModelWrapper(PostModel postModel)
    : super(
        id: postModel.id,
        userId: postModel.userId,
        userName: postModel.userName,
        userPhotoUrl: postModel.userPhotoUrl,
        content: postModel.content,
        imageUrls: postModel.imageUrls,
        tags: postModel.tags,
        location: postModel.location,
        createdAt: postModel.createdAt,
        applauseCount: postModel.applauseCount,
        commentCount: postModel.commentCount,
        shareCount: postModel.shareCount,
        isPublic: postModel.isPublic,
        isUserVerified: postModel.isUserVerified,
        // Artist-specific properties with default values
        artistId: postModel.userId, // Use userId as artistId
        artworkTitle: '', // Default empty since PostModel doesn't have this
        artworkDescription:
            '', // Default empty since PostModel doesn't have this
        medium: '', // Default empty since PostModel doesn't have this
        style: '', // Default empty since PostModel doesn't have this
        price: 0.0, // Default price
        isForSale: false, // Default not for sale
        techniques: [], // Default empty techniques
      );
}

class _PostDetailModalState extends State<PostDetailModal> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();

  List<CommentModel> _comments = [];
  bool _isLoadingComments = true;
  bool _showComments = false;
  bool _isSendingComment = false;
  String? _replyingToCommentId;
  String? _replyingToUserName;

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Determine the group type based on the post type
  GroupType _getGroupType(BaseGroupPost post) {
    if (post is _PostModelWrapper) {
      // For wrapped PostModel, default to artist group type
      return GroupType.artist;
    } else if (post is ArtistGroupPost) {
      return GroupType.artist;
    } else if (post is EventGroupPost) {
      return GroupType.event;
    } else if (post is ArtWalkAdventurePost) {
      return GroupType.artWalk;
    } else if (post is ArtistWantedPost) {
      return GroupType.artistWanted;
    }
    // Default to artist if we can't determine the type
    return GroupType.artist;
  }

  /// Create an updated post with current comment count
  BaseGroupPost _createUpdatedPostWithCounts() {
    // Create a copy of the post with updated comment count
    if (widget.post is _PostModelWrapper) {
      // For wrapped PostModel, create a new wrapper with updated counts
      final wrapper = widget.post as _PostModelWrapper;
      return _PostModelWrapper(
        PostModel(
          id: wrapper.id,
          userId: wrapper.userId,
          userName: wrapper.userName,
          userPhotoUrl: wrapper.userPhotoUrl,
          content: wrapper.content,
          imageUrls: wrapper.imageUrls,
          tags: wrapper.tags,
          location: wrapper.location,
          createdAt: wrapper.createdAt,
          engagementStats: EngagementStats(
            likeCount: wrapper.applauseCount,
            commentCount: _comments.length, // Use current comment count
            shareCount: wrapper.shareCount,
            lastUpdated: DateTime.now(),
          ),
          isPublic: wrapper.isPublic,
          isUserVerified: wrapper.isUserVerified,
        ),
      );
    } else if (widget.post is ArtistGroupPost) {
      final artistPost = widget.post as ArtistGroupPost;
      return ArtistGroupPost(
        id: artistPost.id,
        userId: artistPost.userId,
        userName: artistPost.userName,
        userPhotoUrl: artistPost.userPhotoUrl,
        content: artistPost.content,
        imageUrls: artistPost.imageUrls,
        tags: artistPost.tags,
        location: artistPost.location,
        createdAt: artistPost.createdAt,
        applauseCount: artistPost.applauseCount,
        commentCount: _comments.length, // Use current comment count
        shareCount: artistPost.shareCount,
        isPublic: artistPost.isPublic,
        isUserVerified: artistPost.isUserVerified,
        artistId: artistPost.artistId,
        artworkTitle: artistPost.artworkTitle,
        artworkDescription: artistPost.artworkDescription,
        medium: artistPost.medium,
        style: artistPost.style,
        price: artistPost.price,
        isForSale: artistPost.isForSale,
        techniques: artistPost.techniques,
      );
    }
    // For other post types, just return the original post
    // (could be extended for other types if needed)
    return widget.post;
  }

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      // Load comments from the post's comments subcollection to respect
      // Firestore security rules which allow access to posts/{postId}/comments
      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .get();

      final comments = commentsSnapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();

      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading comments: $e');
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
        });
      }
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSendingComment) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isSendingComment = true;
    });

    try {
      // Get user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};
      final userName = userData['displayName'] as String? ?? 'Anonymous';
      final userPhotoUrl = userData['profileImageUrl'] as String? ?? '';

      // Create comment data
      final commentData = {
        'postId': widget.post.id,
        'userId': user.uid,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'parentCommentId': _replyingToCommentId,
        'likes': 0,
        'isReported': false,
      };

      // Add comment to the post's comments subcollection
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .collection('comments')
          .add(commentData);

      // Increment the comment count on the parent post document
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .update({'commentCount': FieldValue.increment(1)});

      // Clear input and reply state
      _commentController.clear();
      _clearReply();

      // Reload comments
      await _loadComments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added successfully!')),
        );
      }
    } catch (e) {
      AppLogger.error('Error adding comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding comment: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingComment = false;
        });
      }
    }
  }

  void _replyToComment(CommentModel comment) {
    setState(() {
      _replyingToCommentId = comment.id;
      _replyingToUserName = comment.userName;
    });

    // Focus on comment input
    FocusScope.of(context).requestFocus();
  }

  void _clearReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
  }

  void _reportComment(CommentModel comment) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Comment'),
        content: const Text(
          'Are you sure you want to report this comment for inappropriate content?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _submitCommentReport(comment);
            },
            child: const Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCommentReport(CommentModel comment) async {
    try {
      // Update the comment document in the post's comments subcollection
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .collection('comments')
          .doc(comment.id)
          .update({'isReported': true});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment reported successfully')),
        );
      }
    } catch (e) {
      AppLogger.error('Error reporting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error reporting comment: $e')));
      }
    }
  }

  void _handleApplause(BaseGroupPost post) {
    // Handle post applause action
    AppLogger.info('Applause for post: ${post.id}');
  }

  void _handleFeature(BaseGroupPost post) {
    // Handle post feature action
    AppLogger.info('Feature post: ${post.id}');
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

  void _handleShare(BaseGroupPost post) {
    // Handle post share action
    AppLogger.info('Share post: ${post.id}');
  }

  void _navigateToSearch(BuildContext context) {
    Navigator.pushNamed(context, '/community/search');
  }

  void _navigateToMessaging(BuildContext context) {
    Navigator.pushNamed(context, '/community/messaging');
  }

  void _openDeveloperTools(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Developer Tools'),
        content: const Text(
          'Developer tools will be available in a future update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> commentsWidgets = _showComments ? [
      const Divider(),
      Flexible(
        child: _isLoadingComments
            ? const Center(child: CircularProgressIndicator())
            : _comments.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'post_detail_modal_no_comments'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _comments.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: _buildCommentItem(comment),
                  );
                },
              ),
      ),

      // Comment input - moved outside the Flexible widget
      const Divider(),
      Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingToCommentId != null) ...[
              GlassCard(
                padding: const EdgeInsets.all(12),
                borderRadius: 16,
                child: Row(
                  children: [
                    const Icon(
                      Icons.reply,
                      color: Color(0xFF22D3EE),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'post_detail_modal_replying_to'.tr().replaceAll('{user}', _replyingToUserName ?? ''),
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFF22D3EE),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _clearReply,
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF22D3EE),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: GlassInputDecoration(
                      hintText: 'post_detail_modal_add_comment_hint'.tr(),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addComment(),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _isSendingComment ? null : _addComment,
                  icon: _isSendingComment
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
                          ),
                        )
                      : const Icon(Icons.send, color: Color(0xFF22D3EE)),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
              ],
            ),
          ],
        ),
      ),
    ] : [Container()];

    return GlassCard(
      margin: EdgeInsets.zero,
      borderRadius: 24,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header with gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE), Color(0xFF34D399)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Text(
                      'post_detail_modal_title'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    // Search icon
                    IconButton(
                      onPressed: () => _navigateToSearch(context),
                      icon: const Icon(Icons.search, color: Colors.white),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),
                  // Messaging icon
                  IconButton(
                    onPressed: () => _navigateToMessaging(context),
                    icon: const Icon(Icons.message, color: Colors.white),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                  // Developer icon
                  IconButton(
                    onPressed: () => _openDeveloperTools(context),
                    icon: const Icon(Icons.developer_mode, color: Colors.white),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                  // Close icon
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                ],
              ),
            ),
          ),

          // Content - Use Flexible instead of Expanded to prevent overflow
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Post content - wrap in a flexible container
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: GroupPostCard(
                        post: _createUpdatedPostWithCounts(),
                        groupType: _getGroupType(widget.post),
                        onAppreciate: () => _handleApplause(widget.post),
                        onComment: () {
                          setState(() {
                            _showComments = !_showComments;
                          });
                        },
                        onFeature: () => _handleFeature(widget.post),
                        onGift: () => _handleGift(widget.post),
                        onShare: () => _handleShare(widget.post),
                        isCompact: true,
                      ),
                    ),
                  ),
                ),

                // Comments section
                ...commentsWidgets,
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildCommentItem(CommentModel comment) {
    final isReply = comment.parentCommentId.isNotEmpty;

    return GlassCard(
      margin: EdgeInsets.only(left: isReply ? 32 : 0, bottom: 8),
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      glassOpacity: isReply ? 0.06 : 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment header
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: ImageUrlValidator.safeNetworkImage(
                  comment.userAvatarUrl,
                ),
                child: !ImageUrlValidator.isValidImageUrl(comment.userAvatarUrl)
                    ? const Icon(Icons.person, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName,
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _formatTimeAgo(comment.createdAt.toDate()),
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (comment.userId != _currentUserId)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'reply') {
                      _replyToComment(comment);
                    } else if (value == 'report') {
                      _reportComment(comment);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'reply',
                      child: Row(
                        children: [
                          const Icon(Icons.reply, size: 16, color: Color(0xFF22D3EE)),
                          const SizedBox(width: 8),
                          Text(
                            'post_detail_modal_reply'.tr(),
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          const Icon(Icons.flag, size: 16, color: Color(0xFFFF3D8D)),
                          const SizedBox(width: 8),
                          Text(
                            'post_detail_modal_report'.tr(),
                            style: GoogleFonts.spaceGrotesk(
                              color: const Color(0xFFFF3D8D),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert, size: 16, color: Colors.white70),
                  color: Colors.black.withValues(alpha: 0.8),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Comment content
          Text(
            comment.content,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          // Comment actions
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  // Handle like comment
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '0', // Since CommentModel doesn't have likes field
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
        ]),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
}
