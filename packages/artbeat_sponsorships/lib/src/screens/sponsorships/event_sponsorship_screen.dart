import 'package:flutter/material.dart';

import '../../widgets/glass_input_field.dart';
import '../../widgets/gradient_cta_button.dart';
import '../../widgets/hud_top_bar.dart';
import '../../widgets/sponsorship_form_section.dart';
import '../../widgets/sponsorship_price_summary.dart';
import '../../widgets/sponsorship_section.dart';
import '../../widgets/world_background.dart';

class EventSponsorshipScreen extends StatelessWidget {
  const EventSponsorshipScreen({super.key});

  @override
  Widget build(BuildContext context) => WorldBackground(
    child: Column(
      children: [
        HudTopBar(
          title: 'Event Sponsorship',
          onBack: () => Navigator.pop(context),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: const [
              SponsorshipSection(
                title: 'What You Get',
                child: Text(
                  'Sponsor a Local ARTbeat tour or event with equal branding, '
                  'signage, and callouts in promotional videos.',
                ),
              ),
              SponsorshipSection(
                title: 'Pricing',
                child: SponsorshipPriceSummary(
                  price: r'$750',
                  duration: 'Per Event',
                ),
              ),
              SponsorshipSection(
                title: 'Event Details',
                child: Column(
                  children: [
                    SponsorshipFormSection(
                      label: 'Event Name',
                      child: GlassInputField(label: 'e.g. Downtown Art Tour'),
                    ),
                    SizedBox(height: 12),
                    SponsorshipFormSection(
                      label: 'Notes (optional)',
                      child: GlassInputField(label: 'Any special requests'),
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
