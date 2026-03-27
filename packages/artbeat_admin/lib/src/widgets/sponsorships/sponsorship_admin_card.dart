import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/admin_sponsorship.dart';

class SponsorshipAdminCard extends StatelessWidget {
  const SponsorshipAdminCard({
    super.key,
    required this.sponsorship,
    required this.onApprove,
    required this.onNeedsCreative,
    required this.onReject,
    required this.onViewDetails,
  });

  final AdminSponsorship sponsorship;
  final VoidCallback onApprove;
  final VoidCallback onNeedsCreative;
  final VoidCallback onReject;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sponsorship.businessName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              _StatusPill(status: sponsorship.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_titleCase(sponsorship.tier)} sponsor',
            style: TextStyle(color: Colors.grey[300], fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            sponsorship.businessAddress ??
                sponsorship.relatedEntityName ??
                'No location or related entity set',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: sponsorship.paymentStatus ?? 'payment unknown'),
              if (sponsorship.paymentFollowUpStatus?.trim().isNotEmpty ?? false)
                _MetaChip(label: sponsorship.paymentFollowUpStatus!),
              _MetaChip(label: sponsorship.placementKeys.join(', ')),
            ],
          ),
          if (sponsorship.paymentFollowUpNotes?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            Text(
              sponsorship.paymentFollowUpNotes!,
              style: TextStyle(color: Colors.lightBlue[100], fontSize: 12),
            ),
          ],
          if (sponsorship.moderationNotes?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            Text(
              sponsorship.moderationNotes!,
              style: TextStyle(color: Colors.amber[200], fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check, size: 16, color: Colors.green),
                label: Text(
                  'common_approve'.tr(),
                  style: const TextStyle(color: Colors.green),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onNeedsCreative,
                icon: const Icon(Icons.brush, size: 16, color: Colors.amber),
                label: const Text(
                  'Needs creative',
                  style: TextStyle(color: Colors.amber),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                label: Text(
                  'common_reject'.tr(),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              TextButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.visibility, size: 16),
                label: Text('common_details'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.grey[300], fontSize: 12),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' => Colors.lightGreenAccent,
      'active' => Colors.greenAccent,
      'needsCreative' => Colors.amberAccent,
      'rejected' => Colors.redAccent,
      'expired' => Colors.grey,
      _ => Colors.orangeAccent,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _titleCase(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

String _titleCase(String raw) {
  if (raw.isEmpty) return raw;
  final withSpaces = raw.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  return withSpaces
      .split('_')
      .join(' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
