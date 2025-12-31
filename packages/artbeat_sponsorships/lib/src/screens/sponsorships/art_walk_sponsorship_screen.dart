import 'package:flutter/material.dart';

import '../../widgets/glass_input_field.dart';
import '../../widgets/gradient_cta_button.dart';
import '../../widgets/hud_top_bar.dart';
import '../../widgets/sponsorship_form_section.dart';
import '../../widgets/sponsorship_price_summary.dart';
import '../../widgets/sponsorship_section.dart';
import '../../widgets/world_background.dart';

class ArtWalkSponsorshipScreen extends StatelessWidget {
  const ArtWalkSponsorshipScreen({super.key});

  @override
  Widget build(BuildContext context) => WorldBackground(
      child: Column(
        children: [
          HudTopBar(
            title: 'Art Walk Sponsorship',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: const [
                SponsorshipSection(
                  title: 'What You Get',
                  child: Text(
                    'Create a walk featuring local art and your business. '
                    'Users earn XP for stopping at your location.',
                  ),
                ),
                SponsorshipSection(
                  title: 'Pricing',
                  child: SponsorshipPriceSummary(
                    price: r'$250',
                    duration: '30 days',
                  ),
                ),
                SponsorshipSection(
                  title: 'Art Walk Details',
                  child: Column(
                    children: [
                      SponsorshipFormSection(
                        label: 'Walk Title',
                        child: GlassInputField(
                          label: 'Downtown Art + Coffee',
                        ),
                      ),
                      SizedBox(height: 12),
                      SponsorshipFormSection(
                        label: 'Description',
                        child: GlassInputField(
                          label: 'Short description',
                        ),
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
              label: 'Continue',
              onPressed: () {
                Navigator.pushNamed(context, '/sponsorship-review');
              },
            ),
          ),
        ],
      ),
    );
}
