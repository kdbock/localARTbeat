import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/shared_widgets.dart';

/// Enhanced artwork card with the new social engagement system
class EnhancedArtworkCard extends StatelessWidget {
  final ArtworkModel artwork;
  final VoidCallback? onTap;
  final bool showEngagement;
  final bool isCompact;

  const EnhancedArtworkCard({
    super.key,
    required this.artwork,
    this.onTap,
    this.showEngagement = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 16,
        vertical: isCompact ? 4 : 8,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artist Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: isCompact ? 16 : 20,
                      backgroundColor: const Color(0xFF7C4DFF).withValues(
                        alpha: 0.1,
                      ),
                      child: Icon(
                        Icons.person,
                        color: const Color(0xFF7C4DFF),
                        size: isCompact ? 16 : 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artwork.artistName,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: isCompact ? 14 : 16,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF92FFFFFF),
                            ),
                          ),
                          Text(
                            _formatTimeAgo(artwork.createdAt),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: isCompact ? 11 : 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF45FFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      color: const Color(0xFF70FFFFFF),
                      onPressed: () => _showArtworkOptions(context),
                    ),
                  ],
                ),
              ),

            // Artwork Image
            SizedBox(
              width: double.infinity,
              height: isCompact ? 200 : 300,
              child: artwork.imageUrl.isNotEmpty
                  ? SecureNetworkImage(
                      imageUrl: artwork.imageUrl,
                      fit: BoxFit.cover,
                      enableThumbnailFallback: true,
                      errorWidget: Container(
                        color: ArtbeatColors.backgroundSecondary,
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 64,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: ArtbeatColors.backgroundSecondary,
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          size: 64,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ),
            ),

            // Artwork Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Description
                  Text(
                    artwork.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: isCompact ? 16 : 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF92FFFFFF),
                    ),
                  ),
                  if (artwork.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      artwork.description,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: isCompact ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF70FFFFFF),
                        height: 1.4,
                      ),
                      maxLines: isCompact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Artwork Tags
                  if (artwork.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: artwork.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C4DFF).withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF7C4DFF).withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF7C4DFF),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Price and Sale Info
                  if (!artwork.isSold && artwork.price > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC857).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFFC857).withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.attach_money,
                            size: 16,
                            color: Color(0xFFFFC857),
                          ),
                          Text(
                            '\$${artwork.price.toStringAsFixed(0)}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFFC857),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'for_sale'.tr(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFFC857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Engagement Bar
            if (showEngagement)
              ContentEngagementBar(
                contentId: artwork.id,
                contentType: 'artwork',
                initialStats: EngagementStats(
                  likeCount: artwork.applauseCount,
                  commentCount: 0,
                  shareCount: 0,
                  seenCount: artwork.viewsCount,
                  lastUpdated: artwork.createdAt,
                ),
                isCompact: isCompact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
          ],
        ),
      ),
    ));
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showArtworkOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => GlassCard(
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF70FFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Options
              _buildOption(
                icon: Icons.share,
                title: 'share_artwork'.tr(),
                onTap: () {
                  Navigator.pop(context);
                  // Handle share
                },
              ),
              _buildOption(
                icon: Icons.bookmark_border,
                title: 'save_to_collection'.tr(),
                onTap: () {
                  Navigator.pop(context);
                  // Handle save
                },
              ),
              _buildOption(
                icon: Icons.report_outlined,
                title: 'report'.tr(),
                onTap: () {
                  Navigator.pop(context);
                  // Handle report
                },
              ),
              _buildOption(
                icon: Icons.block,
                title: 'hide_from_feed'.tr(),
                onTap: () {
                  Navigator.pop(context);
                  // Handle hide
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF70FFFFFF)),
      title: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF92FFFFFF),
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
