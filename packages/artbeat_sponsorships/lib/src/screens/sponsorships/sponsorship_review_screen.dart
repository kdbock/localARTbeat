import 'package:flutter/material.dart';

import '../../widgets/gradient_cta_button.dart';
import '../../widgets/hud_top_bar.dart';
import '../../widgets/sponsorship_review_row.dart';
import '../../widgets/sponsorship_section.dart';
import '../../widgets/world_background.dart';

class SponsorshipReviewScreen extends StatelessWidget {
  const SponsorshipReviewScreen({super.key});

  @override
  Widget build(BuildContext context) => WorldBackground(
      child: Column(
        children: [
          HudTopBar(
            title: 'Review Sponsorship',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: const [
                SponsorshipSection(
                  title: 'Summary',
                  child: Column(
                    children: [
                      SponsorshipReviewRow(
                        label: 'Type',
                        value: 'Capture Sponsorship',
                      ),
                      SponsorshipReviewRow(
                        label: 'Duration',
                        value: '30 days',
                      ),
                      SponsorshipReviewRow(
                        label: 'Price',
                        value: r'$250',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GradientCtaButton(
              label: 'Submit for Approval',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
}
