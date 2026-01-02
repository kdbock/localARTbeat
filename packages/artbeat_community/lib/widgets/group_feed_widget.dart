import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

import '../models/group_models.dart';
import '../models/post_model.dart';
import '../screens/feed/comments_screen.dart';
import 'group_post_card.dart';

/// Widget that displays the feed for a specific group type
class GroupFeedWidget extends StatefulWidget {
  final GroupType groupType;

  const GroupFeedWidget({super.key, required this.groupType});

  @override
  State<GroupFeedWidget> createState() => _GroupFeedWidgetState();
}

class _GroupFeedWidgetState extends State<GroupFeedWidget>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final List<BaseGroupPost> _posts = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _errorMessage;
  DocumentSnapshot? _lastDocument;

  static const int _postsPerPage = 10;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _loadMorePosts();
    }
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _posts.clear();
    });

    try {
      AppLogger.info('Loading ${widget.groupType.value} group posts...');

      // Query posts for this specific group type
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('groupType', isEqualTo: widget.groupType.value)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      if (!mounted) return;

      if (postsSnapshot.docs.isNotEmpty) {
        _lastDocument = postsSnapshot.docs.last;

        final loadedPosts = <BaseGroupPost>[];
        for (final doc in postsSnapshot.docs) {
          final post = _createPostFromDocument(doc);
          if (post != null) {
            loadedPosts.add(post);
          }
        }

        debugPrint(
          'Loaded ${loadedPosts.length} ${widget.groupType.value} posts',
        );

        if (mounted) {
          setState(() {
            _posts.addAll(loadedPosts);
            _isLoading = false;
          });
        }
      } else {
        AppLogger.info('No ${widget.groupType.value} posts found');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      AppLogger.error('Error loading ${widget.groupType.value} posts: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load posts: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || _lastDocument == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('groupType', isEqualTo: widget.groupType.value)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_postsPerPage)
          .get();

      if (!mounted) return;

      if (postsSnapshot.docs.isNotEmpty) {
        _lastDocument = postsSnapshot.docs.last;

        final morePosts = <BaseGroupPost>[];
        for (final doc in postsSnapshot.docs) {
          final post = _createPostFromDocument(doc);
          if (post != null) {
            morePosts.add(post);
          }
        }

        if (mounted) {
          setState(() {
            _posts.addAll(morePosts);
          });
        }
      }
    } catch (e) {
      AppLogger.error('Error loading more ${widget.groupType.value} posts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_loading_more_posts'.tr(args: [e.toString()])),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  BaseGroupPost? _createPostFromDocument(DocumentSnapshot doc) {
    try {
      switch (widget.groupType) {
        case GroupType.artist:
          return ArtistGroupPost.fromFirestore(doc);
        case GroupType.event:
          return EventGroupPost.fromFirestore(doc);
        case GroupType.artWalk:
          return ArtWalkAdventurePost.fromFirestore(doc);
        case GroupType.artistWanted:
          return ArtistWantedPost.fromFirestore(doc);
      }
    } catch (e) {
      AppLogger.error('Error creating post from document ${doc.id}: $e');
      return null;
    }
  }

  Future<void> _handleAppreciate(BaseGroupPost post) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('sign_in_to_appreciate'.tr())));
      }
      return;
    }

    try {
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(post.id);

      final appreciateRef = postRef.collection('appreciations').doc(user.uid);
      final appreciateDoc = await appreciateRef.get();

      if (!appreciateDoc.exists) {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final postSnapshot = await transaction.get(postRef);
          final currentAppreciateCount =
              (postSnapshot.data()?['applauseCount'] as int?) ?? 0;

          transaction.update(postRef, {
            'applauseCount': currentAppreciateCount + 1,
          });

          transaction.set(appreciateRef, {
            'createdAt': FieldValue.serverTimestamp(),
          });
        });

        // Update local state
        setState(() {
          final index = _posts.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            // Create a new post with updated appreciate count
            // This is a simplified approach - in a real app you'd want proper copyWith methods
            _loadPosts(); // Reload to get updated counts
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('appreciated'.tr())));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('already_appreciated'.tr())));
        }
      }
    } catch (e) {
      AppLogger.error('Error appreciating post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_appreciating_post'.tr(args: [e.toString()])),
          ),
        );
      }
    }
  }

  void _handleComment(BaseGroupPost post) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            CommentsScreen(post: PostModel.fromBaseGroupPost(post)),
      ),
    );
  }

  void _handleFeature(BaseGroupPost post) async {
    try {
      // Mark post as featured in Firestore
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(post.id);

      // First check if the document exists
      final postDoc = await postRef.get();
      if (!postDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('post_not_found'.tr())));
        }
        return;
      }

      // Update the post to mark it as featured
      await postRef.update({'isFeatured': true});

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('post_featured'.tr())));
      }
    } catch (e) {
      AppLogger.error('Error featuring post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_to_feature_post'.tr(args: [e.toString()])),
          ),
        );
      }
    }
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

  void _handleShare(BaseGroupPost post) async {
    try {
      final shareText =
          '${post.content}\n\nShared from ARTbeat by ${post.userName}';
      await SharePlus.instance.share(ShareParams(text: shareText));

      await _updateShareCount(post.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('failed_to_share'.tr(args: [e.toString()]))),
        );
      }
    }
  }

  /// Update share count in Firestore
  Future<void> _updateShareCount(String postId) async {
    try {
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(postId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) return;

        final currentCount = postDoc.data()?['shareCount'] ?? 0;
        transaction.update(postRef, {'shareCount': currentCount + 1});
      });
    } catch (e) {
      AppLogger.info('Failed to update share count: $e');
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF22D3EE), // teal
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'loading_posts'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  color: const Color(0xFF70FFFFFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFF70FFFFFF),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'something_went_wrong'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  color: const Color(0xFF70FFFFFF),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              HudButton(isPrimary: true, onPressed: _loadPosts, text: 'try_again'.tr()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getGroupIcon(), size: 64, color: const Color(0xFF70FFFFFF)),
              const SizedBox(height: 16),
              Text(
                'no_posts_yet_in_group'.tr(args: [widget.groupType.title]),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF92FFFFFF),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'be_the_first_to_share'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF45FFFFFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getGroupIcon() {
    switch (widget.groupType) {
      case GroupType.artist:
        return Icons.palette;
      case GroupType.event:
        return Icons.event;
      case GroupType.artWalk:
        return Icons.directions_walk;
      case GroupType.artistWanted:
        return Icons.work;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_posts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
                ),
              ),
            );
          }

          final post = _posts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GroupPostCard(
              post: post,
              groupType: widget.groupType,
              onAppreciate: () => _handleAppreciate(post),
              onComment: () => _handleComment(post),
              onFeature: () => _handleFeature(post),
              onGift: () => _handleGift(post),
              onShare: () => _handleShare(post),
            ),
          );
        },
      ),
    );
  }
}
