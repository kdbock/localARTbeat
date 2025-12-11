import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_events/artbeat_events.dart' as events;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Screen for displaying an artist's community feed
/// Shows their posts, artwork updates, events, and community interactions
class ArtistCommunityFeedScreen extends StatefulWidget {
  final core.ArtistProfileModel artist;

  const ArtistCommunityFeedScreen({super.key, required this.artist});

  @override
  State<ArtistCommunityFeedScreen> createState() =>
      _ArtistCommunityFeedScreenState();
}

class _ArtistCommunityFeedScreenState extends State<ArtistCommunityFeedScreen> {
  final artwork.ArtworkService _artworkService = artwork.ArtworkService();
  final events.EventService _eventService = events.EventService();

  bool _isLoading = false;
  List<Map<String, dynamic>> _feedItems = [];
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed({bool loadMore = false}) async {
    if (_isLoading || (!loadMore && _feedItems.isNotEmpty)) return;

    setState(() => _isLoading = true);

    try {
      // Load various types of content for the artist's feed
      final newItems = <Map<String, dynamic>>[];

      // Load recent artwork
      final artworkItems = await _loadArtworkItems();
      newItems.addAll(artworkItems);

      // Load recent events
      final eventItems = await _loadEventItems();
      newItems.addAll(eventItems);

      // Load community posts/updates
      final communityItems = await _loadCommunityItems();
      newItems.addAll(communityItems);

      // Sort by timestamp (most recent first)
      newItems.sort((a, b) {
        final aTime = a['timestamp'] as DateTime?;
        final bTime = b['timestamp'] as DateTime?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      setState(() {
        if (loadMore) {
          _feedItems.addAll(newItems);
        } else {
          _feedItems = newItems;
        }
        _hasMoreData = newItems.length >= 20; // Assuming page size of 20
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'community_artist_community_feed_error_error_loading_feed'.tr(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadArtworkItems() async {
    final items = <Map<String, dynamic>>[];

    try {
      final artworks = await _artworkService.getArtworkByArtistProfileId(
        widget.artist.id,
      );

      for (final art in artworks.take(10)) {
        // Take first 10 artworks
        items.add({
          'type': 'artwork',
          'id': art.id,
          'title': art.title,
          'description': art.description,
          'imageUrl': art.imageUrl,
          'timestamp': art.createdAt,
          'likes': art.likeCount,
          'comments': art.commentCount,
          'data': art,
        });
      }
    } catch (e) {
      debugPrint('Error loading artwork items: $e');
    }

    return items;
  }

  Future<List<Map<String, dynamic>>> _loadEventItems() async {
    final items = <Map<String, dynamic>>[];

    try {
      final artistEvents = await _eventService.getEventsByArtist(
        widget.artist.userId,
      );

      for (final event in artistEvents.take(5)) {
        // Take first 5 events
        items.add({
          'type': 'event',
          'id': event.id,
          'title': event.title,
          'description': event.description,
          'imageUrl': event.imageUrls.isNotEmpty ? event.imageUrls.first : null,
          'timestamp': event.dateTime,
          'location': event.location,
          'data': event,
        });
      }
    } catch (e) {
      debugPrint('Error loading event items: $e');
    }

    return items;
  }

  Future<List<Map<String, dynamic>>> _loadCommunityItems() async {
    final items = <Map<String, dynamic>>[];

    try {
      // Load posts/updates from Firestore
      final postsQuery = FirebaseFirestore.instance
          .collection('artistPosts')
          .where('artistId', isEqualTo: widget.artist.userId)
          .orderBy('createdAt', descending: true)
          .limit(10);

      final postsSnapshot = await postsQuery.get();

      for (final doc in postsSnapshot.docs) {
        final data = doc.data();
        items.add({
          'type': 'post',
          'id': doc.id,
          'title': data['title'] ?? 'Artist Update',
          'content': data['content'] ?? '',
          'imageUrl': data['imageUrl'],
          'timestamp': (data['createdAt'] as Timestamp?)?.toDate(),
          'likes': data['likesCount'] ?? 0,
          'comments': data['commentsCount'] ?? 0,
          'data': data,
        });
      }
    } catch (e) {
      debugPrint('Error loading community items: $e');
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: -1, // Detail screen
      appBar: core.EnhancedUniversalHeader(
        title: '${widget.artist.displayName}\'s Feed',
        showBackButton: true,
      ),
      child: Container(
        color: Colors.grey[50],
        child: SafeArea(child: _buildFeedContent()),
      ),
    );
  }

  Widget _buildFeedContent() {
    if (_feedItems.isEmpty && _isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'community_artist_community_feed_loading_loading_artist_feed'
                  .tr(),
            ),
          ],
        ),
      );
    }

    if (_feedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.feed, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'art_walk_artist_feed_no_posts'.tr().replaceAll('{artistName}', widget.artist.displayName),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadFeed(loadMore: false),
      child: ListView.builder(
        itemCount: _feedItems.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _feedItems.length) {
            // Load more indicator
            if (_isLoading) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            } else {
              // Load more button
              return Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => _loadFeed(loadMore: true),
                  child: Text(
                    'community_artist_community_feed_text_load_more'.tr(),
                  ),
                ),
              );
            }
          }

          final item = _feedItems[index];
          return _buildFeedItem(item);
        },
      ),
    );
  }

  Widget _buildFeedItem(Map<String, dynamic> item) {
    switch (item['type']) {
      case 'artwork':
        return _buildArtworkItem(item);
      case 'event':
        return _buildEventItem(item);
      case 'post':
        return _buildPostItem(item);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildArtworkItem(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: core.UserAvatar(
              imageUrl: widget.artist.profileImageUrl,
              displayName: widget.artist.displayName,
              radius: 20,
            ),
            title: Text(
              widget.artist.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'art_walk_artist_feed_posted_artwork'.tr().replaceAll('{date}', DateFormat('MMM d').format(item['timestamp'] as DateTime)),
            ),
          ),

          // Artwork image
          if (item['imageUrl'] != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                item['imageUrl'] as String,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey[300]),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item['description'] != null &&
                    (item['description'] as String).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(item['description'] as String),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('${item['likes']}'),
                    const SizedBox(width: 16),
                    const Icon(Icons.comment, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${item['comments']}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: core.UserAvatar(
              imageUrl: widget.artist.profileImageUrl,
              displayName: widget.artist.displayName,
              radius: 20,
            ),
            title: Text(
              widget.artist.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'art_walk_artist_feed_created_event'.tr().replaceAll('{date}', DateFormat('MMM d').format(item['timestamp'] as DateTime)),
            ),
          ),

          // Event content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item['description'] != null &&
                    (item['description'] as String).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(item['description'] as String),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                      Expanded(child: Text(item['location'] as String? ?? 'art_walk_artist_feed_tbd'.tr())),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat(
                        'MMM d, yyyy • h:mm a',
                      ).format(item['timestamp'] as DateTime),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: core.UserAvatar(
              imageUrl: widget.artist.profileImageUrl,
              displayName: widget.artist.displayName,
              radius: 20,
            ),
            title: Text(
              widget.artist.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'art_walk_artist_feed_posted_update'.tr().replaceAll('{date}', item['timestamp'] != null ? DateFormat('MMM d').format(item['timestamp'] as DateTime) : 'art_walk_artist_feed_recently'.tr()),
            ),
          ),

          // Post content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item['title'] != null &&
                    (item['title'] as String).isNotEmpty) ...[
                  Text(
                    item['title'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(item['content'] as String? ?? ''),
                if (item['imageUrl'] != null &&
                    (item['imageUrl'] as String).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item['imageUrl'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.grey[300]),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('${item['likes'] ?? 0}'),
                    const SizedBox(width: 16),
                    const Icon(Icons.comment, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${item['comments'] ?? 0}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
