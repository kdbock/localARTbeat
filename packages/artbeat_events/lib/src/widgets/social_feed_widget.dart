import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/social_integration_service.dart';

/// Enhanced social feed widget for Phase 3 implementation
/// Displays events from followed artists and trending content
class SocialFeedWidget extends StatefulWidget {
  final bool showFollowedOnly;
  final VoidCallback? onEventTap;
  final EdgeInsets? padding;

  const SocialFeedWidget({
    super.key,
    this.showFollowedOnly = false,
    this.onEventTap,
    this.padding,
  });

  @override
  State<SocialFeedWidget> createState() => _SocialFeedWidgetState();
}

class _SocialFeedWidgetState extends State<SocialFeedWidget> {
  final SocialIntegrationService _socialService = SocialIntegrationService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _feedItems = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFeedItems();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreItems();
    }
  }

  Future<void> _loadFeedItems() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _socialService.getSocialFeed();
      setState(() {
        _feedItems = items;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load more items with pagination
      final moreItems = await _socialService.getSocialFeed(
        limit: 10,
        // In real implementation, pass lastDoc for pagination
      );

      if (moreItems.isEmpty) {
        setState(() {
          _hasMore = false;
        });
      } else {
        setState(() {
          _feedItems.addAll(moreItems);
        });
      }
    } on Exception {
      // Handle pagination error silently
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeedHeader(),
          const SizedBox(height: 16),
          _buildFeedContent(),
        ],
      ),
    );
  }

  Widget _buildFeedHeader() {
    return Row(
      children: [
        Icon(Icons.feed, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(width: 8),
        Text(
          'Social Feed',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadFeedItems,
          tooltip: 'Refresh feed',
        ),
      ],
    );
  }

  Widget _buildFeedContent() {
    if (_isLoading && _feedItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (_feedItems.isEmpty) {
      return _buildEmptyFeedWidget();
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _loadFeedItems,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _feedItems.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _feedItems.length) {
              return _buildLoadingIndicator();
            }

            return _buildFeedItem(_feedItems[index]);
          },
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Error loading feed',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadFeedItems, child: const Text('events_retry'.tr())),
        ],
      ),
    );
  }

  Widget _buildEmptyFeedWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timeline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No feed items yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Follow some artists to see their events in your feed',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildFeedItem(Map<String, dynamic> item) {
    final event = item['event'] as Map<String, dynamic>;
    final artist = item['artist'] as Map<String, dynamic>?;
    final socialStats = item['socialStats'] as Map<String, dynamic>;
    final isFollowing = item['isFollowing'] as bool;
    final timestamp = item['timestamp'] as DateTime;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeedItemHeader(artist, isFollowing, timestamp),
          _buildEventContent(event),
          _buildSocialActions(event['id'], socialStats),
        ],
      ),
    );
  }

  Widget _buildFeedItemHeader(
    Map<String, dynamic>? artist,
    bool isFollowing,
    DateTime timestamp,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: artist?['avatar'] != null
                ? CachedNetworkImageProvider(artist!['avatar'])
                : null,
            child: artist?['avatar'] == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artist?['name'] ?? 'Unknown Artist',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Created ${_formatTimeAgo(timestamp)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          if (!isFollowing)
            TextButton(
              onPressed: () => _followArtist(artist?['id']),
              child: const Text('events_follow'.tr()),
            ),
        ],
      ),
    );
  }

  Widget _buildEventContent(Map<String, dynamic> event) {
    final imageUrls = event['imageUrls'] as List<dynamic>?;
    final hasImages = imageUrls != null && imageUrls.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImages)
          SizedBox(
            height: 200,
            child: CachedNetworkImage(
              imageUrl: imageUrls.first.toString(),
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event['title'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event['description'],
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event['location'],
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, HH:mm').format(event['dateTime']),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialActions(String eventId, Map<String, dynamic> socialStats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            icon: Icons.favorite_border,
            label: '${socialStats['likes']}',
            onTap: () => _toggleLike(eventId),
          ),
          _buildActionButton(
            icon: Icons.comment_outlined,
            label: '${socialStats['comments']}',
            onTap: () => _showComments(eventId),
          ),
          _buildActionButton(
            icon: Icons.share_outlined,
            label: '${socialStats['shares']}',
            onTap: () => _shareEvent(eventId),
          ),
          _buildActionButton(
            icon: Icons.bookmark_border,
            label: '${socialStats['saves']}',
            onTap: () => _toggleSave(eventId),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
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

  Future<void> _followArtist(String? artistId) async {
    if (artistId == null) return;

    try {
      await _socialService.toggleFollowArtist(artistId);
      // Refresh feed to update following status
      await _loadFeedItems();
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('events_follow_error'.tr().replaceAll('{error}', e.toString()))));
      }
    }
  }

  Future<void> _toggleLike(String eventId) async {
    try {
      await _socialService.toggleEventLike(eventId);
      // In a real implementation, update the UI immediately for better UX
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('events_like_error'.tr().replaceAll('{error}', e.toString()))));
      }
    }
  }

  Future<void> _toggleSave(String eventId) async {
    try {
      await _socialService.toggleEventSave(eventId);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('events_save_error'.tr().replaceAll('{error}', e.toString()))));
      }
    }
  }

  void _shareEvent(String eventId) {
    _socialService.shareEvent(eventId, shareMethod: 'app');

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('events_shared'.tr())));
    }
  }

  void _showComments(String eventId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CommentsBottomSheet(eventId: eventId),
    );
  }
}

/// Comments bottom sheet widget
class _CommentsBottomSheet extends StatefulWidget {
  final String eventId;

  const _CommentsBottomSheet({required this.eventId});

  @override
  State<_CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<_CommentsBottomSheet> {
  final SocialIntegrationService _socialService = SocialIntegrationService();
  final TextEditingController _commentController = TextEditingController();

  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final comments = await _socialService.getEventComments(widget.eventId);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } on Exception {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    try {
      await _socialService.addEventComment(widget.eventId, comment);
      _commentController.clear();
      await _loadComments();
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('events_comment_error'.tr().replaceAll('{error}', e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Comments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                ? const Center(child: Text('events_no_comments'.tr()))
                : ListView.builder(
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      return _buildCommentItem(_comments[index]);
                    },
                  ),
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: _addComment, icon: const Icon(Icons.send)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final user = comment['user'] as Map<String, dynamic>?;
    final timestamp = comment['timestamp'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: user?['avatar'] != null
                ? CachedNetworkImageProvider(user!['avatar'])
                : null,
            child: user?['avatar'] == null
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?['name'] ?? 'Anonymous',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(comment['comment']),
                const SizedBox(height: 4),
                if (timestamp != null)
                  Text(
                    DateFormat('MMM dd, HH:mm').format(timestamp.toDate()),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
