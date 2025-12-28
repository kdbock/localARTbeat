import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NewAchievementDialog extends StatelessWidget {
  final String badgeId;
  final Map<String, dynamic> badgeData;

  const NewAchievementDialog({
    super.key,
    required this.badgeId,
    required this.badgeData,
  });

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
    final badgeName = badgeData['name'] as String? ?? badgeId;
    final badgeDescription = badgeData['description'] as String? ?? '';
    final badgeIcon = badgeData['icon'] as String? ?? '🏆';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: WorldBackground(
        withBlobs: true,
        child: GlassCard(
          borderRadius: 36,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _AchievementBadge(iconEmoji: badgeIcon),
              const SizedBox(height: 24),
              Text(
                'art_walk_new_achievement_dialog_title'.tr(),
                textAlign: TextAlign.center,
                style: AppTypography.screenTitle(),
              ),
              const SizedBox(height: 8),
              Text(
                'art_walk_new_achievement_dialog_subtitle'.tr(),
                textAlign: TextAlign.center,
                style: AppTypography.body(Colors.white.withValues(alpha: 0.75)),
              ),
              const SizedBox(height: 24),
              Text(
                badgeName,
                textAlign: TextAlign.center,
                style: AppTypography.body(),
              ),
              const SizedBox(height: 12),
              Text(
                badgeDescription,
                textAlign: TextAlign.center,
                style: AppTypography.helper(),
              ),
              const SizedBox(height: 32),
              GradientCTAButton(
                label: 'art_walk_new_achievement_dialog_button_primary'.tr(),
                icon: Icons.rocket_launch,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final String iconEmoji;

  const _AchievementBadge({required this.iconEmoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x5522D3EE),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Text(iconEmoji, style: const TextStyle(fontSize: 48)),
      ),
    );
  }
}

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

    if (showOnlyRecent && badgeEntries.length > 1) {
      badgeEntries.sort((a, b) {
        final aTime = a.value['earnedAt'] as Timestamp?;
        final bTime = b.value['earnedAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });
      if (badgeEntries.length > 6) {
        badgeEntries.removeRange(6, badgeEntries.length);
      }
    }

    if (badgeEntries.isEmpty) {
      return GlassCard(
        borderRadius: 28,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 40,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'art_walk_achievements_grid_text_empty_title'.tr(),
              style: AppTypography.body(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'art_walk_achievements_grid_text_empty_subtitle'.tr(),
              style: AppTypography.helper(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: badgeEntries.map((entry) {
        final badgeInfo = RewardsService.badges[entry.key];
        if (badgeInfo == null) return const SizedBox.shrink();
        return _BadgeTile(
          badgeId: entry.key,
          badgeInfo: badgeInfo,
          earnedAt: entry.value['earnedAt'] as Timestamp?,
          isNew: entry.value['viewed'] == false,
        );
      }).toList(),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final String badgeId;
  final Map<String, dynamic> badgeInfo;
  final Timestamp? earnedAt;
  final bool isNew;

  const _BadgeTile({
    required this.badgeId,
    required this.badgeInfo,
    this.earnedAt,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    final badgeName = badgeInfo['name'] as String? ?? badgeId;
    final badgeIcon = badgeInfo['icon'] as String? ?? '🏅';

    return Semantics(
      label: badgeName,
      button: true,
      child: GestureDetector(
        onTap: () => _showBadgeDetails(context, badgeName, badgeIcon),
        child: Container(
          width: 110,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: isNew
                  ? const Color(0xFFFFC857)
                  : Colors.white.withValues(alpha: 0.12),
              width: 1.4,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isNew)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFFFC857).withValues(alpha: 0.9),
                  ),
                  child: Text(
                    'art_walk_badge_collection_chip_new'.tr(),
                    style: AppTypography.badge(Colors.black),
                  ),
                ),
              if (isNew) const SizedBox(height: 8),
              Text(badgeIcon, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                badgeName,
                textAlign: TextAlign.center,
                style: AppTypography.helper(
                  Colors.white.withValues(alpha: 0.9),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetails(
    BuildContext context,
    String badgeName,
    String badgeIcon,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: WorldBackground(
          withBlobs: false,
          child: GlassCard(
            borderRadius: 28,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(badgeIcon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(badgeName, style: AppTypography.body()),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  badgeInfo['description'] as String? ?? '',
                  style: AppTypography.body(
                    Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                if (earnedAt != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'art_walk_new_achievement_dialog_text_earned'.tr(
                      namedArgs: {'date': _formatDate(earnedAt!)},
                    ),
                    style: AppTypography.helper(),
                  ),
                ],
                const SizedBox(height: 24),
                GlassSecondaryButton(
                  label: 'art_walk_button_close'.tr(),
                  icon: Icons.check,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.month}/${date.day}/${date.year}';
  }
}
