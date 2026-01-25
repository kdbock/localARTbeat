import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class ArtistBoostCardWidget extends StatelessWidget {
  final ArtistBoostModel boost;
  final VoidCallback? onSendBoost;

  const ArtistBoostCardWidget({
    super.key,
    required this.boost,
    this.onSendBoost,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              boost.boostType,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: const Color(0xFF92FFFFFF),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Momentum +${boost.momentumAmount}',
              style: GoogleFonts.spaceGrotesk(
                color: const Color(0xFF70FFFFFF),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (onSendBoost != null)
              HudButton(
                onPressed: onSendBoost,
                text: 'community_boosts.deploy_boost'.tr(),
              ),
          ],
        ),
      ),
    );
  }
}
