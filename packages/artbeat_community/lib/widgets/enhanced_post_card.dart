import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/post_model.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../src/widgets/user_action_menu.dart';

/// Enhanced post card that supports images, video, and audio
class EnhancedPostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final void Function(String imageUrl, int index)? onImageTap;
  final VoidCallback? onBlockStatusChanged;

  const EnhancedPostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onImageTap,
    this.onBlockStatusChanged,
  });

  @override
  State<EnhancedPostCard> createState() => _EnhancedPostCardState();
}

class _EnhancedPostCardState extends State<EnhancedPostCard> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isVideoInitialized = false;
  bool _isAudioPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _initializeMedia() async {
    // Initialize video if present
    if (widget.post.videoUrl != null) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.post.videoUrl!),
      );
      try {
        await _videoController!.initialize();
        setState(() => _isVideoInitialized = true);
      } catch (e) {
        AppLogger.error('Error initializing video: $e');
      }
    }

    // Initialize audio if present
    if (widget.post.audioUrl != null) {
      _audioPlayer = AudioPlayer();
      _audioPlayer!.onDurationChanged.listen((duration) {
        setState(() => _audioDuration = duration);
      });
      _audioPlayer!.onPositionChanged.listen((position) {
        setState(() => _audioPosition = position);
      });
      _audioPlayer!.onPlayerStateChanged.listen((state) {
        setState(() => _isAudioPlaying = state == PlayerState.playing);
      });
    }
  }

  Future<void> _toggleVideoPlayback() async {
    if (_videoController == null || !_isVideoInitialized) return;

    if (_videoController!.value.isPlaying) {
      await _videoController!.pause();
    } else {
      await _videoController!.play();
    }
    setState(() {});
  }

  Future<void> _toggleAudioPlayback() async {
    if (_audioPlayer == null || widget.post.audioUrl == null) return;

    if (_isAudioPlaying) {
      await _audioPlayer!.pause();
    } else {
      await _audioPlayer!.play(UrlSource(widget.post.audioUrl!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          _buildHeader(),

          // Content text
          if (widget.post.content.isNotEmpty) _buildContent(),

          // Media content
          _buildMediaContent(),

          // Tags
          if (widget.post.tags.isNotEmpty) _buildTags(),

          // Engagement actions
          _buildEngagementActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
            backgroundImage: ImageUrlValidator.safeNetworkImage(
              widget.post.userPhotoUrl,
            ),
            child: !ImageUrlValidator.isValidImageUrl(widget.post.userPhotoUrl)
                ? const Icon(
                    Icons.person,
                    color: ArtbeatColors.primaryPurple,
                    size: 20,
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
                      widget.post.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (widget.post.isUserVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        color: ArtbeatColors.primaryGreen,
                        size: 16,
                      ),
                    ],
                    if (widget.post.groupType != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getGroupColor(
                            widget.post.groupType!,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getGroupColor(widget.post.groupType!),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getGroupDisplayName(widget.post.groupType!),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _getGroupColor(widget.post.groupType!),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  timeago.format(widget.post.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          // Moderation status indicator
          if (widget.post.moderationStatus != PostModerationStatus.approved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getModerationColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.post.moderationStatus.displayName,
                style: TextStyle(
                  color: _getModerationColor(),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          // Three-dot menu with Report/Block options
          UserActionMenu(
            userId: widget.post.userId,
            contentId: widget.post.id,
            contentType: 'post',
            userName: widget.post.userName,
            onBlockStatusChanged: widget.onBlockStatusChanged,
          ),
        ],
      ),
    );
  }

  Color _getModerationColor() {
    switch (widget.post.moderationStatus) {
      case PostModerationStatus.pending:
        return Colors.orange;
      case PostModerationStatus.rejected:
        return Colors.red;
      case PostModerationStatus.flagged:
        return Colors.red;
      case PostModerationStatus.underReview:
        return Colors.amber;
      case PostModerationStatus.approved:
        return ArtbeatColors.primaryGreen;
    }
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        widget.post.content,
        style: const TextStyle(fontSize: 14, height: 1.4),
      ),
    );
  }

  Widget _buildMediaContent() {
    final hasImages = widget.post.imageUrls.isNotEmpty;
    final hasVideo = widget.post.videoUrl != null;
    final hasAudio = widget.post.audioUrl != null;

    if (!hasImages && !hasVideo && !hasAudio) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Images
          if (hasImages) _buildImagesGrid(),

          // Video
          if (hasVideo) _buildVideoPlayer(),

          // Audio
          if (hasAudio) _buildAudioPlayer(),
        ],
      ),
    );
  }

  Widget _buildImagesGrid() {
    final images = widget.post.imageUrls;

    if (images.length == 1) {
      return GestureDetector(
        onTap: widget.onImageTap != null
            ? () => widget.onImageTap!(images[0], 0)
            : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              images[0],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                );
              },
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: images.length == 2 ? 2 : 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: images.length > 4 ? 4 : images.length,
      itemBuilder: (context, index) {
        final isLastItem = index == 3 && images.length > 4;

        return GestureDetector(
          onTap: widget.onImageTap != null
              ? () => widget.onImageTap!(images[index], index)
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    );
                  },
                ),
                if (isLastItem)
                  Container(
                    color: Colors.black.withValues(alpha: 0.6),
                    child: Center(
                      child: Text(
                        '+${images.length - 4}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_isVideoInitialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            children: [
              VideoPlayer(_videoController!),
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleVideoPlayback,
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleAudioPlayback,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: ArtbeatColors.primaryPurple,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isAudioPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Audio',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _audioDuration.inMilliseconds > 0
                      ? _audioPosition.inMilliseconds /
                            _audioDuration.inMilliseconds
                      : 0.0,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    ArtbeatColors.primaryPurple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDuration(_audioPosition)} / ${_formatDuration(_audioDuration)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildTags() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: widget.post.tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '#$tag',
              style: const TextStyle(
                color: ArtbeatColors.primaryPurple,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getGroupColor(String groupType) {
    switch (groupType) {
      case 'artist':
        return ArtbeatColors.primaryPurple;
      case 'event':
        return ArtbeatColors.primaryGreen;
      case 'artwalk':
        return ArtbeatColors.secondaryTeal;
      case 'artistwanted':
        return ArtbeatColors.accentYellow;
      default:
        return ArtbeatColors.primaryPurple;
    }
  }

  String _getGroupDisplayName(String groupType) {
    switch (groupType) {
      case 'artist':
        return 'Artist';
      case 'event':
        return 'Event';
      case 'artwalk':
        return 'Art Walk';
      case 'artistwanted':
        return 'Artist Wanted';
      default:
        return 'Group';
    }
  }

  Widget _buildEngagementActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.favorite_border,
            activeIcon: Icons.favorite,
            label: widget.post.engagementStats.likeCount.toString(),
            isActive: widget.post.isLikedByCurrentUser,
            onTap: widget.onLike,
            color: Colors.red,
          ),
          const SizedBox(width: 24),
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: widget.post.engagementStats.commentCount.toString(),
            onTap: widget.onComment,
            color: ArtbeatColors.primaryPurple,
          ),
          const SizedBox(width: 24),
          _buildActionButton(
            icon: Icons.share_outlined,
            label: widget.post.engagementStats.shareCount.toString(),
            onTap: widget.onShare,
            color: ArtbeatColors.primaryGreen,
          ),
          const Spacer(),
          // Post type indicator
          if (widget.post.videoUrl != null)
            Icon(Icons.videocam, color: Colors.grey[600], size: 16),
          if (widget.post.audioUrl != null)
            Icon(Icons.audiotrack, color: Colors.grey[600], size: 16),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    IconData? activeIcon,
    required String label,
    bool isActive = false,
    VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive && activeIcon != null ? activeIcon : icon,
            color: isActive ? color : Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? color : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
