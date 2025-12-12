import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';

class ProfileMentionsScreen extends StatefulWidget {
  const ProfileMentionsScreen({super.key});

  @override
  State<ProfileMentionsScreen> createState() => _ProfileMentionsScreenState();
}

class _ProfileMentionsScreenState extends State<ProfileMentionsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _mentions = [];
  List<Map<String, dynamic>> _tags = [];
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMentions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMentions() async {
    try {
      final user = Provider.of<UserService>(context, listen: false).currentUser;
      if (user != null) {
        final [mentionsData, tagsData, commentsData] = await Future.wait([
          _getMentions(user.uid),
          _getTags(user.uid),
          _getCommentMentions(user.uid),
        ]);

        setState(() {
          _mentions = mentionsData;
          _tags = tagsData;
          _comments = commentsData;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading mentions: $e')));
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getMentions(String userId) async {
    // In a real implementation, fetch from Firestore where user was mentioned
    return [
      {
        'id': '1',
        'type': 'post_mention',
        'authorId': 'user2',
        'authorName': 'Jane Artist',
        'authorAvatar': null,
        'content': 'Amazing collaboration with @$userId on this piece!',
        'postId': 'post123',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'isRead': false,
      },
      {
        'id': '2',
        'type': 'story_mention',
        'authorId': 'user3',
        'authorName': 'Creative Studio',
        'authorAvatar': null,
        'content': 'Featuring work by @$userId in our latest collection',
        'storyId': 'story456',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)),
        'isRead': true,
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _getTags(String userId) async {
    // In a real implementation, fetch photo/artwork tags from Firestore
    return [
      {
        'id': '1',
        'type': 'photo_tag',
        'authorId': 'user4',
        'authorName': 'Art Gallery',
        'authorAvatar': null,
        'content': 'Tagged you in a photo',
        'photoId': 'photo789',
        'photoUrl': 'https://example.com/photo.jpg',
        'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
        'isRead': false,
      },
      {
        'id': '2',
        'type': 'artwork_tag',
        'authorId': 'user5',
        'authorName': 'Art Collector',
        'authorAvatar': null,
        'content': 'Tagged you in artwork showcase',
        'artworkId': 'artwork101',
        'artworkUrl': 'https://example.com/artwork.jpg',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)),
        'isRead': true,
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _getCommentMentions(String userId) async {
    // In a real implementation, fetch comment mentions from Firestore
    return [
      {
        'id': '1',
        'type': 'comment_mention',
        'authorId': 'user6',
        'authorName': 'Art Enthusiast',
        'authorAvatar': null,
        'content': 'Hey @$userId, what do you think about this technique?',
        'postId': 'post999',
        'postTitle': 'Oil Painting Tutorial',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
        'isRead': false,
      },
      {
        'id': '2',
        'type': 'comment_reply',
        'authorId': 'user7',
        'authorName': 'Fellow Artist',
        'authorAvatar': null,
        'content': '@$userId I totally agree with your perspective!',
        'postId': 'post888',
        'postTitle': 'Digital Art Discussion',
        'timestamp': DateTime.now().subtract(const Duration(hours: 8)),
        'isRead': true,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile_mentions_title'.tr()),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'profile_mentions_title'.tr(),
              icon: _mentions.any((m) => !(m['isRead'] as bool))
                  ? const Badge(child: Icon(Icons.alternate_email))
                  : const Icon(Icons.alternate_email),
            ),
            Tab(
              text: 'Tags',
              icon: _tags.any((t) => !(t['isRead'] as bool))
                  ? const Badge(child: Icon(Icons.local_offer))
                  : const Icon(Icons.local_offer),
            ),
            Tab(
              text: 'Comments',
              icon: _comments.any((c) => !(c['isRead'] as bool))
                  ? const Badge(child: Icon(Icons.comment))
                  : const Icon(Icons.comment),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMentions),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMentionsTab(),
                _buildTagsTab(),
                _buildCommentsTab(),
              ],
            ),
    );
  }

  Widget _buildMentionsTab() {
    if (_mentions.isEmpty) {
      return _buildEmptyState(
        'No Mentions',
        'You haven\'t been mentioned in any posts or stories yet.',
        Icons.alternate_email,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMentions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mentions.length,
        itemBuilder: (context, index) {
          final mention = _mentions[index];
          return _buildMentionCard(mention);
        },
      ),
    );
  }

  Widget _buildTagsTab() {
    if (_tags.isEmpty) {
      return _buildEmptyState(
        'No Tags',
        'You haven\'t been tagged in any photos or artworks yet.',
        Icons.local_offer,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMentions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tags.length,
        itemBuilder: (context, index) {
          final tag = _tags[index];
          return _buildTagCard(tag);
        },
      ),
    );
  }

  Widget _buildCommentsTab() {
    if (_comments.isEmpty) {
      return _buildEmptyState(
        'No Comment Mentions',
        'You haven\'t been mentioned in any comments yet.',
        Icons.comment,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMentions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _comments.length,
        itemBuilder: (context, index) {
          final comment = _comments[index];
          return _buildCommentCard(comment);
        },
      ),
    );
  }

  Widget _buildMentionCard(Map<String, dynamic> mention) {
    final isRead = mention['isRead'] as bool;
    final timestamp = mention['timestamp'] as DateTime;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 3,
      child: InkWell(
        onTap: () => _handleMentionTap(mention),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: !isRead ? Border.all(color: Colors.blue, width: 2) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: mention['authorAvatar'] != null
                        ? NetworkImage(mention['authorAvatar'].toString())
                        : null,
                    child: mention['authorAvatar'] == null
                        ? Text(
                            mention['authorName'].toString()[0].toUpperCase(),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              mention['authorName'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildMentionTypeChip(mention['type'].toString()),
                          ],
                        ),
                        Text(
                          _formatTimestamp(timestamp),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                mention['content'].toString(),
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _viewMentionSource(mention),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('View', style: TextStyle(fontSize: 12)),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.reply, size: 20),
                        onPressed: () => _replyToMention(mention),
                        tooltip: 'Reply',
                      ),
                      IconButton(
                        icon: Icon(
                          isRead
                              ? Icons.mark_email_read
                              : Icons.mark_email_unread,
                          size: 20,
                        ),
                        onPressed: () => _toggleReadStatus(mention),
                        tooltip: isRead ? 'Mark as unread' : 'Mark as read',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagCard(Map<String, dynamic> tag) {
    final isRead = tag['isRead'] as bool;
    final timestamp = tag['timestamp'] as DateTime;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 3,
      child: InkWell(
        onTap: () => _handleTagTap(tag),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: !isRead ? Border.all(color: Colors.orange, width: 2) : null,
          ),
          child: Row(
            children: [
              if (tag['photoUrl'] != null || tag['artworkUrl'] != null)
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(
                        (tag['photoUrl'] ?? tag['artworkUrl']).toString(),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tag['authorName'].toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildTagTypeChip(tag['type'].toString()),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tag['content'].toString(),
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: Icon(
                      isRead ? Icons.visibility : Icons.visibility_off,
                      size: 20,
                    ),
                    onPressed: () => _toggleReadStatus(tag),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    final isRead = comment['isRead'] as bool;
    final timestamp = comment['timestamp'] as DateTime;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 3,
      child: InkWell(
        onTap: () => _handleCommentTap(comment),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: !isRead ? Border.all(color: Colors.green, width: 2) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: comment['authorAvatar'] != null
                        ? NetworkImage(comment['authorAvatar'].toString())
                        : null,
                    child: comment['authorAvatar'] == null
                        ? Text(
                            comment['authorName'].toString()[0].toUpperCase(),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment['authorName'].toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (comment['postTitle'] != null)
                          Text(
                            'in "${comment['postTitle']}"',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                  if (!isRead)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  comment['content'].toString(),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _viewCommentSource(comment),
                    icon: const Icon(Icons.chat, size: 16),
                    label: const Text(
                      'View Conversation',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                      size: 18,
                    ),
                    onPressed: () => _toggleReadStatus(comment),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadMentions,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentionTypeChip(String type) {
    String label;
    Color color;

    switch (type) {
      case 'post_mention':
        label = 'Post';
        color = Colors.blue;
        break;
      case 'story_mention':
        label = 'Story';
        color = Colors.purple;
        break;
      default:
        label = 'Mention';
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Color.fromRGBO(
          (color.r * 255).round(),
          (color.g * 255).round(),
          (color.b * 255).round(),
          0.1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTagTypeChip(String type) {
    String label;
    Color color;

    switch (type) {
      case 'photo_tag':
        label = 'Photo';
        color = Colors.orange;
        break;
      case 'artwork_tag':
        label = 'Artwork';
        color = Colors.red;
        break;
      default:
        label = 'Tag';
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Color.fromRGBO(
          (color.r * 255).round(),
          (color.g * 255).round(),
          (color.b * 255).round(),
          0.1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _handleMentionTap(Map<String, dynamic> mention) {
    _toggleReadStatus(mention);
    // Navigate to the actual post/story
  }

  void _handleTagTap(Map<String, dynamic> tag) {
    _toggleReadStatus(tag);
    // Navigate to the tagged photo/artwork
  }

  void _handleCommentTap(Map<String, dynamic> comment) {
    _toggleReadStatus(comment);
    // Navigate to the comment thread
  }

  void _viewMentionSource(Map<String, dynamic> mention) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${mention['type']} source')),
    );
  }

  void _viewCommentSource(Map<String, dynamic> comment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening comment in ${comment['postTitle']}')),
    );
  }

  void _replyToMention(Map<String, dynamic> mention) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reply functionality coming soon')),
    );
  }

  void _toggleReadStatus(Map<String, dynamic> item) {
    setState(() {
      item['isRead'] = !(item['isRead'] as bool);
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (final mention in _mentions) {
        mention['isRead'] = true;
      }
      for (final tag in _tags) {
        tag['isRead'] = true;
      }
      for (final comment in _comments) {
        comment['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('profile_mentions_all_read'.tr())));
  }
}
