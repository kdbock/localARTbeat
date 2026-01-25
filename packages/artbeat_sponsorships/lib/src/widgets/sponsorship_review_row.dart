import 'package:flutter/material.dart';

class SponsorshipReviewRow extends StatelessWidget {
  const SponsorshipReviewRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}
