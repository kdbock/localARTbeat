// 📁 lib/artbeat_profile/widgets/profile_xp_card.dart
import 'package:flutter/material.dart';
import 'package:artbeat_profile/src/widgets/xp_progress_bar.dart';

class ProfileXpCard extends StatelessWidget {
  final int level;
  final int currentXp;
  final int nextLevelXp;

  const ProfileXpCard({
    super.key,
    required this.level,
    required this.currentXp,
    required this.nextLevelXp,
  });

  @override
  Widget build(BuildContext context) {
    final percent = currentXp / nextLevelXp;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Level $level',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          XpProgressBar(percent: percent),
          const SizedBox(height: 4),
          Text(
            '$currentXp / $nextLevelXp XP',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
