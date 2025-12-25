import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class FavoriteGridItem {
  final String id;
  final String imageUrl;
  final String? contentType;

  FavoriteGridItem({
    required this.id,
    required this.imageUrl,
    this.contentType,
  });
}

class FavoriteGrid extends StatelessWidget {
  final List<FavoriteGridItem> items;
  final void Function(FavoriteGridItem)? onTap;

  const FavoriteGrid({
    super.key,
    required this.items,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => onTap?.call(item),
          child: Hero(
            tag: 'favorite_${item.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: Icon(
                        _iconForType(item.contentType),
                        color: ArtbeatColors.primaryPurple,
                        size: 32,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  IconData _iconForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'artwork':
        return Icons.palette_outlined;
      case 'capture':
        return Icons.camera_alt_outlined;
      case 'art_walk':
      case 'walk':
        return Icons.directions_walk_outlined;
      case 'event':
        return Icons.event_outlined;
      default:
        return Icons.favorite_outline;
    }
  }
}
