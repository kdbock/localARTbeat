import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// User Progress Card - Shows streaks, achievements, and progress
class UserProgressCard extends StatelessWidget {
  final int currentStreak;
  final int totalDiscoveries;
  final int weeklyGoal;
  final int weeklyProgress;
  final VoidCallback? onTap;

  const UserProgressCard({
    Key? key,
    this.currentStreak = 0,
    this.totalDiscoveries = 0,
    this.weeklyGoal = 7,
    this.weeklyProgress = 0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progressPercent = weeklyGoal > 0 ? weeklyProgress / weeklyGoal : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'progress_card_title'.tr(),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.withValues(alpha: 0.5),
                    size: 16,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Streak and discoveries
            Row(
              children: [
                // Current streak
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.local_fire_department,
                    iconColor: Colors.orange,
                    value: '$currentStreak',
                    label: 'progress_card_streak'.tr(),
                  ),
                ),

                const SizedBox(width: 12),

                // Total discoveries
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.explore,
                    iconColor: Colors.blue,
                    value: '$totalDiscoveries',
                    label: 'progress_card_discoveries'.tr(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Weekly progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'progress_card_weekly_goal'.tr(),
                      style: TextStyle(
                        color: Colors.black87.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$weeklyProgress/$weeklyGoal',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Progress bar
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressPercent.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.blue, Colors.purple],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'progress_card_complete'.tr(namedArgs: {'percent': '${(progressPercent * 100).round()}'}),
                  style: TextStyle(
                    color: Colors.black87.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            // Achievement badges (if any)
            if (currentStreak >= 7 || totalDiscoveries >= 50) ...[
              const SizedBox(height: 16),
              _buildAchievementBadges(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.black87.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ux_card_achievements'.tr(),
          style: TextStyle(
            color: Colors.black87.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (currentStreak >= 7)
              _buildBadge(
                icon: Icons.local_fire_department,
                color: Colors.orange,
                label: 'progress_card_streak_7'.tr(),
              ),
            if (totalDiscoveries >= 50)
              _buildBadge(
                icon: Icons.explore,
                color: Colors.blue,
                label: 'progress_card_explorer'.tr(),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
