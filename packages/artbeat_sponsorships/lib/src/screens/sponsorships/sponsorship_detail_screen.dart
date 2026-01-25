import 'package:flutter/material.dart';
import '../../widgets/hud_top_bar.dart';
import '../../widgets/sponsorship_review_row.dart';
import '../../widgets/sponsorship_section.dart';
import '../../widgets/world_background.dart';

class SponsorshipDetailScreen extends StatelessWidget {
  const SponsorshipDetailScreen({super.key});

  @override
  Widget build(BuildContext context) => WorldBackground(
    child: Column(
      children: [
        HudTopBar(
          title: 'Sponsorship Details',
          onBack: () => Navigator.pop(context),
        ),
        Expanded(
          child: ListView(
            children: const [
              SponsorshipSection(
                title: 'Details',
                child: Column(
                  children: [
                    SponsorshipReviewRow(label: 'Status', value: 'Active'),
                    SponsorshipReviewRow(
                      label: 'Type',
                      value: 'Capture Sponsorship',
                    ),
                    SponsorshipReviewRow(label: 'Ends', value: 'Aug 31, 2026'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
