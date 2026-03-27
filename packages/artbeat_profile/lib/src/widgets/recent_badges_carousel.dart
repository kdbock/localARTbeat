import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Model for badge display
class BadgeData {
  final String id;
  final String name;
  final String description;
  final String icon;
  final DateTime earnedAt;
  final String category;

  BadgeData({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.earnedAt,
    required this.category,
  });
}

/// Carousel widget that displays recently earned badges
class RecentBadgesCarousel extends StatelessWidget {
  final List<BadgeData> recentBadges;
  final VoidCallback? onViewAll;

  const RecentBadgesCarousel({
    super.key,
    required this.recentBadges,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (recentBadges.isEmpty) {
      return const SizedBox.shrink();
    }

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: ArtbeatColors.accentYellow,
                    size: 20,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Recent Badges',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: Text(
                    'common_view_all'.tr(),
                    style: const TextStyle(
                      color: ArtbeatColors.accentYellow,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentBadges.length,
              itemBuilder: (context, index) {
                final badge = recentBadges[index];
                return _buildBadgeCard(badge);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(BadgeData badge) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryColor(badge.category).withValues(alpha: 0.3),
            _getCategoryColor(badge.category).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCategoryColor(badge.category).withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badge.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              badge.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'quest':
        return ArtbeatColors.primaryPurple;
      case 'explorer':
        return ArtbeatColors.primaryGreen;
      case 'social':
        return ArtbeatColors.secondaryTeal;
      case 'creator':
        return const Color(0xFFF59E0B); // Orange
      case 'level':
        return ArtbeatColors.accentYellow;
      default:
        return ArtbeatColors.primaryPurple;
    }
  }
}
