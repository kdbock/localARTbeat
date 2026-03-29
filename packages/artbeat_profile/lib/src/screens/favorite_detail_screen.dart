import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_core/auth_service.dart' as core_auth;
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

class FavoriteDetailScreen extends StatefulWidget {
  final String favoriteId;
  final String userId;

  const FavoriteDetailScreen({
    super.key,
    required this.favoriteId,
    required this.userId,
  });

  @override
  State<FavoriteDetailScreen> createState() => _FavoriteDetailScreenState();
}

class _FavoriteDetailScreenState extends State<FavoriteDetailScreen> {
  bool _isLoading = true;
  bool _isCurrentUser = false;
  Map<String, dynamic>? _favoriteData;

  UserService get _userService => context.read<UserService>();

  @override
  void initState() {
    super.initState();
    final currentUser = context.read<core_auth.AuthService>().currentUser;
    _isCurrentUser = currentUser != null && currentUser.uid == widget.userId;
    _loadFavoriteDetails();
  }

  Future<void> _loadFavoriteDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _userService.getFavoriteById(widget.favoriteId);
      setState(() {
        _favoriteData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading favorite: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text((_favoriteData?['title'] as String?) ?? 'Favorite Detail'),
        actions: _isCurrentUser
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Remove from favorites',
                  onPressed: _confirmRemoveFavorite,
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteData == null
          ? _buildNotFoundState()
          : _buildDetailView(theme),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text(
            'Favorite not found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'The favorite you\'re looking for might have been removed.',
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('profile_favorite_go_back'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailView(ThemeData theme) {
    final data = _favoriteData!;
    final String type = data['type'] as String? ?? 'unknown';
    final String? imageUrl = data['imageUrl'] as String?;
    final String title = data['title'] as String? ?? 'Untitled';
    final String description = data['description'] as String? ?? '';
    final String content = data['content'] as String? ?? '';
    final String? sourceUrl = data['sourceUrl'] as String?;
    final int createdTimestamp = data['createdAt'] is int
        ? data['createdAt'] as int
        : int.tryParse(data['createdAt']?.toString() ?? '') ?? 0;
    final DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(
      createdTimestamp,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero image or icon
          if (imageUrl != null && imageUrl.isNotEmpty)
            Hero(
              tag: 'favorite_${widget.favoriteId}',
              child: Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, obj, st) => Container(
                  height: 200,
                  color: theme.primaryColor.withAlpha(25),
                  child: Center(
                    child: Icon(
                      _getIconForType(type),
                      size: 64,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 180,
              color: theme.primaryColor.withAlpha(25),
              child: Center(
                child: Icon(
                  _getIconForType(type),
                  size: 64,
                  color: theme.primaryColor,
                ),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Type badge
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getTypeDisplay(type),
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                if (description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                if (content.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Content',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(content, style: const TextStyle(fontSize: 16)),
                  ),
                ],

                // Source URL if available
                if (sourceUrl != null && sourceUrl.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Source',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final uri = Uri.tryParse(sourceUrl);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not open URL: $sourceUrl'),
                          ),
                        );
                      }
                    },
                    child: Text(
                      sourceUrl,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],

                // Created timestamp
                const SizedBox(height: 32),
                Text(
                  'Added on ${_formatDate(createdAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'word':
        return Icons.text_fields;
      case 'quote':
        return Icons.format_quote;
      case 'article':
        return Icons.article;
      case 'book':
        return Icons.book;
      case 'author':
        return Icons.person;
      case 'content':
      default:
        return Icons.favorite;
    }
  }

  String _getTypeDisplay(String type) {
    // Convert the type to title case (First letter capital, rest lowercase)
    if (type.isEmpty) return 'Unknown';
    return '${type[0].toUpperCase()}${type.substring(1).toLowerCase()}';
  }

  Future<void> _confirmRemoveFavorite() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Favorite'),
        content: const Text(
          'Are you sure you want to remove this from your favorites?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('profile_favorite_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _userService.removeFromFavorites(widget.favoriteId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorites')),
          );
          // Go back to the favorites list
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing favorite: ${e.toString()}')),
          );
        }
      }
    }
  }
}
