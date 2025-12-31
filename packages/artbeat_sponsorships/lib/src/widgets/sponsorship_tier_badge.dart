import 'package:flutter/material.dart';
import '../models/sponsorship_tier.dart';

class SponsorshipTierBadge extends StatelessWidget {
  const SponsorshipTierBadge({super.key, required this.tier});

  final SponsorshipTier tier;

  @override
  Widget build(BuildContext context) {
    final icon = switch (tier) {
      SponsorshipTier.title => Icons.star,
      SponsorshipTier.event => Icons.event,
      SponsorshipTier.artWalk => Icons.map,
      SponsorshipTier.capture => Icons.camera_alt,
      SponsorshipTier.discover => Icons.radar,
    };

    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
        ),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}
