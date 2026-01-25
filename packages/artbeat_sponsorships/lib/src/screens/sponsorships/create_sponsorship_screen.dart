import 'package:flutter/material.dart';
import '../../widgets/hud_top_bar.dart';
import '../../widgets/sponsorship_cta_tile.dart';
import '../../widgets/sponsorship_section.dart';
import '../../widgets/world_background.dart';

class CreateSponsorshipScreen extends StatelessWidget {
  const CreateSponsorshipScreen({super.key});

  @override
  Widget build(BuildContext context) => WorldBackground(
    child: Column(
      children: [
        HudTopBar(
          title: 'Choose Sponsorship',
          onBack: () => Navigator.pop(context),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              SponsorshipSection(
                title: 'Featured',
                subtitle: 'High-visibility opportunities',
                child: Column(
                  children: [
                    SponsorshipCtaTile(
                      icon: Icons.star,
                      title: 'Title Sponsor',
                      subtitle: 'Be the face of Local ARTbeat',
                      onTap: () => _go(context, '/title-sponsorship'),
                    ),
                  ],
                ),
              ),
              SponsorshipSection(
                title: 'Experiences',
                subtitle: 'Engage users through art and exploration',
                child: Column(
                  children: [
                    SponsorshipCtaTile(
                      icon: Icons.map,
                      title: 'Art Walk Sponsorship',
                      subtitle: 'Create a walk featuring your business',
                      onTap: () => _go(context, '/art-walk-sponsorship'),
                    ),
                    const SizedBox(height: 12),
                    SponsorshipCtaTile(
                      icon: Icons.event,
                      title: 'Event Sponsorship',
                      subtitle: 'Sponsor a Local ARTbeat tour',
                      onTap: () => _go(context, '/event-sponsorship'),
                    ),
                  ],
                ),
              ),
              SponsorshipSection(
                title: 'Discovery',
                subtitle: 'Appear when users explore nearby art',
                child: Column(
                  children: [
                    SponsorshipCtaTile(
                      icon: Icons.camera_alt,
                      title: 'Capture Sponsorship',
                      subtitle: 'Sponsor nearby art captures',
                      onTap: () => _go(context, '/capture-sponsorship'),
                    ),
                    const SizedBox(height: 12),
                    SponsorshipCtaTile(
                      icon: Icons.radar,
                      title: 'Discover Sponsorship',
                      subtitle: 'Sponsor instant discoveries',
                      onTap: () => _go(context, '/discover-sponsorship'),
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
