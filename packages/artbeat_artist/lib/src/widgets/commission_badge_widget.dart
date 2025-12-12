import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Widget that displays commission status on artist profiles
class CommissionBadge extends StatelessWidget {
  final bool acceptingCommissions;
  final double? basePrice;
  final int? turnaroundDays;

  const CommissionBadge({
    super.key,
    required this.acceptingCommissions,
    this.basePrice,
    this.turnaroundDays,
  });

  @override
  Widget build(BuildContext context) {
    if (!acceptingCommissions) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green.shade700,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            tr('art_walk_accepting_commissions'),
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Detailed commission info card for profile
class CommissionInfoCard extends StatelessWidget {
  final double? basePrice;
  final int? turnaroundDays;
  final List<String>? availableTypes;

  const CommissionInfoCard({
    super.key,
    this.basePrice,
    this.turnaroundDays,
    this.availableTypes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.art_track, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                tr('art_walk_commission_details'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (basePrice != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('art_walk_base_price'),
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                  Text(
                    '\$${basePrice?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          if (turnaroundDays != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('art_walk_turnaround'),
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                  Text(
                    '$turnaroundDays days',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          if (availableTypes != null && availableTypes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 4,
                children: availableTypes!
                    .map(
                      (type) => Chip(
                        label: Text(
                          type,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        backgroundColor: Colors.blue.shade100,
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
