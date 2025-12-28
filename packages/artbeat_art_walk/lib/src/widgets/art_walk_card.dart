import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/src/models/art_walk_model.dart';

/// Individual art walk card for display in lists and search results
///
/// Features:
/// - Displays art walk title, description, and metadata
/// - Shows distance, duration, and number of art pieces
/// - Supports both compact and expanded description modes
/// - Includes visual indicators for completed walks
/// - Provides tap interaction for navigation to detail view
/// - Responsive design for different screen sizes
///
/// Usage:
/// ```dart
/// ArtWalkCard(
///   artWalk: myArtWalk,
///   onTap: () => navigateToDetail(myArtWalk.id),
///   showFullDescription: true,
/// )
/// ```
class ArtWalkCard extends StatelessWidget {
  /// The art walk data to display
  final ArtWalkModel artWalk;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  /// Whether to show the full description or truncate it
  final bool showFullDescription;

  const ArtWalkCard({
    Key? key,
    required this.artWalk,
    this.onTap,
    this.showFullDescription = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and metadata
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover image or placeholder
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade200,
                    ),
                    child:
                        ImageUrlValidator.safeCorrectedNetworkImage(
                              artWalk.coverImageUrl,
                            ) !=
                            null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image(
                              image:
                                  ImageUrlValidator.safeCorrectedNetworkImage(
                                    artWalk.coverImageUrl,
                                  )!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade300,
                                  child: Icon(
                                    Icons.route,
                                    color: Colors.grey.shade500,
                                    size: 24,
                                  ),
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.route,
                            color: Colors.grey.shade400,
                            size: 24,
                          ),
                  ),

                  const SizedBox(width: 16),

                  // Title and metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artWalk.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // Metadata row
                        Row(
                          children: [
                            if (artWalk.difficulty != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getDifficultyColor(
                                    artWalk.difficulty!,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  artWalk.difficulty!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: _getDifficultyColor(
                                      artWalk.difficulty!,
                                    ),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],

                            if (artWalk.isAccessible == true) ...[
                              Icon(
                                Icons.accessible,
                                size: 16,
                                color: theme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                            ],

                            Icon(
                              Icons.visibility,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${artWalk.viewCount}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Public indicator
                  if (artWalk.isPublic)
                    Icon(Icons.public, size: 16, color: theme.primaryColor),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                artWalk.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
                maxLines: showFullDescription ? null : 2,
                overflow: showFullDescription ? null : TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  if (artWalk.estimatedDuration != null) ...[
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${artWalk.estimatedDuration!.toInt()} min',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  if (artWalk.estimatedDistance != null) ...[
                    Icon(
                      Icons.straighten,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${artWalk.estimatedDistance!.toStringAsFixed(1)} mi',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  Icon(Icons.palette, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${artWalk.artworkIds.length} artworks',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const Spacer(),

                  if (artWalk.zipCode != null) ...[
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      artWalk.zipCode!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),

              // Tags if available
              if (artWalk.tags != null && artWalk.tags!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: artWalk.tags!.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
