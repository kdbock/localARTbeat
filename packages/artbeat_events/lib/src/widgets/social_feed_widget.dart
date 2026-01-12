import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart' hide DateFormat, NumberFormat;

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
      _hasMore = true;
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
    return Padding(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeedHeader(),
          const SizedBox(height: 16),
          Expanded(child: _buildFeedContent()),
        ],
      ),
    );
  }

  // HEADER

  Widget _buildFeedHeader() {
    return Row(
      children: [
        const Icon(Icons.feed, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          'events_social_feed'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadFeedItems,
          tooltip: 'events_refresh_feed'.tr(),
        ),
      ],
    );
  }

  // CONTENT

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

    return RefreshIndicator(
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
    );
  }

  // ERROR + EMPTY

  Widget _buildErrorWidget() {
    return Center(
      child: _GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(
              'events_feed_error_title'.tr(), // "Error loading feed"
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadFeedItems,
              child: Text(
                'events_retry'.tr(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFeedWidget() {
    return Center(
      child: _GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timeline,
              size: 48,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              'events_no_feed_items'.tr(), // "No feed items yet"
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'events_follow_artists_hint'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  // FEED ITEM

  Widget _buildFeedItem(Map<String, dynamic> item) {
    final event = item['event'] as Map<String, dynamic>;
    final artist = item['artist'] as Map<String, dynamic>?;
    final socialStats = item['socialStats'] as Map<String, dynamic>;
    final isFollowing = item['isFollowing'] as bool;
    final timestamp = item['timestamp'] as DateTime;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeedItemHeader(artist, isFollowing, timestamp),
            _buildEventContent(event),
            _buildSocialActions(event['id'] as String, socialStats),
          ],
        ),
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
                ? CachedNetworkImageProvider(artist!['avatar'] as String)
                : null,
            child: artist?['avatar'] == null
                ? const Icon(Icons.person, color: Colors.white70)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artist?['name'] ?? 'events_unknown_artist'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimeAgo(timestamp),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (!isFollowing)
            TextButton(
              onPressed: () => _followArtist(artist?['id'] as String?),
              child: Text(
                'events_follow'.tr(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventContent(Map<String, dynamic> event) {
    final imageUrls = event['imageUrls'] as List<dynamic>?;
    final hasImages = imageUrls != null && imageUrls.isNotEmpty;
    final dateTime = event['dateTime'] as DateTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImages)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(26),
              topRight: Radius.circular(26),
            ),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: imageUrls.first.toString(),
                fit: BoxFit.cover,
                memCacheWidth: 600,
                placeholder: (context, url) => Container(
                  color: Colors.black.withValues(alpha: 0.2),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Icon(Icons.error, color: Colors.white70),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event['title']?.toString() ?? '',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event['description']?.toString() ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event['location']?.toString() ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, HH:mm').format(dateTime),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
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
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.8)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TIME AGO

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'events_time_days_ago'.tr(
        namedArgs: {'days': difference.inDays.toString()},
      );
    } else if (difference.inHours > 0) {
      return 'events_time_hours_ago'.tr(
        namedArgs: {'hours': difference.inHours.toString()},
      );
    } else if (difference.inMinutes > 0) {
      return 'events_time_minutes_ago'.tr(
        namedArgs: {'minutes': difference.inMinutes.toString()},
      );
    } else {
      return 'events_time_just_now'.tr();
    }
  }

  // ACTIONS

  Future<void> _followArtist(String? artistId) async {
    if (artistId == null) return;

    try {
      await _socialService.toggleFollowArtist(artistId);
      await _loadFeedItems();
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'events_follow_error'.tr().replaceAll('{error}', e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleLike(String eventId) async {
    try {
      await _socialService.toggleEventLike(eventId);
      // You could optimistically update local state here
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'events_like_error'.tr().replaceAll('{error}', e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleSave(String eventId) async {
    try {
      await _socialService.toggleEventSave(eventId);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'events_save_error'.tr().replaceAll('{error}', e.toString()),
            ),
          ),
        );
      }
    }
  }

  void _shareEvent(String eventId) {
    _socialService.shareEvent(eventId, shareMethod: 'app');

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('events_shared'.tr())));
    }
  }

  void _showComments(String eventId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'events_comment_error'.tr().replaceAll('{error}', e.toString()),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: SafeBackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: media.size.height * 0.7,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: media.viewInsets.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Text(
                    'events_comments_title'.tr(), // "Comments"
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Divider(color: Colors.white.withValues(alpha: 0.18)),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _comments.isEmpty
                    ? Center(
                        child: Text(
                          'events_no_comments'.tr(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          return _buildCommentItem(_comments[index]);
                        },
                      ),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.18)),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      maxLines: null,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'events_add_comment_hint'.tr(),
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22)),
                          borderSide: BorderSide(color: Color(0xFF22D3EE)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addComment,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final user = comment['user'] as Map<String, dynamic>?;
    final timestamp = comment['timestamp'];

    DateTime? ts;
    if (timestamp is DateTime) {
      ts = timestamp;
    } else if (timestamp != null) {
      // Firestore Timestamp case: timestamp.toDate()
      try {
        ts = (timestamp as dynamic).toDate() as DateTime;
      } on Exception catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: user?['avatar'] != null
                ? CachedNetworkImageProvider(user!['avatar'] as String)
                : null,
            child: user?['avatar'] == null
                ? const Icon(Icons.person, size: 16, color: Colors.white70)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?['name'] ?? 'events_anonymous'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  comment['comment']?.toString() ?? '',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 4),
                if (ts != null)
                  Text(
                    DateFormat('MMM dd, HH:mm').format(ts),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
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

// --------- LOCAL GLASS CARD (design guide style) ---------

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SafeBackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: child,
        ),
      ),
    );
  }
}
