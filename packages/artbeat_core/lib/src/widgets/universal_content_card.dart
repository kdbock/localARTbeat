import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';


/// Universal content card that can display any ARTbeat content type
/// with consistent engagement actions: Appreciate, Connect, Discuss, Amplify
class UniversalContentCard extends StatelessWidget {
  final String contentId;
  final String contentType;
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final String authorName;
  final String? authorImageUrl;
  final String? authorId;
  final DateTime createdAt;
  final EngagementStats engagementStats;
  final VoidCallback? onTap;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onDiscuss;
  final VoidCallback? onAmplify;
  final VoidCallback? onGift;
  final bool showConnect;
  final bool showGift;
  final bool showCommentPrompt;
  final bool isCompact;
  final Widget? customContent;
  final List<String>? tags;

  const UniversalContentCard({
    super.key,
    required this.contentId,
    required this.contentType,
    required this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
    required this.authorName,
    this.authorImageUrl,
    this.authorId,
    required this.createdAt,
    required this.engagementStats,
    this.onTap,
    this.onAuthorTap,
    this.onDiscuss,
    this.onAmplify,
    this.onGift,
    this.showConnect = false,
    this.showGift = false,
    this.showCommentPrompt = false,
    this.isCompact = false,
    this.customContent,
    this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with author info
            _buildHeader(context),

            // Main content
            if (customContent != null)
              customContent!
            else
              _buildDefaultContent(context),

            // Tags
            if (tags != null && tags!.isNotEmpty) _buildTags(context),

            // Engagement bar
            ContentEngagementBar(
              contentId: contentId,
              contentType: contentType,
              initialStats: engagementStats,
              isCompact: isCompact,
              customHandlers: {
                if (onDiscuss != null) EngagementType.comment: onDiscuss,
                if (onAmplify != null) EngagementType.share: onAmplify,
                if (onGift != null) EngagementType.gift: onGift,
              },
            ),
            // Optional quick comment prompt under engagement bar
            if (showCommentPrompt && onDiscuss != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: GestureDetector(
                  onTap: onDiscuss,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: ArtbeatColors.lightGray,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                          color: ArtbeatColors.darkGray,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Write a comment...',
                            style: TextStyle(color: ArtbeatColors.darkGray),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Author avatar
          GestureDetector(
            onTap: onAuthorTap,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: ArtbeatColors.lightGray,
              backgroundImage: ImageUrlValidator.safeNetworkImage(
                authorImageUrl,
              ),
              child: !ImageUrlValidator.isValidImageUrl(authorImageUrl)
                  ? const Icon(
                      Icons.person,
                      color: ArtbeatColors.darkGray,
                      size: 20,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Author info and timestamp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onAuthorTap,
                  child: Text(
                    authorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // Hide the content-type label for plain posts — posts are posts.
                    if (contentType.isNotEmpty && contentType != 'post') ...[
                      Text(
                        _getContentTypeLabel(),
                        style: TextStyle(
                          color: _getContentTypeColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '•',
                        style: TextStyle(
                          color: ArtbeatColors.darkGray,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      _formatTimestamp(createdAt),
                      style: const TextStyle(
                        color: ArtbeatColors.darkGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Removed content-type icon - cards now show a cleaner header
        ],
      ),
    );
  }

  Widget _buildDefaultContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          // Subtitle
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 14,
                color: ArtbeatColors.darkGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          // Description
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: const TextStyle(
                fontSize: 14,
                color: ArtbeatColors.textSecondary,
                height: 1.4,
              ),
              maxLines: isCompact ? 2 : null,
              overflow: isCompact ? TextOverflow.ellipsis : null,
            ),
          ],

          // Image
          if (imageUrl != null && imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: OptimizedImage(
                imageUrl: imageUrl!,
                width: double.infinity,
                height: isCompact ? 200 : 300,
                fit: BoxFit.cover,
              ),
            ),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTags(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: tags!
            .take(5)
            .map(
              (tag) => Chip(
                label: Text(tag, style: const TextStyle(fontSize: 12)),
                backgroundColor: ArtbeatColors.lightGray,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            )
            .toList(),
      ),
    );
  }

  String _getContentTypeLabel() {
    switch (contentType) {
      case 'post':
        return 'Post';
      case 'artwork':
        return 'Artwork';
      case 'art_walk':
        return 'Art Walk';
      case 'event':
        return 'Event';
      case 'profile':
        return 'Profile';
      default:
        return 'Content';
    }
  }

  Color _getContentTypeColor() {
    switch (contentType) {
      case 'post':
        return ArtbeatColors.primaryGreen;
      case 'artwork':
        return ArtbeatColors.accentYellow;
      case 'art_walk':
        return ArtbeatColors.primaryPurple;
      case 'event':
        return ArtbeatColors.accentOrange;
      case 'profile':
        return ArtbeatColors.primaryBlue;
      default:
        return ArtbeatColors.darkGray;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}w';
    }
  }
}
