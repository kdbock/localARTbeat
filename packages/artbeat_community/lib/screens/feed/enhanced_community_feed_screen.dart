import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EnhancedCommunityFeedScreen extends StatefulWidget {
  const EnhancedCommunityFeedScreen({
    super.key,
    this.topicFilter,
    this.artistFilter,
  });

  final String? topicFilter;
  final String? artistFilter;

  @override
  State<EnhancedCommunityFeedScreen> createState() =>
      _EnhancedCommunityFeedScreenState();
}

class _EnhancedCommunityFeedScreenState
    extends State<EnhancedCommunityFeedScreen> {
  late Future<List<_FeedItem>> _feedFuture;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _feedFuture = _loadFeed();
  }

  Future<void> _refresh() async {
    setState(() {
      _feedFuture = _loadFeed();
    });
    await _feedFuture;
  }

  Future<List<_FeedItem>> _loadFeed() async {
    final results = await Future.wait([_loadActivities(), _loadCaptures()]);

    final items = <String, _FeedItem>{};
    for (final list in results) {
      for (final item in list) {
        items.putIfAbsent(item.dedupeKey, () => item);
      }
    }

    final sorted = items.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return sorted.take(60).toList(growable: false);
  }

  Future<List<_FeedItem>> _loadActivities() async {
    try {
      final snapshot = await _firestore
          .collection('socialActivities')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map(_FeedItem.fromActivityDoc)
          .whereType<_FeedItem>()
          .where(_isRelevantActivity)
          .toList(growable: false);
    } catch (error) {
      AppLogger.error('Error loading community activities: $error');
      return [];
    }
  }

  Future<List<_FeedItem>> _loadCaptures() async {
    try {
      final snapshot = await _firestore
          .collection('captures')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map(_FeedItem.fromCaptureDoc)
          .whereType<_FeedItem>()
          .toList(growable: false);
    } catch (error) {
      AppLogger.error('Error loading community captures: $error');
      return _loadCapturesWithoutPublicIndex();
    }
  }

  Future<List<_FeedItem>> _loadCapturesWithoutPublicIndex() async {
    try {
      final snapshot = await _firestore
          .collection('captures')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      return snapshot.docs
          .where((doc) => doc.data()['isPublic'] == true)
          .map(_FeedItem.fromCaptureDoc)
          .whereType<_FeedItem>()
          .take(50)
          .toList(growable: false);
    } catch (fallbackError) {
      AppLogger.error(
        'Error loading community captures with fallback: $fallbackError',
      );
      return [];
    }
  }

  bool _isRelevantActivity(_FeedItem item) {
    final type = item.type.toLowerCase();
    final text = '${item.title} ${item.body}'.toLowerCase();
    return type.contains('capture') ||
        type.contains('discovery') ||
        type.contains('walk') ||
        type.contains('achievement') ||
        type.contains('milestone') ||
        type.contains('badge') ||
        type.contains('level') ||
        type.contains('share') ||
        type.contains('boost') ||
        text.contains('captur') ||
        text.contains('discover') ||
        text.contains('art walk') ||
        text.contains('badge') ||
        text.contains('level') ||
        text.contains('xp') ||
        text.contains('shared') ||
        text.contains('boosted');
  }

  Future<void> _toggleLike(_FeedItem item) async {
    final user = _auth.currentUser;
    if (user == null) {
      _showSnackBar('Please sign in to react to feed activity.');
      return;
    }

    try {
      final existingLike = await _firestore
          .collection('engagements')
          .where('contentId', isEqualTo: item.contentId)
          .where('contentType', isEqualTo: item.contentType)
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'like')
          .limit(1)
          .get();

      final increment = existingLike.docs.isEmpty ? 1 : -1;
      final batch = _firestore.batch();

      if (existingLike.docs.isEmpty) {
        batch.set(_firestore.collection('engagements').doc(), {
          'contentId': item.contentId,
          'contentType': item.contentType,
          'userId': user.uid,
          'type': 'like',
          'createdAt': FieldValue.serverTimestamp(),
          'metadata': {'feedTitle': item.title, 'feedType': item.type},
        });
      } else {
        batch.delete(existingLike.docs.first.reference);
      }

      _incrementFeedItemCount(batch, item, 'likeCount', increment);
      await batch.commit();
      _refreshSilently();
    } catch (error) {
      AppLogger.error('Error toggling feed like: $error');
      _showSnackBar('Could not update that reaction. Please try again.');
    }
  }

  Future<void> _showComments(_FeedItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FeedCommentsSheet(
        item: item,
        firestore: _firestore,
        auth: _auth,
        onCommentAdded: () {
          _refreshSilently();
        },
      ),
    );
  }

  Future<void> _shareItem(_FeedItem item) async {
    final user = _auth.currentUser;
    if (user == null) {
      _showSnackBar('Please sign in to share feed activity.');
      return;
    }

    try {
      final batch = _firestore.batch();
      batch.set(_firestore.collection('engagements').doc(), {
        'contentId': item.contentId,
        'contentType': item.contentType,
        'userId': user.uid,
        'type': 'share',
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': {
          'platform': 'community_feed',
          'feedTitle': item.title,
          'feedType': item.type,
        },
      });
      batch.set(_firestore.collection('socialActivities').doc(), {
        'type': 'share',
        'activityType': 'share',
        'userId': user.uid,
        'userName': user.displayName ?? user.email ?? 'Local explorer',
        'displayName': user.displayName ?? user.email ?? 'Local explorer',
        'userAvatar': user.photoURL ?? '',
        'title': item.title,
        'message': item.internalShareMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': 0,
        'commentCount': 0,
        'shareCount': 0,
        'metadata': {
          'originalContentId': item.contentId,
          'originalContentType': item.contentType,
          'originalFeedType': item.type,
          'captureId': item.captureId,
          'artTitle': item.title,
          'photoUrl': item.imageUrl,
          'imageUrl': item.imageUrl,
          'locationName': item.locationLabel,
          'sharedByName': user.displayName ?? user.email ?? 'Local explorer',
        },
      });
      _incrementFeedItemCount(batch, item, 'shareCount', 1);
      await batch.commit();
      _refreshSilently();
      _showSnackBar('Shared back to the community feed.');
    } catch (error) {
      AppLogger.error('Error sharing feed item internally: $error');
      _showSnackBar('Could not share that to the feed. Please try again.');
    }
  }

  void _refreshSilently() {
    if (!mounted) return;
    setState(() {
      _feedFuture = _loadFeed();
    });
  }

  void _incrementFeedItemCount(
    WriteBatch batch,
    _FeedItem item,
    String field,
    int amount,
  ) {
    final ref = _firestore.collection(item.sourceCollection).doc(item.id);
    batch.update(ref, {
      field: FieldValue.increment(amount),
      'engagementStats.$field': FieldValue.increment(amount),
      'engagementStats.lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF17172A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtbeatColors.backgroundDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'screen_title_community_feed'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _CommunityFeedBackground(
        child: SafeArea(
          child: FutureBuilder<List<_FeedItem>>(
            future: _feedFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: ArtbeatColors.secondaryTeal,
                  ),
                );
              }

              if (snapshot.hasError) {
                return _FeedMessage(
                  icon: Icons.error_outline,
                  title: 'Could not load the community feed',
                  body: 'Pull down to try again.',
                  onRefresh: _refresh,
                );
              }

              final items = snapshot.data ?? const <_FeedItem>[];
              return RefreshIndicator(
                color: ArtbeatColors.secondaryTeal,
                backgroundColor: const Color(0xFF17172A),
                onRefresh: _refresh,
                child: items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 36, 18, 96),
                        children: const [
                          SizedBox(height: 96),
                          _CommunityFeedEmptyState(),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 18, 14, 96),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) => _FeedCard(
                          item: items[index],
                          onLike: () => _toggleLike(items[index]),
                          onComment: () => _showComments(items[index]),
                          onShare: () => _shareItem(items[index]),
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CommunityFeedBackground extends StatelessWidget {
  const _CommunityFeedBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF060711),
            Color(0xFF12112A),
            Color(0xFF071D23),
            Color(0xFF090A12),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -92,
            right: -86,
            child: _GlowSpot(
              color: ArtbeatColors.primaryPurple.withValues(alpha: 0.34),
              size: 240,
            ),
          ),
          Positioned(
            left: -90,
            bottom: 120,
            child: _GlowSpot(
              color: ArtbeatColors.secondaryTeal.withValues(alpha: 0.24),
              size: 220,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.05,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.56),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowSpot extends StatelessWidget {
  const _GlowSpot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.item,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  final _FeedItem item;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: InkWell(
        splashColor: ArtbeatColors.secondaryTeal.withValues(alpha: 0.14),
        highlightColor: Colors.white.withValues(alpha: 0.06),
        onTap: item.captureId == null
            ? null
            : () => Navigator.of(context).pushNamed(
                AppRoutes.captureDetail,
                arguments: {'captureId': item.captureId},
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(
                    imageUrl: item.userPhotoUrl,
                    displayName: item.userName,
                    radius: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.25,
                                ),
                            children: [
                              TextSpan(
                                text: item.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(text: ' ${item.actionText}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 14,
                              color: ArtbeatColors.primaryPurple,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _relativeTime(item.createdAt),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.58,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (item.imageUrl != null)
              AspectRatio(
                aspectRatio: 1,
                child: SecureNetworkImage(
                  imageUrl: item.imageUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (item.body.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (item.locationLabel != null) ...[
                    const SizedBox(height: 10),
                    _LocationChip(label: item.locationLabel!),
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                children: [
                  _FeedActionButton(
                    icon: Icons.favorite_border,
                    label: '${item.likeCount}',
                    onPressed: onLike,
                  ),
                  _FeedActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: '${item.commentCount}',
                    onPressed: onComment,
                  ),
                  const Spacer(),
                  _FeedActionButton(
                    icon: Icons.rocket_launch_outlined,
                    label: 'Boost',
                    compact: false,
                    onPressed: onShare,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _relativeTime(DateTime dateTime) {
    final elapsed = DateTime.now().difference(dateTime);
    if (elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes}m';
    if (elapsed.inDays < 1) return '${elapsed.inHours}h';
    if (elapsed.inDays < 7) return '${elapsed.inDays}d';
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ArtbeatColors.secondaryTeal.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: ArtbeatColors.secondaryTeal.withValues(alpha: 0.34),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 14,
            color: ArtbeatColors.secondaryTeal,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedActionButton extends StatelessWidget {
  const _FeedActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.compact = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.72),
        minimumSize: compact ? const Size(56, 40) : const Size(84, 40),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}

class _FeedCommentsSheet extends StatefulWidget {
  const _FeedCommentsSheet({
    required this.item,
    required this.firestore,
    required this.auth,
    required this.onCommentAdded,
  });

  final _FeedItem item;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final VoidCallback onCommentAdded;

  @override
  State<_FeedCommentsSheet> createState() => _FeedCommentsSheetState();
}

class _FeedCommentsSheetState extends State<_FeedCommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _controller.text.trim();
    final user = widget.auth.currentUser;
    if (text.isEmpty || _isSending) return;
    if (user == null) {
      _showSheetSnackBar('Please sign in to comment.');
      return;
    }

    setState(() => _isSending = true);
    try {
      final batch = widget.firestore.batch();
      batch.set(widget.firestore.collection('engagements').doc(), {
        'contentId': widget.item.contentId,
        'contentType': widget.item.contentType,
        'userId': user.uid,
        'type': 'comment',
        'text': text,
        'comment': text,
        'userName': user.displayName ?? user.email ?? 'Local explorer',
        'userAvatar': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': 0,
      });
      batch.update(
        widget.firestore
            .collection(widget.item.sourceCollection)
            .doc(widget.item.id),
        {
          'commentCount': FieldValue.increment(1),
          'engagementStats.commentCount': FieldValue.increment(1),
          'engagementStats.lastUpdated': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
      _controller.clear();
      widget.onCommentAdded();
    } catch (error) {
      AppLogger.error('Error adding feed comment: $error');
      _showSheetSnackBar('Could not add that comment. Please try again.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSheetSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF17172A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF090A12),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    color: ArtbeatColors.secondaryTeal,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: widget.firestore
                    .collection('engagements')
                    .where('contentId', isEqualTo: widget.item.contentId)
                    .where('contentType', isEqualTo: widget.item.contentType)
                    .where('type', isEqualTo: 'comment')
                    .limit(60)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ArtbeatColors.secondaryTeal,
                      ),
                    );
                  }

                  final comments = [...?snapshot.data?.docs]
                    ..sort((a, b) {
                      final aDate = _commentDate(a.data()['createdAt']);
                      final bDate = _commentDate(b.data()['createdAt']);
                      return bDate.compareTo(aDate);
                    });
                  if (comments.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No comments yet.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.68),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                    itemCount: comments.length,
                    separatorBuilder: (_, _) =>
                        Divider(color: Colors.white.withValues(alpha: 0.08)),
                    itemBuilder: (context, index) {
                      final data = comments[index].data();
                      final name =
                          data['userName']?.toString().trim().isNotEmpty == true
                          ? data['userName'].toString()
                          : 'Local explorer';
                      final text =
                          data['text']?.toString() ??
                          data['comment']?.toString() ??
                          '';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: UserAvatar(
                          imageUrl: data['userAvatar']?.toString(),
                          displayName: name,
                          radius: 18,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          text,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            height: 1.32,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add a comment',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.48),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: ArtbeatColors.secondaryTeal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _isSending ? null : _addComment,
                    style: IconButton.styleFrom(
                      backgroundColor: ArtbeatColors.secondaryTeal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white.withValues(
                        alpha: 0.12,
                      ),
                    ),
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static DateTime _commentDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime(0);
    return DateTime(0);
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.icon,
    required this.title,
    required this.body,
    required this.onRefresh,
  });

  final IconData icon;
  final String title;
  final String body;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Icon(icon, color: ArtbeatColors.secondaryTeal, size: 44),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityFeedEmptyState extends StatelessWidget {
  const _CommunityFeedEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              color: ArtbeatColors.secondaryTeal,
              size: 44,
            ),
            const SizedBox(height: 16),
            Text(
              'community_feed_empty_title'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'community_feed_empty_body'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedItem {
  const _FeedItem({
    required this.id,
    required this.dedupeKey,
    required this.sourceCollection,
    required this.contentId,
    required this.contentType,
    required this.type,
    required this.userName,
    required this.userPhotoUrl,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.icon,
    required this.actionText,
    this.captureId,
    this.imageUrl,
    this.locationLabel,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
  });

  final String id;
  final String dedupeKey;
  final String sourceCollection;
  final String contentId;
  final String contentType;
  final String type;
  final String userName;
  final String? userPhotoUrl;
  final String title;
  final String body;
  final DateTime createdAt;
  final IconData icon;
  final String actionText;
  final String? captureId;
  final String? imageUrl;
  final String? locationLabel;
  final int likeCount;
  final int commentCount;
  final int shareCount;

  String get internalShareMessage {
    final buffer = StringBuffer()
      ..write('shared ')
      ..write(userName)
      ..write("'s ")
      ..write(type.toLowerCase().contains('capture') ? 'capture' : 'activity')
      ..write(' with the community.');
    if (body.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(body.trim());
    }
    if (locationLabel != null) {
      buffer
        ..writeln()
        ..writeln('Location: $locationLabel');
    }
    return buffer.toString();
  }

  static _FeedItem? fromActivityDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final metadata = _asMap(data['metadata']);
    final capture = _asMap(metadata?['capture']);
    final captureId = _firstString([
      metadata?['captureId'],
      capture?['id'],
      data['captureId'],
    ]);
    final type =
        _firstString([data['type'], data['activityType']]) ?? 'activity';
    final message = _firstString([data['message'], data['body']]) ?? '';
    final title =
        _firstString([
          metadata?['artTitle'],
          metadata?['walkTitle'],
          capture?['title'],
          data['title'],
        ]) ??
        _titleForType(type);

    final normalizedType = type.toLowerCase();
    return _FeedItem(
      id: doc.id,
      dedupeKey: captureId == null || normalizedType.contains('share')
          ? 'activity:${doc.id}'
          : 'capture:$captureId',
      sourceCollection: 'socialActivities',
      contentId: doc.id,
      contentType: 'social_activity',
      type: type,
      userName:
          _firstString([data['userName'], data['displayName']]) ??
          'Local explorer',
      userPhotoUrl: _firstString([data['userAvatar'], data['userPhotoUrl']]),
      title: title,
      body: message,
      createdAt:
          _dateFrom(data['timestamp']) ??
          _dateFrom(data['createdAt']) ??
          DateTime.now(),
      icon: _iconForType(type),
      actionText: _actionForType(type),
      captureId: captureId,
      imageUrl: _validUrl(
        _firstString([
          metadata?['photoUrl'],
          metadata?['imageUrl'],
          metadata?['thumbnailUrl'],
          metadata?['selfieUrl'],
          capture?['imageUrl'],
          capture?['thumbnailUrl'],
          data['imageUrl'],
        ]),
      ),
      locationLabel: _cleanLabel(
        _firstString([metadata?['locationName'], data['locationName']]),
      ),
      likeCount: _intFrom(data['likeCount']),
      commentCount: _intFrom(data['commentCount']),
      shareCount: _intFrom(data['shareCount']),
    );
  }

  static _FeedItem? fromCaptureDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final imageUrl = _validUrl(_firstString([data['imageUrl']]));
    if (imageUrl == null) return null;

    final title =
        _firstString([data['title'], data['artType']]) ??
        'New public art capture';
    final engagement = _asMap(data['engagementStats']);

    return _FeedItem(
      id: doc.id,
      dedupeKey: 'capture:${doc.id}',
      sourceCollection: 'captures',
      contentId: doc.id,
      contentType: 'capture',
      type: 'capture',
      userName:
          _firstString([data['userName'], data['userHandle']]) ??
          'Local explorer',
      userPhotoUrl: _firstString([
        data['userProfileUrl'],
        data['userPhotoUrl'],
      ]),
      title: title,
      body:
          _firstString([data['description']]) ??
          'Added a public art capture to the map.',
      createdAt: _dateFrom(data['createdAt']) ?? DateTime.now(),
      icon: Icons.camera_alt,
      actionText: 'captured public art',
      captureId: doc.id,
      imageUrl: imageUrl,
      locationLabel: _cleanLabel(
        _firstString([data['locationName'], data['address']]),
      ),
      likeCount: _intFrom(engagement?['likeCount'] ?? data['likeCount']),
      commentCount: _intFrom(
        engagement?['commentCount'] ?? data['commentCount'],
      ),
      shareCount: _intFrom(engagement?['shareCount'] ?? data['shareCount']),
    );
  }

  static String _titleForType(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('share')) return 'Shared public art';
    if (normalized.contains('walk')) return 'Art walk completed';
    if (normalized.contains('achievement')) return 'Achievement unlocked';
    if (normalized.contains('milestone')) return 'New milestone';
    if (normalized.contains('capture')) return 'New public art capture';
    if (normalized.contains('discovery')) return 'New discovery';
    return 'Community activity';
  }

  static IconData _iconForType(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('share')) return Icons.repeat_rounded;
    if (normalized.contains('walk')) return Icons.directions_walk;
    if (normalized.contains('achievement') ||
        normalized.contains('milestone') ||
        normalized.contains('badge') ||
        normalized.contains('level')) {
      return Icons.emoji_events;
    }
    if (normalized.contains('capture')) return Icons.camera_alt;
    if (normalized.contains('discovery')) return Icons.radar;
    return Icons.auto_awesome;
  }

  static String _actionForType(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('share')) return 'shared a feed highlight';
    if (normalized.contains('walk')) return 'completed an art walk';
    if (normalized.contains('achievement')) return 'unlocked an achievement';
    if (normalized.contains('milestone')) return 'reached a milestone';
    if (normalized.contains('badge')) return 'earned a badge';
    if (normalized.contains('level')) return 'leveled up';
    if (normalized.contains('capture')) return 'captured public art';
    if (normalized.contains('discovery')) return 'discovered public art';
    return 'shared app activity';
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  static String? _firstString(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  static String? _validUrl(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return null;
  }

  static String? _cleanLabel(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'unknown location') {
      return null;
    }
    return trimmed;
  }

  static DateTime? _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static int _intFrom(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
