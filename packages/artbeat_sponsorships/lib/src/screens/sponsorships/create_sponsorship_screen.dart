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
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              SponsorshipSection(
                title: 'sponsorship_create_experiences_title'.tr(),
                subtitle:
                    'Art Walk is the premium curated sponsorship experience. Capture and discovery placements are now handled through Local Ads.'
                        ,
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
                title: 'Local Ads',
                subtitle:
                    'Use Local Ads for capture and discovery visibility inside the app.',
                child: Column(
                  children: [
                    SponsorshipCtaTile(
                      icon: Icons.campaign_outlined,
                      title: 'Open Local Ads',
                      subtitle:
                          'Choose Banner or Inline and submit for review through the ad flow.',
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
