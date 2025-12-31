import 'package:flutter/material.dart';

import '../widgets/hud_top_bar.dart';
import '../widgets/sponsorship_cta_tile.dart';
import '../widgets/sponsorship_section.dart';
import '../widgets/world_background.dart';

class LocalBusinessScreen extends StatelessWidget {
  const LocalBusinessScreen({super.key});

  @override
  Widget build(BuildContext context) => WorldBackground(
      child: Column(
        children: [
          const HudTopBar(
            title: 'Your Business',
          ),
          Expanded(
            child: ListView(
              children: [
                SponsorshipSection(
                  title: 'Promote Your Business',
                  child: Column(
                    children: [
                      SponsorshipCtaTile(
                        icon: Icons.campaign,
                        title: 'View Sponsorships',
                        subtitle:
                            'Manage and create sponsorships',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/sponsorship-dashboard',
                          );
                        },
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
}
