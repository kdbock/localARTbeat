import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show
        AppLogger,
        GlassCard,
        GradientCTAButton,
        HudTopBar,
        MainLayout,
        WorldBackground;
import 'package:google_fonts/google_fonts.dart';
import '../models/artwork_model.dart';
import '../services/artwork_pagination_service.dart';
import '../widgets/artwork_grid_widget.dart';

/// Screen for displaying recently uploaded artwork
class ArtworkRecentScreen extends StatefulWidget {
  const ArtworkRecentScreen({super.key});

  @override
  State<ArtworkRecentScreen> createState() => _ArtworkRecentScreenState();
}

class _ArtworkRecentScreenState extends State<ArtworkRecentScreen> {
  final ArtworkPaginationService _paginationService =
      ArtworkPaginationService();
  final ScrollController _scrollController = ScrollController();

  List<ArtworkModel> _recentArtworks = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialArtworks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialArtworks() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final state = await _paginationService.loadRecentArtworks();

      if (mounted) {
        setState(() {
          _recentArtworks = state.items;
          _lastDocument = state.lastDocument;
          _hasMore = state.hasMore;
          _isLoading = false;
        });

        AppLogger.info('Loaded ${_recentArtworks.length} recent artworks');
      }
    } catch (e) {
      AppLogger.error('Error loading recent artworks: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreArtworks() async {
    if (_isLoadingMore || !_hasMore) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final state = await _paginationService.loadRecentArtworks(
        lastDocument: _lastDocument,
      );

      if (mounted) {
        setState(() {
          _recentArtworks.addAll(state.items);
          _lastDocument = state.lastDocument;
          _hasMore = state.hasMore;
          _isLoadingMore = false;
        });

        AppLogger.info('Loaded ${state.items.length} more recent artworks');
      }
    } catch (e) {
      AppLogger.error('Error loading more artworks: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMoreArtworks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 0,
      appBar: HudTopBar(
        title: 'artwork_recent_title'.tr(),
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/search'),
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ],
      ),
      child: WorldBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                _buildHero(),
                const SizedBox(height: 12),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return GlassCard(
      radius: 26,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF22D3EE), Color(0xFF34D399)],
              ),
            ),
            child: const Icon(Icons.schedule, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'artwork_recent_title'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'artwork_recent_subtitle'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
        ),
      );
    }

    if (_error != null) {
      return GlassCard(
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
                    'artwork_discover_error'.tr(),
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
              _error ?? 'error_unknown'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.76),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            GradientCTAButton(
              height: 46,
              text: 'artwork_retry_button'.tr(),
              icon: Icons.refresh,
              onPressed: _loadInitialArtworks,
            ),
          ],
        ),
      );
    }

    if (_recentArtworks.isEmpty) {
      return GlassCard(
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
                    Icons.image_not_supported_outlined,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'artwork_recent_no_results'.tr(),
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
              'artwork_recent_empty_hint'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GradientCTAButton(
              height: 44,
              text: 'artwork_retry_button'.tr(),
              icon: Icons.refresh,
              onPressed: _loadInitialArtworks,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ArtworkGridWidget(
            artworks: _recentArtworks,
            onRefresh: _loadInitialArtworks,
            scrollController: _scrollController,
          ),
        ),
        // Loading indicator for pagination
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
