import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_profile/widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementInfoScreen extends StatelessWidget {
  const AchievementInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final levelSystem = [
      {'level': 1, 'title': 'Sketcher (Frida Kahlo)', 'xpRange': '0-199 XP'},
      {
        'level': 2,
        'title': 'Color Blender (Jacob Lawrence)',
        'xpRange': '200-499 XP',
      },
      {
        'level': 3,
        'title': 'Brush Trailblazer (Yayoi Kusama)',
        'xpRange': '500-999 XP',
      },
      {
        'level': 4,
        'title': 'Street Master (Jean-Michel Basquiat)',
        'xpRange': '1000-1499 XP',
      },
      {
        'level': 5,
        'title': 'Mural Maven (Faith Ringgold)',
        'xpRange': '1500-2499 XP',
      },
      {
        'level': 6,
        'title': 'Avant-Garde Explorer (Zarina Hashmi)',
        'xpRange': '2500-3999 XP',
      },
      {
        'level': 7,
        'title': 'Visionary Creator (El Anatsui)',
        'xpRange': '4000-5999 XP',
      },
      {
        'level': 8,
        'title': 'Art Legend (Leonardo da Vinci)',
        'xpRange': '6000-7999 XP',
      },
      {
        'level': 9,
        'title': 'Cultural Curator (Shirin Neshat)',
        'xpRange': '8000-9999 XP',
      },
      {'level': 10, 'title': 'Art Walk Influencer', 'xpRange': '10000+ XP'},
    ];

    final achievementCategories = [
      'First Achievements',
      'Milestone Achievements',
      'Creator Achievements',
      'Explorer Achievements',
      'Quest Achievements',
      'Streak Achievements',
    ];

    final levelPerks = [
      'Level 3: Suggest edits to any public artwork',
      'Level 5: Moderate reviews (report abuse, vote quality)',
      'Level 7: Early access to beta features',
      'Level 10: Become an Art Walk Influencer, post updates, featured profile, community spotlight',
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
                          'Earn XP through art walks, captures, reviews, and community contributions. Level up to unlock exclusive perks and become an Art Walk Influencer!',
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
                  ...levelSystem.map(
                    (level) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: LevelBadge(
                        level: level['level'] as int,
                        title: level['title'] as String,
                        xpRange: level['xpRange'] as String,
                      ),
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
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/art-walk/dashboard',
                          ),
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
      ['Art Capture Created', '25 XP'],
      ['Art Capture Approved', '50 XP'],
      ['Visit Individual Artwork', '10 XP'],
      ['Submit a Review (50+ words)', '30 XP'],
      ['Receive Helpful Vote', '10 XP'],
      ['Walk Used by 5+ Users', '75 XP'],
      ['Edit/Update Walk', '20 XP'],
      ['Complete Daily Challenge', 'Varies'],
      ['Complete Weekly Goal', 'Varies'],
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
}
