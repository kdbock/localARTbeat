import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

// Dummy level system for progress calculation
const Map<int, Map<String, dynamic>> _levelSystem = {
  1: {'minXP': 0, 'maxXP': 100, 'title': 'Beginner'},
  2: {'minXP': 101, 'maxXP': 300, 'title': 'Explorer'},
  3: {'minXP': 301, 'maxXP': 600, 'title': 'Artist'},
  4: {'minXP': 601, 'maxXP': 1000, 'title': 'Creator'},
  5: {'minXP': 1001, 'maxXP': 1500, 'title': 'Master'},
  // Add more levels as needed
};

/// Widget that displays the user's level progress with XP bar
class LevelProgressBar extends StatelessWidget {
  final int currentXP;
  final int level;
  final bool showDetails;

  const LevelProgressBar({
    super.key,
    required this.currentXP,
    required this.level,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final levelInfo = _levelSystem[level] ?? _levelSystem[1]!;
    final nextLevelInfo = _levelSystem[level + 1];

    final minXP = levelInfo['minXP'] as int;
    final maxXP = levelInfo['maxXP'] as int;
    final levelTitle = levelInfo['title'] as String;

    final xpInCurrentLevel = currentXP - minXP;
    final xpNeededForLevel = maxXP - minXP + 1;
    final progress = (xpInCurrentLevel / xpNeededForLevel).clamp(0.0, 1.0);
    final xpToNextLevel = nextLevelInfo != null ? (maxXP + 1) - currentXP : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ArtbeatColors.accentYellow,
                      ArtbeatColors.accentYellow.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: ArtbeatColors.accentYellow.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Level $level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (showDetails) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    levelTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Spacer(),
              const SizedBox(width: 8),
              Text(
                '$currentXP XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        ArtbeatColors.accentYellow,
                        ArtbeatColors.primaryGreen,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: ArtbeatColors.accentYellow.withValues(
                          alpha: 0.5,
                        ),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (showDetails && nextLevelInfo != null) ...[
            const SizedBox(height: 4),
            Text(
              '$xpToNextLevel XP to Level ${level + 1}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
