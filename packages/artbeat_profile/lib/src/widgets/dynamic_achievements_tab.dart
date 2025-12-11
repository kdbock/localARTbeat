import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

/// Dynamic achievements tab that loads all badges from RewardsService
class DynamicAchievementsTab extends StatefulWidget {
  final String userId;

  const DynamicAchievementsTab({super.key, required this.userId});

  @override
  State<DynamicAchievementsTab> createState() => _DynamicAchievementsTabState();
}

class _DynamicAchievementsTabState extends State<DynamicAchievementsTab> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Quest',
    'Explorer',
    'Social',
    'Creator',
    'Level',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_outlined,
                color: ArtbeatColors.accentYellow,
              ),
              const SizedBox(width: 8),
              const Text(
                'Achievement Collection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_getEarnedBadgesCount()}/${RewardsService.badges.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: ArtbeatColors.primaryPurple.withValues(
                      alpha: 0.2,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? ArtbeatColors.primaryPurple
                          : ArtbeatColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Badges grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _getFilteredBadges().length,
              itemBuilder: (context, index) {
                final badgeEntry = _getFilteredBadges()[index];
                return _buildBadgeCard(badgeEntry.key, badgeEntry.value);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, Map<String, dynamic>>> _getFilteredBadges() {
    final allBadges = RewardsService.badges.entries.toList();

    if (_selectedCategory == 'All') {
      return allBadges;
    }

    return allBadges.where((entry) {
      final badgeId = entry.key;
      return _getBadgeCategory(badgeId) == _selectedCategory;
    }).toList();
  }

  String _getBadgeCategory(String badgeId) {
    if (badgeId.contains('walk') || badgeId.contains('challenge')) {
      return 'Quest';
    } else if (badgeId.contains('discover') || badgeId.contains('explorer')) {
      return 'Explorer';
    } else if (badgeId.contains('social') ||
        badgeId.contains('friend') ||
        badgeId.contains('helpful')) {
      return 'Social';
    } else if (badgeId.contains('creator') ||
        badgeId.contains('capture') ||
        badgeId.contains('review')) {
      return 'Creator';
    } else if (badgeId.contains('level')) {
      return 'Level';
    }
    return 'Quest';
  }

  int _getEarnedBadgesCount() {
    // This would check actual user data
    // For now, return a placeholder
    return 12;
  }

  bool _isBadgeEarned(String badgeId) {
    // This would check actual user data
    // For now, randomly mark some as earned for demo
    return badgeId.hashCode % 3 == 0;
  }

  double _getBadgeProgress(String badgeId) {
    // This would check actual user progress
    // For now, return random progress for demo
    if (_isBadgeEarned(badgeId)) return 1.0;
    return (badgeId.hashCode % 100) / 100.0;
  }

  Widget _buildBadgeCard(String badgeId, Map<String, dynamic> badgeData) {
    final name = badgeData['name'] as String;
    final icon = badgeData['icon'] as String;
    final isEarned = _isBadgeEarned(badgeId);
    final progress = _getBadgeProgress(badgeId);
    final category = _getBadgeCategory(badgeId);
    final categoryColor = _getCategoryColor(category);
    final rarity = _getBadgeRarity(badgeId);

    return GestureDetector(
      onTap: () => _showBadgeDetails(badgeId, badgeData),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isEarned
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    categoryColor.withValues(alpha: 0.2),
                    categoryColor.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: isEarned ? null : ArtbeatColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEarned
                ? categoryColor.withValues(alpha: 0.5)
                : ArtbeatColors.border,
            width: isEarned ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rarity indicator
            if (isEarned)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getRarityColor(rarity),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rarity,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 4),

            // Badge icon
            Stack(
              alignment: Alignment.center,
              children: [
                if (!isEarned)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                Opacity(
                  opacity: isEarned ? 1.0 : 0.3,
                  child: Text(icon, style: const TextStyle(fontSize: 48)),
                ),
                if (!isEarned)
                  const Icon(Icons.lock, color: Colors.grey, size: 24),
              ],
            ),

            const SizedBox(height: 8),

            // Badge name
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isEarned
                    ? ArtbeatColors.textPrimary
                    : ArtbeatColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Progress bar for locked badges
            if (!isEarned && progress > 0) ...[
              const SizedBox(height: 4),
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: categoryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Quest':
        return ArtbeatColors.primaryPurple;
      case 'Explorer':
        return ArtbeatColors.primaryGreen;
      case 'Social':
        return ArtbeatColors.secondaryTeal;
      case 'Creator':
        return const Color(0xFFF59E0B); // Orange
      case 'Level':
        return ArtbeatColors.accentYellow;
      default:
        return ArtbeatColors.primaryPurple;
    }
  }

  String _getBadgeRarity(String badgeId) {
    // This would be based on actual rarity data
    final hash = badgeId.hashCode % 100;
    if (hash < 10) return 'Legendary';
    if (hash < 30) return 'Epic';
    if (hash < 60) return 'Rare';
    return 'Common';
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'Legendary':
        return const Color(0xFFFFD700); // Gold
      case 'Epic':
        return const Color(0xFF9C27B0); // Purple
      case 'Rare':
        return const Color(0xFF2196F3); // Blue
      default:
        return const Color(0xFF9E9E9E); // Gray
    }
  }

  void _showBadgeDetails(String badgeId, Map<String, dynamic> badgeData) {
    final name = badgeData['name'] as String;
    final description = badgeData['description'] as String;
    final icon = badgeData['icon'] as String;
    final requirement = badgeData['requirement'] as Map<String, dynamic>;
    final isEarned = _isBadgeEarned(badgeId);
    final progress = _getBadgeProgress(badgeId);
    final category = _getBadgeCategory(badgeId);
    final categoryColor = _getCategoryColor(category);

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                categoryColor.withValues(alpha: 0.2),
                categoryColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: ArtbeatColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ArtbeatColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Requirement:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${requirement['type']}: ${requirement['count']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ArtbeatColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (!isEarned) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            categoryColor,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(progress * 100).toInt()}% Complete',
                        style: TextStyle(
                          fontSize: 12,
                          color: categoryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: categoryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text('profile_dynamic_achievements_tab_text_close'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
