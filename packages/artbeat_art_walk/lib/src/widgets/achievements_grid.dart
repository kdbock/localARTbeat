import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementsGrid extends StatelessWidget {
  final List<AchievementModel> achievements;
  final bool showDetails;
  final int crossAxisCount;
  final double childAspectRatio;
  final void Function(AchievementModel)? onAchievementTap;
  final double badgeSize;

  const AchievementsGrid({
    super.key,
    required this.achievements,
    this.showDetails = false,
    this.crossAxisCount = 3,
    this.childAspectRatio = 0.8,
    this.onAchievementTap,
    this.badgeSize = 70,
  });

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          borderRadius: 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withValues(
                        red: ((124.0).clamp(0, 255)).toDouble(),
                        green: ((77.0).clamp(0, 255)).toDouble(),
                        blue: ((255.0).clamp(0, 255)).toDouble(),
                        alpha: (0.4 * 255).toDouble(),
                      ),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'art_walk_achievements_grid_text_empty_title'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'art_walk_achievements_grid_text_empty_subtitle'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFFFFF).withValues(
                    red: 255.0,
                    green: 255.0,
                    blue: 255.0,
                    alpha: (0.7 * 255),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GradientCTAButton(
                label: 'art_walk_achievements_grid_button_learn_more'.tr(),
                icon: Icons.auto_awesome,
                onPressed: () =>
                    Navigator.of(context).pushNamed('/achievements/info'),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = List<AchievementModel>.from(achievements)
      ..sort((a, b) {
        if (a.isNew && !b.isNew) return -1;
        if (!a.isNew && b.isNew) return 1;
        return b.earnedAt.compareTo(a.earnedAt);
      });

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: showDetails ? 20 : 12,
      ),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final achievement = sorted[index];
        return AchievementBadge(
          achievement: achievement,
          showDetails: showDetails,
          isNew: achievement.isNew,
          size: badgeSize,
          onTap: onAchievementTap != null
              ? () => onAchievementTap!(achievement)
              : null,
        );
      },
    );
  }
}
