import 'package:flutter/material.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:easy_localization/easy_localization.dart';

/// Widget to display a grid of achievement badges
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No achievements yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete art walks to earn achievements!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/achievements/info');
                },
                icon: const Icon(Icons.info_outline, size: 18),
                label: Text(
                  'art_walk_achievements_grid_button_learn_more'.tr(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.grey[700],
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort achievements with new ones first
    final sortedAchievements = List<AchievementModel>.from(achievements)
      ..sort((a, b) {
        // Sort by isNew status, then by earnedAt date (most recent first)
        if (a.isNew && !b.isNew) return -1;
        if (!a.isNew && b.isNew) return 1;
        return b.earnedAt.compareTo(a.earnedAt);
      });

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: showDetails ? 24 : 12,
      ),
      itemCount: sortedAchievements.length,
      itemBuilder: (context, index) {
        final achievement = sortedAchievements[index];
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
