import 'package:flutter/material.dart';
import '../models/sponsorship_status.dart';

class SponsorshipStatusChip extends StatelessWidget {
  const SponsorshipStatusChip({super.key, required this.status});

  final SponsorshipStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      SponsorshipStatus.active => Colors.greenAccent,
      SponsorshipStatus.pending => Colors.orangeAccent,
      SponsorshipStatus.expired => Colors.grey,
      SponsorshipStatus.rejected => Colors.redAccent,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.15),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
