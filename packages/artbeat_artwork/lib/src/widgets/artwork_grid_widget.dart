import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../models/artwork_model.dart';

/// Reusable artwork grid widget for displaying artworks in a consistent layout
/// Extracted from duplicate implementations to provide single source of truth
class ArtworkGridWidget extends StatelessWidget {
  final List<ArtworkModel> artworks;
  final void Function(ArtworkModel)? onArtworkTap;
  final void Function(ArtworkModel)? onArtworkEdit;
  final void Function(ArtworkModel)? onArtworkDelete;
  final Future<void> Function()? onRefresh;
  final bool showManagementActions;
  final int crossAxisCount;
  final double childAspectRatio;
  final ScrollController? scrollController;

  const ArtworkGridWidget({
    super.key,
    required this.artworks,
    this.onArtworkTap,
    this.onArtworkEdit,
    this.onArtworkDelete,
    this.onRefresh,
    this.showManagementActions = false,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.8,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final Widget scrollView = CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final artwork = artworks[index];
                return _buildArtworkCard(context, artwork);
              },
              childCount: artworks.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 80), // Space for potential FAB
        ),
      ],
    );

    // Return with or without RefreshIndicator based on whether onRefresh is provided
    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: scrollView,
      );
    } else {
      return scrollView;
    }
  }

  Widget _buildArtworkCard(BuildContext context, ArtworkModel artwork) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: onArtworkTap != null ? () => onArtworkTap!(artwork) : null,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Artwork image
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: _buildArtworkImage(artwork),
                  ),
                ),
                // Artwork details
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildArtworkDetails(context, artwork),
                ),
              ],
            ),
          ),

          // Management actions (edit/delete) - only show if enabled
          if (showManagementActions)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 20,
                  ),
                  onSelected: (value) =>
                      _handleMenuAction(context, value, artwork),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('art_walk_edit'.tr()),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('art_walk_delete'.tr(), style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArtworkImage(ArtworkModel artwork) {
    return _MultiUrlImageLoader(
      urls: [
        if (artwork.imageUrl.isNotEmpty &&
            Uri.tryParse(artwork.imageUrl)?.hasScheme == true)
          artwork.imageUrl,
        ...artwork.additionalImageUrls.where(
            (url) => url.isNotEmpty && Uri.tryParse(url)?.hasScheme == true),
      ],
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  Widget _buildArtworkDetails(BuildContext context, ArtworkModel artwork) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          artwork.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),

        // Medium
        if (artwork.medium.isNotEmpty)
          Text(
            artwork.medium,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: core.ArtbeatColors.textSecondary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 4),

        // Price and status
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Price
            if (artwork.price != null)
              Text(
                '\$${artwork.price!.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: core.ArtbeatColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
              )
            else
              Text(
                'art_walk_not_for_sale'.tr(),
                style: TextStyle(
                  color: core.ArtbeatColors.textSecondary,
                  fontSize: 10,
                ),
              ),

            // View count
            Row(
              children: [
                Icon(
                  Icons.visibility,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 2),
                Text(
                  '${artwork.viewCount}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _handleMenuAction(
      BuildContext context, String action, ArtworkModel artwork) {
    switch (action) {
      case 'edit':
        if (onArtworkEdit != null) {
          onArtworkEdit!(artwork);
        }
        break;
      case 'delete':
        if (onArtworkDelete != null) {
          _showDeleteConfirmation(context, artwork);
        }
        break;
    }
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, ArtworkModel artwork) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('art_walk_delete_artwork'.tr()),
        content: Text(
          'art_walk_delete_confirmation_message'.tr().replaceAll('{title}', artwork.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('art_walk_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('art_walk_delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && onArtworkDelete != null) {
      onArtworkDelete!(artwork);
    }
  }
}

/// A custom image loader that tries multiple URLs in sequence
class _MultiUrlImageLoader extends StatefulWidget {
  final List<String> urls;
  final double? width;
  final BoxFit? fit;

  const _MultiUrlImageLoader({
    required this.urls,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  State<_MultiUrlImageLoader> createState() => _MultiUrlImageLoaderState();
}

class _MultiUrlImageLoaderState extends State<_MultiUrlImageLoader> {
  int _currentUrlIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty || _currentUrlIndex >= widget.urls.length) {
      return _buildImagePlaceholder();
    }

    final currentUrl = widget.urls[_currentUrlIndex];

    return core.SecureNetworkImage(
      imageUrl: currentUrl,
      width: widget.width,
      fit: widget.fit,
      errorWidget: _buildErrorWidget(),
      enableThumbnailFallback: true,
    );
  }

  Widget _buildErrorWidget() {
    // Try next URL if available
    if (_currentUrlIndex < widget.urls.length - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentUrlIndex++;
          });
        }
      });
      // Return loading indicator while switching URLs
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // No more URLs to try, show placeholder
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: widget.width,
      color: Colors.grey[200],
      child: const Icon(
        Icons.image_not_supported,
        size: 48,
        color: Colors.grey,
      ),
    );
  }
}
