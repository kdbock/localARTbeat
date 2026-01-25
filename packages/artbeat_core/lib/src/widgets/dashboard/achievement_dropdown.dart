import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../achievement_badge.dart';

/// Dropdown widget to display user achievements
class AchievementDropdown extends StatelessWidget {
  final List<AchievementBadgeData> achievements;
  final bool isLoading;
  final bool isExpanded;
  final VoidCallback onToggle;

  const AchievementDropdown({
    Key? key,
    required this.achievements,
    required this.isLoading,
    required this.isExpanded,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'dashboard_achievements_count'.tr(namedArgs: {
                        'unlocked': unlockedCount.toString(),
                        'total': achievements.length.toString(),
                      }),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (isExpanded && !isLoading)
            achievements.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: achievements.length,
                    itemBuilder: (context, index) {
                      final a = achievements[index];
                      return ListTile(
                        leading: Icon(
                          a.isUnlocked ? Icons.emoji_events : Icons.lock,
                          color: a.isUnlocked ? Colors.amber : Colors.grey,
                        ),
                        title: Text(a.title),
                        subtitle: Text(a.description),
                        trailing: a.isUnlocked
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                      );
                    },
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'dashboard_achievements_none'.tr(),
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  ),
        ],
      ),
    );
  }
}
