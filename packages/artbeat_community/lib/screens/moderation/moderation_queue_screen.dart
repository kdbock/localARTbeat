import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../../models/post_model.dart';
import '../../models/comment_model.dart';
import '../../services/moderation_service.dart';
import '../../theme/community_colors.dart';

class ModerationQueueScreen extends StatefulWidget {
  const ModerationQueueScreen({super.key});

  @override
  State<ModerationQueueScreen> createState() => _ModerationQueueScreenState();
}

class _ModerationQueueScreenState extends State<ModerationQueueScreen>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  final ModerationService _moderationService = ModerationService();

  // Content to moderate
  List<PostModel> _flaggedPosts = [];
  List<CommentModel> _flaggedComments = [];

  // Selection for bulk actions
  final Set<String> _selectedPosts = {};
  final Set<String> _selectedComments = {};

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
      // Use the new moderation service
      final posts = await _moderationService.getFlaggedPosts();
      final comments = await _moderationService.getFlaggedComments();

      setState(() {
        _flaggedPosts = posts;
        _flaggedComments = comments;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading moderation queue: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approvePost(PostModel post) async {
    try {
      await _moderationService.approvePost(post.id);

      if (!mounted) return;

      setState(() {
        _flaggedPosts.remove(post);
        _selectedPosts.remove(post.id);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post approved')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approving post: $e')));
    }
  }

  Future<void> _removePost(PostModel post) async {
    try {
      await _moderationService.removePost(post.id);

      if (!mounted) return;

      setState(() {
        _flaggedPosts.remove(post);
        _selectedPosts.remove(post.id);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post removed')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing post: $e')));
    }
  }

  Future<void> _approveComment(CommentModel comment) async {
    try {
      await _moderationService.approveComment(comment.id);

      if (!mounted) return;

      setState(() {
        _flaggedComments.remove(comment);
        _selectedComments.remove(comment.id);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment approved')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approving comment: $e')));
    }
  }

  Future<void> _removeComment(CommentModel comment) async {
    try {
      await _moderationService.removeComment(comment.id);

      if (!mounted) return;

      setState(() {
        _flaggedComments.remove(comment);
        _selectedComments.remove(comment.id);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment removed')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing comment: $e')));
    }
  }

  Widget _buildPostItem(PostModel post) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: ImageUrlValidator.safeNetworkImage(
                    post.userPhotoUrl,
                  ),
                  child: !ImageUrlValidator.isValidImageUrl(post.userPhotoUrl)
                      ? Text(post.userName.isNotEmpty ? post.userName[0] : '?')
                      : null,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      post.location,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Content
            Text(post.content),
            const SizedBox(height: 8),

            // Image preview if available
            if (post.imageUrls.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ImageManagementService().getOptimizedImage(
                          imageUrl: post.imageUrls[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          isThumbnail: true,
                          errorWidget: Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey.shade300,
                            child: const Center(child: Icon(Icons.error)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),

            // Tags
            Wrap(
              spacing: 8,
              children: post.tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelStyle: const TextStyle(fontSize: 12),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),

            // Flag reason (would come from actual data in a real app)
            const Text(
              'Flagged for: Potential inappropriate content',
              style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _approvePost(post),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                  child: const Text('Approve'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _removePost(post),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: ImageUrlValidator.safeNetworkImage(
                    comment.userAvatarUrl,
                  ),
                  child:
                      !ImageUrlValidator.isValidImageUrl(comment.userAvatarUrl)
                      ? Text(
                          comment.userName.isNotEmpty
                              ? comment.userName[0]
                              : '?',
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Comment Type: ${comment.type}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Content
            Text(comment.content),
            const SizedBox(height: 8),

            // Post reference
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.article, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'On post:',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      comment.postId,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Flag reason (would come from actual data in a real app)
            const Text(
              'Flagged for: Potential offensive language',
              style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _approveComment(comment),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                  child: const Text('Approve'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _removeComment(comment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1, // Not a main navigation screen
      scaffoldKey: _scaffoldKey,
      appBar: EnhancedUniversalHeader(
        title: 'screen_title_moderation'.tr(),
        showBackButton: true,
        showSearch: false,
        showDeveloperTools: true,
        backgroundGradient: CommunityColors.communityGradient,
        titleGradient: const LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        foregroundColor: Colors.white,
      ),
      drawer: const ArtbeatDrawer(),
      child: Stack(
        children: [
          Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Posts (${_flaggedPosts.length})'),
                  Tab(text: 'Comments (${_flaggedComments.length})'),
                ],
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // Posts tab
                          _flaggedPosts.isEmpty
                              ? const Center(
                                  child: Text('No flagged posts to review'),
                                )
                              : ListView.builder(
                                  itemCount: _flaggedPosts.length,
                                  itemBuilder: (context, index) {
                                    return _buildPostItem(_flaggedPosts[index]);
                                  },
                                ),

                          // Comments tab
                          _flaggedComments.isEmpty
                              ? const Center(
                                  child: Text('No flagged comments to review'),
                                )
                              : ListView.builder(
                                  itemCount: _flaggedComments.length,
                                  itemBuilder: (context, index) {
                                    return _buildCommentItem(
                                      _flaggedComments[index],
                                    );
                                  },
                                ),
                        ],
                      ),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _loadModerationQueue,
              tooltip: 'Refresh',
              child: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
    );
  }
}
