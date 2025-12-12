import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_artist/artbeat_artist.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:cached_network_image/cached_network_image.dart';

/// Screen for showcasing featured artists with special layout and highlighting
class FeaturedArtistScreen extends StatefulWidget {
  const FeaturedArtistScreen({super.key});

  @override
  State<FeaturedArtistScreen> createState() => _FeaturedArtistScreenState();
}

class _FeaturedArtistScreenState extends State<FeaturedArtistScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _isLoading = true;
  List<core.ArtistProfileModel> _featuredArtists = [];

  @override
  void initState() {
    super.initState();
    _loadFeaturedArtists();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadFeaturedArtists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get featured artists based on active features
      final artists = await _subscriptionService.getFeaturedArtists();

      if (mounted) {
        setState(() {
          _featuredArtists = artists.take(10).toList(); // Limit to top 10
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  tr('artist_featured_artist_error_error_loading_featured'))),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToArtistProfile(core.ArtistProfileModel artist) {
    Navigator.pushNamed(
      context,
      '/artist/public-profile',
      arguments: {'userId': artist.userId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              core.ArtbeatColors.primaryPurple,
              core.ArtbeatColors.backgroundPrimary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom header with special featured styling
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Text(
                            tr('art_walk_featured_artists'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('art_walk_discover_exceptional_artists_making_waves_in_the_community'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Featured artists content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _featuredArtists.isEmpty
                        ? _buildEmptyState()
                        : _buildFeaturedContent(),
              ),
            ],
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
          const Icon(Icons.star_outline, size: 80, color: Colors.white54),
          const SizedBox(height: 16),
          Text(
            tr('art_walk_no_featured_artists_yet'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('art_walk_check_back_soon_for_amazing_featured_artists'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedContent() {
    return Column(
      children: [
        // Hero featured artist (first one)
        if (_featuredArtists.isNotEmpty)
          _buildHeroArtist(_featuredArtists.first),

        const SizedBox(height: 20),

        // Other featured artists grid
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  tr('art_walk_more_featured_artists'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: core.ArtbeatColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildArtistsGrid(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroArtist(core.ArtistProfileModel artist) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            core.ArtbeatColors.secondaryTeal,
            core.ArtbeatColors.primaryGreen,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToArtistProfile(artist),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Artist avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: ClipOval(
                    child: artist.profileImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: artist.profileImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                  ),
                ),
                const SizedBox(width: 20),

                // Artist info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              artist.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (artist.isVerified) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (artist.location != null)
                        Text(
                          artist.location!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (artist.bio != null)
                        Text(
                          artist.bio!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'FEATURED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtistsGrid() {
    final otherArtists = _featuredArtists.skip(1).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: otherArtists.length,
      itemBuilder: (context, index) {
        final artist = otherArtists[index];
        return _buildArtistCard(artist);
      },
    );
  }

  Widget _buildArtistCard(core.ArtistProfileModel artist) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToArtistProfile(artist),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image or placeholder
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      core.ArtbeatColors.primaryPurple,
                      core.ArtbeatColors.secondaryTeal,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    if (artist.coverImageUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: artist.coverImageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(Icons.image,
                                color: Colors.white, size: 40),
                          ),
                        ),
                      ),

                    // Featured badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'FEATURED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Artist info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Profile image
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: core.ArtbeatColors.primaryPurple,
                                width: 2),
                          ),
                          child: ClipOval(
                            child: artist.profileImageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: artist.profileImageUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) =>
                                        const Icon(
                                      Icons.person,
                                      size: 16,
                                    ),
                                  )
                                : const Icon(Icons.person, size: 16),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Name and verification
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  artist.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (artist.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (artist.location != null)
                      Text(
                        artist.location!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    if (artist.mediums.isNotEmpty)
                      Text(
                        artist.mediums.take(2).join(', '),
                        style: const TextStyle(
                          color: core.ArtbeatColors.primaryPurple,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
