import 'package:flutter/material.dart';
import '../../widgets/glass_input_field.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_cta_button.dart';
import '../../widgets/hud_top_bar.dart';
import '../../widgets/sponsorship_form_section.dart';
import '../../widgets/sponsorship_price_summary.dart';
import '../../widgets/sponsorship_section.dart';
import '../../widgets/world_background.dart';
import 'sponsorship_review_screen.dart';

class CaptureSponsorshipScreen extends StatefulWidget {
  const CaptureSponsorshipScreen({super.key});

  @override
  State<CaptureSponsorshipScreen> createState() =>
      _CaptureSponsorshipScreenState();
}

class _CaptureSponsorshipScreenState extends State<CaptureSponsorshipScreen> {
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
          title: 'Capture Sponsorship',
          onBack: () => Navigator.pop(context),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              const SponsorshipSection(
                title: 'What You Get',
                child: Text(
                  'Your business will appear when users capture nearby art.',
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
                    label: 'e.g. 3',
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
                    type: 'capture',
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
