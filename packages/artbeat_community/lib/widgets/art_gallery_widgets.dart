import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../models/art_models.dart';
import '../services/art_community_service.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Gallery-style post card focused on beautiful image display
class ArtPostCard extends StatefulWidget {
  final ArtPost post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final bool showUserInfo;

  const ArtPostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
    this.showUserInfo = true,
  });

  @override
  State<ArtPostCard> createState() => _ArtPostCardState();
}

class _ArtPostCardState extends State<ArtPostCard>
    with TickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late AnimationController _colorAnimationController;
  late Animation<double> _likeAnimation;
  late Animation<Color?> _colorAnimation;
  late bool _isLiked;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByCurrentUser ?? false;
    _likesCount = widget.post.likesCount;

    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _colorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _colorAnimation =
        ColorTween(
          begin: ArtbeatColors.textSecondary,
          end: ArtbeatColors.error,
        ).animate(
          CurvedAnimation(
            parent: _colorAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    // Set initial animation state
    if (_isLiked) {
      _colorAnimationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _colorAnimationController.dispose();
    super.dispose();
  }

  void _handleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1;
    });

    // Animate the scale (bounce effect)
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
    });

    // Animate the color change
    if (_isLiked) {
      _colorAnimationController.forward();
    } else {
      _colorAnimationController.reverse();
    }

    widget.onLike?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main image area
            if (widget.post.imageUrls.isNotEmpty)
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: SecureNetworkImage(
                    imageUrl: widget.post.imageUrls.first,
                    fit: BoxFit.cover,
                    enableThumbnailFallback: true,
                    placeholder: Container(
                      color: ArtbeatColors.surface,
                      child: const Icon(
                        Icons.palette,
                        size: 48,
                        color: ArtbeatColors.primaryPurple,
                      ),
                    ),
                    errorWidget: const Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

            // Content area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // User info
                      if (widget.showUserInfo)
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage:
                                  ImageUrlValidator.safeNetworkImage(
                                    widget.post.userAvatarUrl,
                                  ),
                              child:
                                  !ImageUrlValidator.isValidImageUrl(
                                    widget.post.userAvatarUrl,
                                  )
                                  ? const Icon(Icons.person, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        widget.post.userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (widget.post.isUserVerified)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 4),
                                          child: Icon(
                                            Icons.verified,
                                            size: 14,
                                            color: ArtbeatColors.primaryGreen,
                                          ),
                                        ),
                                      if (widget.post.isArtistPost)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 6,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ArtbeatColors.primaryPurple
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Artist',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  ArtbeatColors.primaryPurple,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    _formatTimeAgo(widget.post.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: ArtbeatColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                      // Post content
                      if (widget.post.content.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            widget.post.content,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      // Tags
                      if (widget.post.tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: widget.post.tags.take(3).map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: ArtbeatColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: ArtbeatColors.textSecondary
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: ArtbeatColors.textSecondary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      // Engagement actions
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            // Like button and count
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Like button
                                  AnimatedBuilder(
                                    animation: Listenable.merge([
                                      _likeAnimation,
                                      _colorAnimation,
                                    ]),
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _likeAnimation.value,
                                        child: IconButton(
                                          onPressed: _handleLike,
                                          icon: Icon(
                                            _isLiked
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            size: 14,
                                            color:
                                                _colorAnimation.value ??
                                                ArtbeatColors.textSecondary,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  Flexible(
                                    child: AnimatedBuilder(
                                      animation: _colorAnimation,
                                      builder: (context, child) {
                                        return Text(
                                          '$_likesCount',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                _colorAnimation.value ??
                                                ArtbeatColors.textSecondary,
                                            fontWeight: _isLiked
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 4),

                            // Comment button and count
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: widget.onComment,
                                    icon: const Icon(
                                      Icons.chat_bubble_outline,
                                      size: 14,
                                      color: ArtbeatColors.textSecondary,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      '${widget.post.commentsCount}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: ArtbeatColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Share button
                            IconButton(
                              onPressed: () async {
                                try {
                                  final shareText =
                                      '${widget.post.content}\n\n'
                                      'Shared by ${widget.post.userName} on ArtBeat\n'
                                      '${widget.post.tags.isNotEmpty ? 'Tags: ${widget.post.tags.join(', ')}\n' : ''}'
                                      '#ArtBeat #DigitalArt';

                                  await SharePlus.instance.share(
                                    ShareParams(text: shareText),
                                  );

                                  if (mounted) {
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Post shared successfully!',
                                        ),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to share: $e'),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(
                                Icons.share_outlined,
                                size: 14,
                                color: ArtbeatColors.textSecondary,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
}

/// Artist profile card for the gallery view
class ArtistCard extends StatefulWidget {
  final ArtistProfile artist;
  final VoidCallback? onTap;
  final void Function(bool isFollowing)? onFollow;

  const ArtistCard({
    super.key,
    required this.artist,
    this.onTap,
    this.onFollow,
  });

  @override
  State<ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends State<ArtistCard> {
  late bool _isFollowing;
  late int _followersCount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.artist.isFollowedByCurrentUser;
    _followersCount = widget.artist.followersCount;
  }

  @override
  void didUpdateWidget(ArtistCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artist.isFollowedByCurrentUser !=
        widget.artist.isFollowedByCurrentUser) {
      _isFollowing = widget.artist.isFollowedByCurrentUser;
    }
    if (oldWidget.artist.followersCount != widget.artist.followersCount) {
      _followersCount = widget.artist.followersCount;
    }
  }

  void _handleFollowToggle() async {
    if (_isLoading) return;

    // Store original values in case we need to revert
    final originalFollowing = _isFollowing;
    final originalFollowersCount = _followersCount;

    setState(() {
      _isLoading = true;
      // Optimistic update
      _isFollowing = !_isFollowing;
      _followersCount = _isFollowing
          ? _followersCount + 1
          : _followersCount - 1;
    });

    try {
      // Call the parent callback
      if (widget.onFollow != null) {
        widget.onFollow!(_isFollowing);
      }
    } catch (e) {
      // If parent callback fails, revert optimistic update
      setState(() {
        _isFollowing = originalFollowing;
        _followersCount = originalFollowersCount;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging
    if (kDebugMode) {
      print('🎨 ArtistCard for ${widget.artist.displayName}:');
      print(
        '   Portfolio images count: ${widget.artist.portfolioImages.length}',
      );
      if (widget.artist.portfolioImages.isNotEmpty) {
        print(
          '   First portfolio image: ${widget.artist.portfolioImages.first}',
        );
      }
      print('   Avatar URL: ${widget.artist.avatarUrl}');
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background image if available
              if (widget.artist.portfolioImages.isNotEmpty)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SecureNetworkImage(
                      imageUrl: widget.artist.portfolioImages.first,
                      fit: BoxFit.cover,
                      enableThumbnailFallback: true,
                      placeholder: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ArtbeatColors.primaryPurple.withValues(
                                alpha: 0.2,
                              ),
                              ArtbeatColors.primaryGreen.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ArtbeatColors.primaryPurple,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ArtbeatColors.primaryPurple.withValues(
                                alpha: 0.2,
                              ),
                              ArtbeatColors.primaryGreen.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: ArtbeatColors.primaryPurple,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Overlay gradient for better text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar and follow button row
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipOval(
                            child: widget.artist.avatarUrl.isNotEmpty
                                ? SecureNetworkImage(
                                    imageUrl: widget.artist.avatarUrl,
                                    fit: BoxFit.cover,
                                    enableThumbnailFallback: true,
                                    placeholder: Container(
                                      color: ArtbeatColors.primaryPurple
                                          .withValues(alpha: 0.3),
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    errorWidget: Container(
                                      color: ArtbeatColors.primaryPurple
                                          .withValues(alpha: 0.3),
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: ArtbeatColors.primaryPurple
                                        .withValues(alpha: 0.3),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                          ),
                        ),
                        const Spacer(),
                        // Follow button
                        if (widget.onFollow != null)
                          Container(
                            decoration: BoxDecoration(
                              color: _isFollowing
                                  ? ArtbeatColors.primaryGreen.withValues(
                                      alpha: 0.3,
                                    )
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              onPressed: _isLoading
                                  ? null
                                  : _handleFollowToggle,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Icon(
                                      _isFollowing
                                          ? Icons.person_remove
                                          : Icons.person_add,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                              tooltip: _isFollowing
                                  ? 'Unfollow ${widget.artist.displayName}'
                                  : 'Follow ${widget.artist.displayName}',
                            ),
                          ),
                      ],
                    ),

                    const Spacer(),

                    // Artist info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          widget.artist.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // Bio
                        if (widget.artist.bio.isNotEmpty)
                          Text(
                            widget.artist.bio,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                        const SizedBox(height: 8),

                        // Specialties
                        if (widget.artist.specialties.isNotEmpty)
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: widget.artist.specialties.take(3).map((
                              specialty,
                            ) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  specialty,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 8),

                        // Stats
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_followersCount followers',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            if (widget.artist.isVerified) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.verified,
                                size: 16,
                                color: ArtbeatColors.primaryGreen,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Responsive Art Post Card that adapts to content and follows dashboard design patterns
class ResponsiveArtPostCard extends StatefulWidget {
  final ArtPost post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final bool showUserInfo;

  const ResponsiveArtPostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
    this.showUserInfo = true,
  });

  @override
  State<ResponsiveArtPostCard> createState() => _ResponsiveArtPostCardState();
}

class _ResponsiveArtPostCardState extends State<ResponsiveArtPostCard>
    with TickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late AnimationController _colorAnimationController;
  late AnimationController _commentAnimationController;
  late Animation<double> _likeAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _commentAnimation;
  late bool _isLiked;
  late int _likesCount;
  bool _showComments = false;
  List<ArtComment> _comments = [];
  bool _loadingComments = false;
  final TextEditingController _commentController = TextEditingController();
  bool _postingComment = false;
  late final ArtCommunityService _communityService;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByCurrentUser ?? false;
    _likesCount = widget.post.likesCount;
    _communityService = ArtCommunityService();

    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _colorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _colorAnimation =
        ColorTween(
          begin: ArtbeatColors.textSecondary,
          end: ArtbeatColors.error,
        ).animate(
          CurvedAnimation(
            parent: _colorAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    _commentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _commentAnimation = CurvedAnimation(
      parent: _commentAnimationController,
      curve: Curves.easeInOut,
    );

    // Set initial animation state
    if (_isLiked) {
      _colorAnimationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _colorAnimationController.dispose();
    _commentAnimationController.dispose();
    _commentController.dispose();
    _communityService.dispose();
    super.dispose();
  }

  void _handleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1;
    });

    // Animate the scale (bounce effect)
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
    });

    // Animate the color change
    if (_isLiked) {
      _colorAnimationController.forward();
    } else {
      _colorAnimationController.reverse();
    }

    widget.onLike?.call();
  }

  void _toggleComments() async {
    setState(() {
      _showComments = !_showComments;
    });

    if (_showComments) {
      _commentAnimationController.forward();
      if (_comments.isEmpty) {
        await _loadComments();
      }
    } else {
      _commentAnimationController.reverse();
    }
  }

  Future<void> _loadComments() async {
    if (_loadingComments) return;

    setState(() {
      _loadingComments = true;
    });

    try {
      // Use the community service to load real comments from database
      final comments = await _communityService.getComments(
        widget.post.id,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _comments = comments;
          _loadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingComments = false;
        });
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load comments: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _postingComment) return;

    setState(() {
      _postingComment = true;
    });

    try {
      // Use the community service to post real comment to database
      final commentId = await _communityService.addComment(
        widget.post.id,
        content,
      );

      if (commentId != null && mounted) {
        // Clear the input field
        _commentController.clear();

        // Reload comments to get the updated list from database
        await _loadComments();

        setState(() {
          _postingComment = false;
        });

        // Show success message
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment posted successfully! 💬'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Failed to post comment');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _postingComment = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post comment: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArtbeatColors.primaryPurple.withValues(alpha: 0.03),
            ArtbeatColors.primaryGreen.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // User info header
            if (widget.showUserInfo)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            ArtbeatColors.primaryPurple,
                            ArtbeatColors.primaryGreen,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: ArtbeatColors.primaryPurple.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.transparent,
                        backgroundImage: ImageUrlValidator.safeNetworkImage(
                          widget.post.userAvatarUrl,
                        ),
                        child:
                            !ImageUrlValidator.isValidImageUrl(
                              widget.post.userAvatarUrl,
                            )
                            ? const Icon(
                                Icons.person,
                                size: 24,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.post.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: ArtbeatColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.post.isUserVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  size: 18,
                                  color: ArtbeatColors.primaryGreen,
                                ),
                              ],
                              if (widget.post.isArtistPost) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        ArtbeatColors.primaryPurple,
                                        ArtbeatColors.primaryGreen,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Artist',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTimeAgo(widget.post.createdAt),
                            style: const TextStyle(
                              fontSize: 14,
                              color: ArtbeatColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Post content text
            if (widget.post.content.isNotEmpty)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    widget.post.content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: ArtbeatColors.textPrimary,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

            // Main image area (responsive height)
            if (widget.post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              // Debug info for image URLs
              if (kDebugMode)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEBUG: Image URLs (${widget.post.imageUrls.length}):',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ...widget.post.imageUrls.map(
                          (url) => Text(
                            url.length > 100
                                ? '${url.substring(0, 100)}...'
                                : url,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  constraints: const BoxConstraints(
                    minHeight: 150,
                    maxHeight: 250,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SecureNetworkImage(
                      imageUrl: widget.post.imageUrls.first,
                      fit: BoxFit.cover,
                      enableThumbnailFallback: true,
                      placeholder: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ArtbeatColors.primaryPurple.withValues(
                                alpha: 0.1,
                              ),
                              ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.palette,
                                size: 64,
                                color: ArtbeatColors.primaryPurple,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Loading image...',
                                style: TextStyle(
                                  color: ArtbeatColors.primaryPurple,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      errorWidget: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: ArtbeatColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Tags
            if (widget.post.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.post.tags.take(5).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                            ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ArtbeatColors.primaryPurple.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: ArtbeatColors.primaryPurple,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // Engagement actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Like button and count
                  Expanded(
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _likeAnimation,
                            _colorAnimation,
                          ]),
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _likeAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isLiked
                                      ? ArtbeatColors.error.withValues(
                                          alpha: 0.1,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: IconButton(
                                  onPressed: _handleLike,
                                  icon: Icon(
                                    _isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 24,
                                    color:
                                        _colorAnimation.value ??
                                        ArtbeatColors.textSecondary,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        AnimatedBuilder(
                          animation: _colorAnimation,
                          builder: (context, child) {
                            return Text(
                              '$_likesCount',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: _isLiked
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color:
                                    _colorAnimation.value ??
                                    ArtbeatColors.textSecondary,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Comment button and count
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: ArtbeatColors.primaryPurple.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            onPressed: _toggleComments,
                            icon: Icon(
                              _showComments
                                  ? Icons.chat_bubble
                                  : Icons.chat_bubble_outline,
                              size: 24,
                              color: ArtbeatColors.primaryPurple,
                            ),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_comments.isNotEmpty ? _comments.length : widget.post.commentsCount}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Share button
                  Container(
                    decoration: BoxDecoration(
                      color: ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: () async {
                        try {
                          final shareText =
                              '${widget.post.content}\n\n'
                              'Shared by ${widget.post.userName} on ArtBeat\n'
                              '${widget.post.tags.isNotEmpty ? 'Tags: ${widget.post.tags.join(', ')}\n' : ''}'
                              '#ArtBeat #DigitalArt';

                          await SharePlus.instance.share(
                            ShareParams(text: shareText),
                          );

                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Post shared successfully!'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to share: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.share_outlined,
                        size: 24,
                        color: ArtbeatColors.primaryGreen,
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),

            // Animated comment section
            AnimatedBuilder(
              animation: _commentAnimation,
              builder: (context, child) {
                return SizeTransition(
                  sizeFactor: _commentAnimation,
                  child: _showComments
                      ? _buildCommentSection()
                      : const SizedBox.shrink(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
            color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Comment input section
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: ArtbeatColors.primaryPurple.withValues(
                  alpha: 0.1,
                ),
                child: const Icon(
                  Icons.person,
                  size: 18,
                  color: ArtbeatColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: ArtbeatColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: ArtbeatColors.primaryPurple.withValues(alpha: 0.2),
                    ),
                  ),
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: TextStyle(
                        color: ArtbeatColors.textSecondary,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      ArtbeatColors.primaryPurple,
                      ArtbeatColors.primaryGreen,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: _postingComment ? null : _postComment,
                  icon: _postingComment
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.send, size: 18, color: Colors.white),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),

          // Comments list
          if (_loadingComments) ...[
            const SizedBox(height: 16),
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  ArtbeatColors.primaryPurple,
                ),
              ),
            ),
          ] else if (_comments.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: ArtbeatColors.primaryPurple, thickness: 0.5),
            const SizedBox(height: 12),
            // Show only first 3 comments to avoid overflow
            ...(_comments
                .take(3)
                .map(
                  (comment) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildCommentItem(comment),
                  ),
                )
                .toList()),
            if (_comments.length > 3)
              Center(
                child: TextButton(
                  onPressed: () => _showAllCommentsModal(),
                  child: Text(
                    'View all ${_comments.length} comments',
                    style: const TextStyle(
                      color: ArtbeatColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ] else if (!_loadingComments) ...[
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No comments yet. Be the first to comment!',
                style: TextStyle(
                  color: ArtbeatColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentItem(ArtComment comment) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundImage: ImageUrlValidator.safeNetworkImage(
            comment.userAvatarUrl,
          ),
          backgroundColor: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
          child: !ImageUrlValidator.isValidImageUrl(comment.userAvatarUrl)
              ? const Icon(
                  Icons.person,
                  size: 16,
                  color: ArtbeatColors.primaryPurple,
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
                    comment.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: ArtbeatColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimeAgo(comment.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: ArtbeatColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                comment.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: ArtbeatColors.textPrimary,
                  height: 1.4,
                ),
              ),
              if (comment.likesCount > 0) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite,
                      size: 12,
                      color: ArtbeatColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${comment.likesCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ArtbeatColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showAllCommentsModal() {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Comments (${_comments.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ArtbeatColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildCommentItem(comment),
                    );
                  },
                ),
              ),
            ],
          ),
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
}
