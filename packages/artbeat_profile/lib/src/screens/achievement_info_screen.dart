import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_profile/widgets/widgets.dart';
import 'package:artbeat_profile/src/models/badge_tier.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementInfoScreen extends StatelessWidget {
  const AchievementInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final levelBadges = List.generate(10, (index) => index + 1);
    final achievementCategories = [
      'Explorer Quests',
      'Creative Milestones',
      'Community Highlights',
      'Art Walk Journeys',
    ];
    final badgeTiers = [
      BadgeTier('Bronze', color: const Color(0xFFB76935)),
      BadgeTier('Silver', color: const Color(0xFF9CA3AF)),
      BadgeTier('Gold', color: const Color(0xFFFBBF24)),
      BadgeTier('Platinum', color: const Color(0xFF9C27B0)),
      BadgeTier('Mythic', color: const Color(0xFF2563EB)),
    ];
    final levelPerks = [
      'Unlock exclusive profile themes',
      'Feature your best captures on profile',
      'Access advanced engagement analytics',
      'Receive invite-only art walk drops',
    ];

    return WorldBackground(
      child: SafeArea(
        child: Column(
          children: [
            HudTopBar(
              title: 'profile_achievement_title'.tr(),
              showBackButton: true,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          size: 48,
                          color: Color(0xFF7C4DFF),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'profile_achievement_intro_title'.tr(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'profile_achievement_intro_subtitle'.tr(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  const SectionHeader(title: 'XP System'),
                  const SizedBox(height: 8),
                  _buildXPList(),

                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Level System'),
                  const SizedBox(height: 8),
                  ...levelBadges.map(
                    (level) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: LevelBadge(level: level),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Achievement Categories'),
                  const SizedBox(height: 8),
                  ...achievementCategories.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AchievementCategoryTile(category: cat),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Badge Tiers'),
                  const SizedBox(height: 8),
                  ...badgeTiers.map(_buildTierRow),

                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Level Perks'),
                  const SizedBox(height: 8),
                  ...levelPerks.map(
                    (perk) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PerkItem(perk: perk),
                    ),
                  ),

                  const SizedBox(height: 32),
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Ready to Start Your Journey?',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Begin exploring art walks to earn your first achievements!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        HudButton(
                          text: 'profile_achievement_explore'.tr(),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/art-walks'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXPList() {
    final entries = [
      ['Complete an Art Walk', '100 XP'],
      ['Create a New Art Walk', '75 XP'],
      ['Art Capture Approved', '50 XP'],
      ['Submit a Review (50+ words)', '30 XP'],
      ['Walk Used by 5+ Users', '75 XP'],
      ['Visit Individual Artwork', '10 XP'],
      ['Receive Helpful Vote', '10 XP'],
      ['Edit/Update Walk', '20 XP'],
    ];

    return Column(
      children: entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: 16,
                color: Color(0xFF7C4DFF),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  e[0],
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
              Text(
                e[1],
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF7C4DFF),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTierRow(BadgeTier tier) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: tier.color,
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tier.label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              Text(
                tier.description,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
