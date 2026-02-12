import 'package:flutter/material.dart';
import '../models/artwork_model.dart';

/// A reusable card widget for displaying written content (books, stories, etc.)
class BookCard extends StatelessWidget {
  final ArtworkModel artwork;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const BookCard({
    super.key,
    required this.artwork,
    this.onTap,
    this.width = 140,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image
              Expanded(
                flex: 3,
                child: artwork.imageUrl.isNotEmpty
                    ? Image.network(
                        artwork.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(context),
                      )
                    : _buildPlaceholder(context),
              ),

              // Content info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        artwork.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 1),

                      // Author
                      Text(
                        artwork.artistName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Status/Type
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (artwork.isSerializing) ...[
                            Icon(
                              Icons.schedule,
                              size: 10,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Ongoing',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(fontSize: 8),
                            ),
                          ] else ...[
                            Icon(
                              Icons.check_circle,
                              size: 10,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Complete',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(fontSize: 8),
                            ),
                          ],
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
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.book,
          size: 40,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
