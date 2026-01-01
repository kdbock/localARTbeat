import 'package:artbeat_art_walk/src/widgets/typography.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommentTile extends StatelessWidget {
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final String timeAgo;
  final int likeCount;
  final double? rating;
  final bool isAuthor;
  final bool isReply;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final VoidCallback onLike;

  const CommentTile({
    super.key,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    required this.timeAgo,
    required this.likeCount,
    this.rating,
    this.isAuthor = false,
    this.isReply = false,
    this.onReply,
    this.onDelete,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AvatarBadge(photoUrl: authorPhotoUrl, isReply: isReply),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authorName,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: isReply ? 13 : 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    timeAgo,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline),
                color: const Color(0xFFFF3D8D),
              ),
          ],
        ),
        if (rating != null && !isReply) ...[
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (index) {
              final filled = rating! >= index + 1;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 18,
                  color: const Color(0xFFFFC857),
                ),
              );
            }),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          content,
          style: AppTypography.body(
            Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _ActionChip(
              icon: Icons.thumb_up_alt,
              label: likeCount > 0
                  ? likeCount.toString()
                  : 'art_walk_comment_section_button_like'.tr(),
              onTap: onLike,
            ),
            if (onReply != null && !isReply) ...[
              const SizedBox(width: 12),
              _ActionChip(
                icon: Icons.reply,
                label: 'art_walk_comment_section_button_reply'.tr(),
                onTap: onReply!,
              ),
            ],
          ],
        ),
      ],
    );

    if (isReply) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.all(16),
        child: body,
      );
    }

    return GlassCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(18),
      child: body,
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  final String? photoUrl;
  final bool isReply;

  const _AvatarBadge({required this.photoUrl, required this.isReply});

  @override
  Widget build(BuildContext context) {
    final image = ImageUrlValidator.safeNetworkImage(photoUrl);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
        ),
      ),
      child: CircleAvatar(
        radius: isReply ? 16 : 20,
        backgroundColor: Colors.black.withValues(alpha: 0.4),
        backgroundImage: image,
        child: image == null
            ? Icon(
                Icons.person,
                size: isReply ? 16 : 20,
                color: Colors.white.withValues(alpha: 0.8),
              )
            : null,
      ),
    );
  }
}
