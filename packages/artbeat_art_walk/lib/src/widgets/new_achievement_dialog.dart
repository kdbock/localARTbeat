import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:easy_localization/easy_localization.dart';

/// Dialog for displaying new achievements/badges to users
class NewAchievementDialog extends StatelessWidget {
  final String badgeId;
  final Map<String, dynamic> badgeData;

  const NewAchievementDialog({
    super.key,
    required this.badgeId,
    required this.badgeData,
  });

  /// Show the achievement dialog
  static Future<void> show(BuildContext context, String badgeId) async {
    final badgeData = RewardsService.badges[badgeId];
    if (badgeData == null) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          NewAchievementDialog(badgeId: badgeId, badgeData: badgeData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade100, Colors.blue.shade100],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebration icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  badgeData['icon'] as String? ?? '🏆',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Achievement unlocked text
            Text(
              'Achievement Unlocked!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade800,
              ),
            ),

            const SizedBox(height: 12),

            // Badge name
            Text(
              badgeData['name'] as String,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Badge description
            Text(
              badgeData['description'] as String,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Confetti or celebration animation could go here
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: 0.3),
              ),
              child: const Center(
                child: Text('🎉 ✨ 🎊 ✨ 🎉', style: TextStyle(fontSize: 24)),
              ),
            ),

            const SizedBox(height: 20),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Awesome!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying a user's badge collection
class BadgeCollectionWidget extends StatelessWidget {
  final Map<String, dynamic> userBadges;
  final bool showOnlyRecent;

  const BadgeCollectionWidget({
    super.key,
    required this.userBadges,
    this.showOnlyRecent = false,
  });

  @override
  Widget build(BuildContext context) {
    final badgeEntries = userBadges.entries.toList();

    if (showOnlyRecent) {
      // Sort by earned date and take the most recent 6
      badgeEntries.sort((a, b) {
        final aTime = a.value['earnedAt'] as Timestamp?;
        final bTime = b.value['earnedAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });
      badgeEntries.removeRange(6, badgeEntries.length);
    }

    if (badgeEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No badges yet',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete art walks and capture art to earn your first badges!',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: badgeEntries.map((entry) {
        final badgeId = entry.key;
        final badgeInfo = RewardsService.badges[badgeId];

        if (badgeInfo == null) return const SizedBox.shrink();

        return _BadgeItem(
          badgeId: badgeId,
          badgeInfo: badgeInfo,
          earnedAt: entry.value['earnedAt'] as Timestamp?,
          isNew: entry.value['viewed'] == false,
        );
      }).toList(),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final String badgeId;
  final Map<String, dynamic> badgeInfo;
  final Timestamp? earnedAt;
  final bool isNew;

  const _BadgeItem({
    required this.badgeId,
    required this.badgeInfo,
    this.earnedAt,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBadgeDetails(context),
      child: Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: isNew
              ? Border.all(color: Colors.amber, width: 2)
              : Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // New badge indicator
            if (isNew)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

            if (isNew) const SizedBox(height: 4),

            // Badge icon
            Text(
              badgeInfo['icon'] as String? ?? '🏆',
              style: const TextStyle(fontSize: 32),
            ),

            const SizedBox(height: 4),

            // Badge name (truncated)
            Text(
              badgeInfo['name'] as String,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(
              badgeInfo['icon'] as String? ?? '🏆',
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                badgeInfo['name'] as String,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(badgeInfo['description'] as String),
            if (earnedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Earned: ${_formatDate(earnedAt!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('art_walk_button_close'.tr()),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.month}/${date.day}/${date.year}';
  }
}
