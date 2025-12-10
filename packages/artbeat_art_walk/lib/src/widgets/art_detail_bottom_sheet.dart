import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

/// Bottom sheet widget for displaying art details during art walk experience
class ArtDetailBottomSheet extends StatelessWidget {
  final PublicArtModel art;
  final VoidCallback? onVisitPressed;
  final bool isVisited;
  final String? distanceText;

  const ArtDetailBottomSheet({
    super.key,
    required this.art,
    this.onVisitPressed,
    this.isVisited = false,
    this.distanceText,
  });

  /// Navigate to Create Art Walk screen with this art piece pre-selected
  void _createArtWalk(BuildContext context) {
    // Close the current bottom sheet first
    Navigator.pop(context);

    // Navigate to Create Art Walk screen with this art piece
    Navigator.pushNamed(
      context,
      '/art-walk/create',
      arguments: {'capture': art},
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      if (ImageUrlValidator.safeCorrectedNetworkImage(
                            art.imageUrl,
                          ) !=
                          null) ...[
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[200],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image(
                              image:
                                  ImageUrlValidator.safeCorrectedNetworkImage(
                                    art.imageUrl,
                                  )!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 60,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Title
                      Text(
                        art.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Artist
                      if (art.artistName != null &&
                          art.artistName!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'by ${art.artistName!}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],

                      // Distance from current location
                      if (distanceText != null && distanceText!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.directions_walk,
                              size: 16,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              distanceText!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Description
                      if (art.description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          art.description,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],

                      // Address
                      if (art.address != null && art.address!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                art.address!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Art Type
                      if (art.artType != null && art.artType!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            art.artType!,
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],

                      // Tags
                      if (art.tags.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: art.tags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              backgroundColor: Colors.grey[100],
                              labelStyle: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // Stats
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Icon(
                                  Icons.visibility,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${art.viewCount}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Views',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${art.likeCount}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Likes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            if (art.isVerified)
                              Column(
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: Colors.blue[600],
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Create Art Walk button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _createArtWalk(context),
                        icon: const Icon(Icons.route),
                        label: Text('art_walk_art_detail_bottom_sheet_button_create_art_walk'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    // Visit button (if provided)
                    if (onVisitPressed != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isVisited ? null : onVisitPressed,
                          icon: Icon(
                            isVisited ? Icons.check_circle : Icons.location_on,
                          ),
                          label: Text(
                            isVisited ? 'Already Visited' : 'Mark as Visited',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isVisited
                                ? Colors.green
                                : Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
