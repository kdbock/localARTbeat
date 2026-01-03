import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show
        GlassCard,
        GradientCTAButton,
        HudTopBar,
        SecureNetworkImage,
        WorldBackground;
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../models/collection_model.dart';
import '../services/collection_service.dart';

/// Screen for browsing curated galleries and featured collections
class CuratedGalleryScreen extends StatefulWidget {
  const CuratedGalleryScreen({super.key});

  @override
  State<CuratedGalleryScreen> createState() => _CuratedGalleryScreenState();
}

class _CuratedGalleryScreenState extends State<CuratedGalleryScreen> {
  final CollectionService _collectionService = CollectionService();

  List<CollectionModel> _featuredCollections = [];
  List<CollectionModel> _publicCollections = [];
  bool _isLoading = false;
  String? _error;
  CollectionType? _filterType;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final futures = [
        _collectionService.getFeaturedCollections(),
        _collectionService.getPublicCollections(
          filterByType: _filterType,
          limit: 50,
        ),
      ];

      final results = await Future.wait(futures);

      if (!mounted) return;

      setState(() {
        _featuredCollections = results[0];
        _publicCollections = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshCollections() async {
    await _loadCollections();
  }

  void _filterCollections(CollectionType? type) {
    setState(() {
      _filterType = type;
    });
    _loadCollections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HudTopBar(
        title: 'curated_gallery_title'.tr(),
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
        actions: [
          PopupMenuButton<CollectionType?>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: _filterCollections,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Text('curated_gallery_filter_all'.tr()),
              ),
              ...CollectionType.values.map((type) => PopupMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  )),
            ],
          ),
        ],
      ),
      body: WorldBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
                  ),
                )
              : _error != null
                  ? _buildErrorState()
                  : RefreshIndicator(
                      onRefresh: _refreshCollections,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                        child: _buildContent(),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: GlassCard(
        radius: 26,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Color(0xFFFF3D8D),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'curated_gallery_error_loading'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _error ?? 'curated_gallery_error_unknown'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.76),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            GradientCTAButton(
              height: 46,
              text: 'curated_gallery_retry_button'.tr(),
              icon: Icons.refresh,
              onPressed: _loadCollections,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_featuredCollections.isEmpty && _publicCollections.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      slivers: [
        if (_featuredCollections.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: GlassCard(
              radius: 22,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFC857), Color(0xFF22D3EE)],
                      ),
                    ),
                    child: const Icon(Icons.star, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'curated_gallery_featured_section'.tr(),
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'curated_gallery_subtitle'.tr(),
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
          SliverToBoxAdapter(
            child: SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _featuredCollections.length,
                itemBuilder: (context, index) {
                  return _buildFeaturedCollectionCard(
                      _featuredCollections[index]);
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: const Icon(Icons.collections, color: Colors.white70),
                ),
                const SizedBox(width: 10),
                Text(
                  _filterType != null
                      ? '${_filterType!.displayName} Collections'
                      : 'curated_gallery_all_collections'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        if (_publicCollections.isEmpty)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'curated_gallery_no_collections'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          )
        else
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
                  return _buildPublicCollectionCard(_publicCollections[index]);
                },
                childCount: _publicCollections.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: GlassCard(
        radius: 26,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: const Icon(Icons.collections_outlined,
                      color: Colors.white70),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'curated_gallery_empty_title'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'curated_gallery_empty_message'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GradientCTAButton(
              height: 44,
              text: 'curated_gallery_refresh_button'.tr(),
              icon: Icons.refresh,
              onPressed: _loadCollections,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCollectionCard(CollectionModel collection) {
    return SizedBox(
      width: 240,
      child: GlassCard(
        margin: const EdgeInsets.only(right: 16),
        radius: 22,
        padding: EdgeInsets.zero,
        onTap: () => _navigateToCollectionDetail(collection),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: collection.coverImageUrl?.isNotEmpty == true
                    ? SecureNetworkImage(
                        imageUrl: collection.coverImageUrl!,
                        fit: BoxFit.cover,
                        enableThumbnailFallback: true,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF22D3EE).withValues(alpha: 0.8),
                              const Color(0xFF7C4DFF).withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.collections,
                              size: 48, color: Colors.white),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        collection.title,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber[600],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'curated_gallery_featured_badge'.tr(),
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    collection.type.displayName,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (collection.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      collection.description,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.image, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        '${collection.artworkIds.length} artworks',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.visibility,
                          size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        '${collection.viewCount}',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
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

  Widget _buildPublicCollectionCard(CollectionModel collection) {
    return GlassCard(
      padding: EdgeInsets.zero,
      radius: 18,
      onTap: () => _navigateToCollectionDetail(collection),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: collection.coverImageUrl?.isNotEmpty == true
                  ? SecureNetworkImage(
                      imageUrl: collection.coverImageUrl!,
                      fit: BoxFit.cover,
                      enableThumbnailFallback: true,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF22D3EE).withValues(alpha: 0.8),
                            const Color(0xFF34D399).withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.collections,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collection.title,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  collection.type.displayName,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.image, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      '${collection.artworkIds.length}',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.visibility,
                        size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      '${collection.viewCount}',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCollectionDetail(CollectionModel collection) {
    // Increment view count
    _collectionService.incrementViewCount(collection.id);

    // Navigate to collection detail
    Navigator.pushNamed(
      context,
      '/collection/detail',
      arguments: {'collectionId': collection.id, 'collection': collection},
    );
  }
}
