import 'package:flutter/material.dart';

import '../../widgets/glass_input_field.dart';
import '../../widgets/gradient_cta_button.dart';
import '../../widgets/hud_top_bar.dart';
import '../../widgets/sponsorship_form_section.dart';
import '../../widgets/sponsorship_price_summary.dart';
import '../../widgets/sponsorship_section.dart';
import '../../widgets/world_background.dart';

class CaptureSponsorshipScreen extends StatelessWidget {
  const CaptureSponsorshipScreen({super.key});

  @override
  Widget build(BuildContext context) => WorldBackground(
    child: Column(
      children: [
        HudTopBar(
          title: 'Capture Sponsorship',
          onBack: () => Navigator.pop(context),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: const [
              SponsorshipSection(
                title: 'What You Get',
                child: Text(
                  'Your business will appear when users capture nearby art.',
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
                title: 'Target Area',
                child: SponsorshipFormSection(
                  label: 'Radius (miles)',
                  child: GlassInputField(label: 'e.g. 3'),
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
