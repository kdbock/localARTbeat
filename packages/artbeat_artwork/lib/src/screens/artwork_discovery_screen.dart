import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show
        GlassCard,
        GradientCTAButton,
        HudTopBar,
        MainLayout,
        SecureNetworkImage,
        WorldBackground;
import '../models/artwork_model.dart';
import '../services/artwork_discovery_service.dart';

/// Screen for displaying artwork discovery features
class ArtworkDiscoveryScreen extends StatefulWidget {
  const ArtworkDiscoveryScreen({super.key});

  @override
  State<ArtworkDiscoveryScreen> createState() => _ArtworkDiscoveryScreenState();
}

class _ArtworkDiscoveryScreenState extends State<ArtworkDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  final ArtworkDiscoveryService _discoveryService = ArtworkDiscoveryService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TabController _tabController;
  List<ArtworkModel> _trendingArtworks = [];
  List<ArtworkModel> _personalizedArtworks = [];
  List<ArtworkModel> _similarArtworks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDiscoveryContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDiscoveryContent() async {
    try {
      setState(() => _isLoading = true);

      final userId = _auth.currentUser?.uid;

      // Load different types of recommendations in parallel
      final results = await Future.wait([
        _discoveryService.getTrendingArtworks(limit: 20),
        if (userId != null)
          _discoveryService.getPersonalizedRecommendations(
            limit: 20,
            userId: userId,
          )
        else
          Future.value(<ArtworkModel>[]),
        // For similar artworks, we'll use a placeholder - in real usage this would be based on current artwork
        _discoveryService.getDiscoveryFeed(limit: 20, userId: userId),
      ]);

      setState(() {
        _trendingArtworks = results[0].cast<ArtworkModel>();
        _personalizedArtworks = results[1].cast<ArtworkModel>();
        _similarArtworks = results[2].cast<ArtworkModel>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 0,
      appBar: HudTopBar(
        title: 'artwork_discovery_title'.tr(),
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).maybePop(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'artwork_discover_loading'.tr(),
            onPressed: _loadDiscoveryContent,
          ),
        ],
        subtitle: '',
      ),
      child: WorldBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  radius: 24,
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                      ),
                    ),
                    labelStyle: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: [
                      Tab(text: 'artwork_personalized_tab'.tr()),
                      Tab(text: 'artwork_trending_tab'.tr()),
                      Tab(text: 'artwork_similar_tab'.tr()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _isLoading
                      ? _buildLoadingView()
                      : _error != null
                      ? _buildErrorView()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildPersonalizedTab(),
                            _buildTrendingTab(),
                            _buildSimilarTab(),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'artwork_discover_loading'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        radius: 26,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 36,
                  width: 36,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'common_error'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            GradientCTAButton(
              height: 46,
              text: 'common_retry'.tr(),
              icon: Icons.refresh,
              onPressed: _loadDiscoveryContent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizedTab() {
    final userId = _auth.currentUser?.uid;

    if (userId == null) {
      return _buildSignInPrompt();
    }

    if (_personalizedArtworks.isEmpty) {
      return _buildEmptyState(
        title: 'artwork_discovery_empty_personalized_title'.tr(),
        message: 'artwork_discovery_empty_personalized_body'.tr(),
      );
    }

    return _buildArtworkGrid(
      _personalizedArtworks,
      'artwork_discovery_section_personalized'.tr(),
    );
  }

  Widget _buildTrendingTab() {
    if (_trendingArtworks.isEmpty) {
      return _buildEmptyState(
        title: 'artwork_discovery_empty_trending_title'.tr(),
        message: 'artwork_discovery_empty_trending_body'.tr(),
      );
    }

    return _buildArtworkGrid(
      _trendingArtworks,
      'artwork_discovery_section_trending'.tr(),
    );
  }

  Widget _buildSimilarTab() {
    if (_similarArtworks.isEmpty) {
      return _buildEmptyState(
        title: 'artwork_discovery_empty_similar_title'.tr(),
        message: 'artwork_discovery_empty_similar_body'.tr(),
      );
    }

    return _buildArtworkGrid(
      _similarArtworks,
      'artwork_discovery_section_similar'.tr(),
    );
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: GlassCard(
        radius: 26,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.login, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              'artwork_discovery_sign_in_title'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'artwork_discovery_sign_in_body'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            GradientCTAButton(
              height: 48,
              text: 'art_walk_sign_in'.tr(),
              icon: Icons.arrow_forward_rounded,
              onPressed: () => Navigator.of(context).pushNamed('/auth/login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required String title, required String message}) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        radius: 24,
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
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.explore_outlined,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
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
              message,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtworkGrid(List<ArtworkModel> artworks, String title) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.78,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final artwork = artworks[index];
            return _buildArtworkCard(artwork);
          }, childCount: artworks.length),
        ),
      ],
    );
  }

  Widget _buildArtworkCard(ArtworkModel artwork) {
    return GlassCard(
      padding: EdgeInsets.zero,
      radius: 22,
      onTap: () {
        Navigator.pushNamed(
          context,
          '/artwork/detail',
          arguments: {'artworkId': artwork.id},
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: SecureNetworkImage(
                imageUrl: artwork.imageUrl,
                fit: BoxFit.cover,
                enableThumbnailFallback: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artwork.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                if (artwork.medium.isNotEmpty)
                  _InfoRow(icon: Icons.palette_outlined, label: artwork.medium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (artwork.isForSale && artwork.price != null)
                      _InfoRow(
                        icon: Icons.sell_outlined,
                        label: '\$${artwork.price!.toStringAsFixed(0)}',
                        color: const Color(0xFF34D399),
                      ),
                    if (artwork.isForSale && artwork.price != null)
                      const SizedBox(width: 10),
                    _InfoRow(
                      icon: Icons.visibility,
                      label: '${artwork.viewCount}',
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    const SizedBox(width: 10),
                    _InfoRow(
                      icon: Icons.comment_outlined,
                      label: '${artwork.commentCount}',
                      color: Colors.white.withValues(alpha: 0.75),
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
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoRow({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.white70),
        const SizedBox(width: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.spaceGrotesk(
            color: (color ?? Colors.white).withValues(alpha: 0.85),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
