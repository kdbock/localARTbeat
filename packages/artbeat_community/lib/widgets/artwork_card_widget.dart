import 'package:artbeat_core/artbeat_core.dart' hide ArtworkModel, UserModel;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/artwork_model.dart';
import '../models/user_model.dart';

class ArtworkCardWidget extends StatelessWidget {
  final ArtworkModel artwork;
  final UserModel artist;

  const ArtworkCardWidget({
    super.key,
    required this.artwork,
    required this.artist,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the avatar URL is valid for NetworkImage

    return GlassCard(
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/artist/public-profile',
                      arguments: {'artistId': artist.id},
                    );
                  },
                  child: CircleAvatar(
                    backgroundImage: ImageUrlValidator.safeNetworkImage(
                      artist.avatarUrl,
                    ),
                    radius: 24,
                    child: !ImageUrlValidator.isValidImageUrl(artist.avatarUrl)
                        ? const Icon(Icons.person, size: 24)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.username,
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: ArtbeatColors.textPrimary,
                      ),
                    ),
                    Text(
                      artwork.location,
                      style: GoogleFonts.spaceGrotesk(
                        color: ArtbeatColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              artwork.title,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              artwork.medium,
              style: GoogleFonts.spaceGrotesk(
                color: ArtbeatColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
