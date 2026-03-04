import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../widgets/glass_input_field.dart';
import '../../widgets/gradient_cta_button.dart';
import '../../widgets/sponsor_art_selection_widget.dart';
import '../../widgets/sponsorship_form_section.dart';
import '../../widgets/sponsorship_price_summary.dart';
import '../../widgets/sponsorship_section.dart';
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
  List<String> selectedArtIds = [];

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
          title: 'sponsorship_art_walk_title'.tr(),
          onBackPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              SponsorshipSection(
                title: 'sponsorship_common_what_you_get_title'.tr(),
                child: Text(
                  'sponsorship_art_walk_what_you_get_body'.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ),
              SponsorshipSection(
                title: 'sponsorship_common_pricing_title'.tr(),
                child: SponsorshipPriceSummary(
                  price: 'sponsorship_common_price_art_walk'.tr(),
                  duration: 'sponsorship_common_duration_monthly'.tr(),
                ),
              ),
              SponsorshipSection(
                title: 'sponsorship_art_walk_details_title'.tr(),
                child: Column(
                  children: [
                    SponsorshipFormSection(
                      label: 'sponsorship_art_walk_title_label'.tr(),
                      child: GlassInputField(
                        controller: titleController,
                        label: 'sponsorship_art_walk_title_hint'.tr(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SponsorshipFormSection(
                      label: 'sponsorship_art_walk_description_label'.tr(),
                      child: GlassInputField(
                        controller: descriptionController,
                        label: 'sponsorship_art_walk_description_hint'.tr(),
                      ),
                    ),
                  ],
                ),
              ),
              SponsorshipSection(
                title: 'sponsorship_art_walk_select_art_title'.tr(),
                subtitle: 'sponsorship_art_walk_select_art_subtitle'.tr(),
                child: SponsorArtSelectionWidget(
                  selectedArtIds: selectedArtIds,
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      selectedArtIds = newSelection;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: GradientCtaButton(
            label: 'sponsorship_common_continue_button'.tr(),
            onPressed: () {
              if (titleController.text.isEmpty ||
                  descriptionController.text.isEmpty ||
                  selectedArtIds.length < 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      selectedArtIds.length < 3
                          ? 'sponsorship_art_walk_min_art_error'.tr()
                          : 'sponsorship_art_walk_fields_required_error'.tr(),
                    ),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => SponsorshipReviewScreen(
                    type: 'art_walk',
                    duration: 'sponsorship_common_duration_monthly'.tr(),
                    price: 'sponsorship_common_price_art_walk'.tr(),
                    notes: 'sponsorship_art_walk_notes_summary'.tr(
                      namedArgs: {
                        'title': titleController.text,
                        'description': descriptionController.text,
                        'count': selectedArtIds.length.toString(),
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
