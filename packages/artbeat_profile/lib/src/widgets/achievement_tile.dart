import 'package:flutter/material.dart';
import 'package:artbeat_profile/src/widgets/glass_card.dart' as profile;
import 'package:artbeat_profile/src/widgets/xp_progress_bar.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart' as walk;

class AchievementTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool earned;
  final int xp;
  final int? currentXp;
  final dynamic achievement;

  const AchievementTile({
    Key? key,
    this.title = '',
    this.description = '',
    this.icon = Icons.star,
    this.earned = false,
    this.xp = 0,
    this.currentXp,
    this.achievement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (achievement != null && achievement is walk.AchievementModel) {
      final ach = achievement as walk.AchievementModel;

      return profile.GlassCard(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ach.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ach.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Earned on ${ach.earnedAt.toString().split(' ')[0]}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white60),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Fallback to old implementation
    return profile.GlassCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 48, color: earned ? null : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (!earned) ...[
                  const SizedBox(height: 8),
                  XpProgressBar(
                    percent: currentXp != null ? currentXp! / xp : 0.0,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
