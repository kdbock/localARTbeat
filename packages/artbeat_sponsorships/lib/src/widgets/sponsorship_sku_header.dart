import 'package:flutter/material.dart';

import '../models/sponsorship_tier.dart';
import 'glass_card.dart';
import 'sponsorship_tier_badge.dart';

class SponsorshipSkuHeader extends StatelessWidget {
  const SponsorshipSkuHeader({
    super.key,
    required this.tier,
    required this.title,
    required this.description,
  });

  final SponsorshipTier tier;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SponsorshipTierBadge(tier: tier),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(description),
          ],
        ),
      );
}
