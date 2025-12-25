import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_profile/widgets/widgets.dart';

class FavoritesScreen extends StatefulWidget {
  final String userId;

  const FavoritesScreen({super.key, required this.userId});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _userService = core.UserService();
  final _currentUser = FirebaseAuth.instance.currentUser;
  List<core.FavoriteModel> _favorites = [];
  bool _isLoading = true;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _isCurrentUser = widget.userId == _currentUser?.uid;
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final likedContent = await _userService.getUserLikedContent();
      final parsed = likedContent
          .map((f) => core.FavoriteModel.fromMap(f, f['id'] as String))
          .toList();
      if (mounted) {
        setState(() {
          _favorites = parsed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'profile_favorites_screen_error_error_loading_liked_content'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
          ),
        );
      }
    }
  }

  void _navigateToContent(core.FavoriteModel favorite) {
    final contentId = favorite.metadata?['originalContentId'] as String?;
    final contentType = favorite.metadata?['contentType'] as String?;

    if (contentId == null || contentType == null) return;

    switch (contentType.toLowerCase()) {
      case 'artwork':
        Navigator.pushNamed(context, '/artwork/detail', arguments: contentId);
        break;
      case 'capture':
        Navigator.pushNamed(context, '/capture/detail', arguments: contentId);
        break;
      case 'art_walk':
      case 'artwalk':
      case 'walk':
        Navigator.pushNamed(context, '/art-walk/detail', arguments: contentId);
        break;
      case 'profile':
        Navigator.pushNamed(
          context,
          '/profile/view',
          arguments: {'userId': contentId},
        );
        break;
      case 'event':
        Navigator.pushNamed(context, '/event/detail', arguments: contentId);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'profile_favorites_screen_error_cannot_open_content'.tr(
                namedArgs: {'contentType': contentType},
              ),
            ),
          ),
        );
    }
  }

  Future<void> _confirmRemove(String favoriteId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('profile_favorites_screen_text_remove_like'.tr()),
        content: Text('profile_favorite_confirm_unlike'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('profile_favorites_screen_text_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('profile_favorites_screen_text_unlike'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('engagements')
            .doc(favoriteId)
            .delete();

        if (mounted) {
          setState(() {
            _favorites.removeWhere((f) => f.id == favoriteId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'profile_favorites_screen_success_removed_from_liked_content'
                    .tr(),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'profile_favorites_screen_error_error_unliking_content'.tr(
                  namedArgs: {'error': e.toString()},
                ),
              ),
            ),
          );
        }
      }
    }
  }

  Widget _buildFavoriteCard(core.FavoriteModel favorite) {
    final hasImage = favorite.imageUrl.isNotEmpty;

    return GlassCard(
      onTap: () => _navigateToContent(favorite),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: hasImage
                ? Image.network(
                    favorite.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackBox(favorite),
                  )
                : _fallbackBox(favorite),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  favorite.title.isNotEmpty
                      ? favorite.title
                      : 'Unnamed Favorite',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (favorite.description.isNotEmpty)
                  Text(
                    favorite.description,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (_isCurrentUser)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmRemove(favorite.id),
            ),
        ],
      ),
    );
  }

  Widget _fallbackBox(core.FavoriteModel fav) {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey.shade300,
      child: Icon(
        _iconForType(fav.type),
        color: core.ArtbeatColors.primaryPurple,
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _favorites.isEmpty
                  ? EmptyState(
                      icon: Icons.favorite_border,
                      message: _isCurrentUser
                          ? 'profile_favorite_empty_self'.tr()
                          : 'profile_favorite_empty_other'.tr(),
                      buttonLabel: _isCurrentUser
                          ? 'profile_favorite_discover'.tr()
                          : null,
                      onPressed: _isCurrentUser
                          ? () => Navigator.pushNamed(context, '/community')
                          : null,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFavorites,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _favorites.length,
                        itemBuilder: (_, i) =>
                            _buildFavoriteCard(_favorites[i]),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
