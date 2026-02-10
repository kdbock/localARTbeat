import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show
        GlassCard,
        GlassInputDecoration,
        GradientCTAButton,
        HudTopBar,
        MainLayout,
        SecureNetworkImage,
        WorldBackground;
import 'package:artbeat_ads/artbeat_ads.dart';
import '../models/artwork_model.dart';

/// Screen for browsing all artwork, with filtering options
class ArtworkBrowseScreen extends StatefulWidget {
  const ArtworkBrowseScreen({super.key});

  @override
  State<ArtworkBrowseScreen> createState() => _ArtworkBrowseScreenState();
}

class _ArtworkBrowseScreenState extends State<ArtworkBrowseScreen> {
  static const int _artworksPerAd = 6;
  static const int _adCycleLength = _artworksPerAd + 1;

  final _searchController = TextEditingController();
  String _selectedLocation = 'common_all'.tr();
  String _selectedMedium = 'common_all'.tr();
  List<String> _availableLocations = ['common_all'.tr()];
  List<String> _availableMediums = ['common_all'.tr()];
  bool _isLoadingFilters = true;

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilterOptions() async {
    setState(() {
      _isLoadingFilters = true;
    });

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('artwork')
          .where('isPublic', isEqualTo: true)
          .get();

      final Set<String> locations = {'common_all'.tr()};
      final Set<String> mediums = {'common_all'.tr()};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final location = (data['location'] as String?)?.trim();
        final medium = (data['medium'] as String?)?.trim();

        if (location != null && location.isNotEmpty) {
          locations.add(location);
        }
        if (medium != null && medium.isNotEmpty) {
          mediums.add(medium);
        }
      }

      if (!mounted) return;
      setState(() {
        _availableLocations = _sortFilterOptions(locations);
        _availableMediums = _sortFilterOptions(mediums);
        _isLoadingFilters = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingFilters = false;
      });
    }
  }

  List<String> _sortFilterOptions(Set<String> values) {
    final sorted = values.where((value) => value != 'common_all'.tr()).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ['common_all'.tr(), ...sorted];
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 0,
      appBar: HudTopBar(
        title: 'artwork_browse_title'.tr(),
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/search'),
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ],
        subtitle: '',
      ),
      child: WorldBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildSearchPanel(),
              _buildFilterPanel(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildArtworkGrid(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchPanel() {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
              ),
            ),
            child: Text(
              'artwork_browse_title'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'artwork_browse_subtitle'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'artwork_search_hint'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              final button = GradientCTAButton(
                text: 'art_walk_art_walk_list_text_apply_filters'.tr(),
                icon: Icons.tune,
                onPressed: _performSearch,
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSearchField(),
                    const SizedBox(height: 12),
                    button,
                  ],
                );
              }

              final buttonWidth = math.min(constraints.maxWidth * 0.35, 180.0);

              return Row(
                children: [
                  Expanded(child: _buildSearchField()),
                  const SizedBox(width: 12),
                  SizedBox(width: buttonWidth, child: button),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      cursorColor: const Color(0xFF22D3EE),
      decoration: GlassInputDecoration.search(
        hintText: 'artwork_search_hint'.tr(),
        prefixIcon: const Icon(Icons.search, color: Colors.white70),
        suffixIcon: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () {
            if (_searchController.text.isEmpty) {
              return;
            }
            _searchController.clear();
            _performSearch();
          },
        ),
      ),
      onSubmitted: (_) => _performSearch(),
    );
  }

  Widget _buildFilterPanel() {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'artwork_filters'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  label: 'artwork_location_label'.tr(),
                  value: _selectedLocation,
                  options: _availableLocations,
                  icon: Icons.place_outlined,
                  onChanged: (value) {
                    setState(() => _selectedLocation = value);
                    _performSearch();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  label: 'artwork_medium_label'.tr(),
                  value: _selectedMedium,
                  options: _availableMediums,
                  icon: Icons.category_outlined,
                  onChanged: (value) {
                    setState(() => _selectedMedium = value);
                    _performSearch();
                  },
                ),
              ),
            ],
          ),
          if (_isLoadingFilters) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
              backgroundColor: Colors.white24,
            ),
          ],
          if (_selectedLocation != 'common_all'.tr() ||
              _selectedMedium != 'common_all'.tr()) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_selectedLocation != 'common_all'.tr())
                  _buildActiveFilterChip(_selectedLocation, () {
                    setState(() => _selectedLocation = 'common_all'.tr());
                    _performSearch();
                  }),
                if (_selectedMedium != 'common_all'.tr())
                  _buildActiveFilterChip(_selectedMedium, () {
                    setState(() => _selectedMedium = 'common_all'.tr());
                    _performSearch();
                  }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> options,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    final resolvedValue = options.contains(value)
        ? value
        : (options.isNotEmpty ? options.first : 'common_all'.tr());
    return DropdownButtonFormField<String>(
      initialValue: resolvedValue,
      isExpanded: true,
      dropdownColor: const Color(0xFF07060F),
      iconEnabledColor: Colors.white,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      decoration: GlassInputDecoration.glass(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white70, size: 18),
      ),
      onChanged: (newValue) {
        if (newValue == null) {
          return;
        }
        onChanged(newValue);
      },
      selectedItemBuilder: (context) => options
          .map(
            (option) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                option,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      items: options
          .map(
            (option) => DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onDeleted) {
    return Chip(
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      label: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
      onDeleted: onDeleted,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildArtworkGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getArtworkStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'artwork_error_prefix'.tr() + (snapshot.error?.toString() ?? ''),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'artwork_no_results'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }

        final artworks = docs
            .map((doc) => ArtworkModel.fromFirestore(doc))
            .toList();

        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: AdSmallBannerWidget(
                  zone: LocalAdZone.artists,
                  height: 80,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if ((index + 1) % _adCycleLength == 0) {
                      return const AdGridCardWidget(
                        zone: LocalAdZone.artists,
                        size: 150,
                      );
                    }

                    final adsBefore = (index + 1) ~/ _adCycleLength;
                    final artworkIndex = index - adsBefore;

                    if (artworkIndex >= artworks.length) {
                      return const SizedBox.shrink();
                    }

                    final artwork = artworks[artworkIndex];
                    return _buildArtworkCard(artwork);
                  },
                  childCount:
                      artworks.length + (artworks.length ~/ _artworksPerAd),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: AdSmallBannerWidget(
                  zone: LocalAdZone.artists,
                  height: 120,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: AdSmallBannerWidget(
                  zone: LocalAdZone.artists,
                  height: 100,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }

  Widget _buildArtworkCard(ArtworkModel artwork) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      radius: 26,
      onTap: () => _navigateToArtworkDetail(artwork.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: _buildArtworkImage(artwork),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artwork.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (artwork.medium.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        artwork.medium,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if ((artwork.location ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: Colors.white54,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              artwork.location!,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          artwork.price != null
                              ? '\$${artwork.price!.toStringAsFixed(0)}'
                              : 'art_walk_not_for_sale'.tr(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: artwork.price != null
                                ? const Color(0xFF34D399)
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.visibility,
                              size: 14,
                              color: Colors.white54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${artwork.viewCount}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkImage(ArtworkModel artwork) {
    final imageUrl = _primaryImageUrl(artwork);
    if (imageUrl == null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1330), Color(0xFF07060F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            color: Colors.white38,
            size: 32,
          ),
        ),
      );
    }

    return SecureNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      enableThumbnailFallback: true,
    );
  }

  String? _primaryImageUrl(ArtworkModel artwork) {
    final candidates = [artwork.imageUrl, ...artwork.additionalImageUrls];
    for (final url in candidates) {
      if (url.isNotEmpty && Uri.tryParse(url)?.hasScheme == true) {
        return url;
      }
    }
    return null;
  }

  Stream<QuerySnapshot> _getArtworkStream() {
    Query query = FirebaseFirestore.instance.collection('artwork');

    query = query.where('isPublic', isEqualTo: true);

    if (_selectedLocation != 'common_all'.tr()) {
      query = query.where('location', isEqualTo: _selectedLocation);
    }

    if (_selectedMedium != 'common_all'.tr()) {
      query = query.where('medium', isEqualTo: _selectedMedium);
    }

    if (_searchController.text.isNotEmpty) {
      query = query
          .where('title', isGreaterThanOrEqualTo: _searchController.text)
          .where(
            'title',
            isLessThanOrEqualTo: '${_searchController.text}\uf8ff',
          );
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  void _performSearch() {
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
