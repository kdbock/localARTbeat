import 'package:artbeat_core/artbeat_core.dart' hide GlassCard;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import 'package:artbeat_art_walk/src/models/public_art_model.dart';
import 'package:artbeat_art_walk/src/widgets/glass_card.dart';

class PublicArtCard extends StatelessWidget {
  final PublicArtModel publicArt;
  final VoidCallback? onTap;

  const PublicArtCard({super.key, required this.publicArt, this.onTap});

  @override
  Widget build(BuildContext context) {
    final artworkImage = ImageUrlValidator.safeCorrectedNetworkImage(
      publicArt.imageUrl,
    );

    return Semantics(
      button: onTap != null,
      label: publicArt.title,
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _ArtworkThumbnail(imageProvider: artworkImage)),
              const SizedBox(height: 12),
              _TitleBlock(publicArt: publicArt),
              const SizedBox(height: 8),
              if (publicArt.artType != null) ...[
                _ArtTypeChip(type: publicArt.artType!),
                const SizedBox(height: 8),
              ],
              _StatsRow(publicArt: publicArt),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtworkThumbnail extends StatelessWidget {
  final ImageProvider? imageProvider;

  const _ArtworkThumbnail({required this.imageProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF472B6), Color(0xFFFB923C)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF472B6).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageProvider != null
            ? Image(
                image: imageProvider!,
                fit: BoxFit.cover,
                width: double.infinity,
              )
            : Container(
                color: Colors.white.withValues(alpha: 0.05),
                child: const Center(
                  child: Icon(Icons.palette, color: Colors.white70, size: 32),
                ),
              ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final PublicArtModel publicArt;

  const _TitleBlock({required this.publicArt});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          publicArt.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        if (publicArt.artistName != null) ...[
          const SizedBox(height: 2),
          Text(
            publicArt.artistName!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }
}

class _ArtTypeChip extends StatelessWidget {
  final String type;

  const _ArtTypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final PublicArtModel publicArt;

  const _StatsRow({required this.publicArt});

  @override
  Widget build(BuildContext context) {
    final viewCount = intl.NumberFormat.compact().format(publicArt.viewCount);
    final likeCount = intl.NumberFormat.compact().format(publicArt.likeCount);

    return Row(
      children: [
        _IconLabel(icon: Icons.visibility, label: viewCount),
        const SizedBox(width: 12),
        _IconLabel(icon: Icons.favorite, label: likeCount),
        const Spacer(),
        if (publicArt.isVerified)
          const Icon(Icons.verified, color: Color(0xFF34D399), size: 16),
      ],
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
        Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 12),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
