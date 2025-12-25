import 'package:flutter/material.dart';
import 'package:artbeat_profile/src/widgets/glass_card.dart';

class FavoriteTile extends StatelessWidget {
  final dynamic id;
  final dynamic title;
  final dynamic description;
  final dynamic imageUrl;
  final Map<String, dynamic>? metadata;
  final bool isCurrentUser;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const FavoriteTile({
    Key? key,
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.metadata,
    required this.isCurrentUser,
    this.onRemove,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Hero(
          tag: 'favorite_$id',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (imageUrl != null && imageUrl.toString().isNotEmpty)
                ? Image.network(
                    imageUrl.toString(),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: Icon(
                      _getIconForType(metadata?['contentType'] as String?),
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
          ),
        ),
        title: Text(
          (title != null && title.toString().isNotEmpty) ? title.toString() : 'Unnamed Favorite',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description?.toString() ?? ''),
        trailing: isCurrentUser && onRemove != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onRemove,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'artwork':
        return Icons.palette_outlined;
      case 'capture':
        return Icons.camera_alt_outlined;
      case 'art_walk':
      case 'artwalk':
      case 'walk':
        return Icons.directions_walk_outlined;
      case 'profile':
        return Icons.person_outlined;
      case 'event':
        return Icons.event_outlined;
      default:
        return Icons.favorite_outline;
    }
  }
}
