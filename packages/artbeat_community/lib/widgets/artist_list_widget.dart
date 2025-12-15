import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
// Using ArtistProfileModel from artbeat_core to avoid conflicts
import '../screens/feed/artist_community_feed_screen.dart';

/// Widget that displays a list of available artists
class ArtistListWidget extends StatefulWidget {
  const ArtistListWidget({super.key});

  @override
  State<ArtistListWidget> createState() => _ArtistListWidgetState();
}

class _ArtistListWidgetState extends State<ArtistListWidget>
    with AutomaticKeepAliveClientMixin {
  final List<ArtistProfileModel> _artists = [];
  final Map<String, int> _followerCounts = {};
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _artists.clear();
      _followerCounts.clear();
    });

    try {
      AppLogger.info('Loading artists for community...');

      // Get all artist profiles
      final artistsSnapshot = await FirebaseFirestore.instance
          .collection('artistProfiles')
          .orderBy('displayName')
          .limit(50)
          .get();

      if (!mounted) return;

      AppLogger.info('Found ${artistsSnapshot.docs.length} artist documents');

      final loadedArtists = <ArtistProfileModel>[];
      for (final doc in artistsSnapshot.docs) {
        try {
          AppLogger.info('Processing artist document: ${doc.id}');
          final artist = ArtistProfileModel.fromFirestore(doc);
          loadedArtists.add(artist);

          // Get follower count for this artist
          final followerCount = await _getFollowerCount(doc.id);
          _followerCounts[doc.id] = followerCount;

          debugPrint(
            'Successfully loaded artist: ${artist.displayName} with $followerCount followers',
          );
        } catch (e) {
          AppLogger.error('Error parsing artist ${doc.id}: $e');
        }
      }

      AppLogger.info('Loaded ${loadedArtists.length} artists');

      if (mounted) {
        setState(() {
          _artists.addAll(loadedArtists);
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading artists: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load artists: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// Get the actual follower count for an artist from the artistFollows collection
  Future<int> _getFollowerCount(String artistProfileId) async {
    try {
      final followersSnapshot = await FirebaseFirestore.instance
          .collection('artistFollows')
          .where('artistProfileId', isEqualTo: artistProfileId)
          .get();

      return followersSnapshot.docs.length;
    } catch (e) {
      debugPrint(
        'Error getting follower count for artist $artistProfileId: $e',
      );
      return 0;
    }
  }

  String _formatFollowerCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              ArtbeatColors.primaryPurple,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading artists...',
            style: TextStyle(fontSize: 16, color: ArtbeatColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: ArtbeatColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Something went wrong',
            style: const TextStyle(
              fontSize: 16,
              color: ArtbeatColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadArtists,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.palette, size: 64, color: ArtbeatColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'No Artists Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ArtbeatColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Check back later for new artists!',
            style: TextStyle(fontSize: 14, color: ArtbeatColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistCard(ArtistProfileModel artist) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToArtistFeed(artist),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Artist Avatar
              CircleAvatar(
                radius: 30,
                backgroundImage: ImageUrlValidator.safeNetworkImage(
                  artist.profileImageUrl,
                ),
                child:
                    !ImageUrlValidator.isValidImageUrl(artist.profileImageUrl)
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),

              // Artist Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            artist.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (artist.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 18,
                            color: ArtbeatColors.primaryPurple,
                          ),
                        ],
                        if (artist.isFeatured) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ArtbeatColors.accentYellow.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'FEATURED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: ArtbeatColors.accentYellow,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (artist.location?.isNotEmpty == true) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: ArtbeatColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              artist.location ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: ArtbeatColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (artist.bio?.isNotEmpty == true) ...[
                      Text(
                        artist.bio!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ArtbeatColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Follower count
                    if (_followerCounts[artist.id] != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 14,
                            color: ArtbeatColors.primaryPurple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatFollowerCount(_followerCounts[artist.id]!)} followers',
                            style: const TextStyle(
                              fontSize: 14,
                              color: ArtbeatColors.primaryPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Mediums and Styles
                    if (artist.mediums.isNotEmpty ||
                        artist.styles.isNotEmpty) ...[
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          ...artist.mediums
                              .take(2)
                              .map(
                                (medium) => _buildTag(
                                  medium,
                                  ArtbeatColors.primaryPurple,
                                ),
                              ),
                          ...artist.styles
                              .take(2)
                              .map(
                                (style) => _buildTag(
                                  style,
                                  ArtbeatColors.primaryGreen,
                                ),
                              ),
                          if (artist.mediums.length + artist.styles.length > 4)
                            _buildTag(
                              '+${artist.mediums.length + artist.styles.length - 4}',
                              ArtbeatColors.textSecondary,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow Icon
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: ArtbeatColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  void _navigateToArtistFeed(ArtistProfileModel artist) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ArtistCommunityFeedScreen(artist: artist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_artists.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadArtists,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _artists.length,
        itemBuilder: (context, index) {
          return _buildArtistCard(_artists[index]);
        },
      ),
    );
  }
}
