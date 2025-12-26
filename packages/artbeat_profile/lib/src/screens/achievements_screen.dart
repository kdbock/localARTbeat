import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_profile/widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = UserModel(
      id: '',
      email: '',
      username: '',
      fullName: '',
      createdAt: DateTime.now(),
    ); // TODO: Replace with real user
    final achievements = <dynamic>[]; // TODO: Replace with real achievements

    return WorldBackground(
      child: SafeArea(
        child: Column(
          children: [
            const HudTopBar(title: 'Achievements', showBackButton: true),
            Expanded(
              child: achievements.isEmpty
                  ? const EmptyState(
                      icon: Icons.emoji_events_outlined,
                      message:
                          'No achievements yet — start exploring art walks!',
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Level Progress',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: 0.92),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              XpProgressBar(
                                currentXp: user.xp,
                                nextLevelXp: user.nextLevelXp,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${user.xp} XP / ${user.nextLevelXp} XP',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...achievements.map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AchievementTile(achievement: a),
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
}
