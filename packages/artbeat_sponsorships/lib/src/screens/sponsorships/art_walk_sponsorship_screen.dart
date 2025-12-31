import 'package:flutter/material.dart';

import '../../widgets/glass_input_field.dart';
import '../../widgets/gradient_cta_button.dart';
import '../../widgets/hud_top_bar.dart';
import '../../widgets/sponsorship_form_section.dart';
import '../../widgets/sponsorship_price_summary.dart';
import '../../widgets/sponsorship_section.dart';
import '../../widgets/world_background.dart';
import 'sponsorship_review_screen.dart';

class ArtWalkSponsorshipScreen extends StatefulWidget {
  const ArtWalkSponsorshipScreen({super.key});

  @override
  State<ArtWalkSponsorshipScreen> createState() =>
      _ArtWalkSponsorshipScreenState();
}

class _ArtWalkSponsorshipScreenState extends State<ArtWalkSponsorshipScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

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
            children: [
              const SponsorshipSection(
                title: 'What You Get',
                child: Text(
                  'Create a walk featuring local art and your business. '
                  'Users earn XP for stopping at your location.',
                ),
              ),
              const SponsorshipSection(
                title: 'Pricing',
                child: SponsorshipPriceSummary(
                  price: r'$500',
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
                        controller: titleController,
                        label: 'Downtown Art + Coffee',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SponsorshipFormSection(
                      label: 'Description',
                      child: GlassInputField(
                        controller: descriptionController,
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
              if (titleController.text.isEmpty ||
                  descriptionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields to continue'),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SponsorshipReviewScreen(
                    type: 'art_walk',
                    duration: '30 days',
                    price: r'$500',
                    notes:
                        'Title: ${titleController.text}\nDescription: ${descriptionController.text}',
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
