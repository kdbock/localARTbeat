import 'dart:async';

import 'package:artbeat_artist/artbeat_artist.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class _FilterOption {
  final String value;
  final String labelKey;

  const _FilterOption({required this.value, required this.labelKey});
}

/// Screen for browsing artists
class ArtistBrowseScreen extends StatefulWidget {
  final String mode;

  const ArtistBrowseScreen({super.key, this.mode = 'all'});

  @override
  State<ArtistBrowseScreen> createState() => _ArtistBrowseScreenState();
}

class _ArtistBrowseScreenState extends State<ArtistBrowseScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final ValueNotifier<List<core.ArtistProfileModel>> _artistsNotifier =
      ValueNotifier([]);
  DocumentSnapshot? _lastArtistDoc;
  late _FilterOption _selectedMedium;
  late _FilterOption _selectedStyle;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  static const List<_FilterOption> _mediumOptions = [
    _FilterOption(value: 'All', labelKey: 'artist_artist_browse_filter_all'),
    _FilterOption(
      value: 'Oil Paint',
      labelKey: 'artist_artist_browse_medium_oil_paint',
    ),
    _FilterOption(
      value: 'Acrylic',
      labelKey: 'artist_artist_browse_medium_acrylic',
    ),
    _FilterOption(
      value: 'Watercolor',
      labelKey: 'artist_artist_browse_medium_watercolor',
    ),
    _FilterOption(
      value: 'Digital',
      labelKey: 'artist_artist_browse_medium_digital',
    ),
    _FilterOption(
      value: 'Mixed Media',
      labelKey: 'artist_artist_browse_medium_mixed_media',
    ),
    _FilterOption(
      value: 'Photography',
      labelKey: 'artist_artist_browse_medium_photography',
    ),
  ];

  static const List<_FilterOption> _styleOptions = [
    _FilterOption(value: 'All', labelKey: 'artist_artist_browse_filter_all'),
    _FilterOption(
      value: 'Abstract',
      labelKey: 'artist_artist_browse_style_abstract',
    ),
    _FilterOption(
      value: 'Realism',
      labelKey: 'artist_artist_browse_style_realism',
    ),
    _FilterOption(
      value: 'Impressionism',
      labelKey: 'artist_artist_browse_style_impressionism',
    ),
    _FilterOption(
      value: 'Pop Art',
      labelKey: 'artist_artist_browse_style_pop_art',
    ),
    _FilterOption(
      value: 'Surrealism',
      labelKey: 'artist_artist_browse_style_surrealism',
    ),
    _FilterOption(
      value: 'Contemporary',
      labelKey: 'artist_artist_browse_style_contemporary',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedMedium = _mediumOptions.first;
    _selectedStyle = _styleOptions.first;
    _scrollController.addListener(_onScroll);
    _loadArtists(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _artistsNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadArtists({required bool reset}) async {
    if (reset) {
      if (_isLoading) return;
    } else {
      if (_isLoading || _isLoadingMore || !_hasMore) return;
    }

    setState(() {
      if (reset) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      if (reset) {
        _artistsNotifier.value = [];
        _lastArtistDoc = null;
        _hasMore = true;
      }

      final page = await _subscriptionService.getAllArtistsPage(
        searchQuery: _searchController.text,
        medium: _selectedMedium.value != 'All' ? _selectedMedium.value : null,
        style: _selectedStyle.value != 'All' ? _selectedStyle.value : null,
        startAfter: _lastArtistDoc,
        limit: 50,
      );

      // Filter for featured artists if mode is 'featured'
      final filteredArtists = widget.mode == 'featured'
          ? page.artists.where((artist) => artist.isFeatured).toList()
          : page.artists;

      if (mounted) {
        final currentArtists = List<core.ArtistProfileModel>.from(
          _artistsNotifier.value,
        );
        _artistsNotifier.value = [...currentArtists, ...filteredArtists];
        setState(() {
          _lastArtistDoc = page.lastDoc;
          _hasMore = page.hasMore;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('artist_artist_browse_error_error_loading_artists'),
            ),
          ),
        );
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _applyFilters() => _loadArtists(reset: true);

  void _resetFilters() {
    setState(() {
      _selectedMedium = _mediumOptions.first;
      _selectedStyle = _styleOptions.first;
      _searchController.clear();
    });
    _loadArtists(reset: true);
  }

  void _openProfile(core.ArtistProfileModel artist) {
    Navigator.pushNamed(
      context,
      '/artist/public-profile',
      arguments: {'artistId': artist.userId},
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {});
      if (value.isEmpty || value.length > 2) {
        _loadArtists(reset: true);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) {
      _loadArtists(reset: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFeaturedMode = widget.mode == 'featured';

    return core.MainLayout(
      currentIndex: -1,
      child: WorldBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HudTopBar(
                title: tr(
                  isFeaturedMode
                      ? 'artist_artist_browse_title_featured'
                      : 'artist_artist_browse_title_all',
                ),
                subtitle: tr(
                  isFeaturedMode
                      ? 'artist_artist_browse_subtitle_featured'
                      : 'artist_artist_browse_subtitle_all',
                ),
                onMenu: () => Navigator.of(context).pop(),
                menuIcon: Icons.arrow_back_rounded,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: _buildFiltersCard(isFeaturedMode),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersCard(bool isFeaturedMode) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientBadge(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFeaturedMode
                          ? Icons.local_fire_department_rounded
                          : Icons.travel_explore_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tr(
                        isFeaturedMode
                            ? 'artist_artist_browse_badge_featured'
                            : 'artist_artist_browse_badge_discover',
                      ),
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _showFilterDialog,
                icon: const Icon(Icons.tune_rounded, color: Colors.white),
                tooltip: tr('artist_artist_browse_filter_open'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tr('artist_artist_browse_heading'),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('artist_artist_browse_subheading'),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            decoration: GlassInputDecoration(
              hintText: tr('artist_artist_browse_hint_search'),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 22,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      tooltip: tr('artist_artist_browse_a11y_clear_search'),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                        _loadArtists(reset: true);
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FilterPill(
                icon: Icons.palette_rounded,
                label: tr(
                  'artist_artist_browse_pill_medium',
                  namedArgs: {'value': tr(_selectedMedium.labelKey)},
                ),
                onTap: _showFilterDialog,
              ),
              _FilterPill(
                icon: Icons.auto_awesome_rounded,
                label: tr(
                  'artist_artist_browse_pill_style',
                  namedArgs: {'value': tr(_selectedStyle.labelKey)},
                ),
                onTap: _showFilterDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          HudButton(
            label: tr('artist_artist_browse_cta_apply_filters'),
            icon: Icons.bolt_rounded,
            onPressed: _applyFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
        ),
      );
    }

    return ValueListenableBuilder<List<core.ArtistProfileModel>>(
      valueListenable: _artistsNotifier,
      builder: (context, artists, _) {
        if (_isLoading && artists.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
            ),
          );
        }

        if (artists.isEmpty) {
          return ArtistBrowseEmptyState(onReset: _resetFilters);
        }

        return _ArtistBrowseListView(
          artists: artists,
          controller: _scrollController,
          isLoadingMore: _isLoadingMore,
          onArtistTap: _openProfile,
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogContext) {
        _FilterOption tempMedium = _selectedMedium;
        _FilterOption tempStyle = _selectedStyle;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setInnerState) {
              return GlassCard(
                padding: const EdgeInsets.all(18),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('artist_artist_browse_text_filter_artists'),
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr('artist_artist_browse_filter_medium_label'),
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _mediumOptions
                            .map(
                              (option) => _FilterChoicePill(
                                option: option,
                                selected: tempMedium == option,
                                onTap: () =>
                                    setInnerState(() => tempMedium = option),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr('artist_artist_browse_filter_style_label'),
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _styleOptions
                            .map(
                              (option) => _FilterChoicePill(
                                option: option,
                                selected: tempStyle == option,
                                onTap: () =>
                                    setInnerState(() => tempStyle = option),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: GlassButton(
                              label: tr(
                                'artist_artist_browse_cta_reset_filters',
                              ),
                              icon: Icons.refresh_rounded,
                              onPressed: () {
                                setInnerState(() {
                                  tempMedium = _mediumOptions.first;
                                  tempStyle = _styleOptions.first;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: HudButton(
                              label: tr('artist_artist_browse_text_apply'),
                              icon: Icons.check_rounded,
                              onPressed: () {
                                setState(() {
                                  _selectedMedium = tempMedium;
                                  _selectedStyle = tempStyle;
                                });
                                Navigator.pop(dialogContext);
                                _applyFilters();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilterPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChoicePill extends StatelessWidget {
  final _FilterOption option;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChoicePill({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.12),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF22D3EE).withValues(alpha: 0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.brightness_1_rounded,
              size: 10,
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 10),
            Text(
              tr(option.labelKey),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: selected ? 0.96 : 0.82),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GlassTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ArtistBrowseEmptyState extends StatelessWidget {
  final VoidCallback onReset;

  const ArtistBrowseEmptyState({Key? key, required this.onReset})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('artist_artist_browse_text_no_artists_found'),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('artist_artist_browse_text_empty_state'),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            HudButton(
              label: tr('artist_artist_browse_cta_reset_filters'),
              icon: Icons.refresh_rounded,
              onPressed: onReset,
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistBrowseListView extends StatelessWidget {
  final List<core.ArtistProfileModel> artists;
  final ScrollController controller;
  final bool isLoadingMore;
  final ValueChanged<core.ArtistProfileModel> onArtistTap;

  const _ArtistBrowseListView({
    Key? key,
    required this.artists,
    required this.controller,
    required this.isLoadingMore,
    required this.onArtistTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      physics: const BouncingScrollPhysics(),
      itemCount: artists.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= artists.length) {
          return const _ArtistBrowseLoadingMoreIndicator();
        }
        final artist = artists[index];
        return RepaintBoundary(
          child: _ArtistBrowseCard(
            artist: artist,
            onTap: () => onArtistTap(artist),
          ),
        );
      },
    );
  }
}

class _ArtistBrowseCard extends StatelessWidget {
  final core.ArtistProfileModel artist;
  final VoidCallback onTap;

  const _ArtistBrowseCard({Key? key, required this.artist, required this.onTap})
    : super(key: key);

  bool get _isPremium => artist.subscriptionTier != core.SubscriptionTier.free;
  bool get _isGallery => artist.userType.name == core.UserType.gallery.name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0A1330), Color(0xFF071C18)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          image:
                              core.ImageUrlValidator.isValidImageUrl(
                                artist.coverImageUrl,
                              )
                              ? DecorationImage(
                                  image:
                                      core.ImageUrlValidator.safeNetworkImage(
                                        artist.coverImageUrl,
                                      )!,
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.black.withValues(alpha: 0.45),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Row(
                        children: [
                          if (artist.isFeatured)
                            GradientBadge(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tr('artist_artist_browse_badge_featured'),
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (artist.hasActiveBoost) ...[
                            if (artist.isFeatured) const SizedBox(width: 8),
                            Tooltip(
                              message: 'boost_badge_tooltip'.tr(),
                              child: GradientBadge(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF97316),
                                    Color(0xFF22D3EE),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.bolt_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'boost_badge_label'.tr(),
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (artist.isVerified) ...[
                            const SizedBox(width: 8),
                            GradientBadge(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF22D3EE), Color(0xFF34D399)],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tr('artist_artist_browse_badge_verified'),
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 14,
                      child: Row(
                        children: [
                          core.BoostPulseRing(
                            enabled: artist.hasActiveBoost,
                            ringPadding: 4,
                            ringWidth: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: core.UserAvatar(
                                imageUrl: artist.profileImageUrl,
                                displayName: artist.displayName,
                                radius: 36,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                artist.displayName,
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (_isGallery)
                                    _GlassTag(
                                      icon: Icons.storefront_rounded,
                                      label: tr(
                                        'artist_artist_browse_text_gallery',
                                      ),
                                    ),
                                  if (_isPremium) ...[
                                    if (_isGallery) const SizedBox(width: 8),
                                    _GlassTag(
                                      icon: Icons.star_rounded,
                                      label:
                                          artist.subscriptionTier ==
                                              core.SubscriptionTier.business
                                          ? tr(
                                              'artist_artist_browse_badge_business',
                                            )
                                          : tr(
                                              'artist_artist_browse_badge_premium',
                                            ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                artist.bio?.isNotEmpty == true
                    ? artist.bio!
                    : tr('artist_artist_browse_text_no_bio'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (artist.mediums.isEmpty)
                    _GlassTag(
                      icon: Icons.brush_rounded,
                      label: tr('artist_artist_browse_text_medium_unknown'),
                    )
                  else ...[
                    ...artist.mediums
                        .take(3)
                        .map(
                          (medium) => _GlassTag(
                            icon: Icons.brush_rounded,
                            label: medium,
                          ),
                        ),
                    if (artist.mediums.length > 3)
                      _GlassTag(
                        icon: Icons.add_rounded,
                        label: '+${artist.mediums.length - 3}',
                      ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              HudButton(
                label: tr('artist_artist_browse_cta_view_profile'),
                icon: Icons.chevron_right_rounded,
                onPressed: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtistBrowseLoadingMoreIndicator extends StatelessWidget {
  const _ArtistBrowseLoadingMoreIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
        ),
      ),
    );
  }
}
