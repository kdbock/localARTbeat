import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';

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
    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 8.0,
        bottom: isReply ? 0.0 : 8.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Author avatar
              CircleAvatar(
                radius: isReply ? 14.0 : 18.0,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: ImageUrlValidator.safeNetworkImage(
                  authorPhotoUrl,
                ),
                child: !ImageUrlValidator.isValidImageUrl(authorPhotoUrl)
                    ? Icon(
                        Icons.person,
                        size: isReply ? 16.0 : 20.0,
                        color: Colors.grey.shade700,
                      )
                    : null,
              ),
              const SizedBox(width: 8),

              // Author name and timestamp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: isReply ? 12.0 : 14.0,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: isReply ? 10.0 : 12.0,
                      ),
                    ),
                  ],
                ),
              ),

              // Delete option for author
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: onDelete,
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),

          // Rating (only for top-level comments)
          if (rating != null && !isReply)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 44.0),
              child: Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating! ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  );
                }),
              ),
            ),

          // Comment content
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 44.0),
            child: Text(content),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 44.0),
            child: Row(
              children: [
                // Like button
                TextButton.icon(
                  icon: const Icon(Icons.thumb_up, size: 14),
                  label: Text(
                    likeCount > 0 ? likeCount.toString() : 'Like',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onLike,
                ),

                // Reply button for top-level comments
                if (onReply != null && !isReply)
                  TextButton.icon(
                    icon: const Icon(Icons.reply, size: 14),
                    label: const Text('Reply', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: onReply,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
