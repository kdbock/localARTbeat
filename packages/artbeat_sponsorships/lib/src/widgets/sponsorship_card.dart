import 'package:flutter/material.dart';
import '../models/sponsorship.dart';
import 'sponsorship_status_chip.dart';
import 'sponsorship_tier_badge.dart';

class SponsorshipCard extends StatelessWidget {
  const SponsorshipCard({
    super.key,
    required this.sponsorship,
    required this.onTap,
  });

  final Sponsorship sponsorship;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(24),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          SponsorshipTierBadge(tier: sponsorship.tier),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sponsorship.businessName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  sponsorship.businessAddress ??
                      sponsorship.relatedEntityName ??
                      sponsorship.tier.name.toUpperCase(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                SponsorshipStatusChip(status: sponsorship.status),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}
