import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/commission_artist_preview_model.dart';
import '../routing/app_routes.dart';
import '../services/commission_artist_preview_service.dart';
import '../theme/artbeat_colors.dart';

class CommissionArtistsPreview extends StatefulWidget {
  const CommissionArtistsPreview({super.key, this.showHeader = true});

  final bool showHeader;

  @override
  State<CommissionArtistsPreview> createState() =>
      _CommissionArtistsPreviewState();
}

class _CommissionArtistsPreviewState extends State<CommissionArtistsPreview> {
  late final CommissionArtistPreviewService _service;
  final Map<String, String> _artistNames = {};

  bool _isLoading = false;
  List<CommissionArtistPreviewModel> _artists = [];

  @override
  void initState() {
    super.initState();
    _service = context.read<CommissionArtistPreviewService>();
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    setState(() => _isLoading = true);
    try {
      final artists = await _service.getAvailableArtists();
      final names = await _service.getArtistNames(
        artists.map((artist) => artist.artistId),
      );
      if (!mounted) return;
      setState(() {
        _artists = artists;
        _artistNames
          ..clear()
          ..addAll(names);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Artists available for commission',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_artists.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'No commission artists available right now.',
              style: GoogleFonts.spaceGrotesk(
                color: ArtbeatColors.textSecondary,
              ),
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) =>
                  _buildArtistCard(context, _artists[index]),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: _artists.length,
            ),
          ),
      ],
    );
  }

  Widget _buildArtistCard(
    BuildContext context,
    CommissionArtistPreviewModel artist,
  ) {
    final imageUrl = artist.portfolioImages.isNotEmpty
        ? artist.portfolioImages.first
        : null;
    final artistName =
        _artistNames[artist.artistId] ?? _fallbackName(artist.artistId);

    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.commissionRequest,
          arguments: {'artistId': artist.artistId, 'artistName': artistName},
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildImageFallback(),
                      )
                    : _buildImageFallback(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    artist.availableTypes.isEmpty
                        ? 'Open for commissions'
                        : artist.availableTypes.join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    artist.basePrice > 0
                        ? 'From \$${artist.basePrice.toStringAsFixed(0)}'
                        : 'Custom pricing',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFBBF24),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: Colors.white.withValues(alpha: 0.05),
      child: const Center(
        child: Icon(Icons.palette_outlined, color: Colors.white54, size: 32),
      ),
    );
  }

  String _fallbackName(String artistId) {
    final length = math.min(artistId.length, 8);
    if (length == 0) return 'Artist';
    return 'Artist ${artistId.substring(0, length)}';
  }
}
