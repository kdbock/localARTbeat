import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show ArtistProfileModel, ArtbeatColors;
import 'package:artbeat_community/widgets/glass_card.dart';
import '../models/artwork_model.dart';
import 'avatar_widget.dart';

class CanvasFeed extends StatelessWidget {
  final List<ArtworkModel> artworks;
  final void Function(ArtistProfileModel)
  onArtistTap; // Updated to accept ArtistProfileModel

  const CanvasFeed({
    super.key,
    required this.artworks,
    required this.onArtistTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: artworks.length,
      itemBuilder: (context, index) {
        final artwork = artworks[index];
        return GlassCard(
          margin: const EdgeInsets.all(8.0),
          borderRadius: 24,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                AvatarWidget(
                  avatarUrl: artwork.artist?.profileImageUrl ?? '',
                  onTap: () {
                    if (artwork.artist != null) {
                      onArtistTap(artwork.artist!);
                    }
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artwork.title,
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Medium: ${artwork.medium}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Location: ${artwork.location}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Posted: ${artwork.createdAt}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
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
