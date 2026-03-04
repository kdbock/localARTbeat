import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../widgets/glass_input_field.dart';
import '../../widgets/gradient_cta_button.dart';
import '../../widgets/sponsorship_form_section.dart';
import '../../widgets/sponsorship_price_summary.dart';
import '../../widgets/sponsorship_section.dart';
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
          title: 'sponsorship_capture_title'.tr(),
          onBackPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              SponsorshipSection(
                title: 'sponsorship_common_what_you_get_title'.tr(),
                child: Text(
                  'sponsorship_capture_what_you_get_body'.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ),
              SponsorshipSection(
                title: 'sponsorship_common_pricing_title'.tr(),
                child: SponsorshipPriceSummary(
                  price: 'sponsorship_common_price_capture'.tr(),
                  duration: 'sponsorship_common_duration_monthly'.tr(),
                ),
              ),
              SponsorshipSection(
                title: 'sponsorship_common_target_area_title'.tr(),
                child: SponsorshipFormSection(
                  label: 'sponsorship_common_radius_label'.tr(),
                  child: GlassInputField(
                    controller: radiusController,
                    label: 'sponsorship_capture_radius_hint'.tr(),
                  ),
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
              if (radiusController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('sponsorship_common_enter_radius_error'.tr()),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => SponsorshipReviewScreen(
                    type: 'capture',
                    duration: 'sponsorship_common_duration_monthly'.tr(),
                    price: 'sponsorship_common_price_capture'.tr(),
                    notes: 'sponsorship_common_radius_notes'.tr(
                      namedArgs: {'radius': radiusController.text},
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
