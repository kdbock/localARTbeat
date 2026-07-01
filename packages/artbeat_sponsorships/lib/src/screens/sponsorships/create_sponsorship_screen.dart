import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../widgets/sponsorship_cta_tile.dart';
import '../../widgets/sponsorship_section.dart';

class CreateSponsorshipScreen extends StatelessWidget {
  const CreateSponsorshipScreen({super.key});

  @override
  Widget build(BuildContext context) => WorldBackground(
    child: Column(
      children: [
        HudTopBar(
          title: 'sponsorship_create_title'.tr(),
          onBackPressed: () => Navigator.pop(context),
          actions: [
            AppHelpButton(
              title: 'sponsorship_hub_help_title'.tr(),
              body: 'sponsorship_hub_help_body'.tr(),
              steps: [
                'sponsorship_hub_help_step_choose'.tr(),
                'sponsorship_hub_help_step_creative'.tr(),
                'sponsorship_hub_help_step_review'.tr(),
              ],
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              SponsorshipSection(
                title: 'sponsorship_create_experiences_title'.tr(),
                subtitle: 'sponsorship_create_experiences_subtitle'.tr(),
                child: Column(
                  children: [
                    SponsorshipCtaTile(
                      icon: Icons.map,
                      title: 'sponsorship_create_art_walk_title'.tr(),
                      subtitle: 'sponsorship_create_art_walk_subtitle'.tr(),
                      onTap: () => _go(context, AppRoutes.sponsorshipArtWalk),
                    ),
                  ],
                ),
              ),
              SponsorshipSection(
                title: 'sponsorship_create_placements_title'.tr(),
                subtitle: 'sponsorship_create_placements_subtitle'.tr(),
                child: Column(
                  children: [
                    SponsorshipCtaTile(
                      icon: Icons.campaign_outlined,
                      title: 'sponsorship_create_placements_cta_title'.tr(),
                      subtitle: 'sponsorship_create_placements_cta_subtitle'
                          .tr(),
                      onTap: () => _go(context, AppRoutes.ads),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  void _go(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }
}
