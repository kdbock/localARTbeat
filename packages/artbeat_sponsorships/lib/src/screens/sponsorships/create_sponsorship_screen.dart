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
                title: 'sponsorship_create_discovery_title'.tr(),
                subtitle: 'sponsorship_create_discovery_subtitle'.tr(),
                child: Column(
                  children: [
                    SponsorshipCtaTile(
                      icon: Icons.camera_alt,
                      title: 'sponsorship_create_capture_title'.tr(),
                      subtitle: 'sponsorship_create_capture_subtitle'.tr(),
                      onTap: () => _go(context, AppRoutes.sponsorshipCapture),
                    ),
                    const SizedBox(height: 12),
                    SponsorshipCtaTile(
                      icon: Icons.radar,
                      title: 'sponsorship_create_discover_title'.tr(),
                      subtitle: 'sponsorship_create_discover_subtitle'.tr(),
                      onTap: () => _go(context, AppRoutes.sponsorshipDiscover),
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
