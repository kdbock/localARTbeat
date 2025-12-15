import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DashboardArtistsSection extends StatefulWidget {
  final DashboardViewModel viewModel;

  const DashboardArtistsSection({Key? key, required this.viewModel})
    : super(key: key);

  @override
  State<DashboardArtistsSection> createState() =>
      _DashboardArtistsSectionState();
}

class _DashboardArtistsSectionState extends State<DashboardArtistsSection> {
  // Track loading states for each artist
  final Map<String, bool> _loadingStates = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
            ArtbeatColors.primaryGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context),
            const SizedBox(height: 16),
            _buildArtistsContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: ArtbeatColors.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.people, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'dashboard_artists_title'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
              Text(
                'dashboard_artists_subtitle'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  color: ArtbeatColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [ArtbeatColors.primaryPurple, ArtbeatColors.primaryGreen],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/artist/browse'),
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.explore, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'View All',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArtistsContent(BuildContext context) {
    if (widget.viewModel.isLoadingArtists) {
      return _buildLoadingState();
    }

    if (widget.viewModel.artistsError != null) {
      return _buildErrorState();
    }

    final artists = widget.viewModel.artists;

    if (artists.isEmpty) {
      return _buildEmptyState(context);
    }

    return SizedBox(
      height: 140, // Updated to match new card height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 12,
              right: index == artists.length - 1 ? 0 : 0,
            ),
            child: _buildArtistCard(context, artist),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 160, // Updated to match new card height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 12),
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 160, // Updated to match new card height
      decoration: BoxDecoration(
        color: ArtbeatColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: ArtbeatColors.textSecondary,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Unable to load artists',
              style: TextStyle(color: ArtbeatColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 160, // Updated to match new card height
      decoration: BoxDecoration(
        color: ArtbeatColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              color: ArtbeatColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'No featured artists yet',
              style: TextStyle(
                color: ArtbeatColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back soon for featured artists!',
              style: TextStyle(color: ArtbeatColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/artist/search'),
              icon: const Icon(Icons.search, size: 16),
              label: Text('dashboard_find_artists'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtbeatColors.primaryPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistCard(BuildContext context, ArtistProfileModel artist) {
    return Container(
      width: 150,
      height: 160, // Increased to accommodate larger avatar
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top row: Follow icon, Avatar, Commission icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Follow icon (left of avatar)
                  _buildFollowButton(context, artist),

                  // Avatar (center)
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/artist/public-profile',
                      arguments: {'artistId': artist.userId},
                    ),
                    child: Container(
                      width: 65,
                      height: 65,
                      margin: const EdgeInsets.only(
                        top: 8,
                      ), // Move down slightly
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            ArtbeatColors.primaryPurple,
                            ArtbeatColors.primaryGreen,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: ClipOval(
                          child:
                              (artist.profileImageUrl != null &&
                                  artist.profileImageUrl?.isNotEmpty == true)
                              ? CachedNetworkImage(
                                  imageUrl: artist.profileImageUrl ?? '',
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                        Icons.person,
                                        color: ArtbeatColors.textSecondary,
                                        size: 30,
                                      ),
                                )
                              : const Icon(
                                  Icons.person,
                                  color: ArtbeatColors.textSecondary,
                                  size: 30,
                                ),
                        ),
                      ),
                    ),
                  ),

                  // Commission icon (right of avatar)
                  _buildCommissionButton(context, artist),
                ],
              ),

              // Follower count (beneath follow button)
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '${_formatFollowerCount(artist.followersCount)} followers',
                  style: const TextStyle(
                    fontSize: 10,
                    color: ArtbeatColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Artist name (links to profile)
              const SizedBox(height: 4),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/artist/public-profile',
                    arguments: {'artistId': artist.userId},
                  ),
                  child: Text(
                    artist.displayName.isNotEmpty
                        ? artist.displayName
                        : 'Unknown Artist',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ArtbeatColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowButton(BuildContext context, ArtistProfileModel artist) {
    final isFollowing = artist.isFollowing;
    final isLoading = _loadingStates[artist.userId] ?? false;

    return GestureDetector(
      onTap: isLoading ? null : () => _handleFollowAction(context, artist),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isFollowing
              ? ArtbeatColors.primaryPurple.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFollowing
                ? ArtbeatColors.primaryPurple
                : Colors.grey.withValues(alpha: 0.3),
            width: isFollowing ? 1.5 : 1,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ArtbeatColors.primaryPurple,
                  ),
                ),
              )
            : Icon(
                isFollowing ? Icons.person_remove : Icons.person_add,
                size: 16,
                color: isFollowing ? ArtbeatColors.primaryPurple : Colors.grey,
              ),
      ),
    );
  }

  Widget _buildCommissionButton(
    BuildContext context,
    ArtistProfileModel artist,
  ) {
    return GestureDetector(
      onTap: () => _handleCommissionAction(context, artist),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.purple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Icon(Icons.work, size: 16, color: Colors.purple),
      ),
    );
  }

  void _handleFollowAction(
    BuildContext context,
    ArtistProfileModel artist,
  ) async {
    if (_loadingStates[artist.userId] == true) return;

    setState(() {
      _loadingStates[artist.userId] = true;
    });

    try {
      // Toggle follow status using the content engagement service
      final engagementService = ContentEngagementService();
      final newFollowState = await engagementService.toggleEngagement(
        contentId: artist.userId,
        contentType: 'profile',
        engagementType: EngagementType.follow,
      );

      // Update the artist model with new follow state and count
      if (mounted) {
        final updatedArtist = artist.copyWith(
          isFollowing: newFollowState,
          followersCount: newFollowState
              ? artist.followersCount + 1
              : (artist.followersCount - 1).clamp(0, double.infinity).toInt(),
        );

        // Update the artist in the viewModel
        widget.viewModel.updateArtist(updatedArtist);

        // Show feedback
        final message = newFollowState
            ? 'Following ${artist.displayName}'
            : 'Unfollowed ${artist.displayName}';

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'dashboard_failed_to_follow'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingStates[artist.userId] = false;
        });
      }
    }
  }

  void _handleCommissionAction(
    BuildContext context,
    ArtistProfileModel artist,
  ) async {
    // Navigate to commission request screen
    Navigator.pushNamed(
      context,
      '/commission/request',
      arguments: {'artistId': artist.userId, 'artistName': artist.displayName},
    );
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
}
