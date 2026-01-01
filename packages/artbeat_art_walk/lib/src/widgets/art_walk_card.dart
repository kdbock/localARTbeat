import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import 'package:artbeat_art_walk/src/models/art_walk_model.dart';

class ArtWalkCard extends StatelessWidget {
  final ArtWalkModel artWalk;
  final VoidCallback? onTap;
  final bool showFullDescription;

  const ArtWalkCard({
    super.key,
    required this.artWalk,
    this.onTap,
    this.showFullDescription = false,
  });

  @override
  Widget build(BuildContext context) {
    final coverImage = ImageUrlValidator.safeCorrectedNetworkImage(
      artWalk.coverImageUrl,
    );

    return Semantics(
      button: onTap != null,
      label: artWalk.title,
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          borderRadius: 28,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CoverThumbnail(imageProvider: coverImage),
                  const SizedBox(width: 16),
                  Expanded(child: _TitleBlock(artWalk: artWalk)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                artWalk.description,
                maxLines: showFullDescription ? null : 3,
                overflow: showFullDescription
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 16),
              _MetadataRow(artWalk: artWalk),
              const SizedBox(height: 16),
              _StatsWrap(artWalk: artWalk),
              if (artWalk.tags != null && artWalk.tags!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _TagWrap(tags: artWalk.tags!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverThumbnail extends StatelessWidget {
  final ImageProvider? imageProvider;

  const _CoverThumbnail({required this.imageProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: imageProvider != null
            ? Image(image: imageProvider!, fit: BoxFit.cover)
            : Container(
                color: Colors.white.withValues(alpha: 0.05),
                child: const Icon(Icons.route, color: Colors.white70, size: 28),
              ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final ArtWalkModel artWalk;

  const _TitleBlock({required this.artWalk});

  @override
  Widget build(BuildContext context) {
    final viewCount = intl.NumberFormat.compact().format(artWalk.viewCount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                artWalk.title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            if (artWalk.isFlagged)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3D8D).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF3D8D).withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  Icons.report_gmailerrorred,
                  color: Colors.pinkAccent.shade100,
                  size: 16,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _IconLabel(icon: Icons.visibility, label: viewCount),
            if (artWalk.completionCount != null) ...[
              const SizedBox(width: 12),
              _IconLabel(
                icon: Icons.flag,
                label: intl.NumberFormat.compact().format(
                  artWalk.completionCount!,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final ArtWalkModel artWalk;

  const _MetadataRow({required this.artWalk});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _StatusChip(
        icon: artWalk.isPublic ? Icons.public : Icons.lock_outline,
        label: artWalk.isPublic
            ? 'art_walk_art_walk_card_chip_public'.tr()
            : 'art_walk_art_walk_card_chip_private'.tr(),
      ),
    ];

    if (artWalk.isAccessible == true) {
      chips.add(
        _StatusChip(
          icon: Icons.accessible,
          label: 'art_walk_art_walk_card_chip_accessible'.tr(),
        ),
      );
    }

    if (artWalk.difficulty != null && artWalk.difficulty!.isNotEmpty) {
      chips.add(
        _StatusChip(icon: Icons.trending_up, label: artWalk.difficulty!),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }
}

class _StatsWrap extends StatelessWidget {
  final ArtWalkModel artWalk;

  const _StatsWrap({required this.artWalk});

  @override
  Widget build(BuildContext context) {
    final stats = <Widget>[];

    if (artWalk.estimatedDuration != null) {
      stats.add(
        _StatPill(
          icon: Icons.access_time,
          label: 'art_walk_art_walk_card_text_duration'.tr(
            namedArgs: {
              'minutes': artWalk.estimatedDuration!.toStringAsFixed(0),
            },
          ),
        ),
      );
    }

    if (artWalk.estimatedDistance != null) {
      stats.add(
        _StatPill(
          icon: Icons.straighten,
          label: 'art_walk_art_walk_card_text_distance'.tr(
            namedArgs: {'miles': artWalk.estimatedDistance!.toStringAsFixed(1)},
          ),
        ),
      );
    }

    stats.add(
      _StatPill(
        icon: Icons.palette,
        label: 'art_walk_art_walk_card_text_artworks'.tr(
          namedArgs: {'count': artWalk.artworkIds.length.toString()},
        ),
      ),
    );

    if (artWalk.zipCode != null && artWalk.zipCode!.isNotEmpty) {
      stats.add(
        _StatPill(
          icon: Icons.location_on,
          label: 'art_walk_art_walk_card_text_zip'.tr(
            namedArgs: {'zip': artWalk.zipCode!},
          ),
        ),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: stats);
  }
}

class _TagWrap extends StatelessWidget {
  final List<String> tags;

  const _TagWrap({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.take(4).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Text(
            tag,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatusChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _IconLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
