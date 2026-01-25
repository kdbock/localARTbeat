import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show GlassCard, GradientCTAButton, SecureNetworkImage;
import '../models/artwork_model.dart';
import '../services/artwork_discovery_service.dart';

/// Widget for displaying artwork discovery recommendations
class ArtworkDiscoveryWidget extends StatefulWidget {
  final String? userId;
  final int limit;
  final String title;
  final String? subtitleKey;
  final VoidCallback? onSeeAllPressed;

  const ArtworkDiscoveryWidget({
    super.key,
    this.userId,
    this.limit = 10,
    this.title = 'artwork_discovery_title',
    this.subtitleKey,
    this.onSeeAllPressed,
  });

  @override
  State<ArtworkDiscoveryWidget> createState() => _ArtworkDiscoveryWidgetState();
}

class _ArtworkDiscoveryWidgetState extends State<ArtworkDiscoveryWidget> {
  final ArtworkDiscoveryService _discoveryService = ArtworkDiscoveryService();
  List<ArtworkModel> _recommendations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      setState(() => _isLoading = true);
      final recommendations = await _discoveryService.getDiscoveryFeed(
        limit: widget.limit,
        userId: widget.userId,
      );
      setState(() {
        _recommendations = recommendations.cast<ArtworkModel>();
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
    if (_isLoading) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'art_walk_loading_recommendations'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFFF3D8D)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'art_walk_error_heading'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'art_walk_failed_to_load_recommendations'.tr(
                namedArgs: {'error': _error ?? '—'},
              ),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            GradientCTAButton(
              height: 44,
              text: 'art_walk_retry'.tr(),
              onPressed: _loadRecommendations,
              icon: Icons.refresh,
            ),
          ],
        ),
      );
    }

    if (_recommendations.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: const Icon(
                    Icons.explore_outlined,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'art_walk_no_recommendations_available'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'art_walk_no_recommendations_subtitle'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final resolvedTitle = widget.title.tr();
    final resolvedSubtitle = widget.subtitleKey?.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolvedTitle,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.95),
                        letterSpacing: 0.4,
                      ),
                    ),
                    if (resolvedSubtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        resolvedSubtitle,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.onSeeAllPressed != null)
                GradientCTAButton(
                  height: 44,
                  width: 120,
                  text: 'art_walk_see_all'.tr(),
                  icon: Icons.chevron_right,
                  onPressed: widget.onSeeAllPressed,
                ),
            ],
          ),
        ),

        SizedBox(
          height: 236,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _recommendations.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _buildArtworkCard(context, _recommendations[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildArtworkCard(BuildContext context, ArtworkModel artwork) {
    return SizedBox(
      width: 210,
      child: GlassCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(12),
        radius: 22,
        onTap: () {
          Navigator.of(context).pushNamed(
            '/artist/artwork-detail',
            arguments: {'artworkId': artwork.id},
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: SecureNetworkImage(
                  imageUrl: artwork.imageUrl,
                  fit: BoxFit.cover,
                  enableThumbnailFallback: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
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
            if (artwork.isForSale && artwork.price != null) ...[
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.sell_outlined,
                label: '\$${artwork.price!.toStringAsFixed(0)}',
                color: const Color(0xFF34D399),
              ),
            ],
          ],
        ),
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
      children: [
        Icon(icon, size: 14, color: color ?? Colors.white70),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              color: (color ?? Colors.white).withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
