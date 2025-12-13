import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_community/screens/feed/create_post_screen.dart';

class DashboardArtworkSection extends StatelessWidget {
  final DashboardViewModel viewModel;

  const DashboardArtworkSection({Key? key, required this.viewModel})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArtbeatColors.primaryGreen.withValues(alpha: 0.05),
            ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context),
            const SizedBox(height: 16),
            _buildArtworkContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: ArtbeatColors.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.palette, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Artwork Gallery',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
              Text(
                'Explore beautiful artwork from local artists',
                style: TextStyle(
                  fontSize: 14,
                  color: ArtbeatColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [ArtbeatColors.primaryGreen, ArtbeatColors.primaryPurple],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/artwork/browse'),
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.explore, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'View All',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArtworkContent(BuildContext context) {
    if (viewModel.isLoadingArtwork) {
      return _buildLoadingState();
    }

    if (viewModel.artworkError != null) {
      return _buildErrorState();
    }

    final artworks = viewModel.artwork;

    if (artworks.isEmpty) {
      return _buildEmptyState(context);
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: artworks.length,
        itemBuilder: (context, index) {
          final artworkItem = artworks[index];
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 12,
              right: index == artworks.length - 1 ? 0 : 0,
            ),
            child: _buildArtworkCard(context, artworkItem),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 12),
            child: _buildSkeletonCard(),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: ArtbeatColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: ArtbeatColors.textSecondary,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Unable to load artwork',
              style: TextStyle(color: ArtbeatColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: ArtbeatColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.palette_outlined,
              color: ArtbeatColors.textSecondary,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'No artwork available',
              style: TextStyle(
                color: ArtbeatColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Check back soon for featured artwork!',
              style: TextStyle(color: ArtbeatColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtworkCard(BuildContext context, ArtworkModel artworkItem) {
    return Container(
      width: 180,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            '/artwork/detail',
            arguments: {'artworkId': artworkItem.id},
          ),
          borderRadius: BorderRadius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Artwork image (full background)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    color: ArtbeatColors.backgroundSecondary,
                  ),
                  child: _isValidImageUrl(artworkItem.imageUrl)
                      ? SecureNetworkImage(
                          imageUrl: artworkItem.imageUrl,
                          fit: BoxFit.cover,
                          enableThumbnailFallback: true,
                          placeholder: Container(
                            color: ArtbeatColors.backgroundSecondary,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: const Icon(
                            Icons.image,
                            color: ArtbeatColors.textSecondary,
                            size: 32,
                          ),
                        )
                      : Builder(
                          builder: (context) {
                            // Only log invalid URLs in debug mode to reduce spam
                            if (artworkItem.imageUrl.isNotEmpty) {
                              debugPrint(
                                '⚠️ Invalid artwork image URL: ${artworkItem.imageUrl}',
                              );
                            }
                            return const Icon(
                              Icons.image,
                              color: ArtbeatColors.textSecondary,
                              size: 32,
                            );
                          },
                        ),
                ),

                // Bottom gradient overlay for title and engagement
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          artworkItem.title.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 8),

                        // Engagement icons row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Appreciate (Heart/Palette)
                            _buildEngagementButton(
                              Icons.favorite_outline,
                              artworkItem.likesCount,
                              () => _handleAppreciate(context, artworkItem),
                            ),

                            // Gift to Artist
                            _buildEngagementButton(
                              Icons.card_giftcard,
                              0,
                              () => _handleGiftArtist(context, artworkItem),
                            ),

                            // Commission Artist
                            _buildEngagementButton(
                              Icons.work_outline,
                              0,
                              () =>
                                  _handleCommissionArtist(context, artworkItem),
                            ),

                            // Share
                            _buildEngagementButton(
                              Icons.share_outlined,
                              0,
                              () => _handleAmplify(context, artworkItem),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildEngagementButton(IconData icon, int count, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(count),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleAppreciate(BuildContext context, ArtworkModel artwork) async {
    try {
      final engagementService = ContentEngagementService();
      await engagementService.toggleEngagement(
        contentId: artwork.id.toString(),
        contentType: 'artwork',
        engagementType: EngagementType.like,
      );

      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(const SnackBar(content: Text('Artwork appreciated!')));
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _handleAmplify(BuildContext context, ArtworkModel artwork) async {
    try {
      // Create a caption for the community post
      final caption =
          '${artwork.title} by ${artwork.artistName}\n\n'
          '${artwork.description}\n\n'
          '#artwork #artbeat';

      // Navigate to CreatePostScreen with pre-filled artwork data
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => CreatePostScreen(
            prefilledImageUrl: artwork.imageUrl,
            prefilledCaption: caption,
          ),
        ),
      );

      // Track the share as an engagement
      final engagementService = ContentEngagementService();
      await engagementService.toggleEngagement(
        contentId: artwork.id.toString(),
        contentType: 'artwork',
        engagementType: EngagementType.share,
      );
    } catch (e) {
      AppLogger.error('Error sharing artwork: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: ${e.toString()}')),
        );
      }
    }
  }

  void _handleGiftArtist(BuildContext context, ArtworkModel artwork) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => GiftSelectionWidget(
        recipientId: artwork.artistId,
        recipientName: artwork.artistName,
      ),
    );
  }

  void _handleCommissionArtist(
    BuildContext context,
    ArtworkModel artwork,
  ) async {
    // Navigate to commission request screen for the artist
    Navigator.pushNamed(
      context,
      '/commission/request',
      arguments: {
        'artistId': artwork.artistId,
        'artistName': artwork.artistName,
      },
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: ArtbeatColors.backgroundSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(ArtbeatColors.primaryBlue),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty || url.trim().isEmpty) return false;

    // Check for invalid file URLs
    if (url == 'file:///' || url.startsWith('file:///') && url.length <= 8) {
      return false;
    }

    // Check for just the file scheme with no actual path
    if (url == 'file://' || url == 'file:') {
      return false;
    }

    // Check for malformed URLs that start with file:// but have no host
    if (url.startsWith('file://') && !url.startsWith('file:///')) {
      return false;
    }

    // Check for valid URL schemes
    return url.startsWith('http://') ||
        url.startsWith('https://') ||
        (url.startsWith('file:///') && url.length > 8);
  }
}
