import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';

import '../models/post_model.dart';
import '../models/comment_model.dart';

/// Post card widget using the universal engagement system
/// This replaces the old post card with Appreciate/Connect/Discuss/Amplify actions
class PostCard extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final List<CommentModel> comments;
  final void Function(String) onUserTap;
  final void Function(String) onComment;
  // Removed legacy onApplause and onShare callbacks; use UniversalEngagementBar via UniversalContentCard
  final void Function(PostModel)? onFeature;
  final void Function(PostModel)? onGift;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.comments,
    required this.onUserTap,
    required this.onComment,
    this.onFeature,
    this.onGift,
    this.isExpanded = false,
    required this.onToggleExpand,
  });

  /// Get the post type based on the PostModel
  String get postType => 'POST';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onComment(post.id),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildContent(),
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildImage(),
            ],
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Author avatar
        UserAvatar(
          radius: 20,
          imageUrl: post.userPhotoUrl,
          displayName: post.userName,
          onTap: () => onUserTap(post.userId),
        ),
        const SizedBox(width: 12),
        // Author name and time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => onUserTap(post.userId),
                child: Text(
                  post.userName,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _formatTime(post.createdAt),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (post.content.isEmpty) return const SizedBox.shrink();

    return Text(
      post.content,
      style: GoogleFonts.spaceGrotesk(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
    );
  }

  Widget _buildImage() {
    return SecureNetworkImage(
      imageUrl: post.imageUrls.first,
      borderRadius: BorderRadius.circular(16),
      fit: BoxFit.cover,
      height: 200,
      width: double.infinity,
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        // Comment button
        Expanded(
          child: HudButton(
            isPrimary: false,
            onPressed: () => onComment(post.id),
            text: '${post.engagementStats.commentCount}',
            icon: Icons.comment_outlined,
          ),
        ),
        const SizedBox(width: 8),
        // Gift button
        Expanded(
          child: HudButton(
            isPrimary: true,
            onPressed: () => onGift?.call(post),
            text: 'gift'.tr(),
            icon: Icons.card_giftcard,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}
