import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_artist/artbeat_artist.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;

/// Screen for browsing verified artists
class VerifiedArtistScreen extends StatefulWidget {
  const VerifiedArtistScreen({super.key});

  @override
  State<VerifiedArtistScreen> createState() => _VerifiedArtistScreenState();
}

class _VerifiedArtistScreenState extends State<VerifiedArtistScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _isLoading = true;
  List<core.ArtistProfileModel> _artists = [];
  String _selectedMedium = 'All';
  String _selectedStyle = 'All';
  final TextEditingController _searchController = TextEditingController();

  // Filter options
  final List<String> _mediums = [
    'All',
    'Oil Paint',
    'Acrylic',
    'Watercolor',
    'Digital',
    'Mixed Media',
    'Photography'
  ];
  final List<String> _styles = [
    'All',
    'Abstract',
    'Realism',
    'Impressionism',
    'Pop Art',
    'Surrealism',
    'Contemporary'
  ];

  @override
  void initState() {
    super.initState();
    _loadVerifiedArtists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVerifiedArtists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get verified artists with current filters
      final artists = await _subscriptionService.getVerifiedArtists();

      // Apply client-side filtering for medium and style
      var filteredArtists = artists;

      if (_selectedMedium != 'All') {
        filteredArtists = filteredArtists
            .where((artist) => artist.mediums.contains(_selectedMedium))
            .toList();
      }

      if (_selectedStyle != 'All') {
        filteredArtists = filteredArtists
            .where((artist) => artist.styles.contains(_selectedStyle))
            .toList();
      }

      // Apply search filter
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        filteredArtists = filteredArtists
            .where((artist) =>
                artist.displayName.toLowerCase().contains(query) ||
                (artist.bio?.toLowerCase().contains(query) ?? false))
            .toList();
      }

      if (mounted) {
        setState(() {
          _artists = filteredArtists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  tr('artist_verified_artist_error_error_loading_verified'))),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    _loadVerifiedArtists();
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: -1, // No bottom navigation for this screen
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              core.ArtbeatColors.backgroundSecondary,
              core.ArtbeatColors.backgroundPrimary,
            ],
          ),
        ),
        child: Column(
          children: [
            // Custom header
            Container(
              padding: const EdgeInsets.only(top: 50, bottom: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    core.ArtbeatColors.verified,
                    core.ArtbeatColors.primaryBlue
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Verified Artists',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      tr('art_walk_explore_artists_who_have_been_verified_for_authenticity_and_quality'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search verified artists...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _loadVerifiedArtists();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  if (value.isEmpty || value.length > 2) {
                    _loadVerifiedArtists();
                  }
                },
              ),
            ),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  FilterChip(
                    label: Text(
                        tr('artist_artist_browse_text_medium_selectedmedium')),
                    selected: _selectedMedium != 'All',
                    onSelected: (_) => _showFilterDialog(),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(
                        tr('artist_artist_browse_text_style_selectedstyle')),
                    selected: _selectedStyle != 'All',
                    onSelected: (_) => _showFilterDialog(),
                  ),
                ],
              ),
            ),

            // Results
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _artists.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.verified_user,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                tr('art_walk_no_verified_artists_found'),
                                style: const TextStyle(
                                    fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _artists.length,
                          itemBuilder: (context, index) {
                            final artist = _artists[index];
                            return _buildArtistCard(artist);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistCard(core.ArtistProfileModel artist) {
    final bool isPremium =
        artist.subscriptionTier != core.SubscriptionTier.free;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isPremium ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPremium
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/artist/public-profile',
            arguments: {'artistId': artist.userId},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image and profile picture
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover image
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    image: artist.coverImageUrl != null &&
                            artist.coverImageUrl!.isNotEmpty &&
                            Uri.tryParse(artist.coverImageUrl!)?.hasScheme ==
                                true
                        ? DecorationImage(
                            image: NetworkImage(artist.coverImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: artist.coverImageUrl == null ||
                            artist.coverImageUrl!.isEmpty ||
                            Uri.tryParse(artist.coverImageUrl!)?.hasScheme !=
                                true
                        ? Colors.grey[300]
                        : null,
                  ),
                ),

                // Profile picture
                Positioned(
                  bottom: -40,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: core.UserAvatar(
                      imageUrl: artist.profileImageUrl,
                      displayName: artist.displayName,
                      radius: 40,
                    ),
                  ),
                ),

                // Verified badge (prominent)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: core.ArtbeatColors.verified,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tr('art_walk_verified'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Featured badge (if also featured)
                if (artist.isFeatured)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 45), // Space for profile pic

            // Artist info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          artist.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (artist.userType.name == core.UserType.gallery.name)
                        Chip(
                          label: Text(tr('artist_artist_browse_text_gallery')),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withAlpha(51),
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    artist.bio ?? 'No bio provided',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...artist.mediums.take(2).map((medium) => Chip(
                            label: Text(medium),
                            backgroundColor:
                                Theme.of(context).chipTheme.backgroundColor,
                            labelPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          )),
                      if (artist.mediums.length > 2)
                        Chip(
                          label: Text(tr(
                              'artist_artist_browse_text_artistmediumslength_2')),
                          backgroundColor:
                              Theme.of(context).chipTheme.backgroundColor,
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        String tempMedium = _selectedMedium;
        String tempStyle = _selectedStyle;

        return AlertDialog(
          title:
              Text(tr('artist_verified_artist_text_filter_verified_artists')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Medium',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _mediums.map((medium) {
                    return ChoiceChip(
                      label: Text(medium),
                      selected: tempMedium == medium,
                      onSelected: (selected) {
                        setState(() {
                          tempMedium = selected ? medium : 'All';
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(tr('art_walk_style'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _styles.map((style) {
                    return ChoiceChip(
                      label: Text(style),
                      selected: tempStyle == style,
                      onSelected: (selected) {
                        setState(() {
                          tempStyle = selected ? style : 'All';
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(tr('admin_admin_payment_text_cancel')),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedMedium = tempMedium;
                  _selectedStyle = tempStyle;
                });
                Navigator.pop(context);
                _applyFilters();
              },
              child: Text(tr('artist_artist_browse_text_apply')),
            ),
          ],
        );
      },
    );
  }
}
