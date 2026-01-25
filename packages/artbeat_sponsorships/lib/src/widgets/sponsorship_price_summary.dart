import 'package:artbeat_core/shared_widgets.dart';
import 'package:flutter/material.dart';

class SponsorshipPriceSummary extends StatelessWidget {
  const SponsorshipPriceSummary({
    super.key,
    required this.price,
    required this.duration,
  });

  final String price;
  final String duration;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          price,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          duration,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
      ],
    ),
  );
}
