import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/artbeat_core.dart'
    hide GlassCard, WorldBackground, HudTopBar, GradientCTAButton;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtDetailBottomSheet extends StatelessWidget {
  final PublicArtModel art;
  final VoidCallback? onVisitPressed;
  final bool isVisited;
  final String? distanceText;

  const ArtDetailBottomSheet({
    super.key,
    required this.art,
    this.onVisitPressed,
    this.isVisited = false,
    this.distanceText,
  });

  void _createArtWalk(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushNamed(
      context,
      '/art-walk/create',
      arguments: {'capture': art},
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = ImageUrlValidator.safeCorrectedNetworkImage(
      art.imageUrl,
    );
    final tags = art.tags.where((tag) => tag.trim().isNotEmpty).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      maxChildSize: 0.94,
      minChildSize: 0.3,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF07060F), Color(0xFF0A1330), Color(0xFF071C18)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(38)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroArt(
                          media: imageProvider,
                          art: art,
                          distanceText: distanceText,
                        ),
                        const SizedBox(height: 18),
                        GlassCard(
                          borderRadius: 28,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                art.title,
                                style: AppTypography.screenTitle(),
                              ),
                              if (art.artistName != null &&
                                  art.artistName!.trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'art_walk_art_detail_bottom_sheet_text_by_artist'
                                      .tr(
                                        namedArgs: {'artist': art.artistName!},
                                      ),
                                  style: AppTypography.body(
                                    Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                              if (art.description.trim().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  art.description,
                                  style: AppTypography.body(
                                    Colors.white.withValues(alpha: 0.78),
                                  ),
                                ),
                              ],
                              if (distanceText != null &&
                                  distanceText!.trim().isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _InfoRow(
                                  icon: Icons.directions_walk,
                                  label: distanceText!,
                                ),
                              ],
                              if (art.address != null &&
                                  art.address!.trim().isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _InfoRow(
                                  icon: Icons.location_on,
                                  label: art.address!,
                                ),
                              ],
                              if (art.artType != null &&
                                  art.artType!.trim().isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _FloatingChip(
                                  icon: Icons.style,
                                  label: art.artType!,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          GlassCard(
                            borderRadius: 28,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'art_walk_art_detail_bottom_sheet_text_tags_label'
                                      .tr(),
                                  style: AppTypography.sectionLabel(
                                    Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: tags
                                      .map(
                                        (tag) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.14,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            tag,
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        GlassCard(
                          borderRadius: 28,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'art_walk_art_detail_bottom_sheet_text_stats_label'
                                    .tr(),
                                style: AppTypography.sectionLabel(
                                  Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _StatTile(
                                    icon: Icons.visibility,
                                    label:
                                        'art_walk_art_detail_bottom_sheet_text_views'
                                            .tr(),
                                    value: art.viewCount.toString(),
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  _StatTile(
                                    icon: Icons.favorite,
                                    label:
                                        'art_walk_art_detail_bottom_sheet_text_likes'
                                            .tr(),
                                    value: art.likeCount.toString(),
                                    color: const Color(0xFFFF3D8D),
                                  ),
                                  if (art.isVerified) ...[
                                    const SizedBox(width: 12),
                                    _StatTile(
                                      icon: Icons.verified,
                                      label:
                                          'art_walk_art_detail_bottom_sheet_text_verified'
                                              .tr(),
                                      value: '—',
                                      color: const Color(0xFF22D3EE),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (onVisitPressed != null && !isVisited) ...[
                          GradientCTAButton(
                            label:
                                'art_walk_art_detail_bottom_sheet_button_mark_visited'
                                    .tr(),
                            icon: Icons.check_circle,
                            onPressed: onVisitPressed,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (onVisitPressed != null && isVisited) ...[
                          GlassCard(
                            borderRadius: 24,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF34D399),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'art_walk_art_detail_bottom_sheet_button_visited'
                                        .tr(),
                                    style: AppTypography.body(
                                      Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        _GlassOutlineButton(
                          icon: Icons.route,
                          label:
                              'art_walk_art_detail_bottom_sheet_button_create_art_walk'
                                  .tr(),
                          onPressed: () => _createArtWalk(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroArt extends StatelessWidget {
  final ImageProvider? media;
  final PublicArtModel art;
  final String? distanceText;

  const _HeroArt({
    required this.media,
    required this.art,
    required this.distanceText,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 32,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: media != null
                  ? Image(image: media!, fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1F1B2E), Color(0xFF0B2030)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 46,
                        ),
                      ),
                    ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.64),
                    ],
                  ),
                ),
              ),
            ),
            if (distanceText != null && distanceText!.trim().isNotEmpty)
              Positioned(
                top: 16,
                right: 16,
                child: _FloatingChip(
                  icon: Icons.directions_walk,
                  label: distanceText!,
                ),
              ),
            if (art.isVerified)
              Positioned(
                top: 16,
                left: 16,
                child: _FloatingChip(
                  icon: Icons.verified,
                  label: 'art_walk_art_detail_bottom_sheet_text_verified'.tr(),
                  accentColor: const Color(0xFF22D3EE),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTypography.body(Colors.white.withValues(alpha: 0.85)),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accentColor;

  const _FloatingChip({
    required this.icon,
    required this.label,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        color: color.withValues(alpha: 0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassOutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _GlassOutlineButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          foregroundColor: Colors.white,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
