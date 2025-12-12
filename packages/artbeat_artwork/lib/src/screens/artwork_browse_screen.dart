import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart' show MainLayout;
import 'package:artbeat_ads/artbeat_ads.dart';
import '../models/artwork_model.dart';
import '../widgets/artwork_header.dart';

/// Screen for browsing all artwork, with filtering options
class ArtworkBrowseScreen extends StatefulWidget {
  const ArtworkBrowseScreen({super.key});

  @override
  State<ArtworkBrowseScreen> createState() => _ArtworkBrowseScreenState();
}

class _ArtworkBrowseScreenState extends State<ArtworkBrowseScreen> {
  final _searchController = TextEditingController();
  String _selectedLocation = 'All';
  String _selectedMedium = 'All';

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      // Get distinct locations from artwork collection
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('artwork').get();

      // Extract unique locations
      final Set<String> locations = {'All'};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final location = data['location'] as String?;
        if (location != null && location.isNotEmpty) {
          locations.add(location);
        }
      }

      // Store locations if needed for UI dropdowns later
    } catch (e) {
      // debugPrint('Error loading locations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex:
          0, // Dashboard tab - artwork browsing is accessed from dashboard
      appBar: ArtworkHeader(
        title: 'artwork_browse_title'.tr(),
        showBackButton: true,
        showSearch: true,
        showDeveloper: false,
        onSearchPressed: () => Navigator.pushNamed(context, '/search'),
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'artwork_search_hint'.tr(),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch();
                  },
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text('artwork_filters'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                if (_selectedLocation != 'All')
                  Chip(
                    label: Text(_selectedLocation),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _selectedLocation = 'All';
                      });
                      _performSearch();
                    },
                  ),
                const SizedBox(width: 8),
                if (_selectedMedium != 'All')
                  Chip(
                    label: Text(_selectedMedium),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _selectedMedium = 'All';
                      });
                      _performSearch();
                    },
                  ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _buildArtworkGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getArtworkStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('artwork_error_prefix'.tr() +
                (snapshot.error?.toString() ?? '')),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text('artwork_no_results'.tr()),
          );
        }

        final artworks =
            docs.map((doc) => ArtworkModel.fromFirestore(doc)).toList();

        return CustomScrollView(
          slivers: [
            // Slot 1: Header banner
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: AdSmallBannerWidget(
                  zone: LocalAdZone.artists,
                  height: 80,
                ),
              ),
            ),

            // Grid with interspersed ads
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Slot 2: Interspersed ad every 6th item
                    if (index > 0 && (index - 1) % 6 == 0) {
                      return const AdGridCardWidget(
                        zone: LocalAdZone.artists,
                        size: 150,
                      );
                    }

                    // Calculate actual artwork index accounting for ads
                    final int adsShown = (index - 1) ~/ 6;
                    final int artworkIndex = index - adsShown;

                    if (artworkIndex >= artworks.length) {
                      return const SizedBox.shrink();
                    }

                    final artwork = artworks[artworkIndex];
                    return GestureDetector(
                      onTap: () => _navigateToArtworkDetail(artwork.id),
                      child: Card(
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                color: Colors.grey[300],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                artwork.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: artworks.length + (artworks.length ~/ 6),
                ),
              ),
            ),

            // Slot 3: Filter section ad
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: AdSmallBannerWidget(
                  zone: LocalAdZone.artists,
                  height: 120,
                ),
              ),
            ),

            // Slot 4: Bottom load-more banner
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: AdSmallBannerWidget(
                  zone: LocalAdZone.artists,
                  height: 100,
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        );
      },
    );
  }

  Stream<QuerySnapshot> _getArtworkStream() {
    Query query = FirebaseFirestore.instance.collection('artwork');

    // Only show public artworks
    query = query.where('isPublic', isEqualTo: true);

    // Apply location filter if selected
    if (_selectedLocation != 'All') {
      query = query.where('location', isEqualTo: _selectedLocation);
    }

    // Apply medium filter if selected
    if (_selectedMedium != 'All') {
      query = query.where('medium', isEqualTo: _selectedMedium);
    }

    // Apply search by title if provided
    if (_searchController.text.isNotEmpty) {
      // For a simple search, we can use where with field path
      // This is not a full text search but works for exact matches
      query = query
          .where('title', isGreaterThanOrEqualTo: _searchController.text)
          .where('title',
              isLessThanOrEqualTo: '${_searchController.text}\uf8ff');
    }

    // Sort by creation date (newest first)
    return query.orderBy('createdAt', descending: true).snapshots();
  }

  void _performSearch() {
    // Trigger a rebuild to apply search
    setState(() {});
  }

  void _navigateToArtworkDetail(String artworkId) {
    Navigator.pushNamed(
      context,
      '/artist/artwork-detail',
      arguments: {'artworkId': artworkId},
    );
  }
}
