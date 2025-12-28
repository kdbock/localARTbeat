// Refactored to match Local ARTbeat design_guide.md
// Applied: WorldBackground, GlassCard, GradientCTAButton, tr() localization, SpaceGrotesk, spacing & touch targets

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_art_walk/src/widgets/world_background.dart';
import 'package:artbeat_art_walk/src/widgets/glass_card.dart';
import 'package:artbeat_art_walk/src/widgets/gradient_cta_button.dart';
import 'package:artbeat_art_walk/src/widgets/text_styles.dart';

class EnhancedMyArtWalksScreen extends StatelessWidget {
  const EnhancedMyArtWalksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              automaticallyImplyLeading: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'art_walk_enhanced_my_art_walks_text_my_art_walks'.tr(),
                style: AppTextStyles.whiteHeading,
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              centerTitle: true,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  children: [
                    _buildSectionHeader(
                      icon: Icons.play_circle_fill,
                      title:
                          'art_walk_enhanced_my_art_walks_text_section_in_progress'
                              .tr(),
                      count: 2,
                    ),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Art Walk to Riverfront',
                              style: AppTextStyles.whiteHeading,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '3/8 art pieces visited',
                              style: AppTextStyles.whiteSmall,
                            ),
                            const SizedBox(height: 12),
                            GradientCTAButton(
                              label:
                                  'art_walk_enhanced_my_art_walks_text_resume_walk'
                                      .tr(),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      icon: Icons.check_circle_outline,
                      title:
                          'art_walk_enhanced_my_art_walks_text_section_completed'
                              .tr(),
                      count: 1,
                    ),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Downtown Public Art Tour',
                              style: AppTextStyles.whiteHeading,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Completed! 🎉',
                              style: AppTextStyles.whiteSmall,
                            ),
                            const SizedBox(height: 12),
                            GradientCTAButton(
                              label:
                                  'art_walk_enhanced_my_art_walks_text_review_walk'
                                      .tr(),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.whiteHeading,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('$count', style: AppTextStyles.whiteSmall),
        ),
      ],
    );
  }
}
