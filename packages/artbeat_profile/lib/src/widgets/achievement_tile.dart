import 'package:flutter/material.dart';
import 'package:artbeat_profile/src/widgets/glass_card.dart';
import 'package:artbeat_profile/src/widgets/xp_progress_bar.dart';

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
    if (achievement != null) {
      return Text('Achievement: $achievement');
    }
    return GlassCard(
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
