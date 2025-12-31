import 'package:flutter/material.dart';

import '../../widgets/glass_input_field.dart';
import '../../widgets/gradient_cta_button.dart';
import '../../widgets/hud_top_bar.dart';
import '../../widgets/sponsorship_form_section.dart';
import '../../widgets/sponsorship_price_summary.dart';
import '../../widgets/sponsorship_section.dart';
import '../../widgets/world_background.dart';
import 'sponsorship_review_screen.dart';

class DiscoverSponsorshipScreen extends StatefulWidget {
  const DiscoverSponsorshipScreen({super.key});

  @override
  State<DiscoverSponsorshipScreen> createState() =>
      _DiscoverSponsorshipScreenState();
}

class _DiscoverSponsorshipScreenState extends State<DiscoverSponsorshipScreen> {
  final TextEditingController radiusController = TextEditingController();

  @override
  void dispose() {
    radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WorldBackground(
    child: Column(
      children: [
        HudTopBar(
          title: 'Discover Sponsorship',
          onBack: () => Navigator.pop(context),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              const SponsorshipSection(
                title: 'What You Get',
                child: Text(
                  'Your business appears on the discovery radar when users '
                  'are actively searching for nearby art.',
                ),
              ),
              const SponsorshipSection(
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
                  child: GlassInputField(
                    controller: radiusController,
                    label: 'e.g. 5',
                  ),
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
              if (radiusController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a radius to continue'),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SponsorshipReviewScreen(
                    type: 'discover',
                    duration: '30 days',
                    price: r'$250',
                    notes: 'Radius: ${radiusController.text} miles',
                  ),
                ),
              );
            },
            onTap: () {},
          ),
        ),
      ],
    ),
  );
}
