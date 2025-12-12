import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:easy_localization/easy_localization.dart';

class FavoritesScreen extends StatefulWidget {
  final String userId;

  const FavoritesScreen({super.key, required this.userId});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final core.UserService _userService = core.UserService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  List<core.FavoriteModel> _favorites = [];
  bool _isLoading = true;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _isCurrentUser = currentUser != null && currentUser!.uid == widget.userId;
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final likedContent = await _userService.getUserLikedContent();
      if (!mounted) return;

      setState(() {
        _favorites = likedContent
            .map((f) => core.FavoriteModel.fromMap(f, f['id'] as String))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'profile_favorites_screen_error_error_loading_liked_content'
                  .tr()
                  .replaceAll('{error}', e.toString()),
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: -1,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                core.ArtbeatColors.primaryPurple.withAlpha(13), // 0.05 opacity
                Colors.white,
                core.ArtbeatColors.primaryGreen.withAlpha(13), // 0.05 opacity
              ],
            ),
          ),
          child: SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: core.ArtbeatColors.primaryPurple,
                    ),
                  )
                : _favorites.isEmpty
                ? _buildEmptyState()
                : _buildFavoritesList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.favorite_border,
            size: 80,
            color: core.ArtbeatColors.accentYellow,
          ),
          const SizedBox(height: 16),
          Text(
            _isCurrentUser
                ? 'You haven\'t liked any content yet'
                : 'This user hasn\'t liked any content yet',
            style: const TextStyle(
              fontSize: 16,
              color: core.ArtbeatColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (_isCurrentUser) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to discover content
                Navigator.pushNamed(context, '/community');
              },
              icon: const Icon(Icons.explore),
              label: Text('profile_favorite_discover'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: core.ArtbeatColors.primaryPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final favorite = _favorites[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
            child: ListTile(
              leading: Hero(
                tag: 'favorite_${favorite.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: favorite.imageUrl.isNotEmpty
                      ? Image.network(
                          favorite.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, obj, st) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: Icon(
                            _getIconForType(favorite.type),
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                ),
              ),
              title: Text(
                favorite.title.isNotEmpty ? favorite.title : 'Unnamed Favorite',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(favorite.description),
              trailing: _isCurrentUser
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmRemoveFavorite(favorite.id),
                    )
                  : null,
              onTap: () {
                // Navigate to the appropriate content based on type
                final contentType =
                    favorite.metadata?['contentType'] as String?;
                final contentId =
                    favorite.metadata?['originalContentId'] as String?;

                if (contentId != null && contentType != null) {
                  switch (contentType.toLowerCase()) {
                    case 'artwork':
                      Navigator.pushNamed(
                        context,
                        '/artwork/detail',
                        arguments: contentId,
                      );
                      break;
                    case 'capture':
                      Navigator.pushNamed(
                        context,
                        '/capture/detail',
                        arguments: contentId,
                      );
                      break;
                    case 'art_walk':
                    case 'artwalk':
                    case 'walk':
                      Navigator.pushNamed(
                        context,
                        '/art-walk/detail',
                        arguments: contentId,
                      );
                      break;
                    case 'profile':
                      Navigator.pushNamed(
                        context,
                        '/profile/view',
                        arguments: {'userId': contentId},
                      );
                      break;
                    case 'event':
                      Navigator.pushNamed(
                        context,
                        '/event/detail',
                        arguments: contentId,
                      );
                      break;
                    default:
                      // Fallback: try to open as generic content
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'profile_favorites_screen_error_cannot_open_content'
                                .tr()
                                .replaceAll('{contentType}', contentType),
                          ),
                        ),
                      );
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
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
        return Icons.favorite_outlined;
    }
  }

  Future<void> _confirmRemoveFavorite(String favoriteId) async {
    final result = await showDialog<bool>(
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

    if (result == true) {
      try {
        // Remove the engagement (like) from Firestore
        await FirebaseFirestore.instance
            .collection('engagements')
            .doc(favoriteId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'profile_favorites_screen_success_removed_from_liked_content'
                    .tr(),
              ),
            ),
          );
          _loadFavorites(); // Refresh the list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'profile_favorites_screen_error_error_unliking_content'
                    .tr()
                    .replaceAll('{error}', e.toString()),
              ),
            ),
          );
        }
      }
    }
  }
}
