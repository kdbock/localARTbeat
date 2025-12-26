// Local ARTbeat theme update for EnhancedPostCard:
// - Converts white card → glass card on dark world background
// - Adds gradient accents + readable text tokens
// - Keeps ALL logic (video/audio/handlers) intact
// - Makes chips, dividers, media frames, buttons match the new design
//
// Drop-in replacement for your current file.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/post_model.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../src/widgets/user_action_menu.dart';

/// Local ARTbeat tokens (scoped to this file)
class _LAB {
  static const Color teal = Color(0xFF22D3EE);
  static const Color green = Color(0xFF34D399);
  static const Color purple = Color(0xFF7C4DFF);
  static const Color pink = Color(0xFFFF3D8D);
  static const Color yellow = Color(0xFFFFC857);

  static const Color textPrimary = Color(0xF2FFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textTertiary = Color(0x73FFFFFF);

  static Color glassFill([double a = 0.08]) =>
      Colors.white.withValues(alpha: a);
  static Color glassBorder([double a = 0.14]) =>
      Colors.white.withValues(alpha: a);
}

class _Glass extends StatelessWidget {
  const _Glass({
    required this.child,
    this.padding,
    this.radius = 20,
    this.blur = 16,
    this.fillAlpha = 0.08,
    this.borderAlpha = 0.14,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final double blur;
  final double fillAlpha;
  final double borderAlpha;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _LAB.glassFill(fillAlpha),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: _LAB.glassBorder(borderAlpha)),
            boxShadow: shadow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: _LAB.teal.withValues(alpha: 0.08),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

// ignore: unused_element
class _GradientIconChip extends StatelessWidget {
  const _GradientIconChip({required this.icon, required this.size});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_LAB.purple, _LAB.teal, _LAB.green],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _LAB.purple.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.55),
    );
  }
}

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
    if (widget.post.videoUrl != null) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.post.videoUrl!),
      );
      try {
        await _videoController!.initialize();
        if (!mounted) return;
        setState(() => _isVideoInitialized = true);
      } catch (e) {
        AppLogger.error('Error initializing video: $e');
      }
    }

    if (widget.post.audioUrl != null) {
      _audioPlayer = AudioPlayer();
      _audioPlayer!.onDurationChanged.listen((duration) {
        if (!mounted) return;
        setState(() => _audioDuration = duration);
      });
      _audioPlayer!.onPositionChanged.listen((position) {
        if (!mounted) return;
        setState(() => _audioPosition = position);
      });
      _audioPlayer!.onPlayerStateChanged.listen((state) {
        if (!mounted) return;
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
    if (!mounted) return;
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
    return GestureDetector(
      onTap: widget.onTap,
      child: _Glass(
        radius: 22,
        blur: 16,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),

            if (widget.post.content.isNotEmpty) _buildContent(),

            _buildMediaContent(),

            if (widget.post.tags.isNotEmpty) _buildTags(),

            _buildEngagementActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hasAvatar = ImageUrlValidator.isValidImageUrl(
      widget.post.userPhotoUrl,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _LAB.purple.withValues(alpha: 0.55),
                  _LAB.teal.withValues(alpha: 0.45),
                  _LAB.green.withValues(alpha: 0.45),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                  backgroundImage: hasAvatar
                      ? ImageUrlValidator.safeNetworkImage(
                          widget.post.userPhotoUrl,
                        )
                      : null,
                  child: !hasAvatar
                      ? const Icon(
                          Icons.person,
                          color: _LAB.textPrimary,
                          size: 22,
                        )
                      : null,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Name + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Text(
                      widget.post.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _LAB.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    if (widget.post.isUserVerified)
                      const Icon(Icons.verified, color: _LAB.green, size: 16),
                    if (widget.post.groupType != null)
                      _pill(
                        _getGroupDisplayName(widget.post.groupType!),
                        _getGroupColor(widget.post.groupType!),
                      ),
                    if (widget.post.moderationStatus !=
                        PostModerationStatus.approved)
                      _pill(
                        widget.post.moderationStatus.displayName,
                        _getModerationColor(),
                        filled: true,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  timeago.format(widget.post.createdAt),
                  style: const TextStyle(
                    color: _LAB.textTertiary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Menu
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

  Widget _pill(String text, Color accent, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (filled ? accent : Colors.white).withValues(
          alpha: filled ? 0.18 : 0.10,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.30), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: filled ? _LAB.textPrimary : accent,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Color _getModerationColor() {
    switch (widget.post.moderationStatus) {
      case PostModerationStatus.pending:
        return _LAB.yellow;
      case PostModerationStatus.rejected:
      case PostModerationStatus.flagged:
        return _LAB.pink;
      case PostModerationStatus.underReview:
        return Colors.amber;
      case PostModerationStatus.approved:
        return _LAB.green;
    }
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Text(
        widget.post.content,
        style: const TextStyle(
          color: _LAB.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    final hasImages = widget.post.imageUrls.isNotEmpty;
    final hasVideo = widget.post.videoUrl != null;
    final hasAudio = widget.post.audioUrl != null;

    if (!hasImages && !hasVideo && !hasAudio) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        children: [
          if (hasImages) _buildImagesGrid(),
          if (hasVideo) _buildVideoPlayer(),
          if (hasAudio) _buildAudioPlayer(),
        ],
      ),
    );
  }

  Widget _buildImagesGrid() {
    final images = widget.post.imageUrls;

    Widget imageTile(
      String url,
      int index, {
      BorderRadius? radius,
      Widget? overlay,
    }) {
      return GestureDetector(
        onTap: widget.onImageTap != null
            ? () => widget.onImageTap!(url, index)
            : null,
        child: ClipRRect(
          borderRadius: radius ?? BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white.withValues(alpha: 0.08),
                  child: const Center(
                    child: Icon(Icons.broken_image, color: _LAB.textSecondary),
                  ),
                ),
              ),
              if (overlay != null) overlay,
            ],
          ),
        ),
      );
    }

    if (images.length == 1) {
      return _Glass(
        radius: 18,
        blur: 12,
        fillAlpha: 0.05,
        borderAlpha: 0.12,
        shadow: false,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: imageTile(images[0], 0, radius: BorderRadius.circular(18)),
        ),
      );
    }

    final count = images.length > 4 ? 4 : images.length;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        final isLast = index == 3 && images.length > 4;
        return _Glass(
          radius: 16,
          blur: 12,
          fillAlpha: 0.05,
          borderAlpha: 0.12,
          shadow: false,
          child: imageTile(
            images[index],
            index,
            radius: BorderRadius.circular(16),
            overlay: isLast
                ? Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    child: Center(
                      child: Text(
                        '+${images.length - 4}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_isVideoInitialized) {
      return const Padding(
        padding: EdgeInsets.only(top: 10),
        child: _Glass(
          radius: 18,
          blur: 12,
          fillAlpha: 0.06,
          borderAlpha: 0.12,
          shadow: false,
          child: SizedBox(
            height: 220,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_LAB.teal),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: _Glass(
        radius: 18,
        blur: 12,
        fillAlpha: 0.05,
        borderAlpha: 0.12,
        shadow: false,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: Stack(
              children: [
                VideoPlayer(_videoController!),
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _toggleVideoPlayback,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.001),
                      ),
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: _videoController!.value.isPlaying
                              ? 0.0
                              : 1.0,
                          duration: const Duration(milliseconds: 250),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 34,
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
      ),
    );
  }

  Widget _buildAudioPlayer() {
    final progress = _audioDuration.inMilliseconds > 0
        ? (_audioPosition.inMilliseconds / _audioDuration.inMilliseconds).clamp(
            0.0,
            1.0,
          )
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: _Glass(
        radius: 18,
        blur: 12,
        fillAlpha: 0.08,
        borderAlpha: 0.14,
        shadow: false,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            GestureDetector(
              onTap: _toggleAudioPlayback,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_LAB.purple, _LAB.teal, _LAB.green],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  _isAudioPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
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
                    style: TextStyle(
                      color: _LAB.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        _LAB.teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatDuration(_audioPosition)} / ${_formatDuration(_audioDuration)}',
                    style: const TextStyle(
                      color: _LAB.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.post.tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _LAB.glassBorder(0.16)),
            ),
            child: Text(
              '#$tag',
              style: const TextStyle(
                color: _LAB.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
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
        return _LAB.purple;
      case 'event':
        return _LAB.green;
      case 'artwalk':
        return _LAB.teal;
      case 'artistwanted':
        return _LAB.yellow;
      default:
        return _LAB.purple;
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: _Glass(
        radius: 18,
        blur: 14,
        fillAlpha: 0.06,
        borderAlpha: 0.12,
        shadow: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _actionButton(
              icon: Icons.favorite_border,
              activeIcon: Icons.favorite,
              label: widget.post.engagementStats.likeCount.toString(),
              isActive: widget.post.isLikedByCurrentUser,
              onTap: widget.onLike,
              color: _LAB.pink,
            ),
            const SizedBox(width: 18),
            _actionButton(
              icon: Icons.chat_bubble_outline,
              label: widget.post.engagementStats.commentCount.toString(),
              onTap: widget.onComment,
              color: _LAB.teal,
            ),
            const SizedBox(width: 18),
            _actionButton(
              icon: Icons.share_outlined,
              label: widget.post.engagementStats.shareCount.toString(),
              onTap: widget.onShare,
              color: _LAB.green,
            ),
            const Spacer(),
            if (widget.post.videoUrl != null)
              const Icon(Icons.videocam, color: _LAB.textTertiary, size: 16),
            if (widget.post.audioUrl != null)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.audiotrack,
                  color: _LAB.textTertiary,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    IconData? activeIcon,
    required String label,
    bool isActive = false,
    VoidCallback? onTap,
    required Color color,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive && activeIcon != null ? activeIcon : icon,
              color: isActive ? color : _LAB.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : _LAB.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
